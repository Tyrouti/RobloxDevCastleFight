--!strict
-- Real arena routes/targets and unchanged services. Cloned pads isolate the live match.
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.GameConfig)
local Server=game:GetService("ServerScriptService").CastleFightServer
local Economy=require(Server.EconomyService)
local Match=require(Server.MatchService)
local Buildings=require(Server.BuildingService)
local BuildingModels=require(Server.BuildingModels)
local Units=require(Server.UnitService)
local UnitModels=require(Server.UnitModels)
local Routes=require(Server.LaneRoutes)
local Combat=require(Server.CombatService)
local Tests={}
function Tests.Run(): {padsBuilt: number,arrived: number,attacked: number,failures: {string}}
 assert(game:GetService("RunService"):IsStudio(),"E_STUDIO_ONLY")
 local map=workspace.Map
 local report={padsBuilt=0,arrived=0,attacked=0,failures={} :: {string}}
 for _,original in map.BuildPads:GetChildren() do
  local pads=map.BuildPads:Clone()
  for _,p in pads:GetChildren() do p:SetAttribute("IsOccupied",false) end
  local active=Instance.new("Folder"); active:SetAttribute("SystemOwner","CastleFightBuildings")
  local soldiers=Instance.new("Folder"); soldiers:SetAttribute("SystemOwner","CastleFightUnits")
  local economy=Economy.new(Config,function(_: Economy.Faction,_: number): () end)
  local units: Units.Service?=nil; local buildings: Buildings.Service?=nil; local combat: Combat.Service?=nil
  local match=Match.new(economy,function(status: Match.Status,_: number): ()
   if status~="InProgress" then
    if combat then if status=="Starting" or status=="Waiting" then combat.Reset() else combat.Stop() end end
    if units then units.ClearUnits() end; if buildings then buildings.ClearBuildings() end
   end
  end)
  local now=0
  local b=Buildings.new(pads,active,economy,match,BuildingModels.Create,function(): () if units then units.SyncBuildings() end end); buildings=b
  local u=Units.new(pads,soldiers,Routes.new(map),b,match,UnitModels.Create,function(): number return now end); units=u
  local c=Combat.new(map,u,match,function(): number return now end,function(_: Combat.Effect): () end,function(_: Types.FactionId,_: number,_: number): () end); combat=c
  local ok,failure=pcall(function(): boolean
   local faction=original:GetAttribute("OwnerFaction") :: Types.FactionId
   local lane=original:GetAttribute("LaneId") :: Types.LaneId
   assert(match.Start())
   local id: Types.BuildingId=if faction=="Human" then "KnightBarracks" else "GiantGraveyard"
   assert(b.TryBuild(faction :: Types.FactionId,original.Name,id,"arena-build",match.GetMatchId()))
   report.padsBuilt+=1
   now=5; match.Step(5); c.Step(); u.Step(5)
   local d=b.GetBuildingDetails(faction :: Types.FactionId,original.Name); assert(d)
   assert(b.TrySell(faction :: Types.FactionId,original.Name,d.instanceId,d.revision,"arena-sell",match.GetMatchId()))
   -- Fixed dt matches the existing movement cap. Never teleport or override the route.
   for _=1,240 do now+=.1; match.Step(.1); c.Step(); u.Step(.1) end
   local all=u.GetUnits(); assert(#all==1,"E_WAVE_COUNT")
   local unit=all[1]
   local enemy=if faction=="Human" then "Undead" else "Human"
   local target=map.Castles[enemy.."Castle"][lane.."CastleTarget"] :: BasePart
   assert(unit.reachedCastle and (unit.position-target.Position).Magnitude<.01,"E_NOT_ARRIVED")
   report.arrived+=1
   local snap=c.GetSnapshot()
   assert(snap.castleHits>0 and (if enemy=="Human" then snap.HumanHP else snap.UndeadHP)<Config.castleHealth,"E_NO_CASTLE_DAMAGE")
   assert(u.GetDiagnostics().movementCorrections==0 and snap.effectErrors==0,"E_DIAGNOSTICS")
   report.attacked+=1
   return true
  end)
  match.Finish(); u.ClearUnits(); b.ClearBuildings(); pads:Destroy(); soldiers:Destroy(); active:Destroy()
  if not ok then table.insert(report.failures,original.Name..":"..tostring(failure)) end
  task.wait()
 end
 return report
end
return table.freeze(Tests)
