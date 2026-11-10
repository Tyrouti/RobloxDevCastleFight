--!strict
-- Explicit Studio-only demonstration. Real purchases, routes, damage and replicated HP.
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local Definitions=require(Shared.Config.BuildingConfig)
local Buildings=require(script.Parent.BuildingService)
local Economy=require(script.Parent.EconomyService)
local Match=require(script.Parent.MatchService)
local Demo={}
function Demo.Create(buildings: Buildings.Service,economy: Economy.Economy,match: Match.Match,faction: Types.FactionId): {success: boolean,code: string,built: number}
 assert(game:GetService("RunService"):IsStudio(),"E_STUDIO_ONLY")
 if match.GetStatus()~="InProgress" then return {success=false,code="E_MATCH_INACTIVE",built=0} end
 local ids: {Types.BuildingId}=if faction=="Human" then {"KnightBarracks","ArcherTower","MageAcademy"} else {"GiantGraveyard","BoneTower","NecromancerCrypt"}
 local cost=0;for _,id in ids do cost+=Definitions[id :: Types.BuildingId].cost*3 end
 local amount=math.max(0,cost-economy.GetGold(faction))
 if amount>0 then assert(economy.AddGold(faction,amount,"hud-demo-fund",match.GetMatchId())) end
 local built=0
 for i=1,9 do
  local lane=if i<=5 then "Upper" else "Lower";local index=if i<=5 then i else i-5
  local id=ids[(i-1)%3+1];local padId=faction.."_"..lane.."_"..string.format("%02d",index)
  local ok,code=buildings.TryBuild(faction,padId,id :: Types.BuildingId,"hud-demo:"..padId,match.GetMatchId())
  if not ok then return {success=false,code=code,built=built} end;built+=1
 end
 return {success=true,code="OK",built=built}
end
return table.freeze(Demo)
