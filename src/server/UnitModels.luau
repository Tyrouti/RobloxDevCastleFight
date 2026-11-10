--!strict
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.UnitPresentation)
local Definitions=require(Shared.Config.UnitConfig)
local UnitModels={}
local function add(model: Model,name: string,size: Vector3,p: Vector3,color: Color3,material: Enum.Material?): Part
	local part=Instance.new("Part"); part.Name=name; part.Size=size; part.CFrame=CFrame.new(p); part.Color=color
	part.Material=material or Enum.Material.SmoothPlastic; part.Anchored=true; part.CanCollide=false; part.CanTouch=false; part.CanQuery=false
	part.TopSurface=Enum.SurfaceType.Smooth; part.BottomSurface=Enum.SurfaceType.Smooth; part.Parent=model; return part
end
function UnitModels.Create(unitId: Types.UnitId): Model
	local info=Config.entries[unitId]; assert(info,"E_UNIT_ID")
	local templates=game:GetService("ServerStorage"):FindFirstChild("CastleFightUnitTemplates")
	local template=templates and templates:FindFirstChild(info.assetId)
	local model: Model
	if template then assert(template:IsA("Model"),"E_UNIT_TEMPLATE_TYPE"); local clone=template:Clone(); assert(clone,"E_UNIT_TEMPLATE_ARCHIVABLE"); model=clone
	else
		model=Instance.new("Model"); model.Name=unitId
		local human=Definitions[unitId].faction=="Human"
		local cloth=if human then Color3.fromRGB(40,108,201) else Color3.fromRGB(117,56,158)
		local bone=if human then Color3.fromRGB(225,190,149) else Color3.fromRGB(218,214,184)
		local metal=if human then Color3.fromRGB(164,177,189) else Color3.fromRGB(83,84,94)
		local caster=unitId=="Mage" or unitId=="Necromancer"
		add(model,"Torso",Vector3.new(1.8,1.65,.9),Vector3.new(0,2.45,0),if caster then cloth else metal)
		add(model,"Head",Vector3.new(1.55,1.4,1.25),Vector3.new(0,3.95,0),bone)
		for _,side in {-1,1} do
			add(model,"Leg"..side,Vector3.new(.65,1.6,.8),Vector3.new(side*.48,.8,0),if human then metal else bone)
			add(model,"Arm"..side,Vector3.new(.55,1.7,.65),Vector3.new(side*1.18,2.5,0),if caster then cloth else bone)
			add(model,"Eye"..side,Vector3.new(.22,.25,.08),Vector3.new(side*.34,4.05,-.65),Color3.fromRGB(25,29,38))
		end
		if unitId=="Knight" then
			add(model,"Helmet",Vector3.new(1.7,.45,1.4),Vector3.new(0,4.65,0),metal)
			add(model,"Shield",Vector3.new(.3,1.6,1.1),Vector3.new(-1.65,2.3,-.15),cloth)
			add(model,"Sword",Vector3.new(.25,2.2,.25),Vector3.new(1.55,2.8,-.3),metal)
		elseif unitId=="Archer" or unitId=="SkeletonArcher" then
			add(model,"Hood",Vector3.new(1.7,.5,1.4),Vector3.new(0,4.65,.1),if human then Color3.fromRGB(120,133,81) else cloth)
			add(model,"Bow",Vector3.new(.3,2,.35),Vector3.new(1.55,2.7,-.4),Color3.fromRGB(135,101,65))
			for _,sign in {-1,1} do add(model,"BowTip"..sign,Vector3.new(.6,.2,.3),Vector3.new(1.3,2.7+sign,-.4),bone) end
		elseif caster then
			add(model,"Robe",Vector3.new(1.9,1.5,1.15),Vector3.new(0,1.1,.15),cloth)
			add(model,"Hat",Vector3.new(1.9,.4,1.65),Vector3.new(0,4.65,.05),cloth)
			add(model,"HatTop",Vector3.new(.9,.8,.9),Vector3.new(0,5.15,.05),if human then Color3.fromRGB(222,181,72) else metal)
			add(model,"Staff",Vector3.new(.25,3.8,.25),Vector3.new(1.55,2.4,-.3),Color3.fromRGB(101,80,65))
			add(model,"StaffOrb",Vector3.new(.7,.7,.7),Vector3.new(1.55,4.5,-.3),if human then Color3.fromRGB(109,204,241) else Color3.fromRGB(119,238,140),Enum.Material.Neon)
		else
			add(model,"ShoulderArmor",Vector3.new(2.8,.8,1.2),Vector3.new(0,3.15,.05),metal)
			add(model,"BoneCrest",Vector3.new(.65,.8,.9),Vector3.new(0,4.85,0),bone)
			add(model,"Club",Vector3.new(.5,2.8,.5),Vector3.new(1.65,2.5,-.3),Color3.fromRGB(115,102,84))
			add(model,"ClubHead",Vector3.new(1.1,1.2,1.1),Vector3.new(1.65,4,-.3),metal)
		end
	end
	local ok,failure=pcall(function(): boolean
		local count=0
		for _,obj in model:GetDescendants() do
			assert(not obj:IsA("LuaSourceContainer") and not obj:IsA("Humanoid") and not obj:IsA("AnimationController") and not obj:IsA("Bone") and not obj:IsA("JointInstance") and not obj:IsA("Constraint"),"E_UNIT_TEMPLATE_REQUIRES_REVIEW")
			if obj:IsA("BasePart") then count+=1; obj.Anchored=true; obj.CanCollide=false; obj.CanTouch=false; obj.CanQuery=false end
		end
		assert(count>0 and count<=Config.maxTemplateParts,"E_UNIT_TEMPLATE_PARTS")
		model.PrimaryPart=nil; model:PivotTo(CFrame.identity)
		local _,size=model:GetBoundingBox(); assert(size.Y>0,"E_UNIT_TEMPLATE_SIZE"); model:ScaleTo(model:GetScale()*info.height/size.Y)
		local cf,bounds=model:GetBoundingBox(); model:PivotTo(CFrame.new(-cf.X,-cf.Y+bounds.Y/2,-cf.Z)*model:GetPivot()); model.WorldPivot=CFrame.identity
		model:SetAttribute("AssetId",info.assetId); return true
	end)
	if not ok then model:Destroy(); error(failure) end
	return model
end
return table.freeze(UnitModels)
