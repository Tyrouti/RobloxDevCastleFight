--!strict
local Types = require(script.Parent.Types)
type AssetConfig = Types.AssetConfig
type Report = Types.Report
local Safety = require(script.Parent.Safety)
local Config = require(script.Parent.Config)
local Pipeline = {}

local function selected(): Instance
	local items = game:GetService("Selection"):Get()
	assert(#items == 1, "E_SELECTION: select exactly one imported model")
	return items[1]
end
local function anchor(name: string, size: Vector3, cf: CFrame): Part
	local p = Instance.new("Part") ; p.Name = name ; p.Size = size ; p.CFrame = cf
	p.Transparency = 1
	Safety.Visual({p})
	return p
end
local function target(root: Model, assetId: string): Model
	local item = Safety.Folder(root, "Prepared"):FindFirstChild(assetId)
	assert(item and item:IsA("Model") and item:GetAttribute("PipelineOwner") == Safety.OWNER, "E_PREPARED_NOT_FOUND")
	return item
end
function Pipeline.CheckAsset(root: Model, assetId: string): Report
	Safety.Guard(root)
	local asset = target(root, assetId)
	local c = Config.Get(assetId)
	local visual = asset:FindFirstChild("Visual") ; assert(visual and visual:IsA("Model"), "E_VISUAL")
	local cf, size = visual:GetBoundingBox()
	local parts = Safety.Parts(visual, c.maxVisualComponents)
	local meshes, unsafe = {}, 0
	for _, p in parts do
		if p:IsA("MeshPart") then table.insert(meshes, {name = p.Name, meshId = p.MeshId, textureId = p.TextureID}) end
		if p.CanCollide or p.CanTouch or p.CanQuery or not p.Anchored then unsafe += 1 end
	end
	local evidence = c.geometryEvidence
	local evidenceMatches = evidence ~= nil and #meshes == #(evidence :: Types.Evidence).observedMeshIds
	if evidence then
		for _, mesh in meshes do if not table.find(evidence.observedMeshIds, mesh.meshId) then evidenceMatches = false end end
	end
	local triangleCount: number? = if evidenceMatches and evidence then evidence.triangleCount else nil
	local pad = root:FindFirstChild("BuildPlot") ; assert(pad and pad:IsA("BasePart"), "E_PLOT")
	local feetY = cf.Position.Y - size.Y / 2
	local padTopY = pad.Position.Y + pad.Size.Y / 2
	local footprint = c.plotSizeStuds or {pad.Size.X, pad.Size.Z}
	local projected = Safety.Footprint(cf, size, pad)
	local fits = projected.X <= footprint[1] and projected.Y <= footprint[2]
	local equipmentUnsafe, equipmentCount = 0, 0
	local missingSlots: {string} = {}
	local carrier = asset:FindFirstChild("AssetRoot")
	if c.assetType == "unit" then
		for _, name in {"RightHand", "LeftHand", "Back", "Head", "Root"} do
			local slot = if carrier then carrier:FindFirstChild(name) else nil
			if not slot or not slot:IsA("Attachment") then table.insert(missingSlots, name) end
		end
	end
	for _, p in Safety.Folder(asset, "Equipment"):GetDescendants() do
		if p:IsA("BasePart") then
			equipmentCount += 1
			if p.CanCollide or p.CanTouch or p.CanQuery or not p.Anchored then equipmentUnsafe += 1 end
		end
	end
	local report: Report = {
		assetId = assetId, assetType = c.assetType, importStatus = "existing_import_copy_verified",
		validationStatus = "requiring_manual_review", visualComponents = #parts, meshParts = meshes,
		height = size.Y, width = size.X, depth = size.Z, feetY = feetY, surfaceY = padTopY,
		groundAligned = math.abs(feetY - padTopY) < 0.002, pivot = {asset:GetPivot().Position.X, asset:GetPivot().Position.Y, asset:GetPivot().Position.Z},
		unsafeVisualParts = unsafe, footprintFits = fits, maxTriangles = c.maxTriangles,
		projectedFootprint = {projected.X, projected.Y}, equipmentVisualParts = equipmentCount,
		unsafeEquipmentParts = equipmentUnsafe, collisionMode = c.collisionMode,
		missingEquipmentSlots = missingSlots,
		simpleCollisionPresent = asset:FindFirstChild("SimpleCollision") ~= nil,
		triangleCount = triangleCount, triangleEvidence = if triangleCount then "offline_report_matching_mesh_ids_not_live_topology_readback" else "requiring_manual_review",
		overTriangleBudget = if triangleCount then triangleCount > c.maxTriangles else nil,
		desiredForwardDirection = c.desiredForwardDirection, declaredSourceForward = c.sourceForwardDirection,
		orientationStatus = "requiring_manual_review_face_direction_not_inferable",
		requiresRig = c.requiresRig, rigCreated = false, provisionalAttachments = c.assetType == "unit",
		limitations = {"No automatic face detection, topology/UV/self-intersection/skin/deformation certification", "Equipment is static; future animation grips require verification"},
	}
	local value = asset:FindFirstChild("Diagnostics")
	if value and value:IsA("StringValue") then value.Value = game:GetService("HttpService"):JSONEncode(report) end
	return report
end
function Pipeline.PrepareAsset(root: Model, assetId: string, explicitSource: Instance?): (Model, Report)
	Safety.Guard(root)
	local c = Config.Get(assetId) ; Config.Validate(c, true)
	local prepared = Safety.Folder(root, "Prepared")
	assert(not prepared:FindFirstChild(assetId), "E_DUPLICATE_ASSET: ResetTest archives old copies first")
	local source = explicitSource or selected()
	assert(not source:IsDescendantOf(root) and source ~= root, "E_SOURCE_IN_TEST: choose original external import")
	assert(source:IsA("Model") or source:IsA("MeshPart"), "E_SOURCE_TYPE")
	local originals = Safety.Parts(source, c.maxVisualComponents)
	local meshCount = 0
	for _, p in originals do if p:IsA("MeshPart") then assert(p.MeshId ~= "", "E_EMPTY_MESH") ; meshCount += 1 end end
	assert(meshCount > 0, "E_MESH_REQUIRED: imported MeshPart required")
	local originalState = Safety.Snapshot(originals)
	local asset = Instance.new("Model") ; asset.Name = assetId ; asset:SetAttribute("PipelineOwner", Safety.OWNER)
	local visual = Safety.CloneModel(source, "Visual") ; visual.Parent = asset
	Safety.Visual(Safety.Parts(visual, c.maxVisualComponents))
	local _, initialSize = visual:GetBoundingBox()
	assert(initialSize.Y > 0.001, "E_ZERO_HEIGHT")
	local height = c.targetHeightStuds :: number
	visual:ScaleTo(visual:GetScale() * height / initialSize.Y)
	local cf, size = visual:GetBoundingBox()
	visual.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
	local pad = root:FindFirstChild("BuildPlot") ; assert(pad and pad:IsA("BasePart"), "E_PLOT")
	assert(pad.CFrame.UpVector.Y > 0.999, "E_SLOPED_PLOT: manual review required")
	local feet = Vector3.new(pad.Position.X, pad.Position.Y + pad.Size.Y / 2, pad.Position.Z)
	local desired = Safety.Yaw(c.desiredForwardDirection)
	local yaw = if c.sourceForwardDirection then desired - Safety.Yaw(c.sourceForwardDirection) else 0
	visual:PivotTo(CFrame.new(feet) * CFrame.Angles(0, yaw, 0))
	local bodyCF, bodySize = visual:GetBoundingBox()
	local footprint = c.plotSizeStuds or {pad.Size.X, pad.Size.Z}
	local projected = Safety.Footprint(bodyCF, bodySize, pad)
	assert(projected.X <= footprint[1] and projected.Y <= footprint[2], "E_PLOT_BOUNDS: resized asset exceeds plot")
	local rootPart = anchor("AssetRoot", Vector3.new(0.1, 0.1, 0.1), CFrame.new(feet) * CFrame.Angles(0, desired, 0))
	rootPart.Parent = asset ; asset.PrimaryPart = rootPart
	local equipment = Instance.new("Folder") ; equipment.Name = "Equipment" ; equipment.Parent = asset
	local diagnostics = Instance.new("StringValue") ; diagnostics.Name = "Diagnostics" ; diagnostics.Parent = asset
	if c.assetType == "unit" then
		for name, pose in c.equipmentSlots do
			local slot = Instance.new("Attachment") ; slot.Name = name
			slot.CFrame = CFrame.new(Safety.Vector(pose.position) * height) * Safety.Pose({0, 0, 0}, pose.rotationDegrees)
			slot:SetAttribute("ProvisionalNotRig", true) ; slot.Parent = rootPart
		end
	elseif c.assetType == "building" or c.assetType == "castle" then
		local point = c.spawnPoint ; assert(point, "E_SPAWN_MARKER_CONFIG")
		local p = Safety.Vector(point.positionNormalized)
		local offset = Vector3.new(p.X * bodySize.X, p.Y * height, p.Z * bodySize.Z)
		local spawn = Instance.new("Attachment") ; spawn.Name = "SpawnPoint"
		spawn.CFrame = CFrame.new(offset) * Safety.Pose({0, 0, 0}, point.rotationDegrees)
		spawn:SetAttribute("ProvisionalNotGameplaySpawn", true) ; spawn.Parent = rootPart
		local exit = anchor("ExitMarker", Vector3.new(0.5, 0.04, 0.5), spawn.WorldCFrame + Vector3.new(0, 0.025, 0))
		exit.Transparency = 0.25 ; exit.Color = Color3.fromRGB(70, 200, 150) ; exit.Parent = asset
	end
	if c.collisionMode == "box" then
		local collider = anchor("SimpleCollision", bodySize, bodyCF)
		collider.CanCollide = true ; collider.CanQuery = true ; collider.Parent = asset
		collider:SetAttribute("ProvisionalBoxBlocksDoorway", true)
	end
	Safety.AssertUnchanged(originalState)
	Safety.Publish(asset, prepared)
	return asset, Pipeline.CheckAsset(root, assetId)
end
function Pipeline.Target(root: Model, assetId: string): Model Safety.Guard(root) ; return target(root, assetId) end
return Pipeline
