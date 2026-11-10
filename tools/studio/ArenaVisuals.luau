--!strict
-- Disk-authored editor art. Runtime identities live in MapBuilder; no new gameplay systems.
local Config = require(script.Parent.MapConfig)
local Art = {}
local creationCount=0
local IVORY = Color3.fromRGB(220, 226, 219)
local DARK = Color3.fromRGB(43, 38, 58)
local GOLD = Color3.fromRGB(191, 151, 70)
local BLUE = Color3.fromRGB(75, 205, 255)
local VIOLET = Color3.fromRGB(173, 76, 239)
local function piece(parent: Instance, name: string, size: Vector3, p: Vector3, color: Color3, material: Enum.Material?): Part
 local result = Instance.new("Part")
 result.Name=name; result.Size=size; result.CFrame=CFrame.new(Config.origin+p)
 result.Anchored=true; result.CanCollide=false; result.CanTouch=false; result.CanQuery=false
 result.Color=color; result.Material=material or Enum.Material.Slate
 result.TopSurface=Enum.SurfaceType.Smooth; result.BottomSurface=Enum.SurfaceType.Smooth
 result.Parent=parent
 creationCount+=1; if creationCount%64==0 then task.wait() end
 return result
end
local function group(parent: Instance, name: string): Model
 local model=Instance.new("Model"); model.Name=name; model.Parent=parent; return model
end
local function disc(parent: Instance, name: string, p: Vector3, radius: number, height: number, color: Color3, material: Enum.Material?): Part
 local result=piece(parent,name,Vector3.new(height,radius*2,radius*2),p,color,material)
 result.Shape=Enum.PartType.Cylinder; result.CFrame*=CFrame.Angles(0,0,math.pi/2); return result
end
local function glow(part: BasePart, color: Color3, range: number): ()
 local old=part:FindFirstChild("Glow")
 local light=if old and old:IsA("PointLight") then old else Instance.new("PointLight"); light.Name="Glow"; light.Color=color
 light.Range=range; light.Brightness=0.8; light.Shadows=false; light.Parent=part
end
local function beam(parent: Instance, name: string, a: Vector3, b: Vector3, width: number, color: Color3, material: Enum.Material?): Part
 local result=piece(parent,name,Vector3.new(width,width,(b-a).Magnitude),(a+b)/2,color,material)
 result.CFrame=CFrame.lookAt(Config.origin+(a+b)/2,Config.origin+b); return result
end
-- Two thin wedge solids span one triangular facet, using its longest edge as a basis.
local function triangle(parent: Instance,name: string,a: Vector3,b: Vector3,c: Vector3,color: Color3): BasePart
 local ab=b-a; local ac=c-a; local bc=c-b
 if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then a,c=c,a
 elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
 ab=b-a; ac=c-a; bc=c-b
 local right=ac:Cross(ab).Unit; local up=bc:Cross(right).Unit; local back=bc.Unit
 local height=math.abs(ab:Dot(up)); local first: BasePart?=nil
 for i=1,2 do
  local v=if i==1 then ab else ac
  local w=Instance.new("WedgePart"); w.Name=name.."_"..i
  w.Size=Vector3.new(.025,height,math.abs(v:Dot(back)))
  w.CFrame=CFrame.fromMatrix(Config.origin+(a+(if i==1 then b else c))/2,if i==1 then right else -right,up,if i==1 then back else -back)
  w.Anchored=true; w.CanCollide=false; w.CanQuery=false; w.CanTouch=false
  w.Material=Enum.Material.Glass; w.Color=color; w.Transparency=.05; w.Parent=parent
  if not first then first=w end
 end
 assert(first); return first
