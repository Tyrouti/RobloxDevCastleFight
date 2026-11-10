--!strict
-- Real services/models; synthetic off-tree starting positions isolate precise combat cases.
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.GameConfig)
local CombatConfig=require(Shared.Config.CombatConfig)
local Math=require(Shared.CombatMath)
local Economy=require(script.Parent.EconomyService)
local Match=require(script.Parent.MatchService)
local Buildings=require(script.Parent.BuildingService)
local BuildingModels=require(script.Parent.BuildingModels)
local Units=require(script.Parent.UnitService)
local UnitModels=require(script.Parent.UnitModels)
local Routes=require(script.Parent.LaneRoutes)
local Combat=require(script.Parent.CombatService)
local Demo=require(script.Parent.UnitDemo)
local Contact=require(script.Parent.CrystalContact)
type Fixture={army: Units.Service,build: Buildings.Service,match: Match.Match,economy: Economy.Economy,battle: Combat.Service,
	events: {Combat.Effect},Tick: (number) -> (),TickWithoutCombat: (number) -> (),Build: (Types.FactionId,string,Types.BuildingId,boolean?) -> (),
	Wave: () -> (),Get: (Types.FactionId,Types.UnitId?) -> Units.Data,Destroy: () -> ()}
local function gate(faction: string,lane: string): Vector3
	local castle=workspace.Map.Castles[faction.."Castle"] :: Model
	local p=castle:FindFirstChild(lane.."CastleTarget") :: BasePart
	local zone=Contact.Read(castle);local d=Vector3.new(if faction=="Human" then 1 else -1,0,if lane=="Upper" then -1 else 1).Unit
	return Vector3.new(zone.center.X,p.Position.Y,zone.center.Z)+d*(zone.radius+3.5)
end
local function position(x: number,lane: string): Vector3 local p=gate("Human",lane); return Vector3.new(x,p.Y,p.Z) end
local function fixture(starts: {[string]:Vector3}?): Fixture
	local pads=workspace.Map.BuildPads:Clone(); for _,pad in pads:GetChildren() do pad:SetAttribute("IsOccupied",false) end
	local buildingsFolder=Instance.new("Folder"); buildingsFolder:SetAttribute("SystemOwner","CastleFightBuildings")
	local unitFolder=Instance.new("Folder"); unitFolder:SetAttribute("SystemOwner","CastleFightUnits")
	local economy=Economy.new(Config,function(_: Economy.Faction,_: number): () end)
	local army: Units.Service?=nil; local build: Buildings.Service?=nil; local battle: Combat.Service?=nil
	local match=Match.new(economy,function(status: Match.Status,_: number): ()
		if status~="InProgress" then
			if battle then if status=="Starting" or status=="Waiting" then battle.Reset() else battle.Stop() end end
			if army then army.ClearUnits() end; if build then build.ClearBuildings() end
		end
	end)
	local b=Buildings.new(pads,buildingsFolder,economy,match,BuildingModels.Create,function(): () if army then army.SyncBuildings() end end); build=b
	local now=0; local routes=Routes.new(workspace.Map)
	if starts then
		routes={CreatePath=function(pad: BasePart,lane: Types.LaneId,faction: Types.FactionId): Routes.Path
			local custom=starts[pad.Name]; assert(custom,"E_TEST_START")
			return {start=custom,points={gate(if faction=="Human" then "Undead" else "Human",lane)},direction=Vector3.new(if faction=="Human" then 1 else -1,0,0)}
		end}
	end
	local u=Units.new(pads,unitFolder,routes,b,match,UnitModels.Create,function(): number return now end); army=u
	local events: {Combat.Effect}={}
	local c=Combat.new(workspace.Map,u,match,function(): number return now end,function(e: Combat.Effect): () table.insert(events,e) end,function(_: Types.FactionId,_: number,_: number): () end); battle=c
	match.Start()
	assert(economy.AddGold("Human",9000,"fund-human",match.GetMatchId())); assert(economy.AddGold("Undead",9000,"fund-undead",match.GetMatchId()))
	local number=0
	local f={} :: Fixture; f.army=u; f.build=b; f.match=match; f.economy=economy; f.battle=c; f.events=events
	function f.Tick(dt: number): () now+=dt; match.Step(dt); c.Step(); u.Step(dt) end
	function f.TickWithoutCombat(dt: number): () now+=dt; match.Step(dt); u.Step(dt) end
	function f.Build(faction: Types.FactionId,pad: string,id: Types.BuildingId,upgrade: boolean?): ()
		number+=1; assert(b.TryBuild(faction,pad,id,"build"..number,match.GetMatchId()))
		if upgrade then local d=b.GetBuildingDetails(faction,pad); assert(d); assert(b.TryUpgrade(faction,pad,d.instanceId,d.revision,"upgrade"..number,match.GetMatchId())) end
	end
	function f.Wave(): ()
		f.TickWithoutCombat(Config.firstSpawnDelaySeconds)
		for _,faction in {"Human","Undead"} do for _,r in b.GetBuildingsForFaction(faction :: Types.FactionId) do
			assert(b.TrySell(faction :: Types.FactionId,r.padId,r.instanceId,r.revision,"stop-source:"..r.instanceId,match.GetMatchId()))
		end end
	end
	function f.Get(faction: Types.FactionId,id: Types.UnitId?): Units.Data
		for _,unit in u.GetUnits() do if unit.faction==faction and (not id or unit.unitId==id) then return unit end end; error("Missing test unit")
	end
	function f.Destroy(): () match.Finish(); u.ClearUnits(); b.ClearBuildings(); pads:Destroy(); unitFolder:Destroy(); buildingsFolder:Destroy() end
	return f
