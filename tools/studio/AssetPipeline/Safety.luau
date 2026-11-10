--!strict
local Types = require(script.Parent.Types)
type SourceSnapshot = Types.SourceSnapshot
local Safety = {}
Safety.SCENE_ID = "castlefight.asset-visual-test.v1"
Safety.OWNER = "castlefight.asset-pipeline.v1"

function Safety.Edit(): ()
	assert(not game:GetService("RunService"):IsRunning(), "E_PLAY_MODE: editor tools only")
end
function Safety.Guard(root: Model): ()
	Safety.Edit()
	assert(game.PlaceId ~= 101102700433907, "E_MAIN_MAP: editor preparation belongs in a test place")
	local marker = root:FindFirstChild("SceneId")
	assert(marker and marker:IsA("StringValue") and marker.Value == Safety.SCENE_ID, "E_SCENE_ID: wrong test scene")
	assert(root.Parent == workspace or root.Parent == nil, "E_SCENE_PARENT")
end
function Safety.Folder(parent: Instance, name: string): Folder
	local item = parent:FindFirstChild(name)
	assert(item and item:IsA("Folder"), "E_FOLDER: " .. name)
	return item
end
function Safety.Parts(source: Instance, maxParts: number): {BasePart}
	assert(source:IsA("Model") or source:IsA("BasePart"), "E_SOURCE_TYPE: Model or BasePart required")
	local parts: {BasePart} = {}
	if source:IsA("BasePart") then table.insert(parts, source) end
	local descendants = source:GetDescendants()
	assert(#descendants <= 1000, "E_COMPONENT_LIMIT: too many descendants")
	for _, child in descendants do
		assert(not child:IsA("LuaSourceContainer") and not child:IsA("Humanoid")
			and not child:IsA("Bone") and not child:IsA("JointInstance")
			and not child:IsA("Constraint") and not child:IsA("AnimationController"), "E_UNSAFE_SOURCE: scripts or existing rig require review")
		if child:IsA("BasePart") then table.insert(parts, child) end
	end
	assert(#parts > 0 and #parts <= maxParts, "E_COMPONENT_LIMIT: invalid visual component count")
	return parts
end
function Safety.Visual(parts: {BasePart}): ()
	for _, part in parts do
		part.Anchored = true ; part.CanCollide = false ; part.CanTouch = false ; part.CanQuery = false ; part.Massless = true
	end
end
function Safety.Snapshot(parts: {BasePart}): {SourceSnapshot}
	local result: {SourceSnapshot} = {}
	for _, part in parts do
		table.insert(result, {part = part, cf = part.CFrame, size = part.Size, parent = part.Parent,
			anchored = part.Anchored, collide = part.CanCollide, touch = part.CanTouch, query = part.CanQuery,
			meshId = if part:IsA("MeshPart") then part.MeshId else nil,
			textureId = if part:IsA("MeshPart") then part.TextureID else nil})
	end
	return result
end
function Safety.AssertUnchanged(snapshot: {SourceSnapshot}): ()
	for _, entry in snapshot do
		local p = entry.part
		assert(p.Parent == entry.parent and p.CFrame == entry.cf and p.Size == entry.size
			and p.Anchored == entry.anchored and p.CanCollide == entry.collide and p.CanTouch == entry.touch
			and p.CanQuery == entry.query, "E_SOURCE_CHANGED")
		if p:IsA("MeshPart") then assert(p.MeshId == entry.meshId and p.TextureID == entry.textureId, "E_SOURCE_CONTENT_CHANGED") end
	end
end
function Safety.CloneModel(source: Instance, name: string): Model
	local wrapper = Instance.new("Model") ; wrapper.Name = name
	local clone = source:Clone()
	assert(clone, "E_ARCHIVABLE: source cannot be cloned")
	clone.Parent = wrapper
	wrapper:SetAttribute("PipelineOwner", Safety.OWNER)
	return wrapper
end
function Safety.Publish(object: Instance, parent: Instance): ()
	local history = game:GetService("ChangeHistoryService")
	local ok, id = pcall(function(): string? return history:TryBeginRecording("AssetPipeline", "Prepare visual asset copy") end)
	local success, message = pcall(function(): boolean object.Parent = parent ; return true end)
	if ok and id then history:FinishRecording(id, if success then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel) end
	assert(success, tostring(message))
end
function Safety.Vector(values: {number}): Vector3
	return Vector3.new(values[1], values[2], values[3])
end
function Safety.Pose(position: {number}, angles: {number}): CFrame
	return CFrame.new(Safety.Vector(position)) * CFrame.Angles(math.rad(angles[1]), math.rad(angles[2]), math.rad(angles[3]))
end
function Safety.Yaw(direction: string): number
	local angles = {["-Z"] = 0, ["+Z"] = math.pi, ["+X"] = -math.pi / 2, ["-X"] = math.pi / 2}
	local value = angles[direction] ; assert(value ~= nil, "E_FORWARD_DIRECTION") ; return value
end
function Safety.Footprint(cf: CFrame, size: Vector3, pad: BasePart): Vector2
	local minX, minZ, maxX, maxZ = math.huge, math.huge, -math.huge, -math.huge
	for _, x in {-1, 1} do
		for _, y in {-1, 1} do
			for _, z in {-1, 1} do
				local p = pad.CFrame:PointToObjectSpace(cf * Vector3.new(x * size.X / 2, y * size.Y / 2, z * size.Z / 2))
				minX = math.min(minX, p.X)
				maxX = math.max(maxX, p.X)
				minZ = math.min(minZ, p.Z)
				maxZ = math.max(maxZ, p.Z)
			end
		end
	end
	return Vector2.new(maxX - minX, maxZ - minZ)
end
return Safety
