--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Input=game:GetService("UserInputService")
local Http=game:GetService("HttpService")
local Shared=ReplicatedStorage.CastleFightShared
local Types=require(Shared.Types)
local Definitions=require(Shared.Config.BuildingConfig)
local Presentation=require(Shared.Config.BuildingPresentation)
local Config=require(Shared.Config.GameConfig)
local Levels=require(Shared.Config.BuildingLevels)
local Menu={}
local started=false
local messages: {[string]:string}={
	E_MATCH_INACTIVE="You can only build during a match.",E_NOT_YOUR_PAD="This build pad belongs to your opponent.",
	E_PAD_OCCUPIED="This build pad is occupied.",E_INSUFFICIENT_GOLD="Not enough gold.",
	E_PRODUCER_LIMIT="You already have three buildings of this type.",E_PASSIVE_LIMIT="This lane already has a passive building.",
	E_RATE_LIMIT="Too many requests. Please wait.",E_NOT_ASSIGNED="You have not been assigned a faction yet.",
	E_STALE_MATCH="The match has changed. Select the build pad again.",E_DUPLICATE_REQUEST="This request has already been completed.",
	E_MODEL_PREPARATION="Could not prepare the model. No gold was spent.",E_TIMEOUT="The response is delayed. Check the build pad.",
	E_MAX_LEVEL="This building is already level 2.",E_STALE_BUILDING="The building has changed. Select it again.",
	E_BUILDING_MISSING="This building has been sold or removed.",E_BUILDING_BUSY="Another action is being processed for this building.",
	E_UPGRADE_VISUAL="The upgrade failed. No gold was spent.",
}
local function label(parent: Instance,name: string,text: string,size: number): TextLabel
	local obj=Instance.new("TextLabel"); obj.Name=name; obj.Text=text; obj.TextSize=size; obj.Font=Enum.Font.GothamMedium
	obj.TextColor3=Color3.fromRGB(236,239,248); obj.BackgroundTransparency=1; obj.TextXAlignment=Enum.TextXAlignment.Left; obj.Parent=parent
	return obj
end

