--!strict
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local Definitions=require(Shared.Config.BuildingConfig)
local Presentation=require(Shared.Config.BuildingPresentation)
local Models={}
local function producerAnchor(model: Model,buildingId: Types.BuildingId): ()
	if Definitions[buildingId].kind~="Producer" then return end
	local existing=model:FindFirstChild("UnitSpawn",true)
	if existing then assert(existing:IsA("Attachment"),"E_BUILDING_UNIT_SPAWN_TYPE");return end
	local root=model:FindFirstChildWhichIsA("BasePart",true);assert(root,"E_BUILDING_ROOT")
	local cf,size=model:GetBoundingBox();local facing=model:GetPivot().LookVector
	local center=Vector3.new(cf.X,cf.Y-size.Y/2,cf.Z)
	local distance=(math.abs(facing.X)*size.X+math.abs(facing.Z)*size.Z)/2
	local pose=CFrame.lookAt(center+facing*distance,center+facing*(distance+1))
	local attachment=Instance.new("Attachment");attachment.Name="UnitSpawn";attachment.CFrame=root.CFrame:ToObjectSpace(pose);attachment.Parent=root
end

function Models.CreateUpgradeVisual(model: Model,faction: Types.FactionId): Folder
	local folder=Instance.new("Folder"); folder.Name="LevelTwoVisuals"
	local glow=Instance.new("Highlight"); glow.Name="LevelTwoGlow"; glow.Adornee=model
	glow.FillColor=if faction=="Human" then Color3.fromRGB(245,195,75) else Color3.fromRGB(123,240,146)
	glow.OutlineColor=glow.FillColor; glow.FillTransparency=.85; glow.OutlineTransparency=.15
	glow.DepthMode=Enum.HighlightDepthMode.Occluded; glow.Parent=folder
	return folder
end

local function add(model: Model,name: string,size: Vector3,position: Vector3,color: Color3,material: Enum.Material?): Part
	local p=Instance.new("Part"); p.Name=name; p.Size=size; p.CFrame=CFrame.new(position)
	p.Anchored=true; p.CanCollide=false; p.CanTouch=false; p.CanQuery=true
	p.Color=color; p.Material=material or Enum.Material.SmoothPlastic
	p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth; p.Parent=model; return p
end

function Models.Fit(model: Model,pad: BasePart): ()
	assert(model.Parent==nil,"E_TEMPLATE_MUST_BE_CLONE")
	local parts=0
	for _,obj in model:GetDescendants() do
		assert(not obj:IsA("LuaSourceContainer") and not obj:IsA("Humanoid") and not obj:IsA("Constraint") and not obj:IsA("JointInstance"),"E_UNSAFE_TEMPLATE")
		if obj:IsA("BasePart") then
			parts+=1; obj.Anchored=true; obj.CanCollide=false; obj.CanTouch=false; obj.CanQuery=true
		end
	end
	assert(parts>0 and parts<=200,"E_TEMPLATE_PARTS")
	model.PrimaryPart=nil; model:PivotTo(CFrame.identity)
	local _,size=model:GetBoundingBox()
	assert(size.X>0 and size.Y>0 and size.Z>0,"E_TEMPLATE_SIZE")
	local margin=Presentation.padMarginStuds*2
	local scale=math.min(1,(pad.Size.X-margin)/size.X,(pad.Size.Z-margin)/size.Z,Presentation.maxHeightStuds/size.Y)
	assert(scale>0,"E_PAD_SIZE"); model:ScaleTo(model:GetScale()*scale)
	local cf,bounds=model:GetBoundingBox()
	model:PivotTo(CFrame.new(-cf.X,-cf.Y+bounds.Y/2,-cf.Z)*model:GetPivot())
	model.WorldPivot=CFrame.identity
	local entry=pad:FindFirstChild("LaneEntry")
	local facing=if entry and entry:IsA("Attachment") and entry.Position.Z>0 then math.pi else 0
	model:PivotTo(pad.CFrame*CFrame.new(0,pad.Size.Y/2,0)*CFrame.Angles(0,facing,0))
end

