--!strict
-- Command Bar / Edit-mode patch for an EXISTING KnightVisualTest scene.
-- Does not recreate KnightBody, import meshes, alter MeshId/texture, or add a rig.
local root = workspace:FindFirstChild("KnightVisualTest")
assert(root and root:IsA("Model"), "Open the existing KnightVisualTest scene first")
local marker = root:FindFirstChild("SceneId")
assert(marker and marker:IsA("StringValue") and marker.Value == "castlefight.knight-visual-test.v1", "Wrong scene")
assert(not game:GetService("RunService"):IsRunning(), "Stop the playtest before updating")

local function model(name: string): Model
	local item = root:FindFirstChild(name)
	assert(item and item:IsA("Model"), "Missing Model: " .. name)
	return item
end
local function part(parent: Instance, name: string): Part
	local item = parent:FindFirstChild(name)
	assert(item and item:IsA("Part"), "Expected existing Part: " .. name)
	return item
end
local function vector(v: Vector3): {number}
	return {v.X, v.Y, v.Z}
end

local body, sword, shield = model("KnightBody"), model("Sword"), model("Shield")
local padItem = root:FindFirstChild("KnightPad")
assert(padItem and padItem:IsA("BasePart"), "KnightPad missing")
local pad = padItem :: BasePart
assert(pad.CFrame.UpVector.Y > 0.999 and body:GetPivot().UpVector.Y > 0.999, "Expected an upright body and horizontal pad")
local grip = part(sword, "Grip")
local handle = part(shield, "Handle")
local upper, main, lower, tip = part(shield, "UpperPlate"), part(shield, "MainPlate"), part(shield, "LowerPlate"), part(shield, "Tip")

local bodyCF, bodySize = body:GetBoundingBox()
assert(bodySize.Y > 1 and bodySize.Y < 20, "Unexpected body scale")
local ratio = bodySize.Y / 5
local padTopY = (pad.CFrame * CFrame.new(0, pad.Size.Y / 2, 0)).Position.Y
local oldFeetY = bodyCF.Position.Y - bodySize.Y / 2
local groundDelta = padTopY - oldFeetY
assert(math.abs(groundDelta) < bodySize.Y, "Large ground correction: inspect the scene manually")

type Snapshot = {item: BasePart, cf: CFrame, size: Vector3, color: Color3, anchored: boolean,
	collide: boolean, touch: boolean, query: boolean, massless: boolean}
local snapshots: {Snapshot} = {}
local meshBefore: {[MeshPart]: {meshId: string, textureId: string, size: Vector3}} = {}
for _, object in {body, sword, shield} do
	for _, item in object:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer") and not item:IsA("Humanoid")
			and not item:IsA("Bone") and not item:IsA("JointInstance")
			and not item:IsA("Constraint"), "Unexpected script/rig; stop and inspect")
		if item:IsA("BasePart") then
			table.insert(snapshots, {item = item, cf = item.CFrame, size = item.Size, color = item.Color,
				anchored = item.Anchored, collide = item.CanCollide, touch = item.CanTouch,
				query = item.CanQuery, massless = item.Massless})
			if item:IsA("MeshPart") then
				meshBefore[item] = {meshId = item.MeshId, textureId = item.TextureID, size = item.Size}
			end
		end
	end