end
local function shard(parent: Instance,name: string,p: Vector3,scale: number,color: Color3): BasePart
 local ring: {Vector3}={}
 for i=1,4 do local a=i*math.pi/2+math.pi/4; table.insert(ring,p+Vector3.new(math.cos(a)*2*scale,.4*scale,math.sin(a)*2*scale)) end
 local top=p+Vector3.new(.4*scale,5.8*scale,0); local bottom=p-Vector3.new(.2*scale,3.25*scale,0)
 local first: BasePart?=nil
 for i=1,4 do
  local c=color:Lerp(if i%2==0 then Color3.new(1,1,1) else Color3.fromRGB(10,46,89),if i%2==0 then .22 else .2)
  local face=triangle(parent,name.."Upper"..i,top,ring[i],ring[i%4+1],c)
  triangle(parent,name.."Lower"..i,bottom,ring[i%4+1],ring[i],c)
  if not first then first=face end
 end
 piece(parent,name.."Heart",Vector3.new(.35,5,.35)*scale,p,color,Enum.Material.Neon)
 assert(first); return first
end
function Art.DressCrystal(model: Model, faction: string): ()
 local human=faction=="Human"; local sign=if human then -1 else 1
 local x=sign*89; local stone=if human then IVORY else DARK
 local trim=if human then GOLD else Color3.fromRGB(110,65,114); local accent=if human then BLUE else VIOLET
 model:SetAttribute("DisplayName",faction.." Crystal")
 local foundation=model:FindFirstChild("Foundation")
 assert(foundation and foundation:IsA("BasePart"),"E_FOUNDATION")
 foundation.Size=Vector3.new(32,.15,Config.crystalPlazaDepth); foundation.Position=Config.origin+Vector3.new(sign*84,2.075,0)
 foundation.Color=stone; foundation.Material=Enum.Material.Marble
 -- The common plaza overlaps both roads by ten studs, on exactly the same walkable plane.
 foundation:SetAttribute("CommonApproach",true)
 local art=group(model,"Sanctum17B")
 for _,z in {-Config.crystalPlazaDepth/2+.5,Config.crystalPlazaDepth/2-.5} do
  piece(art,"PlazaBorder"..z,Vector3.new(32,.08,.55),Vector3.new(sign*84,2.19,z),trim,Enum.Material.Metal)
 end
 for tier=1,3 do
  disc(art,"Octave"..tier,Vector3.new(x,2.1+tier*.65,0),10.5-tier*1.3,.65,if tier==2 then trim else stone,Enum.Material.Marble)
 end
 local keep=model:FindFirstChild("Keep"); assert(keep and keep:IsA("BasePart"),"E_KEEP")
 keep.Size=Vector3.new(5.6,13,5.6); keep.CFrame=CFrame.new(Config.origin+Vector3.new(x,13,0))*CFrame.Angles(0,math.pi/4,math.rad(8))
 keep.Color=accent; keep.Material=Enum.Material.Glass; keep.Transparency=1
 -- Keep is preserved for the existing HP billboard; embellishments belong to its castle.
 shard(art,"CrownCrystal",Vector3.new(x,13,0),2,accent)
 glow(keep,accent,35)
 for i=1,4 do
  local a=i*math.pi/2+math.pi/4
  shard(art,"Orbit"..i,Vector3.new(x+math.cos(a)*6.5,6.5,math.sin(a)*6.5),.6,accent)
 end
 for i=1,12 do
  local a=i*math.pi/6
  local rune=piece(art,"Rune"..i,Vector3.new(.38,.07,1.8),Vector3.new(x+math.cos(a)*10,2.2,math.sin(a)*10),accent,Enum.Material.Neon)
  rune.CFrame*=CFrame.Angles(0,-a,0)
 end
 for _,z in {-14,14} do
  local needle=piece(art,"Guardian"..z,Vector3.new(2,10,2),Vector3.new(sign*94,7.2,z),stone,Enum.Material.Marble)
  needle.CFrame*=CFrame.Angles(0,0,if human then 0 else math.rad(-sign*12))
  piece(art,"GuardianCrown"..z,Vector3.new(3,.5,3),Vector3.new(sign*94,12.4,z),trim,Enum.Material.Metal)
  shard(art,"GuardianFlame"..z,Vector3.new(sign*94,14,z),.4,accent)
  if not human then
   for rib=1,3 do
    beam(art,"Rib"..z.."_"..rib,Vector3.new(sign*(82+rib),3,z*.75),Vector3.new(sign*(83+rib),6+rib,z*.75+math.sign(z)*2),.45,Color3.fromRGB(176,167,150))
   end
  end
 end
