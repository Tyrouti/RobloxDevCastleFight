--!strict
export type Pose = {position: {number}, rotationDegrees: {number}}
export type Concept = {status: string, variant: string, path: string, sha256: string}
export type Evidence = {triangleCount: number, reportPath: string, sourceSHA256: string, observedMeshIds: {string}}
export type AssetConfig = {
	assetId: string, assetType: string, faction: string, sourceModelPath: string?,
	approvedConcept: Concept?, targetHeightStuds: number?, maxTriangles: number,
	desiredForwardDirection: string, sourceForwardDirection: string?, collisionMode: string,
	requiresRig: boolean, characterCategory: string?, equipmentSlots: {[string]: Pose},
	importStatus: string, validationStatus: string, maxVisualComponents: number,
	plotSizeStuds: {number}?, spawnPoint: {positionNormalized: {number}, rotationDegrees: {number}, provisional: boolean}?,
	geometryEvidence: Evidence?, notes: string?,
}
export type EquipmentConfig = {slot: string, gripName: string, offset: {number}, rotationDegrees: {number}, referenceHeightStuds: number}
export type SourceSnapshot = {part: BasePart, cf: CFrame, size: Vector3, parent: Instance?, anchored: boolean,
	collide: boolean, touch: boolean, query: boolean, meshId: string?, textureId: string?}
export type Report = {[string]: any}
return {}
