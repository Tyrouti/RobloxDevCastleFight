--!strict
-- Pure server-side spatial predicate. No remotes, damage, timers or auto-start.
type FactionId = "Human" | "Undead"
export type MapDefinition = {
	origin: Vector3, size: Vector3, humanBoundaryX: number, undeadBoundaryX: number,
}
export type Territory = "HumanTerritory" | "NeutralZone" | "UndeadTerritory" | "Outside"

local TerritoryService = {}
local function finite(value: number): boolean
	return value == value and math.abs(value) < math.huge
end

local function getTerritory(Config: MapDefinition, position: Vector3): Territory
	local p = position - Config.origin
	if not (finite(p.X) and finite(p.Y) and finite(p.Z)) then return "Outside" end
	-- Territory is an XZ prism. Height/reach/life/cooldown belong to future SwordService.
	if math.abs(p.X) > Config.size.X / 2 or math.abs(p.Z) > Config.size.Z / 2 then return "Outside" end
	if p.X < Config.humanBoundaryX then return "HumanTerritory" end
	if p.X > Config.undeadBoundaryX then return "UndeadTerritory" end
	return "NeutralZone"
end

local function isOwnTerritory(Config: MapDefinition, faction: FactionId, position: Vector3): boolean
	local territory = getTerritory(Config, position)
	return (faction == "Human" and territory == "HumanTerritory")
		or (faction == "Undead" and territory == "UndeadTerritory")
end

local function canUseSwordOnUnit(Config: MapDefinition,
	playerFaction: FactionId, unitFaction: FactionId, playerPosition: Vector3, unitPosition: Vector3): boolean
	if not ((playerFaction == "Human" and unitFaction == "Undead")
		or (playerFaction == "Undead" and unitFaction == "Human")) then return false end
	return isOwnTerritory(Config, playerFaction, playerPosition)
		and isOwnTerritory(Config, playerFaction, unitPosition)
end

function TerritoryService.new(config: MapDefinition)
	assert(config.humanBoundaryX < config.undeadBoundaryX, "E_TERRITORY_BOUNDS")
	-- Snapshot the small immutable dependency; callers cannot move boundaries after Init.
	local Config = table.freeze(table.clone(config))
	return table.freeze({
		GetTerritory = function(position: Vector3): Territory return getTerritory(Config,position) end,
		IsOwnTerritory = function(faction: FactionId,position: Vector3): boolean return isOwnTerritory(Config,faction,position) end,
		CanUseSwordOnUnit = function(playerFaction: FactionId,unitFaction: FactionId,playerPosition: Vector3,unitPosition: Vector3): boolean
			return canUseSwordOnUnit(Config,playerFaction,unitFaction,playerPosition,unitPosition)
		end,
	})
end

return table.freeze(TerritoryService)
