# Economy — testing in the main CastleFight place

Historical report, 2026-11-08. Open CastleFight (placeId 101102700433907) with Workspace.Map. The Rojo connection was verified: Main.server.luau maps to Script, Main.client.luau to LocalScript. default.project.json was unchanged. Never overwrite CastleFight.rbxl with build/Economy.rbxlx: the build contains code, not the current map.

Press Play and select **Server** in the Command Bar. Waiting HUD shows unassigned, 0 gold, +0/s.

~~~lua
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("Start"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("Snapshot"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("RunChecks"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("Finish"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("Reset"))
~~~

Run commands individually. The first player receives Human, the second Undead in a two-player test; this is diagnostic assignment only. Both server accounts exist without a second player. No bot exists. Start gives 350 gold, +6/s, InProgress; Starting is brief, with no artificial countdown. Finish gives Finished/0/+0; waiting adds nothing. Reset returns Waiting/unassigned. Start after either gives 350 and a new MatchId. Start during an active match is rejected. Stop removes simulation data. No DataStore writes occur. Published servers have no test Control. Automatic match startup was not implemented at this milestone; P23 later adds the local portal queue.

## Server API

EconomyService.new(config, onChanged) creates a private ledger; MatchService.new(economy, onChanged) owns its lifecycle. Runtime owns the real instances. Do not create a second EconomyService to read an active match. BuildingService uses the same dependency for purchases, upgrades, and sale refunds.

Methods: GetGold(faction), CanAfford(faction, amount), TrySpendGold(faction, amount, operationId, expectedMatchId), AddGold with the same arguments, ResetEconomy(matchId, giveStartingGold). SetActive/Step are coordinator internals. Only match lifecycle may reset. Do not call AddGold from kill handlers; kill rewards are absent.

Amounts must be positive and finite; NaN, infinity, zero, and negatives are rejected. Fractions remain exact. Each new intention needs a new server-generated operationId. Even failed operations cannot be repeated. Do not repeat purchase side effects on E_DUPLICATE_OPERATION. An old expectedMatchId is rejected after restart.

## Historical checks actually performed

Map read without changes: HumanCastle x=-88.375, UndeadCastle x=88.375; territories 70/60/70; all 20 PadId/OwnerFaction/LaneId passed MapBuilder.Check, five per group.

Single-player Studio Play: Waiting 0 → InProgress 350; observed ticks 458→464→470→476 (+6 each); Finished stayed 0 after 2.2 seconds; Reset Waiting; MatchId=2 restarted at 350. A single HUD displayed faction/gold/income/status and was visually inspected. Client attribute tampering to 999999 left server ledger 476; the next tick restored client/HUD to 482. Client could not see the ServerStorage test endpoint.

43 isolated Studio tests covered cap 9999, insufficient/zero balance, idempotency, conflicts, invalid numbers, fractions, receipt/fractional-second reset, and no income outside InProgress. Active accounts were untouched. Strict src analysis passed; client/server error logs were empty. Studio returned to Edit.

Limitations at that milestone: no two-client or phone test; departure/late join, bot, timer/victory remained TODO. Clients can fake their own HUD, not server gold. Manually check target-resolution readability, repeated starts, and two clients. Character spawned at the original off-arena SpawnLocation; map/spawn were unchanged.

API references: [RunService](https://create.roblox.com/docs/reference/engine/classes/RunService), [attributes](https://create.roblox.com/docs/reference/engine/classes/Instance#GetAttributeChangedSignal), [ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui).