end
assert(#snapshots <= 100, "Unexpectedly many visual parts")
assert(next(meshBefore) ~= nil, "KnightBody contains no imported MeshPart")

local labels: {{item: BillboardGui, enabled: boolean}} = {}
for _, parentName in {"KnightPad", "ReferencePad", "SwordStand", "ShieldStand"} do
	local parent = root:FindFirstChild(parentName)
	local label = if parent then parent:FindFirstChild("Label") else nil
	if label and label:IsA("BillboardGui") then
		table.insert(labels, {item = label, enabled = label.Enabled})
	end
end
local oldSwordPrimary, oldShieldPrimary = sword.PrimaryPart, shield.PrimaryPart
local oldBodyPivot = body:GetPivot()
local history = game:GetService("ChangeHistoryService")
local recording: string? = nil
local recordOK, recordResult = pcall(function(): string?
	return history:TryBeginRecording("KnightVisualPolishV1", "Polish knight equipment and ground")
end)
if recordOK then recording = recordResult end

local ok, failure = pcall(function(): ()
	-- Translate only when needed. No scaling, mesh changes, body replacement or deletion.
	if math.abs(groundDelta) > 0.0001 then body:PivotTo(oldBodyPivot + Vector3.new(0, groundDelta, 0)) end
	local cf, size = body:GetBoundingBox()
	local footPosition = Vector3.new(cf.Position.X, padTopY, cf.Position.Z)
	local frame = CFrame.fromMatrix(footPosition, body:GetPivot().RightVector, body:GetPivot().UpVector)
	-- Palm centers estimated from the original low-poly hand vertex spans, then checked visually.
	-- These are STATIC editor positions, not rig/attachment sockets.
	local rightPalm = frame * CFrame.new(2.54 * ratio, 2.765 * ratio, 0.018 * ratio)
	local leftPalm = frame * CFrame.new(-2.54 * ratio, 2.765 * ratio, 0.018 * ratio)
	sword.PrimaryPart = grip
	shield.PrimaryPart = handle
	sword:PivotTo(rightPalm * CFrame.Angles(0, 0, math.rad(-72)))
	-- Reuse all five existing shield Parts. Diamond lower panel forms an actual pointed silhouette.
	local blue = Color3.fromRGB(37, 102, 205)
	local function panel(p: Part, dimensions: Vector3, offset: Vector3, roll: number): ()
		p.Size = dimensions * ratio
		p.CFrame = leftPalm * CFrame.new(offset * ratio) * CFrame.Angles(0, 0, math.rad(roll))
		p.Color = blue
	end
	handle.Size = Vector3.new(0.18, 0.46, 0.24) * ratio
	handle.CFrame = leftPalm
	panel(upper, Vector3.new(1.04, 0.18, 0.16), Vector3.new(0, 0.61, -0.2), 0)
	panel(main, Vector3.new(1.28, 0.82, 0.16), Vector3.new(0, 0.16, -0.2), 0)
	panel(lower, Vector3.new(0.905, 0.905, 0.16), Vector3.new(0, -0.25, -0.2), 45)
	-- This small tip support sits inside the diamond, avoiding an extra square projection.
	panel(tip, Vector3.new(0.24, 0.24, 0.12), Vector3.new(0, -0.72, -0.18), 45)
	for _, snap in snapshots do
		local p = snap.item
		p.Anchored = true p.CanCollide = false p.CanTouch = false p.CanQuery = false p.Massless = true
	end
	for _, label in labels do label.item.Enabled = false end
	local afterCF, afterSize = body:GetBoundingBox()
	assert(math.abs(afterSize.Y - bodySize.Y) < 0.001, "Body height changed")
	assert(math.abs(afterCF.Position.Y - afterSize.Y / 2 - padTopY) < 0.001, "Feet not on pad")
	for mesh, before in meshBefore do
		assert(mesh.MeshId == before.meshId and mesh.TextureID == before.textureId and mesh.Size == before.size,
			"Imported mesh identity/size changed")
	end
end)

if not ok then
	for _, snap in snapshots do
		local p = snap.item
		p.Size = snap.size p.CFrame = snap.cf p.Color = snap.color p.Anchored = snap.anchored
		p.CanCollide = snap.collide p.CanTouch = snap.touch p.CanQuery = snap.query p.Massless = snap.massless
	end
	body:PivotTo(oldBodyPivot)
	sword.PrimaryPart = oldSwordPrimary shield.PrimaryPart = oldShieldPrimary
	for _, label in labels do label.item.Enabled = label.enabled end
	if recording then history:FinishRecording(recording, Enum.FinishRecordingOperation.Cancel) end
	error("Update rolled back: " .. tostring(failure))
end
if recording then history:FinishRecording(recording, Enum.FinishRecordingOperation.Commit) end

local cf, size = body:GetBoundingBox()
local _, shieldSize = shield:GetBoundingBox()
local result = {
	version = 1, applied = true, bodyPreserved = true, height = size.Y,
	padTopY = padTopY, feetY = cf.Position.Y - size.Y / 2, groundDelta = groundDelta,
	swordGrip = vector(grip.Position), shieldHandle = vector(handle.Position), shieldBounds = vector(shieldSize),
	disabledBillboards = #labels, meshUnchanged = true, riggingPerformed = false,
}
print(game:GetService("HttpService"):JSONEncode(result))
return result
