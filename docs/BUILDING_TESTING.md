# Castle Fight construction

Historical construction milestone; later functionality is documented in the linked reports.

## Studio procedure

Open the main place with Workspace.Map.BuildPads and its existing default.project.json Rojo connection. No new profile is needed. Synchronization was verified through module reads and Playtest. build/Building.rbxlx contains code only; do not open it over the original map.

Press Play; in the **Server Command Bar**, invoke Start. The single player receives Human/350. Select a free friendly pad and building card. A model appears in Workspace.ActiveBuildings, IsOccupied becomes true, menu closes, and HUD gold/count update. Unaffordable cards are disabled. The list scrolls on short screens; × closes it. Enemy/occupied pads and server refusals show notifications.

The original camera/spawn were unchanged; walk to the arena. Optional temporary **Client Command Bar** overview:

~~~lua
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.lookAt(Vector3.new(-52, 85, -150), Vector3.new(-52, 2, -210))
~~~

Run individually on **Server**:

~~~lua
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("Start"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("RunBuildingChecks"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("RunChecks"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("Finish"))
print(game.ServerStorage.CastleFightStudioTests.Control:Invoke("Reset"))
~~~

Finish blocks construction, removes buildings, and releases pads. Reset returns Waiting; Start gives 350 again. Stop discards simulation buildings. Published servers do not create Control. Matchmaking/bot were future work at this milestone.

## Server API and security

Runtime owns one BuildingService using existing economy/match, BuildPads, its ActiveBuildings folder, factory, and count callback. Future systems must receive it as a dependency, not create duplicate registries/balances.

- CanBuild(faction, padId, buildingId) → boolean, code.
- TryBuild(faction, padId, buildingId, requestId, expectedMatchId) → boolean, code.
- GetBuilding(padId) → record copy or nil.
- GetBuildingsForFaction(faction) → copies.
- GetBuildingCount(faction, buildingId?, laneId?) → count.
- ClearBuildings() clears only owned records/models/IsOccupied.

Faction is a trusted server dependency. Network payloads cannot supply faction, owner, price, CFrame, Instance, or model path. Successful requestId replay is blocked; changed parameters conflict; stale matchId is rejected. Clients do not retry purchases automatically. Limits: 10 pads, three identical Producers across lanes, one Passive per lane. Transactions are synchronous without yield. Preparation/publication errors precede payment; EconomyService refusal rolls back temporary model/occupancy. Client attributes are never authoritative purchase data.

Codes: E_MATCH_INACTIVE, E_NOT_YOUR_PAD, E_PAD_OCCUPIED, E_INSUFFICIENT_GOLD, E_PRODUCER_LIMIT, E_PASSIVE_LIMIT, E_STALE_MATCH, E_DUPLICATE_REQUEST, E_REQUEST_CONFLICT, E_PAYLOAD, E_RATE_LIMIT, E_MODEL_PREPARATION/E_MODEL_BOUNDS/E_MODEL_PUBLICATION.

## Replacing placeholders

After separate manual import/validation, create ServerStorage.CastleFightBuildingTemplates (Folder). Insert a Model named exactly for BuildingPresentation assetId, e.g. human_barracks or undead_cursed_obelisk. The pipeline downloads nothing and does not call Meshy.

Factory clones without changing templates. Requirements: 1..200 BasePart/MeshPart; no scripts, Humanoid, joints, constraints. Parts become anchored and noncolliding/nontouching; MeshId/textures copy. Proportions remain; downscale if needed to the pad with 0.5-stud margin and height 12. Pivot is base center; local −Z faces the lane. Missing template uses a Parts placeholder; invalid existing template rejects purchase without payment.

## Checks performed on 2026-11-08

MapBuilder.Check before/after: 167 Parts, 20 pads, 156-stud routes; no geometry rebuild. No ActiveBuildings runtime folder in Edit.

64 isolated checks on detached pad copies: phase/ownership/prices/insufficient funds, replay/conflicts, limits, ten buildings, both factions, LaneId/assetId, all eight models (base/pivot/footprint/no collision), payloads, stale MatchId, cleanup/restart, factory failure before payment, and rollback after EconomyService rejection. Active accounts untouched. Earlier 43 economy checks passed.

Actual single-player Play: clicked Human_Upper_03 and bought KnightBarracks for 260, base Y=2.3, Upper, HUD 1/10, menu closed. Client BuildRequest bought ArcherTower; replay/conflict/enemy pad/price injection/12 spam requests were rejected. Exactly one additional object/payment 190; concurrent +6 income accounted separately.

iPhone 16 portrait emulator: menu dimensions and four cards checked; academy button purchased the third building. Pad menu opened with mouse before resizing. Synthetic input did not confirm a normal pad tap; TouchTapInWorld is connected but physical touch remains manual. Not a physical phone test.

Finish removed 3/3 buildings, released 20/20 pads, HUD 0/10/0 gold, and requests got E_MATCH_INACTIVE. No client/server errors; src strict and Rojo build passed. Emulator off, Studio Edit. No two-client test; Undead tested in isolation. Manually check phone taps/scrolling and both factions with two clients.

Further reports: [management](BUILDING_MANAGEMENT.md), [spawning](UNIT_SPAWN_MOVEMENT.md), [combat](COMBAT_TESTING.md). Abilities/bot/monetization were absent at this milestone.

API: [RemoteEvent](https://create.roblox.com/docs/reference/engine/classes/RemoteEvent), [Activated](https://create.roblox.com/docs/reference/engine/classes/GuiButton#Activated), [TouchTapInWorld](https://create.roblox.com/docs/reference/engine/classes/UserInputService#TouchTapInWorld), [Model](https://create.roblox.com/docs/reference/engine/classes/Model).
