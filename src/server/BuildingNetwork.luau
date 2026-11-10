--!strict
local Types=require(game:GetService("ReplicatedStorage").CastleFightShared.Types)
local BuildingService=require(script.Parent.BuildingService)
export type Payload={action: string,padId: string,buildingId: Types.BuildingId?,instanceId: string?,revision: number?,requestId: string,matchId: number}
type Bucket={tokens: number,time: number}
local Network={}
function Network.Parse(payload: any): (Payload?,string)
	if typeof(payload)~="table" then return nil,"E_PAYLOAD" end
	local action=payload.action or "Build"
	if action~="Build" and action~="Upgrade" and action~="Sell" then return nil,"E_PAYLOAD" end
	local count=0
	for key in payload do
		count+=1
		local common=key=="action" or key=="padId" or key=="requestId" or key=="matchId"
		local specific=if action=="Build" then key=="buildingId" else key=="instanceId" or key=="revision"
		if count>6 or not (common or specific) then return nil,"E_PAYLOAD" end
	end
	for _,key in {"padId","requestId"} do
		if typeof(payload[key])~="string" or #payload[key]==0 or #payload[key]>64 then return nil,"E_PAYLOAD" end
	end
	local epoch=payload.matchId
	if typeof(epoch)~="number" or epoch~=epoch or epoch<1 or epoch>=math.huge or epoch%1~=0 then return nil,"E_PAYLOAD" end
	if action=="Build" then
		if typeof(payload.buildingId)~="string" or #payload.buildingId==0 or #payload.buildingId>64 then return nil,"E_PAYLOAD" end
	else
		if typeof(payload.instanceId)~="string" or #payload.instanceId==0 or #payload.instanceId>64 then return nil,"E_PAYLOAD" end
		local revision=payload.revision
		if typeof(revision)~="number" or revision%1~=0 or revision<1 or revision>2 then return nil,"E_PAYLOAD" end
	end
	local parsed: Payload={action=action :: string,padId=payload.padId,buildingId=payload.buildingId,instanceId=payload.instanceId,revision=payload.revision,requestId=payload.requestId,matchId=epoch}
	return parsed,"OK"
end
function Network.Connect(request: RemoteEvent,reply: RemoteEvent,getFaction: (Player) -> Types.FactionId?,buildings: BuildingService.Service): {Disconnect: () -> (),Forget: (Player) -> ()}
	local buckets: {[Player]:Bucket}={}
	local connection=request.OnServerEvent:Connect(function(player: Player,raw: any): ()
		local now=os.clock(); local bucket: Bucket=buckets[player] or {tokens=6,time=now}; buckets[player]=bucket
		bucket.tokens=math.min(6,bucket.tokens+(now-bucket.time)*2); bucket.time=now
		local payload,reason=Network.Parse(raw)
		local requestId=if payload then payload.requestId else ""
		if bucket.tokens<1 then reply:FireClient(player,requestId,false,"E_RATE_LIMIT",""); return end
		bucket.tokens-=1
		if not payload then reply:FireClient(player,requestId,false,reason,""); return end
		local faction=getFaction(player)
		if not faction then reply:FireClient(player,requestId,false,"E_NOT_ASSIGNED",payload.padId); return end
		local success,code=false,"E_PAYLOAD"
		if payload.action=="Build" then
			success,code=buildings.TryBuild(faction :: Types.FactionId,payload.padId,payload.buildingId :: Types.BuildingId,payload.requestId,payload.matchId)
		elseif payload.action=="Upgrade" then
			success,code=buildings.TryUpgrade(faction :: Types.FactionId,payload.padId,payload.instanceId :: string,payload.revision :: number,payload.requestId,payload.matchId)
		else
			success,code=buildings.TrySell(faction :: Types.FactionId,payload.padId,payload.instanceId :: string,payload.revision :: number,payload.requestId,payload.matchId)
		end
		reply:FireClient(player,payload.requestId,success,code,payload.padId,payload.action)
	end)
	return {
		Disconnect=function(): () connection:Disconnect(); table.clear(buckets) end,
		Forget=function(player: Player): () buckets[player]=nil end,
	}
end
return table.freeze(Network)
