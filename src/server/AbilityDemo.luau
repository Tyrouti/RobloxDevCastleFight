--!strict
local Shared=game.ReplicatedStorage.CastleFightShared
local Types=require(Shared.Types)
local Buildings=require(script.Parent.BuildingService)
local Economy=require(script.Parent.EconomyService)
local Match=require(script.Parent.MatchService)
local Demo={}
function Demo.Create(buildings: Buildings.Service,economy: Economy.Economy,match: Match.Match): any
 assert(game:GetService("RunService"):IsStudio(),"E_STUDIO_ONLY")
 local result=require(script.Parent.UnitDemo).Create(buildings,economy,match);if not result.success then return result end
 local built=result.built
 for _,faction in {"Human","Undead"} do
  local side=faction :: Types.FactionId;local id: Types.BuildingId=if faction=="Human" then "LightSanctuary" else "CursedObelisk"
  assert(economy.AddGold(side :: Types.FactionId,1000,"ability-demo-fund:"..faction,match.GetMatchId()))
  for _,lane in {"Upper","Lower"} do
   local pad=faction.."_"..lane.."_04";assert(buildings.TryBuild(side :: Types.FactionId,pad,id,"ability-demo:"..pad,match.GetMatchId()));built+=1
  end
 end
 return {success=true,built=built,code="OK"}
end
return table.freeze(Demo)
