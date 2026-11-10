--!strict
local Config=require(game.ReplicatedStorage.CastleFightShared.Config.LobbyConfig)
local Art={}
function Art.Apply(root: Model): ()
 assert(root:GetAttribute("SystemOwner")=="CastleFightLobby23" and not root:FindFirstChild("ArchitecturalDetail"),"E_LOBBY_ART_TARGET")
 local detail=Instance.new("Folder");detail.Name="ArchitecturalDetail";detail.Parent=root
 local gold=Color3.fromRGB(167,136,82);local pale=Color3.fromRGB(175,181,175);local dark=Color3.fromRGB(55,59,76)
 local function p(name: string,size: Vector3,cf: CFrame,color: Color3,material: Enum.Material?,solid: boolean?): Part
  local obj=Instance.new("Part");obj.Name=name;obj.Size=size;obj.CFrame=CFrame.new(Config.origin)*cf;obj.Color=color;obj.Material=material or Enum.Material.Slate;obj.Anchored=true;obj.CanCollide=solid~=false;obj.CanTouch=false;obj.CanQuery=solid~=false;obj.TopSurface=Enum.SurfaceType.Smooth;obj.BottomSurface=Enum.SurfaceType.Smooth;obj.Parent=detail;return obj
 end
 -- A finite rocky escarpment screens the distant arena rather than exposing a test-world horizon.
 for i=-3,3 do
  local height=if math.abs(i)==3 then 38 elseif math.abs(i)==2 then 55 elseif math.abs(i)==1 then 70 else 50
  local cliff=Instance.new("WedgePart");cliff.Name="RearEscarpment";cliff.Size=Vector3.new(48,height,64);cliff.CFrame=CFrame.new(Config.origin+Vector3.new(i*37,height/2-13,-122))*CFrame.Angles(0,(if i<0 then math.pi/2 else -math.pi/2)+math.rad(i*7),0)
  cliff.Color=Color3.fromRGB(93+i*2,105+i*2,113+i*2);cliff.Material=Enum.Material.Rock;cliff.Anchored=true;cliff.CanTouch=false;cliff.CastShadow=false;cliff.Parent=detail
  p("RockStratum",Vector3.new(38,18,36),CFrame.new(i*35,-5,-108)*CFrame.Angles(.12,i*.1,.1),dark,Enum.Material.Rock)
 end
 for _,side in {-1,1} do
  local accent=if side<0 then Color3.fromRGB(92,192,221) else Color3.fromRGB(167,111,213)
  -- Raised garden terraces make the arrival court a place to explore.
  p("ArrivalGarden",Vector3.new(35,1.6,21),CFrame.new(side*65,.9,67),pale)
  p("ArrivalEarth",Vector3.new(32,.35,18),CFrame.new(side*65,1.9,67),if side<0 then Color3.fromRGB(78,103,76) else Color3.fromRGB(55,47,67),Enum.Material.Ground)
  for n=1,7 do
   local x=side*65-14+n*3.5
   local stone=p("GardenCrystal",Vector3.new(.7,1.3+n%3*.3,.7),CFrame.new(x,3,73)*CFrame.Angles(0,.7,.2),accent,Enum.Material.Neon,false);stone.Transparency=.12
   local shrub=p("LowShrub",Vector3.new(4,2.1,4),CFrame.new(x,2.8,65),if side<0 then Color3.fromRGB(107,141,113) else Color3.fromRGB(82,69,100),Enum.Material.Grass,false);shrub.Shape=Enum.PartType.Ball
  end
  -- Open arcades frame the side gardens without creating extra game buildings.
  for z=-52,48,25 do
   for _,dz in {-7,7} do
    p("ArcadeBase",Vector3.new(4,1,4),CFrame.new(side*93,1,z+dz),gold)
    p("ArcadeColumn",Vector3.new(2,13,2),CFrame.new(side*93,7.5,z+dz),pale,Enum.Material.Marble)
    p("ArcadeCapital",Vector3.new(3.6,1,3.6),CFrame.new(side*93,14,z+dz),gold)
   end
   p("ArcadeLintel",Vector3.new(5,1.3,19),CFrame.new(side*93,15,z),dark)
   p("ArcadeCornice",Vector3.new(6,.5,20),CFrame.new(side*93,16,z),gold)
  end
  -- Small relief niches and flanking pennants give the keep a readable facade.
  for _,x in {side*11,side*65} do
   p("NicheFrame",Vector3.new(7,13,1.1),CFrame.new(x,10,-76),gold)
   p("NicheRecess",Vector3.new(5.8,11,.4),CFrame.new(x,10,-75.25),dark)
   p("NicheLight",Vector3.new(1.6,6,.3),CFrame.new(x,10,-74.9),accent,Enum.Material.Neon,false)
  end
  for z=25,61,12 do
   p("CeremonialInlay",Vector3.new(1.4,.08,5),CFrame.new(side*12,.43,z)*CFrame.Angles(0,side*.15,0),gold,Enum.Material.Metal,false)
  end
 end
 -- An arrival gate and its lamps close the composition behind the spawn.
 for _,x in {-15,15} do
  p("ArrivalGateBase",Vector3.new(6,2,6),CFrame.new(x,1,82),gold)
  p("ArrivalGatePier",Vector3.new(4,18,5),CFrame.new(x,11,82),pale)
  p("ArrivalGateCap",Vector3.new(7,1.5,7),CFrame.new(x,20.5,82),gold)
 end
 for i=0,12 do local a=i*math.pi/12
  p("ArrivalGateArch",Vector3.new(3.5,4,5),CFrame.new(math.cos(a)*15,20+math.sin(a)*10,82)*CFrame.Angles(0,0,a-math.pi/2),pale)
 end
 for _,id in Config.modeOrder do
  local def=Config.modes[id];local c=def.position;local scale=if id=="Bot" or id=="Duel" then 1 else .65
  local position=c+Vector3.new(22,4,8)*scale
  p("ModeLectern",Vector3.new(6,1,4)*scale,CFrame.new(position-Vector3.new(0,3.3,0)),gold)
  local panel=p("ModeDescription",Vector3.new(11,5,.4)*scale,CFrame.new(position)*CFrame.Angles(0,math.pi,0),dark,Enum.Material.SmoothPlastic,false)
  local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=40;gui.LightInfluence=0;gui.Parent=panel
  local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.Text=def.description;text.TextColor3=Color3.fromRGB(224,221,210);text.TextWrapped=true;text.TextScaled=true;text.Font=Enum.Font.GothamMedium;text.BackgroundTransparency=1;text.Parent=gui
 end
end
return table.freeze(Art)
