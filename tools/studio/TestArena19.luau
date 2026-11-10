--!strict
local Config=require(script.Parent.MapConfig)
local Builder=require(script.Parent.MapBuilder)
local Test={}
function Test.Run(): {passed: number,areaBefore: number,areaAfter: number,parts: number}
 local map=workspace:FindFirstChild("Map");assert(map and map:IsA("Model"))
 local old=game.ServerStorage:FindFirstChild("Arena19Before");assert(old)
 local backup=old:FindFirstChild("Map");assert(backup)
 local passed=0
 local function check(ok: boolean,message: string): () assert(ok,message);passed+=1 end
 local report=Builder.Check(map);check(report.passed,table.concat(report.errors,","))
 local maps=0;for _,o in workspace:GetChildren() do if o.Name=="Map" then maps+=1 end end;check(maps==1,"one active map")
 check(map:GetAttribute("ExpansionRevision")=="19","expansion revision")
 check(Config.size.X*Config.size.Z==30000,"real area +25 percent")
 local territories=map:FindFirstChild("Territories");assert(territories)
 for _,p in territories:GetChildren() do check(p:IsA("BasePart") and p.Size.Z==150,"territory depth") end
 local pads=map:FindFirstChild("BuildPads");assert(pads);check(#pads:GetChildren()==20,"twenty pads")
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={map}
 for x=-96,96,16 do for z=-70,70,10 do
  local result=workspace:Raycast(Config.origin+Vector3.new(x,70,z),Vector3.new(0,-100,0),params)
  check(result~=nil and result.Instance.CanCollide and result.Position.Y>=0,"safe continuous support")
 end end
 local lanes=map:FindFirstChild("Lanes");local castles=map:FindFirstChild("Castles");assert(lanes and castles)
 for _,lane in Config.lanes do
  for x=-89,89 do
   local hit=workspace:Raycast(Config.origin+Vector3.new(x,3,lane.z),Vector3.new(0,-2,0),params)
   check(hit~=nil and math.abs(hit.Position.Y-Config.laneSurfaceY)<.03,"road and shared plaza continuity")
  end
  local model=lanes:FindFirstChild(lane.name);assert(model)
  local routes=model:FindFirstChild("Waypoints");assert(routes)
  for _,route in routes:GetChildren() do
   local points=route:GetChildren();table.sort(points,function(a: Instance,b: Instance): boolean return a.Name<b.Name end)
   local length=0
   for i,p in points do assert(p:IsA("BasePart"));check(math.abs(p.Position.Z-Config.origin.Z-lane.z)<.001,"waypoint follows lane")
    if i>1 then local previous=points[i-1] :: BasePart;length+=(p.Position-previous.Position).Magnitude end
   end
   check(math.abs(length-156)<.001,"unchanged route length")
  end
 end
 for _,c in castles:GetChildren() do
  local oldCastle=backup:FindFirstChild("Castles"):FindFirstChild(c.Name);assert(oldCastle)
  for _,p in c:GetDescendants() do if p:IsA("BasePart") and string.match(p.Name,"^CrownCrystal") then
   local original=oldCastle:FindFirstChild(p.Name,true);assert(original and original:IsA("BasePart"))
   check(p.Size==original.Size and p.CFrame==original.CFrame,"main crystal geometry unchanged")
  end end
 end
 local plate=workspace:FindFirstChild("Baseplate");assert(plate and plate:IsA("BasePart"))
 check(plate.Transparency==1 and plate.CanCollide,"baseplate invisible, safety collision retained")
 for _,t in plate:GetDescendants() do if t:IsA("Texture") or t:IsA("Decal") then check(t.Transparency==1,"checker texture hidden") end end
 local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation");assert(spawn)
 check(spawn.Enabled and math.abs(spawn.Position.Z-Config.origin.Z)<=75,"spawn inside expanded arena")
 local hit=workspace:Raycast(spawn.Position+Vector3.new(0,20,0),Vector3.new(0,-60,0),params)
 check(hit~=nil and hit.Instance.CanCollide,"spawn has collidable support")
 return {passed=passed,areaBefore=24000,areaAfter=30000,parts=report.parts}
end
return table.freeze(Test)
