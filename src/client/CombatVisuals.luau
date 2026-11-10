--!strict
-- All projectiles/flashes are cosmetic; this module never requests or calculates gameplay damage.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Config=require(ReplicatedStorage.CastleFightShared.Config.CombatConfig)
type Shot={part: Part,from: Vector3,to: Vector3,born: number,duration: number}
type Flash={highlight: Highlight,untilTime: number}
type Bar={gui: BillboardGui,connections: {RBXScriptConnection}}
local Visuals={}; local started=false
function Visuals.Start(): ()
	if started then return end; started=true
	local state=ReplicatedStorage:WaitForChild("CastleFightState")
	local castles=state:WaitForChild("Castles")
	local remote=ReplicatedStorage:WaitForChild("CastleFightCombatRemotes"):WaitForChild("Effect") :: RemoteEvent
	local units=workspace:WaitForChild("ActiveUnits")
	local root=Instance.new("Folder"); root.Name="CastleFightCombatUI"; root.Parent=Players.LocalPlayer:WaitForChild("PlayerGui")
	local fx=Instance.new("Folder"); fx.Name="CastleFightLocalCombatFX"; fx.Parent=workspace
	local bars: {[Instance]:Bar}={}; local shots: {Shot}={}; local flashes: {[Model]:Flash}={}; local deadAt: {[Model]:number}={}
	local connections: {RBXScriptConnection}={}
	local function bar(model: Model,health: Instance,castle: boolean): ()
		local gui=Instance.new("BillboardGui"); gui.Name=if castle then model.Name.."Health" else "UnitHealth"
		gui.Size=UDim2.fromOffset(if castle then 165 else 55,if castle then 32 else 8); gui.AlwaysOnTop=true; gui.MaxDistance=350; gui.Enabled=false; gui.Parent=root
		local background=Instance.new("Frame"); background.Size=UDim2.fromScale(1,1); background.BackgroundColor3=Color3.fromRGB(37,39,47); background.BorderSizePixel=0; background.Parent=gui
		local fill=Instance.new("Frame"); fill.Name="Fill"; fill.BorderSizePixel=0; fill.BackgroundColor3=if (model:GetAttribute("Faction") or model:GetAttribute("OwnerFaction"))=="Human" then Color3.fromRGB(78,163,239) else Color3.fromRGB(166,93,218); fill.Parent=background
		local text: TextLabel?=nil
		if castle then
			local caption=Instance.new("TextLabel"); caption.Size=UDim2.fromScale(1,1); caption.BackgroundTransparency=1; caption.TextColor3=Color3.new(1,1,1); caption.TextSize=13; caption.Font=Enum.Font.GothamMedium; caption.Parent=background; text=caption
		end
		local function update(): ()
			-- Map models can replicate before their parts. Attach/reposition as descendants arrive.
			local head=model:FindFirstChild("Head",true) or model:FindFirstChild("Keep",true) or model:FindFirstChildWhichIsA("BasePart",true)
			if not head or not head:IsA("BasePart") then gui.Enabled=false; return end
			gui.Adornee=head; local cf,size=model:GetBoundingBox(); gui.StudsOffsetWorldSpace=Vector3.new(0,cf.Y+size.Y/2-head.Position.Y+1,0)
			local hp=health:GetAttribute("HP"); local maxHP=health:GetAttribute("MaxHP")
			if typeof(hp)~="number" or typeof(maxHP)~="number" or maxHP<=0 then return end
			fill.BackgroundColor3=if (model:GetAttribute("Faction") or model:GetAttribute("OwnerFaction"))=="Human" then Color3.fromRGB(78,163,239) else Color3.fromRGB(166,93,218)
			fill.Size=UDim2.fromScale(math.clamp(hp/maxHP,0,1),1); gui.Enabled=(not castle and hp>0) or (castle and state:GetAttribute("DebugCastleBillboards")==true)
			if text then text.Text=model.Name.."  "..string.format("%g/%g",hp,maxHP) end
		end
		bars[model]={gui=gui,connections={state:GetAttributeChangedSignal("DebugCastleBillboards"):Connect(update),health:GetAttributeChangedSignal("HP"):Connect(update),health:GetAttributeChangedSignal("MaxHP"):Connect(update),health:GetAttributeChangedSignal("Faction"):Connect(update),model.DescendantAdded:Connect(update)}}; update()
	end
	local function addUnit(obj: Instance): ()
		if not obj:IsA("Model") then return end
		bar(obj,obj,false)
		local record=bars[obj]; if not record then return end
		local function stateChanged(): () if obj:GetAttribute("State")=="Dead" then deadAt[obj]=os.clock() end end
		table.insert(record.connections,obj:GetAttributeChangedSignal("State"):Connect(stateChanged)); stateChanged()
	end
	table.insert(connections,units.ChildAdded:Connect(addUnit))
	table.insert(connections,units.ChildRemoved:Connect(function(obj: Instance): ()
		local b=bars[obj]; if b then for _,c in b.connections do c:Disconnect() end; b.gui:Destroy(); bars[obj]=nil end
		if obj:IsA("Model") then deadAt[obj]=nil; local flash=flashes[obj]; if flash then flash.highlight:Destroy(); flashes[obj]=nil end end
	end))
	for _,obj in units:GetChildren() do addUnit(obj) end
	local map=workspace:WaitForChild("Map"); local castleModels=map:WaitForChild("Castles")
	for _,faction in {"Human","Undead"} do local model=castleModels:WaitForChild(faction.."Castle"); if model:IsA("Model") then bar(model,castles:WaitForChild(faction),true) end end
	local function clearEffects(): ()
		for _,shot in shots do shot.part:Destroy() end; table.clear(shots)
		for _,flash in flashes do flash.highlight:Destroy() end; table.clear(flashes); table.clear(deadAt)
	end
	table.insert(connections,remote.OnClientEvent:Connect(function(message: any): ()
		if state:GetAttribute("MatchStatus")~="InProgress" or typeof(message)~="table" or typeof(message.source)~="Vector3" or typeof(message.target)~="Vector3" then return end
		local now=os.clock(); local model=message.targetModel
		if typeof(model)=="Instance" and model:IsA("Model") and model.Parent then
			local flash=flashes[model]
			if not flash then
				local h=Instance.new("Highlight"); h.Adornee=model; h.FillColor=Color3.new(1,1,1); h.FillTransparency=.25; h.OutlineTransparency=1; h.DepthMode=Enum.HighlightDepthMode.Occluded; h.Parent=fx
				flash={highlight=h,untilTime=now}; flashes[model]=flash
			end
			flash.untilTime=now+Config.unitCombat.hitFlashSeconds
		end
		if message.style=="Melee" then return end
		local p=Instance.new("Part"); p.Name="CosmeticProjectile"; p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.CastShadow=false
		if message.style=="Arrow" then p.Size=Vector3.new(.13,.13,1.2); p.Color=Color3.fromRGB(227,206,155)
		else p.Shape=Enum.PartType.Ball; p.Size=Vector3.new(.6,.6,.6); p.Material=Enum.Material.Neon; p.Color=if message.unitId=="Necromancer" then Color3.fromRGB(177,86,238) else Color3.fromRGB(87,185,255) end
		p.CFrame=CFrame.new(message.source); p.Parent=fx
		table.insert(shots,{part=p,from=message.source,to=message.target,born=now,duration=math.max(.05,(message.target-message.source).Magnitude/Config.unitCombat.projectileSpeedStudsPerSecond)})
	end))
	table.insert(connections,state:GetAttributeChangedSignal("MatchStatus"):Connect(function(): () if state:GetAttribute("MatchStatus")~="InProgress" then clearEffects() end end))
	table.insert(connections,RunService.RenderStepped:Connect(function(): ()
		local now=os.clock()
		for index=#shots,1,-1 do local s=shots[index]; local alpha=(now-s.born)/s.duration
			if alpha>=1 then s.part:Destroy(); table.remove(shots,index)
			else local p=s.from:Lerp(s.to,alpha); s.part.CFrame=if (s.to-p).Magnitude>.001 then CFrame.lookAt(p,s.to) else CFrame.new(p) end
		end
		for model,flash in flashes do if now>=flash.untilTime or model.Parent==nil then flash.highlight:Destroy(); flashes[model]=nil end end
		for model,time in deadAt do
			local alpha=math.clamp((now-time)/Config.unitCombat.deathVisualSeconds,0,1)
			for _,part in model:GetDescendants() do if part:IsA("BasePart") then part.LocalTransparencyModifier=alpha end end
		end
	end))
	root.Destroying:Connect(function(): ()
		for _,c in connections do c:Disconnect() end; for _,b in bars do for _,c in b.connections do c:Disconnect() end; b.gui:Destroy() end
		clearEffects(); fx:Destroy()
	end)
end
return table.freeze(Visuals)
