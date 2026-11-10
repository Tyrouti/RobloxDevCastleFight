-- ROJO_SYNC_TEST_002
-- ROJO_SYNC_TEST_001
--!strict
local GameConfig = {
 factions = table.freeze({ "Human", "Undead" }),
 lanes = table.freeze({ "Upper", "Lower" }),
 castleHealth = 1500,
 startingGold = 350,
 goldPerSecond = 6,
 maxGold = 9999,
 goldPerUnitKill = 0,
 deathCoinsAreCurrency = false,
 buildingSlotsPerLane = 5,
 buildingSlotsPerPlayer = 10,
 maxSameProducerPerPlayer = 3,
 maxPassivePerLanePerPlayer = 1,
 maxLivingUnitsPerSide = 30,
 firstSpawnDelaySeconds = 5,
 minimumProductionIntervalSeconds = 20,
 maxBuildingLevel = 2,
 upgradeCostFraction = 0.7,
 upgradeGoldRounding = "NearestHalfUp", -- Whole-gold upgrade costs; refunds remain exact.
 levelTwoUnitHealthMultiplier = 1.2,
 levelTwoUnitDamageMultiplier = 1.2,
 levelTwoSpawnIntervalMultiplier = 0.9,
 levelTwoPassiveStrengthMultiplier = 1.25,
 sellRefundFraction = 0.6,
 matchDurationSeconds = 600,
 maxHumanPlayers = 2,
 soloBotSupported = true,
 cosmeticsOnlyMonetization = true,
 -- Rounding, bot strategy and timing edge cases: see MASTER_SPEC open decisions.
}
return table.freeze(GameConfig)