end
function Art.Crystal(parent: Instance, faction: string): ()
 local model=group(parent,faction.."Castle"); model:SetAttribute("OwnerFaction",faction)
 local sign=if faction=="Human" then -1 else 1
 local foundation=piece(model,"Foundation",Vector3.one,Vector3.zero,IVORY); foundation.CanCollide=true; foundation.CanQuery=true
 for _,lane in Config.lanes do
  local target=piece(model,lane.id.."CastleTarget",Vector3.one,Vector3.new(sign*78,Config.laneSurfaceY,lane.z),BLUE)
  target.Transparency=1; target:SetAttribute("LaneId",lane.id)
 end
 local keep=piece(model,"Keep",Vector3.one,Vector3.zero,BLUE); model.PrimaryPart=keep
 Art.DressCrystal(model,faction)
end
local function tree(parent: Instance, x: number, z: number, human: boolean, index: number): ()
 local m=group(parent,"Tree"..index); local trunk=Color3.fromRGB(85,72,78)
 beam(m,"Trunk",Vector3.new(x,2,z),Vector3.new(x+.7,9,z),1.1,trunk,Enum.Material.Wood)
 for branch=1,3 do
  local a=branch*2.1; local endp=Vector3.new(x+math.cos(a)*3,10+branch*.7,z+math.sin(a)*2.5)
  beam(m,"Bough"..branch,Vector3.new(x,6+branch*.5,z),endp,.65,trunk,Enum.Material.Wood)
  if human then
   local c=piece(m,"Silverleaf"..branch,Vector3.new(5.5,3.7,4.5),endp,Color3.fromRGB(137+branch*12,180+branch*8,159+branch*9),Enum.Material.Grass)
   c.Shape=Enum.PartType.Ball
  else
   beam(m,"Claw"..branch,endp,endp+Vector3.new(math.cos(a),2,math.sin(a)),.3,trunk,Enum.Material.Wood)
  end
 end
 if human then
  piece(m,"Bloom",Vector3.new(.4,.6,.4),Vector3.new(x+1,5,z),BLUE,Enum.Material.Neon)
 else shard(m,"Blight",Vector3.new(x+2,3,z),.3,VIOLET) end
