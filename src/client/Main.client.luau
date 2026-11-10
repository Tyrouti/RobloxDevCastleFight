--!strict
-- Server creates the state only in the game map. Do not race Workspace replication.
local state=game:GetService("ReplicatedStorage"):WaitForChild("CastleFightState",30)
if not state then return end
require(script.Parent.LobbyController).Start()
require(script.Parent.ArenaCamera).Start()
require(script.Parent.CastleHud).Start()
require(script.Parent.EconomyHud).Start()
require(script.Parent.BuildMenu).Start()
require(script.Parent.UnitRenderer).Start()
require(script.Parent.CombatVisuals).Start()

require(script.Parent.EffectVisuals).Start()
