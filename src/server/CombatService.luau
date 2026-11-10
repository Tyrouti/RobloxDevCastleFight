--!strict
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.CombatConfig)
local GameConfig=require(Shared.Config.GameConfig)
local MapConfig=require(Shared.Config.MapConfig)
local Math=require(Shared.CombatMath)
local Units=require(script.Parent.UnitService)
local Match=require(script.Parent.MatchService)
local Contact=require(script.Parent.CrystalContact)
local Effects=require(script.Parent.EffectService)
type Faction=Types.FactionId
type Castle={model: Model,hp: number,targets: {[string]:Vector3},zone: Contact.Zone}
export type Effect={unitId: Types.UnitId,source: Vector3,target: Vector3,targetModel: Model,style: string,damage: number}
export type Snapshot={HumanHP: number,UndeadHP: number,maxHP: number,searchPasses: number,unitHits: number,castleHits: number,kills: number,activeCooldowns: number,effectErrors: number}
export type Service={Step: () -> (),Reset: () -> (),Stop: () -> (),GetSnapshot: () -> Snapshot}
local CombatService={}
local function living(unit: Units.Data): boolean return unit.hp>0 and unit.state~="Dead" end
function CombatService.new(map: Instance,units: Units.Service,match: Match.Match,clock: () -> number,
	onEffect: (Effect) -> (),onCastleChanged: (Faction,number,number) -> (),effects: Effects.Service?): Service
	local castles: {[string]:Castle}={}
	local castleFolder=map:FindFirstChild("Castles"); assert(castleFolder,"E_CASTLES_MISSING")
	for _,faction in {"Human","Undead"} do
		local model=castleFolder:FindFirstChild(faction.."Castle")
		assert(model and model:IsA("Model") and model:GetAttribute("OwnerFaction")==faction,"E_CASTLE_OWNER")
		local targets: {[string]:Vector3}={}
		for _,lane in MapConfig.lanes do local p=model:FindFirstChild(lane.id.."CastleTarget"); assert(p and p:IsA("BasePart"),"E_CASTLE_TARGET"); targets[lane.id]=p.Position end
		castles[faction]={model=model,hp=GameConfig.castleHealth,targets=targets,zone=Contact.Read(model)}
	end
	local nextAttack: {[string]:number}={}; local nextSearch=0
	local searches=0; local unitHits=0; local castleHits=0; local kills=0; local effectErrors=0
	local api={} :: Service
	function api.GetSnapshot(): Snapshot
		local count=0; for _ in nextAttack do count+=1 end
		return {HumanHP=castles.Human.hp,UndeadHP=castles.Undead.hp,maxHP=GameConfig.castleHealth,
			searchPasses=searches,unitHits=unitHits,castleHits=castleHits,kills=kills,activeCooldowns=count,effectErrors=effectErrors}
	end
	function api.Stop(): () table.clear(nextAttack); nextSearch=clock() end
	function api.Reset(): ()
		api.Stop(); searches=0; unitHits=0; castleHits=0; kills=0; effectErrors=0
		for _,faction in {"Human","Undead"} do castles[faction].hp=GameConfig.castleHealth; onCastleChanged(faction :: Faction,GameConfig.castleHealth,GameConfig.castleHealth) end
	end
	local function effect(attacker: Units.Data,target: Vector3,model: Model,damage: number): ()
		local message: Effect={unitId=attacker.unitId,source=attacker.position+Vector3.new(0,2.5,0),target=target+Vector3.new(0,2.5,0),
			targetModel=model,style=Config.attackStyles[attacker.unitId],damage=damage}
		local ok=pcall(function(): () onEffect(message) end); if not ok then effectErrors+=1 end
	end
	function api.Step(): ()
		if match.GetStatus()~="InProgress" then return end
		local now=clock(); if now<nextSearch then return end
		nextSearch=now+Config.unitCombat.searchIntervalSeconds; searches+=1
		local all=units.GetUnits(); table.sort(all,function(a: Units.Data,b: Units.Data): boolean return a.instanceId<b.instanceId end)
		local present: {[string]:boolean}={}; local aliveThisTick: {[string]:boolean}={}; local castleDamage: {[string]:number}={Human=0,Undead=0}
		for _,unit in all do aliveThisTick[unit.instanceId]=living(unit) end
		for _,snapshot in all do
			local attacker=units.GetUnit(snapshot.instanceId)
			if not attacker or not living(attacker) then continue end
			present[attacker.instanceId]=true
			local nearest: Units.Data?=nil; local distance=math.huge
			for _,candidate in all do
				if candidate.faction==attacker.faction or candidate.laneId~=attacker.laneId then continue end
				if not aliveThisTick[candidate.instanceId] then continue end
				local d=(candidate.position-attacker.position).Magnitude
				if d<=attacker.stats.attackRangeStuds and (d<distance or (d==distance and nearest and candidate.instanceId<nearest.instanceId)) then nearest=candidate; distance=d end
			end
			if nearest then
				local current=units.GetUnit(nearest.instanceId)
				if not current or not living(current) then units.SetCombatState(attacker.instanceId,false,nil); continue end
				nearest=current
				units.SetCombatState(attacker.instanceId,true,nearest.position); attacker.model:SetAttribute("TargetId",nearest.instanceId)
				if now>=(nextAttack[attacker.instanceId] or 0) then
					-- Record the cooldown before damage/effect notifications. No catch-up attack bursts.
					nextAttack[attacker.instanceId]=now+attacker.stats.attackCooldownSeconds
					local damage=Math.UnitDamage(attacker.stats.damage,attacker.stats.damageType,nearest.unitId,if effects then effects.Outgoing(attacker.instanceId) else 1)
					local loss,died=units.ApplyDamage(nearest.instanceId,damage)
                    if effects then effects.OnAttack(attacker,nearest) end
					if loss>0 then unitHits+=1; if died then kills+=1; aliveThisTick[nearest.instanceId]=false end; effect(attacker,nearest.position,nearest.model,loss) end
				end
			else
				local enemy=if attacker.faction=="Human" then "Undead" else "Human"
				local castle=castles[enemy]; local target=castle.targets[attacker.laneId]
				if attacker.reachedCastle and castle.hp>0 and Contact.CanAttack(castle.zone,attacker.position,attacker.radius,attacker.height,attacker.faction,attacker.laneId) then
					target=Contact.Surface(castle.zone,attacker.position)
					units.SetCombatState(attacker.instanceId,true,target); attacker.model:SetAttribute("TargetId",enemy.."Castle")
					if now>=(nextAttack[attacker.instanceId] or 0) then
						nextAttack[attacker.instanceId]=now+attacker.stats.attackCooldownSeconds
						local damage=Math.CastleDamage(attacker.stats.damage,attacker.unitId,if effects then effects.Outgoing(attacker.instanceId) else 1)
						castleDamage[enemy]+=damage; castleHits+=1; effect(attacker,target,castle.model,damage)
					end
				else units.SetCombatState(attacker.instanceId,false,nil); attacker.model:SetAttribute("TargetId",nil) end
			end
		end
		for id in nextAttack do local u=units.GetUnit(id); if not present[id] or not u or not living(u) then nextAttack[id]=nil end end
		-- Both lanes share one HP pool. Resolve all castle hits in this tick before finishing.
		for _,faction in {"Human","Undead"} do
			local castle=castles[faction]
			if castleDamage[faction]>0 then castle.hp=math.max(0,castle.hp-castleDamage[faction]); onCastleChanged(faction :: Faction,castle.hp,GameConfig.castleHealth) end
		end
		if castles.Human.hp<=0 and castles.Undead.hp<=0 then match.Finish(nil,"Draw")
		elseif castles.Human.hp<=0 then match.Finish("Undead","CastleDestroyed")
		elseif castles.Undead.hp<=0 then match.Finish("Human","CastleDestroyed") end
	end
	api.Reset(); return table.freeze(api)
end
return table.freeze(CombatService)
