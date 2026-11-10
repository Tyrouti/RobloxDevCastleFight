--!strict
-- Client presentation only. Reads the existing replicated castle records; never sends HP.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
type Panel={frame: Frame,fill: Frame,trail: Frame,flash: Frame,stroke: UIStroke,title: TextLabel,value: TextLabel,status: TextLabel,
 lastHP: number?,matchId: number?,fillTween: Tween?,trailTween: Tween?,flashTween: Tween?,pulse: Tween?}
local Hud={}; local started=false
local WHITE=Color3.fromRGB(239,245,255)
local RED=Color3.fromRGB(255,114,125)
local function frame(parent: Instance,name: string,color: Color3): Frame
 local f=Instance.new("Frame");f.Name=name;f.BorderSizePixel=0;f.BackgroundColor3=color;f.Parent=parent;return f
end
local function corner(parent: Instance,radius: number): ()
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,radius);c.Parent=parent
end
local function label(parent: Instance,name: string,size: number): TextLabel
 local l=Instance.new("TextLabel");l.Name=name;l.BackgroundTransparency=1;l.Font=Enum.Font.GothamBold
 l.TextSize=size;l.TextColor3=WHITE;l.TextXAlignment=Enum.TextXAlignment.Left;l.Parent=parent;return l
end
local function cancel(tween: Tween?): () if tween then tween:Cancel() end end
local function numberText(value: number): string
 return if math.abs(value-math.round(value))<.001 then string.format("%d",math.round(value)) else string.format("%.1f",value)
