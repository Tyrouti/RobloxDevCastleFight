--!strict
-- Editor-only, explicit call. Installed from disk by tools/build-map-tools.mjs.
local Config = require(script.Parent.MapConfig)
local RunService = game:GetService("RunService")
local History = game:GetService("ChangeHistoryService")
local Storage = game:GetService("ServerStorage")
local Http = game:GetService("HttpService")
local Art = require(script.Parent.ArenaVisuals)
local Builder = {}
export type Report = { passed: boolean, errors: {string}, parts: number, pads: number, routeLengths: {[string]: number} }
type Options = { expectedPlaceId: number, backupConfirmed: boolean }

local function guard(expectedPlaceId: number): ()
	assert(RunService:IsStudio() and RunService:IsEdit(), "E_EDIT_ONLY")
	assert(game.PlaceId == expectedPlaceId, "E_WRONG_PLACE")
	assert(not workspace:FindFirstChild("KnightVisualTest") and not workspace:FindFirstChild("AssetVisualTest"), "E_ASSET_TEST_PLACE")
end
local function folder(parent: Instance, name: string): Folder
	local result = Instance.new("Folder"); result.Name = name; result.Parent = parent; return result
end
local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?, solid: boolean?): Part
	local result = Instance.new("Part")
	result.Name = name; result.Size = size; result.CFrame = CFrame.new(Config.origin + position)
	result.Color = color; result.Material = material or Enum.Material.SmoothPlastic
	result.Anchored = true; result.CanCollide = solid == true; result.CanTouch = false; result.CanQuery = solid == true
	result.TopSurface = Enum.SurfaceType.Smooth; result.BottomSurface = Enum.SurfaceType.Smooth
	result.Parent = parent; return result
end
local function marker(parent: Instance, name: string, position: Vector3): Part
	local result = part(parent, name, Vector3.one, position, Color3.new(1,1,1))
	result.Transparency = 1; return result
end
local function recording(name: string, operation: () -> ()): ()
	local ok, id = pcall(function(): string? return History:TryBeginRecording(name) end)
	local success, failure = pcall(function(): boolean operation(); return true end)
	if ok and id then History:FinishRecording(id, if success then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel) end
	if not success then error(failure) end
