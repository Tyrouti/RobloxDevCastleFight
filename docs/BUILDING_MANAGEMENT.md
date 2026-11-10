# Upgrades and sales

Historical stage 14 report. [Stage 15](UNIT_SPAWN_MOVEMENT.md) later implemented spawning/movement with independent snapshots. References below to a future spawner or disabled effects describe stage 14; P22 later enables effects. Historical intervals below are not current P21B balance.

## Manual procedure

Open the main place with existing default.project.json/Rojo. Play; invoke Start on Server. Build on a friendly free pad, then select its model or occupied base. The same BuildMenu shows name/level, current/next stats, Upgrade price, and Sell refund.

ArcherTower costs 190, upgrade 133; starting 350 covers both. Historical L2 Archer: HP=120, damage=16.8, interval=12.6 s. Gold/green highlight appears; Upgrade disables. Refund: L2 193.8, L1 114. Pad releases, HUD decrements, rebuild allowed. KnightBarracks upgrade 182, total 442, L2 refund 265.2; wait for income after purchase. P21B supersedes production intervals; do not change balance to match this historical example.

Insufficient gold disables Upgrade with a hint. At cap 9999, credited sale may be below nominal 60%; panel shows both. No rounding of HP/damage/shield/interval/refund. Upgrade cost rounds nearest integer, half up; current prices already give integer 70%: 260→182, 190→133, 230→161, 200→140.

Run commands individually in **Server Command Bar**:

~~~lua
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("Start"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("RunManagementChecks"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("RunBuildingChecks"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("RunChecks"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("Finish"))
~~~

Finish removes upgraded models/highlights and frees pads. Start after Finish gives a new MatchId/350. Stop returns Edit without saving simulated buildings. Existing test-match mechanism is reused.

## Server contract

Same Runtime-owned BuildingService:

- CanUpgrade(faction, padId), CanSell(faction, padId) → boolean, code.
- TryUpgrade(faction, padId, instanceId, revision, requestId, expectedMatchId).
- TrySell has the same signature; both return boolean, code.
- GetBuildingDetails(faction, padId) → Details or nil; enemy requests reveal nothing.

Details: level, totalSpent, instanceId, revision, upgradeCost (nil at cap), refund, refundAtCurrentBalance, stats, nextStats. stats.unit is a new frozen UnitDefinition snapshot; spawnIntervalSeconds affects future spawns. UnitService must copy per spawn and preserve older snapshots/live units. Historical passive stats: shieldHealth=56.25 or curseDamageMultiplier=1.25, curseDamageType=Magical; curseDamage was nil/requiresManualConfiguration=true, not invented damage. Spawning/effects were not started by this stage.

BuildRequest remains the same RemoteEvent. Management sends exactly {action="Upgrade" or "Sell", padId, instanceId, revision, requestId, matchId}. No price, target level, spending, refund, or faction from clients. Server validates all fields/state. Each intention needs a fresh GUID requestId; successful IDs cannot replay or change actions. Pad locking prevents reentrant/concurrent handling. Upgrade changes Revision; rebuilding changes InstanceId. Missing responses do not trigger automatic duplicate payments.

Refusals: E_MAX_LEVEL, E_INSUFFICIENT_GOLD, E_NOT_YOUR_PAD, E_BUILDING_MISSING, E_STALE_BUILDING, E_BUILDING_VERSION, E_BUILDING_BUSY, E_DUPLICATE_REQUEST/E_REQUEST_CONFLICT, E_STALE_MATCH/E_MATCH_INACTIVE. Highlight/payment failure preserves level/spending/gold; credit failure restores the same sold model/occupancy. Original EconomyService commits money; no duplicate balance/service.

## Historical checks

Single-player main-place Play. 47 new Studio checks passed: L1→L2, level cap, insufficient funds, exact L1/L2 refunds, old unit snapshot preservation, shield/curse, ownership, duplicate/stale IDs/revisions, payment/credit rollback, reentrant Sell during Upgrade, release/rebuild, Finish, gold cap. Earlier building 64/economy 43 passed.

Actual ArcherTower click opened management; Upgrade spent 133, set Level=2/Revision=2/TotalSpent=323, correct highlight/stats. Sell removed it, freed pad, refunded 193.8; +6 income accounted separately. HUD showed fractional balance/0 of 10 and closed menu.

Real client RemoteEvents: replay Upgrade/Sell → E_DUPLICATE_REQUEST; delayed sale after rebuild or stale revision → E_STALE_BUILDING. One payment/credit per action. An upgraded tower before Finish was removed 1/1, pads free 20/20.

Desktop and iPhone 16 portrait layouts inspected. Synthetic emulator Sell click missed: layout-only mobile evidence, not native touch validation. Desktop button sale confirmed. Physical touch/scrolling and two clients remain manual.

All src strict, Rojo build, and verify passed; no Play client/server errors. Emulator off, Studio Edit. Map, KnightVisualTest/AssetVisualTest, original Meshy files, and approved concepts unchanged. No paid calls. Later [spawning](UNIT_SPAWN_MOVEMENT.md) and [combat](COMBAT_TESTING.md) add those systems; passive effects, bot, and monetization were absent at this historical stage.
