# Basic combat — stage 16

Historical report. Later P21 contact rules and P22 Draw supersede the original castle approach/double-destruction behavior below.

Sync disk code through Rojo in the main place. Map must contain two lanes, CastleTarget, twenty pads; tools do not rebuild it. Play, then **Server Command Bar**:

~~~lua
local control = game.ServerStorage.CastleFightStudioTests.Control
print(control:Invoke("RunCombatChecks"))
print(control:Invoke("StartUnitDemo"))
print(control:Invoke("CombatSnapshot"))
print(control:Invoke("UnitSnapshot"))
print(control:Invoke("Finish")) -- stop and clear buildings/armies
print(control:Invoke("StartUnitDemo")) -- restart
~~~

StartUnitDemo reuses the existing match and real purchases of twelve Producers; both factions spawn on both lanes after five seconds. Studio camera shows arena. This server-only diagnostic grants no enemy-building privilege to players.

## Implementation

Existing Heartbeat invokes CombatService before UnitService movement. Searches/attacks at most 10/s; cooldown copied from UnitConfig at spawn, may wait up to one search step, never bursts catch-up. First attack immediate; changing target preserves cooldown.

Nearest live enemy on same lane within range uses private 3D positions. Unit priority, then enemy castle after route end. GUID breaks equal-distance ties/orders attacks; units killed earlier in a step cannot attack. CombatService changes movement state, not a second movement system.

CombatMath applies target resistance to upgraded attacker damage. Castle melee 100%, ranged 65%, no unit resistance. Each faction has one 1500-HP pool across lanes; sum hits per step, clamp at zero. CastleDestroyed finishes with opposing winner. Original simultaneous result was SimultaneousCastleDestructionUnresolved; **P22 now uses winner=nil/reason=Draw**. This stage did not implement the 600-second timer.

Dead immediately leaves targets/live cap, stops, despawns after 0.6 s via common update. No kill gold. Finish clears armies/buildings/cooldowns; restart restores HP. CastleFightState.Castles.Human/Undead exposes HP/MaxHP; Winner/FinishReason on state. Effect remote sends server→client only. Projectiles/flashes/fades/bars are cosmetic; projectile contact never deals damage.

## Checks actually performed at stage 16

52 new real-service checks plus prior economy43/building64/management47/unit73 (227): three enemy pairs, resistances, nearest/changed targets, cooldown, lane separation, death/cap release/despawn, shared HP, Finish/cleanup/restart, sixty models in one step. Isolated fixtures used controlled routes, not primary map. Sixty-unit functionality is not a weak-phone performance benchmark.

Normal StartUnitDemo Play showed combat/HP loss/deaths: 227 hits, 20 deaths, effectErrors=0. Client FireServer with arbitrary damage did not change HP. Two castle HP bars appeared correctly after late detail replication.

Separate normal Play: client BuildRequest bought ArcherTower at Human_Upper_01/Lower_01, no gold/HP edits or enemies. 122 hits gave UndeadHP=389.8 (1500−122×9.1), 165 hits gave zero; Human1500. Finished/Human/CastleDestroyed; units/buildings empty, cooldown0/effectErrors0. Restart demo:120 hits/8 deaths, two castle bars/sixteen unit bars; Finish cleared again. No client/server errors. Edit MapBuilder.Check:167 Parts/20 pads/four156 routes. All src strict, Rojo build/Combat.rbxlx, verify35 files passed. Main disk place untouched.

## Manual acceptance

Check six silhouettes/projectiles/HP bars from game camera. After Finish, Start and build friendly ArcherTowers on both lanes; one Archer deals14×0.65=9.1 per castle hit. At zero expect Finished/Human/CastleDestroyed and empty runtime containers; Human1500 without enemies. Inspect Output, repeated demo, late second client, latency/StreamingEnabled/mobile performance. Slow frames do not catch up attacks. At this stage no physical collisions, rig/animation, passives, sword, bot, kill rewards. Original Meshy/map unchanged.
