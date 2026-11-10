--!strict
-- Geometry clearance, not unit speed, damage, health or production balance.
return table.freeze({spawnClearance=.35,friendlyGap=.2,bodyGap=.1,crystalContactGap=3.5,epsilon=.03,maxMovementSlice=.75,
 preferredLateralOffset=3,allyLookahead=8,enemyApproachLookahead=20,meleeSlotInset=.08,
 meleeSlotAngles=table.freeze({-50,50,0,-70,70}),meleeYieldAngles=table.freeze({-50,50,-70,70})})
