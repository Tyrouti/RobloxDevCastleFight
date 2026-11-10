--!strict
local Shared=game.ReplicatedStorage.CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.GameConfig)
local Definitions=require(Shared.Config.BuildingConfig)
local Economy=require(script.Parent.EconomyService)
local Match=require(script.Parent.MatchService)
local Buildings=require(script.Parent.BuildingService)
local Models=require(script.Parent.BuildingModels)
local Units=require(script.Parent.UnitService)
local UnitModels=require(script.Parent.UnitModels)
local Routes=require(script.Parent.LaneRoutes)
local Combat=require(script.Parent.CombatService)
local Contact=require(script.Parent.CrystalContact)
local Geometry=require(script.Parent.UnitGeometry)
local Demo=require(script.Parent.UnitDemo)
local Tests={}
local function fixture()
 local pads=workspace.Map.BuildPads:Clone();for _,p in pads:GetChildren() do p:SetAttribute("IsOccupied",false) end
 local active=Instance.new("Folder");active:SetAttribute("SystemOwner","CastleFightBuildings")
 local soldiers=Instance.new("Folder");soldiers:SetAttribute("SystemOwner","CastleFightUnits")
 local e=Economy.new(Config,function(_: Economy.Faction,_: number): () end)
 local now=0;local army: Units.Service?=nil;local buildings: Buildings.Service?=nil;local battle: Combat.Service?=nil
 local m=Match.new(e,function(status: Match.Status,_: number): ()
  if status~="InProgress" then if battle then if status=="Starting" then battle.Reset() else battle.Stop() end end;if army then army.ClearUnits() end;if buildings then buildings.ClearBuildings() end end
 end)
 local b=Buildings.new(pads,active,e,m,Models.Create,function(): () if army then army.SyncBuildings() end end);buildings=b
 local u=Units.new(pads,soldiers,Routes.new(workspace.Map),b,m,UnitModels.Create,function(): number return now end);army=u
 local c=Combat.new(workspace.Map,u,m,function(): number return now end,function(_: Combat.Effect): () end,function(_: Types.FactionId,_: number,_: number): () end);battle=c
 local function step(dt: number,fight: boolean?): () now+=dt;m.Step(dt);if fight~=false then c.Step() end;u.Step(dt) end
 local function destroy(): () m.Finish();u.ClearUnits();b.ClearBuildings();pads:Destroy();active:Destroy();soldiers:Destroy() end
 return {pads=pads,active=active,soldiers=soldiers,e=e,m=m,b=b,u=u,c=c,step=step,destroy=destroy}
