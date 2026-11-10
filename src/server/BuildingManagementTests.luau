--!strict
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.GameConfig)
local Levels=require(Shared.Config.BuildingLevels)
local Units=require(Shared.Config.UnitConfig)
local Economy=require(script.Parent.EconomyService)
local Match=require(script.Parent.MatchService)
local Buildings=require(script.Parent.BuildingService)
local Models=require(script.Parent.BuildingModels)
local Network=require(script.Parent.BuildingNetwork)
local Tests={}
function Tests.Run(): {passed: number,names: {string}}
	assert(game:GetService("RunService"):IsStudio(),"E_STUDIO_ONLY")
	local pads=workspace.Map.BuildPads:Clone()
	for _,pad in pads:GetChildren() do pad:SetAttribute("IsOccupied",false) end
	local active=Instance.new("Folder"); active:SetAttribute("SystemOwner","CastleFightBuildings")
	local economy=Economy.new(Config,function(_: Economy.Faction,_: number): () end)
	local match=Match.new(economy,function(_: Match.Status,_: number): () end)
	local service: Buildings.Service?=nil; local failVisual=false; local reenter=false; local reentryCode=""
	local api=Buildings.new(pads,active,economy,match,Models.Create,function(): () end,function(model: Model,faction: Types.FactionId): Folder
		if failVisual then error("Intentional visual preparation failure") end
		if reenter then
			local s=service :: Buildings.Service; local d=s.GetBuildingDetails("Human","Human_Upper_01"); assert(d)
			local _,code=s.TrySell("Human",d.padId,d.instanceId,d.revision,"reentrant",match.GetMatchId()); reentryCode=code
		end
		return Models.CreateUpgradeVisual(model,faction)
	end); service=api
	local names: {string}={}
	local function check(name: string,result: boolean): () assert(result,"FAIL: "..name); table.insert(names,name) end
	local function near(a: number,b: number): boolean return math.abs(a-b)<1e-7 end
	local function details(padId: string): Buildings.Details local d=api.GetBuildingDetails("Human",padId); assert(d); return d end
	local function modelAt(padId: string): Model local record=api.GetBuilding(padId); assert(record); return record.model end
	local function upgrade(d: Buildings.Details,id: string): (boolean,string) return api.TryUpgrade("Human",d.padId,d.instanceId,d.revision,id,match.GetMatchId()) end
	local function sell(d: Buildings.Details,id: string): (boolean,string) return api.TrySell("Human",d.padId,d.instanceId,d.revision,id,match.GetMatchId()) end
	match.Start(); local epoch=match.GetMatchId()
	check("round nearest down",Levels.RoundUpgradeGold(10.49)==10)
	check("round half up",Levels.RoundUpgradeGold(10.5)==11)
	check("round nearest up",Levels.RoundUpgradeGold(10.51)==11)
	check("knight upgrade cost 182",Levels.UpgradeCost("KnightBarracks")==182)
	check("archer upgrade cost 133",Levels.UpgradeCost("ArcherTower")==133)
	assert(api.TryBuild("Human","Human_Upper_01","KnightBarracks","build1",epoch))
	local first=details("Human_Upper_01")
	check("new building level and investment",first.level==1 and first.totalSpent==260 and first.revision==1)
	check("level one refund 156",first.refund==156)
	local poor=upgrade(first,"poor"); check("insufficient gold upgrade refused",not poor and economy.GetGold("Human")==90 and details(first.padId).level==1)
	assert(economy.AddGold("Human",1000,"fund",epoch))
	failVisual=true; local balance=economy.GetGold("Human"); local failed=upgrade(first,"visual-fail"); failVisual=false
	check("visual failure no debit",not failed and economy.GetGold("Human")==balance and details(first.padId).level==1)
	assert(economy.TrySpendGold("Human",1,"upgrade:reserved",epoch))
	balance=economy.GetGold("Human"); local conflict=upgrade(first,"reserved")
	check("upgrade debit rejection restores state",not conflict and economy.GetGold("Human")==balance and details(first.padId).totalSpent==260 and details(first.padId).revision==1)
	check("upgrade rollback removes visual",modelAt(first.padId):FindFirstChild("LevelTwoVisuals")==nil)
	assert(economy.AddGold("Human",1,"restore",epoch))
	local oldUnit=first.stats.unit; assert(oldUnit)
	balance=economy.GetGold("Human"); reenter=true; local upgraded=upgrade(first,"upgrade-main"); reenter=false
	local second=details(first.padId)
	check("upgrade succeeds once",upgraded and second.level==2 and second.revision==2 and second.totalSpent==442)
	check("upgrade exact debit",economy.GetGold("Human")==balance-182)
	check("concurrent same-pad action blocked",reentryCode=="E_BUILDING_BUSY")
	check("visual level two",modelAt(first.padId):FindFirstChild("LevelTwoVisuals")~=nil)
	local newUnit=second.stats.unit; local interval=second.stats.spawnIntervalSeconds; assert(newUnit and interval)
	check("new unit health damage interval",near(newUnit.health,336) and near(newUnit.damage,20.4) and near(interval,23.4))
	check("old unit snapshot unchanged",oldUnit.health==280 and oldUnit.damage==17 and Units["Knight" :: Types.UnitId].health==280)
	check("snapshots frozen",table.isfrozen(second.stats) and table.isfrozen(newUnit))
	check("no next level",second.nextStats==nil and second.upgradeCost==nil)
	balance=economy.GetGold("Human"); local repeatOk,repeatCode=upgrade(first,"upgrade-main")
	check("duplicate upgrade refused",not repeatOk and repeatCode=="E_DUPLICATE_REQUEST" and economy.GetGold("Human")==balance)
	local above,aboveCode=upgrade(second,"level3"); check("level three refused",not above and aboveCode=="E_MAX_LEVEL")
	local stale,staleCode=sell(first,"old-revision"); check("sell concurrent with old upgrade revision refused",not stale and staleCode=="E_STALE_BUILDING")
	check("enemy cannot read details",api.GetBuildingDetails("Undead",first.padId)==nil)
	local foreign=api.TrySell("Undead",second.padId,second.instanceId,second.revision,"enemy",epoch)
	check("enemy cannot sell",not foreign and details(first.padId).level==2)
	check("enemy cannot upgrade",not api.CanUpgrade("Undead",first.padId))
	check("level two refund includes upgrade",near(second.refund,265.2))
	assert(economy.AddGold("Human",1,"sell:reserved",epoch)); balance=economy.GetGold("Human")
	local rejected=sell(second,"reserved")
	check("credit rejection restores building and pad",not rejected and economy.GetGold("Human")==balance and details(first.padId).level==2 and #active:GetChildren()==1)
	check("credit rollback occupancy",pads:FindFirstChild(first.padId):GetAttribute("IsOccupied")==true)
	balance=economy.GetGold("Human"); local sold=sell(second,"sell-main")
	check("sell level two refunds exact fraction",sold and near(economy.GetGold("Human")-balance,265.2))
	check("sell frees pad removes model and count",api.GetBuilding(first.padId)==nil and #active:GetChildren()==0 and pads:FindFirstChild(first.padId):GetAttribute("IsOccupied")==false and api.GetBuildingCount("Human")==0)
	balance=economy.GetGold("Human"); local twice,twiceCode=sell(second,"sell-main")
	check("duplicate sell no double credit",not twice and twiceCode=="E_DUPLICATE_REQUEST" and economy.GetGold("Human")==balance)
	check("second sell with new nonce refused",not sell(second,"sell-again"))
	assert(api.TryBuild("Human",first.padId,"KnightBarracks","rebuild",epoch)); local rebuilt=details(first.padId)
	check("rebuild new identity level one",rebuilt.instanceId~=second.instanceId and rebuilt.level==1 and rebuilt.totalSpent==260)
	local oldRequest,oldCode=sell(second,"late-after-rebuild")
	check("old building id cannot sell replacement",not oldRequest and oldCode=="E_STALE_BUILDING" and details(first.padId).instanceId==rebuilt.instanceId)
	balance=economy.GetGold("Human"); assert(sell(rebuilt,"sell-level1"))
	check("level one sale exact refund",near(economy.GetGold("Human")-balance,156))
	local shield=Levels.Snapshot("LightSanctuary",2)
	check("shield 56.25 unchanged interval",shield.shieldHealth==56.25 and shield.effectIntervalSeconds==7)
	local curse=Levels.Snapshot("CursedObelisk",2)
	check("curse level two 7.5 magical",curse.curseDamageMultiplier==1.25 and curse.curseDamageType=="Magical" and curse.curseDamage==7.5 and not curse.requiresManualConfiguration)
	assert(api.TryBuild("Human",first.padId,"ArcherTower","cap-building",epoch)); local cap=details(first.padId)
	assert(economy.AddGold("Human",20000,"cap-balance",epoch))
	check("sale details disclose cap",details(first.padId).refund==114 and details(first.padId).refundAtCurrentBalance==0)
	assert(sell(cap,"cap-sale")); check("refund respects existing gold maximum",economy.GetGold("Human")==9999)
	check("upgrade payload parsed",Network.Parse({action="Upgrade",padId="p",instanceId="id",revision=1,requestId="r",matchId=1})~=nil)
	check("sell payload parsed",Network.Parse({action="Sell",padId="p",instanceId="id",revision=2,requestId="r",matchId=1})~=nil)
	check("client refund injection refused",Network.Parse({action="Sell",padId="p",instanceId="id",revision=1,requestId="r",matchId=1,refund=9999})==nil)
	check("missing instance refused",Network.Parse({action="Sell",padId="p",revision=1,requestId="r",matchId=1})==nil)
	check("invalid revision refused",Network.Parse({action="Upgrade",padId="p",instanceId="id",revision=0/0,requestId="r",matchId=1})==nil)
	assert(api.TryBuild("Human",first.padId,"KnightBarracks","end-building",epoch)); local last=details(first.padId)
	match.Finish(); local ended=upgrade(last,"finished"); check("finished upgrade and sale refused",not ended and not sell(last,"finished-sale"))
	api.ClearBuildings(); check("match cleanup clears levelled state",#active:GetChildren()==0 and api.GetBuilding(first.padId)==nil)
	match.Start(); check("previous match action refused",not api.TrySell("Human",last.padId,last.instanceId,last.revision,"old-match",epoch))
	api.ClearBuildings(); pads:Destroy(); active:Destroy()
	return {passed=#names,names=names}
end
return table.freeze(Tests)