function Models.Create(buildingId: Types.BuildingId,pad: BasePart): Model
	local info=Presentation.entries[buildingId]; assert(info,"E_BUILDING_ID")
	local templates=game:GetService("ServerStorage"):FindFirstChild("CastleFightBuildingTemplates")
	local template=templates and templates:FindFirstChild(info.assetId)
	if template then
		assert(template:IsA("Model"),"E_TEMPLATE_TYPE")
		local clone=template:Clone(); assert(clone,"E_TEMPLATE_ARCHIVABLE")
		local ok,failure=pcall(function(): boolean Models.Fit(clone,pad); producerAnchor(clone,buildingId); return true end)
		if not ok then clone:Destroy(); error(failure) end
		return clone
	end
	local model=Instance.new("Model"); model.Name=buildingId
	local human=Definitions[buildingId].faction=="Human"
	local stone=if human then Color3.fromRGB(208,202,180) else Color3.fromRGB(66,61,79)
	local accent=if human then Color3.fromRGB(42,112,212) else Color3.fromRGB(133,62,182)
	local detail=if human then Color3.fromRGB(230,188,75) else Color3.fromRGB(117,230,135)
	add(model,"Foundation",Vector3.new(7,.6,8),Vector3.new(0,.3,0),stone,Enum.Material.Slate)
	local style=info.style
	if style=="Barracks" then
		add(model,"Hall",Vector3.new(6,4,6),Vector3.new(0,2.6,0),stone)
		add(model,"Roof",Vector3.new(7,1.2,7),Vector3.new(0,5.2,0),accent)
		add(model,"Door",Vector3.new(2,3,.2),Vector3.new(0,2.1,-3.1),Color3.fromRGB(67,70,76))
		for _,x in {-2.4,2.4} do add(model,"Banner"..x,Vector3.new(.7,2,.2),Vector3.new(x,3.7,-3.2),detail) end
	elseif style=="Tower" or style=="BoneTower" then
		add(model,"Tower",Vector3.new(4,7,4),Vector3.new(0,4.1,0),stone,Enum.Material.Slate)
		add(model,"Platform",Vector3.new(6,1,6),Vector3.new(0,8.1,0),accent)
		for _,x in {-2.4,2.4} do for _,z in {-2.4,2.4} do add(model,"Merlon"..x..z,Vector3.new(1,1.5,1),Vector3.new(x,9.2,z),if human then stone else Color3.fromRGB(207,201,175)) end end
		if not human then add(model,"Soul",Vector3.new(1,2,1),Vector3.new(0,9.1,0),detail,Enum.Material.Neon) end
	elseif style=="Academy" then
		add(model,"Hall",Vector3.new(6,3.5,6),Vector3.new(0,2.35,0),stone)
		add(model,"Roof",Vector3.new(7,.8,7),Vector3.new(0,4.5,0),accent)
		add(model,"Spire",Vector3.new(2,3,2),Vector3.new(0,6.3,0),accent)
		local crystal=add(model,"Crystal",Vector3.new(1.7,1.7,1.7),Vector3.new(0,8.6,0),detail); crystal.CFrame*=CFrame.Angles(0,0,math.pi/4)
	elseif style=="Sanctuary" then
		for _,x in {-2.4,2.4} do add(model,"Pillar"..x,Vector3.new(1.2,5,1.2),Vector3.new(x,3.1,0),stone) end
		add(model,"Arch",Vector3.new(6,1,2),Vector3.new(0,6.1,0),accent)
		add(model,"Altar",Vector3.new(3,1.5,3),Vector3.new(0,1.35,0),stone)
		add(model,"Light",Vector3.new(1.7,2,1.7),Vector3.new(0,3.1,0),detail)
	elseif style=="Graveyard" then
		add(model,"Earth",Vector3.new(6,.5,7),Vector3.new(0,.85,0),Color3.fromRGB(70,80,67))
		for index,z in {-2,1,3} do
			add(model,"Grave"..index,Vector3.new(2,3,.9),Vector3.new(if index%2==0 then 1.5 else -1.5,2.6,z),stone)
		end
		for _,x in {-2.7,2.7} do add(model,"GatePost"..x,Vector3.new(1,4,1),Vector3.new(x,2.6,-3),accent) end
	elseif style=="Crypt" then
		add(model,"Vault",Vector3.new(6,3.5,6),Vector3.new(0,2.35,0),stone,Enum.Material.Slate)
		add(model,"SteppedRoof",Vector3.new(6.5,1,6.5),Vector3.new(0,4.6,0),accent)
		add(model,"UpperRoof",Vector3.new(4,1.3,4),Vector3.new(0,5.75,0),stone)
		add(model,"Entrance",Vector3.new(2.2,2.8,.2),Vector3.new(0,2,-3.1),Color3.fromRGB(27,24,34))
		add(model,"Seal",Vector3.new(1.2,1.2,.3),Vector3.new(0,4.3,-3.3),detail,Enum.Material.Neon)
	else
		add(model,"Plinth",Vector3.new(5,1,5),Vector3.new(0,1.1,0),accent)
		add(model,"Monolith",Vector3.new(2.5,6,2.5),Vector3.new(0,4.6,0),stone,Enum.Material.Slate)
		local crown=add(model,"Crown",Vector3.new(2,2,2),Vector3.new(0,8.6,0),detail,Enum.Material.Neon); crown.CFrame*=CFrame.Angles(0,0,math.pi/4)
	end
	if not human and style~="Obelisk" then add(model,"SoulLantern",Vector3.new(.8,1,.8),Vector3.new(2.5,1.1,-3.5),detail,Enum.Material.Neon) end
	Models.Fit(model,pad); producerAnchor(model,buildingId); return model
end
return table.freeze(Models)
