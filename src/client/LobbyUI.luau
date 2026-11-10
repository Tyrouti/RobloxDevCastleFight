--!strict
local TweenService=game:GetService("TweenService")
local Input=game:GetService("UserInputService")
local Config=require(game.ReplicatedStorage.CastleFightShared.Config.LobbyConfig)
local UI={}
export type View={Render: (string,string,string,number,string?) -> (),gui: ScreenGui}
function UI.Create(player: Player,onCancel: () -> (),onInteract: () -> ()): View
 local gui=Instance.new("ScreenGui");gui.Name="CastleFightLobbyUI";gui.ResetOnSpawn=false;gui.DisplayOrder=40;gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 local content=Instance.new("CanvasGroup");content.Name="Content";content.BackgroundTransparency=1;content.Size=UDim2.fromScale(1,1);content.Parent=gui
 local function panel(name: string,size: UDim2,position: UDim2): Frame
  local f=Instance.new("Frame");f.Name=name;f.Size=size;f.Position=position;f.BackgroundColor3=Color3.fromRGB(16,22,35);f.BackgroundTransparency=.08;f.BorderSizePixel=0;f.Parent=content
  local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,12);c.Parent=f
  local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(188,157,91);s.Transparency=.45;s.Thickness=1;s.Parent=f
  return f
 end
 local function label(parent: Instance,name: string,text: string,size: number,color: Color3): TextLabel
  local t=Instance.new("TextLabel");t.Name=name;t.Text=text;t.Font=Enum.Font.GothamMedium;t.TextSize=size;t.TextColor3=color;t.BackgroundTransparency=1;t.TextXAlignment=Enum.TextXAlignment.Left;t.TextWrapped=true;t.Parent=parent;return t
 end
 local gold=Color3.fromRGB(231,204,140);local white=Color3.fromRGB(235,240,249)
 local brand=panel("Brand",UDim2.fromOffset(370,93),UDim2.fromOffset(18,16))
 local title=label(brand,"Title","CASTLE FIGHT",27,gold);title.Font=Enum.Font.GothamBold;title.Position=UDim2.fromOffset(17,10);title.Size=UDim2.new(1,-34,0,35)
 local welcome=label(brand,"Welcome","Welcome, "..player.DisplayName,14,white);welcome.Position=UDim2.fromOffset(17,49);welcome.Size=UDim2.new(1,-34,0,29)
 local tag=panel("PlayerTag",UDim2.fromOffset(220,57),UDim2.new(1,-238,0,16))
 local name=label(tag,"Name",player.DisplayName,15,white);name.Position=UDim2.fromOffset(14,8);name.Size=UDim2.new(1,-28,0,22)
 local realm=label(tag,"Realm","HALL OF TWO KINGDOMS",10,gold);realm.Position=UDim2.fromOffset(14,32);realm.Size=UDim2.new(1,-28,0,16)
 local card=panel("ModeCard",UDim2.fromOffset(610,112),UDim2.new(.5,0,1,-18));card.AnchorPoint=Vector2.new(.5,1)
 local edge=Instance.new("Frame");edge.BorderSizePixel=0;edge.BackgroundColor3=Color3.fromRGB(91,198,239);edge.Size=UDim2.new(.5,-24,0,2);edge.Position=UDim2.fromOffset(16,0);edge.Parent=card
 local edge2=edge:Clone();edge2.BackgroundColor3=Color3.fromRGB(181,111,230);edge2.Position=UDim2.new(.5,8,0,0);edge2.Parent=card
 local modeTitle=label(card,"ModeTitle","CHOOSE A MODE",18,gold);modeTitle.Font=Enum.Font.GothamBold;modeTitle.Position=UDim2.fromOffset(17,12);modeTitle.Size=UDim2.new(1,-34,0,25)
 local status=label(card,"Status","",14,white);status.Position=UDim2.fromOffset(17,41);status.Size=UDim2.new(1,-34,0,36)
 local hint=label(card,"Hint","",12,Color3.fromRGB(156,173,193));hint.Position=UDim2.fromOffset(17,80);hint.Size=UDim2.new(1,-34,0,20)
 local cancel=Instance.new("TextButton");cancel.Name="CancelQueue";cancel.Text="CANCEL";cancel.Font=Enum.Font.GothamBold;cancel.TextSize=12;cancel.TextColor3=gold;cancel.BackgroundColor3=Color3.fromRGB(41,46,63);cancel.Size=UDim2.fromOffset(106,32);cancel.Position=UDim2.new(1,-122,0,42);cancel.Visible=false;cancel.Parent=card
 local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,7);c.Parent=cancel
 local interact=cancel:Clone();interact.Name="Interact";interact.Text=if Input.TouchEnabled then "SELECT" else "E · SELECT";interact.BackgroundColor3=Color3.fromRGB(47,73,94);interact.Parent=card
 local overlay=Instance.new("Frame");overlay.Name="Transition";overlay.Size=UDim2.fromScale(1,1);overlay.BackgroundColor3=Color3.fromRGB(10,14,26);overlay.BackgroundTransparency=1;overlay.BorderSizePixel=0;overlay.ZIndex=10;overlay.Parent=gui
 local transition=label(overlay,"Caption","CASTLE FIGHT",28,gold);transition.Font=Enum.Font.GothamBold;transition.TextXAlignment=Enum.TextXAlignment.Center;transition.AnchorPoint=Vector2.new(.5,.5);transition.Position=UDim2.fromScale(.5,.5);transition.Size=UDim2.new(1,-40,0,50);transition.TextTransparency=1;transition.ZIndex=11
 local lastLocation="";local connections: {RBXScriptConnection}={}
 local function resize(): ()
  local camera=workspace.CurrentCamera;if not camera then return end
  local narrow=camera.ViewportSize.X<650;local short=camera.ViewportSize.Y<500
  brand.Size=UDim2.fromOffset(if narrow then math.min(370,camera.ViewportSize.X-24) elseif short then 320 else 370,if short then 62 else 93)
  title.TextSize=if narrow then 23 else 27;welcome.Position=UDim2.fromOffset(17,if short then 39 else 49);welcome.Size=UDim2.new(1,-34,0,if short then 22 else 29)
  brand.Position=UDim2.fromOffset(12,10);tag.Visible=not narrow and not short
  card.Size=UDim2.fromOffset(math.min(610,camera.ViewportSize.X-24),if short then 88 elseif narrow then 128 else 112)
  card.Position=UDim2.new(.5,0,1,if Input.TouchEnabled then -132 elseif short then -10 else -18)
  hint.Position=UDim2.fromOffset(17,if short then 65 elseif narrow then 105 else 80)
  modeTitle.Position=UDim2.fromOffset(17,if short then 7 else 12);status.Position=UDim2.fromOffset(17,if short then 31 else 41)
  cancel.Position=UDim2.new(1,-122,0,if short then 32 else 42);interact.Position=cancel.Position
  status.Size=UDim2.new(1,if cancel.Visible or interact.Visible then -145 else -34,0,if short then 31 elseif narrow then 57 else 36)
  interact.Text=if Input.TouchEnabled then "SELECT" else "E · SELECT"
 end
 table.insert(connections,cancel.Activated:Connect(onCancel))
 table.insert(connections,interact.Activated:Connect(onInteract))
 if workspace.CurrentCamera then table.insert(connections,workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)) end
 gui.Parent=player:WaitForChild("PlayerGui");resize()
 gui.Destroying:Connect(function(): () for _,connection in connections do connection:Disconnect() end end)
 local view={} :: View;view.gui=gui
 function view.Render(location: string,phase: string,mode: string,queue: number,nearMode: string?): ()
  content.Visible=location=="Lobby"
  if location~=lastLocation then
   if location=="Transition" then overlay.Active=true;TweenService:Create(overlay,TweenInfo.new(.2),{BackgroundTransparency=.08}):Play();TweenService:Create(transition,TweenInfo.new(.2),{TextTransparency=0}):Play()
   else overlay.Active=false;TweenService:Create(overlay,TweenInfo.new(.25),{BackgroundTransparency=1}):Play();TweenService:Create(transition,TweenInfo.new(.2),{TextTransparency=1}):Play();if location=="Lobby" then content.GroupTransparency=1;TweenService:Create(content,TweenInfo.new(.3),{GroupTransparency=0}):Play() end end
   lastLocation=location
  end
  local definition=Config.modes[mode];local near=if nearMode then Config.modes[nearMode] else nil
  modeTitle.Text=if definition then definition.title else "CHOOSE A MODE"
  cancel.Visible=phase=="Queued";interact.Visible=near~=nil and not cancel.Visible
  interact.Text=if Input.TouchEnabled then "SELECT" else "E · SELECT"
  status.Size=UDim2.new(1,if cancel.Visible or interact.Visible then -145 else -34,0,if card.Size.Y.Offset<100 then 31 elseif card.Size.Y.Offset>112 then 57 else 36)
  if phase=="Queued" then status.Text="WAITING FOR A LOCAL PLAYER · "..queue.."/2"
  elseif phase=="Unavailable" and definition then status.Text=definition.status.." · "..definition.description
  elseif phase=="Busy" then status.Text="Arena busy. Wait for the current match to end."
  elseif phase=="StartFailed" or phase=="NotReady" then status.Text="Match did not start. Try again at the portal."
  elseif near then status.Text=near.title.." · "..near.status.."\n"..near.description
  else status.Text="Approach a portal. 1 VS 1 needs two players on this server." end
  hint.Text=if near then (if Input.TouchEnabled then "Tap to select a mode" else "Press E or select the button") else "Explore the castle courtyard"
 end
 return view
end
return table.freeze(UI)
