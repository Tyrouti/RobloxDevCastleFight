# Castle Fight — master specification

Status: MVP foundation, 2026-11-08, with approved milestone updates through P23 on 2026-11-10. This is the requirements source for later work. Change approved balance only with user permission. Historical geometry and interval values below are explicitly superseded by later milestones.

## Concept and implementation status

1v1 Human vs Undead strategy. Two parallel lanes, Upper and Lower; units cannot switch lanes. Players construct producing/passive buildings, upgrade/sell them, and eventually assist with a sword only in their own territory. One human may eventually face a bot obeying identical economy/limits.

Implemented: Parts map, asset preparation, server economy, four match states, HUD, building purchase/upgrade/sale, six unit types, automated spawning, movement, lane combat, and castle attacks. P23 starts local 1 VS 1 through lobby portals for two players on the current server; Studio diagnostics remain. P22 adds shields, curse, and Necromancer corruption. Sword/bot remain future work. Monetization is cosmetic only. Persistent progression, rankings, and inventories are outside this task.

## Field, economy, limits

- One castle per side, 1500 HP. Arena17B visually represents these as Human/Undead Crystals; HumanCastle/UndeadCastle, CastleTarget, and shared HP pools remain.
- Faction halves use light/dark stone with gradual central transition. Separate square build markers have no road branches. Shared crystal plazas span both lanes; 20 pads alternate inside/outside roads. See [17B](ARENA_17B.md) and later geometry updates below.
- Starting gold 350; income 6/s only InProgress; cap 9999.
- Private faction balances share the same player/future-bot contract. Waiting/Finished: 0. Starting resets to 350, clears receipts/fractional income remainder. Finish zeros both balances. Gold never persists across matches/servers.
- Five pads per lane per side: ten per player, twenty total.
- At most three identical Producers per player across both lanes.
- At most one Passive per lane per side, affecting only that lane.
- At most thirty live units per side, both lanes combined.
- First spawn five seconds after construction. Later attempts use the building interval. At cap, skip without queuing; next attempt follows the interval. Selling stops future spawns, preserving existing units. Upgrade retains first deadline/last-attempt time and applies the new interval without a second timer.
- No kill gold; death coins are cosmetic only.

## Buildings

Purchase, static placement, upgrade, sale, and Producer spawning work. Server checks phase, ownership/occupancy, faction, limits, gold, and for management InstanceId/Revision. Client prices/refunds/levels are rejected. Finish/Reset/new start clear buildings, units, schedules. P22 enables passive shields/curse.

| Faction | ID | Cost | Unit/effect | Interval, s |
|---|---|---:|---|---:|
| Human | KnightBarracks | 260 | Knight | 26 |
| Human | ArcherTower | 190 | Archer | 22 |
| Human | MageAcademy | 250 | Mage | 27 |
| Human | LightSanctuary | 230 | Shield 45 HP | 7 |
| Undead | GiantGraveyard | 260 | Giant | 30 |
| Undead | BoneTower | 190 | SkeletonArcher | 24 |
| Undead | NecromancerCrypt | 250 | Necromancer | 28 |
| Undead | CursedObelisk | 200 | Curse: 6 Magical/s, 5 s, outgoing damage ×0.85 | 8 |

Two levels. Upgrade costs 70% of initial price, nearest integer half up (GameConfig.upgradeGoldRounding=NearestHalfUp). This conventional rule was chosen during prompt 14; separate clarification remains unanswered, although all eight current prices produce integers. L2 NEW units gain HP/base damage ×1.2; production interval ×0.9, minimum 20 s (P21B). Existing units do not improve. LightSanctuary shield ×1.25 =56.25 HP. CursedObelisk periodic damage ×1.25 =7.5 Magical/s. No passive interval reduction is specified/applied.

Sale refunds exactly 60% actually spent, including upgrade, without rounding, capped at gold 9999; UI shows actual credit. KnightBarracks: upgrade 182, total 442, refund 265.2. Selling only InProgress removes the building and frees pad/limits.

## Units

Distances in studs, speed studs/s, cooldown seconds.

| ID | Faction | HP | Damage | Type | Cooldown | Range | Speed |
|---|---|---:|---:|---|---:|---:|---:|
| Knight | Human | 280 | 17 | Physical | 1.5 | 3 | 8 |
| Archer | Human | 100 | 14 | Physical | 1.2 | 18 | 9 |
| Mage | Human | 85 | 22 | Magical | 2 | 16 | 8 |
| Giant | Undead | 255 | 19 | Physical | 1.8 | 3 | 8 |
| SkeletonArcher | Undead | 90 | 15 | Physical | 1.3 | 17 | 9 |
| Necromancer | Undead | 80 | 21 | Magical | 2.1 | 16 | 8 |

## Combat

Spawn at the producer UnitSpawn with bounds-based offset, walk to LaneEntry and remaining faction/lane waypoints. Human moves +X, Undead −X. Copy HP/damage/speed/stats from building-level snapshot at spawn. Anchored, noncolliding parts. States: Moving, Attacking, WaitingAtCastle, Dead. Nearest live enemy in range on the same lane stops movement; losing it resumes the original path. Distance uses private server 3D positions. Central search/attack at most every 0.1 s; UnitConfig cooldown survives target changes. First attack immediately available. GUID breaks ties and orders attacks within a step. Dead releases live capacity immediately, stops attacking, and despawns after 0.6 s. No kill reward.

