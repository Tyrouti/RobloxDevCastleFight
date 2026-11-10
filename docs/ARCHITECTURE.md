# Castle Fight architecture

Read with MASTER_SPEC.md and AGENTS.md. Current runtime includes EconomyService, MatchService, BuildingService, UnitService, CombatService, EffectService, TerritoryService, and P23 lobby modules. Historical descriptions of future systems refer to their original milestones; the sections below explain subsequent integration.

## Sources and synchronization

src is authoritative code. Original CastleFight.rbxl and later approved P23 hold geometry; never overwrite them with Rojo builds. Workspace, Terrain, Lighting, and assets are outside synchronization.

| Disk | DataModel |
|---|---|
| src/shared | ReplicatedStorage.CastleFightShared |
| src/server | ServerScriptService.CastleFightServer |
| src/client | StarterPlayer.StarterPlayerScripts.CastleFightClient |

CastleFight folders isolate code. $ignoreUnknownInstances preserves unknown objects but matching names can update: inspect connection diff. Never edit the same scripts through parallel Rojo/MCP/other sync.

GameConfig stores economy/match/pads/limits/upgrades/sales; UnitConfig six units; BuildingConfig eight buildings and agreed effects; CombatConfig resistances/sword; Types IDs/record shapes. Historically Curse.parameters=nil meant unresolved, not zero damage; P22 supplies agreed curse damage. Configs have no tasks/DataModel side effects and are frozen. Runtime state is separate. Shared contains no secrets; server uses its own authoritative configuration.

## Responsibilities and dependencies

| Module | Responsibility |
|---|---|
| MatchService | Phase, lifecycle, result, cleanup coordination |
| EconomyService | Private gold/income and atomic spend/refund |
| BuildingService | Pads, ownership, faction/limits, build/upgrade/sell |
| UnitService | Spawn, cap, lane, immutable spawn stats, movement/private HP |
| CombatService | Targets, cooldown, resistance/damage, castle HP |
| EffectService | Lane-local temporary effects, schedules, damage filtering |
| TerritoryService | Spatial ownership |
| SwordService, BotService | Planned, not pre-created empty services |

Use explicit acyclic dependencies and Init/Start order. Stop connections/tasks on shutdown. Client controllers handle UI/input/cosmetics only.

Main.server → Runtime → services. Main.client starts HUD/rendering/lobby controllers; foundation Bootstrap modules remain. Runtime requires Map SceneId=castlefight.map.v1 and never rebuilds it. One server Heartbeat coordinates all updates. Client intentions contain IDs, never trusted price/damage/outcome. Server validates types, finite numbers, frequency, phase, ownership, faction, resources, limits.

## Economy and replication

Private faction balances are never read back from replicated state. MatchService controls activation/reset; Heartbeat dt accrues whole-second income with remainder. No income outside InProgress. Finish zeros gold; restart gives new MatchId/350. Timer victory was not connected in the original economy stage.

ReplicatedStorage.CastleFightState exposes MatchStatus/MatchId/IncomePerSecond. Player attributes CastleFightFaction/Gold/Income drive subscribed HUD. No economy remotes exist. TrySpendGold/AddGold accept server operationId/expectedMatchId, validate/write without yield, and retain receipts including failures until reset. Replay → E_DUPLICATE_OPERATION; parameter conflict → E_OPERATION_CONFLICT; old match → E_STALE_MATCH. At 10000 operations per faction new transactions block without dropping receipts: technical memory limit, not balance. Fractions preserved, AddGold capped. No kill handlers/rewards.

Studio-only ServerStorage.CastleFightStudioTests.Control (BindableFunction) controls Start/Finish/Reset/Snapshot/isolated checks. It is absent in published servers and inaccessible to clients. Diagnostic assignment sorts UserId, first two Human/Undead; extras/late joins wait until next Start. This is not general matchmaking/bot replacement. [Economy instructions](ECONOMY_TESTING.md).

