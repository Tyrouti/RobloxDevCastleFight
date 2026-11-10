--!strict
-- Studio-only fixtures use the real services and immutable stats. Synthetic starts isolate formations.
local Shared=game.ReplicatedStorage.CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.GameConfig)
local Definitions=require(Shared.Config.BuildingConfig)
local Levels=require(Shared.Config.BuildingLevels)
local Economy=require(script.Parent.EconomyService)
local Match=require(script.Parent.MatchService)
local Buildings=require(script.Parent.BuildingService)
local Models=require(script.Parent.BuildingModels)
local Units=require(script.Parent.UnitService)
local UnitModels=require(script.Parent.UnitModels)
local Routes=require(script.Parent.LaneRoutes)
local Combat=require(script.Parent.CombatService)
local Geometry=require(script.Parent.UnitGeometry)
local Tests={}
type Placement={pad: string,id: Types.BuildingId,x: number,z: number}
local function fixture(placements: {Placement}?,visible: boolean?)
 assert(game:GetService("RunService"):IsStudio(),"E_STUDIO_ONLY")
 local pads=workspace.Map.BuildPads:Clone();for _,p in pads:GetChildren() do p:SetAttribute("IsOccupied",false) end
 local active=Instance.new("Folder");active.Name="P21BScenarioBuildings";active:SetAttribute("SystemOwner","CastleFightBuildings")
 local soldiers=Instance.new("Folder");soldiers.Name="P21BScenarioUnits";soldiers:SetAttribute("SystemOwner","CastleFightUnits")
 if visible then active.Parent=workspace;soldiers.Parent=workspace end
 local e=Economy.new(Config,function(_: Economy.Faction,_: number): () end)
 local now=0;local army: Units.Service?=nil;local buildings: Buildings.Service?=nil;local battle: Combat.Service?=nil
 local m=Match.new(e,function(status: Match.Status,_: number): ()
  if status~="InProgress" then if battle then if status=="Starting" then battle.Reset() else battle.Stop() end end;if army then army.ClearUnits() end;if buildings then buildings.ClearBuildings() end end
 end)
 local b=Buildings.new(pads,active,e,m,Models.Create,function(): () if army then army.SyncBuildings() end end);buildings=b
 local routes=Routes.new(workspace.Map)
 if placements then
  local lookup: {[string]:Placement}={};for _,p in placements do lookup[p.pad]=p end
  routes={CreatePath=function(pad: BasePart,lane: Types.LaneId,faction: Types.FactionId): Routes.Path
   local p=lookup[pad.Name];assert(p);local start=Vector3.new(p.x,2.15,p.z)
   local roadZ=if lane=="Upper" then -200 else -160
   return {start=start,points={start,Vector3.new(if faction=="Human" then 96 else -96,2.15,roadZ)},direction=Vector3.new(if faction=="Human" then 1 else -1,0,0)}
  end}
 end
 local u=Units.new(pads,soldiers,routes,b,m,UnitModels.Create,function(): number return now end);army=u
 local hits: {[string]:number}={};local hitTypes: {[string]:boolean}={}
 local c=Combat.new(workspace.Map,u,m,function(): number return now end,function(effect: Combat.Effect): ()
  for _,unit in u.GetUnits() do if unit.unitId==effect.unitId and (unit.position+Vector3.new(0,2.5,0)-effect.source).Magnitude<.01 then hits[unit.instanceId]=now;hitTypes[unit.unitId]=true end end
 end,function(_: Types.FactionId,_: number,_: number): () end);battle=c
 local function step(dt: number,fight: boolean?): () now+=dt;m.Step(dt);if fight~=false then c.Step() end;u.Step(dt) end
 local function advanceClock(dt: number): () now+=dt;u.Step(0) end
 local function destroy(): () m.Finish();pads:Destroy();active:Destroy();soldiers:Destroy() end
 assert(m.Start());assert(e.AddGold("Human",9000,"human",m.GetMatchId()));assert(e.AddGold("Undead",9000,"undead",m.GetMatchId()))
 if placements then
  for i,p in placements do local faction=Definitions[p.id].faction :: Types.FactionId;assert(b.TryBuild(faction :: Types.FactionId,p.pad,p.id,"scene"..i,m.GetMatchId())) end
  step(5,false)
  for _,faction in {"Human","Undead"} do for _,r in b.GetBuildingsForFaction(faction :: Types.FactionId) do assert(b.TrySell(faction :: Types.FactionId,r.padId,r.instanceId,r.revision,"stop:"..r.instanceId,m.GetMatchId())) end end
 end
 return {pads=pads,active=active,soldiers=soldiers,e=e,m=m,b=b,u=u,c=c,step=step,advance=advanceClock,destroy=destroy,hits=hits,hitTypes=hitTypes}
