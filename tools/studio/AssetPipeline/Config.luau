--!strict
local Types = require(script.Parent.Types)
type AssetConfig = Types.AssetConfig
type EquipmentConfig = Types.EquipmentConfig
local data: any = game:GetService("HttpService"):JSONDecode(require(script.Parent.GeneratedConfig))
local Config = {}
local function finite(n: any): boolean return typeof(n) == "number" and n == n and math.abs(n) < math.huge end
local function triple(values: any): boolean
	return typeof(values) == "table" and #values == 3 and finite(values[1]) and finite(values[2]) and finite(values[3])
end
function Config.Validate(c: AssetConfig, ready: boolean?): ()
	assert(typeof(c.assetId) == "string" and string.match(c.assetId, "^[a-z][a-z0-9_]*$"), "E_CONFIG_ID")
	assert(table.find({"unit", "building", "castle", "prop"}, c.assetType), "E_CONFIG_TYPE")
	assert(table.find({"human", "undead", "neutral"}, c.faction), "E_CONFIG_FACTION")
	assert(table.find({"none", "box"}, c.collisionMode), "E_CONFIG_COLLISION")
	assert(finite(c.maxTriangles) and c.maxTriangles > 0 and c.maxTriangles % 1 == 0, "E_CONFIG_TRIANGLES")
	assert(finite(c.maxVisualComponents) and c.maxVisualComponents >= 1 and c.maxVisualComponents <= 128, "E_CONFIG_COMPONENTS")
	assert(table.find({"-Z", "+Z", "-X", "+X"}, c.desiredForwardDirection), "E_CONFIG_FORWARD")
	if c.sourceForwardDirection then assert(table.find({"-Z", "+Z", "-X", "+X"}, c.sourceForwardDirection), "E_CONFIG_SOURCE_FORWARD") end
	if c.assetType == "unit" then
		assert(c.characterCategory and table.find({"humanoid", "skeleton", "giant"}, c.characterCategory), "E_CHARACTER_CATEGORY")
		for _, name in {"RightHand", "LeftHand", "Back", "Head", "Root"} do
			local slot = c.equipmentSlots[name]
			assert(slot and triple(slot.position) and triple(slot.rotationDegrees), "E_SLOT: " .. name)
		end
	end
	if ready then
		assert(c.sourceModelPath and c.sourceModelPath ~= "", "E_SOURCE_MISSING: downloaded model required")
		assert(c.approvedConcept and c.approvedConcept.status == "approved", "E_CONCEPT_NOT_APPROVED")
		assert(finite(c.targetHeightStuds) and (c.targetHeightStuds :: number) > 0 and (c.targetHeightStuds :: number) <= 100, "E_TARGET_HEIGHT_TODO")
	end
end
function Config.Get(assetId: string): AssetConfig
	for _, value in data.assets do
		if value.assetId == assetId then local c = value :: AssetConfig ; Config.Validate(c) ; return c end
	end
	error("E_ASSET_NOT_FOUND: " .. assetId)
end
function Config.Equipment(kind: string): EquipmentConfig
	local value = data.equipment[kind]
	assert(value and table.find({"Sword", "Shield", "Bow", "Staff"}, kind), "E_EQUIPMENT_KIND")
	assert(triple(value.offset) and triple(value.rotationDegrees) and finite(value.referenceHeightStuds) and value.referenceHeightStuds > 0, "E_EQUIPMENT_CONFIG")
	return value :: EquipmentConfig
end
function Config.Scene(): any
	local c = data.scene
	assert(triple(c.origin) and triple(c.padSize) and triple(c.frontCamera) and triple(c.angleCamera), "E_SCENE_CONFIG")
	assert(c.padSize[1] > 0 and c.padSize[2] > 0 and c.padSize[3] > 0, "E_PAD_SIZE")
	assert(finite(c.rulerHeight) and c.rulerHeight >= 1 and c.rulerHeight <= 100 and c.rulerHeight % 1 == 0, "E_RULER_LIMIT")
	assert(finite(c.lightBrightness) and c.lightBrightness >= 0 and c.lightBrightness <= 5, "E_LIGHT_BRIGHTNESS")
	assert(finite(c.lightRange) and c.lightRange >= 1 and c.lightRange <= 100, "E_LIGHT_RANGE")
	return c
end
return Config
