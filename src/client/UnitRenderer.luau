--!strict
-- Presentation only. Interpolation cannot change the server's private movement/HP records.
local RunService=game:GetService("RunService")
local Config=require(game:GetService("ReplicatedStorage").CastleFightShared.Config.UnitPresentation)
local MapConfig=require(game:GetService("ReplicatedStorage").CastleFightShared.Config.MapConfig)
type View={pose: CFrame,target: CFrame,connection: RBXScriptConnection}
local Renderer={}
local started=false
function Renderer.Start(): ()
	if started then return end; started=true
	local folder=workspace:WaitForChild("ActiveUnits")
	local demoConnection: RBXScriptConnection?=nil
	if RunService:IsStudio() then
		local state=game:GetService("ReplicatedStorage"):WaitForChild("CastleFightState")
		local previous: {camera: Camera,kind: Enum.CameraType,pose: CFrame}?=nil
		local function demoView(): ()
			local camera=workspace.CurrentCamera; if not camera then return end
			if state:GetAttribute("StudioUnitDemo")==true then
				if not previous then previous={camera=camera,kind=camera.CameraType,pose=camera.CFrame} end
				camera.CameraType=Enum.CameraType.Scriptable
				camera.CFrame=CFrame.lookAt(MapConfig.origin+Vector3.new(0,135,115),MapConfig.origin+Vector3.new(0,3,0))
			elseif previous then
				previous.camera.CameraType=previous.kind; previous.camera.CFrame=previous.pose; previous=nil
			end
		end
		demoConnection=state:GetAttributeChangedSignal("StudioUnitDemo"):Connect(demoView); demoView()
	end
	local views: {[Model]:View}={}
	local function add(obj: Instance): ()
		if not obj:IsA("Model") or obj:GetAttribute("SystemOwner")~="CastleFightUnits" then return end
		local target=obj:GetAttribute("MovementCFrame"); if typeof(target)~="CFrame" then return end
		local connection=obj:GetAttributeChangedSignal("MovementCFrame"):Connect(function(): ()
			local view=views[obj]; local pose=obj:GetAttribute("MovementCFrame")
			if view and typeof(pose)=="CFrame" then view.target=pose end
		end)
		views[obj]={pose=target,target=target,connection=connection}
	end
	local added=folder.ChildAdded:Connect(add)
	local removed=folder.ChildRemoved:Connect(function(obj: Instance): ()
		if obj:IsA("Model") then local view=views[obj]; if view then view.connection:Disconnect(); views[obj]=nil end end
	end)
	for _,obj in folder:GetChildren() do add(obj) end
	local render=RunService.RenderStepped:Connect(function(dt: number): ()
		local alpha=1-math.exp(-Config.smoothingRate*dt)
		for model,view in views do view.pose=view.pose:Lerp(view.target,alpha); model:PivotTo(view.pose) end
	end)
	folder.Destroying:Connect(function(): ()
		added:Disconnect(); removed:Disconnect(); render:Disconnect(); for _,view in views do view.connection:Disconnect() end; table.clear(views)
		if demoConnection then demoConnection:Disconnect() end
	end)
end
return table.freeze(Renderer)
