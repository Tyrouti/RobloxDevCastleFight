--!strict
-- Editor geometry; not economy or combat balance. World axes: Human -> +X.
local MapConfig = {
	sceneId = "castlefight.map.v1",
	version = 1,
	origin = Vector3.new(0, 0, -180),
	size = Vector3.new(280, 2, 150),
	surfaceY = 2,
	humanFraction = 0.35,
	neutralFraction = 0.30,
	undeadFraction = 0.35,
	-- Inclusive outer edges; x=-30 and x=30 belong to NeutralZone (fail closed).
	humanBoundaryX = -30,
	undeadBoundaryX = 30,
	laneHalfLength = 114,
	routeEndX = 110,
	crystalX = 114,
	crystalApproachZ = 4,
	laneWidth = 12,
	laneSurfaceY = 2.15,
	lanes = table.freeze({
		table.freeze({ id = "Upper", name = "TopLane", z = -20 }),
		table.freeze({ id = "Lower", name = "BottomLane", z = 20 }),
	}),
	padSize = Vector3.new(8, 0.3, 10),
	padSurfaceY = 2.3,
	padZ = 53.75,
	-- Alternating outer/inner courts, with eight studs between neighbouring squares.
	humanPadXs = table.freeze({ -96, -84, -72, -60, -48 }),
	padInnerZ = 5,
	waypointXs = table.freeze({ -110, -96, -60, -30, 0, 30, 60, 96, 110 }),
	depthScale = 1.25,
	crystalPlazaDepth = 60,
	maxParts = 1800,
}
return table.freeze(MapConfig)
