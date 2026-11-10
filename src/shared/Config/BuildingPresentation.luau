--!strict
local Types=require(script.Parent.Parent.Types)
export type Entry={assetId: string, title: string, symbol: string, style: string}
local entries: {[Types.BuildingId]:Entry}={
	KnightBarracks={assetId="human_barracks",title="Knight Barracks",symbol="K",style="Barracks"},
	ArcherTower={assetId="human_archer_tower",title="Archer Tower",symbol="A",style="Tower"},
	MageAcademy={assetId="human_mage_academy",title="Mage Academy",symbol="M",style="Academy"},
	LightSanctuary={assetId="human_light_sanctuary",title="Light Sanctuary",symbol="L",style="Sanctuary"},
	GiantGraveyard={assetId="undead_giant_graveyard",title="Giant Graveyard",symbol="G",style="Graveyard"},
	BoneTower={assetId="undead_bone_tower",title="Bone Tower",symbol="B",style="BoneTower"},
	NecromancerCrypt={assetId="undead_necromancer_crypt",title="Necromancer Crypt",symbol="N",style="Crypt"},
	CursedObelisk={assetId="undead_cursed_obelisk",title="Cursed Obelisk",symbol="C",style="Obelisk"},
}
for _,entry in entries do table.freeze(entry) end
return table.freeze({
	entries=table.freeze(entries),
	order=table.freeze({
		Human=table.freeze({"KnightBarracks","ArcherTower","MageAcademy","LightSanctuary"}),
		Undead=table.freeze({"GiantGraveyard","BoneTower","NecromancerCrypt","CursedObelisk"}),
	}),
	maxHeightStuds=12, padMarginStuds=.5,
})
