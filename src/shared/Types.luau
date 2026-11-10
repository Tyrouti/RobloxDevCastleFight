--!strict
export type FactionId = "Human" | "Undead"
export type LaneId = "Upper" | "Lower"
export type DamageType = "Physical" | "Magical"
export type UnitId = "Knight" | "Archer" | "Mage" | "Giant" | "SkeletonArcher" | "Necromancer"
export type BuildingId = "KnightBarracks" | "ArcherTower" | "MageAcademy" | "LightSanctuary" | "GiantGraveyard" | "BoneTower" | "NecromancerCrypt" | "CursedObelisk"
export type UnitDefinition = {
 faction: FactionId, health: number, damage: number, damageType: DamageType,
 attackCooldownSeconds: number, attackRangeStuds: number, speedStudsPerSecond: number,
}
export type PassiveEffect = {
 kind: "Shield" | "Curse", intervalSeconds: number, laneOnly: boolean,
 shieldHealth: number?, parameters: { [string]: number }?,
 damageType: DamageType?, periodicDamage: number?,
}
export type BuildingDefinition = {
 faction: FactionId, kind: "Producer" | "Passive", cost: number,
 unitId: UnitId?, spawnIntervalSeconds: number?, effect: PassiveEffect?,
}
export type DamageMultipliers = { Physical: number, Magical: number }
return table.freeze({})
