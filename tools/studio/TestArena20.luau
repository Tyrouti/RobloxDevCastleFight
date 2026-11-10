--!strict
-- Real services and active map geometry; isolated producer fixtures do not alter the running match.
local Shared=game.ReplicatedStorage.CastleFightShared
local Config=require(Shared.Config.MapConfig)
local Game=require(Shared.Config.GameConfig)
local Definitions=require(Shared.Config.BuildingConfig)
local Types=require(Shared.Types)
local Server=game.ServerScriptService.CastleFightServer
local Routes=require(Server.LaneRoutes)
local Economy=require(Server.EconomyService)
local Match=require(Server.MatchService)
local Buildings=require(Server.BuildingService)
local BuildingModels=require(Server.BuildingModels)
local Units=require(Server.UnitService)
local UnitModels=require(Server.UnitModels)
local Combat=require(Server.CombatService)
local Tests={}
function Tests.Geometry(): {passed: number,roads: {number},routes: {number},parts: number}
 local map=workspace.Map;assert(map:GetAttribute("Correction20")==true)
 local count=0;local function check(ok: boolean,label: string): () assert(ok,label);count+=1 end
 check(#map.BuildPads:GetChildren()==20,"twenty pads")
 check(not map:FindFirstChild("Exterior19"),"gray exterior removed")
 local parts=0
 for _,p in map:GetDescendants() do if p:IsA("BasePart") then
  parts+=1
  check(p.Transparency==1 or (p.Size.X<=300 and p.Size.Z<=170),"no giant visible floor:"..p:GetFullName())
 end end
 local routes={};local roads={}
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={map.Territories,map.Lanes,map.Castles}
 for _,lane in Config.lanes do
  local model=map.Lanes[lane.name];local road=model.Road :: BasePart
  check(math.abs(road.Size.X-228)<.01 and road.Size.Z==12,"road size");table.insert(roads,road.Size.X)
  for _,faction in {"Human","Undead"} do
   local pts=model.Waypoints[faction]:GetChildren();table.sort(pts,function(a,b)return a.Name<b.Name end)
   local length=0
   for i=2,#pts do
    local a=pts[i-1] :: BasePart;local b=pts[i] :: BasePart;local d=b.Position-a.Position;length+=d.Magnitude
    for k=0,20 do local pos=a.Position+d*k/20;check(workspace:Raycast(pos+Vector3.new(0,5,0),Vector3.new(0,-10,0),params)~=nil,"route has continuous support") end
   end
   check(length>=220 and length<=235,"route length");table.insert(routes,length)
  end
 end
 for _,pad in map.BuildPads:GetChildren() do
  local p=pad :: BasePart;local entry=p:FindFirstChild("LaneEntry") :: Attachment;local spawn=p:FindFirstChild("SpawnPoint") :: Attachment
  check((spawn.WorldPosition-p.Position).Magnitude<=6.01,"spawn beside producer")
  check((spawn.WorldPosition-entry.WorldPosition).Magnitude>0,"producer approach exists")
  check(math.abs(p.Position.X)<140 and math.abs(p.Position.Z-Config.origin.Z)<75,"pad in territory")
  check(math.abs(p.Position.Z-Config.origin.Z-(if p:GetAttribute("LaneId")=="Upper" then -20 else 20))>=11,"pad separated from road")
 end
 check(workspace.Baseplate.Transparency==1,"baseplate hidden")
 return {passed=count,roads=roads,routes=routes,parts=parts}
end
function Tests.Gameplay(): {built: number,spawnedBesideBuilding: number,enteredLane: number,attacked: number,noRemoteHits: number,failures: {string}}
 local map=workspace.Map
 local result={built=0,spawnedBesideBuilding=0,enteredLane=0,attacked=0,noRemoteHits=0,failures={} :: {string}}
 for _,pad in map.BuildPads:GetChildren() do
  -- Every producing type is checked on every owned pad: 60 fixtures, all six unit classes.
  local faction=pad:GetAttribute("OwnerFaction") :: Types.FactionId
  for id,definition in Definitions do
   if definition.faction~=faction or not definition.unitId then continue end
   local pads=map.BuildPads:Clone();for _,p in pads:GetChildren() do p:SetAttribute("IsOccupied",false) end
   local active=Instance.new("Folder");active:SetAttribute("SystemOwner","CastleFightBuildings")
   local soldiers=Instance.new("Folder");soldiers:SetAttribute("SystemOwner","CastleFightUnits")
   local economy=Economy.new(Game,function(_: Economy.Faction,_: number): () end)
   local now=0;local u: Units.Service?=nil;local b: Buildings.Service?=nil;local c: Combat.Service?=nil
   local match=Match.new(economy,function(status: Match.Status,_: number): ()
    if status~="InProgress" then if c then if status=="Starting" then c.Reset() else c.Stop() end end;if u then u.ClearUnits() end;if b then b.ClearBuildings() end end
   end)
   local build=Buildings.new(pads,active,economy,match,BuildingModels.Create,function(): () if u then u.SyncBuildings() end end);b=build
   local army=Units.new(pads,soldiers,Routes.new(map),build,match,UnitModels.Create,function(): number return now end);u=army
   local combat=Combat.new(map,army,match,function(): number return now end,function(_: Combat.Effect): () end,function(_: Types.FactionId,_: number,_: number): () end);c=combat
   local ok,failure=pcall(function(): boolean
    assert(match.Start());assert(build.TryBuild(faction,pad.Name,id :: Types.BuildingId,"p20build",match.GetMatchId()));result.built+=1
    now=5;match.Step(5);army.Step(5)
    local unit=army.GetUnits()[1];assert(unit,"spawn missing")
    local spawn=pad:FindFirstChild("SpawnPoint") :: Attachment;local entry=pad:FindFirstChild("LaneEntry") :: Attachment
    assert((unit.position-spawn.WorldPosition).Magnitude<.01,"not spawned beside producer");result.spawnedBesideBuilding+=1
    local details=build.GetBuildingDetails(faction,pad.Name);assert(details);assert(build.TrySell(faction,pad.Name,details.instanceId,details.revision,"p20sell",match.GetMatchId()))
    local enemy=if faction=="Human" then "Undead" else "Human";local lane=pad:GetAttribute("LaneId") :: string
    local target=map.Castles[enemy.."Castle"][lane.."CastleTarget"] :: BasePart
    local passedEntry=false;local gotHit=false
    for _=1,450 do
     local before=army.GetUnits()[1];assert(before)
     local wasHit=combat.GetSnapshot().castleHits
     now+=.1;match.Step(.1);combat.Step();army.Step(.1)
     local after=army.GetUnits()[1];assert(after)
     assert((after.position-before.position).Magnitude<=before.speed*.1+.001,"movement exceeded configured speed")
     if math.abs(after.position.Z-entry.WorldPosition.Z)<.01 then passedEntry=true end
     local hits=combat.GetSnapshot().castleHits
     if hits>wasHit then
      assert(before.reachedCastle and (before.position-target.Position).Magnitude<=before.stats.attackRangeStuds+.01,"castle hit before physical arrival")
      gotHit=true;break
     end
     assert(hits==0,"unexpected remote hit")
    end
    assert(passedEntry,"did not walk onto own road");result.enteredLane+=1
    assert(gotHit,"did not reach and attack crystal");result.attacked+=1;result.noRemoteHits+=1
    assert(army.GetDiagnostics().movementCorrections==0 and combat.GetSnapshot().effectErrors==0,"runtime diagnostics")
    return true
   end)
   match.Finish();army.ClearUnits();build.ClearBuildings();pads:Destroy();active:Destroy();soldiers:Destroy()
   if not ok then table.insert(result.failures,pad.Name..":"..id..":"..tostring(failure)) end
   task.wait()
  end
 end
 return result
end
return table.freeze(Tests)