## Construction and management

Runtime owns one BuildingService sharing economy/match. BuildingModels synchronously creates Parts or clones ServerStorage.CastleFightBuildingTemplates by assetId. BuildingPresentation contains assetId/labels/styles; prices stay in BuildingConfig. BuildingNetwork reads faction only from private seats; quota burst 6, refill 2/s.

CastleFightBuildRemotes contains BuildRequest/BuildResult. Legacy Build accepts exactly padId/buildingId/requestId/matchId; strings 1..64, positive finite integer matchId, no extra fields. Result goes only to sender: requestId/success/code/padId. Successful IDs bind operation parameters and cannot pay twice. No remote AddGold/SpendGold.

CanBuild is read-only. TryBuild prepares a detached model, checks base/footprint, provisionally publishes/registers, then pays last. No yields in factory/callback/API. Payment refusal removes only the new model and rolls back record/IsOccupied. Post-commit notification failure cannot repeat payment/refund. Future asynchronous imports must finish before TryBuild.

ActiveBuildings exists only in simulation with SystemOwner=CastleFightBuildings. Private records; getters copy. ClearBuildings removes only registered models/releases known pads, never Map geometry. A foreign existing ActiveBuildings folder blocks initialization. Starting/Finished/Waiting clears through callbacks. Player CastleFightBuildingCount updates HUD. BuildMenu raycast/Activated/TouchTapInWorld are UX only; server rechecks.

Management adds instanceId (new GUID per build), revision, level, totalSpent. Same service owns CanUpgrade/TryUpgrade/CanSell/TrySell/GetBuildingDetails. BuildingLevels snapshots are independent; spawner copies a new one per unit. Historical nil periodicDamage was unresolved and was later set by P22.

BuildRequest adds action=Build/Upgrade/Sell, preserving legacy Build. Upgrade/Sell allow only action/padId/instanceId/revision/requestId/matchId under the same quota. Faction remains private. Successful ID signature includes action/instance/revision. InstanceId blocks selling a replacement; Revision blocks commands prepared before upgrade.

All three operations share a pad lock and never yield. Upgrade prepares highlight and reversible level/spending/attribute changes before payment; failure restores all. Sale detaches model/releases record/pad before original AddGold; failure restores the same model, success destroys it. Rollback precedes notification. Service/coordinator callbacks must remain synchronous.

Details is immutable: current/next stats, upgrade price, nominal/actual capped refund. Replicated Level/Revision/TotalSpent/InstanceId serve UI only. L2 Highlight affects runtime clone, never source GLB/FBX/templates. Studio Control adds RunBuildingChecks/RunManagementChecks, not a second test match. [Construction](BUILDING_TESTING.md), [management](BUILDING_MANAGEMENT.md).

## Spawning, movement, combat

UnitService shares BuildingService/MatchService, read-only LaneRoutes, UnitModels factory, monotonic os.clock. Post-commit OnChanged synchronizes schedules by InstanceId. Sale removes schedule; upgrade changes snapshot/interval, not first deadline/last attempt. Passive buildings never spawn. No skipped-spawn queue or unbounded frame catch-up.

The common Heartbeat runs match/units, with effects/combat before movement as integrated later. No per-NPC loops, task.delay per building, PathfindingService, Humanoid, rig, or animation. Cap thirty per faction includes WaitingAtCastle. Private position/path/state/HP/stats remain authoritative; speed budgets constrain travel each Step and unexpected model displacement is corrected. LaneRoutes checks direction/order, reverse faction paths, lane separation; copied paths are immutable. Use real LaneEntry and skip waypoints behind it.

