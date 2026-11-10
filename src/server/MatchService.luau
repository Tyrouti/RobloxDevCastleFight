--!strict
local EconomyService=require(script.Parent.EconomyService)
export type Status = "Waiting" | "Starting" | "InProgress" | "Finished"
export type Result = {winner: EconomyService.Faction?,reason: string}
export type Match = {
	GetStatus: () -> Status, GetMatchId: () -> number,
	Start: () -> (boolean,string), Finish: (EconomyService.Faction?,string?) -> (boolean,string), Reset: () -> (boolean,string), Step: (number) -> (),
	GetResult: () -> Result?,
}
local MatchService={}

function MatchService.new(economy: EconomyService.Economy, onChanged: (Status,number) -> ()): Match
	local status: Status="Waiting"; local matchId=0
	local result: Result?=nil
	local api={}
	local function transition(nextStatus: Status): () status=nextStatus; onChanged(status,matchId) end
	function api.GetStatus(): Status return status end
	function api.GetMatchId(): number return matchId end
	function api.GetResult(): Result? return result end
	function api.Start(): (boolean,string)
		if status~="Waiting" and status~="Finished" then return false,"E_MATCH_ALREADY_STARTED" end
		result=nil; matchId+=1; transition("Starting"); economy.ResetEconomy(matchId,true)
		transition("InProgress"); economy.SetActive(true); return true,"OK"
	end
	function api.Finish(winner: EconomyService.Faction?,reason: string?): (boolean,string)
		if status~="InProgress" then return false,"E_MATCH_INACTIVE" end
		result=table.freeze({winner=winner,reason=reason or "Manual"})
		economy.SetActive(false); transition("Finished"); economy.ResetEconomy(matchId,false)
		return true,"OK"
	end
	function api.Reset(): (boolean,string)
		if status=="InProgress" or status=="Starting" then return false,"E_FINISH_FIRST" end
		result=nil; economy.ResetEconomy(matchId,false); transition("Waiting"); return true,"OK"
	end
	function api.Step(deltaSeconds: number): () if status=="InProgress" then economy.Step(deltaSeconds) end end
	return table.freeze(api)
end
return table.freeze(MatchService)