end
local function placements(kind: string): {Placement}
 local p: {Placement}={}
 local function add(faction: string,lane: string,slot: number,id: Types.BuildingId,x: number,offset: number): ()
  table.insert(p,{pad=faction.."_"..lane.."_0"..slot,id=id,x=x,z=(if lane=="Upper" then -200 else -160)+offset})
 end
 local lanes: {string}=if kind=="both-lanes" then {"Upper","Lower"} else {"Upper"}
 for _,lane in lanes do
  if kind=="archer-giant" then
   add("Undead",lane,1,"BoneTower",8,-3);add("Undead",lane,2,"GiantGraveyard",20,-3)
   add("Human",lane,1,"KnightBarracks",-12,3);add("Human",lane,2,"KnightBarracks",-18,-3)
  else
   local melee=kind=="melee" or kind=="many-one"
   add("Human",lane,1,if melee then "KnightBarracks" else "ArcherTower",-8,-3)
   add("Human",lane,2,"KnightBarracks",-20,-3)
   if kind~="archer-knight" then add("Human",lane,3,if melee then "KnightBarracks" else "MageAcademy",-26,3) end
   add("Undead",lane,1,"GiantGraveyard",12,if kind=="many-one" then 0 else -3)
   if kind~="many-one" then add("Undead",lane,2,if kind=="both-lanes" then "BoneTower" else "GiantGraveyard",20,3) end
  end
 end
 return p
end
function Tests.Scene(kind: string): any
 assert(table.find({"archer-knight","archer-giant","melee","mixed","many-one","both-lanes"},kind),"E_TEST_SCENE")
 return fixture(placements(kind),true)
