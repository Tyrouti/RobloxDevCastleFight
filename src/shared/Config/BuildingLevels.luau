--!strict
-- Pure, fresh snapshots: spawners copy these at spawn time, never mutate living units.
local Types=require(script.Parent.Parent.Types)
local Config=require(script.Parent.GameConfig)
local Definitions=require(script.Parent.BuildingConfig)
local Units=require(script.Parent.UnitConfig)
local Effects=require(script.Parent.EffectConfig)
export type Stats={
	level: number,kind: string,unitId: Types.UnitId?,unit: Types.UnitDefinition?,spawnIntervalSeconds: number?,
	effectKind: string?,effectIntervalSeconds: number?,shieldHealth: number?,curseDamage: number?,
	curseDamageMultiplier: number?,curseDamageType: Types.DamageType?,requiresManualConfiguration: boolean,
}
local Levels={}
function Levels.RoundUpgradeGold(amount: number): number
	assert(Config.upgradeGoldRounding=="NearestHalfUp","E_ROUNDING_POLICY")
	return math.floor(amount+.5)
end
function Levels.UpgradeCost(buildingId: Types.BuildingId): number
	return Levels.RoundUpgradeGold(Definitions[buildingId].cost*Config.upgradeCostFraction)
end
function Levels.Refund(totalSpent: number): number return totalSpent*Config.sellRefundFraction end
function Levels.Snapshot(buildingId: Types.BuildingId,level: number): Stats
	assert(level==1 or level==Config.maxBuildingLevel,"E_BUILDING_LEVEL")
	local definition=Definitions[buildingId]
	local upgraded=level==Config.maxBuildingLevel
	local stats: Stats={level=level,kind=definition.kind,requiresManualConfiguration=false}
	local unitId=definition.unitId
	if unitId then
		local unit=table.clone(Units[unitId :: Types.UnitId])
		unit.health*=if upgraded then Config.levelTwoUnitHealthMultiplier else 1
		unit.damage*=if upgraded then Config.levelTwoUnitDamageMultiplier else 1
		stats.unitId=unitId :: Types.UnitId; stats.unit=table.freeze(unit)
		stats.spawnIntervalSeconds=math.max(Config.minimumProductionIntervalSeconds,(definition.spawnIntervalSeconds :: number)*(if upgraded then Config.levelTwoSpawnIntervalMultiplier else 1))
	else
		local effect=definition.effect; assert(effect,"E_EFFECT_CONFIG")
		local multiplier=if upgraded then Config.levelTwoPassiveStrengthMultiplier else 1
		stats.effectKind=effect.kind; stats.effectIntervalSeconds=effect.intervalSeconds
		if effect.kind=="Shield" then stats.shieldHealth=(effect.shieldHealth :: number)*multiplier
		else
			stats.curseDamageMultiplier=multiplier; stats.curseDamageType=effect.damageType
			stats.curseDamage=if effect.periodicDamage then effect.periodicDamage*multiplier else nil
			stats.requiresManualConfiguration=effect.periodicDamage==nil
		end
	end
	return table.freeze(stats)
end
function Levels.Describe(stats: Stats): string
	local unit=stats.unit
	if unit then return string.format("%s: HP %g · damage %g\nInterval: %g s",tostring(stats.unitId),unit.health,unit.damage,stats.spawnIntervalSeconds :: number) end
	if stats.effectKind=="Shield" then return string.format("Shield: %g HP for %g s\nEffect interval: %g s",stats.shieldHealth :: number,Effects.shieldDuration,stats.effectIntervalSeconds :: number) end
	return string.format("Curse: %g Magical/s for %g s\nTarget outgoing damage −%g%%\nInterval: %g s",stats.curseDamage :: number,Effects.curseDuration,(1-Effects.curseOutgoingMultiplier)*100,stats.effectIntervalSeconds :: number)
end
return table.freeze(Levels)
