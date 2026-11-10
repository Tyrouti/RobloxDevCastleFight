--!strict
-- Private server ledger. No yields between checking, recording and spending.
export type Faction = "Human" | "Undead"
export type Config = {startingGold: number, goldPerSecond: number, maxGold: number}
export type Economy = {
	GetGold: (Faction) -> number,
	CanAfford: (Faction,number) -> boolean,
	TrySpendGold: (Faction,number,string,number) -> (boolean,string),
	AddGold: (Faction,number,string,number) -> (boolean,string),
	ResetEconomy: (number,boolean) -> (), SetActive: (boolean) -> (), Step: (number) -> (),
}
type Receipt = {amount: number, kind: string, success: boolean, code: string}
local EconomyService = {}
local FACTIONS: {Faction}={"Human","Undead"}
local function validAmount(amount: number): boolean
	return typeof(amount)=="number" and amount==amount and amount>0 and amount<math.huge
end
local function validFaction(faction: Faction): boolean return faction=="Human" or faction=="Undead" end

function EconomyService.new(config: Config, onChanged: (Faction, number) -> ()): Economy
	local balances: {[string]:number}={Human=0,Undead=0}
	local receipts: {[string]:{[string]:Receipt}}={Human={},Undead={}}
	local receiptCounts: {[string]:number}={Human=0,Undead=0}
	local active=false; local matchId=0; local elapsed=0
	local api={}
	function api.GetGold(faction: Faction): number
		assert(validFaction(faction),"E_FACTION"); return balances[faction]
	end
	function api.CanAfford(faction: Faction, amount: number): boolean
		return active and validFaction(faction) and validAmount(amount) and balances[faction]>=amount
	end
	local function transact(faction: Faction, amount: number, operationId: string, expectedMatchId: number, kind: string): (boolean,string)
		if not active then return false,"E_MATCH_INACTIVE" end
		if expectedMatchId~=matchId then return false,"E_STALE_MATCH" end
		if not validFaction(faction) then return false,"E_FACTION" end
		if not validAmount(amount) then return false,"E_AMOUNT" end
		if typeof(operationId)~="string" or #operationId==0 or #operationId>128 then return false,"E_OPERATION_ID" end
		local receipt=receipts[faction][operationId]
		if receipt then
			if receipt.amount~=amount or receipt.kind~=kind then return false,"E_OPERATION_CONFLICT" end
			-- Do not signal a second successful purchase to a caller. It must reuse its own result.
			return false,"E_DUPLICATE_OPERATION"
		end
		-- Never evict receipts during a match: eviction could allow a duplicate debit.
		if receiptCounts[faction]>=10000 then return false,"E_LEDGER_FULL" end
		local success=kind=="Add" or balances[faction]>=amount
		local code=if success then "OK" else "E_INSUFFICIENT_GOLD"
		receipts[faction][operationId]={amount=amount,kind=kind,success=success,code=code}
		receiptCounts[faction]+=1
		if not success then return false,code end
		balances[faction]=if kind=="Add" then math.min(config.maxGold,balances[faction]+amount) else balances[faction]-amount
		onChanged(faction,balances[faction]); return true,code
	end
	function api.TrySpendGold(faction: Faction, amount: number, operationId: string, expectedMatchId: number): (boolean,string)
		return transact(faction,amount,operationId,expectedMatchId,"Spend")
	end
	function api.AddGold(faction: Faction, amount: number, operationId: string, expectedMatchId: number): (boolean,string)
		return transact(faction,amount,operationId,expectedMatchId,"Add")
	end
	function api.ResetEconomy(newMatchId: number, giveStartingGold: boolean): ()
		active=false; elapsed=0; matchId=newMatchId
		for _,name in FACTIONS do
			local faction=name :: Faction
			balances[faction]=if giveStartingGold then config.startingGold else 0
			receipts[faction]={}; receiptCounts[faction]=0; onChanged(faction :: Faction,balances[faction])
		end
	end
	function api.SetActive(value: boolean): () active=value; if not value then elapsed=0 end end
	function api.Step(deltaSeconds: number): ()
		if not active or not validAmount(deltaSeconds) then return end
		elapsed+=deltaSeconds
		local ticks=math.floor(elapsed); if ticks==0 then return end
		elapsed-=ticks
		for _,name in FACTIONS do
			local faction=name :: Faction
			balances[faction]=math.min(config.maxGold,balances[faction]+ticks*config.goldPerSecond)
			onChanged(faction :: Faction,balances[faction])
		end
	end
	return table.freeze(api)
end
return table.freeze(EconomyService)