After the individual final approach, without an in-range enemy unit, attack only the enemy castle. Require bounds-aware physical pedestal gap ≤3.5 studs, vertical overlap, and correct approach side; shared plaza center is not the attack condition. Each castle has one 1500-HP pool across lanes. Melee deals 100%, ranged 65% of upgraded base damage; unit resistances do not apply to castles. Sum castle hits per step. Zero HP finishes with opposing faction winner. Both crystals zero in one damage batch: winner=nil, reason=Draw. Different steps retain the first completed result. Finish clears combat/units/buildings; restart restores HP. Cosmetic projectiles/flashes never control damage. See [combat report](COMBAT_TESTING.md).

Knight incoming Magical ×0.75, Physical ×1; Giant Physical ×0.65, Magical ×1.35; others ×1. Without passives: base damage × attacker level bonus × target incoming multiplier. Do not invent rounding. Units move/fight only on their own lane.

## Sword and match requirements

Future sword: 10 Physical, one hit/1.5 s, max range 7, at most one enemy unit. Player and target both inside player's territory. No attacks on castles/buildings/players, no stun/knockback. Server checks position/range/target/ownership/life/cooldown.

Match requirement: maximum 600 s; timer winner has higher remaining castle HP, equality draws. Destroyed castle loses; both in one combat step draw. Server owns timer/outcome. The full timed MVP is not claimed complete by current foundation reports.

## Open decisions — do not invent balance

- New abilities beyond P22 require separate approval; do not implement unrequested future abilities.
- First P22 passive pulse is one full interval after construction; no-target skips do not queue a pulse.
- HP/damage/shields/intervals retain fractions. Upgrade gold uses the rule above; refunds stay exact. Future money operations need their own rule.
- Original map v1: 200×120, origin=(0,0,-180), Human left/−X, Undead right/+X. TopLane/BottomLane carry Upper/Lower, route 156. X territories Human [−100,−30), Neutral [−30,30], Undead (30,100], Z±60. Historical editor geometry; later changes require route checks and are listed below.
- Building attacks are absent. Basic target/castle rules are defined above; future abilities need approval.
- Destruction coinciding with timer, player departure/death, faction allocation, bot-match startup, and second-player replacement of bot require decisions beyond the explicit P23 local-session rules.
- Bot strategy/decision frequency are unresolved.

These do not block the foundation; dependent mechanics require approval. Future MVP acceptance must cover 1v1/bot, both lanes, limits/income/no kill reward, first spawn, upgrades affecting new units only, sale, resistances, lane-local effects, every sword restriction, timer/draw, and client inability to change gold/damage/outcome. Current foundation checks do not establish a completed full MVP.

## Milestone 19 — 2026-11-10

Arena17B expanded to 200×150 (30000 studs², +25%), local Z±75; roads Z±28.75, full route still 156. Twenty pads/balance preserved. CastleHud reads server HP/MaxHP, floating castle indicators disabled. Earlier sizes describe pre-expansion 17B. [Report](ARENA_19.md).

## P20 correction and P21 approval

Arena 280×150, roads 228, complete routes 234.520584. Crystals X±114, approaches X±110/local Z±4. Units walk from producer SpawnPoint through LaneEntry; damage requires physical approach. HP/damage/speed/economy unchanged. P19 preserved. [P20 report](ARENA_20_CORRECTION.md).

User approved visual P20 as P21 foundation. All 1404 geometry parts preserved. Producer UnitSpawn, nonoverlapping release queue, physical crystal contact, Finish/restart verified. [P21 report](UNIT_21_FINALIZATION.md).

## P21B — intervals and shared combat

User approved Producer intervals 22/24/26/27/28/30 seconds. First release remains five seconds; L2 minimum interval 20. Lane-width distribution and ally avoidance use the common server Step and real bounds. CombatService, HP/damage/speed/prices, geometry, and waypoint routes preserved. [Report](UNIT_21B_SPAWN_COMBAT.md).

## P22 — temporary effects

LightSanctuary every 7 s chooses the most advanced live ally on its lane without a shield: 45 HP (L2 56.25), up to 10 s, nonstacking, absorbs post-resistance damage. CursedObelisk every 8 s chooses the most advanced live enemy on its lane: 5 s, 6 Magical/s (L2 7.5), all outgoing damage ×0.85. Necromancer successful living-unit hit adds 2 Magical/s for 3 s; primary damage unchanged. Resistance/shield affect periodic damage; source curse also affects its periodic damage. No corruption on crystals; old shared HP/contact attack preserved.

One effect of each type per target. Reapplying Curse/DamageOverTime refreshes duration without stacking or resetting next tick; ticks every second, including expiry boundary. Sale stops future pulses, existing effects expire naturally. Death/removal/Finish clear effects. Central EffectService updates before CombatService; client VFX never affects damage. Existing corruption survives source death. Necromancer level does not increase the extra six damage; only old primary-damage upgrade applies. [Report](ABILITIES_22.md).

## P23 — lobby and local mode selection

Separate Lobby23 courtyard origin=(0,8,420), permanent neutral SpawnLocation, four physical portals. Arena initial spawn disabled only in separate P23. 1 VS BOT, 2 VS 2, and Arena show COMING SOON and cannot start. 1 VS 1 is a two-player FIFO queue on the current server using one existing arena; no cross-server matchmaking/TeleportService. Solo players honestly wait; extras stay in lobby. No bot.

Server checks live character, portal proximity, allowed mode, phase, duplicate requests. First confirmed player Human, second Undead. Lobby/Transition/Match are LobbyService location states, separate from MatchService Waiting/Starting/InProgress/Finished. Existing rules finish combat; participants return to lobby and battle HUD hides. Participant departure cancels through Finish(nil,ParticipantLeft), no winner/rewards; competitive forfeit remains TODO. Late joins cannot enter active matches.

Prices, P21B production, HP/damage, P22 abilities, battle geometry preserved. Lobby uses temporary Roblox Parts architecture, not production 3D assets. [Report](LOBBY_23.md).
