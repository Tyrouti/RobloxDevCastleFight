--!strict
local Types=require(script.Parent.Types)
local Config=require(script.Parent.Config.CombatConfig)
local CombatMath={}
local function validate(baseDamage: number): ()
	assert(baseDamage==baseDamage and baseDamage>=0 and baseDamage<math.huge,"E_DAMAGE_AMOUNT")
end
function CombatMath.UnitDamage(baseDamage: number,damageType: Types.DamageType,target: Types.UnitId,outgoingMultiplier: number?): number
	validate(baseDamage)
	local multipliers=Config.incomingDamageMultipliers[target]; assert(multipliers,"E_DAMAGE_TARGET")
	local multiplier=multipliers[damageType]; assert(multiplier,"E_DAMAGE_TYPE")
	-- baseDamage already contains the source building's level bonus. Do not apply it twice.
	return baseDamage*multiplier*(outgoingMultiplier or 1)
end
function CombatMath.CastleDamage(baseDamage: number,attacker: Types.UnitId,outgoingMultiplier: number?): number
	validate(baseDamage)
	local style=Config.attackStyles[attacker]; assert(style,"E_ATTACK_STYLE")
	return baseDamage*(outgoingMultiplier or 1)*(if style=="Melee" then Config.unitCombat.meleeCastleDamageMultiplier else Config.unitCombat.rangedCastleDamageMultiplier)
end
return table.freeze(CombatMath)
