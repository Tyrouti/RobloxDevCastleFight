--!strict
-- Explicit migration of the existing P19 map, invoked only after Save As to P20.
local Config=require(script.Parent.MapConfig)
local Correction={}
local function make(parent: Instance,name: string,size: Vector3,pos: Vector3,color: Color3,material: Enum.Material,solid: boolean): Part
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=Config.origin+pos;p.Color=color;p.Material=material
 p.Anchored=true;p.CanCollide=solid;p.CanQuery=solid;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
function Correction.Apply(): {parts: number,roadLength: number,routeLength: number}
 assert(game:GetService("RunService"):IsEdit() and game.PlaceId==0,"E_EDITOR_ONLY")
 assert(game.Name=="CastleFight_Arena17B_P20_Fixed.rbxl","E_WRONG_FILE")
 assert(Config.size.X==280 and Config.laneHalfLength==114,"E_STALE_CONFIG")
 local map=workspace:FindFirstChild("Map");assert(map and map:IsA("Model") and map:GetAttribute("ExpansionRevision")=="19","E_P19_REQUIRED")
 assert(game.ServerStorage:FindFirstChild("Arena20Before") and not map:GetAttribute("Correction20"),"E_BACKUP_OR_ALREADY_APPLIED")
 local origin=Config.origin
 -- Remove only the known P19 exterior, whose broad visible floor caused the gray plane.
 local old=map:FindFirstChild("Exterior19");assert(old);old:Destroy()
 local territories=map:FindFirstChild("Territories");assert(territories)
 for _,p in territories:GetChildren() do
  assert(p:IsA("BasePart"));local sign=if p.Name=="HumanTerritory" then -1 elseif p.Name=="UndeadTerritory" then 1 else 0
  p.Size=Vector3.new(if sign==0 then 60 else 110,2,150);p.Position=origin+Vector3.new(sign*85,1,0)
  p:SetAttribute("MinX",p.Position.X-p.Size.X/2);p:SetAttribute("MaxX",p.Position.X+p.Size.X/2)
 end
 local decor=map:FindFirstChild("Decorations");assert(decor)
 for _,o in decor:GetChildren() do
  if o:IsA("Model") then
   local cf=o:GetPivot();local localX=cf.X-origin.X;o:PivotTo(cf+Vector3.new(localX*.4,0,0))
  elseif o:IsA("BasePart") then
   o.CFrame+=Vector3.new((o.Position.X-origin.X)*.4,0,0)
   if o.Size.X>100 or string.match(o.Name,"^TerrainMosaic") then o.Size=Vector3.new(o.Size.X*1.4,o.Size.Y,o.Size.Z) end
  end
 end
 local lanes=map:FindFirstChild("Lanes");local pads=map:FindFirstChild("BuildPads");local castles=map:FindFirstChild("Castles");assert(lanes and pads and castles)
 for _,lane in Config.lanes do
  local lm=lanes:FindFirstChild(lane.name);assert(lm)
  local road=lm:FindFirstChild("Road") :: BasePart;local oldZ=road.Position.Z
  for _,p in lm:GetDescendants() do
   if p:IsA("BasePart") and not p:IsDescendantOf(lm:FindFirstChild("Waypoints") :: Instance) then
    p.CFrame+=Vector3.new((p.Position.X-origin.X)*(228/156-1),0,origin.Z+lane.z-oldZ)
    p.Size=Vector3.new(p.Size.X*228/156,p.Size.Y,p.Size.Z)
   end
  end
  road.Size=Vector3.new(228,.15,12);road.Position=origin+Vector3.new(0,2.075,lane.z)
  local waypoints=lm:FindFirstChild("Waypoints");assert(waypoints)
  for _,faction in {"Human","Undead"} do
   local route=waypoints:FindFirstChild(faction);assert(route);route:ClearAllChildren()
   for i=1,#Config.waypointXs do
    local x=Config.waypointXs[if faction=="Human" then i else #Config.waypointXs+1-i]
    local z=if math.abs(x)==110 then math.sign(lane.z)*4 else lane.z
    local p=make(route,string.format("%02d",i),Vector3.one,Vector3.new(x,2.15,z),Color3.new(),Enum.Material.SmoothPlastic,false)
    p.Transparency=1;p:SetAttribute("Order",i);p:SetAttribute("LaneId",lane.id);p:SetAttribute("OwnerFaction",faction)
   end
  end
 end
 for _,pad in pads:GetChildren() do
  assert(pad:IsA("BasePart"));local faction=pad:GetAttribute("OwnerFaction");local sign=if faction=="Human" then -1 else 1
  local index=tonumber(string.match(pad.Name,"(%d+)$"));assert(index)
  local laneSign=if pad:GetAttribute("LaneId")=="Upper" then -1 else 1
  local z=laneSign*(if index%2==1 then 53.75 else 5)
  local pos=origin+Vector3.new(sign*math.abs(Config.humanPadXs[index]),2.15,z);local delta=pos-pad.Position
  for _,p in pad:GetDescendants() do if p:IsA("BasePart") then p.CFrame+=delta end end
  pad.Position=pos
  local spawn=pad:FindFirstChild("SpawnPoint") :: Attachment;local entry=pad:FindFirstChild("LaneEntry") :: Attachment
  spawn.Position=Vector3.new(0,0,math.sign(laneSign*20-z)*6)
  entry.Position=Vector3.new(0,0,laneSign*20-z)
 end
 for _,faction in {"Human","Undead"} do
  local castle=castles:FindFirstChild(faction.."Castle");assert(castle and castle:IsA("Model"))
  local sign=if faction=="Human" then -1 else 1
  castle:PivotTo(castle:GetPivot()+Vector3.new(sign*25,0,0))
  local foundation=castle:FindFirstChild("Foundation") :: BasePart
  foundation.Size=Vector3.new(42,.15,60);foundation.Position=origin+Vector3.new(sign*117,2.075,0)
  for _,p in castle:GetDescendants() do
   if p:IsA("BasePart") and string.match(p.Name,"^PlazaBorder") then p.Position=origin+Vector3.new(sign*117,2.19,math.sign(p.Position.Z-origin.Z)*29.5);p.Size=Vector3.new(42,.08,.55) end
  end
  for _,lane in Config.lanes do local target=castle:FindFirstChild(lane.id.."CastleTarget") :: BasePart;target.Position=origin+Vector3.new(sign*110,2.15,math.sign(lane.z)*4) end
 end
 local rim=Instance.new("Folder");rim.Name="BoundedLandscape20";rim.Parent=map
 -- Faceted buttresses and sloping rocks form a finite cliff, with no horizontal outside floor.
 for i=0,23 do
  for _,side in {-1,1} do
   local x=-138+i*12;local human=x<0;local stone=if human then Color3.fromRGB(114,139,135) else Color3.fromRGB(53,40,68)
   local height=9+(i%4)*2
   local p=make(rim,"Cliff"..i.."_"..side,Vector3.new(15,height,13),Vector3.new(x,-height/2+1,side*(77+(i%3))),stone,Enum.Material.Rock,true)
   p.CFrame*=CFrame.Angles(0,.07*(i%3-1),side*.13)
   if i%3==0 then
    local rock=make(rim,"Crest"..i.."_"..side,Vector3.new(11,4+i%5,8),Vector3.new(x,3,side*78),stone,Enum.Material.Rock,true);rock.CFrame*=CFrame.Angles(.12,.31*i,.16)
   end
  end
 end
 for _,side in {-1,1} do
  for i=0,11 do
   local stone=if side<0 then Color3.fromRGB(114,139,135) else Color3.fromRGB(53,40,68)
   local p=make(rim,"EndCliff"..side.."_"..i,Vector3.new(15,12+i%4,15),Vector3.new(side*(142+i%3),-5,-73+i*13),stone,Enum.Material.Rock,true)
   p.CFrame*=CFrame.Angles(.06*i,.13*i,.08*side)
  end
 end
 -- Catch floor is invisible and below the entire island. The original Baseplate is also hidden.
 local catch=make(rim,"InvisibleCatch",Vector3.new(340,2,220),Vector3.new(0,-24,0),Color3.new(),Enum.Material.SmoothPlastic,true);catch.Transparency=1
 local base=workspace:FindFirstChild("Baseplate");if base and base:IsA("BasePart") then base.Transparency=1;for _,d in base:GetDescendants() do if d:IsA("Texture") or d:IsA("Decal") then d.Transparency=1 end end end
 -- Invisible border stops normal player movement before the cliff edge, without a visible rectangular wall.
 for _,s in {-1,1} do
  local a=make(rim,"BoundaryZ"..s,Vector3.new(280,18,2),Vector3.new(0,7,s*75),Color3.new(),Enum.Material.SmoothPlastic,true);a.Transparency=1
  local b=make(rim,"BoundaryX"..s,Vector3.new(2,18,150),Vector3.new(s*139,7,0),Color3.new(),Enum.Material.SmoothPlastic,true);b.Transparency=1
 end
 local spawn=workspace:FindFirstChild("SpawnLocation");assert(spawn and spawn:IsA("SpawnLocation"));spawn.Position=origin+Vector3.new(0,3,64)
 map:SetAttribute("ArenaSize",Config.size);map:SetAttribute("Correction20",true)
 local n=0;for _,o in map:GetDescendants() do if o:IsA("BasePart") then n+=1 end end
 return {parts=n,roadLength=228,routeLength=192+2*math.sqrt(14^2+16^2)}
end
return table.freeze(Correction)
