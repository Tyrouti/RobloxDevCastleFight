--!strict
-- Run in Edit after installing disk-authored tools and building the arena.
local tools = game:GetService("ServerStorage").CastleFightArena17ATools
local Builder = require(tools.MapBuilder)
local Config = require(tools.MapConfig)
local Routes = require(game.ServerScriptService.CastleFightServer.LaneRoutes)
local map = workspace:FindFirstChild("Map")
assert(map and map:IsA("Model"), "E_MAP")
local tests: {string} = {}
local function expect(label: string, ok: boolean): ()
	assert(ok, label); table.insert(tests, label)
end
-- Sample both road footprints and the shared plaza continuously, including crystal centres.
local function covered(x: number,z: number): boolean
 local point=Config.origin+Vector3.new(x,Config.laneSurfaceY,z)
 for _,obj in map:GetDescendants() do
  if obj:IsA("BasePart") and obj.CanCollide then
   local p=obj.CFrame:PointToObjectSpace(point)
   if math.abs(p.X)<=obj.Size.X/2+.001 and math.abs(p.Z)<=obj.Size.Z/2+.001 and math.abs(p.Y-obj.Size.Y/2)<.01 then return true end
  end
 end
 return false
end
expect("two functional crystals",#map.Castles:GetChildren()==2)
for _,lane in Config.lanes do
 for x=-89,89 do expect("continuous road and plaza "..lane.id..x,covered(x,lane.z)) end
end
for _,sign in {-1,1} do
 for z=-23,23 do expect("common transverse approach "..sign..z,covered(sign*78,z)) end
 expect("crystal foundation contact "..sign,covered(sign*89,0))
end
local original=game.ServerStorage.Arena17B_Before.Map
for _,lane in Config.lanes do for _,faction in {"Human","Undead"} do
 for _,point in map.Lanes[lane.name].Waypoints[faction]:GetChildren() do
  expect("unchanged waypoint "..point:GetFullName(),point.Position==original.Lanes[lane.name].Waypoints[faction][point.Name].Position)
 end
end end
local count = 0
for _, obj in workspace:GetChildren() do if obj.Name == "Map" then count += 1 end end
expect("exactly one active Map", count == 1)
expect("17B visual revision", map:GetAttribute("VisualRevision") == "17B")
local routes = Routes.new(map)
for _, pad in map.BuildPads:GetChildren() do
	assert(pad:IsA("BasePart"))
	local faction = pad:GetAttribute("OwnerFaction")
	local lane = pad:GetAttribute("LaneId")
	assert(faction == "Human" or faction == "Undead")
	assert(lane == "Upper" or lane == "Lower")
	local path = routes.CreatePath(pad, lane, faction)
	expect("functional LaneEntry " .. pad.Name, #path.points > 0 and math.abs(path.start.Y - Config.laneSurfaceY) < 0.001)
	local marker = pad:FindFirstChild("SquareMarker")
	expect("square marker " .. pad.Name, marker ~= nil and marker:IsA("BasePart") and marker.Size.X == marker.Size.Z)
	-- Decorative bounds projected into the pad plane must stay outside its original footprint.
	for _, obj in map.Decorations:GetDescendants() do
		if not obj:IsA("BasePart") then continue end
		local cf = obj.CFrame; local half = obj.Size / 2
		local ex = math.abs(cf.RightVector.X)*half.X + math.abs(cf.UpVector.X)*half.Y + math.abs(cf.LookVector.X)*half.Z
		local ez = math.abs(cf.RightVector.Z)*half.X + math.abs(cf.UpVector.Z)*half.Y + math.abs(cf.LookVector.Z)*half.Z
		if obj.Position.Y + half.Y <= 2.1 then continue end
		expect("pad clearance " .. pad.Name .. "/" .. obj:GetFullName(), math.abs(obj.Position.X-pad.Position.X) >= ex+pad.Size.X/2 or math.abs(obj.Position.Z-pad.Position.Z) >= ez+pad.Size.Z/2)
	end
end
local before = #workspace:GetDescendants()
for _ = 1, 2 do
	local prepared, report = Builder.Prepare(game.PlaceId)
	expect("repeat offline build passes", report.passed and report.parts <= Config.maxParts)
	prepared:Destroy()
end
expect("offline rebuild leaves Workspace unchanged", #workspace:GetDescendants() == before)
local ok, failure = pcall(function(): boolean Builder.Build({expectedPlaceId=game.PlaceId,backupConfirmed=true}); return true end)
expect("repeat live build rejected", not ok and string.find(tostring(failure), "E_MAP_EXISTS", 1, true) ~= nil)
local clone = map:Clone()
local obstruction = Instance.new("Part"); obstruction.Name = "VisibleObstacle"; obstruction.Anchored = true
obstruction.CanCollide = false; obstruction.CanTouch = false; obstruction.CanQuery = false
obstruction.Size = Vector3.new(4,4,4); obstruction.Position = Config.origin + Vector3.new(0,5,23); obstruction.Parent = clone
expect("noncolliding visible road obstruction detected", not Builder.Check(clone).passed)
clone:Destroy()
return {passed=#tests, map=Builder.Check(map), twoOfflineRebuilds=true, liveDuplicateRejected=true}
