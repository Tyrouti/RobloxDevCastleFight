--!strict
-- Explicit editor migration of the existing Arena17B. No Workspace sync or gameplay services.
local Config=require(script.Parent.MapConfig)
local Art=require(script.Parent.ArenaVisuals)
local Builder=require(script.Parent.MapBuilder)
local Expansion={}
local function part(parent: Instance,name: string,size: Vector3,p: Vector3,color: Color3,solid: boolean?): Part
 local o=Instance.new("Part");o.Name=name;o.Size=size;o.CFrame=CFrame.new(Config.origin+p)
 o.Anchored=true;o.CanCollide=solid==true;o.CanQuery=solid==true;o.CanTouch=false
 o.Color=color;o.Material=Enum.Material.Slate;o.TopSurface=Enum.SurfaceType.Smooth;o.BottomSurface=Enum.SurfaceType.Smooth;o.Parent=parent;return o
end
local function exterior(map: Model): ()
 local root=Instance.new("Model");root.Name="Exterior19";root.Parent=map
 -- A complete collidable floor covers the arena, the old spawn and every visible outside approach.
 for i=1,64 do
  local x=-520+i*16;local t=math.clamp((x+128)/256,0,1)
  local p=part(root,"WorldGround"..i,Vector3.new(16,2,2048),Vector3.new(x,-1,0),Color3.fromRGB(108,137,121):Lerp(Color3.fromRGB(48,42,62),t),true)
  p.Material=Enum.Material.Ground
 end
 for _,side in {-1,1} do
  local p=part(root,"DistantGround"..side,Vector3.new(1536,2,2048),Vector3.new(side*1280,-1,0),if side<0 then Color3.fromRGB(108,137,121) else Color3.fromRGB(48,42,62),true)
  p.Material=Enum.Material.Ground
 end
 for _,s in {-1,1} do
  local color=if s<0 then Color3.fromRGB(170,184,162) else Color3.fromRGB(64,52,79)
  local accent=if s<0 then Color3.fromRGB(100,216,246) else Color3.fromRGB(172,88,223)
  -- Small stepped courts connect the raised island to safe outside ground, without pad branches.
  for i=1,3 do
   part(root,"Terrace"..s.."_"..i,Vector3.new(26,.5,140-i*6),Vector3.new(s*(106+i*8),.25+i*.25,0),color,true)
  end
  for i=1,6 do
   for _,zsign in {-1,1} do
    local x=s*(30+i*19);local z=zsign*(102+(i%2)*11)
    local rock=part(root,"Ridge"..s..i..zsign,Vector3.new(15,5+(i%3)*2,12),Vector3.new(x,2,z),color)
    rock.CFrame*=CFrame.Angles(.12*i,.4*i,.1*zsign)
    part(root,"RuneStone"..s..i..zsign,Vector3.new(2,.18,2),Vector3.new(x,6+(i%3),z),accent).Material=Enum.Material.Neon
   end
  end
  local wall=part(root,"OuterBoundary"..s,Vector3.new(3,12,230),Vector3.new(s*151,4,0),color,true)
  wall.Material=Enum.Material.Rock;wall.Transparency=1
 end
 for _,s in {-1,1} do
  part(root,"FarBoundary"..s,Vector3.new(300,12,3),Vector3.new(0,4,s*116),Color3.fromRGB(64,67,77),true).Transparency=1
 end
 -- Reuse existing groves, keeping the original art and all source models intact.
 local decor=map:FindFirstChild("Decorations");assert(decor)
 local trees: {Model}={};for _,o in decor:GetChildren() do if o:IsA("Model") and string.match(o.Name,"^Tree") then table.insert(trees,o) end end
 local human: Model?=nil;local undead: Model?=nil
 for _,t in trees do if t:GetPivot().Position.X<Config.origin.X then human=t else undead=t end end
 for i=1,8 do
  local sign=if i<=4 then -1 else 1;local source=if sign<0 then human else undead;assert(source)
  local model=source:Clone();model.Name="OuterGrove"..i;model.Parent=root
  model:PivotTo(CFrame.new(Config.origin+Vector3.new(sign*(40+math.floor((i-1)%4)*22),6,if i%2==0 then 99 else -99)))
  task.wait()
 end
 -- Avoid a hard technical horizon while preserving the scene's existing Lighting effects.
 local lighting=game:GetService("Lighting");lighting.FogColor=Color3.fromRGB(100,111,135);lighting.FogStart=180;lighting.FogEnd=570
