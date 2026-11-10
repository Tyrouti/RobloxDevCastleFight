# Castle Fight

Castle Fight is a Roblox strategy prototype: **Human vs Undead**, two independent lanes, automated armies, and server-controlled construction and combat.

Current approved release: **CastleFight_Arena17B_P23_Lobby.rbxl**. P21B and P22 are preserved milestones. Never overwrite original place files with a Rojo build. See [specification](docs/MASTER_SPEC.md), [architecture](docs/ARCHITECTURE.md), and [developer rules](AGENTS.md).

## Features and development status

- Castle courtyard lobby, four portals, and a local two-player FIFO queue for 1 VS 1.
- Two factions, two lanes, 20 build pads, eight buildings, and six unit types.
- Authoritative gold, construction, upgrades, refunds, spawning, movement, combat, crystal health, and completion.
- P22 shields, curses, Necromancer damage over time, client effects, and responsive HUD.
- Asset manifests, approved concept references, model inspection, and Studio diagnostics.

This is an MVP foundation/prototype. 1 VS BOT, 2 VS 2, and Arena are unavailable placeholders. No AI bot, cross-server matchmaking, persistent progression, inventory, or ranking system exists. The sword is a future task. Cosmetic-only monetization is a design constraint, not an implemented purchase system.

## Technology stack

Roblox Studio, strict typed Luau ModuleScripts, Rojo 7, Node.js built-in tests, and PowerShell. Optional asset workflows use GLB/FBX and the Universal Asset Pipeline. No paid generation is required to run the project.

## Installation and Studio setup

1. Clone this private repository with an authorized GitHub account.
2. Install Roblox Studio, Node.js, and [Rojo 7 CLI and plugin](https://rojo.space/docs/v7/getting-started/installation/). Keep compatible CLI/plugin versions. Install luau-lsp separately for static analysis; tool binaries are excluded from Git.
3. Open a **copy** of approved P23 in Studio. Preserve the original and prior milestones.
4. Sync the English sources as described below. Original binary snapshots retain historical embedded scripts and text.
5. Keep API Services/DataStores disabled. Do not publish during setup.

## Rojo setup

Run from the project root:

~~~powershell
rojo serve arena-p23.project.json
~~~

Connect the Studio plugin to localhost:34878. This profile allows local place ID 0; verify the target before connecting. For a cloud place, deliberately review servePlaceIds. The foundation default.project.json uses port 34872 and place ID 101102700433907; it is not the P23 profile.

Review proposed changes. Runtime maps to ReplicatedStorage.CastleFightShared, ServerScriptService.CastleFightServer, and StarterPlayer.StarterPlayerScripts.CastleFightClient; P23 also maps editor tools under ServerStorage. Workspace, Terrain, Lighting, and existing assets stay outside sync. Unknown-instance preservation does not protect matching names from updates. Stop on unintended geometry or unrelated script changes.

Edit sources on disk. Do not run a second script sync on the same modules. A profile is not an active connection. Rojo code builds do not contain the approved arena/lobby geometry.

## Testing

~~~powershell
powershell -NoProfile -File tools/verify.ps1
node --test tools/asset-pipeline.test.mjs tools/universal-assets.test.mjs
node tools/asset-pipeline.mjs validate
rojo build default.project.json --output build/English-runtime.rbxlx
rojo build arena-p23.project.json --output build/English-p23-code.rbxlx
rojo sourcemap arena-p23.project.json --output build/english.sourcemap.json
luau-lsp analyze --platform=roblox --definitions=@roblox=.tools/asset-validation/globalTypes.d.luau --sourcemap=build/english.sourcemap.json src
~~~

Create build/ first if needed. The definitions path is a local prerequisite, not a bundled dependency. verify.ps1 checks paths, strict configuration headers, frozen configs, and encoding; it does not execute gameplay.

In a disposable Studio P23 copy, sync English sources and start a local server with two clients. Approach the 1 VS 1 portal with each, join, verify factions and match HUD, then finish and check lobby return/cleanup. A third client stays in the lobby. Unavailable portals must not start a match. Check HUD/menu readability on desktop and phone portrait/landscape. Studio server checks use ServerStorage.CastleFightStudioTests.Control; see [P23 testing](docs/LOBBY_23.md) and individual reports.

Historical PASS results describe earlier sessions, not a fresh localization test. See [release report](docs/ENGLISH_RELEASE.md) for this branch's actual checks.

## Project structure

| Path | Purpose |
|---|---|
| src/shared/Config | Balance and presentation |
| src/shared | Shared types and combat math |
| src/server | Authoritative services, runtime, Studio tests |
| src/client | HUD, input, rendering, lobby, cosmetic effects |
| tools | Offline asset utilities, tests, editor tools |
| docs | Specification, architecture, manifests, reports |
| assets/concepts | Original concepts and selections |
| assets/models | Model sources, provenance, reviews, inspections |
| assets/maps, assets/tests | Historical visual and machine-readable evidence |
| *.project.json | Rojo code/tools profiles |
| *.rbxl | Preserved full-place milestones; P23 is current |

## Known limitations and asset policy

One battle arena per server, local queue only. Physical-device, long-session, and high-latency profiling remain incomplete. Historical screenshots and binary milestones can contain Russian text and remain preserved evidence. Sync English sources into a disposable P23 copy for a localized run. Model generation does not imply artistic approval; read model reviews. Asset warning 203785492 and unrelated user scripts are documented in the P23 report.

Build output, local backups, tool executables, locks, credentials, logs, and recovery files are excluded. Original concepts/models and approved P23 are retained. Current asset sizes do not require Git LFS. Do not commit credentials or signed download URLs. No generation, Roblox upload, or experience publication is part of this release.
