# Unit spawning and movement

Historical stage15. [Stage16 combat](COMBAT_TESTING.md) later adds damage; StartUnitDemo now fights. Historical production intervals and spawn geometry below were superseded by P20/P21/P21B.

## Both factions/lanes in one test

Open main place/current Map/existing default.project.json Rojo, Play, **Server**:

~~~lua
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("StartUnitDemo"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("UnitSnapshot"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("RunUnitChecks"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("Finish"))
~~~

Do not Start first: demo calls existing startTestMatch, only Waiting/Finished; it never deletes active buildings to restart. Finish deliberately before rerunning. It buys KnightBarracks/ArcherTower/MageAcademy and GiantGraveyard/BoneTower/NecromancerCrypt on both lanes (12), using Studio-only AddGold for missing funds without bypassing prices/limits. Player remains Human, no enemy-building right; not a bot. Published game has no Control.

Demo overview camera shows twelve static Parts characters after five seconds: six types on both lanes, Human right/Undead left, configured HP/speed/damage. Original stage15 ended WaitingAtCastle without damage. Finish resets camera/state; Stop ends simulation. Normal Start/BuildMenu Producers also spawn. Sale stops future attempts, preserves units. Upgrade changes new units/next interval only, no second timer. Stage15 did not add passives/combat/rigging/animation.

## Timing and routes

First deadline five seconds after build commit; one schedule per building GUID in common Heartbeat. Upgrade preserves first deadline or last-attempt time; new interval applies to elapsed time. Historical Archer14/12.6 and Knight22/19.8 seconds are superseded by P21B. Copy MaxHP/base damage each spawn; old snapshots/models remain.

At thirty live units per faction, skip attempt and schedule normal interval; no queue/immediate refill. Slow frames do not burst missed waves. Stable PadId order is technical ordering, not an approved fairness queue. Use actual TopLane/BottomLane.Waypoints and pad LaneEntry. Original lane-start path began ahead of entry with constant height/Z, no return toward own castle; P20/P21 later add producer exit and final contact approach. WaitingAtCastle stays live/occupies capacity. Original stage15 could visually overlap waiting units; later bounds/formation work supersedes that.

## API/security

Runtime owns one UnitService. SyncBuildings follows successful commits, never client attributes. API Step(dt), SyncBuildings(), GetCount(faction), GetUnit(instanceId), GetUnits(), GetDiagnostics(), RemoveUnit(instanceId), ClearUnits(). Getters copy, stats/path frozen. RemoveUnit releases capacity; stage15 had no damage/reward API.

Attributes: UnitId, unique UnitInstanceId, Faction, LaneId, HP/MaxHP, Speed, State, SourceBuildingId GUID, SourceBuildingType, SourcePadId, SourceBuildingLevel, BaseDamage, DamageType, AttackRange, AttackCooldown, MatchId, AssetId. Replication only; private server authority. Clients send no position/HP/spawn/faction. Anchored parts avoid client physics ownership.

One server Heartbeat for units/schedules, one client RenderStepped interpolation. No PathfindingService, per-NPC coroutine/loop/task.delay, or Humanoid. Server enforces speed×dt and corrects unexpected displacement. Client CFrame edits cannot change server path/state.

## Visual templates

Manually create ServerStorage.CastleFightUnitTemplates Folder after static-model review. Model names match UnitPresentation: human_knight, human_archer, human_mage, undead_giant, undead_skeleton_archer, undead_necromancer. Clone source with MeshId/textures; preserve proportions, visual height, feet-center pivot, forward−Z. Height is cosmetic, not HP/speed.

Accept1..100 static BasePart/MeshPart, no scripts/Humanoid/AnimationController/Bones/joints/constraints. Rig needs separate review. KnightBody diagnostic is not a ready Humanoid and remains unchanged. Missing template uses distinct Parts silhouettes: knight/helmet/sword/shield, archer/hood/bow, mage/staff, bone giant, skeleton archer, necromancer. Invalid templates increment modelErrors without generating/downloading replacements.

## Historical checks

73 isolated checks with cloned pads/controlled clocks: six types/two lanes, no spawn before5s, speed/direction/attributes/sources, no Passive spawning, sale,14→12.6 upgrade/no duplicate timer, old HP/damage preserved, pre-first upgrade,30+30/cap skip/no queue, WaitingAtCastle, displacement correction, cleanup/restart, all placeholder pivots/heights/assetIds. Primary Map/accounts untouched. Earlier economy43/building64/management47 passed.

Real Play:12 purchases,6+6 after5s, armies visually checked both lanes; reached30+30, all60 waiting at castles,68 skipped cap attempts, modelErrors0/movementCorrections0. Enemy purchase E_NOT_YOUR_PAD. Real sale schedules12→11 preserving units; Archer upgrade kept schedule count. Finish removed60/all buildings/schedules. Repeat after camera integration: first wave12, Finish Custom/zero counters, second demo exactly12 schedules/wave after5s. Strict/build/verify passed, no session client/server errors.

No two real clients, poor-network/mobile FPS, or imported Meshy-unit-template tests. Sixty models is functional evidence, not universal FPS. Manually check smoothing/build clicks, streaming/latency, future model scale/forward. Map/source assets/test scenes unchanged; no paid calls.

API: [Model/PivotTo](https://create.roblox.com/docs/reference/engine/classes/Model), [Heartbeat](https://create.roblox.com/docs/reference/engine/classes/RunService#Heartbeat), [CFrame.Lerp](https://create.roblox.com/docs/reference/engine/datatypes/CFrame#Lerp).
