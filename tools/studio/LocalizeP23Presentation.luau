--!strict
-- Explicit editor-only text migration for the separate English P23 release copy.
local Config = require(game.ReplicatedStorage.CastleFightShared.Config.LobbyConfig)
type Mode = {position: Vector3, title: string, description: string, status: string, available: boolean}
local Modes: {[string]: Mode} = Config.modes :: any
local Localize = {}

function Localize.Run(): number
	assert(game:GetService("RunService"):IsEdit(), "E_EDIT_ONLY")
	assert(game.Name == "CastleFight_Arena17B_P23_English.rbxl", "E_ENGLISH_COPY_ONLY")
	local root = workspace:FindFirstChild("Lobby23")
	assert(root and root:IsA("Model"), "E_LOBBY_MISSING")
	local changed = 0
	local function setText(object: Instance, property: string, value: string): ()
		if (object :: any)[property] ~= value then
			(object :: any)[property] = value
			changed += 1
		end
	end
	for _, object in root:GetDescendants() do
		if object:IsA("TextLabel") then
			local panel = object.Parent and object.Parent.Parent
			if panel and panel:IsA("BasePart") and panel.Name == "ModeDescription" then
				local nearest: string? = nil
				local distance = math.huge
				for id, definition in Modes do
					local scale = if id == "Bot" or id == "Duel" then 1 else 0.65
					local expected = Config.origin + definition.position + Vector3.new(22, 4, 8) * scale
					local gap = (panel.Position - expected).Magnitude
					if gap < distance then distance = gap; nearest = id end
				end
				assert(nearest and distance < 0.01, "E_DESCRIPTION_POSITION")
				setText(object, "Text", Modes[nearest].description)
				continue
			end
			local portal = object:FindFirstAncestorWhichIsA("Model")
			local mode = if portal then Modes[portal.Name] else nil
			if mode then
				local plaque = object.Parent and object.Parent.Parent
				assert(plaque and plaque:IsA("BasePart"), "E_PLAQUE_STRUCTURE")
				-- Existing plaque proportions distinguish titles from statuses at both portal scales.
				setText(object, "Text", if plaque.Size.Y / plaque.Size.X > 0.1 then mode.title else mode.status)
			elseif object:IsDescendantOf(root.CastleArchitecture) and object.Text ~= "CASTLE FIGHT" then
				setText(object, "Text", "TWO KINGDOMS · ONE DESTINY")
			end
		elseif object:IsA("ProximityPrompt") and object.Name == "ChooseMode" then
			local portal = object:FindFirstAncestorWhichIsA("Model")
			local mode = if portal then Modes[portal.Name] else nil
			assert(mode, "E_PORTAL_MODE")
			setText(object, "ObjectText", mode.title)
			setText(object, "ActionText", if mode.available then "Join queue" else "Details · COMING SOON")
		end
	end
	return changed
end

return table.freeze(Localize)
