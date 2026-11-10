--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Config=require(ReplicatedStorage.CastleFightShared.Config.GameConfig)
local Hud={}
local started=false

function Hud.Start(): ()
	if started then return end; started=true
	local player=Players.LocalPlayer
	local state=ReplicatedStorage:WaitForChild("CastleFightState")
	local playerGui=player:WaitForChild("PlayerGui")
	assert(not playerGui:FindFirstChild("CastleFightEconomyHud"),"E_DUPLICATE_HUD")
	local gui=Instance.new("ScreenGui"); gui.Name="CastleFightEconomyHud"; gui.ResetOnSpawn=false; gui.DisplayOrder=10
	gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
	local panel=Instance.new("Frame"); panel.Name="Panel"; panel.Position=UDim2.fromOffset(12,108); panel.Size=UDim2.new(1,-24,0,162)
	panel.BackgroundColor3=Color3.fromRGB(25,30,42); panel.BackgroundTransparency=.08; panel.Parent=gui
	local constraint=Instance.new("UISizeConstraint"); constraint.MaxSize=Vector2.new(240,162); constraint.Parent=panel
	local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,8); corner.Parent=panel
	local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,2); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=panel
	local padding=Instance.new("UIPadding"); padding.PaddingTop=UDim.new(0,9); padding.PaddingLeft=UDim.new(0,12); padding.PaddingRight=UDim.new(0,12); padding.Parent=panel
	local labels: {[string]:TextLabel}={}
	for index,name in {"Faction","Gold","Income","Status","Buildings"} do
		local label=Instance.new("TextLabel"); label.Name=name; label.LayoutOrder=index; label.BackgroundTransparency=1
		label.Size=UDim2.new(1,0,0,26); label.Font=Enum.Font.GothamMedium; label.TextSize=17
		label.TextXAlignment=Enum.TextXAlignment.Left; label.TextColor3=Color3.fromRGB(235,239,248)
		label.Parent=panel; labels[name]=label
	end
	labels.Gold.TextColor3=Color3.fromRGB(255,216,107)
	local function render(): ()
		local faction=player:GetAttribute("CastleFightFaction") or "Unassigned"
		labels.Faction.Text="Faction: "..(if faction=="Unassigned" then "unassigned" else tostring(faction))
		labels.Gold.Text="Gold: "..tostring(player:GetAttribute("CastleFightGold") or 0)
		labels.Income.Text="Income: +"..tostring(player:GetAttribute("CastleFightIncome") or 0).."/s"
		labels.Status.Text="Match: "..tostring(state:GetAttribute("MatchStatus") or "Waiting")
		labels.Buildings.Text="Buildings: "..tostring(player:GetAttribute("CastleFightBuildingCount") or 0).."/"..tostring(Config.buildingSlotsPerPlayer)
	end
	local connections: {RBXScriptConnection}={}
	for _,attribute in {"CastleFightFaction","CastleFightGold","CastleFightIncome","CastleFightBuildingCount"} do table.insert(connections,player:GetAttributeChangedSignal(attribute):Connect(render)) end
	table.insert(connections,state:GetAttributeChangedSignal("MatchStatus"):Connect(render))
	gui.Destroying:Connect(function(): () for _,connection in connections do connection:Disconnect() end end)
	local function layoutHud(): ()
  local camera=workspace.CurrentCamera
  local small=camera and (camera.ViewportSize.X<600 or camera.ViewportSize.Y<480)
  panel.Position=UDim2.fromOffset(12,if small then 94 else 108)
  panel.Size=UDim2.new(1,-24,0,if small then 108 else 162)
  constraint.MaxSize=Vector2.new(if small then 195 else 240,if small then 108 else 162)
  for _,l in labels do l.TextSize=if small then 12 else 17;l.Size=UDim2.new(1,0,0,if small then 16 else 26) end
 end
 local cam=workspace.CurrentCamera
 if cam then table.insert(connections,cam:GetPropertyChangedSignal("ViewportSize"):Connect(layoutHud)) end
 render(); gui.Parent=playerGui;layoutHud()
end
return table.freeze(Hud)
