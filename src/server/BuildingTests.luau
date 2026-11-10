--!strict
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.GameConfig)
local Presentation=require(Shared.Config.BuildingPresentation)
local Definitions=require(Shared.Config.BuildingConfig)
local EconomyService=require(script.Parent.EconomyService)
local MatchService=require(script.Parent.MatchService)
local BuildingService=require(script.Parent.BuildingService)
local Models=require(script.Parent.BuildingModels)
local Network=require(script.Parent.BuildingNetwork)
local Tests={}
function Tests.Run(): {passed: number,names: {string}}
	assert(game:GetService("RunService"):IsStudio(),"E_STUDIO_ONLY")
	local map=workspace:FindFirstChild("Map"); assert(map,"E_MAP")
	local original=map:FindFirstChild("BuildPads"); assert(original,"E_PADS")
	local pads=original:Clone(); assert(pads)
	-- Clone a busy real map safely; all mutations are confined to these unparented copies.
	for _,pad in pads:GetChildren() do pad:SetAttribute("IsOccupied",false) end
	local active=Instance.new("Folder"); active:SetAttribute("SystemOwner","CastleFightBuildings")
	local economy=EconomyService.new(Config,function(_: EconomyService.Faction,_: number): () end)
	local match=MatchService.new(economy,function(_: MatchService.Status,_: number): () end)
	local factoryFails=false
	local service=BuildingService.new(pads,active,economy,match,function(id: Types.BuildingId,pad: BasePart): Model
		if factoryFails then error("Intentional test failure before debit") end; return Models.Create(id,pad)
	end,function(): () end)
	local names: {string}={}
	local function check(name: string,result: boolean): () assert(result,"FAIL: "..name); table.insert(names,name) end
	local function attempt(pad: string,id: Types.BuildingId,requestId: string): (boolean,string) return service.TryBuild("Human",pad,id,requestId,match.GetMatchId()) end
	local function denied(name: string,pad: string,id: Types.BuildingId,requestId: string,expected: string): ()
		local before=economy.GetGold("Human"); local ok,code=attempt(pad,id,requestId)
		check(name,not ok and code==expected and economy.GetGold("Human")==before)
	end
	denied("waiting refused without debit","Human_Upper_01","KnightBarracks","waiting","E_MATCH_INACTIVE")
	match.Start()
	denied("enemy pad refused without debit","Undead_Upper_01","KnightBarracks","enemy","E_NOT_YOUR_PAD")
	denied("enemy building refused","Human_Upper_01","BoneTower","enemy-building","E_WRONG_BUILDING_FACTION")
	denied("unknown building refused","Human_Upper_01",("Unknown" :: string) :: Types.BuildingId,"unknown","E_BUILDING_ID")
	factoryFails=true; denied("model failure no debit or occupancy","Human_Upper_01","KnightBarracks","model-failure","E_MODEL_PREPARATION"); factoryFails=false
	check("failed model leaves pad free",pads:FindFirstChild("Human_Upper_01"):GetAttribute("IsOccupied")==false and #active:GetChildren()==0)
	-- Exercise rollback after provisional publication when the existing economy refuses payment.
	assert(economy.TrySpendGold("Human",1,"build:reserved",match.GetMatchId()))
	denied("payment rejection rolls back publication","Human_Upper_01","KnightBarracks","reserved","E_OPERATION_CONFLICT")
	check("rollback removes model and private record",#active:GetChildren()==0 and service.GetBuilding("Human_Upper_01")==nil and pads:FindFirstChild("Human_Upper_01"):GetAttribute("IsOccupied")==false)
	assert(economy.AddGold("Human",1,"restore-fixture",match.GetMatchId()))
	check("own purchase succeeds",(attempt("Human_Upper_01","KnightBarracks","purchase")))
	check("exact price debited",economy.GetGold("Human")==90)
	local record=service.GetBuilding("Human_Upper_01"); assert(record)
	check("lane and asset identity",record.laneId=="Upper" and record.assetId=="human_barracks" and record.model:GetAttribute("LaneId")=="Upper")
	check("occupied attribute set",pads:FindFirstChild("Human_Upper_01"):GetAttribute("IsOccupied")==true)
	denied("duplicate request no debit","Human_Upper_01","KnightBarracks","purchase","E_DUPLICATE_REQUEST")
	denied("request identity conflict","Human_Upper_02","KnightBarracks","purchase","E_REQUEST_CONFLICT")
	denied("different request occupied pad","Human_Upper_01","KnightBarracks","double","E_PAD_OCCUPIED")
	denied("insufficient gold no debit","Human_Upper_02","ArcherTower","poor","E_INSUFFICIENT_GOLD")
	local fund=0
	local function topUp(faction: EconomyService.Faction): () fund+=1; assert(economy.AddGold(faction,9000,"fund"..fund,match.GetMatchId())) end
	topUp("Human"); topUp("Undead")
	check("second producer",(attempt("Human_Upper_02","KnightBarracks","knight2")))
	check("third producer",(attempt("Human_Upper_03","KnightBarracks","knight3")))
	denied("fourth producer limit across lanes","Human_Lower_01","KnightBarracks","knight4","E_PRODUCER_LIMIT")
	check("first passive upper",(attempt("Human_Upper_04","LightSanctuary","passive1")))
	denied("second passive same lane","Human_Upper_05","LightSanctuary","passive2","E_PASSIVE_LIMIT")
	check("passive different lane allowed",(attempt("Human_Lower_01","LightSanctuary","passive3")))
	for index,pad in {"Human_Upper_05","Human_Lower_02","Human_Lower_03"} do check("archer "..index,(attempt(pad,"ArcherTower","archer"..index))) end
	for index,pad in {"Human_Lower_04","Human_Lower_05"} do check("mage "..index,(attempt(pad,"MageAcademy","mage"..index))) end
	check("ten buildings total",service.GetBuildingCount("Human")==10 and #service.GetBuildingsForFaction("Human")==10)
	check("count by type and lane",service.GetBuildingCount("Human","KnightBarracks")==3 and service.GetBuildingCount("Human",nil,"Lower")==5)
	check("Undead independent purchase",(service.TryBuild("Undead","Undead_Lower_01","CursedObelisk","undead1",match.GetMatchId())))
	check("faction counts independent",service.GetBuildingCount("Undead")==1 and service.GetBuildingCount("Human")==10)
	for id,info in Presentation.entries do
		local def=Definitions[id :: Types.BuildingId]; local pad=pads:FindFirstChild(def.faction.."_Upper_01") :: BasePart
		local model=Models.Create(id :: Types.BuildingId,pad); local cf,size=model:GetBoundingBox()
		check("model fit "..info.assetId,math.abs(cf.Position.Y-size.Y/2-pad.Position.Y-pad.Size.Y/2)<.01 and size.X<=pad.Size.X and size.Z<=pad.Size.Z)
		check("pivot at pad "..id,(model:GetPivot().Position-(pad.Position+Vector3.new(0,pad.Size.Y/2,0))).Magnitude<.01)
		local safe=true; for _,part in model:GetDescendants() do if part:IsA("BasePart") then safe=safe and part.Anchored and not part.CanCollide and not part.CanTouch end end
		check("nonblocking visuals "..id,safe); model:Destroy()
	end
	local malformed: {any}={false,{padId="x"},{padId="x",buildingId="KnightBarracks",requestId="x",matchId=1,cost=0},{padId="x",buildingId="x",requestId="x",matchId=0/0}}
	for index,payload in malformed do
		check("malformed payload "..index,Network.Parse(payload)==nil)
	end
	check("valid payload parsed",Network.Parse({padId="Human_Upper_01",buildingId="KnightBarracks",requestId="valid",matchId=1})~=nil)
	match.Finish(); denied("finished refused","Human_Upper_01","KnightBarracks","finished","E_MATCH_INACTIVE")
	service.ClearBuildings()
	local free=true; for _,pad in pads:GetChildren() do free=free and pad:GetAttribute("IsOccupied")==false end
	check("clear destroys generated models and frees pads",free and #active:GetChildren()==0 and service.GetBuildingCount("Human")==0)
	match.Start(); local old=match.GetMatchId()-1
	local stale=service.TryBuild("Human","Human_Upper_01","KnightBarracks","old",old)
	check("old match rejected",not stale and economy.GetGold("Human")==350)
	check("new match can build on freed pad",(attempt("Human_Upper_01","KnightBarracks","purchase")))
	service.ClearBuildings(); pads:Destroy(); active:Destroy()
	return {passed=#names,names=names}
end
return table.freeze(Tests)