end
local Tests={}
function Tests.Run(): {passed: number,names: {string}}
	assert(game:GetService("RunService"):IsStudio(),"E_STUDIO_ONLY")
	local names: {string}={}
	local function check(name: string,result: boolean): () assert(result,"FAIL: "..name); table.insert(names,name) end
	local function near(a: number,b: number): boolean return math.abs(a-b)<1e-6 end
	check("Knight physical against Giant 11.05",near(Math.UnitDamage(17,"Physical","Giant"),11.05))
	check("Mage magical against Giant 29.7",near(Math.UnitDamage(22,"Magical","Giant"),29.7))
	check("Knight magical resistance",near(Math.UnitDamage(22,"Magical","Knight"),16.5))
	check("Knight physical unchanged",Math.UnitDamage(19,"Physical","Knight")==19)
	check("other units full damage",Math.UnitDamage(14,"Physical","SkeletonArcher")==14)
	check("upgraded damage not doubled",near(Math.UnitDamage(20.4,"Physical","Giant"),13.26))
	check("melee castle damage",Math.CastleDamage(17,"Knight")==17 and Math.CastleDamage(19,"Giant")==19)
	check("ranged castle damage",near(Math.CastleDamage(14,"Archer"),9.1) and near(Math.CastleDamage(22,"Mage"),14.3))
	local valid=pcall(function(): number return Math.UnitDamage(0/0,"Physical","Giant") end); check("invalid damage refused",not valid)
	for _,case in {
		{human="KnightBarracks",undead="GiantGraveyard",unit="Knight",damage=11.05},
		{human="ArcherTower",undead="BoneTower",unit="Archer",damage=14},
		{human="MageAcademy",undead="GiantGraveyard",unit="Mage",damage=29.7},
	} do
		local f=fixture({Human_Upper_01=position(0,"Upper"),Undead_Upper_01=position(2.7,"Upper")})
		f.Build("Human","Human_Upper_01",case.human :: Types.BuildingId); f.Build("Undead","Undead_Upper_01",case.undead :: Types.BuildingId); f.Wave()
		local h=f.Get("Human"); local e=f.Get("Undead"); f.Tick(.11)
		local event: Combat.Effect?=nil; for _,hit in f.events do if hit.unitId==case.unit then event=hit end end
		check("duel hit "..case.unit,event~=nil and near(event.damage,case.damage))
		check("attacking stops movement "..case.unit,f.Get("Human").state=="Attacking" and f.Get("Human").position==h.position)
		local hits=f.battle.GetSnapshot().unitHits; f.battle.Step(); f.battle.Step()
		check("same tick no duplicate "..case.unit,f.battle.GetSnapshot().unitHits==hits)
		local gold=f.economy.GetGold("Human"); local loss,died=f.army.ApplyDamage(e.instanceId,e.hp)
		local corpse=f.army.GetUnit(e.instanceId); assert(corpse)
		check("death frees live slot "..case.unit,died and loss>0 and f.army.GetCount("Undead")==0 and corpse.state=="Dead")
		check("no kill gold "..case.unit,f.economy.GetGold("Human")==gold)
		check("dead takes no second damage "..case.unit,f.army.ApplyDamage(e.instanceId,100)==0)
		local hp=f.Get("Human").hp; f.Tick(.11)
		check("dead cannot hit and actor resumes "..case.unit,f.Get("Human").hp==hp and f.Get("Human").state=="Moving")
		f.Tick(CombatConfig.unitCombat.deathVisualSeconds)
		check("corpse removed "..case.unit,f.army.GetUnit(e.instanceId)==nil)
		f.Destroy()
	end
	local lanes=fixture({Human_Upper_01=position(0,"Upper"),Undead_Lower_01=position(2.7,"Upper")})
	lanes.Build("Human","Human_Upper_01","KnightBarracks"); lanes.Build("Undead","Undead_Lower_01","GiantGraveyard"); lanes.Wave(); lanes.Tick(.11)
	check("different lane cannot attack even when close",lanes.battle.GetSnapshot().unitHits==0 and lanes.Get("Human").state=="Moving"); lanes.Destroy()
	local retarget=fixture({Human_Upper_01=position(0,"Upper"),Undead_Upper_01=position(2.7,"Upper"),Undead_Upper_02=position(9,"Upper")})
	retarget.Build("Human","Human_Upper_01","ArcherTower"); retarget.Build("Undead","Undead_Upper_01","GiantGraveyard"); retarget.Build("Undead","Undead_Upper_02","BoneTower"); retarget.Wave(); retarget.Tick(.11)
	local human=retarget.Get("Human"); local giant=retarget.Get("Undead","Giant"); local skeleton=retarget.Get("Undead","SkeletonArcher")
	check("nearest target selected",human.model:GetAttribute("TargetId")==giant.instanceId)
	retarget.army.ApplyDamage(giant.instanceId,giant.maxHP); local count=#retarget.events; retarget.Tick(.11)
	check("dead target replaced",retarget.Get("Human").model:GetAttribute("TargetId")==skeleton.instanceId)
	local humanHits=0; for index=count+1,#retarget.events do if retarget.events[index].unitId=="Archer" then humanHits+=1 end end
	check("retarget preserves cooldown",humanHits==0)
	retarget.Tick(1.21); local replacement=retarget.army.GetUnit(skeleton.instanceId); assert(replacement)
	check("new target receives next attack",replacement.hp<skeleton.hp); retarget.Destroy()
	local escape=fixture({Human_Upper_01=position(2.7,"Upper"),Undead_Upper_01=position(0,"Upper")})
	escape.Build("Human","Human_Upper_01","KnightBarracks"); escape.Build("Undead","Undead_Upper_01","GiantGraveyard"); escape.Wave(); escape.Tick(.11)
	local enemy=escape.Get("Undead"); escape.army.SetCombatState(enemy.instanceId,false,nil); escape.TickWithoutCombat(1); escape.battle.Step()
	check("out of range resumes route",escape.Get("Human").state=="Moving"); escape.Destroy()
	local castle=fixture({Human_Upper_01=gate("Undead","Upper"),Human_Lower_01=gate("Undead","Lower")})
	castle.Build("Human","Human_Upper_01","KnightBarracks"); castle.Build("Human","Human_Lower_01","ArcherTower"); castle.Wave(); castle.Tick(.11); castle.Tick(.11)
	local hp=castle.battle.GetSnapshot()
	check("two lanes share castle health",near(hp.UndeadHP,Config.castleHealth-17-9.1) and hp.castleHits==2)
	check("allied castle never hit",hp.HumanHP==Config.castleHealth)
	check("castle units stay attacking",castle.Get("Human").state=="Attacking")
	for _=1,1600 do if castle.match.GetStatus()=="Finished" then break end; castle.Tick(.11) end
	local result=castle.match.GetResult()
	check("castle destruction finishes existing match",castle.match.GetStatus()=="Finished" and castle.battle.GetSnapshot().UndeadHP==0 and result~=nil and result.winner=="Human" and result.reason=="CastleDestroyed")
	check("finish cleans units and cooldowns",castle.army.GetDiagnostics().units==0 and castle.battle.GetSnapshot().activeCooldowns==0)
	local ended=castle.battle.GetSnapshot().castleHits; castle.Tick(20); check("no attacks after Finish",castle.battle.GetSnapshot().castleHits==ended)
	castle.match.Start(); check("restart resets health and result",castle.battle.GetSnapshot().UndeadHP==Config.castleHealth and castle.match.GetResult()==nil); castle.Destroy()
	local large=fixture(nil); assert(Demo.Create(large.build,large.economy,large.match).success)
	for _=1,40 do large.TickWithoutCombat(22) end
	check("sixty live units ready",large.army.GetCount("Human")==30 and large.army.GetCount("Undead")==30)
	local dead=large.Get("Human"); large.army.ApplyDamage(dead.instanceId,dead.hp)
	check("death immediately releases capped slot",large.army.GetCount("Human")==29)
	large.TickWithoutCombat(22); large.TickWithoutCombat(22)
	check("spawn refills slot without double decrement",large.army.GetCount("Human")==30 and large.army.GetUnit(dead.instanceId)==nil)
	-- A replacement now walks from its producer along the longer P20 route.
	-- Wait for physical arrival rather than assuming the old 156-stud travel time.
	for _=1,12 do
		local arrived=true;for _,unit in large.army.GetUnits() do arrived=arrived and unit.reachedCastle end
		if arrived then break end;large.TickWithoutCombat(5)
	end
	large.battle.Step(); local sixty=large.battle.GetSnapshot()
	check("central tick handles sixty separated units",sixty.unitHits+sixty.castleHits>0 and sixty.unitHits+sixty.castleHits<=60 and sixty.effectErrors==0)
	large.battle.Step();local repeated=large.battle.GetSnapshot();check("sixty units no double hit",repeated.castleHits==sixty.castleHits and repeated.unitHits==sixty.unitHits)
	large.match.Finish(); check("sixty unit cleanup",large.army.GetDiagnostics().units==0 and large.battle.GetSnapshot().activeCooldowns==0); large.Destroy()
	return {passed=#names,names=names}
end
return table.freeze(Tests)