end
function Art.Ground(parent: Instance): ()
 local decor=group(parent,"Decorations")
 -- A sculpted bastion silhouette: layered perimeter, interrupted parapets, buttresses.
 piece(decor,"Undercroft",Vector3.new(204,5,122),Vector3.new(0,-2.6,0),Color3.fromRGB(35,39,51))
 piece(decor,"FloatingCornice",Vector3.new(207,.6,125),Vector3.new(0,-.4,0),Color3.fromRGB(114,111,126))
 for i=1,25 do
  local x=-104+i*8; local t=math.clamp((x+36)/72,0,1)
  local earth=Color3.fromRGB(117,153,137):Lerp(Color3.fromRGB(65,51,77),t)
  piece(decor,"TerrainMosaic"..i,Vector3.new(8,.06,120),Vector3.new(x,2.03,0),earth,Enum.Material.Ground)
  for _,s in {-1,1} do
   piece(decor,"Parapet"..i.."_"..s,Vector3.new(7.7,1,1.5),Vector3.new(x,2.5,s*59),IVORY:Lerp(DARK,t),Enum.Material.Marble)
   if i%3==0 then
    local b=piece(decor,"Buttress"..i.."_"..s,Vector3.new(4,5,5),Vector3.new(x,-.5,s*60),IVORY:Lerp(DARK,t))
    b.CFrame*=CFrame.Angles(math.rad(s*12),0,0)
   end
  end
 end
 -- Broad central sanctuary, lower than the lanes. No ornament enters an army corridor.
 disc(decor,"EclipseBasin",Vector3.new(0,2.07,0),15,.04,Color3.fromRGB(65,74,88),Enum.Material.Marble)
 disc(decor,"EclipseMirror",Vector3.new(0,2.1,0),12,.025,Color3.fromRGB(89,114,139),Enum.Material.Glass)
 for i=1,20 do
  local a=i*math.pi/10; local t=(math.cos(a)+1)/2
  local p=Vector3.new(math.cos(a)*13.5,2.17,math.sin(a)*13.5)
  local r=piece(decor,"EclipseArc"..i,Vector3.new(3.6,.1,.55),p,GOLD:Lerp(VIOLET,t),Enum.Material.Metal)
  r.CFrame*=CFrame.Angles(0,-a-math.pi/2,0)
 end
 for i=1,8 do
  local a=i*math.pi/4
  local r=piece(decor,"CompassRose"..i,Vector3.new(.3,.05,9),Vector3.new(math.cos(a)*5,2.15,math.sin(a)*5),BLUE:Lerp(VIOLET,(math.cos(a)+1)/2),Enum.Material.Metal)
  r.CFrame*=CFrame.Angles(0,-a+math.pi/2,0)
 end
 disc(decor,"CompassHeart",Vector3.new(0,2.17,0),1.8,.05,IVORY,Enum.Material.Marble)
 -- Perimeter groves leave a clean five-stud verge outside construction courts.
 for _,sign in {-1,1} do
  local human=sign==-1; local stone=if human then IVORY else DARK
  local accent=if human then BLUE else VIOLET
  for index,x in {28,52,77,93} do
   for _,z in {-54,54} do tree(decor,sign*x,z,human,(sign+2)*100+index*10+z) end
  end
  for index,x in {24,56} do
   for _,z in {-35,35} do
    local m=group(decor,"Wayshrine"..sign.."_"..index.."_"..z)
    disc(m,"Foot",Vector3.new(sign*x,2.35,z),2.3,.6,stone,Enum.Material.Marble)
    local column=piece(m,"Column",Vector3.new(1.8,5,1.8),Vector3.new(sign*x,5.1,z),stone,Enum.Material.Marble)
    if not human then column.CFrame*=CFrame.Angles(0,0,.18) end
    local lamp=disc(m,"Chalice",Vector3.new(sign*x,7.7,z),1.4,.5,if human then GOLD else DARK,Enum.Material.Metal)
    shard(m,"Flame",Vector3.new(sign*x,9,z),.35,accent); glow(lamp,accent,13)
   end
  end
  for index,x in {18,34,50,66} do
   for _,z in {-50,50} do
    local m=group(decor,"Planting"..sign..index..z)
    for j=1,3 do
     local p=Vector3.new(sign*x+(j-2)*1.1,2.6,z+math.sin(j)*.7)
     if human then
      local leaf=piece(m,"Leaf"..j,Vector3.new(.6,1.5,.7),p,Color3.fromRGB(109,183,153),Enum.Material.Grass)
      leaf.CFrame*=CFrame.Angles(0,j,math.rad(j*20))
      piece(m,"Starflower"..j,Vector3.new(.45,.3,.45),p+Vector3.new(0,.8,0),BLUE,Enum.Material.Neon)
     else
      beam(m,"Bone"..j,p,p+Vector3.new(.6,.7,.2),.25,Color3.fromRGB(170,156,143))
     end
    end
   end
  end
 end
 -- Expand open ground and grove spacing without stretching trees/crystals or changing route length.
 for _,obj in decor:GetChildren() do
  if string.match(obj.Name,"^Eclipse") or string.match(obj.Name,"^Compass") then continue end
  if obj:IsA("Model") then
   local cf=obj:GetPivot();local z=cf.Position.Z-Config.origin.Z
   obj:PivotTo(cf+Vector3.new(0,0,z*(Config.depthScale-1)))
  elseif obj:IsA("BasePart") then
   local z=obj.Position.Z-Config.origin.Z;obj.CFrame+=Vector3.new(0,0,z*(Config.depthScale-1))
   if string.match(obj.Name,"^TerrainMosaic") or obj.Name=="Undercroft" or obj.Name=="FloatingCornice" then obj.Size*=Vector3.new(1,1,Config.depthScale) end
  end
 end
