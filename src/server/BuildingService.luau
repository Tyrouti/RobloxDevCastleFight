--!strict
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.GameConfig)
local Definitions=require(Shared.Config.BuildingConfig)
local Presentation=require(Shared.Config.BuildingPresentation)
local Levels=require(Shared.Config.BuildingLevels)
local Models=require(script.Parent.BuildingModels)
local Http=game:GetService("HttpService")
local EconomyService=require(script.Parent.EconomyService)
local MatchService=require(script.Parent.MatchService)
type Faction=Types.FactionId
type BuildingId=Types.BuildingId
type LaneId=Types.LaneId
export type Record={padId: string,buildingId: BuildingId,assetId: string,faction: Faction,laneId: LaneId,matchId: number,model: Model,
	instanceId: string,revision: number,level: number,totalSpent: number}
export type Details={padId: string,buildingId: BuildingId,assetId: string,faction: Faction,laneId: LaneId,matchId: number,
	instanceId: string,revision: number,level: number,totalSpent: number,upgradeCost: number?,refund: number,
	refundAtCurrentBalance: number,stats: Levels.Stats,nextStats: Levels.Stats?}
type Pad={part: BasePart,faction: Faction,laneId: LaneId}
export type Service={
	CanBuild: (Faction,string,BuildingId) -> (boolean,string),
	TryBuild: (Faction,string,BuildingId,string,number) -> (boolean,string),
	GetBuilding: (string) -> Record?, GetBuildingsForFaction: (Faction) -> {Record},
	GetBuildingCount: (Faction,BuildingId?,LaneId?) -> number, ClearBuildings: () -> (),
	CanUpgrade: (Faction,string) -> (boolean,string), CanSell: (Faction,string) -> (boolean,string),
	TryUpgrade: (Faction,string,string,number,string,number) -> (boolean,string),
	TrySell: (Faction,string,string,number,string,number) -> (boolean,string),
	GetBuildingDetails: (Faction,string) -> Details?,
}
local BuildingService={}