end
function Hud.Start(): ()
 if started then return end;started=true
 local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui")
 local state=ReplicatedStorage:WaitForChild("CastleFightState")
 local castles=state:WaitForChild("Castles")
 assert(not playerGui:FindFirstChild("CastleFightCastleHud"),"E_DUPLICATE_CASTLE_HUD")
 local gui=Instance.new("ScreenGui");gui.Name="CastleFightCastleHud";gui.ResetOnSpawn=false;gui.DisplayOrder=15
 gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.ClipToDeviceSafeArea=true;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 local safe=frame(gui,"SafeCanvas",Color3.new());safe.Size=UDim2.fromScale(1,1);safe.BackgroundTransparency=1
 local root=frame(safe,"Root",Color3.new());root.AnchorPoint=Vector2.new(.5,0);root.Position=UDim2.new(.5,0,0,8)
 root.Size=UDim2.fromOffset(760,88);root.BackgroundTransparency=1
 local vs=label(root,"Divider",12);vs.Text="VS";vs.TextColor3=Color3.fromRGB(213,187,130)
 vs.TextXAlignment=Enum.TextXAlignment.Center;vs.AnchorPoint=Vector2.new(.5,.5);vs.Position=UDim2.fromScale(.5,.5);vs.Size=UDim2.fromOffset(28,28)
 local panels: {[string]:Panel}={};local connections: {RBXScriptConnection}={}
 local colors={Human=Color3.fromRGB(78,202,255),Undead=Color3.fromRGB(193,111,247)}
 for index,faction in {"Human","Undead"} do
  local accent=colors[faction];local panel=frame(root,faction,Color3.new(1,1,1));corner(panel,10)
  panel.Size=UDim2.new(.5,-20,1,0);panel.Position=UDim2.new(if index==1 then 0 else .5,if index==1 then 0 else 20,0,0)
  local gradient=Instance.new("UIGradient");gradient.Color=ColorSequence.new(Color3.fromRGB(38,47,68),Color3.fromRGB(14,18,32));gradient.Rotation=90;gradient.Parent=panel
  local stroke=Instance.new("UIStroke");stroke.Color=accent;stroke.Transparency=.42;stroke.Thickness=1.2;stroke.Parent=panel
  local edge=frame(panel,"CrownLine",Color3.fromRGB(203,174,107));edge.Position=UDim2.fromOffset(14,0);edge.Size=UDim2.new(1,-28,0,2);corner(edge,1)
  local icon=frame(panel,"CrystalEmblem",accent);icon.AnchorPoint=Vector2.new(.5,.5);icon.Position=UDim2.fromOffset(25,29)
  icon.Size=UDim2.fromOffset(18,24);icon.Rotation=45;corner(icon,3)
  local facet=frame(icon,"Facet",WHITE);facet.BackgroundTransparency=.7;facet.Size=UDim2.new(.35,0,1,-4);facet.Position=UDim2.fromOffset(3,2);corner(facet,2)
  local title=label(panel,"Title",13);title.Text=string.upper(faction);title.TextColor3=accent
  title.Position=UDim2.fromOffset(48,9);title.Size=UDim2.new(1,-58,0,18)
  local value=label(panel,"Health",19);value.Text="— / —";value.Position=UDim2.fromOffset(48,28);value.Size=UDim2.new(1,-58,0,23)
  local track=frame(panel,"Track",Color3.fromRGB(8,12,23));track.Position=UDim2.new(0,14,1,-30);track.Size=UDim2.new(1,-28,0,10);corner(track,4)
  local trackStroke=Instance.new("UIStroke");trackStroke.Color=accent;trackStroke.Transparency=.75;trackStroke.Parent=track
  local trail=frame(track,"DamageTrail",Color3.fromRGB(249,206,137));trail.Size=UDim2.fromScale(0,1);corner(trail,4)
  local fill=frame(track,"Fill",accent);fill.Size=UDim2.fromScale(0,1);corner(fill,4)
  local sheen=Instance.new("UIGradient");sheen.Color=ColorSequence.new(accent:Lerp(WHITE,.3),accent);sheen.Rotation=90;sheen.Parent=fill
  if index==2 then for _,f in {fill,trail} do f.AnchorPoint=Vector2.new(1,0);f.Position=UDim2.fromScale(1,0) end end
  local status=label(panel,"Status",9);status.Text="CRYSTAL";status.TextColor3=Color3.fromRGB(156,168,192)
  status.Position=UDim2.new(0,14,1,-17);status.Size=UDim2.new(1,-28,0,13)
  local flash=frame(panel,"HitFlash",WHITE);flash.Size=UDim2.fromScale(1,1);flash.BackgroundTransparency=1;flash.ZIndex=8;corner(flash,10)
  local p: Panel={frame=panel,fill=fill,trail=trail,flash=flash,stroke=stroke,title=title,value=value,status=status}
  panels[faction]=p
  local health=castles:WaitForChild(faction)
  local function render(): ()
   local hp=health:GetAttribute("HP");local maximum=health:GetAttribute("MaxHP");local matchId=state:GetAttribute("MatchId")
   if typeof(hp)~="number" or typeof(maximum)~="number" or maximum<=0 or hp~=hp or maximum~=maximum then
    value.Text="— / —";return
   end
   hp=math.clamp(hp,0,maximum);local ratio=hp/maximum
   local currentId=if typeof(matchId)=="number" then matchId else 0
   local sameMatch=p.matchId==currentId;local hit=sameMatch and p.lastHP~=nil and hp<(p.lastHP :: number)
   cancel(p.fillTween);cancel(p.trailTween);cancel(p.flashTween);cancel(p.pulse);p.pulse=nil
   if p.lastHP==nil or not sameMatch then fill.Size=UDim2.fromScale(ratio,1);trail.Size=fill.Size
   else
    p.fillTween=TweenService:Create(fill,TweenInfo.new(.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.fromScale(ratio,1)});(p.fillTween :: Tween):Play()
    p.trailTween=TweenService:Create(trail,TweenInfo.new(.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false,.12),{Size=UDim2.fromScale(ratio,1)});(p.trailTween :: Tween):Play()
   end
   flash.BackgroundTransparency=if hit then .76 else 1
   if hit then p.flashTween=TweenService:Create(flash,TweenInfo.new(.3),{BackgroundTransparency=1});(p.flashTween :: Tween):Play() end
   value.Text=numberText(hp).." / "..numberText(maximum)
   local critical=hp>0 and ratio<=.25
   status.Text=if hp<=0 then "DESTROYED" elseif critical then "IN DANGER" else "CRYSTAL"
   status.TextColor3=if hp<=0 or critical then RED else Color3.fromRGB(156,168,192)
   stroke.Color=if hp<=0 or critical then RED else accent;stroke.Transparency=.42
   if critical then p.pulse=TweenService:Create(stroke,TweenInfo.new(.7,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=.05});(p.pulse :: Tween):Play() end
   panel:SetAttribute("DisplayedHP",hp);panel:SetAttribute("DisplayedMaxHP",maximum);panel:SetAttribute("Critical",critical);panel:SetAttribute("Destroyed",hp<=0)
   p.lastHP=hp;p.matchId=currentId
  end
  -- Subscribe before the snapshot: initial/late replication and every subsequent change use one source.
  table.insert(connections,health:GetAttributeChangedSignal("HP"):Connect(render))
  table.insert(connections,health:GetAttributeChangedSignal("MaxHP"):Connect(render))
  table.insert(connections,state:GetAttributeChangedSignal("MatchId"):Connect(render));render()
 end
 local function layout(): ()
  local width=safe.AbsoluteSize.X;local small=width<600 or safe.AbsoluteSize.Y<480
  root.Size=UDim2.fromOffset(math.max(180,math.min(760,width-24)),if small then 74 else 88)
  for _,p in panels do p.title.TextSize=if small then 11 else 13;p.value.TextSize=if small then 14 else 19
   p.title.Position=UDim2.fromOffset(43,7);p.value.Position=UDim2.fromOffset(43,if small then 24 else 28)
   p.status.TextSize=if small then 8 else 9
  end
 end
 table.insert(connections,safe:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
 gui.Destroying:Connect(function(): ()
  for _,c in connections do c:Disconnect() end
  for _,p in panels do cancel(p.fillTween);cancel(p.trailTween);cancel(p.flashTween);cancel(p.pulse) end
  started=false
 end)
 gui.Parent=playerGui;layout()
end
return table.freeze(Hud)
