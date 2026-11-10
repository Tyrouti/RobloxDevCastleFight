--!strict
local Shared=game.ReplicatedStorage.CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.EffectConfig)
local Levels=require(Shared.Config.BuildingLevels)
local Math=require(Shared.CombatMath)
local Units=require(script.Parent.UnitService)
local Buildings=require(script.Parent.BuildingService)
local Match=require(script.Parent.MatchService)
export type Kind="Shield" | "Curse" | "DamageOverTime"
type Entry={kind: Kind,expires: number,nextTick: number,power: number,sourceId: string?}
export type Message={kind: string,effect: Kind,action: string,targetModel: Model}
export type Service={Step: () -> (),SyncBuildings: () -> (),Clear: () -> (),Remove: (string) -> (),
 Apply: (string,Kind,number,string?) -> boolean,Absorb: (string,number) -> number,Outgoing: (string) -> number,
 OnAttack: (Units.Data,Units.Data) -> (),Has: (string,Kind) -> boolean,GetSnapshot: () -> any}
local Effects={}
function Effects.new(units: Units.Service,buildings: Buildings.Service,match: Match.Match,clock: () -> number,send: (Message) -> ()): Service
 local records: {[string]:{[string]:Entry}}={}
 local schedules: {[string]:{record: Buildings.Record,due: number}}={}
 local ticks=0;local applications=0;local absorbed=0;local eventErrors=0;local periodicKills=0
 local api={} :: Service
 local function publish(id: string,entry: Entry,action: string): ()
  local unit=units.GetUnit(id);if not unit then return end
  local active=action=="Applied" or action=="Updated"
  unit.model:SetAttribute("Effect"..entry.kind,if active then workspace:GetServerTimeNow()+math.max(0,entry.expires-clock()) else nil)
  if entry.kind=="Shield" then unit.model:SetAttribute("ShieldRemaining",if active then entry.power else nil) end
  local ok=pcall(send,{kind="StatusEffect",effect=entry.kind,action=action,targetModel=unit.model});if not ok then eventErrors+=1 end
 end
 local function removeKind(id: string,kind: Kind,action: string): ()
  local row=records[id];local entry=if row then row[kind] else nil;if not entry then return end
  row[kind]=nil;publish(id,entry,action);if next(row)==nil then records[id]=nil end
 end
 function api.Remove(id: string): () for _,kind in {"Shield","Curse","DamageOverTime"} do removeKind(id,kind :: Kind,"Removed") end end
 function api.Clear(): ()
  local ids={};for id in records do table.insert(ids,id) end;for _,id in ids do api.Remove(id) end;table.clear(schedules)
  ticks=0;applications=0;absorbed=0;periodicKills=0
 end
 function api.Has(id: string,kind: Kind): boolean local row=records[id];local e=if row then row[kind] else nil;return e~=nil and e.expires>clock() end
 function api.Apply(id: string,kind: Kind,power: number,sourceId: string?): boolean
  if match.GetStatus()~="InProgress" or power<=0 or power~=power or power==math.huge then return false end
  local unit=units.GetUnit(id);if not unit or unit.hp<=0 then return false end
  if kind=="Shield" and api.Has(id,kind) then return false end
  local now=clock();local row=records[id] or {};records[id]=row
  local old=row[kind];if old and old.expires<=now then removeKind(id,kind,"Expired");row=records[id] or {};records[id]=row;old=nil end
  local duration=if kind=="Shield" then Config.shieldDuration elseif kind=="Curse" then Config.curseDuration else Config.necromancerDuration
  local e: Entry={kind=kind,power=power,sourceId=sourceId,expires=now+duration,nextTick=if old then old.nextTick else now+Config.tickSeconds}
  row[kind]=e;applications+=1;publish(id,e,if old then "Updated" else "Applied");return true
 end
 function api.Absorb(id: string,damage: number): number
  if not api.Has(id,"Shield") then return damage end
  local e=records[id].Shield;local amount=math.min(damage,e.power);e.power-=amount;absorbed+=amount
  if e.power<=0 then removeKind(id,"Shield","Broken") else local u=units.GetUnit(id);if u then u.model:SetAttribute("ShieldRemaining",e.power) end end
  return damage-amount
 end
 function api.Outgoing(id: string): number return if api.Has(id,"Curse") then Config.curseOutgoingMultiplier else 1 end
 function api.OnAttack(attacker: Units.Data,target: Units.Data): ()
  if attacker.unitId=="Necromancer" then api.Apply(target.instanceId,"DamageOverTime",Config.necromancerTickDamage,attacker.instanceId) end
 end
 function api.SyncBuildings(): ()
  if match.GetStatus()~="InProgress" then table.clear(schedules);return end
  local present: {[string]:boolean}={}
  for _,faction in {"Human","Undead"} do for _,r in buildings.GetBuildingsForFaction(faction :: Types.FactionId) do
   local stats=Levels.Snapshot(r.buildingId,r.level);if stats.kind~="Passive" then continue end
   present[r.instanceId]=true;local s=schedules[r.instanceId]
   if s then s.record=r else schedules[r.instanceId]={record=r,due=clock()+(stats.effectIntervalSeconds :: number)} end
  end end
  for id in schedules do if not present[id] then schedules[id]=nil end end
 end
 function api.Step(): ()
  if match.GetStatus()~="InProgress" then return end
  local now=clock();local ids={};for id in records do table.insert(ids,id) end;table.sort(ids)
  for _,id in ids do
   local unit=units.GetUnit(id);if not unit or unit.hp<=0 then api.Remove(id);continue end
   for _,kind in {"Curse","DamageOverTime","Shield"} do
    local row=records[id];local e=if row then row[kind] else nil;if not e then continue end
    if kind~="Shield" then
     -- At most the configured lifetime's ticks, even after a long frame; advance before damage.
     while e.nextTick<=math.min(now,e.expires) do
      e.nextTick+=Config.tickSeconds;ticks+=1
      local multiplier=if e.sourceId then api.Outgoing(e.sourceId) else 1
      local _,died=units.ApplyDamage(id,Math.UnitDamage(e.power,"Magical",unit.unitId,multiplier));if died then periodicKills+=1 end
      local current=units.GetUnit(id);if not current or current.hp<=0 then break end
     end
    end
    if now>=e.expires then removeKind(id,e.kind,"Expired") end
   end
  end
  api.SyncBuildings();local order={};for id in schedules do table.insert(order,id) end;table.sort(order)
  for _,id in order do
   local s=schedules[id];if now<s.due then continue end
   local r=s.record;local stats=Levels.Snapshot(r.buildingId,r.level);s.due=now+(stats.effectIntervalSeconds :: number)
   local kind: Kind=if stats.effectKind=="Shield" then "Shield" else "Curse"
   local target: Units.Data?=nil;local progress=-math.huge
   for _,u in units.GetUnits() do
    if u.hp<=0 or u.laneId~=r.laneId or (if kind=="Shield" then u.faction~=r.faction or api.Has(u.instanceId,"Shield") else u.faction==r.faction) then continue end
    local p=if u.faction=="Human" then u.position.X else -u.position.X
    if p>progress or (p==progress and target and u.instanceId<target.instanceId) then target=u;progress=p end
   end
   if target then api.Apply(target.instanceId,kind,if kind=="Shield" then stats.shieldHealth :: number else stats.curseDamage :: number,nil) end
  end
 end
 function api.GetSnapshot(): any
  local list={};local count=0;for id,row in records do for _,e in row do count+=1;table.insert(list,{id=id,kind=e.kind,power=e.power,expires=e.expires,nextTick=e.nextTick}) end end
  local scheduleCount=0;for _ in schedules do scheduleCount+=1 end
  return {active=count,records=list,schedules=scheduleCount,ticks=ticks,applications=applications,absorbed=absorbed,eventErrors=eventErrors,periodicKills=periodicKills,perUnitThreads=0}
 end
 units.SetEffectHooks(api.Absorb,api.Remove)
 return table.freeze(api)
end
return table.freeze(Effects)
