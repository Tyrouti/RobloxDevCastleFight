--!strict
local Safety = require(script.Parent.Safety)
local Config = require(script.Parent.Config)
local Scene = {}

local function block(name: string, size: Vector3, cf: CFrame, color: Color3, collide: boolean): Part
	local p = Instance.new("Part") ; p.Name = name ; p.Size = size ; p.CFrame = cf
	p.Color = color ; p.Material = Enum.Material.SmoothPlastic ; p.Anchored = true
	p.CanCollide = collide ; p.CanTouch = false ; p.CanQuery = collide
	return p
end
function Scene.CreateTestScene(): Model
	Safety.Edit()
	local existing = workspace:FindFirstChild("AssetVisualTest")
	if existing then assert(existing:IsA("Model"), "E_SCENE_DUPLICATE") ; Safety.Guard(existing) ; return existing end
	local legacy = workspace:FindFirstChild("KnightVisualTest")
	local bootstrap = workspace:FindFirstChild("AssetVisualTestBootstrap")
	local allowedLegacy = legacy and legacy:FindFirstChild("SceneId")
	assert((allowedLegacy and allowedLegacy:IsA("StringValue") and allowedLegacy.Value == "castlefight.knight-visual-test.v1")
		or (bootstrap and bootstrap:IsA("StringValue") and bootstrap.Value == Safety.SCENE_ID), "E_CONTEXT: use a test place, not the game map")
	assert(game.PlaceId ~= 101102700433907, "E_MAIN_MAP: creation refused")
	local c = Config.Scene()
	local origin = CFrame.new(Safety.Vector(c.origin))
	local root = Instance.new("Model") ; root.Name = "AssetVisualTest"
	root:SetAttribute("PipelineOwner", Safety.OWNER)
	local id = Instance.new("StringValue") ; id.Name = "SceneId" ; id.Value = Safety.SCENE_ID ; id.Parent = root
	for _, name in {"Prepared", "Archive", "EquipmentTemplates"} do local f = Instance.new("Folder") ; f.Name = name ; f.Parent = root end
	block("Ground", Vector3.new(28, 0.5, 26), origin * CFrame.new(0, -0.25, 0), Color3.fromRGB(95, 100, 106), true).Parent = root
	block("BuildPlot", Safety.Vector(c.padSize), origin * CFrame.new(0, c.padSize[2] / 2, 0), Color3.fromRGB(145, 148, 152), true).Parent = root
	for i = 0, c.rulerHeight do
		block("HeightTick_" .. i, Vector3.new(0.4, 0.03, 0.1), origin * CFrame.new(-9, c.padSize[2] + i, 0), Color3.new(0.9, 0.9, 0.9), false).Parent = root
	end
	block("Ruler", Vector3.new(0.06, c.rulerHeight, 0.06), origin * CFrame.new(-9, c.padSize[2] + c.rulerHeight / 2, 0), Color3.new(0.9, 0.9, 0.9), false).Parent = root
	-- Local white lights do not change the user's existing global Lighting or old stand.
	for index, offset in {Vector3.new(-8, 10, -8), Vector3.new(8, 10, 4)} do
		local lamp = block("Light_" .. index, Vector3.new(0.2, 0.2, 0.2), origin + offset, Color3.new(1, 1, 1), false)
		lamp.Transparency = 1
		local light = Instance.new("PointLight") ; light.Color = Color3.new(1, 1, 1) ; light.Brightness = c.lightBrightness ; light.Range = c.lightRange ; light.Parent = lamp
		lamp.Parent = root
	end
	Safety.Publish(root, workspace)
	return root
end
function Scene.View(root: Model, angle: boolean): ()
	Safety.Guard(root)
	local pad = root:FindFirstChild("BuildPlot") ; assert(pad and pad:IsA("BasePart"), "E_PLOT")
	local camera = workspace.CurrentCamera ; assert(camera, "E_CAMERA")
	local c = Config.Scene()
	local offset = Safety.Vector(if angle then c.angleCamera else c.frontCamera)
	camera.CFrame = CFrame.lookAt(pad.Position + offset, pad.Position + Vector3.new(0, 2.5, 0))
end
function Scene.ResetTest(root: Model): number
	Safety.Guard(root)
	local prepared, archive = Safety.Folder(root, "Prepared"), Safety.Folder(root, "Archive")
	local objects = prepared:GetChildren()
	for _, item in objects do assert(item:GetAttribute("PipelineOwner") == Safety.OWNER, "E_FOREIGN_OBJECT: reset refused") end
	if #objects == 0 then return 0 end
	local storage = game:GetService("ServerStorage")
	local vault = storage:FindFirstChild("CastleFightAssetArchive")
	if vault then
		assert(vault:IsA("Folder") and vault:GetAttribute("PipelineOwner") == Safety.OWNER, "E_FOREIGN_ARCHIVE")
	else
		local created = Instance.new("Folder")
		created.Name = "CastleFightAssetArchive"
		created:SetAttribute("PipelineOwner", Safety.OWNER)
		Safety.Publish(created, storage)
		vault = created
	end
	local batch = Instance.new("Folder")
	batch.Name = "Reset_" .. game:GetService("HttpService"):GenerateGUID(false)
	Safety.Publish(batch, vault)
	local link = Instance.new("ObjectValue")
	link.Name = batch.Name
	link.Value = batch
	link.Parent = archive
	for _, item in objects do Safety.Publish(item, batch) end
	return #objects
end
return Scene
