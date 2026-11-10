--!strict
local Shared=game.ReplicatedStorage.CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.GameConfig)
local Math=require(Shared.CombatMath)
local Levels=require(Shared.Config.BuildingLevels)
local Economy=require(script.Parent.EconomyService)
local Match=require(script.Parent.MatchService)
local Buildings=require(script.Parent.BuildingService)
local Models=require(script.Parent.BuildingModels)
local Units=require(script.Parent.UnitService)
local UnitModels=require(script.Parent.UnitModels)
local Routes=require(script.Parent.LaneRoutes)
local Combat=require(script.Parent.CombatService)
local Effects=require(script.Parent.EffectService)
local Contact=require(script.Parent.CrystalContact)
local Tests={}
local function fixture(custom: boolean?)
 local pads=workspace.Map.BuildPads:Clone();for _,p in pads:GetChildren() do p:SetAttribute("IsOccupied",false) end
 local active=Instance.new("Folder");active:SetAttribute("SystemOwner","CastleFightBuildings")
 local soldiers=Instance.new("Folder");soldiers:SetAttribute("SystemOwner","CastleFightUnits")
 local e=Economy.new(Config,function(_: Economy.Faction,_: number): () end)
 local now=0;local u: Units.Service?=nil;local b: Buildings.Service?=nil;local fx: Effects.Service?=nil;local c: Combat.Service?=nil
 local m=Match.new(e,function(status: Match.Status,_: number): ()
  if status~="InProgress" then if fx then fx.Clear() end;if c then if status=="Starting" then c.Reset() else c.Stop() end end;if u then u.ClearUnits() end;if b then b.ClearBuildings() end end
 end)
 local build=Buildings.new(pads,active,e,m,Models.Create,function(): () if u then u.SyncBuildings() end;if fx then fx.SyncBuildings() end end);b=build
 local route=Routes.new(workspace.Map)
 if custom then route={CreatePath=function(pad: BasePart,lane: Types.LaneId,faction: Types.FactionId): Routes.Path
  local slot=tonumber(string.sub(pad.Name,-2));assert(slot);local x=(if faction=="Human" then 0 else 10)+(slot-1)*20
  local start=Vector3.new(x,2.15,if lane=="Upper" then -200 else -160)
  return {start=start,points={start,Vector3.new(if faction=="Human" then 96 else -96,2.15,start.Z)},direction=Vector3.new(if faction=="Human" then 1 else -1,0,0)}
 end} end
 local army=Units.new(pads,soldiers,route,build,m,UnitModels.Create,function(): number return now end);u=army
 local messages: {Effects.Message}={}
 local effect=Effects.new(army,build,m,function(): number return now end,function(message: Effects.Message): () table.insert(messages,message) end);fx=effect
 local battle=Combat.new(workspace.Map,army,m,function(): number return now end,function(_: Combat.Effect): () end,function(_: Types.FactionId,_: number,_: number): () end,effect);c=battle
 local function advance(dt: number,fight: boolean?,move: boolean?): () now+=dt;effect.Step();if fight then battle.Step() end;army.Step(if move then dt else 0) end
 local serial=0
 local function buy(faction: Types.FactionId,pad: string,id: Types.BuildingId,level: number?): Buildings.Record
  serial+=1;assert(build.TryBuild(faction,pad,id,"build"..serial,m.GetMatchId()));local r=build.GetBuilding(pad);assert(r)
  if level==2 then assert(build.TryUpgrade(faction,pad,r.instanceId,r.revision,"upgrade"..serial,m.GetMatchId()));r=build.GetBuilding(pad);assert(r) end
  return r
 end
 local function get(pad: string): Units.Data for _,unit in army.GetUnits() do if unit.sourcePadId==pad then return unit end end;error("E_TEST_UNIT:"..pad) end
 local function read(id: string): Units.Data local unit=army.GetUnit(id);assert(unit,"E_TEST_UNIT_MISSING");return unit end
 local function sell(r: Buildings.Record): () assert(build.TrySell(r.faction,r.padId,r.instanceId,r.revision,"sell:"..r.instanceId,m.GetMatchId())) end
 local function destroy(): () m.Finish();pads:Destroy();active:Destroy();soldiers:Destroy() end
 assert(m.Start());assert(e.AddGold("Human",9000,"human",m.GetMatchId()));assert(e.AddGold("Undead",9000,"undead",m.GetMatchId()))
 return {u=army,b=build,m=m,fx=effect,c=battle,e=e,advance=advance,buy=buy,get=get,read=read,sell=sell,destroy=destroy,messages=messages}
