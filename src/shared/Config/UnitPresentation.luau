--!strict
local Types=require(script.Parent.Parent.Types)
export type Entry={assetId: string,height: number}
local entries: {[Types.UnitId]:Entry}={
	Knight={assetId="human_knight",height=5}, Archer={assetId="human_archer",height=5}, Mage={assetId="human_mage",height=5},
	Giant={assetId="undead_giant",height=6.5}, SkeletonArcher={assetId="undead_skeleton_archer",height=5}, Necromancer={assetId="undead_necromancer",height=5},
}
for _,entry in entries do table.freeze(entry) end
return table.freeze({entries=table.freeze(entries),snapshotHz=20,smoothingRate=20,maxTemplateParts=100})
