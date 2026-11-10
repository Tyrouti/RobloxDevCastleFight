--!strict
-- Deterministic clock, real services/models, off-tree cloned pads. Never advances the real match.
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.GameConfig)
local Definitions=require(Shared.Config.UnitConfig)
local Visual=require(Shared.Config.UnitPresentation)
local Economy=require(script.Parent.EconomyService)
local Match=require(script.Parent.MatchService)
local Buildings=require(script.Parent.BuildingService)
local BuildingModels=require(script.Parent.BuildingModels)
local UnitService=require(script.Parent.UnitService)
local UnitModels=require(script.Parent.UnitModels)
local LaneRoutes=require(script.Parent.LaneRoutes)
local Demo=require(script.Parent.UnitDemo)
local Tests={}
function Tests.Run(): {passed: number,names: {string}}
	assert(game:GetService("RunService"):IsStudio(),"E_STUDIO_ONLY")
	local names: {string}={}
	local function check(name: string,result: boolean): () assert(result,"FAIL: "..name); table.insert(names,name) end
	local function near(a: number,b: number): boolean return math.abs(a-b)<.01 end
	local pads=workspace.Map.BuildPads:Clone(); for _,pad in pads:GetChildren() do pad:SetAttribute("IsOccupied",false) end
	local active=Instance.new("Folder"); active:SetAttribute("SystemOwner","CastleFightBuildings")
	local soldiers=Instance.new("Folder"); soldiers:SetAttribute("SystemOwner","CastleFightUnits")
	local economy=Economy.new(Config,function(_: Economy.Faction,_: number): () end)
	local buildings: Buildings.Service?=nil; local units: UnitService.Service?=nil
	local match=Match.new(economy,function(status: Match.Status,_: number): ()
		if status~="InProgress" then if units then units.ClearUnits() end; if buildings then buildings.ClearBuildings() end end
	end)
	local army: UnitService.Service
	local build=Buildings.new(pads,active,economy,match,BuildingModels.Create,function(): () if units then units.SyncBuildings() end end); buildings=build
	local now=0
	army=UnitService.new(pads,soldiers,LaneRoutes.new(workspace.Map),build,match,UnitModels.Create,function(): number return now end); units=army
	local function tick(dt: number): () now+=dt; match.Step(dt); army.Step(dt) end
	local function sourceCount(id: string): number local n=0; for _,u in army.GetUnits() do if u.sourceBuildingId==id then n+=1 end end; return n end
	local function unitFrom(id: string): UnitService.Data for _,u in army.GetUnits() do if u.sourceBuildingId==id then return u end end; error("Missing unit from "..id) end
	local function details(faction: Types.FactionId,pad: string): Buildings.Details local d=build.GetBuildingDetails(faction,pad); assert(d); return d end
	local function fund(faction: Types.FactionId,id: string): () assert(economy.AddGold(faction,9000,id,match.GetMatchId())) end
	tick(10); check("waiting has no units or schedules",army.GetDiagnostics().units==0 and army.GetDiagnostics().schedules==0)
	match.Start(); check("demo uses real building purchases",Demo.Create(build,economy,match).built==12)
	check("twelve producer schedules",army.GetDiagnostics().schedules==12 and build.GetBuildingCount("Human")==6 and build.GetBuildingCount("Undead")==6)
	tick(4.99); check("no spawn before five seconds",army.GetDiagnostics().units==0)
	tick(.01); check("first spawn both factions both lanes",army.GetCount("Human")==6 and army.GetCount("Undead")==6)
	local combinations: {[string]:boolean}={}
	for _,unit in army.GetUnits() do
		combinations[unit.unitId..unit.laneId]=true
		check("base stats snapshot "..unit.unitId..unit.laneId,unit.hp==Definitions[unit.unitId].health and unit.speed==Definitions[unit.unitId].speedStudsPerSecond)
		check("attributes and source "..unit.unitId..unit.laneId,unit.model:GetAttribute("HP")==unit.hp and unit.model:GetAttribute("UnitId")==unit.unitId and unit.model:GetAttribute("SourceBuildingId")==unit.sourceBuildingId)
	end
	for id in Visual.entries do check("type on both lanes "..id,combinations[id.."Upper"]==true and combinations[id.."Lower"]==true) end
	local knight=details("Human","Human_Upper_01"); local giant=details("Undead","Undead_Upper_01"); local archer=details("Human","Human_Upper_02")
	local humanBefore=unitFrom(knight.instanceId); local undeadBefore=unitFrom(giant.instanceId); local oldArcher=unitFrom(archer.instanceId)
	tick(1)
	local humanAfter=unitFrom(knight.instanceId); local undeadAfter=unitFrom(giant.instanceId)
	check("Human walks producer approach at configured speed",near((humanAfter.position-humanBefore.position).Magnitude,8))
	check("Undead walks producer approach at configured speed",near((undeadAfter.position-undeadBefore.position).Magnitude,8))
	check("both factions approach their lane without X teleport",humanAfter.position.X==humanBefore.position.X and undeadAfter.position.X==undeadBefore.position.X and humanAfter.position.Z>humanBefore.position.Z and undeadAfter.position.Z>undeadBefore.position.Z)
	fund("Human","tests-human"); fund("Undead","tests-undead")
	assert(build.TryBuild("Human","Human_Upper_04","LightSanctuary","passive-human",match.GetMatchId()))
	assert(build.TryBuild("Undead","Undead_Upper_04","CursedObelisk","passive-undead",match.GetMatchId()))
	check("passive buildings have no schedules",army.GetDiagnostics().schedules==12)
	assert(build.TrySell("Human",knight.padId,knight.instanceId,knight.revision,"sell-producer",match.GetMatchId()))
	check("sale immediately removes one schedule",army.GetDiagnostics().schedules==11 and sourceCount(knight.instanceId)==1)
	assert(build.TryUpgrade("Human",archer.padId,archer.instanceId,archer.revision,"upgrade-producer",match.GetMatchId()))
	check("upgrade does not duplicate schedule",army.GetDiagnostics().schedules==11)
	tick(18.9); check("upgraded interval not early",sourceCount(archer.instanceId)==1)
	tick(.1); check("upgraded interval is 20 preserving elapsed",sourceCount(archer.instanceId)==2)
	local upgradedUnit: UnitService.Data?=nil
	for _,u in army.GetUnits() do if u.sourceBuildingId==archer.instanceId and u.sourceLevel==2 then upgradedUnit=u end end
	assert(upgradedUnit)
	check("new unit gets upgraded stats",upgradedUnit.maxHP==120 and near(upgradedUnit.stats.damage,16.8))
	local stillOld=army.GetUnit(oldArcher.instanceId); assert(stillOld)
	check("existing unit unchanged",oldArcher.maxHP==100 and oldArcher.stats.damage==14 and stillOld.maxHP==100)
	check("no spawn after sold building",sourceCount(knight.instanceId)==1)
	for _=1,40 do tick(22) end
	check("sixty units faction limits",army.GetCount("Human")==30 and army.GetCount("Undead")==30 and #soldiers:GetChildren()==60)
	check("limit slots skipped without backlog",army.GetDiagnostics().skippedAtLimit>0 and army.GetDiagnostics().perUnitThreads==0)
	local waiting=true; local safe=true
	for _,u in army.GetUnits() do
		waiting=waiting and (u.state=="WaitingAtCastle" or u.state=="Moving") and (if u.laneId=="Upper" then u.position.Z< -180 else u.position.Z> -180)
		for _,p in u.model:GetDescendants() do if p:IsA("BasePart") then safe=safe and p.Anchored and not p.CanCollide and not p.CanTouch end end
	end
	check("all units stay on own lane and safely queue",waiting)
	check("sixty units cannot physically push",safe)
	local sample=army.GetUnits()[1]; sample.model:PivotTo(CFrame.new(999,999,999)); local corrections=army.GetDiagnostics().movementCorrections
	tick(0); check("server corrects unexpected teleport",(sample.model:GetPivot().Position-sample.position).Magnitude<.01 and army.GetDiagnostics().movementCorrections==corrections+1)
	local removed: UnitService.Data?=nil; for _,u in army.GetUnits() do if u.faction=="Human" then removed=u; break end end; assert(removed)
	assert(army.RemoveUnit(removed.instanceId)); tick(0)
	check("free slot does not release queued burst",army.GetCount("Human")==29)
	tick(30); check("next scheduled attempt fills slot",army.GetCount("Human")==30)
	check("remove unknown is harmless",not army.RemoveUnit("missing") and army.GetCount("Human")==30)
	match.Finish(); check("finish cleans units and all schedules",#soldiers:GetChildren()==0 and army.GetDiagnostics().units==0 and army.GetDiagnostics().schedules==0)
	tick(100); check("finished has no late spawns",army.GetDiagnostics().units==0)
	match.Start(); assert(Demo.Create(build,economy,match).success); tick(4.99)
	check("restart creates no old timers",army.GetDiagnostics().units==0 and army.GetDiagnostics().schedules==12)
	tick(.01); check("restart first wave exactly twelve",army.GetDiagnostics().units==12)
	match.Finish(); match.Start(); fund("Human","first-upgrade-fund")
	assert(build.TryBuild("Human","Human_Upper_01","KnightBarracks","first-upgrade-build",match.GetMatchId()))
	tick(4); local first=details("Human","Human_Upper_01")
	assert(build.TryUpgrade("Human",first.padId,first.instanceId,first.revision,"before-first-spawn",match.GetMatchId()))
	tick(.99); check("upgrade preserves first five seconds",army.GetDiagnostics().units==0)
	tick(.01); local firstUnit=army.GetUnits()[1]
	check("first upgraded unit and single timer",firstUnit.maxHP==336 and army.GetDiagnostics().units==1 and army.GetDiagnostics().schedules==1)
	match.Finish()
	for id,info in Visual.entries do
		local model=UnitModels.Create(id :: Types.UnitId); local cf,size=model:GetBoundingBox()
		check("placeholder height and feet "..id,near(size.Y,info.height) and near(cf.Y-size.Y/2,0) and model:FindFirstChildOfClass("Humanoid")==nil)
		check("asset mapping "..id,model:GetAttribute("AssetId")==info.assetId); model:Destroy()
	end
	check("models and spawners have no errors",army.GetDiagnostics().modelErrors==0)
	army.ClearUnits(); pads:Destroy(); active:Destroy(); soldiers:Destroy()
	return {passed=#names,names=names}
end
return table.freeze(Tests)
