--!strict
local Types = require(script.Parent.Parent.Types)
local incomingDamageMultipliers: { [Types.UnitId]: Types.DamageMultipliers } = {
 Knight = { Physical = 1, Magical = 0.75 },
 Archer = { Physical = 1, Magical = 1 },
 Mage = { Physical = 1, Magical = 1 },
 Giant = { Physical = 0.65, Magical = 1.35 },
 SkeletonArcher = { Physical = 1, Magical = 1 },
 Necromancer = { Physical = 1, Magical = 1 },
}
for _, multipliers in incomingDamageMultipliers do
 table.freeze(multipliers)
end
local attackStyles: { [Types.UnitId]: string } = {
 Knight="Melee", Giant="Melee", Archer="Arrow", SkeletonArcher="Arrow", Mage="Magic", Necromancer="Magic",
}
return table.freeze({
 incomingDamageMultipliers = table.freeze(incomingDamageMultipliers),
 attackStyles = table.freeze(attackStyles),
 unitCombat = table.freeze({
  searchIntervalSeconds = 0.1,
  deathVisualSeconds = 0.6,
  meleeCastleDamageMultiplier = 1,
  rangedCastleDamageMultiplier = 0.65,
  projectileSpeedStudsPerSecond = 70,
  hitFlashSeconds = 0.1,
 }),
 sword = table.freeze({
  damage = 10,
  damageType = "Physical" :: Types.DamageType,
  cooldownSeconds = 1.5,
  maxRangeStuds = 7,
  maxTargetsPerSwing = 1,
  requirePlayerInOwnTerritory = true,
  requireTargetInOwnTerritory = true,
  enemyUnitsOnly = true,
  canHitCastles = false,
  canHitBuildings = false,
  canHitPlayers = false,
  appliesStun = false,
  appliesKnockback = false,
 }),
})
