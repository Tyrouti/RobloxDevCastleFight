--!strict
-- Only the existing server-side Studio control invokes this. No client admin route.
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local Definitions=require(Shared.Config.BuildingConfig)
local Buildings=require(script.Parent.BuildingService)
local Economy=require(script.Parent.EconomyService)
local Match=require(script.Parent.MatchService)
local Demo={}
function Demo.Create(buildings: Buildings.Service,economy: Economy.Economy,match: Match.Match): {success: boolean,code: string,built: number}
	assert(game:GetService("RunService"):IsStudio(),"E_STUDIO_ONLY")
	if match.GetStatus()~="InProgress" then return {success=false,code="E_MATCH_INACTIVE",built=0} end
	if buildings.GetBuildingCount("Human")+buildings.GetBuildingCount("Undead")>0 then return {success=false,code="E_DEMO_REQUIRES_EMPTY_MATCH",built=0} end
	local built=0
	for _,faction in {"Human","Undead"} do
		local ids: {Types.BuildingId}=if faction=="Human" then {"KnightBarracks","ArcherTower","MageAcademy"} else {"GiantGraveyard","BoneTower","NecromancerCrypt"}
		local total=0; for _,id in ids do total+=Definitions[id :: Types.BuildingId].cost*2 end
		local needed=math.max(0,total-economy.GetGold(faction :: Types.FactionId))
		if needed>0 then
			local paid,code=economy.AddGold(faction :: Types.FactionId,needed,"unit-demo-fund",match.GetMatchId())
			if not paid then return {success=false,code=code,built=built} end
		end
		for _,lane in {"Upper","Lower"} do for index,id in ids do
			local padId=faction.."_"..lane.."_"..string.format("%02d",index)
			local ok,code=buildings.TryBuild(faction :: Types.FactionId,padId,id :: Types.BuildingId,"unit-demo:"..padId,match.GetMatchId())
			if not ok then return {success=false,code=code,built=built} end; built+=1
		end end
	end
	return {success=true,code="OK",built=built}
end
return table.freeze(Demo)