ActiveUnits exists only during simulation with SystemOwner=CastleFightUnits. Attributes: UnitInstanceId/UnitId/Faction/LaneId/HP/MaxHP/Speed/State/SourceBuildingId (GUID)/SourceBuildingType/SourcePadId/SourceBuildingLevel and combat stats. Static PivotTo is not rigging. UnitModels uses Parts or validated ServerStorage.CastleFightUnitTemplates clones. Anchored, CanCollide/CanTouch/CanQuery=false, so units do not block build clicks. One client RenderStepped interpolates MovementCFrame snapshots around 20 Hz; smoothing cannot change server position.

Finish/Starting/Waiting clear owned models/schedules/counts through coordinator. Shutdown disconnects Heartbeat. RemoveUnit is server-only; no reward. Studio StartUnitDemo/RunUnitChecks/UnitSnapshot use the same startTestMatch, real purchases, and price-derived test funding without bypassing limits. This is not a bot or permission to build for an enemy. Studio demo camera resets after Finish. [Spawning](UNIT_SPAWN_MOVEMENT.md).

Stage16 CombatService runs before movement, at most 10 Hz. UnitService owns HP/path, SetCombatState/ApplyDamage/death cleanup. CombatMath is pure resistance/castle-multiplier math using spawn snapshots. MatchService.Finish accepts optional winner/reason; GetResult returns it; Finish() remains compatible. Server castle HP replicates under CastleFightState.Castles; Winner/FinishReason on state. CombatVisuals is cosmetic. CastleFightCombatRemotes.Effect has server send only, no incoming damage handler. Cooldown/death use tables, not extra loops. RunCombatChecks isolates real services. [Combat](COMBAT_TESTING.md).

## Asset and editor pipelines

Meshy needs separate permission. After approval: agree list/style/scale; generate; track provenance/license; import; inspect polygons/textures/collision/rig/animation/performance; register actual IDs. Never invent IDs or add non-MVP systems. [Pipeline](ASSET_PIPELINE.md), [16-asset manifest](ASSET_MANIFEST.json). User chooses one of two real A/B concepts before each 3D model; selection.json records choice/hash. Concept selection and paid permission are separate. Pipeline does not generate/import/change Workspace automatically.

ArenaVisuals is an explicit MapBuilder dependency. Prepare validates off-Workspace; Build refuses existing Map; Archive stores old map in ServerStorage. SceneId remains castlefight.map.v1, VisualRevision=17B. Visible 7.8-square pad lies within functional 8×10 base. PadId/OwnerFaction/LaneId/IsOccupied and SpawnPoint/LaneEntry instances remain, positions updated for alternating rows. Redesign preserves castle/target/road/waypoint instances, requires Arena17B_Before.Map. Foundations continuously span both roads. Lighting is explicit editor action with CastleFight17ALightingBackup. Default profile never syncs Workspace/Lighting. [17B](ARENA_17B.md).

Editor-only Universal Asset Pipeline: tools/studio/AssetPipeline, assets/asset-preparation.json, separate asset-tools.project.json. Excluded from runtime, no Workspace sync/spawning/rigging. Dependencies Types/GeneratedConfig → Config/Safety → AssetPipeline/AssetVisualTest/EquipmentAttachment → Commands. Disk sources package one-way into rbxmx/installers. [Details](UNIVERSAL_ASSET_PIPELINE.md).

verify.ps1, separate Rojo builds/sourcemaps, Luau analysis, and Studio tests are distinct checks. A tree build is not type/runtime/full-match validation.

## Milestone integrations

**19:** CastleHud subscribes existing Human/Undead HP/MaxHP/MatchId; no second HP store/remote. Castle billboards show only DebugCastleBillboards=true. ArenaCamera sets initial view then preserves Custom/input. ArenaExpansion is explicit Map migration. CastleHudDemo buys real buildings; core services unchanged. arena-redesign also maps canonical runtime. [Report](ARENA_19.md).

**P20:** LaneRoutes builds SpawnPoint → LaneEntry → remaining lane waypoints → crystal approach, checks monotonic X/height/lane side; only final approach changes Z. UnitService/CombatService unchanged. Arena20Correction explicitly migrates existing Map. arena-p20 profile code-only; full geometry in Corrected.rbxl. [Report](ARENA_20_CORRECTION.md).