end
function Tests.Run(): any
 assert(game:GetService("RunService"):IsStudio(),"E_STUDIO_ONLY")
 local names={};local function check(name: string,ok: boolean): () assert(ok,"FAIL:"..name);table.insert(names,name) end
 local function near(a: number,b: number): boolean return math.abs(a-b)<.0001 end
 do
  local f=fixture(true);f.buy("Human","Human_Upper_01","KnightBarracks");f.buy("Human","Human_Upper_02","ArcherTower");f.buy("Human","Human_Lower_01","KnightBarracks");f.advance(5)
  local knight=f.get("Human_Upper_01");local archer=f.get("Human_Upper_02");local lower=f.get("Human_Lower_01")
  local sanctuary=f.buy("Human","Human_Upper_04","LightSanctuary")
  f.advance(6.999);check("shield not early",not f.fx.Has(archer.instanceId,"Shield"));f.advance(.0011)
  check("most advanced unshielded ally on own lane",f.fx.Has(archer.instanceId,"Shield") and not f.fx.Has(knight.instanceId,"Shield") and not f.fx.Has(lower.instanceId,"Shield"))
  check("shield cannot stack",not f.fx.Apply(archer.instanceId,"Shield",45,nil))
  f.advance(7);check("next activation chooses unshielded ally",f.fx.Has(knight.instanceId,"Shield"))
  f.sell(sanctuary);check("sale removes passive schedule",f.fx.GetSnapshot().schedules==0)
  check("sale preserves applied shield",f.fx.Has(knight.instanceId,"Shield"));f.advance(10);check("shield expires",not f.fx.Has(knight.instanceId,"Shield"))
  f.fx.Apply(knight.instanceId,"Shield",45,nil);local hp=f.read(knight.instanceId).hp
  local loss=f.u.ApplyDamage(knight.instanceId,Math.UnitDamage(20,"Physical","Knight"));check("shield absorbs physical",loss==0 and f.read(knight.instanceId).hp==hp)
  loss=f.u.ApplyDamage(knight.instanceId,Math.UnitDamage(40,"Magical","Knight"));check("resistance before shield",near(loss,5) and not f.fx.Has(knight.instanceId,"Shield"))
  f.fx.Apply(knight.instanceId,"Shield",56.25,nil);loss=f.u.ApplyDamage(knight.instanceId,Math.UnitDamage(80,"Magical","Knight"));check("level two shield exact capacity",near(loss,3.75))
  local upgraded=f.buy("Human","Human_Upper_04","LightSanctuary",2);f.advance(7)
  local found=false;for _,r in f.fx.GetSnapshot().records do if r.kind=="Shield" and near(r.power,56.25) then found=true end end
  check("level two building emits 56.25 shield every seven",found and Levels.Snapshot("LightSanctuary",2).effectIntervalSeconds==7);f.sell(upgraded)
  f.fx.Apply(knight.instanceId,"Curse",6,nil);f.fx.Apply(knight.instanceId,"DamageOverTime",2,nil)
  f.u.ApplyDamage(knight.instanceId,9999);check("death immediately removes all target effects",not f.fx.Has(knight.instanceId,"Curse") and not f.fx.Has(knight.instanceId,"DamageOverTime") and not f.fx.Has(knight.instanceId,"Shield"))
  f.m.Finish();check("Finish clears effects and schedules",f.fx.GetSnapshot().active==0 and f.fx.GetSnapshot().schedules==0)
  f.advance(100);check("no finished ticks",f.fx.GetSnapshot().ticks==0);assert(f.m.Start());check("restart no old effects",f.fx.GetSnapshot().active==0);f.destroy()
 end
 do
  local f=fixture(true);f.buy("Human","Human_Upper_01","KnightBarracks");f.buy("Human","Human_Upper_02","ArcherTower");f.buy("Human","Human_Lower_01","KnightBarracks");f.advance(5)
  local knight=f.get("Human_Upper_01");local archer=f.get("Human_Upper_02");local lower=f.get("Human_Lower_01")
  local obelisk=f.buy("Undead","Undead_Upper_04","CursedObelisk",2);f.advance(8)
  check("curse selects most advanced enemy on own lane",f.fx.Has(archer.instanceId,"Curse") and not f.fx.Has(knight.instanceId,"Curse") and not f.fx.Has(lower.instanceId,"Curse"))
  local hp=f.read(archer.instanceId).hp;f.advance(.999);check("curse no immediate tick",f.read(archer.instanceId).hp==hp);f.advance(.0011)
  check("level two curse tick 7.5",near(hp-f.read(archer.instanceId).hp,7.5))
  check("curse scales outgoing unit damage",near(Math.UnitDamage(14,"Physical","Giant",f.fx.Outgoing(archer.instanceId)),14*.65*.85))
  check("curse scales outgoing castle damage",near(Math.CastleDamage(14,"Archer",f.fx.Outgoing(archer.instanceId)),14*.65*.85))
  f.sell(obelisk);check("sale preserves curse",f.fx.Has(archer.instanceId,"Curse"));f.advance(4)
  check("five ticks then curse expiration",near(hp-f.read(archer.instanceId).hp,37.5) and not f.fx.Has(archer.instanceId,"Curse"))
  f.advance(20);check("sold obelisk never reapplies",not f.fx.Has(archer.instanceId,"Curse"))
  f.fx.Apply(knight.instanceId,"Curse",6,nil);hp=f.read(knight.instanceId).hp;f.advance(1);check("curse magical resistance",near(hp-f.read(knight.instanceId).hp,4.5))
  f.fx.Apply(knight.instanceId,"Curse",6,nil);local count=f.fx.GetSnapshot().active;f.advance(0);check("curse refresh no stack or immediate tick",f.fx.GetSnapshot().active==count and near(hp-f.read(knight.instanceId).hp,4.5))
  f.destroy()
 end
 do
  local f=fixture(true);f.buy("Human","Human_Upper_01","KnightBarracks");f.buy("Undead","Undead_Upper_01","NecromancerCrypt");f.advance(5)
  local knight=f.get("Human_Upper_01");local necro=f.get("Undead_Upper_01");local hp=knight.hp
  f.advance(0,true);check("successful Necromancer attack applies DOT",f.fx.Has(knight.instanceId,"DamageOverTime"))
  check("main Necromancer attack unchanged",near(hp-f.read(knight.instanceId).hp,21*.75))
  hp=f.read(knight.instanceId).hp;f.advance(3);check("three resisted DOT ticks",near(hp-f.read(knight.instanceId).hp,4.5) and not f.fx.Has(knight.instanceId,"DamageOverTime"))
  f.fx.Apply(necro.instanceId,"DamageOverTime",2,nil);hp=f.read(necro.instanceId).hp;f.advance(3);check("DOT total six without resistance",near(hp-f.read(necro.instanceId).hp,6))
  f.fx.Apply(knight.instanceId,"DamageOverTime",2,necro.instanceId);hp=f.read(knight.instanceId).hp;f.advance(1)
  f.fx.Apply(knight.instanceId,"DamageOverTime",2,necro.instanceId);f.advance(0);check("DOT refresh no extra tick",near(hp-f.read(knight.instanceId).hp,1.5))
  f.advance(2.5);check("refresh extends DOT lifetime",f.fx.Has(knight.instanceId,"DamageOverTime"));f.advance(.5)
  check("DOT refresh preserves cadence without stacking",near(hp-f.read(knight.instanceId).hp,6) and not f.fx.Has(knight.instanceId,"DamageOverTime"))
  f.fx.Apply(necro.instanceId,"Curse",6,nil);f.fx.Apply(knight.instanceId,"DamageOverTime",2,necro.instanceId);hp=f.read(knight.instanceId).hp;f.advance(1)
  check("curse scales outgoing periodic damage",near(hp-f.read(knight.instanceId).hp,2*.75*.85))
  local ticks=f.fx.GetSnapshot().ticks;f.advance(0);f.advance(0);check("same timestamp no duplicate ticks",f.fx.GetSnapshot().ticks==ticks)
  check("no per unit effect threads",f.fx.GetSnapshot().perUnitThreads==0);f.destroy()
 end
 do
  local f=fixture(true);local passive=f.buy("Human","Human_Upper_04","LightSanctuary")
  f.advance(7);check("empty lane skips activation",f.fx.GetSnapshot().active==0)
  f.buy("Human","Human_Upper_01","KnightBarracks");f.advance(5);local unit=f.get("Human_Upper_01")
  check("skipped pulse creates no delayed application",not f.fx.Has(unit.instanceId,"Shield"))
  assert(f.b.TryUpgrade("Human",passive.padId,passive.instanceId,passive.revision,"passive-upgrade",f.m.GetMatchId()))
  f.advance(1.999);check("passive upgrade no early pulse",not f.fx.Has(unit.instanceId,"Shield"));f.advance(.0011)
  check("passive upgrade keeps deadline",f.fx.Has(unit.instanceId,"Shield") and near(f.read(unit.instanceId).model:GetAttribute("ShieldRemaining") :: number,56.25))
  check("invalid effect power refused",not f.fx.Apply(unit.instanceId,"Curse",0,nil) and not f.fx.Apply(unit.instanceId,"Curse",0/0,nil))
  check("unknown target refused",not f.fx.Apply("missing","Shield",45,nil))
  f.fx.Apply(unit.instanceId,"Curse",6,nil);f.fx.Apply(unit.instanceId,"DamageOverTime",2,nil)
  f.u.RemoveUnit(unit.instanceId);check("manual removal clears all effects",f.fx.GetSnapshot().active==0)
  f.m.Finish();assert(f.m.Start());assert(f.e.AddGold("Human",1000,"fresh-fund",f.m.GetMatchId()))
  f.buy("Human","Human_Upper_04","LightSanctuary");f.buy("Human","Human_Upper_01","KnightBarracks");f.advance(5)
  unit=f.get("Human_Upper_01");check("restart no old pulse",not f.fx.Has(unit.instanceId,"Shield"));f.advance(2);check("restart fresh passive deadline",f.fx.Has(unit.instanceId,"Shield"));f.destroy()
 end
 do
  local f=fixture(true);f.buy("Human","Human_Upper_01","KnightBarracks");f.buy("Undead","Undead_Upper_01","NecromancerCrypt");f.buy("Undead","Undead_Upper_03","GiantGraveyard");f.advance(5)
  local knight=f.get("Human_Upper_01");local necro=f.get("Undead_Upper_01");local giant=f.get("Undead_Upper_03")
  f.fx.Apply(knight.instanceId,"Shield",45,nil);local hp=knight.hp;f.advance(0,true)
  check("shielded successful attack still applies corruption",f.fx.Has(knight.instanceId,"DamageOverTime") and f.read(knight.instanceId).hp==hp)
  f.fx.Remove(knight.instanceId);f.fx.OnAttack(knight,necro);check("ordinary attack does not apply corruption",not f.fx.Has(necro.instanceId,"DamageOverTime"))
  f.fx.Apply(giant.instanceId,"DamageOverTime",2,nil);hp=f.read(giant.instanceId).hp;f.advance(3)
  check("Giant magical multiplier applies to DOT",near(hp-f.read(giant.instanceId).hp,8.1))
  f.fx.Apply(giant.instanceId,"Shield",5,nil);hp=f.read(giant.instanceId).hp;f.u.ApplyDamage(giant.instanceId,Math.UnitDamage(10,"Magical","Giant"))
  check("vulnerability before shield",near(hp-f.read(giant.instanceId).hp,8.5))
  f.fx.Apply(necro.instanceId,"DamageOverTime",2,nil);hp=f.read(necro.instanceId).hp
  for _=1,6 do f.advance(.5);f.fx.Apply(necro.instanceId,"DamageOverTime",2,nil) end
  check("frequent refresh cannot postpone DOT ticks",near(hp-f.read(necro.instanceId).hp,6))
  f.fx.Remove(necro.instanceId);f.fx.Apply(necro.instanceId,"Curse",6,nil);f.advance(5)
  check("expired curse restores outgoing damage",f.fx.Outgoing(necro.instanceId)==1)
  local expired=false;local removed=false;local broken=false;local updated=false
  for _,message in f.messages do expired=expired or message.action=="Expired";removed=removed or message.action=="Removed";broken=broken or message.action=="Broken";updated=updated or message.action=="Updated" end
  check("expiration event published",expired);check("removal event published",removed);check("shield break event published",broken);check("refresh event published",updated)
  f.u.ApplyDamage(necro.instanceId,f.read(necro.instanceId).hp-1);f.fx.Apply(necro.instanceId,"DamageOverTime",2,nil);f.advance(1)
  check("periodic death uses normal HP and removes effects",f.read(necro.instanceId).hp==0 and not f.fx.Has(necro.instanceId,"DamageOverTime") and f.fx.GetSnapshot().periodicKills==1)
  f.destroy()
 end
 local drawRows=Tests.Draw();check("four castle resolution cases",#drawRows==4)
 local stress=fixture();assert(require(script.Parent.UnitDemo).Create(stress.b,stress.e,stress.m).success)
 for _=1,2500 do if #stress.u.GetUnits()==60 then break end;stress.advance(.25,false,true) end
 check("stress sixty live units",#stress.u.GetUnits()==60)
 for _,u in stress.u.GetUnits() do stress.fx.Apply(u.instanceId,"Shield",56.25,nil);stress.fx.Apply(u.instanceId,"Curse",6,nil);stress.fx.Apply(u.instanceId,"DamageOverTime",2,nil) end
 check("one hundred eighty bounded effect records",stress.fx.GetSnapshot().active==180)
 local began=os.clock();for _=1,100 do stress.advance(.016) end;local milliseconds=(os.clock()-began)*1000/100
 check("sixty remain alive with effects",#stress.u.GetUnits()==60);stress.m.Finish();check("stress cleanup",stress.fx.GetSnapshot().active==0);stress.destroy()
 return {passed=#names,names=names,draw=drawRows,stressUnits=60,stressEffects=180,averageStepMilliseconds=milliseconds}
end
function Tests.Draw(): any
 local rows={}
 for _,kind in {"HumanDestroyed","UndeadDestroyed","SameStep","LaterStep"} do
  -- Test doubles inject lethal packet sizes, never mutate production HP or UnitConfig.
  local e=Economy.new(Config,function(_: Economy.Faction,_: number): () end);local m=Match.new(e,function(_: Match.Status,_: number): () end);assert(m.Start())
  local all: {any}={};local late=false
  for _,faction in {"Human","Undead"} do
   local enemy=if faction=="Human" then "Undead" else "Human";local zone=Contact.Read(workspace.Map.Castles[enemy.."Castle"] :: Model)
   local radius=2;local start=Contact.Stop(zone,Vector3.new(if faction=="Human" then 96 else -96,2.15,-200),Vector3.new(if faction=="Human" then 110 else -110,2.15,-184),radius)
   table.insert(all,{instanceId=faction,unitId=if faction=="Human" then "Knight" else "Giant",faction=faction,laneId="Upper",hp=1,state="Moving",position=start,radius=radius,height=5,reachedCastle=true,model=Instance.new("Model"),stats={damage=1500,attackCooldownSeconds=1,attackRangeStuds=3,damageType="Physical"}})
  end
  local mock={GetUnits=function(): any return all end,GetUnit=function(id: string): any for _,u in all do if u.instanceId==id then return u end end;return nil end,
   SetCombatState=function(_: string,_: boolean,_: Vector3?): boolean return true end,ApplyDamage=function(_: string,_: number): (number,boolean) return 0,false end} :: any
  if kind=="HumanDestroyed" then all[1].reachedCastle=false elseif kind=="UndeadDestroyed" or kind=="LaterStep" then all[2].reachedCastle=false end
  local now=0;local c=Combat.new(workspace.Map,mock,m,function(): number return now end,function(_: Combat.Effect): () end,function(_: Types.FactionId,_: number,_: number): () end)
  c.Step();if kind=="LaterStep" then all[2].reachedCastle=true;now=1;c.Step();late=true end
  local result=m.GetResult();assert(result and m.GetStatus()=="Finished")
  if kind=="SameStep" then assert(result.winner==nil and result.reason=="Draw") else assert(result.winner==(if kind=="HumanDestroyed" then "Undead" else "Human") and result.reason=="CastleDestroyed") end
  table.insert(rows,{case=kind,winner=result.winner,reason=result.reason,laterDamageIgnored=late});for _,u in all do u.model:Destroy() end
 end
 return rows
end
return table.freeze(Tests)
