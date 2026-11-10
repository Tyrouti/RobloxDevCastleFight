--!strict
local Types = require(script.Parent.Types)
type AssetConfig = Types.AssetConfig
local Safety = require(script.Parent.Safety)
local Config = require(script.Parent.Config)
local Equipment = {}

function Equipment.Register(root: Model, kind: string, source: Instance): Model
	Safety.Guard(root)
	local settings = Config.Equipment(kind)
	local folder = Safety.Folder(root, "EquipmentTemplates")
	assert(not folder:FindFirstChild(kind), "E_DUPLICATE_TEMPLATE: " .. kind)
	assert(not source:IsDescendantOf(root), "E_TEMPLATE_SOURCE: choose an external original")
	local original = Safety.Snapshot(Safety.Parts(source, 64))
	local copy = Safety.CloneModel(source, kind)
	local grip = copy:FindFirstChild(settings.gripName, true)
	assert(grip and grip:IsA("BasePart"), "E_GRIP_MISSING: " .. settings.gripName)
	copy.PrimaryPart = grip
	Safety.Visual(Safety.Parts(copy, 64))
	-- Templates are stored away from the display; original equipment is never moved.
	Safety.AssertUnchanged(original)
	for _, p in Safety.Parts(copy, 64) do
		p:SetAttribute("TemplateTransparency", p.Transparency)
		p.Transparency = 1
	end
	Safety.Publish(copy, folder)
	return copy
end

function Equipment.Place(root: Model, asset: Model, c: AssetConfig, kind: string,
	offsetOverride: CFrame?): Model
	Safety.Guard(root)
	assert(asset.Parent == Safety.Folder(root, "Prepared") and asset:GetAttribute("PipelineOwner") == Safety.OWNER, "E_ASSET_OWNER")
	assert(c.assetType == "unit", "E_EQUIPMENT_UNIT_ONLY")
	local settings = Config.Equipment(kind)
	local rootPart = asset:FindFirstChild("AssetRoot")
	assert(rootPart and rootPart:IsA("BasePart"), "E_ASSET_ROOT")
	local slot = rootPart:FindFirstChild(settings.slot)
	assert(slot and slot:IsA("Attachment"), "E_SLOT_MISSING: " .. settings.slot)
	local folder = Safety.Folder(asset, "Equipment")
	assert(not folder:FindFirstChild(kind), "E_DUPLICATE_EQUIPMENT: " .. kind)
	local template = Safety.Folder(root, "EquipmentTemplates"):FindFirstChild(kind)
	assert(template and template:IsA("Model"), "E_EQUIPMENT_SOURCE_MISSING: register " .. kind)
	local height = c.targetHeightStuds ; assert(height, "E_TARGET_HEIGHT_TODO")
	local copy = template:Clone()
	copy.Name = kind
	copy:ScaleTo(copy:GetScale() * height / settings.referenceHeightStuds)
	for _, p in Safety.Parts(copy, 64) do
		-- Templates use a separate saved transparency attribute, not destructive texture replacement.
		local alpha = p:GetAttribute("TemplateTransparency")
		p.Transparency = if typeof(alpha) == "number" then alpha else 0
	end
	local pose = offsetOverride or Safety.Pose(settings.offset, settings.rotationDegrees)
	copy:PivotTo(slot.WorldCFrame * pose)
	Safety.Visual(Safety.Parts(copy, 64))
	copy:SetAttribute("PipelineOwner", Safety.OWNER)
	copy:SetAttribute("PlacementMode", "static_provisional_not_animation_verified")
	Safety.Publish(copy, folder)
	return copy
end
return Equipment
