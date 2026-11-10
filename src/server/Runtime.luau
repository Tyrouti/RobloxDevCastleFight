--!strict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local ServerStorage=game:GetService("ServerStorage")
local Config=require(ReplicatedStorage.CastleFightShared.Config.GameConfig)
local EconomyService=require(script.Parent.EconomyService)
local MatchService=require(script.Parent.MatchService)
local BuildingService=require(script.Parent.BuildingService)
local BuildingModels=require(script.Parent.BuildingModels)
local BuildingNetwork=require(script.Parent.BuildingNetwork)
local UnitService=require(script.Parent.UnitService)
local UnitModels=require(script.Parent.UnitModels)
local LaneRoutes=require(script.Parent.LaneRoutes)
local CombatService=require(script.Parent.CombatService)
local EffectService=require(script.Parent.EffectService)
local LobbyService=require(script.Parent.LobbyService)
type Faction=EconomyService.Faction
local Runtime={}
local started=false

function Runtime.Start(): ()
    assert(RunService:IsServer(),"E_SERVER_ONLY")
    if started then return end
    local map=workspace:FindFirstChild("Map")
    if not map or map:GetAttribute("SceneId")~="castlefight.map.v1" then return end
    started=true
    assert(not ReplicatedStorage:FindFirstChild("CastleFightState"),"E_DUPLICATE_STATE")
    local state=Instance.new("Folder"); state.Name="CastleFightState"
    state:SetAttribute("MatchStatus","Waiting"); state:SetAttribute("MatchId",0)
    state:SetAttribute("LobbyEnabled",workspace:FindFirstChild("Lobby23")~=nil)
    state:SetAttribute("IncomePerSecond",Config.goldPerSecond); state.Parent=ReplicatedStorage
    local seats: {[Player]:Faction}={}
    local buildings: BuildingService.Service?=nil
    local units: UnitService.Service?=nil
    local combat: CombatService.Service?=nil
    local statusEffects: EffectService.Service?=nil
    local lobby: LobbyService.Service?=nil
    local readResult: (() -> MatchService.Result?)?=nil
    local function publishPlayer(player: Player, gold: number, income: number): ()
        player:SetAttribute("CastleFightFaction",seats[player] or "Unassigned")
        player:SetAttribute("CastleFightGold",gold); player:SetAttribute("CastleFightIncome",income)
        local service=buildings; local faction=seats[player]
        player:SetAttribute("CastleFightBuildingCount",if service and faction then service.GetBuildingCount(faction :: Faction) else 0)
    end
    local economy=EconomyService.new(Config,function(faction: Faction,gold: number): ()
        for player,seat in seats do
            if seat==faction then publishPlayer(player,gold,if state:GetAttribute("MatchStatus")=="InProgress" then Config.goldPerSecond else 0) end
        end
    end)
    local match=MatchService.new(economy,function(status: MatchService.Status,id: number): ()
        state:SetAttribute("MatchId",id); state:SetAttribute("MatchStatus",status)
        local result=if readResult then readResult() else nil
        state:SetAttribute("Winner",if result then result.winner else nil); state:SetAttribute("FinishReason",if result then result.reason else nil)
        state:SetAttribute("Outcome",if result then (if result.reason=="Draw" then "Draw" else result.winner) else nil)
        if status~="InProgress" then state:SetAttribute("StudioUnitDemo",false) end
        if statusEffects and status~="InProgress" then statusEffects.Clear() end
        local battle=combat
        if battle then if status=="Starting" or status=="Waiting" then battle.Reset() elseif status=="Finished" then battle.Stop() end end
        local service=buildings
        local army=units; if army and status~="InProgress" then army.ClearUnits() end
        if service and status~="InProgress" then service.ClearBuildings() end
        if lobby and (status=="Finished" or status=="Waiting") then table.clear(seats);lobby.MatchEnded() end
        for _,player in Players:GetPlayers() do
            local seat=seats[player]
            publishPlayer(player,if seat then economy.GetGold(seat :: Faction) else 0,if seat and status=="InProgress" then Config.goldPerSecond else 0)
        end
    end)
    readResult=match.GetResult
    assert(not workspace:FindFirstChild("ActiveBuildings"),"E_ACTIVE_BUILDINGS_EXISTS")
    local active=Instance.new("Folder"); active.Name="ActiveBuildings"; active:SetAttribute("SystemOwner","CastleFightBuildings"); active.Parent=workspace
    local pads=map:FindFirstChild("BuildPads"); assert(pads,"E_BUILD_PADS_MISSING")
    buildings=BuildingService.new(pads,active,economy,match,BuildingModels.Create,function(): ()
        local service=buildings
        for _,player in Players:GetPlayers() do
            local faction=seats[player]
            player:SetAttribute("CastleFightBuildingCount",if service and faction then service.GetBuildingCount(faction :: Faction) else 0)
        end
        local army=units; if army then army.SyncBuildings() end
        if statusEffects then statusEffects.SyncBuildings() end
    end)
    assert(not workspace:FindFirstChild("ActiveUnits"),"E_ACTIVE_UNITS_EXISTS")
    local activeUnits=Instance.new("Folder"); activeUnits.Name="ActiveUnits"; activeUnits:SetAttribute("SystemOwner","CastleFightUnits"); activeUnits.Parent=workspace
    units=UnitService.new(pads,activeUnits,LaneRoutes.new(map),buildings :: BuildingService.Service,match,UnitModels.Create,os.clock)
    local health=Instance.new("Folder"); health.Name="Castles"; health.Parent=state
    for _,faction in {"Human","Undead"} do local record=Instance.new("Folder"); record.Name=faction; record.Parent=health end
    assert(not ReplicatedStorage:FindFirstChild("CastleFightCombatRemotes"),"E_COMBAT_REMOTES_EXIST")
    local combatRemotes=Instance.new("Folder"); combatRemotes.Name="CastleFightCombatRemotes"
    local effects=Instance.new("RemoteEvent"); effects.Name="Effect"; effects.Parent=combatRemotes; combatRemotes.Parent=ReplicatedStorage
    statusEffects=EffectService.new(units :: UnitService.Service,buildings :: BuildingService.Service,match,os.clock,function(message: EffectService.Message): () effects:FireAllClients(message) end)
    combat=CombatService.new(map,units :: UnitService.Service,match,os.clock,function(message: CombatService.Effect): ()
        effects:FireAllClients(message)
    end,function(faction: Faction,hp: number,maxHP: number): ()
        local record=health:FindFirstChild(faction); assert(record); record:SetAttribute("HP",hp); record:SetAttribute("MaxHP",maxHP)
    end,statusEffects)
    assert(not ReplicatedStorage:FindFirstChild("CastleFightBuildRemotes"),"E_BUILD_REMOTES_EXIST")
    local remotes=Instance.new("Folder"); remotes.Name="CastleFightBuildRemotes"
    local request=Instance.new("RemoteEvent"); request.Name="BuildRequest"; request.Parent=remotes
    local reply=Instance.new("RemoteEvent"); reply.Name="BuildResult"; reply.Parent=remotes
    remotes.Parent=ReplicatedStorage
    local network=BuildingNetwork.Connect(request,reply,function(player: Player): Faction? return seats[player] end,buildings :: BuildingService.Service)
    local connections: {RBXScriptConnection}={}
    local lobbyModel=workspace:FindFirstChild("Lobby23")
    if lobbyModel and lobbyModel:IsA("Model") then
        lobby=LobbyService.new(lobbyModel,state,match,function(first: Player,second: Player): boolean
            if match.GetStatus()~="Waiting" and match.GetStatus()~="Finished" then return false end
            table.clear(seats);seats[first]="Human";seats[second]="Undead"
            local ok=match.Start();if not ok then table.clear(seats) end;return ok
        end)
    end
    local studioDemoStarted: number?=nil
    local studioHoldCombat=false
    local studioPeakUnits=0;local studioPeakAttackers=0
    local studioScene: any=nil
    local function beginStudioTiming(): ()
        studioDemoStarted=os.clock();state:SetAttribute("StudioFirstSpawnElapsed",nil);state:SetAttribute("StudioFirstUnitHitElapsed",nil);state:SetAttribute("StudioFirstCastleHitElapsed",nil)
    end
    table.insert(connections,Players.PlayerAdded:Connect(function(player: Player): () publishPlayer(player,0,0) end))
    table.insert(connections,Players.PlayerRemoving:Connect(function(player: Player): () seats[player]=nil; network.Forget(player) end))
    for _,player in Players:GetPlayers() do publishPlayer(player,0,0) end
    table.insert(connections,RunService.Heartbeat:Connect(function(dt: number): ()
        match.Step(dt);if statusEffects and not studioHoldCombat then statusEffects.Step() end
        local battle=combat; if battle and not studioHoldCombat then battle.Step() end; local army=units; if army then army.Step(dt) end
        if studioScene then studioScene.step(dt) end
        if RunService:IsStudio() and studioDemoStarted and army and battle then
            local elapsed=os.clock()-studioDemoStarted;local s=battle.GetSnapshot()
            local attacking=0;local upper=0;local lower=0
            for _,unit in army.GetUnits() do
                if unit.hp>0 and unit.state=="Attacking" then attacking+=1;if unit.laneId=="Upper" then upper+=1 else lower+=1 end end
            end
            studioPeakUnits=math.max(studioPeakUnits,army.GetDiagnostics().units);studioPeakAttackers=math.max(studioPeakAttackers,attacking)
            state:SetAttribute("StudioPeakUnits",studioPeakUnits);state:SetAttribute("StudioPeakAttackers",studioPeakAttackers)
            state:SetAttribute("StudioUpperAttackers",upper);state:SetAttribute("StudioLowerAttackers",lower)
            if army.GetDiagnostics().units>0 and state:GetAttribute("StudioFirstSpawnElapsed")==nil then state:SetAttribute("StudioFirstSpawnElapsed",elapsed) end
            if s.unitHits>0 and state:GetAttribute("StudioFirstUnitHitElapsed")==nil then state:SetAttribute("StudioFirstUnitHitElapsed",elapsed) end
            if s.castleHits>0 and state:GetAttribute("StudioFirstCastleHitElapsed")==nil then state:SetAttribute("StudioFirstCastleHitElapsed",elapsed) end
        end
    end))
    -- No RemoteEvents or client commands. This endpoint exists only in local Studio simulation.
    if RunService:IsStudio() then
        assert(not ServerStorage:FindFirstChild("CastleFightStudioTests"),"E_DUPLICATE_TEST_CONTROL")
        local container=Instance.new("Folder"); container.Name="CastleFightStudioTests"; container.Parent=ServerStorage
        local control=Instance.new("BindableFunction"); control.Name="Control"; control.Parent=container
        local function startTestMatch(): {success: boolean,code: string,matchId: number?}
            if studioScene then studioScene.destroy();studioScene=nil end
            if match.GetStatus()~="Waiting" and match.GetStatus()~="Finished" then return {success=false,code="E_MATCH_ALREADY_STARTED"} end
            local roster=Players:GetPlayers()
            if #roster==0 then return {success=false,code="E_PLAYER_REQUIRED_USE_PLAY"} end
            table.sort(roster,function(a: Player,b: Player): boolean return a.UserId<b.UserId end)
            table.clear(seats)
            for index,player in roster do if index<=#Config.factions then seats[player]=Config.factions[index] :: Faction end end
            local ok,code=match.Start()
            if ok and lobby then local participants={};for _,player in roster do if seats[player] then table.insert(participants,player) end end;lobby.Admit(participants) end
            return {success=ok,code=code,matchId=match.GetMatchId()}
        end
        control.OnInvoke=function(action: string): any
            if action=="LobbySnapshot" then return if lobby then lobby.Snapshot() else {enabled=false}
            elseif action=="RunLobbyChecks" then return require(script.Parent.LobbyTests).Run()
            elseif action=="EffectSnapshot" then
                return (statusEffects :: EffectService.Service).GetSnapshot()
            elseif action=="ApplyAbilityStressEffects" then
                local army=units :: UnitService.Service
                if army.GetDiagnostics().units~=60 then return {success=false,code="E_SIXTY_UNITS_REQUIRED"} end
                local service=statusEffects :: EffectService.Service
                for _,unit in army.GetUnits() do
                    service.Apply(unit.instanceId,"Shield",56.25,nil)
                    service.Apply(unit.instanceId,"Curse",6,nil)
                    service.Apply(unit.instanceId,"DamageOverTime",2,nil)
                end
                return service.GetSnapshot()
            elseif action=="RunEffectChecks" then
                return require(script.Parent.EffectTests).Run()
            elseif action=="StartAbilityDemo" then
                local result=startTestMatch();if not result.success then return result end
                beginStudioTiming();studioHoldCombat=false
                return require(script.Parent.AbilityDemo).Create(buildings :: BuildingService.Service,economy,match)
            elseif action=="FinishAbilityDemo" then
                local ok,code=match.Finish();return {success=ok,code=code}
            elseif string.sub(action,1,14)=="Start21BScene:" then
                if studioScene then studioScene.destroy();studioScene=nil end
                match.Finish();studioHoldCombat=false
                studioScene=require(script.Parent.Unit21BTests).Scene(string.sub(action,15))
                return {success=true,units=studioScene.u.GetDiagnostics()}
            elseif action=="Scene21BSnapshot" then
                if not studioScene then return {success=false} end
                local list={};for _,unit in studioScene.u.GetUnits() do table.insert(list,{id=unit.unitId,x=unit.position.X,z=unit.position.Z,state=unit.state,hp=unit.hp}) end
                return {units=list,combat=studioScene.c.GetSnapshot()}
            elseif action=="Stop21BScene" then
                if studioScene then studioScene.destroy();studioScene=nil end;return {success=true}
            elseif action=="Start" then
                return startTestMatch()
            elseif action=="StartUnitDemo" or action=="Start21BStress" then
                local result=startTestMatch(); if not result.success then return result end
                studioHoldCombat=action=="Start21BStress";studioPeakUnits=0;studioPeakAttackers=0
                state:SetAttribute("StudioCombatHeld",studioHoldCombat)
                beginStudioTiming()
                local demo=require(script.Parent.UnitDemo).Create(buildings :: BuildingService.Service,economy,match)
                if demo.success then state:SetAttribute("StudioUnitDemo",true) end
                return demo
            elseif action=="Resume21BCombat" then
                studioHoldCombat=false;state:SetAttribute("StudioCombatHeld",false);return {success=true}
            elseif action=="StartCastleHudDemo" or action=="StartHumanCastleHudDemo" then
                local result=startTestMatch();if not result.success then return result end
                beginStudioTiming()
                local faction: Faction=if action=="StartHumanCastleHudDemo" then "Undead" else "Human"
                local demo=require(script.Parent.CastleHudDemo).Create(buildings :: BuildingService.Service,economy,match,faction)
                if demo.success then state:SetAttribute("StudioUnitDemo",true) end
                return demo
            elseif action=="Finish" then
                if studioScene then studioScene.destroy();studioScene=nil end
                studioHoldCombat=false;state:SetAttribute("StudioCombatHeld",false)
                local ok,code=match.Finish(); return {success=ok,code=code}
            elseif action=="Reset" then
                local ok,code=match.Reset()
                if ok then table.clear(seats); for _,p in Players:GetPlayers() do publishPlayer(p,0,0) end end
                return {success=ok,code=code}
            elseif action=="RunChecks" then
                return require(script.Parent.EconomyTests).Run()
            elseif action=="RunBuildingChecks" then
                return require(script.Parent.BuildingTests).Run()
            elseif action=="RunManagementChecks" then
                return require(script.Parent.BuildingManagementTests).Run()
            elseif action=="RunUnitChecks" then
                return require(script.Parent.UnitTests).Run()
            elseif action=="RunCombatChecks" then
                return require(script.Parent.CombatTests).Run()
            elseif action=="CombatSnapshot" then
                local battle=combat :: CombatService.Service; return {combat=battle.GetSnapshot(),result=match.GetResult(),status=match.GetStatus()}
            elseif action=="UnitSnapshot" then
                local army=units :: UnitService.Service
                local list={}
                for _,unit in army.GetUnits() do table.insert(list,{id=unit.instanceId,unitId=unit.unitId,faction=unit.faction,lane=unit.laneId,
                    x=unit.position.X,z=unit.position.Z,state=unit.state,hp=unit.hp,level=unit.sourceLevel}) end
                return {diagnostics=army.GetDiagnostics(),units=list}
            elseif action=="Snapshot" then
                return {status=match.GetStatus(),matchId=match.GetMatchId(),Human=economy.GetGold("Human"),Undead=economy.GetGold("Undead")}
            end
            return {success=false,code="E_UNKNOWN_TEST_ACTION"}
        end
    end
    game:BindToClose(function(): ()
        if lobby then lobby.Destroy() end
        if studioScene then studioScene.destroy();studioScene=nil end
        for _,connection in connections do connection:Disconnect() end
        network.Disconnect()
        economy.SetActive(false)
        local battle=combat; if battle then battle.Stop() end
        local army=units; if army then army.ClearUnits() end
        if statusEffects then statusEffects.Clear() end
    end)
end
return table.freeze(Runtime)