function BuildingService.new(padsFolder: Instance,activeFolder: Folder,economy: EconomyService.Economy,match: MatchService.Match,
	createModel: (BuildingId,BasePart) -> Model,onChanged: () -> (),createUpgradeVisual: ((Model,Faction) -> Folder)?): Service
	local pads: {[string]:Pad}={}; local records: {[string]:Record}={}; local requests: {[string]:string}={}
	local busy: {[string]:boolean}={}
	local upgradeVisual=createUpgradeVisual or Models.CreateUpgradeVisual
	local function notify(): ()
		local ok,failure=pcall(function(): boolean onChanged(); return true end)
		if not ok then warn("[BuildingService] committed, notification failed: "..tostring(failure)) end
	end
	local function locked(padId: string,operation: () -> (boolean,string)): (boolean,string)
		if busy[padId] then return false,"E_BUILDING_BUSY" end
		busy[padId]=true
		local ok,success,code=pcall(operation); busy[padId]=nil
		if not ok then warn("[BuildingService] operation failed: "..tostring(success)); return false,"E_BUILDING_INTERNAL" end
		return success,code
	end
	assert(activeFolder:GetAttribute("SystemOwner")=="CastleFightBuildings","E_FOREIGN_BUILDINGS_FOLDER")
	for _,obj in padsFolder:GetChildren() do
		assert(obj:IsA("BasePart"),"E_PAD_TYPE")
		local id=obj:GetAttribute("PadId"); local faction=obj:GetAttribute("OwnerFaction"); local lane=obj:GetAttribute("LaneId")
		assert(typeof(id)=="string" and #id<=64 and not pads[id],"E_PAD_ID")
		assert(faction=="Human" or faction=="Undead","E_PAD_FACTION"); assert(lane=="Upper" or lane=="Lower","E_PAD_LANE")
		assert(obj:GetAttribute("IsOccupied")==false,"E_PAD_OCCUPIED_AT_INIT")
		pads[id]={part=obj,faction=faction :: Faction,laneId=lane :: LaneId}
	end
	local api={} :: Service
	function api.GetBuilding(padId: string): Record?
		local record=records[padId]; return if record then table.freeze(table.clone(record)) else nil
	end
	function api.GetBuildingDetails(faction: Faction,padId: string): Details?
		local record=records[padId]; if not record or record.faction~=faction then return nil end
		local refund=Levels.Refund(record.totalSpent)
		return table.freeze({padId=padId,buildingId=record.buildingId,assetId=record.assetId,faction=faction,laneId=record.laneId,
			matchId=record.matchId,instanceId=record.instanceId,revision=record.revision,level=record.level,totalSpent=record.totalSpent,
			upgradeCost=if record.level<Config.maxBuildingLevel then Levels.UpgradeCost(record.buildingId) else nil,
			refund=refund,refundAtCurrentBalance=math.min(refund,Config.maxGold-economy.GetGold(faction)),
			stats=Levels.Snapshot(record.buildingId,record.level),
			nextStats=if record.level<Config.maxBuildingLevel then Levels.Snapshot(record.buildingId,record.level+1) else nil})
	end
	function api.GetBuildingsForFaction(faction: Faction): {Record}
		local result: {Record}={}; for _,record in records do if record.faction==faction then table.insert(result,table.freeze(table.clone(record))) end end
		return result
	end
	function api.GetBuildingCount(faction: Faction,buildingId: BuildingId?,laneId: LaneId?): number
		local count=0; for _,record in records do if record.faction==faction and (not buildingId or record.buildingId==buildingId) and (not laneId or record.laneId==laneId) then count+=1 end end
		return count
	end
	function api.CanBuild(faction: Faction,padId: string,buildingId: BuildingId): (boolean,string)
		if match.GetStatus()~="InProgress" then return false,"E_MATCH_INACTIVE" end
		local pad=pads[padId]; if not pad then return false,"E_PAD_ID" end
		if pad.faction~=faction then return false,"E_NOT_YOUR_PAD" end
		if pad.part.Parent~=padsFolder or pad.part:GetAttribute("PadId")~=padId or pad.part:GetAttribute("OwnerFaction")~=pad.faction or pad.part:GetAttribute("LaneId")~=pad.laneId then return false,"E_PAD_CHANGED" end
		if records[padId] or pad.part:GetAttribute("IsOccupied")~=false then return false,"E_PAD_OCCUPIED" end
		local definition=Definitions[buildingId]; if not definition then return false,"E_BUILDING_ID" end
		if definition.faction~=faction then return false,"E_WRONG_BUILDING_FACTION" end
		if api.GetBuildingCount(faction)>=Config.buildingSlotsPerPlayer then return false,"E_BUILDING_LIMIT" end
		if definition.kind=="Producer" and api.GetBuildingCount(faction,buildingId)>=Config.maxSameProducerPerPlayer then return false,"E_PRODUCER_LIMIT" end
		if definition.kind=="Passive" then
			local count=0; for _,record in records do if record.faction==faction and record.laneId==pad.laneId and Definitions[record.buildingId].kind=="Passive" then count+=1 end end
			if count>=Config.maxPassivePerLanePerPlayer then return false,"E_PASSIVE_LIMIT" end
		end
		if not economy.CanAfford(faction,definition.cost) then return false,"E_INSUFFICIENT_GOLD" end
		return true,"OK"
	end
	local function build(faction: Faction,padId: string,buildingId: BuildingId,requestId: string,expectedMatchId: number): (boolean,string)
		if expectedMatchId~=match.GetMatchId() then return false,"E_STALE_MATCH" end
		if typeof(requestId)~="string" or #requestId==0 or #requestId>64 then return false,"E_REQUEST_ID" end
		local key=faction..":"..requestId; local signature="Build:"..padId..":"..buildingId
		if requests[key] then return false,if requests[key]==signature then "E_DUPLICATE_REQUEST" else "E_REQUEST_CONFLICT" end
		local allowed,reason=api.CanBuild(faction,padId,buildingId); if not allowed then return false,reason end
		local pad=pads[padId]
		local ok,created=pcall(createModel,buildingId,pad.part)
		if not ok then return false,"E_MODEL_PREPARATION" end
		local model=created :: Model
		if not model:IsA("Model") or model.Parent~=nil then return false,"E_MODEL_PREPARATION" end
		local cf,size=model:GetBoundingBox(); local ground=pad.part.Position.Y+pad.part.Size.Y/2
		if math.abs(cf.Position.X-pad.part.Position.X)>.05 or math.abs(cf.Position.Z-pad.part.Position.Z)>.05
			or math.abs(cf.Position.Y-size.Y/2-ground)>.05 or size.X>pad.part.Size.X+.01 or size.Z>pad.part.Size.Z+.01 then model:Destroy(); return false,"E_MODEL_BOUNDS" end
		local record: Record={padId=padId,buildingId=buildingId,assetId=Presentation.entries[buildingId].assetId,faction=faction,laneId=pad.laneId,matchId=expectedMatchId,model=model,
			instanceId=Http:GenerateGUID(false),revision=1,level=1,totalSpent=Definitions[buildingId].cost}
		local function rollback(): () records[padId]=nil; model:Destroy(); pad.part:SetAttribute("IsOccupied",false) end
		-- Publish provisionally, then debit LAST. No yielding factory/API is permitted here.
		local published=pcall(function(): ()
			model.Name=padId; model:SetAttribute("SystemOwner","CastleFightBuildings")
			model:SetAttribute("PadId",padId); model:SetAttribute("BuildingId",buildingId); model:SetAttribute("AssetId",record.assetId)
			model:SetAttribute("OwnerFaction",faction); model:SetAttribute("LaneId",pad.laneId); model:SetAttribute("MatchId",expectedMatchId)
			model:SetAttribute("InstanceId",record.instanceId); model:SetAttribute("Revision",1); model:SetAttribute("Level",1); model:SetAttribute("TotalSpent",record.totalSpent)
			records[padId]=record; pad.part:SetAttribute("IsOccupied",true); model.Parent=activeFolder
		end)
		if not published then rollback(); return false,"E_MODEL_PUBLICATION" end
		local paid,code=economy.TrySpendGold(faction,Definitions[buildingId].cost,"build:"..requestId,expectedMatchId)
		if not paid then rollback(); return false,code end
		requests[key]=signature
		-- Payment has committed. Notification failure must never trigger a second purchase/refund.
		notify()
		return true,"OK"
	end
	function api.TryBuild(faction: Faction,padId: string,buildingId: BuildingId,requestId: string,expectedMatchId: number): (boolean,string)
		return locked(padId,function(): (boolean,string) return build(faction,padId,buildingId,requestId,expectedMatchId) end)
	end
	local function owned(faction: Faction,padId: string): (Record?,string)
		if match.GetStatus()~="InProgress" then return nil,"E_MATCH_INACTIVE" end
		local pad=pads[padId]; if not pad then return nil,"E_PAD_ID" end
		if pad.faction~=faction then return nil,"E_NOT_YOUR_PAD" end
		if pad.part.Parent~=padsFolder or pad.part:GetAttribute("PadId")~=padId or pad.part:GetAttribute("OwnerFaction")~=faction or pad.part:GetAttribute("LaneId")~=pad.laneId then return nil,"E_PAD_CHANGED" end
		local record=records[padId]; if not record then return nil,"E_BUILDING_MISSING" end
		if record.faction~=faction or record.matchId~=match.GetMatchId() or record.model.Parent~=activeFolder
			or record.model:GetAttribute("InstanceId")~=record.instanceId or pad.part:GetAttribute("IsOccupied")~=true then return nil,"E_BUILDING_CHANGED" end
		return record,"OK"
	end
	function api.CanUpgrade(faction: Faction,padId: string): (boolean,string)
		local record,reason=owned(faction,padId); if not record then return false,reason end
		if record.level>=Config.maxBuildingLevel then return false,"E_MAX_LEVEL" end
		if not economy.CanAfford(faction,Levels.UpgradeCost(record.buildingId)) then return false,"E_INSUFFICIENT_GOLD" end
		return true,"OK"
	end
	function api.CanSell(faction: Faction,padId: string): (boolean,string)
		local record,reason=owned(faction,padId); return record~=nil,reason
	end
	local function managementRequest(faction: Faction,padId: string,instanceId: string,revision: number,requestId: string,epoch: number,action: string): (Record?,string)
		if epoch~=match.GetMatchId() then return nil,"E_STALE_MATCH" end
		if match.GetStatus()~="InProgress" then return nil,"E_MATCH_INACTIVE" end
		if typeof(requestId)~="string" or #requestId==0 or #requestId>64 then return nil,"E_REQUEST_ID" end
		if typeof(instanceId)~="string" or #instanceId==0 or #instanceId>64 or typeof(revision)~="number" or revision%1~=0 or revision<1 or revision>Config.maxBuildingLevel then return nil,"E_BUILDING_VERSION" end
		local signature=action..":"..padId..":"..instanceId..":"..revision
		local previous=requests[faction..":"..requestId]
		if previous then return nil,if previous==signature then "E_DUPLICATE_REQUEST" else "E_REQUEST_CONFLICT" end
		local record,reason=owned(faction,padId); if not record then return nil,reason end
		if record.instanceId~=instanceId or record.revision~=revision then return nil,"E_STALE_BUILDING" end
		return record,"OK"
	end
	function api.TryUpgrade(faction: Faction,padId: string,instanceId: string,revision: number,requestId: string,epoch: number): (boolean,string)
		return locked(padId,function(): (boolean,string)
			local record,reason=managementRequest(faction,padId,instanceId,revision,requestId,epoch,"Upgrade"); if not record then return false,reason end
			local allowed,code=api.CanUpgrade(faction,padId); if not allowed then return false,code end
			local cost=Levels.UpgradeCost(record.buildingId)
			local ok,result=pcall(upgradeVisual,record.model,faction)
			if not ok then return false,"E_UPGRADE_VISUAL" end
			local visual=result :: Folder
			if visual.Parent~=nil then return false,"E_UPGRADE_VISUAL" end
			local oldSpent=record.totalSpent; local oldLevel=record.level
			local function rollback(): ()
				visual:Destroy(); record.level=oldLevel; record.revision=revision; record.totalSpent=oldSpent
				record.model:SetAttribute("Level",oldLevel); record.model:SetAttribute("Revision",revision); record.model:SetAttribute("TotalSpent",oldSpent)
			end
			local staged=pcall(function(): ()
				visual.Parent=record.model; record.level+=1; record.revision+=1; record.totalSpent+=cost
				record.model:SetAttribute("Level",record.level); record.model:SetAttribute("Revision",record.revision); record.model:SetAttribute("TotalSpent",record.totalSpent)
			end)
			if not staged then rollback(); return false,"E_UPGRADE_VISUAL" end
			local paid,paymentCode=economy.TrySpendGold(faction,cost,"upgrade:"..requestId,epoch)
			if not paid then rollback(); return false,paymentCode end
			requests[faction..":"..requestId]="Upgrade:"..padId..":"..instanceId..":"..revision
			notify(); return true,"OK"
		end)
	end
	function api.TrySell(faction: Faction,padId: string,instanceId: string,revision: number,requestId: string,epoch: number): (boolean,string)
		return locked(padId,function(): (boolean,string)
			local record,reason=managementRequest(faction,padId,instanceId,revision,requestId,epoch,"Sell"); if not record then return false,reason end
			local refund=Levels.Refund(record.totalSpent); local pad=pads[padId]
			local function rollback(): () records[padId]=record; pad.part:SetAttribute("IsOccupied",true); record.model.Parent=activeFolder end
			local staged=pcall(function(): () records[padId]=nil; pad.part:SetAttribute("IsOccupied",false); record.model.Parent=nil end)
			if not staged then rollback(); return false,"E_SELL_PREPARATION" end
			local credited,code=economy.AddGold(faction,refund,"sell:"..requestId,epoch)
			if not credited then rollback(); return false,code end
			requests[faction..":"..requestId]="Sell:"..padId..":"..instanceId..":"..revision
			record.model:Destroy(); notify(); return true,"OK"
		end)
	end
	function api.ClearBuildings(): ()
		for padId,record in records do record.model:Destroy(); local pad=pads[padId]; if pad.part.Parent==padsFolder then pad.part:SetAttribute("IsOccupied",false) end end
		table.clear(records); table.clear(requests); onChanged()
	end
	return table.freeze(api)
end
return table.freeze(BuildingService)