end
function Expansion.RefreshExterior(): Builder.Report
 assert(game:GetService("RunService"):IsEdit() and game.PlaceId==0,"E_TARGET")
 local map=workspace:FindFirstChild("Map");assert(map and map:IsA("Model") and map:GetAttribute("ExpansionRevision")=="19","E_MAP")
 local old=map:FindFirstChild("Exterior19");assert(old);old:Destroy();exterior(map)
 return Builder.Check(map)
end
function Expansion.Apply(): Builder.Report
 assert(game:GetService("RunService"):IsEdit() and game.PlaceId==0,"E_TARGET")
 local map=workspace:FindFirstChild("Map");assert(map and map:IsA("Model") and map:GetAttribute("VisualRevision")=="17B","E_ARENA17B")
 assert(map:GetAttribute("ExpansionRevision")==nil,"E_ALREADY_EXPANDED")
 assert(game.ServerStorage:FindFirstChild("Arena19Before"),"E_BACKUP_REQUIRED")
 local before=map:FindFirstChild("Territories");assert(before)
 for _,p in before:GetChildren() do assert(p:IsA("BasePart") and math.abs(p.Size.Z-120)<.01,"E_BEFORE_DIMENSIONS") end
 local history=game:GetService("ChangeHistoryService");local id=history:TryBeginRecording("Expand existing Arena17B")
 local ok,failure=pcall(function(): boolean
  for _,p in before:GetChildren() do if p:IsA("BasePart") then p.Size=Vector3.new(p.Size.X,p.Size.Y,Config.size.Z) end end
  local old=map:FindFirstChild("Decorations");assert(old);old:Destroy();Art.Ground(map)
  local lanes=map:FindFirstChild("Lanes");local pads=map:FindFirstChild("BuildPads");local castles=map:FindFirstChild("Castles");assert(lanes and pads and castles)
  for _,lane in Config.lanes do
   local model=lanes:FindFirstChild(lane.name);assert(model)
   local road=model:FindFirstChild("Road");assert(road and road:IsA("BasePart"))
   local delta=Vector3.new(0,0,Config.origin.Z+lane.z-road.Position.Z)
   for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.CFrame+=delta end end
   for _,faction in {"Human","Undead"} do
    for index,_ in Config.humanPadXs do
     local pad=pads:FindFirstChild(faction.."_"..lane.id.."_"..string.format("%02d",index));assert(pad and pad:IsA("BasePart"))
     assert(pad:GetAttribute("IsOccupied")==false,"E_PAD_OCCUPIED")
     local distance=if index%2==1 then Config.padZ else Config.padInnerZ
     local z=if lane.z<0 then -distance else distance
     local shift=Vector3.new(0,0,Config.origin.Z+z-pad.Position.Z)
     for _,o in pad:GetDescendants() do if o:IsA("BasePart") then o.CFrame+=shift end end
     pad.CFrame+=shift
     local entry=pad:FindFirstChild("LaneEntry");assert(entry and entry:IsA("Attachment"));entry.Position=Vector3.new(0,0,lane.z-z)
    end
   end
  end
  for _,castle in castles:GetChildren() do
   local f=castle:FindFirstChild("Foundation");assert(f and f:IsA("BasePart"));f.Size=Vector3.new(f.Size.X,f.Size.Y,Config.crystalPlazaDepth)
   for _,lane in Config.lanes do local p=castle:FindFirstChild(lane.id.."CastleTarget");assert(p and p:IsA("BasePart"));p.Position=Vector3.new(p.Position.X,p.Position.Y,Config.origin.Z+lane.z) end
   for _,p in castle:GetDescendants() do if p:IsA("BasePart") and string.match(p.Name,"^PlazaBorder") then p.Position=Vector3.new(p.Position.X,p.Position.Y,Config.origin.Z+math.sign(p.Position.Z-Config.origin.Z)*(Config.crystalPlazaDepth/2-.5)) end end
  end
  exterior(map)
  local base=workspace:FindFirstChild("Baseplate")
  if base and base:IsA("BasePart") then base.Transparency=1;for _,t in base:GetDescendants() do if t:IsA("Texture") or t:IsA("Decal") then t.Transparency=1 end end end
  local spawn=workspace:FindFirstChildWhichIsA("SpawnLocation")
  if spawn then spawn.CFrame=CFrame.new(Config.origin+Vector3.new(0,3,62));spawn.Enabled=true;spawn.Transparency=1;spawn.CanCollide=false
   for _,t in spawn:GetDescendants() do if t:IsA("Decal") or t:IsA("Texture") then t.Transparency=1 end end
  end
  map:SetAttribute("ExpansionRevision","19");map:SetAttribute("ArenaSize",Config.size)
  return true
 end)
 if id then history:FinishRecording(id,if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel) end
 if not ok then error(failure) end
 return Builder.Check(map)
end
return table.freeze(Expansion)
