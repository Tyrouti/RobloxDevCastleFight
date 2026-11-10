--!strict
-- QA in the existing test place. Building path uses knight geometry as a labeled fixture,
-- NOT a generated or imported building. No asset/config files are changed by this test.
local api = require(game.ReplicatedStorage.CastleFightAssetTools.Commands)
local config = require(game.ReplicatedStorage.CastleFightAssetTools.Config)
local safety = require(game.ReplicatedStorage.CastleFightAssetTools.Safety)
local old = workspace:FindFirstChild("KnightVisualTest")
assert(old and old:IsA("Model"), "Existing knight test required")
local source = old:FindFirstChild("KnightBody")
assert(source and source:IsA("Model"), "Existing imported knight required")
local root = api.CreateTestScene()
local originals = safety.Snapshot(safety.Parts(source, 64))
local swordOriginal = old:FindFirstChild("Sword")
local shieldOriginal = old:FindFirstChild("Shield")
assert(swordOriginal and shieldOriginal)
local gearBefore = safety.Snapshot(safety.Parts(swordOriginal, 64))
local shieldBefore = safety.Snapshot(safety.Parts(shieldOriginal, 64))
local cases: {string} = {}
local function rejected(name: string, expected: string, callback: () -> ()): ()
	local ok, message = pcall(function(): boolean
		callback()
		return true
	end)
	assert(not ok and string.find(tostring(message), expected, 1, true), name .. ": " .. tostring(message))
	table.insert(cases, name)
end
rejected("duplicate asset", "E_DUPLICATE_ASSET", function(): () api.PrepareAsset("human_knight", source, root) end)
rejected("duplicate equipment", "E_DUPLICATE_EQUIPMENT", function(): () api.PlaceEquipment("human_knight", "Sword", nil, root) end)
rejected("missing Bow template", "E_EQUIPMENT_SOURCE_MISSING", function(): () api.PlaceEquipment("human_knight", "Bow", nil, root) end)
rejected("missing Staff template", "E_EQUIPMENT_SOURCE_MISSING", function(): () api.PlaceEquipment("human_knight", "Staff", nil, root) end)
rejected("missing building file", "E_SOURCE_MISSING", function(): () api.PrepareAsset("human_barracks", source, root) end)
local wrong = Instance.new("Model")
rejected("wrong scene", "E_SCENE_ID", function(): () api.CheckAsset("human_knight", wrong) end)
wrong:Destroy()
local prepared = root:FindFirstChild("Prepared")
assert(prepared and prepared:IsA("Folder"))
local foreign = Instance.new("Folder")
foreign.Name = "__QA_ForeignNotPipelineOwned"
foreign.Parent = prepared
rejected("foreign object reset refused", "E_FOREIGN_OBJECT", function(): () api.ResetTest(root) end)
foreign:Destroy() -- only this test-created empty fixture
assert(api.ResetTest(root) == 1 and #prepared:GetChildren() == 0)
assert(source.Parent == old)
table.insert(cases, "ResetTest archives copies outside Workspace and preserves original")
local reference = old:FindFirstChild("Reference5Stud")
assert(reference)
rejected("no MeshPart", "E_MESH_REQUIRED", function(): () api.PrepareAsset("human_knight", reference, root) end)
local c = config.Get("human_knight")
local savedHeight, savedLimit = c.targetHeightStuds, c.maxVisualComponents
c.targetHeightStuds = nil
rejected("unknown height", "E_TARGET_HEIGHT_TODO", function(): () api.PrepareAsset("human_knight", source, root) end)
c.targetHeightStuds = savedHeight
local twoMeshes = source:Clone()
local mesh = twoMeshes:FindFirstChildWhichIsA("MeshPart", true)
assert(mesh)
mesh:Clone().Parent = twoMeshes
c.maxVisualComponents = 1
rejected("visual component limit", "E_COMPONENT_LIMIT", function(): () api.PrepareAsset("human_knight", twoMeshes, root) end)
c.maxVisualComponents = savedLimit
twoMeshes:Destroy() -- temporary unparented fixture, never an imported original
local originalConfig = table.clone(c)
local fixtureOK, fixtureFailure = pcall(function(): boolean
	c.assetType = "building"
	c.requiresRig = false
	c.collisionMode = "box"
	c.targetHeightStuds = 6
	c.plotSizeStuds = {1, 1}
	c.spawnPoint = {positionNormalized = {0, 0, -0.65}, rotationDegrees = {0, 0, 0}, provisional = true}
	rejected("building footprint overflow", "E_PLOT_BOUNDS", function(): () api.PrepareAsset("human_knight", source, root) end)
	c.plotSizeStuds = {14, 14}
	local building, report = api.PrepareAsset("human_knight", source, root)
	assert(report.groundAligned and report.footprintFits and report.simpleCollisionPresent)
	local anchor = building:FindFirstChild("AssetRoot")
	assert(anchor and anchor:FindFirstChild("SpawnPoint") and building:FindFirstChild("ExitMarker"))
	local collider = building:FindFirstChild("SimpleCollision")
	assert(collider and collider:IsA("BasePart") and collider.CanCollide)
	assert(api.ResetTest(root) == 1)
	table.insert(cases, "building normalization/box/SpawnPoint/ExitMarker on reused knight geometry fixture only")
	return true
end)
for key in c :: any do (c :: any)[key] = nil end
for key, value in originalConfig :: any do (c :: any)[key] = value end
assert(fixtureOK, tostring(fixtureFailure))
local selection = game:GetService("Selection")
local previousSelection = selection:Get()
selection:Set({source})
local unit, report = api.PrepareAsset("human_knight", nil, root)
selection:Set(previousSelection)
table.insert(cases, "Selection fallback uses the actual selected original")
local anchor = unit:FindFirstChild("AssetRoot")
assert(anchor)
for _, name in {"RightHand", "LeftHand", "Back", "Head", "Root"} do
	local slot = anchor:FindFirstChild(name)
	assert(slot and slot:IsA("Attachment") and slot:GetAttribute("ProvisionalNotRig"))
end
api.PlaceEquipment("human_knight", "Sword", nil, root)
api.PlaceEquipment("human_knight", "Shield", nil, root)
report = api.CheckAsset("human_knight", root)
assert(math.abs(report.height - 5) < 0.002 and report.groundAligned and report.unsafeVisualParts == 0)
assert(report.equipmentVisualParts == 10 and report.unsafeEquipmentParts == 0)
assert(report.triangleCount == 1576 and report.overTriangleBudget and report.validationStatus == "requiring_manual_review")
for _, child in unit:GetDescendants() do assert(not child:IsA("Bone") and not child:IsA("Motor6D") and not child:IsA("Humanoid")) end
safety.AssertUnchanged(originals)
safety.AssertUnchanged(gearBefore)
safety.AssertUnchanged(shieldBefore)
table.insert(cases, "five provisional Attachments, equipment clones, no rig, original transforms/IDs unchanged")
api.ViewAngle(root)
local sceneSettings = config.Scene()
for _, name in {"Light_1", "Light_2"} do
	local lamp = root:FindFirstChild(name)
	local light = if lamp then lamp:FindFirstChildWhichIsA("PointLight") else nil
	if light then
		light.Brightness = sceneSettings.lightBrightness
		light.Range = sceneSettings.lightRange
	end
end
return game:GetService("HttpService"):JSONEncode({passed = #cases, cases = cases, report = report,
	buildingFixtureWasNotBuildingImport = true, noPaidCalls = true, originalsPreserved = true})
