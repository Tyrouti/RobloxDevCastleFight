--!strict
-- Explicit editor construction. Rojo synchronizes this module, never Workspace geometry.
local Config=require(game.ReplicatedStorage.CastleFightShared.Config.LobbyConfig)
local Builder={}
local STONE=Color3.fromRGB(126,137,148)
local PALE=Color3.fromRGB(192,195,184)
local DARK=Color3.fromRGB(55,53,73)
local GOLD=Color3.fromRGB(171,137,76)
local BLUE=Color3.fromRGB(96,206,240)
local PURPLE=Color3.fromRGB(171,104,227)
function Builder.Prepare(): Model
 local root=Instance.new("Model");root.Name=Config.modelName;root:SetAttribute("SystemOwner","CastleFightLobby23")
 local floor=Instance.new("Folder");floor.Name="Courtyard";floor.Parent=root
 local castle=Instance.new("Folder");castle.Name="CastleArchitecture";castle.Parent=root
 local gardens=Instance.new("Folder");gardens.Name="Gardens";gardens.Parent=root
 local portals=Instance.new("Folder");portals.Name="Portals";portals.Parent=root
 local function part(parent: Instance,name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material?,solid: boolean?): Part
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=CFrame.new(Config.origin)*cf;p.Color=color;p.Material=material or Enum.Material.Slate
  p.Anchored=true;p.CanCollide=solid~=false;p.CanTouch=false;p.CanQuery=solid~=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
 end
 local function block(parent: Instance,name: string,size: Vector3,pos: Vector3,color: Color3,material: Enum.Material?,solid: boolean?): Part
  return part(parent,name,size,CFrame.new(pos),color,material,solid)
 end
 local function disk(parent: Instance,name: string,pos: Vector3,radius: number,height: number,color: Color3,material: Enum.Material?,solid: boolean?): Part
  local p=part(parent,name,Vector3.new(height,radius*2,radius*2),CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2),color,material,solid);p.Shape=Enum.PartType.Cylinder;return p
 end
 local function beam(parent: Instance,name: string,a: Vector3,b: Vector3,width: number,color: Color3,material: Enum.Material?): Part
  return part(parent,name,Vector3.new(width,width,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,material,false)
 end
 local function lamp(parent: Instance,pos: Vector3,color: Color3): ()
  block(parent,"LanternFoot",Vector3.new(2.2,.5,2.2),pos+Vector3.new(0,.25,0),GOLD)
  block(parent,"LanternPost",Vector3.new(.5,6,.5),pos+Vector3.new(0,3,0),DARK,Enum.Material.Metal)
  local glass=block(parent,"LanternGlass",Vector3.new(1.3,1.9,1.3),pos+Vector3.new(0,6.6,0),color,Enum.Material.Neon,false)
  block(parent,"LanternCap",Vector3.new(2,.35,2),pos+Vector3.new(0,7.7,0),GOLD,Enum.Material.Metal,false)
  local light=Instance.new("PointLight");light.Color=color;light.Range=16;light.Brightness=.65;light.Shadows=false;light.Parent=glass
 end
 local function crystal(parent: Instance,pos: Vector3,color: Color3,scale: number): ()
  local p=part(parent,"Crystal",Vector3.new(1.4,3.2,1.4)*scale,CFrame.new(pos)*CFrame.Angles(0,math.pi/4,.1),color,Enum.Material.Neon,false)
  local tip=Instance.new("WedgePart");tip.Name="CrystalFacet";tip.Size=Vector3.new(1.4,1.8,1.4)*scale;tip.CFrame=p.CFrame*CFrame.new(0,2.1*scale,0);tip.Color=color;tip.Material=Enum.Material.Glass;tip.Anchored=true;tip.CanCollide=false;tip.CanTouch=false;tip.CanQuery=false;tip.Parent=parent
 end
 local function plaque(parent: Instance,pos: Vector3,size: Vector3,text: string,color: Color3): ()
  local p=part(parent,"Inscription",size,CFrame.new(pos)*CFrame.Angles(0,math.pi,0),DARK,Enum.Material.SmoothPlastic,false)
  local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=32;gui.LightInfluence=0;gui.Parent=p
  local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Text=text;label.TextColor3=color;label.Font=Enum.Font.GothamBold;label.TextScaled=true;label.TextWrapped=true;label.Parent=gui
 end
 -- Finite raised courtyard, with layered masonry and a continuous walkable floor.
 block(floor,"Foundation",Vector3.new(208,8,184),Vector3.new(0,-4,0),DARK,Enum.Material.Rock)
 block(floor,"PlazaStone",Vector3.new(196,.6,172),Vector3.new(0,-.05,0),STONE,Enum.Material.Cobblestone)
 disk(floor,"CentralMosaic",Vector3.new(0,.31,0),37,.15,Color3.fromRGB(152,155,153),Enum.Material.Marble)
 for ring=1,3 do for i=1,32 do
  local angle=i*math.pi/16;local radius=12+ring*8
  part(floor,"RadialPaving",Vector3.new(4.7,.12,2.4),CFrame.new(math.sin(angle)*radius,.43,math.cos(angle)*radius)*CFrame.Angles(0,angle,0),if ring==3 then GOLD else PALE,Enum.Material.Limestone,false)
 end end
 for _,x in {-53,53} do
  block(floor,"ProcessionalWalk",Vector3.new(24,.18,102),Vector3.new(x,.25,7),if x<0 then Color3.fromRGB(166,173,176) else Color3.fromRGB(100,100,122),Enum.Material.Slate)
  for _,side in {-1,1} do block(floor,"InlaidBrass",Vector3.new(.23,.1,100),Vector3.new(x+side*12,.4,7),GOLD,Enum.Material.Metal,false) end
  for z=-37,55,8 do block(floor,"WalkJoint",Vector3.new(23,.05,.13),Vector3.new(x,.37,z),Color3.fromRGB(78,85,96),Enum.Material.Slate,false) end
 end
 for _,side in {-1,1} do
  block(castle,"SideParapet",Vector3.new(3,8,170),Vector3.new(side*99,4,0),if side<0 then STONE else DARK)
  block(castle,"ParapetCoping",Vector3.new(4.2,.6,170),Vector3.new(side*99,8.2,0),GOLD,Enum.Material.Limestone)
  for z=-80,80,10 do
   block(castle,"Buttress",Vector3.new(5,10,3),Vector3.new(side*99,5,z),PALE)
   block(castle,"Crenel",Vector3.new(4,2,3.5),Vector3.new(side*99,9.5,z),STONE)
  end
  block(castle,"SouthernWall",Vector3.new(82,7,3),Vector3.new(side*57,3.5,84),STONE)
  block(castle,"SafetyBoundary",Vector3.new(1,30,185),Vector3.new(side*105,15,0),DARK).Transparency=1
 end
 block(castle,"RearKeep",Vector3.new(196,23,8),Vector3.new(0,11.5,-82),STONE)
 for x=-90,90,12 do
  block(castle,"KeepButtress",Vector3.new(3,27,11),Vector3.new(x,13.5,-81),PALE)
  block(castle,"Battlement",Vector3.new(5,4,9),Vector3.new(x,25,-82),STONE)
 end
 block(castle,"RearCornice",Vector3.new(196,1,10),Vector3.new(0,22,-82),GOLD,Enum.Material.Limestone)
 for _,z in {-93,93} do local guard=block(castle,"SafetyBoundary",Vector3.new(210,30,1),Vector3.new(0,15,z),DARK);guard.Transparency=1 end
 local function tower(x: number,z: number,color: Color3): ()
  disk(castle,"TowerPlinth",Vector3.new(x,1,z),10,2,DARK)
  disk(castle,"TowerShaft",Vector3.new(x,19,z),8.2,36,STONE)
  for _,y in {5,15,27,36} do disk(castle,"TowerStringcourse",Vector3.new(x,y,z),8.8,.7,PALE) end
  disk(castle,"TowerCrown",Vector3.new(x,37,z),10,2,GOLD)
  for i=1,10 do local a=i*math.pi/5
   part(castle,"TowerMerlon",Vector3.new(3,4,3),CFrame.new(x+math.sin(a)*8.8,39.5,z+math.cos(a)*8.8)*CFrame.Angles(0,a,0),STONE)
  end
  block(castle,"TowerWindow",Vector3.new(2.4,7,.25),Vector3.new(x,24,z+8.2),color,Enum.Material.Neon,false)
  crystal(castle,Vector3.new(x,43,z),color,1.2)
 end
 tower(-91,-75,BLUE);tower(91,-75,PURPLE);tower(-25,-82,BLUE);tower(25,-82,PURPLE)
 plaque(castle,Vector3.new(0,29,-75),Vector3.new(40,6,.4),"CASTLE FIGHT",Color3.fromRGB(235,209,143))
 plaque(castle,Vector3.new(0,20,-77),Vector3.new(34,3,.3),"TWO KINGDOMS · ONE DESTINY",PALE)
 for _,x in {-42,42} do
  block(castle,"BannerPole",Vector3.new(15,.3,.3),Vector3.new(x,23,-75),GOLD,Enum.Material.Metal,false)
  block(castle,"FactionBanner",Vector3.new(10,14,.3),Vector3.new(x,15.5,-75),if x<0 then Color3.fromRGB(45,98,153) else Color3.fromRGB(85,47,114),Enum.Material.Fabric,false)
  crystal(castle,Vector3.new(x,16,-74.5),if x<0 then BLUE else PURPLE,.7)
 end
 -- Neutral magical fountain, with contrasting streams and a golden astrolabe.
 local fountain=Instance.new("Model");fountain.Name="ConfluenceFountain";fountain.Parent=root
 for level=0,2 do disk(fountain,"FountainStep",Vector3.new(0,.5+level*.65,-4),14-level,1,if level==2 then PALE else STONE) end
 disk(fountain,"Water",Vector3.new(0,2.25,-4),10,.25,Color3.fromRGB(91,159,181),Enum.Material.Glass,false).Transparency=.25
 for i=1,24 do local a=i*math.pi/12;part(fountain,"BasinRim",Vector3.new(3,1.3,1.6),CFrame.new(math.sin(a)*12,2.7,-4+math.cos(a)*12)*CFrame.Angles(0,a,0),PALE,Enum.Material.Marble) end
 disk(fountain,"CentralPedestal",Vector3.new(0,4,-4),3.8,4,DARK)
 disk(fountain,"GiltCapital",Vector3.new(0,6.1,-4),4.5,.5,GOLD,Enum.Material.Metal)
 crystal(fountain,Vector3.new(-1.25,9.2,-4),BLUE,1.35);crystal(fountain,Vector3.new(1.25,9.2,-4),PURPLE,1.35)
 for i=1,24 do local a=i*math.pi/12
  beam(fountain,"Astrolabe",Vector3.new(math.cos(a)*6,10+math.sin(a)*6,-4),Vector3.new(math.cos(a+.26)*6,10+math.sin(a+.26)*6,-4),.25,GOLD,Enum.Material.Metal)
 end
 for _,side in {-1,1} do for i=0,6 do
  block(fountain,"MagicCascade",Vector3.new(.5,1.7,.5),Vector3.new(side*(3+i*.85),6-i*.55,-4),if side<0 then BLUE else PURPLE,Enum.Material.Neon,false).Transparency=.35
 end end
 -- Portal architecture is distinct from the retained gameplay buildings.
 for _,id in Config.modeOrder do
  local def=Config.modes[id];local model=Instance.new("Model");model.Name=id;model:SetAttribute("ModeId",id);model.Parent=portals
  local c=def.position;local scale=if id=="Bot" or id=="Duel" then 1 else .65
  local stone=if id=="Bot" or id=="Teams" then PALE else DARK
  local function p(name: string,size: Vector3,pos: Vector3,color: Color3,mat: Enum.Material?,solid: boolean?): Part return block(model,name,size*scale,c+pos*scale,color,mat,solid) end
  p("PortalDais",Vector3.new(34,1.2,22),Vector3.new(0,.6,0),stone)
  p("ApproachStep",Vector3.new(36,.4,8),Vector3.new(0,.2,13),STONE)
  p("ApproachStep",Vector3.new(35,.8,5),Vector3.new(0,.4,10),stone)
  for _,side in {-1,1} do
   p("ArchFoot",Vector3.new(6,2,7),Vector3.new(side*10,2,0),GOLD)
   p("ArchPier",Vector3.new(3.8,15,4.5),Vector3.new(side*10,10,0),stone)
   p("PierInlay",Vector3.new(.35,13,.3),Vector3.new(side*10,10,2.4),def.color,Enum.Material.Neon,false)
   p("PierCapital",Vector3.new(5,1.2,6),Vector3.new(side*10,17,0),GOLD)
  end
  for i=0,16 do local a=i*math.pi/16
   part(model,"ArchVoussoir",Vector3.new(2.4,3.7,5)*scale,CFrame.new(c+Vector3.new(math.cos(a)*10.2,17+math.sin(a)*10.2,0)*scale)*CFrame.Angles(0,0,a-math.pi/2),stone,Enum.Material.Limestone)
   part(model,"ArchRune",Vector3.new(.7,1.3,.25)*scale,CFrame.new(c+Vector3.new(math.cos(a)*10.2,17+math.sin(a)*10.2,2.65)*scale)*CFrame.Angles(0,0,a-math.pi/2),def.color,Enum.Material.Neon,false)
  end
  local core=p("PortalCore",Vector3.new(15,21,.45),Vector3.new(0,12,0),def.color,Enum.Material.Glass,false);core.Transparency=.55
  local glow=Instance.new("PointLight");glow.Color=def.color;glow.Range=20;glow.Brightness=.8;glow.Parent=core
  if id=="Duel" then p("HumanSigil",Vector3.new(1.4,6,.6),Vector3.new(-3.3,12,.7),BLUE,Enum.Material.Neon,false);p("UndeadSigil",Vector3.new(1.4,6,.6),Vector3.new(3.3,12,.7),PURPLE,Enum.Material.Neon,false) end
  plaque(model,c+Vector3.new(0,30,1)*scale,Vector3.new(30,4,.4)*scale,def.title,GOLD)
  plaque(model,c+Vector3.new(0,3.4,5.2)*scale,Vector3.new(26,2,.3)*scale,def.status,if def.available then BLUE else PALE)
  local anchor=p("Interaction",Vector3.new(2,3,2),Vector3.new(0,4,10),def.color,Enum.Material.SmoothPlastic,false);anchor.Transparency=1
  local prompt=Instance.new("ProximityPrompt");prompt.Name="ChooseMode";prompt.ObjectText=def.title;prompt.ActionText=if def.available then "Join queue" else "Details · COMING SOON"
  prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.GamepadKeyCode=Enum.KeyCode.ButtonX;prompt.MaxActivationDistance=Config.promptDistance;prompt.HoldDuration=.25;prompt.RequiresLineOfSight=false;prompt.ClickablePrompt=true;prompt.Style=Enum.ProximityPromptStyle.Custom;prompt.Parent=anchor
 end
 -- Gardens, seating and warm lanterns soften the courtyard and frame its paths.
 for _,side in {-1,1} do
  for _,z in {-47,3,58} do
   local x=side*84
   block(gardens,"RaisedBed",Vector3.new(17,1.1,17),Vector3.new(x,.6,z),if side<0 then PALE else DARK)
   block(gardens,"Earth",Vector3.new(15,.3,15),Vector3.new(x,1.3,z),if side<0 then Color3.fromRGB(69,91,65) else Color3.fromRGB(52,44,62),Enum.Material.Ground)
   block(gardens,"TreeTrunk",Vector3.new(1.8,13,1.8),Vector3.new(x,7.5,z),Color3.fromRGB(76,64,61),Enum.Material.Wood)
   for i=1,5 do local a=i*math.pi*.8
    local b=Vector3.new(x+math.cos(a)*4,12+i*.8,z+math.sin(a)*4)
    beam(gardens,"TreeBranch",Vector3.new(x,9,z),b,.8,Color3.fromRGB(75,65,71),Enum.Material.Wood)
    if side<0 then local leaf=block(gardens,"Canopy",Vector3.new(7,5,7),b+Vector3.new(0,1,0),if i%2==0 then Color3.fromRGB(92,129,107) else Color3.fromRGB(132,155,129),Enum.Material.Grass,false);leaf.Shape=Enum.PartType.Ball
    else crystal(gardens,b,PURPLE,.3) end
   end
   for i=1,5 do crystal(gardens,Vector3.new(x-6+i*2,2,z+5),if side<0 then BLUE else PURPLE,.18) end
  end
  for _,z in {-64,18,68} do lamp(gardens,Vector3.new(side*38,.4,z),if side<0 then Color3.fromRGB(180,224,240) else Color3.fromRGB(193,162,227)) end
  for _,z in {20,59} do
   block(gardens,"BenchSeat",Vector3.new(12,.6,3),Vector3.new(side*27,2,z),Color3.fromRGB(111,93,71),Enum.Material.Wood)
   for _,dx in {-4.3,4.3} do block(gardens,"BenchLeg",Vector3.new(.8,1.6,2),Vector3.new(side*27+dx,1,z),DARK,Enum.Material.Metal) end
  end
 end
 for i=1,28 do local a=i*math.pi/14
  part(floor,"CliffMasonry",Vector3.new(15,9,12),CFrame.new(math.sin(a)*104,-6,math.cos(a)*92)*CFrame.Angles(.1,a,.07),Color3.fromRGB(71,77,87),Enum.Material.Rock)
 end
 local spawn=Instance.new("SpawnLocation");spawn.Name="LobbySpawn";spawn.Size=Vector3.new(10,.3,10);spawn.CFrame=CFrame.new(Config.origin+Vector3.new(0,.55,48));spawn.Anchored=true;spawn.Neutral=true;spawn.Enabled=true;spawn.Duration=0;spawn.Transparency=1;spawn.CanCollide=false;spawn.CanTouch=false;spawn.Parent=root
 disk(floor,"ArrivalSeal",Vector3.new(0,.38,48),8,.16,PALE,Enum.Material.Marble)
 for i=1,16 do local a=i*math.pi/8;part(floor,"ArrivalRune",Vector3.new(.6,.08,1.1),CFrame.new(math.sin(a)*6.5,.5,48+math.cos(a)*6.5)*CFrame.Angles(0,a,0),GOLD,Enum.Material.Metal,false) end
 root.WorldPivot=CFrame.new(Config.origin)
 require(script.Parent.LobbyArtPass).Apply(root)
 return root
end
function Builder.Build(): any
 assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(),"E_EDIT_ONLY")
 assert(not workspace:FindFirstChild(Config.modelName),"E_LOBBY_ALREADY_EXISTS")
 local root=Builder.Prepare();root.Parent=workspace
 for _,obj in workspace:GetDescendants() do if obj:IsA("SpawnLocation") and not obj:IsDescendantOf(root) then obj:SetAttribute("Lobby23PreviouslyEnabled",obj.Enabled);obj.Enabled=false end end
 local count=0;for _,obj in root:GetDescendants() do if obj:IsA("BasePart") then count+=1 end end
 local portals=root:FindFirstChild("Portals");assert(portals)
 return {parts=count,origin=tostring(Config.origin),portals=#portals:GetChildren()}
end
return table.freeze(Builder)