function Menu.Start(): ()
	if started then return end; started=true
	local player=Players.LocalPlayer
	local state=ReplicatedStorage:WaitForChild("CastleFightState")
	local remotes=ReplicatedStorage:WaitForChild("CastleFightBuildRemotes")
	local request=remotes:WaitForChild("BuildRequest") :: RemoteEvent
	local reply=remotes:WaitForChild("BuildResult") :: RemoteEvent
	local map=workspace:WaitForChild("Map"); local pads=map:WaitForChild("BuildPads")
	local active=workspace:WaitForChild("ActiveBuildings")
	local playerGui=player:WaitForChild("PlayerGui")
	assert(not playerGui:FindFirstChild("CastleFightBuildMenu"),"E_DUPLICATE_BUILD_MENU")
	local gui=Instance.new("ScreenGui"); gui.Name="CastleFightBuildMenu"; gui.ResetOnSpawn=false; gui.DisplayOrder=20; gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
	local panel=Instance.new("Frame"); panel.Name="Panel"; panel.AnchorPoint=Vector2.one
	panel.Position=UDim2.new(1,-12,1,-12); panel.Size=UDim2.new(1,-24,.72,0); panel.BackgroundColor3=Color3.fromRGB(25,30,42); panel.Visible=false; panel.Parent=gui
	local limit=Instance.new("UISizeConstraint"); limit.MaxSize=Vector2.new(370,440); limit.Parent=panel
	local corner=Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,8); corner.Parent=panel
	local title=label(panel,"Title","Building",18); title.Position=UDim2.fromOffset(12,8); title.Size=UDim2.new(1,-52,0,28)
	local close=Instance.new("TextButton"); close.Name="Close"; close.Text="×"; close.TextSize=26; close.Size=UDim2.fromOffset(36,36); close.Position=UDim2.new(1,-40,0,3)
	close.TextColor3=Color3.new(1,1,1); close.BackgroundTransparency=1; close.Parent=panel
	local cards=Instance.new("ScrollingFrame"); cards.Name="Cards"; cards.Position=UDim2.fromOffset(10,46); cards.Size=UDim2.new(1,-20,1,-80)
	cards.BackgroundTransparency=1; cards.BorderSizePixel=0; cards.ScrollBarThickness=5; cards.AutomaticCanvasSize=Enum.AutomaticSize.Y; cards.CanvasSize=UDim2.new(); cards.Parent=panel
	local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,8); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Parent=cards
	local management=Instance.new("ScrollingFrame"); management.Name="Management"; management.Position=cards.Position; management.Size=cards.Size
	management.BackgroundTransparency=1; management.BorderSizePixel=0; management.ScrollBarThickness=5
	management.AutomaticCanvasSize=Enum.AutomaticSize.Y; management.CanvasSize=UDim2.new(); management.Visible=false; management.Parent=panel
	local managementLayout=Instance.new("UIListLayout"); managementLayout.Padding=UDim.new(0,12); managementLayout.SortOrder=Enum.SortOrder.LayoutOrder; managementLayout.Parent=management
	local detailsText=label(management,"Details","",14); detailsText.Size=UDim2.new(1,-8,0,0); detailsText.AutomaticSize=Enum.AutomaticSize.Y
	detailsText.TextWrapped=true; detailsText.TextYAlignment=Enum.TextYAlignment.Top; detailsText.LayoutOrder=1
	local upgrade=Instance.new("TextButton"); upgrade.Name="Upgrade"; upgrade.Size=UDim2.new(1,-8,0,46); upgrade.LayoutOrder=2
	upgrade.TextColor3=Color3.new(1,1,1); upgrade.Font=Enum.Font.GothamMedium; upgrade.TextSize=16; upgrade.Parent=management
	local sell=Instance.new("TextButton"); sell.Name="Sell"; sell.Size=upgrade.Size; sell.LayoutOrder=3
	sell.TextColor3=Color3.new(1,1,1); sell.Font=Enum.Font.GothamMedium; sell.TextSize=16; sell.BackgroundColor3=Color3.fromRGB(124,62,64); sell.Parent=management
	local hint=label(panel,"Hint","Select a building to purchase",12); hint.Position=UDim2.new(0,12,1,-28); hint.Size=UDim2.new(1,-24,0,22)
	local notice=label(gui,"Notice","",14); notice.AnchorPoint=Vector2.new(.5,0); notice.Position=UDim2.new(.5,0,0,210); notice.Size=UDim2.new(1,-24,0,44)
	notice.TextXAlignment=Enum.TextXAlignment.Center; notice.TextWrapped=true; notice.BackgroundColor3=Color3.fromRGB(39,43,56); notice.Visible=false
	local noticeLimit=Instance.new("UISizeConstraint"); noticeLimit.MaxSize=Vector2.new(480,44); noticeLimit.Parent=notice
	local selected: BasePart?=nil; local selectedModel: Model?=nil; local pending: string?=nil; local noticeRevision=0
	local connections: {RBXScriptConnection}={}; local buttons: {[string]:TextButton}={}
	local modelConnections: {[Instance]:{RBXScriptConnection}}={}
	local refresh: () -> ()
	local function notify(code: string): ()
		noticeRevision+=1; local revision=noticeRevision; notice.Text=messages[code] or ("Building: "..code); notice.Visible=true
		task.delay(3,function(): () if gui.Parent and noticeRevision==revision then notice.Visible=false end end)
	end
	local function counts(faction: string,buildingId: string,laneId: string): (number,number)
		local producers=0; local passives=0
		for _,model in active:GetChildren() do
			if model:GetAttribute("OwnerFaction")==faction then
				local id=model:GetAttribute("BuildingId")
				if id==buildingId then producers+=1 end
				local def=if typeof(id)=="string" then Definitions[id :: Types.BuildingId] else nil
				if def and def.kind=="Passive" and model:GetAttribute("LaneId")==laneId then passives+=1 end
			end
		end
		return producers,passives
	end
	refresh=function(): ()
		local pad=selected; if not pad then panel.Visible=false; return end
		if state:GetAttribute("MatchStatus")~="InProgress" or pad.Parent~=pads then selected=nil; panel.Visible=false; return end
		local faction=tostring(player:GetAttribute("CastleFightFaction")); local gold=player:GetAttribute("CastleFightGold")
		if typeof(gold)~="number" then gold=0 end
		local lane=tostring(pad:GetAttribute("LaneId")); local occupied=pad:GetAttribute("IsOccupied")~=false
		local model=selectedModel
		cards.Visible=model==nil; management.Visible=model~=nil
		if model then
			if model.Parent~=active then selectedModel=nil; selected=nil; panel.Visible=false; return end
			local id=model:GetAttribute("BuildingId") :: Types.BuildingId
			local level=model:GetAttribute("Level") :: number; local spent=model:GetAttribute("TotalSpent") :: number
			if not Presentation.entries[id :: Types.BuildingId] or typeof(level)~="number" or typeof(spent)~="number" then return end
			local stats=Levels.Snapshot(id :: Types.BuildingId,level); local refund=Levels.Refund(spent); local credited=math.min(refund,Config.maxGold-gold)
			local nextText=if level<Config.maxBuildingLevel then "\n\nLevel 2:\n"..Levels.Describe(Levels.Snapshot(id :: Types.BuildingId,level+1)) else "\n\nMaximum level"
			detailsText.Text=Levels.Describe(stats)..nextText..(if stats.kind=="Producer" then "\n\nBonuses apply only to new units." else "\n\nPassive effect not enabled yet.").."\nSpent: "..tostring(spent).."\nRefund: "..string.format("%g",refund)
				..(if credited<refund then " (after gold cap: "..string.format("%g",credited)..")" else "")
			title.Text=Presentation.entries[id :: Types.BuildingId].title.." · L"..level
			local cost=Levels.UpgradeCost(id :: Types.BuildingId); local allowed=not pending and level<Config.maxBuildingLevel and gold>=cost
			upgrade.Text=if level>=Config.maxBuildingLevel then "Level 2 — maximum" else "Upgrade · "..cost.." gold"
			upgrade:SetAttribute("Available",allowed); upgrade.Active=allowed; upgrade.Selectable=allowed; upgrade.AutoButtonColor=allowed
			upgrade.BackgroundColor3=if allowed then Color3.fromRGB(45,103,151) else Color3.fromRGB(54,57,65)
			sell.Text="Sell · +"..string.format("%g",refund).." gold"; sell:SetAttribute("Available",not pending); sell.Active=not pending; sell.Selectable=not pending
			hint.Text=if pending then "Waiting for server…" else (if level<Config.maxBuildingLevel and gold<cost then "Not enough gold to upgrade" else "Upgrade or sell this building")
			return
		end
		title.Text="Build · "..lane; hint.Text=if pending then "Waiting for server…" else "Select a building to purchase"
		for id,button in buttons do
			local def=Definitions[id :: Types.BuildingId]; button.Visible=def.faction==faction
			local producers,passives=counts(faction,id,lane)
			local allowed=not pending and not occupied and gold>=def.cost and pad:GetAttribute("OwnerFaction")==faction
				and (player:GetAttribute("CastleFightBuildingCount") :: number or 0)<Config.buildingSlotsPerPlayer
				and (def.kind~="Producer" or producers<Config.maxSameProducerPerPlayer)
				and (def.kind~="Passive" or passives<Config.maxPassivePerLanePerPlayer)
			button.Active=allowed; button.Selectable=allowed; button.AutoButtonColor=allowed; button:SetAttribute("Available",allowed)
			button.BackgroundColor3=if allowed then Color3.fromRGB(49,68,94) else Color3.fromRGB(47,49,57)
			local cost=button:FindFirstChild("Cost") :: TextLabel
			cost.Text=if gold<def.cost then tostring(def.cost).." gold · insufficient" else tostring(def.cost).." gold"
			cost.TextColor3=if allowed then Color3.fromRGB(255,215,110) else Color3.fromRGB(160,162,170)
		end
	end
	for _,faction in {"Human","Undead"} do
	local order: {string}=if faction=="Human" then Presentation.order.Human else Presentation.order.Undead
	for index,id in order do
		local buildingId=id :: Types.BuildingId; local info=Presentation.entries[id :: Types.BuildingId]; local def=Definitions[id :: Types.BuildingId]
		local button=Instance.new("TextButton"); button.Name=id; button.LayoutOrder=index; button.Size=UDim2.new(1,-7,0,82); button.Text=""; button.Parent=cards; buttons[id]=button
		local icon=label(button,"Icon",info.symbol,25); icon.Position=UDim2.fromOffset(8,17); icon.Size=UDim2.fromOffset(34,42); icon.TextXAlignment=Enum.TextXAlignment.Center
		icon.BackgroundTransparency=0; icon.BackgroundColor3=if faction=="Human" then Color3.fromRGB(36,105,189) else Color3.fromRGB(110,55,147)
		local name=label(button,"NameLabel",info.title,15); name.Position=UDim2.fromOffset(50,6); name.Size=UDim2.new(1,-56,0,20)
		local cost=label(button,"Cost",tostring(def.cost).." gold",13); cost.Position=UDim2.fromOffset(50,27); cost.Size=UDim2.new(1,-56,0,18)
		local description=if def.kind=="Producer" then tostring(def.unitId).." · every "..tostring(def.spawnIntervalSeconds).." s" else (if faction=="Human" then "Lane shields (planned)" else "Lane curse (planned)")
		local text=label(button,"Description",description,12); text.TextWrapped=true; text.Position=UDim2.fromOffset(50,47); text.Size=UDim2.new(1,-56,0,30)
		table.insert(connections,button.Activated:Connect(function(): ()
			if button:GetAttribute("Available")~=true or pending then return end
			local pad=selected; if not pad then return end
			local requestId=Http:GenerateGUID(false); pending=requestId; refresh()
			request:FireServer({padId=pad:GetAttribute("PadId"),buildingId=buildingId,requestId=requestId,matchId=state:GetAttribute("MatchId")})
			task.delay(8,function(): () if gui.Parent and pending==requestId then pending=nil; notify("E_TIMEOUT"); refresh() end end)
		end))
	end end
	local function manage(action: string,button: TextButton): ()
		local model=selectedModel; local pad=selected
		if not model or not pad or pending or button:GetAttribute("Available")~=true then return end
		local requestId=Http:GenerateGUID(false); pending=requestId; refresh()
		request:FireServer({action=action,padId=pad:GetAttribute("PadId"),instanceId=model:GetAttribute("InstanceId"),revision=model:GetAttribute("Revision"),requestId=requestId,matchId=state:GetAttribute("MatchId")})
		task.delay(8,function(): () if gui.Parent and pending==requestId then pending=nil; notify("E_TIMEOUT"); refresh() end end)
	end
	table.insert(connections,upgrade.Activated:Connect(function(): () manage("Upgrade",upgrade) end))
	table.insert(connections,sell.Activated:Connect(function(): () manage("Sell",sell) end))
	local function selectAt(position: Vector2): ()
		local camera=workspace.CurrentCamera; if not camera then return end
		local ray=camera:ScreenPointToRay(position.X,position.Y)
		local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances=if player.Character then {player.Character} else {}
		local hit=workspace:Raycast(ray.Origin,ray.Direction*1000,params)
		if not hit then return end
		local model=hit.Instance:FindFirstAncestorWhichIsA("Model")
		if model and model.Parent~=active then model=nil end
		local pad=if hit.Instance.Parent==pads then hit.Instance else (if model then pads:FindFirstChild(tostring(model:GetAttribute("PadId"))) else nil)
		if not pad or not pad:IsA("BasePart") then return end
		if state:GetAttribute("MatchStatus")~="InProgress" then notify("E_MATCH_INACTIVE"); return end
		if pad:GetAttribute("OwnerFaction")~=player:GetAttribute("CastleFightFaction") then notify("E_NOT_YOUR_PAD"); return end
		if not model and pad:GetAttribute("IsOccupied")==true then
			local candidate=active:FindFirstChild(tostring(pad:GetAttribute("PadId"))); if candidate and candidate:IsA("Model") then model=candidate end
		end
		if pending then return end
		selected=pad; selectedModel=model; panel.Visible=true; gui:SetAttribute("SelectedPadId",pad:GetAttribute("PadId")); refresh()
	end
	table.insert(connections,Input.InputBegan:Connect(function(input: InputObject,processed: boolean): ()
		if not processed and input.UserInputType==Enum.UserInputType.MouseButton1 then selectAt(Vector2.new(input.Position.X,input.Position.Y)) end
	end))
	table.insert(connections,Input.TouchTapInWorld:Connect(function(position: Vector2,processed: boolean): () if not processed then selectAt(position) end end))
	table.insert(connections,close.Activated:Connect(function(): () selected=nil; selectedModel=nil; panel.Visible=false end))
	table.insert(connections,reply.OnClientEvent:Connect(function(requestId: string,success: boolean,code: string,padId: string,action: string?): ()
		gui:SetAttribute("LastResultCode",code); gui:SetAttribute("LastResultSuccess",success)
		if pending==requestId then pending=nil end
		if success then
			if action~="Upgrade" and selected and selected:GetAttribute("PadId")==padId then selected=nil; selectedModel=nil; panel.Visible=false end
		else notify(code) end
		refresh()
	end))
	for _,name in {"CastleFightGold","CastleFightFaction","CastleFightBuildingCount"} do table.insert(connections,player:GetAttributeChangedSignal(name):Connect(refresh)) end
	table.insert(connections,state:GetAttributeChangedSignal("MatchStatus"):Connect(function(): () pending=nil; refresh() end))
	table.insert(connections,active.ChildAdded:Connect(refresh)); table.insert(connections,active.ChildRemoved:Connect(refresh))
	local function watchModel(model: Instance): ()
		local watchers: {RBXScriptConnection}={}; modelConnections[model]=watchers
		for _,attribute in {"Level","Revision","TotalSpent"} do table.insert(watchers,model:GetAttributeChangedSignal(attribute):Connect(refresh)) end
	end
	for _,model in active:GetChildren() do watchModel(model) end
	table.insert(connections,active.ChildAdded:Connect(watchModel))
	table.insert(connections,active.ChildRemoved:Connect(function(model: Instance): ()
		local watchers: {RBXScriptConnection}=modelConnections[model] or {}
		for _,connection in watchers do connection:Disconnect() end; modelConnections[model]=nil
	end))
	for _,pad in pads:GetChildren() do table.insert(connections,pad:GetAttributeChangedSignal("IsOccupied"):Connect(refresh)) end
	gui.Destroying:Connect(function(): ()
		for _,connection in connections do connection:Disconnect() end
		for _,watchers in modelConnections do for _,connection in watchers do connection:Disconnect() end end
	end)
	gui.Parent=playerGui
end
return table.freeze(Menu)
