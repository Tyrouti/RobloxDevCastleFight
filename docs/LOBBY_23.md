# P23 — Castle Fight lobby

Historical report,2026-11-10,based on P22. Separate approved result CastleFight_Arena17B_P23_Lobby.rbxl (254441 bytes). Unpublished; artistic acceptance remains the user's decision. The English release preserves this binary and supplies localized disk sources; see ENGLISH_RELEASE.md for current validation rather than treating historical PASS as new evidence.

## Location

Separate finite Workspace.Lobby23 courtyard,origin(0,8,420),base208×184,plaza196×172. 1009 anchored BaseParts,four portals/four ProximityPrompts. Central spawn circle/magic fountain,four towers,fortress wall,colonnades,entrance arch,gardens,benches,lanterns,crystals,rock backdrop. Human left,Undead right,neutral center. Prepared Parts geometry,not new production 3D assets.

Only new initial SpawnLocation:LobbySpawn. Original top-level spawn disabled,prior Enabled saved in Lobby23PreviouslyEnabled. Server controls CharacterAdded/RespawnLocation. Ordinary start in lobby with Custom camera/character input. CastleHud/EconomyHud/BuildMenu enable only in Match.

Arena not rebuilt:1404Parts,20BuildPads,roads228,four directed routes234.520584. Geometry2165PASS. No new battle map.

## Modes and interaction

| Portal | Actual behavior |
|---|---|
| 1 VS BOT |COMING SOON,unavailable,no bot/fake match|
| 1 VS 1 |Real FIFO two-player current-server queue,existing MatchService|
| 2 VS 2 |Future/unavailable|
| Arena |Future/unavailable|

First participant Human,second Undead. One arena/server. Third stays lobby/Busy when choosing occupied mode. No cross-server search/TeleportService.

Prompt:E/ButtonX,hold0.25s,range10. Touch SELECT button uses same native prompt InputHoldBegin/End. Server rechecks live character,full3D distance,allowed mode,phase,cooldown. Client cannot fake a pair confirmation. Duplicate transition blocked,queue cancellable,fade during transition.

Lobby/Transition/Match are player-location states;Waiting/Starting/InProgress/Finished remain MatchService. Finish returns participants/clears buildings/units/effects. Departure cancels with ParticipantLeft,no winner/reward. Competitive departure penalties remain TODO/not approved.

## Files and preservation

Created LobbyConfig,LobbyBuilder/LobbyArtPass,LobbyQueue/LobbyPolicy/LobbyService/LobbyTests,LobbyController/LobbyUI,arena-p23.project.json/report,assets/maps/lobby23/*.jpg,assets/tests/p23/evidence.json. Changed Runtime,Main.client,ArenaCamera,MASTER_SPEC,ARCHITECTURE. src hash comparison to backup found only those three existing runtime files changed. CombatService/CombatMath/UnitService/BuildingService/MatchService/EffectService/EconomyService/old configs unchanged. New modules strict/explicit dependencies,no scripts embedded in scenery.

## Historical checks actually executed

| Check | Result |
|---|---|
| Luau LSP Roblox definitions/sourcemap |PASS,no errors|
| Rojo default |PASS,build/Arena23-runtime.rbxlx|
| Rojo P23 |PASS,build/Arena23-code.rbxlx|
| verify |PASS,58Luau files/no BOM|
| LobbyTests |43PASS:queue,policy,native prompts,geometry,safe floor|
| Economy/Building/Management/Unit/Combat |43/64/47/73/52PASS|
| P22 Effects |60PASS,60units/180effects,four castle outcomes|
| P21 regression |60cases/46196assertions,no failures,60unit stress|
| P21B intervals |89assertionsPASS|
| P21B formations |6scenariosPASS,overlap/outside/speedErrors0|
| P20 geometry |2165PASS,20pads/continuous route support|

Distinct suites/scenarios/assertions are not combined into an artificial total. Machine evidence assets/tests/p23/evidence.json.

### Actual historical Playtest

Single Play and local server with three real Studio clients. Normal WalkSpeed16 spawn/walking to portals verified. Native E at bot portal returned Unavailable,MatchWaiting/matchId0. Two native prompts formed pair/InProgress/opposite factions;all three battle HUDs visible,LobbyUI hidden. Late third spawned lobby/battleHUDhidden/Busy confirmed. Manual Finish returned participants/reset third Busy/cleared queue/buildings/units. Re-pair started next match;Kick reached PlayerRemoving/ParticipantLeft,remaining Lobby/Idle/queueempty.

Existing CastleHudDemo destroyed Undead naturally:136hits/HP0/Human/CastleDestroyed. Remaining clients returned lobby,buildings/units/effects/schedules0,effectErrors0. Mobile screen button actually clicked in emulator and entered real queue. iPhone16portrait393×852/landscape852×393,iPadA161180×820 inspected after final adaptation;touch controls clear. Emulation only,not physical devices. Exactly one Lobby23 Model;Builder blocks duplicate,Runtime does not rebuild on Start.

## Screenshots

- [Top](../assets/maps/lobby23/01-top.jpg)
- [Player spawn](../assets/maps/lobby23/02-spawn.jpg)
- [Bot portal](../assets/maps/lobby23/03-bot-portal.jpg)
- [Duel portal](../assets/maps/lobby23/04-duel-portal.jpg)
- [Overview](../assets/maps/lobby23/05-overview.jpg)
- [Phone portrait](../assets/maps/lobby23/06-phone-portrait.jpg),[landscape](../assets/maps/lobby23/07-phone-landscape.jpg),[tablet](../assets/maps/lobby23/08-tablet.jpg).

These retain historical Russian text as visual evidence;localization does not repaint screenshots.

## Backup,save,limitations

build/backups/p23-before contains full P22/src/tools/docs/profiles/original hashes. Root P22 not overwritten. Full P23 saved through Studio Edit;code builds do not replace geometry-containing place. Historical active Rojo was arena-p20/34874,Workspace excluded;P23/34878 prepared,not connected then,no second sync server.

Open P23 and Play;for real1v1 use local server/two clients,each approach/select portal. Unavailable modes never start. Save further approved changes deliberately in correct version;no publication. English release uses separate localized derivative,not overwrite of approved original.

No cross-server matchmaking/AI;one arena/server. No long low-end physical-phone memory/FPS/high-latency profile. Existing asset203785492 warning and two user Hello world scripts preserved. Assess art through screenshots/Studio;technical PASS is not visual approval. No next gameplay stage begun.
