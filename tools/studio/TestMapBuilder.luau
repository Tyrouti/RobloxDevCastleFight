--!strict
-- Command Bar / MCP edit-time test. Never edits the live Map; mutation tests use unparented clones.
local tools = game:GetService("ServerStorage").CastleFightMapTools
local Builder = require(tools.MapBuilder)
local Config = require(tools.MapConfig)
local Territory = require(tools.TerritoryService).new(Config)
local map = workspace:FindFirstChild("Map")
assert(map and map:IsA("Model"), "Build map first")
local passed: {string} = {}
local function expect(name: string, result: boolean): ()
	assert(result, "FAIL: " .. name); table.insert(passed,name)
end
local function rejected(name: string, operation: () -> (), code: string): ()
	local ok, failure = pcall(function(): boolean operation(); return true end)
	expect(name,not ok and string.find(tostring(failure),code,1,true)~=nil)
end
local function at(x: number, z: number?): Vector3 return Config.origin+Vector3.new(x,3,z or 0) end
expect("live map structural report",Builder.Check(map).passed)
for _,case in {
	{x=-100,result="HumanTerritory"}, {x=-30.01,result="HumanTerritory"},
	{x=-30,result="NeutralZone"}, {x=0,result="NeutralZone"}, {x=30,result="NeutralZone"},
	{x=30.01,result="UndeadTerritory"}, {x=100,result="UndeadTerritory"},
	{x=-100.01,result="Outside"}, {x=100.01,result="Outside"},
} do expect("territory x="..case.x,Territory.GetTerritory(at(case.x))==case.result) end
expect("outside map width",Territory.GetTerritory(at(-50,60.1))=="Outside")
expect("NaN fails closed",Territory.GetTerritory(Vector3.new(0/0,3,0))=="Outside")
expect("infinity fails closed",Territory.GetTerritory(Vector3.new(math.huge,3,0))=="Outside")
expect("Human own enemy target",Territory.CanUseSwordOnUnit("Human","Undead",at(-60),at(-50)))
expect("Undead own enemy target",Territory.CanUseSwordOnUnit("Undead","Human",at(60),at(50)))
expect("friendly fire refused",not Territory.CanUseSwordOnUnit("Human","Human",at(-60),at(-50)))
expect("player outside own territory refused",not Territory.CanUseSwordOnUnit("Human","Undead",at(0),at(-50)))
expect("target outside own territory refused",not Territory.CanUseSwordOnUnit("Human","Undead",at(-60),at(0)))
expect("boundary target refused",not Territory.CanUseSwordOnUnit("Human","Undead",at(-60),at(-30)))
expect("outside arena refused",not Territory.CanUseSwordOnUnit("Undead","Human",at(60),at(101)))
expect("territory prism explicit",Territory.IsOwnTerritory("Human",at(-50)+Vector3.new(0,1000,0)))
rejected("duplicate build refused",function(): () Builder.Build({expectedPlaceId=game.PlaceId,backupConfirmed=true}) end,"E_MAP_EXISTS")
rejected("wrong place refused",function(): () Builder.Build({expectedPlaceId=-1,backupConfirmed=true}) end,"E_WRONG_PLACE")
rejected("backup acknowledgement required",function(): () Builder.Build({expectedPlaceId=game.PlaceId,backupConfirmed=false}) end,"E_BACKUP_CONFIRMATION")
rejected("wrong rollback scene refused",function(): () Builder.Archive(game.PlaceId,"foreign") end,"E_SCENE_CONFIRMATION")
local function tamper(name: string, change: (Model) -> ()): ()
	local clone=map:Clone(); assert(clone and clone:IsA("Model"))
	change(clone); local report=Builder.Check(clone); clone:Destroy(); expect(name,not report.passed)
end
local function child(parent: Instance, path: string): Instance
	local current=parent
	for name in string.gmatch(path,"[^/]+") do local nextChild=current:FindFirstChild(name); assert(nextChild,"Missing "..path); current=nextChild end
	return current
end
tamper("wrong PadId detected",function(copy: Model): () (child(copy,"BuildPads"):GetChildren()[1]):SetAttribute("PadId","bad") end)
tamper("pad road overlap detected",function(copy: Model): () local pad=child(copy,"BuildPads"):GetChildren()[1] :: BasePart; pad.Position=at(-50,-23) end)
tamper("territory geometry mismatch detected",function(copy: Model): () (child(copy,"Territories/HumanTerritory") :: BasePart).Size=Vector3.new(60,2,120) end)
tamper("waypoint order detected",function(copy: Model): () child(copy,"Lanes/TopLane/Waypoints/Human/01"):SetAttribute("Order",99) end)
tamper("missing waypoint detected",function(copy: Model): () child(copy,"Lanes/BottomLane/Waypoints/Undead/01"):Destroy() end)
tamper("foreign corridor obstacle detected",function(copy: Model): ()
	local block=Instance.new("Part"); block.Name="TestObstacle"; block.Anchored=true; block.Size=Vector3.new(4,8,4); block.Position=at(0,23); block.Parent=copy
end)
expect("live map unchanged after clone tests",Builder.Check(map).passed)
return {passed=#passed,tests=passed,map=Builder.Check(map),playtestPerformed=false,archiveSuccessTested=false}