end
local function ownedMap(): Model
	local all = {}; for _, child in workspace:GetChildren() do if child.Name == "Map" then table.insert(all, child) end end
	assert(#all == 1, "E_MAP_MISSING_OR_DUPLICATE")
	local map = all[1]; assert(map:IsA("Model") and map:GetAttribute("SceneId") == Config.sceneId, "E_FOREIGN_MAP")
	return map
end

local function terrainAndDecor(map: Model): ()
 local ground = folder(map, "Territories")
 for _, def in {{name="HumanTerritory",x=-65,width=70}, {name="NeutralZone",x=0,width=60}, {name="UndeadTerritory",x=65,width=70}} do
  local tile=part(ground,def.name,Vector3.new(def.width,2,Config.size.Z),Vector3.new(def.x,1,0),Color3.fromRGB(105,112,103),Enum.Material.Ground,true)
  tile:SetAttribute("MinX",def.x-def.width/2); tile:SetAttribute("MaxX",def.x+def.width/2)
 end
 Art.Ground(map)
end

local function lanesAndPads(map: Model): ()
	local lanes=folder(map,"Lanes"); local pads=folder(map,"BuildPads")
	for _, lane in Config.lanes do
		local laneModel=Instance.new("Model"); laneModel.Name=lane.name; laneModel.Parent=lanes; laneModel:SetAttribute("LaneId",lane.id)
		part(laneModel,"Road",Vector3.new(156,.15,Config.laneWidth),Vector3.new(0,2.075,lane.z),Color3.fromRGB(153,151,139),Enum.Material.Cobblestone,true)
		Art.Road(laneModel, lane.z)
		local routes=folder(laneModel,"Waypoints")
		for _,faction in {"Human","Undead"} do
			local route=folder(routes,faction)
			for index=1,#Config.waypointXs do
				local x=Config.waypointXs[if faction=="Human" then index else #Config.waypointXs+1-index]
				local point=marker(route,string.format("%02d",index),Vector3.new(x,Config.laneSurfaceY,lane.z))
				point:SetAttribute("Order",index); point:SetAttribute("LaneId",lane.id); point:SetAttribute("OwnerFaction",faction)
			end
		end
		for _,faction in {"Human","Undead"} do
			local sign=if faction=="Human" then 1 else -1
			for index,x in Config.humanPadXs do
				local distance=if index%2==1 then Config.padZ else Config.padInnerZ
				local z=if lane.z<0 then -distance else distance
				local id=faction.."_"..lane.id.."_"..string.format("%02d",index)
				local pad=part(pads,id,Config.padSize,Vector3.new(sign*x,2.15,z),if faction=="Human" then Color3.fromRGB(148,184,198) else Color3.fromRGB(130,111,156),Enum.Material.Slate,true)
				pad:SetAttribute("PadId",id); pad:SetAttribute("OwnerFaction",faction); pad:SetAttribute("LaneId",lane.id); pad:SetAttribute("IsOccupied",false)
				local spawn=Instance.new("Attachment"); spawn.Name="SpawnPoint"; spawn.Position=Vector3.new(0,.15,if lane.z>z then 6 else -6); spawn.Parent=pad
				local entry=Instance.new("Attachment"); entry.Name="LaneEntry"; entry.Position=Vector3.new(0,0,lane.z-z); entry.Parent=pad
				Art.Pad(pad)
			end
		end
	end
end

function Builder.Check(map: Model?): Report
	local root=map or ownedMap()
	local errors: {string}={}; local function check(ok: boolean, message: string): () if not ok then table.insert(errors,message) end end
	check(root:GetAttribute("SceneId")==Config.sceneId,"E_SCENE_ID")
	local parts=0; local paths: {[string]:boolean}={}
	for _,obj in root:GetDescendants() do
		if obj:IsA("BasePart") then parts+=1; check(obj.Anchored,"E_UNANCHORED:"..obj.Name) end
		local path=obj:GetFullName(); check(not paths[path],"E_DUPLICATE_NAME:"..path); paths[path]=true
	end
	local pads=root:FindFirstChild("BuildPads"); local count=0; local ids: {[string]:boolean}={}; local groups: {[string]:number}={}
	if pads then for _,obj in pads:GetChildren() do
		count+=1; check(obj:IsA("BasePart"),"E_PAD_TYPE")
		if not obj:IsA("BasePart") then continue end
		local id=tostring(obj:GetAttribute("PadId")); local faction=tostring(obj:GetAttribute("OwnerFaction")); local laneId=tostring(obj:GetAttribute("LaneId"))
		check(not ids[id],"E_PAD_DUPLICATE:"..id); ids[id]=true
		check(id==obj.Name and string.match(id,"^"..faction.."_"..laneId.."_0[1-5]$")~=nil,"E_PAD_ID:"..id)
		check(faction=="Human" or faction=="Undead","E_PAD_FACTION")
		check(laneId=="Upper" or laneId=="Lower","E_PAD_LANE")
		check(obj:GetAttribute("IsOccupied")==false,"E_PAD_OCCUPIED")
		local p=obj.Position-Config.origin; local half=obj.Size/2
		check((faction=="Human" and p.X+half.X<=-30) or (faction=="Undead" and p.X-half.X>=30),"E_PAD_TERRITORY:"..id)
		check(math.abs(p.X)+half.X<=100 and math.abs(p.Z)+half.Z<=Config.size.Z/2,"E_PAD_OUTSIDE")
		for _,lane in Config.lanes do check(math.abs(p.Z-lane.z)>=half.Z+Config.laneWidth/2,"E_PAD_ROAD_OVERLAP:"..id) end
		check(obj:FindFirstChild("SpawnPoint")~=nil and obj:FindFirstChild("LaneEntry")~=nil,"E_PAD_ACCESS:"..id)
		local key=faction..laneId; groups[key]=(groups[key] or 0)+1
	end end
	check(count==20,"E_PAD_COUNT")
	for _,f in {"Human","Undead"} do for _,l in {"Upper","Lower"} do check(groups[f..l]==5,"E_PAD_GROUP:"..f..l) end end
	local lengths: {[string]:number}={}; local lanes=root:FindFirstChild("Lanes")
	check(lanes~=nil and #lanes:GetChildren()==2,"E_LANE_COUNT")
	if lanes then for _,lane in Config.lanes do
		local model=lanes:FindFirstChild(lane.name); check(model~=nil,"E_LANE_MISSING")
		if not model then continue end
		local road=model:FindFirstChild("Road"); check(road~=nil and road:IsA("BasePart") and road.Size==Vector3.new(156,.15,12),"E_ROAD_SIZE")
		local routes=model:FindFirstChild("Waypoints")
		for _,f in {"Human","Undead"} do
			local route=routes and routes:FindFirstChild(f); local points: {Instance}=if route then route:GetChildren() else {}
			table.sort(points,function(a: Instance,b: Instance): boolean return a.Name<b.Name end)
			check(#points==7,"E_WAYPOINT_COUNT")
			local length=0; local previous: Vector3?=nil
			for i,obj in points do
				check(obj:IsA("BasePart") and obj:GetAttribute("Order")==i,"E_WAYPOINT_ORDER")
				if obj:IsA("BasePart") then
					local expectedX=Config.waypointXs[if f=="Human" then i else 8-i]
					check(expectedX~=nil and (obj.Position-(Config.origin+Vector3.new(expectedX,Config.laneSurfaceY,lane.z))).Magnitude<.001,"E_WAYPOINT_POSITION")
					if previous then length+=(obj.Position-previous).Magnitude end; previous=obj.Position
				end
			end
			lengths[lane.id..f]=length; check(math.abs(length-156)<.001,"E_ROUTE_LENGTH")
		end
	end end
	local territories=root:FindFirstChild("Territories")
	for _,definition in {{name="HumanTerritory",x=-65,width=70},{name="NeutralZone",x=0,width=60},{name="UndeadTerritory",x=65,width=70}} do
		local tile=territories and territories:FindFirstChild(definition.name)
		check(tile~=nil and tile:IsA("BasePart") and tile.Size==Vector3.new(definition.width,2,Config.size.Z)
			and tile.Position==Config.origin+Vector3.new(definition.x,1,0),"E_TERRITORY:"..definition.name)
	end
	local castles=root:FindFirstChild("Castles")
	for _,faction in {"Human","Undead"} do
		local model=castles and castles:FindFirstChild(faction.."Castle"); check(model~=nil,"E_CASTLE:"..faction)
		for _,lane in Config.lanes do
			local target=model and model:FindFirstChild(lane.id.."CastleTarget")
			check(target~=nil and target:IsA("BasePart") and target.Position==Config.origin+Vector3.new(if faction=="Human" then -78 else 78,Config.laneSurfaceY,lane.z),"E_CASTLE_TARGET")
		end
	end
	-- Axis-aligned Parts only. Test a 10-stud-wide, 8-stud-high army corridor.
	for _,obj in root:GetDescendants() do
		if not obj:IsA("BasePart") or not obj.CanCollide then continue end
		local p=obj.Position-Config.origin; local half=obj.Size/2
		if p.Y+half.Y<=Config.laneSurfaceY+.01 or p.Y-half.Y>=Config.laneSurfaceY+8 then continue end
		for _,lane in Config.lanes do
			check(not (math.abs(p.X)<78+half.X and math.abs(p.Z-lane.z)<5+half.Z),"E_ROUTE_OBSTACLE:"..obj.Name)
		end
	end
	if (root:GetAttribute("VisualRevision")=="17A" or root:GetAttribute("VisualRevision")=="17B") then
  for _,obj in root:GetDescendants() do
   check(not string.match(obj.Name,"^PadAccess_"),"E_PAD_ACCESS_ROAD:"..obj.Name)
   if obj:IsA("BasePart") and not obj.CanCollide and obj.Transparency<1 then
    check(not obj.CanQuery and not obj.CanTouch,"E_DECOR_INTERACTION:"..obj.Name)
    local cf=obj.CFrame; local half=obj.Size/2
    local extent=Vector3.new(math.abs(cf.RightVector.X)*half.X+math.abs(cf.UpVector.X)*half.Y+math.abs(cf.LookVector.X)*half.Z,
     math.abs(cf.RightVector.Y)*half.X+math.abs(cf.UpVector.Y)*half.Y+math.abs(cf.LookVector.Y)*half.Z,
     math.abs(cf.RightVector.Z)*half.X+math.abs(cf.UpVector.Z)*half.Y+math.abs(cf.LookVector.Z)*half.Z)
    local p=obj.Position-Config.origin
    if p.Y+extent.Y>Config.laneSurfaceY+0.3 then
     for _,lane in Config.lanes do
      check(not (math.abs(p.X)<78+extent.X and math.abs(p.Z-lane.z)<Config.laneWidth/2+extent.Z),"E_VISIBLE_ROUTE_OBSTACLE:"..obj.Name)
     end
    end
   end
  end
  if pads then for _,pad in pads:GetChildren() do
   local square=pad:FindFirstChild("SquareMarker")
   check(square~=nil and square:IsA("BasePart") and square.Size.X==square.Size.Z,"E_SQUARE_MARKER:"..pad.Name)
  end end
 end
 check(parts<=Config.maxParts,"E_PART_BUDGET")
	return {passed=#errors==0,errors=errors,parts=parts,pads=count,routeLengths=lengths}
end

function Builder.Prepare(expectedPlaceId: number): (Model, Report)
	guard(expectedPlaceId)
	local map=Instance.new("Model"); map.Name="Map"; map:SetAttribute("SceneId",Config.sceneId); map:SetAttribute("Version",Config.version)
	map:SetAttribute("VisualRevision", "17B"); map:SetAttribute("Origin",Config.origin); map:SetAttribute("Builder","CastleFightMapBuilder")
	local success,failure=pcall(function(): boolean
		terrainAndDecor(map); lanesAndPads(map); local castles=folder(map,"Castles"); Art.Crystal(castles,"Human"); Art.Crystal(castles,"Undead")
		return true
	end)
	if not success then map:Destroy(); error(failure) end
	local report=Builder.Check(map)
	if not report.passed then map:Destroy(); error("E_VALIDATION:"..table.concat(report.errors,",")) end
	return map,report
end

function Builder.Build(options: Options): (Model, Report)
	guard(options.expectedPlaceId); assert(options.backupConfirmed,"E_BACKUP_CONFIRMATION")
	assert(not workspace:FindFirstChild("Map"),"E_MAP_EXISTS_NO_OVERWRITE")
	local map,report=Builder.Prepare(options.expectedPlaceId)
	-- Publication is the only Workspace mutation; all validation happens off-tree.
	recording("Build Castle Fight Map",function(): () map.Parent=workspace end)
	Art.Lighting()
	return map,report
end

function Builder.Archive(expectedPlaceId: number, confirmedSceneId: string): string
	guard(expectedPlaceId); assert(confirmedSceneId==Config.sceneId,"E_SCENE_CONFIRMATION")
	-- Explicit rollback: preserve the entire owned map, never destroy an existing place.
	local map=ownedMap(); local name="Map_"..Http:GenerateGUID(false)
	recording("Archive Castle Fight Map",function(): ()
		local archive=Storage:FindFirstChild("CastleFightMapArchive")
		if archive then assert(archive:IsA("Folder"),"E_ARCHIVE_TYPE") else archive=folder(Storage,"CastleFightMapArchive") end
		map.Name=name; map.Parent=archive
	end)
	return "ServerStorage.CastleFightMapArchive."..name
end


-- In-place editor migration. Preserve the actual pads, castles, targets, roads and waypoint instances.
-- The caller must have already archived the complete pre-migration Map in ServerStorage.
function Builder.Redesign(expectedPlaceId: number): Report
 guard(expectedPlaceId)
 local map=ownedMap()
 local lanes=map:FindFirstChild("Lanes"); local pads=map:FindFirstChild("BuildPads"); local castles=map:FindFirstChild("Castles")
 assert(lanes and pads and castles,"E_STRUCTURE")
 assert(map:GetAttribute("VisualRevision")=="17A" or map:GetAttribute("VisualRevision")=="17B","E_EXPECT_ARENA17")
 local backup=Storage:FindFirstChild("Arena17B_Before")
 assert(backup and backup:FindFirstChild("Map"),"E_BACKUP_REQUIRED")
 recording("Redesign Arena17A geometry",function(): ()
  local decor=map:FindFirstChild("Decorations"); assert(decor,"E_DECOR")
  decor:Destroy(); Art.Ground(map); task.wait()
  for _,lane in Config.lanes do
   local laneModel=lanes:FindFirstChild(lane.name); assert(laneModel,"E_LANE")
   for _,obj in laneModel:GetChildren() do
    if obj.Name~="Road" and obj.Name~="Waypoints" then obj:Destroy() end
   end
   Art.Road(laneModel,lane.z); task.wait()
   for _,faction in {"Human","Undead"} do
    local sign=if faction=="Human" then 1 else -1
    for i,x in Config.humanPadXs do
     local id=faction.."_"..lane.id.."_"..string.format("%02d",i)
     local pad=pads:FindFirstChild(id); assert(pad and pad:IsA("BasePart"),"E_PAD")
     assert(pad:GetAttribute("IsOccupied")==false,"E_OCCUPIED_PAD")
     for _,obj in pad:GetChildren() do if obj:IsA("BasePart") then obj:Destroy() end end
     local distance=if i%2==1 then Config.padZ else Config.padInnerZ
     local z=if lane.z<0 then -distance else distance
     pad.Position=Config.origin+Vector3.new(sign*x,2.15,z)
     local spawn=pad:FindFirstChild("SpawnPoint"); local entry=pad:FindFirstChild("LaneEntry")
     assert(spawn and spawn:IsA("Attachment") and entry and entry:IsA("Attachment"),"E_ATTACHMENTS")
     spawn.Position=Vector3.new(0,.15,if lane.z>z then 6 else -6)
     entry.Position=Vector3.new(0,0,lane.z-z)
     Art.Pad(pad)
    end
   end
  end
  for _,faction in {"Human","Undead"} do
   local castle=castles:FindFirstChild(faction.."Castle"); assert(castle and castle:IsA("Model"),"E_CASTLE")
   for _,obj in castle:GetChildren() do
    if obj.Name~="Foundation" and obj.Name~="Keep" and not string.match(obj.Name,"CastleTarget$") then obj:Destroy() end
   end
   Art.DressCrystal(castle,faction); task.wait()
  end
  map:SetAttribute("VisualRevision","17B"); Art.Lighting()
 end)
 return Builder.Check(map)
end

function Builder.View(angle: boolean?): ()
	ownedMap(); local camera=workspace.CurrentCamera; assert(camera,"E_CAMERA")
	camera.CameraType=Enum.CameraType.Fixed
	local target=Config.origin+Vector3.new(0,3,0)
	camera.CFrame=CFrame.lookAt(target+(if angle then Vector3.new(120,155,165) else Vector3.new(0,210,95)),target)
	game:GetService("Selection"):Set({})
end
return table.freeze(Builder)
