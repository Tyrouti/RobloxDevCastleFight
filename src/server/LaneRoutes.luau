--!strict
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local MapConfig=require(Shared.Config.MapConfig)
local Contact=require(script.Parent.CrystalContact)
type Route={points: {Vector3},direction: number,y: number,z: number}
export type Path={start: Vector3,points: {Vector3},direction: Vector3}
export type Context={spawn: Vector3,radius: number}
export type Routes={CreatePath: (BasePart,Types.LaneId,Types.FactionId,Context?) -> Path}
local LaneRoutes={}
local function child(parent: Instance,name: string): Instance
	local result=parent:FindFirstChild(name); assert(result,"E_ROUTE_MISSING:"..name); return result
end
function LaneRoutes.new(map: Instance): Routes
	local routes: {[string]:Route}={}
	for _,lane in MapConfig.lanes do
		local laneModel=child(child(map,"Lanes"),lane.name)
		assert(laneModel:GetAttribute("LaneId")==lane.id,"E_ROUTE_LANE")
		for _,faction in {"Human","Undead"} do
			local objects=child(child(laneModel,"Waypoints"),faction):GetChildren()
			table.sort(objects,function(a: Instance,b: Instance): boolean return a.Name<b.Name end)
			assert(#objects>=2 and #objects<=32,"E_ROUTE_COUNT")
			local points: {Vector3}={}; local direction=if faction=="Human" then 1 else -1
			for index,obj in objects do
				assert(obj:IsA("BasePart") and obj:GetAttribute("Order")==index and obj:GetAttribute("LaneId")==lane.id,"E_ROUTE_ORDER")
				local p=obj.Position
				assert((p.Z-MapConfig.origin.Z)*lane.z>0,"E_ROUTE_LANE_SIDE")
				if index>1 then local previous=points[index-1]; assert(direction*(p.X-previous.X)>0 and math.abs(p.Y-previous.Y)<.01,"E_ROUTE_GEOMETRY") end
				table.insert(points,p)
			end
			routes[lane.id..faction]={points=table.freeze(points),direction=direction,y=points[1].Y,z=MapConfig.origin.Z+lane.z}
		end
	end
	local routeLength: number?=nil
	for _,lane in MapConfig.lanes do
		local human=routes[lane.id.."Human"]; local undead=routes[lane.id.."Undead"]
		assert(#human.points==#undead.points,"E_ROUTE_PAIR")
		for index,point in human.points do assert((point-undead.points[#undead.points+1-index]).Magnitude<.01,"E_ROUTE_PAIR") end
		local length=0;for i=2,#human.points do length+=(human.points[i]-human.points[i-1]).Magnitude end
		assert(not routeLength or math.abs(length-routeLength)<.01,"E_ROUTE_LENGTH"); routeLength=length
	end
	assert(math.abs(routes.UpperHuman.z-routes.LowerHuman.z)>=MapConfig.laneWidth,"E_LANES_OVERLAP")
	return table.freeze({CreatePath=function(pad: BasePart,lane: Types.LaneId,faction: Types.FactionId,context: Context?): Path
		local route=routes[lane..faction]; assert(route,"E_ROUTE_ID")
		local entry=child(pad,"LaneEntry"); assert(entry:IsA("Attachment"),"E_LANE_ENTRY")
		local laneEntry=entry.WorldPosition
		if context then laneEntry=Vector3.new(context.spawn.X,laneEntry.Y,laneEntry.Z) end
		assert(math.abs(laneEntry.Z-route.z)<.01 and math.abs(laneEntry.Y-route.y)<.01,"E_LANE_ENTRY_POSITION")
		local spawn=child(pad,"SpawnPoint");assert(spawn:IsA("Attachment"),"E_SPAWN_POINT")
		local start=if context then context.spawn else spawn.WorldPosition
		assert((start-laneEntry).Magnitude>0 and math.abs(start.X-laneEntry.X)<.01,"E_PRODUCER_APPROACH")
		local remaining: {Vector3}={laneEntry}
		assert(route.direction*(laneEntry.X-route.points[2].X)>=0 and route.direction*(route.points[#route.points-1].X-laneEntry.X)>=0,"E_ENTRY_OUTSIDE_ROUTE")
		for _,point in route.points do if route.direction*(point.X-laneEntry.X)>.001 then table.insert(remaining,point) end end
		if context then
			local enemy=if faction=="Human" then "Undead" else "Human"
			local castle=child(child(map,"Castles"),enemy.."Castle");assert(castle:IsA("Model"))
			remaining[#remaining]=Contact.Stop(Contact.Read(castle),remaining[#remaining-1],remaining[#remaining],context.radius)
		end
		return {start=start,points=table.freeze(remaining),direction=(laneEntry-start).Unit}
	end})
end
return table.freeze(LaneRoutes)
