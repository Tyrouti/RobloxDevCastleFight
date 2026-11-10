--!strict
local Types = require(script.Parent.Types)
local Core = require(script.Parent.AssetPipeline)
local Scene = require(script.Parent.AssetVisualTest)
local Equipment = require(script.Parent.EquipmentAttachment)
local Config = require(script.Parent.Config)
local Commands = {}
local function scene(explicit: Model?): Model
	if explicit then return explicit end
	local value = workspace:FindFirstChild("AssetVisualTest")
	assert(value and value:IsA("Model"), "E_SCENE_MISSING: call CreateTestScene first")
	return value
end
function Commands.CreateTestScene(): Model return Scene.CreateTestScene() end
function Commands.PrepareAsset(assetId: string, source: Instance?, root: Model?): (Model, Types.Report)
	return Core.PrepareAsset(scene(root), assetId, source)
end
function Commands.CheckAsset(assetId: string, root: Model?): Types.Report
	return Core.CheckAsset(scene(root), assetId)
end
function Commands.RegisterEquipment(kind: string, source: Instance, root: Model?): Model
	return Equipment.Register(scene(root), kind, source)
end
function Commands.PlaceEquipment(assetId: string, kind: string, offset: CFrame?, root: Model?): Model
	local r = scene(root)
	return Equipment.Place(r, Core.Target(r, assetId), Config.Get(assetId), kind, offset)
end
function Commands.ResetTest(root: Model?): number return Scene.ResetTest(scene(root)) end
function Commands.ViewFront(root: Model?): () Scene.View(scene(root), false) end
function Commands.ViewAngle(root: Model?): () Scene.View(scene(root), true) end
return Commands
