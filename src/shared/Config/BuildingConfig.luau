--!strict
local Types = require(script.Parent.Parent.Types)
local buildings: { [Types.BuildingId]: Types.BuildingDefinition } = {
 KnightBarracks = { faction = "Human", kind = "Producer", cost = 260, unitId = "Knight", spawnIntervalSeconds = 26 },
 ArcherTower = { faction = "Human", kind = "Producer", cost = 190, unitId = "Archer", spawnIntervalSeconds = 22 },
 MageAcademy = { faction = "Human", kind = "Producer", cost = 250, unitId = "Mage", spawnIntervalSeconds = 27 },
 LightSanctuary = { faction = "Human", kind = "Passive", cost = 230, effect = { kind = "Shield", intervalSeconds = 7, laneOnly = true, shieldHealth = 45 } },
 GiantGraveyard = { faction = "Undead", kind = "Producer", cost = 260, unitId = "Giant", spawnIntervalSeconds = 30 },
 BoneTower = { faction = "Undead", kind = "Producer", cost = 190, unitId = "SkeletonArcher", spawnIntervalSeconds = 24 },
 NecromancerCrypt = { faction = "Undead", kind = "Producer", cost = 250, unitId = "Necromancer", spawnIntervalSeconds = 28 },
 CursedObelisk = { faction = "Undead", kind = "Passive", cost = 200, effect = { kind = "Curse", intervalSeconds = 8, laneOnly = true, damageType = "Magical", periodicDamage = 6, parameters = nil } },
}
for _, definition in buildings do
 local effect = definition.effect
 if effect then
  table.freeze(effect)
 end
 table.freeze(definition)
end
return table.freeze(buildings)
