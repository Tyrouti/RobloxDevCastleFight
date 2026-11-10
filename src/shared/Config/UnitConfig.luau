--!strict
local Types = require(script.Parent.Parent.Types)
local units: { [Types.UnitId]: Types.UnitDefinition } = {
 Knight = { faction = "Human", health = 280, damage = 17, damageType = "Physical", attackCooldownSeconds = 1.5, attackRangeStuds = 3, speedStudsPerSecond = 8 },
 Archer = { faction = "Human", health = 100, damage = 14, damageType = "Physical", attackCooldownSeconds = 1.2, attackRangeStuds = 18, speedStudsPerSecond = 9 },
 Mage = { faction = "Human", health = 85, damage = 22, damageType = "Magical", attackCooldownSeconds = 2, attackRangeStuds = 16, speedStudsPerSecond = 8 },
 Giant = { faction = "Undead", health = 255, damage = 19, damageType = "Physical", attackCooldownSeconds = 1.8, attackRangeStuds = 3, speedStudsPerSecond = 8 },
 SkeletonArcher = { faction = "Undead", health = 90, damage = 15, damageType = "Physical", attackCooldownSeconds = 1.3, attackRangeStuds = 17, speedStudsPerSecond = 9 },
 Necromancer = { faction = "Undead", health = 80, damage = 21, damageType = "Magical", attackCooldownSeconds = 2.1, attackRangeStuds = 16, speedStudsPerSecond = 8 },
}
for _, definition in units do
 table.freeze(definition)
end
return table.freeze(units)