end
function Art.Road(parent: Instance, z: number): ()
 for i=1,26 do
  local x=-81+i*6; local t=math.clamp((x+36)/72,0,1)
  local stone=IVORY:Lerp(Color3.fromRGB(83,70,102),t)
  -- The collidable Road below is continuous; fine mortar joints are purely decorative.
  for row=1,2 do
   piece(parent,"Flagstone"..i.."_"..row,Vector3.new(5.92,.025,5.6),Vector3.new(x,2.164,z+(row-1.5)*5.7),stone,Enum.Material.Marble)
  end
  for _,side in {-1,1} do
   piece(parent,"RoadBorder"..i.."_"..side,Vector3.new(6,.08,.5),Vector3.new(x,2.17,z+side*6.25),GOLD:Lerp(Color3.fromRGB(111,65,143),t),Enum.Material.Metal)
  end
  if i%3==0 then
   local rune=piece(parent,"LaneRune"..i,Vector3.new(.6,.02,1.6),Vector3.new(x,2.19,z),BLUE:Lerp(VIOLET,t),Enum.Material.Neon)
   rune.CFrame*=CFrame.Angles(0,math.pi/4,0)
  end
 end
end
function Art.Pad(pad: BasePart): ()
 pad.Transparency=1
 local p=pad.Position-Config.origin; local human=pad:GetAttribute("OwnerFaction")=="Human"
 local stone=if human then IVORY else DARK; local accent=if human then BLUE else VIOLET
 piece(pad,"SquareMarker",Vector3.new(7.8,.12,7.8),Vector3.new(p.X,2.27,p.Z),stone,Enum.Material.Marble)
 for _,s in {-1,1} do
  piece(pad,"FrameX"..s,Vector3.new(7.8,.07,.28),Vector3.new(p.X,2.365,p.Z+s*3.75),if human then GOLD else accent,Enum.Material.Metal)
  piece(pad,"FrameZ"..s,Vector3.new(.28,.07,7.8),Vector3.new(p.X+s*3.75,2.365,p.Z),if human then GOLD else accent,Enum.Material.Metal)
 end
 local rune=piece(pad,"PlacementRune",Vector3.new(2.2,.03,2.2),Vector3.new(p.X,2.35,p.Z),accent,Enum.Material.Neon)
 rune.CFrame*=CFrame.Angles(0,math.pi/4,0)
end
function Art.Lighting(): ()
 local l=game:GetService("Lighting")
 local storage=game:GetService("ServerStorage")
 if not storage:FindFirstChild("CastleFight17ALightingBackup") then
  local record=Instance.new("Folder"); record.Name="CastleFight17ALightingBackup"
  record:SetAttribute("ClockTime",l.ClockTime); record:SetAttribute("Brightness",l.Brightness)
  record:SetAttribute("Ambient",l.Ambient); record:SetAttribute("OutdoorAmbient",l.OutdoorAmbient)
  record:SetAttribute("ExposureCompensation",l.ExposureCompensation); record:SetAttribute("GlobalShadows",l.GlobalShadows)
  record.Parent=storage
 end
 l.ClockTime=14.2; l.Brightness=2.2; l.GlobalShadows=true
 l.Ambient=Color3.fromRGB(78,80,106); l.OutdoorAmbient=Color3.fromRGB(116,126,145); l.ExposureCompensation=-.15
end
return table.freeze(Art)
