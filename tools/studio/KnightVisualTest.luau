--!strict
-- Editor-only utility for the standalone KnightVisualTest place. Never runs automatically.
local KnightVisualTest = {}
local SCENE_ID = "castlefight.knight-visual-test.v1"

export type CheckResult = {
	imported: boolean, bodyHeight: number?, feetY: number?, pivotY: number?,
	visualParts: number, collidableVisualParts: number, unanchoredVisualParts: number,
	forward: Vector3?,
}

local function sceneGuard(root: Model): ()
	local marker = root:FindFirstChild("SceneId")
	assert(marker and marker:IsA("StringValue") and marker.Value == SCENE_ID,
		"Wrong scene: open assets/tests/human_knight/KnightVisualTest.rbxlx first")
	assert(root.Parent == nil or root.Parent == workspace, "Test scene must be a top-level Model")
end

local function visualParts(object: Instance): {BasePart}
	local result: {BasePart} = {}
	if object:IsA("BasePart") then table.insert(result, object) end
	local descendants = object:GetDescendants()
	assert(#descendants <= 500, "Unexpectedly large import; inspect manually")
	for _, item in descendants do
		assert(not item:IsA("LuaSourceContainer") and not item:IsA("Humanoid")
			and not item:IsA("Bone") and not item:IsA("JointInstance")
			and not item:IsA("Constraint") and not item:IsA("AnimationController"),
			"Only static meshes/parts accepted; do not add scripts or a rig")
		if item:IsA("BasePart") then table.insert(result, item) end
	end
	return result
end

local function disablePhysics(parts: {BasePart}): ()
	for _, part in parts do
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
	end
end

-- source is the manually imported Model/MeshPart, preferably stored in ServerStorage.
-- yawDegrees=180 when its face points +Z, or 0 when it already faces -Z.
-- Fix an incorrect up axis in the Importer before running this utility.
function KnightVisualTest.Prepare(source: Instance, root: Model, height: number, yawDegrees: number): Model
	sceneGuard(root)
	assert(source:IsA("Model") or source:IsA("MeshPart"), "Select actual imported Model or MeshPart")
	assert(not source:IsDescendantOf(root) and source ~= root, "Select imported source, not the stand")
	assert(not root:FindFirstChild("KnightBody"), "KnightBody exists; no duplicate created")
	assert(height == height and height >= 1 and height <= 20, "Choose finite height in studs")
	assert(yawDegrees == 0 or yawDegrees == 180, "Use yaw 0 or 180 after inspecting front")
	assert(#visualParts(source) > 0, "Import has no geometry")
	local wrapper = Instance.new("Model")
	wrapper.Name = "KnightBody"
	local copy = source:Clone()
	assert(copy, "Imported source must be Archivable")
	copy.Parent = wrapper
	disablePhysics(visualParts(wrapper))
	wrapper.PrimaryPart = nil
	local _, size = wrapper:GetBoundingBox()
	assert(size.Y > 0.001, "Invalid height; check import orientation")
	wrapper:ScaleTo(wrapper:GetScale() * height / size.Y)
	local boxCF, boxSize = wrapper:GetBoundingBox()
	local bottom = boxCF.Position - Vector3.new(0, boxSize.Y / 2, 0)
	wrapper.WorldPivot = CFrame.new(bottom)
	local feet = Vector3.new(0, 0.25, 0)
	wrapper:PivotTo(CFrame.new(feet) * CFrame.Angles(0, math.rad(yawDegrees), 0))
	-- Reset pivot axes only; geometry keeps the rotation just applied.
	wrapper.WorldPivot = CFrame.new(feet)
	wrapper:SetAttribute("TestHeightStuds", height)
	wrapper:SetAttribute("ImportYawDegrees", yawDegrees)
	wrapper:SetAttribute("VisualOnly", true)
	wrapper.Parent = root
	local imported = root:FindFirstChild("BodyImported")
	if imported and imported:IsA("BoolValue") then imported.Value = true end
	local pad = root:FindFirstChild("KnightPad")
	local label = if pad then pad:FindFirstChild("Label") else nil
	local text = if label then label:FindFirstChild("Text") else nil
	if text and text:IsA("TextLabel") then
		text.Text = "BODY COPY PREPARED\nVerify front / texture / hands"
	end
	return wrapper
end

-- Static placement only: no joints, Tools, skinning, animations or attachments.
-- Grip transforms are initial visual estimates, not measured hand sockets.
function KnightVisualTest.PlaceEquipment(root: Model): ()
	sceneGuard(root)
	local body = root:FindFirstChild("KnightBody")
	assert(body and body:IsA("Model"), "Import and prepare the body first")
	local sword, shield = root:FindFirstChild("Sword"), root:FindFirstChild("Shield")
	assert(sword and sword:IsA("Model") and shield and shield:IsA("Model"), "Equipment missing")
	local height = body:GetAttribute("TestHeightStuds")
	assert(typeof(height) == "number", "Missing normalized height")
	local ratio = height / 5
	sword:ScaleTo(ratio)
	shield:ScaleTo(ratio)
	sword:PivotTo(CFrame.new(2.48 * ratio, 0.25 + 2.62 * ratio, -0.05 * ratio)
		* CFrame.Angles(0, 0, math.rad(-65)))
	shield:PivotTo(CFrame.new(-2.48 * ratio, 0.25 + 2.62 * ratio, -0.32 * ratio))
	disablePhysics(visualParts(sword))
	disablePhysics(visualParts(shield))
	root:SetAttribute("EquipmentPlacement", "static_approximation_check_hands_manually")
end

function KnightVisualTest.Check(root: Model): CheckResult
	sceneGuard(root)
	local count, collidable, unanchored = 0, 0, 0
	for _, name in {"KnightBody", "Sword", "Shield", "Reference5Stud"} do
		local object = root:FindFirstChild(name)
		if object then
			for _, part in visualParts(object) do
				count += 1
				if part.CanCollide or part.CanTouch or part.CanQuery then collidable += 1 end
				if not part.Anchored then unanchored += 1 end
			end
		end
	end
	local result: CheckResult = {
		imported = false, visualParts = count, collidableVisualParts = collidable,
		unanchoredVisualParts = unanchored,
	}
	local body = root:FindFirstChild("KnightBody")
	if body and body:IsA("Model") then
		local cf, size = body:GetBoundingBox()
		result.imported = true
		result.bodyHeight = size.Y
		result.feetY = cf.Position.Y - size.Y / 2
		result.pivotY = body:GetPivot().Position.Y
		result.forward = body:GetPivot().LookVector
	end
	return result
end

return KnightVisualTest