end
function Tests.Intervals(): any
 local f=fixture(nil);local rows={};local checks=0
 local function check(ok: boolean,label: string): () assert(ok,label);checks+=1 end
 for _,id in {"ArcherTower","BoneTower","KnightBarracks","MageAcademy","NecromancerCrypt","GiantGraveyard"} do
  local def=Definitions[id :: Types.BuildingId];local faction=def.faction :: Types.FactionId;local pad=faction.."_Upper_01"
  check(f.b.TryBuild(faction :: Types.FactionId,pad,id :: Types.BuildingId,"build:"..id,f.m.GetMatchId()),"build producer")
  f.advance(4.999);check(#f.u.GetUnits()==0,"first not early");f.advance(.001);check(#f.u.GetUnits()==1,"first exactly five")
  for _,unit in f.u.GetUnits() do f.u.RemoveUnit(unit.instanceId) end
  local interval=def.spawnIntervalSeconds;assert(interval)
  local upgraded=Levels.Snapshot(id :: Types.BuildingId,2).spawnIntervalSeconds;assert(upgraded)
  check(upgraded>=20 and upgraded<=30,"upgraded interval remains within range")
  for _=1,3 do
   f.advance(interval-.001);check(#f.u.GetUnits()==0,"interval not early")
   f.advance(.0011);check(#f.u.GetUnits()==1,"single spawn at interval")
   f.advance(0);check(#f.u.GetUnits()==1,"same tick no double spawn")
   for _,unit in f.u.GetUnits() do f.u.RemoveUnit(unit.instanceId) end
  end
  local r=f.b.GetBuilding(pad);assert(r);assert(f.b.TrySell(faction :: Types.FactionId,pad,r.instanceId,r.revision,"sell:"..id,f.m.GetMatchId()))
  f.advance(interval*2);check(#f.u.GetUnits()==0 and f.u.GetDiagnostics().schedules==0,"sale stops production")
  table.insert(rows,{id=id,interval=interval,levelTwoInterval=upgraded,subsequentWaves=3})
 end
 -- Offset producer start times and two faction accounts: no shared timer.
 assert(f.b.TryBuild("Human","Human_Upper_01","ArcherTower","player1",f.m.GetMatchId()))
 f.advance(2);assert(f.b.TryBuild("Undead","Undead_Upper_01","BoneTower","player2",f.m.GetMatchId()))
 f.advance(3);check(f.u.GetCount("Human")==1 and f.u.GetCount("Undead")==0,"independent first deadline")
 f.advance(2);check(f.u.GetCount("Human")==1 and f.u.GetCount("Undead")==1,"second independent first deadline")
 f.m.Finish();f.advance(100);check(#f.u.GetUnits()==0 and f.u.GetDiagnostics().schedules==0,"Finish no late spawn")
 assert(f.m.Start());assert(f.b.TryBuild("Human","Human_Upper_01","ArcherTower","restart",f.m.GetMatchId()))
 f.advance(4.999);check(#f.u.GetUnits()==0,"restart no old timer");f.advance(.0011);check(#f.u.GetUnits()==1,"restart fresh deadline")
 f.destroy();return {assertions=checks,rows=rows}
end
function Tests.Formations(): any
 local rows={}
 for _,kind in {"archer-knight","archer-giant","melee","mixed","many-one","both-lanes"} do
  local f=fixture(placements(kind));local peak=0;local upper=0;local lower=0;local overlaps=0;local outside=0;local advanced=false;local againstOne=0;local speedErrors=0
  for _=1,200 do
   local previous: {[string]:Vector3}={};for _,a in f.u.GetUnits() do previous[a.instanceId]=a.position end
   f.step(.05)
   local live=f.u.GetUnits();local count=0;local lanes={Upper=0,Lower=0};local targets: {[string]:number}={}
   for i,a in live do
    if a.hp<=0 then continue end
    if previous[a.instanceId] and (a.position-previous[a.instanceId]).Magnitude>a.speed*.05+.001 then speedErrors+=1 end
    if a.state=="Attacking" and f.hits[a.instanceId] then
     count+=1;lanes[a.laneId]+=1
     local target=a.model:GetAttribute("TargetId");if typeof(target)=="string" then targets[target]=(targets[target] or 0)+1;againstOne=math.max(againstOne,targets[target]) end
    end
    local roadZ=if a.laneId=="Upper" then -200 else -160
    local look=a.model:GetPivot().LookVector
    local extent=math.abs(look.X)*a.width/2+math.abs(look.Z)*a.depth/2
    if math.abs(a.position.Z-roadZ)+extent>6.01 then outside+=1 end
    if (a.unitId=="Knight" and a.position.X> -7) or (a.unitId=="Giant" and kind=="archer-giant" and a.position.X<7) then advanced=true end
    for j=i+1,#live do local b=live[j]
     if b.hp>0 and a.faction==b.faction and Geometry.Overlap(a.position,look,a.width,a.depth,b.position,b.model:GetPivot().LookVector,b.width,b.depth,0) then overlaps+=1 end
    end
   end
   peak=math.max(peak,count);upper=math.max(upper,lanes.Upper);lower=math.max(lower,lanes.Lower)
  end
  local positions={};for _,a in f.u.GetUnits() do table.insert(positions,{id=a.unitId,x=a.position.X,z=a.position.Z,state=a.state,hit=f.hits[a.instanceId]~=nil}) end
  assert(overlaps==0 and outside==0 and speedErrors==0,"E_FORMATION_GEOMETRY:"..kind)
  assert(peak>=3 and f.hitTypes.Knight and f.hitTypes.Giant,"E_FORMATION_ATTACKS:"..kind)
  if kind=="many-one" then assert(againstOne>=2,"E_SINGLE_TARGET_QUEUE") end
  if kind=="both-lanes" then assert(upper>=3 and lower>=3,"E_BOTH_LANES_QUEUE") end
  table.insert(rows,{scenario=kind,peakAttackers=peak,upper=upper,lower=lower,peakAgainstOne=againstOne,overlaps=overlaps,outside=outside,speedErrors=speedErrors,meleePassedFront=advanced,hits=f.c.GetSnapshot().unitHits,kills=f.c.GetSnapshot().kills,hitTypes=f.hitTypes,positions=positions})
  f.destroy();task.wait()
 end
 return rows
end
return table.freeze(Tests)