end
function Tests.Run(): {cases: number,assertions: number,minGap: number,maxGap: number,stressUnits: number,stressMilliseconds: number,failures: {string}}
 assert(game:GetService("RunService"):IsStudio(),"E_STUDIO_ONLY")
 local result={cases=0,assertions=0,minGap=math.huge,maxGap=0,stressUnits=0,stressMilliseconds=0,failures={} :: {string}}
 local function check(ok: boolean,label: string): () assert(ok,label);result.assertions+=1 end
 for _,pad in workspace.Map.BuildPads:GetChildren() do
  local faction=pad:GetAttribute("OwnerFaction") :: Types.FactionId
  for id,def in Definitions do
   if def.faction~=faction or def.kind~="Producer" then continue end
   local f=fixture()
   local ok,errorMessage=pcall(function(): boolean
    assert(f.m.Start());assert(f.b.TryBuild(faction,pad.Name,id :: Types.BuildingId,"test21",f.m.GetMatchId()))
    local record=f.b.GetBuilding(pad.Name);assert(record)
    local anchor=record.model:FindFirstChild("UnitSpawn",true);assert(anchor and anchor:IsA("Attachment"))
    local original=record.model:GetPivot();local before=anchor.WorldPosition;record.model:PivotTo(original+Vector3.new(.25,0,0))
    check((anchor.WorldPosition-before-Vector3.new(.25,0,0)).Magnitude<.001,"UnitSpawn follows building")
    record.model:PivotTo(original)
    f.step(4.99);check(#f.u.GetUnits()==0,"five-second first deadline")
    f.step(.01);local unit=f.u.GetUnits()[1];assert(unit)
    local measured=Geometry.Measure(unit.model);local expected=Geometry.Start(record.model,pad :: BasePart,measured)
    check((unit.position-expected).Magnitude<.001,"spawn uses building attachment and unit bounds")
    check(not Geometry.IntersectsBuilding(unit.position,unit.radius,unit.height,record.model),"outside building")
    check(unit.model:GetPivot().LookVector:Dot(anchor.WorldCFrame.LookVector)>.99,"spawn faces road")
    local enemy=if faction=="Human" then "Undead" else "Human";local lane=pad:GetAttribute("LaneId") :: string
    local castle=workspace.Map.Castles[enemy.."Castle"] :: Model;local zone=Contact.Read(castle)
    check(not Contact.CanAttack(zone,unit.position,unit.radius,unit.height,faction,lane),"distant unit cannot attack crystal")
    local entered=false;local arrived=false;local entry=pad:FindFirstChild("LaneEntry") :: Attachment
    for _=1,450 do
     local previous=f.u.GetUnit(unit.instanceId);assert(previous)
     local hits=f.c.GetSnapshot().castleHits
     f.step(.1)
     local current=f.u.GetUnit(unit.instanceId);assert(current)
     check((current.position-previous.position).Magnitude<=current.speed*.1+.001,"continuous speed-limited walk")
     check(not Geometry.IntersectsBuilding(current.position,current.radius,current.height,record.model),"never crosses producer")
     if math.abs(current.position.Z-entry.WorldPosition.Z)<=6-current.width/2 then entered=true end
     local gap=Contact.Gap(zone,previous.position,previous.radius,previous.height)
     if gap>3.53 or not previous.reachedCastle then check(f.c.GetSnapshot().castleHits==hits,"no damage before physical contact") end
     if f.c.GetSnapshot().castleHits>0 then
      check(previous.reachedCastle and Contact.CanAttack(zone,previous.position,previous.radius,previous.height,faction,lane),"hit requires contact on correct side")
      result.minGap=math.min(result.minGap,gap);result.maxGap=math.max(result.maxGap,gap);arrived=true;break
     end
    end
    check(entered and arrived,"producer to road to crystal")
    local hits=f.c.GetSnapshot().castleHits;f.c.Step();check(f.c.GetSnapshot().castleHits==hits,"same clock no second hit")
    assert(f.m.Finish());check(#f.soldiers:GetChildren()==0 and #f.active:GetChildren()==0,"Finish removes units and buildings")
    f.step(100);check(#f.u.GetUnits()==0,"no spawn after Finish")
    assert(f.m.Start());check(f.c.GetSnapshot().HumanHP==1500 and f.c.GetSnapshot().UndeadHP==1500,"restart resets HP")
    result.cases+=1;return true
   end)
   f.destroy();if not ok then table.insert(result.failures,pad.Name..":"..id..":"..tostring(errorMessage)) end;task.wait()
  end
 end
 -- Blocked producer cannot emit overlapping copies or catch up in bursts.
 do
  local f=fixture();assert(f.m.Start());assert(f.b.TryBuild("Human","Human_Upper_01","ArcherTower","blocked-source",f.m.GetMatchId()))
  f.step(5,false);local first=f.u.GetUnits()[1];assert(first);f.u.SetCombatState(first.instanceId,true,first.position+Vector3.xAxis)
  f.step(22,false);check(#f.u.GetUnits()==1 and f.u.GetDiagnostics().blockedSpawns==1,"occupied exit skips overlap")
  f.u.SetCombatState(first.instanceId,false,nil);f.step(1,false);check(#f.u.GetUnits()==1,"no immediate catch-up spawn")
  f.step(21,false);check(#f.u.GetUnits()==2,"next unchanged interval emits second unit")
  f.destroy()
 end
 -- 60 actual live models, no combat damage during accumulation; queue must not overlap.
 local f=fixture();assert(f.m.Start());assert(Demo.Create(f.b,f.e,f.m).success)
 for _=1,2500 do if f.u.GetCount("Human")==30 and f.u.GetCount("Undead")==30 then break end;f.step(.25,false) end
 result.stressUnits=#f.u.GetUnits();check(result.stressUnits==60,"sixty live units")
 local all=f.u.GetUnits()
 for i,a in all do for j=i+1,#all do local b=all[j];local distance=(a.position-b.position).Magnitude
  local overlap=if a.faction==b.faction then Geometry.Overlap(a.position,a.model:GetPivot().LookVector,a.width,a.depth,b.position,b.model:GetPivot().LookVector,b.width,b.depth,.19) else distance<a.bodyRadius+b.bodyRadius+.09
  check(not overlap,"no overlapping friendly bounds or enemy bodies")
 end end
 local began=os.clock();for _=1,100 do f.step(.016,false) end;result.stressMilliseconds=(os.clock()-began)*1000/100
 check(f.u.GetDiagnostics().perUnitThreads==0 and f.u.GetDiagnostics().modelErrors==0,"bounded centralized update")
 f.destroy();return result
end
function Tests.Lifecycle(): {any}
 local rows: {any}={}
 for _,faction in {"Human","Undead"} do for _,lane in {"Upper","Lower"} do
  local f=fixture();assert(f.m.Start());local id: Types.BuildingId=if faction=="Human" then "KnightBarracks" else "GiantGraveyard"
  assert(f.b.TryBuild(faction :: Types.FactionId,faction.."_"..lane.."_01",id,"life",f.m.GetMatchId()))
  for _=1,2400 do if f.m.GetStatus()=="Finished" then break end;f.step(.1) end
  local result=f.m.GetResult();assert(result and result.winner==faction and result.reason=="CastleDestroyed","E_LIFECYCLE_DESTROY")
  assert(#f.soldiers:GetChildren()==0 and #f.active:GetChildren()==0 and f.u.GetDiagnostics().schedules==0,"E_FINISH_CLEANUP")
  local hits=f.c.GetSnapshot().castleHits;f.step(60);assert(f.c.GetSnapshot().castleHits==hits and #f.u.GetUnits()==0)
  assert(f.m.Start());assert(f.c.GetSnapshot().HumanHP==1500 and f.c.GetSnapshot().UndeadHP==1500)
  assert(f.b.TryBuild(faction :: Types.FactionId,faction.."_"..lane.."_01",id,"new-life",f.m.GetMatchId()))
  f.step(4.99);assert(#f.u.GetUnits()==0);f.step(.01);assert(#f.u.GetUnits()==1)
  table.insert(rows,{faction=faction,lane=lane,hits=hits,finished=true,restarted=true});f.destroy()
 end end
 for _,lane in {"Upper","Lower"} do
  local f=fixture();assert(f.m.Start())
  assert(f.b.TryBuild("Human","Human_"..lane.."_01","KnightBarracks","duel-human",f.m.GetMatchId()))
  assert(f.b.TryBuild("Undead","Undead_"..lane.."_01","GiantGraveyard","duel-undead",f.m.GetMatchId()))
  f.step(5);for _,faction in {"Human","Undead"} do local p=faction.."_"..lane.."_01";local r=f.b.GetBuilding(p);assert(r);assert(f.b.TrySell(faction :: Types.FactionId,p,r.instanceId,r.revision,"single-wave"..faction,f.m.GetMatchId())) end
  local resumed=false;local position: Vector3?=nil
  for _=1,1000 do
   f.step(.1)
   if f.c.GetSnapshot().kills>0 then
    for _,u in f.u.GetUnits() do if u.hp>0 and u.state=="Moving" then
     if not position then position=u.position elseif (u.position-position).Magnitude>4 then resumed=true end
    end end
   end
   if resumed and f.c.GetSnapshot().castleHits>0 then break end
  end
  assert(f.c.GetSnapshot().kills==1 and resumed and f.c.GetSnapshot().castleHits>0,"E_DUEL_WINNER_RESUME")
  table.insert(rows,{lane=lane,naturalKills=1,winnerContinued=true,contactDamage=true});f.destroy()
 end
 return rows
end
function Tests.Meeting(): {any}
 local rows={};local ids={{"KnightBarracks","GiantGraveyard"},{"ArcherTower","BoneTower"},{"MageAcademy","NecromancerCrypt"}}
 local positions={}
 for side,faction in {"Human","Undead"} do for index,pair in ids do
  local id=pair[side] :: Types.BuildingId;local pad=workspace.Map.BuildPads[faction.."_Upper_"..string.format("%02d",index)] :: BasePart
  local building=Models.Create(id :: Types.BuildingId,pad);local unitId=Definitions[id :: Types.BuildingId].unitId;assert(unitId)
  local model=UnitModels.Create(unitId :: Types.UnitId);local size=Geometry.Measure(model);local start=Geometry.Start(building,pad,size)
  local entry=pad:FindFirstChild("LaneEntry") :: Attachment;local stats=require(Shared.Config.UnitConfig)[unitId :: Types.UnitId]
  table.insert(positions,{faction=faction,id=unitId,x=start.X,delay=math.abs(entry.WorldPosition.Z-start.Z)/stats.speedStudsPerSecond,speed=stats.speedStudsPerSecond,range=stats.attackRangeStuds})
  building:Destroy();model:Destroy()
 end end
 for _,h in positions do if h.faction~="Human" then continue end;for _,u in positions do if u.faction~="Undead" then continue end
  local walk=(u.x-h.x+h.delay*h.speed+u.delay*u.speed)/(h.speed+u.speed)
  local contact=walk-math.max(h.range,u.range)/(h.speed+u.speed)
  table.insert(rows,{human=h.id,undead=u.id,centerMeetingAfterBuild=5+walk,firstAttackAfterBuild=5+contact,approachHuman=h.delay,approachUndead=u.delay})
 end end
 table.sort(rows,function(a,b)return a.firstAttackAfterBuild<b.firstAttackAfterBuild end);return rows
end
return table.freeze(Tests)