**P21:** BuildingModels adds UnitSpawn only to Producers. UnitGeometry measures prepared clones; UnitService creates individual LaneRoutes paths and checks clearance in common Step. Cache building bounds per Step. CrystalContact reads existing Octave1 pedestal for LaneRoutes/CombatService; HP remains CombatService-owned. UnitNavigation stores geometric clearances. Runtime adds Studio timing only. Approved Map unchanged. [Report](UNIT_21_FINALIZATION.md).

**P21B:** UnitGeometry uses oriented-rectangle SAT for ally bounds, old enemy-body clearance. UnitService distributes within lane width, bypasses stopped allies, selects free existing-melee-range positions. Short lateral attack reposition consumes speed budget; turns cannot overlap allies. Map/LaneRoutes/CombatService unchanged. BuildingConfig stores production periods; BuildingLevels applies ×0.9 with minimumProductionIntervalSeconds=20. Runtime adds Studio combat hold/counters only; normal gameplay never holds combat. Unit21BTests uses real services, controlled clocks, diagnostic scenes, original stats. [Report](UNIT_21B_SPAWN_COMBAT.md).

**P22:** EffectService depends on UnitService/BuildingService/MatchService/CombatMath, no reverse CombatService cycle. UnitService exposes narrow post-resistance damage filter and death/removal callback. One effect instance clears on match transitions; existing building callback syncs passive schedules. Effects update before combat. CombatService optionally receives outgoing multiplier/Necromancer OnAttack, retaining tests without effects. Entire castle-damage batch resolves before double-zero Finish(nil,Draw). MatchService unchanged.

EffectConfig stores new parameters; BuildingConfig keeps prices/IDs/periods plus approved curse damage; BuildingLevels retains ×1.25. Shields absorb calculated incoming damage. Each record has expires/nextTick/sourceId/power; nextTick advances before damage. Refresh adds no record/timer. Catch-up ticks bounded by lifespan; passive pulses do not burst catch-up.

Model attributes EffectShield/EffectCurse/EffectDamageOverTime use absolute GetServerTimeNow plus ShieldRemaining. Existing Effect event sends StatusEffect Applied/Updated/Expired/Removed/Broken, no incoming handler. EffectVisuals rebuilds from attributes using local Parts/ParticleEmitter/TweenService, one RenderStepped/event, noncolliding parts. Expired VFX disappear without removal messages; Debris finishes fading. Finish clears VFX; no second HP/damage authority. [Report](ABILITIES_22.md).

**P23:** LobbyBuilder.Prepare/LobbyArtPass build a finite courtyard separate from arena; explicit editor Build publishes and disables old spawn while preserving Enabled attribute. No Workspace/Lighting sync. LobbyConfig stores modes/availability/spawn/interaction. LobbyPolicy validates phase/life/distance. LobbyQueue is FIFO user IDs, guards duplicate/reentrant start, calls Runtime; no second MatchService.

Runtime binds existing match.Start to Human/Undead seats. LobbyService owns private player records, ProximityPrompt.Triggered, cancellation, CharacterAdded/PlayerRemoving, and return on Finish. Match state and player location are independent; bystanders never enter because global match is InProgress. Late joins stay Lobby. ParticipantLeft cancels without winner. Missing Lobby23 preserves P22 mode.

LobbyController/LobbyUI read CastleFightLocation/LobbyStatus/LobbyMode/LobbyQueueCount only. Select calls native InputHoldBegin/End on current prompt, not a trusted client mode; server rechecks. CancelQueue accepts only empty cancellation intent. Battle ScreenGui enables only at Match location. ArenaCamera changes initial transition overview, preserving Custom/input. Character/rig/speed unchanged. Player subscriptions disconnect on departure, service subscriptions on Shutdown. [Report](LOBBY_23.md).
