--!strict
-- One bounded update shared by all units and producer schedules. No NPC threads or pathfinding.
local Shared=game:GetService("ReplicatedStorage").CastleFightShared
local Types=require(Shared.Types)
local Config=require(Shared.Config.GameConfig)
local Visual=require(Shared.Config.UnitPresentation)
local Levels=require(Shared.Config.BuildingLevels)
local CombatConfig=require(Shared.Config.CombatConfig)
local Buildings=require(script.Parent.BuildingService)
local Match=require(script.Parent.MatchService)
local LaneRoutes=require(script.Parent.LaneRoutes)
local Geometry=require(script.Parent.UnitGeometry)
local Navigation=require(Shared.Config.UnitNavigation)
local MapConfig=require(Shared.Config.MapConfig)
local Http=game:GetService("HttpService")
type Faction=Types.FactionId
export type Data={instanceId: string,unitId: Types.UnitId,faction: Faction,laneId: Types.LaneId,hp: number,maxHP: number,speed: number,
	state: string,sourceBuildingId: string,sourceBuildingType: Types.BuildingId,sourcePadId: string,sourceLevel: number,
	stats: Types.UnitDefinition,position: Vector3,model: Model,reachedCastle: boolean,radius: number,bodyRadius: number,height: number,width: number,depth: number}
type Unit=Data & {path: {Vector3},nextPoint: number,facing: Vector3,publishElapsed: number,removeAt: number?,laneOffset: number,combatTarget: Vector3?}
type Schedule={record: Buildings.Record,stats: Levels.Stats,firstAt: number,lastAttemptAt: number?,errorReported: boolean}
export type Diagnostics={Human: number,Undead: number,units: number,schedules: number,skippedAtLimit: number,modelErrors: number,movementCorrections: number,perUnitThreads: number,blockedSpawns: number,blockedMoves: number}
export type Service={SyncBuildings: () -> (),Step: (number) -> (),ClearUnits: () -> (),RemoveUnit: (string) -> boolean,
	GetUnits: () -> {Data},GetUnit: (string) -> Data?,GetCount: (Faction) -> number,GetDiagnostics: () -> Diagnostics,
	SetCombatState: (string,boolean,Vector3?) -> boolean,ApplyDamage: (string,number) -> (number,boolean),
 SetEffectHooks: (((string,number) -> number)?,((string) -> ())?) -> ()}
local UnitService={}
local FACTIONS: {Faction}={"Human","Undead"}

function UnitService.new(padsFolder: Instance,active: Folder,routes: LaneRoutes.Routes,buildings: Buildings.Service,match: Match.Match,
	createModel: (Types.UnitId) -> Model,clock: () -> number): Service
	assert(active:GetAttribute("SystemOwner")=="CastleFightUnits","E_FOREIGN_UNITS_FOLDER")
	local units: {[string]:Unit}={}; local schedules: {[string]:Schedule}={}; local order: {string}={}
	local counts: {[string]:number}={Human=0,Undead=0}
	local skipped=0; local errors=0; local corrections=0; local serial=0
	local blockedSpawns=0;local blockedMoves=0
	local obstacles: {Geometry.Bounds}={}
 local damageFilter: ((string,number) -> number)?=nil
 local removed: ((string) -> ())?=nil
	local rayParams=RaycastParams.new();rayParams.FilterType=Enum.RaycastFilterType.Include
	local map=workspace:FindFirstChild("Map");rayParams.FilterDescendantsInstances=if map then {map} else {}
	local function free(position: Vector3,radius: number,bodyRadius: number,height: number,faction: Faction,ignore: string?,facing: Vector3,width: number,depth: number): boolean
		for id,other in units do
			if id==ignore or other.hp<=0 then continue end
			local delta=Vector3.new(position.X-other.position.X,0,position.Z-other.position.Z)
			if faction==other.faction then
                if Geometry.Overlap(position,facing,width,depth,other.position,other.facing,other.width,other.depth,Navigation.friendlyGap) then return false end
            elseif delta.Magnitude<bodyRadius+other.bodyRadius+Navigation.bodyGap-.001 then return false end
		end
		for _,bounds in obstacles do if Geometry.IntersectsBounds(position,radius,height,bounds) then return false end end
		return true
	end
	local api={} :: Service
 function api.SetEffectHooks(filter: ((string,number) -> number)?,onRemoved: ((string) -> ())?): () damageFilter=filter;removed=onRemoved end
	function api.GetCount(faction: Faction): number return counts[faction] or 0 end
	function api.GetUnit(id: string): Data?
		local unit=units[id]; return if unit then table.freeze(table.clone(unit)) else nil
	end
	function api.GetUnits(): {Data}
		local result: {Data}={}; for _,unit in units do table.insert(result,table.freeze(table.clone(unit))) end; return result
	end
	function api.GetDiagnostics(): Diagnostics
		return {Human=counts.Human,Undead=counts.Undead,units=counts.Human+counts.Undead,schedules=#order,
			skippedAtLimit=skipped,modelErrors=errors,movementCorrections=corrections,perUnitThreads=0,blockedSpawns=blockedSpawns,blockedMoves=blockedMoves}
	end
	function api.RemoveUnit(id: string): boolean
		local unit=units[id]; if not unit then return false end
  if removed then removed(id) end
		units[id]=nil; if unit.state~="Dead" then counts[unit.faction]-=1 end; unit.model:Destroy(); return true
	end
	function api.SetCombatState(id: string,attacking: boolean,target: Vector3?): boolean
		local unit=units[id]; if not unit or unit.hp<=0 or unit.state=="Dead" then return false end
		unit.state=if attacking then "Attacking" else (if unit.reachedCastle then "WaitingAtCastle" else "Moving")
        unit.combatTarget=if attacking then target else nil
		if attacking and target then
			local delta=Vector3.new(target.X-unit.position.X,0,target.Z-unit.position.Z)
			if delta.Magnitude>.001 then
                local facing=delta.Unit;local clear=true
                for otherId,other in units do
                    if otherId~=id and other.hp>0 and other.faction==unit.faction and Geometry.Overlap(unit.position,facing,unit.width,unit.depth,other.position,other.facing,other.width,other.depth,Navigation.friendlyGap) then clear=false;break end
                end
                -- Turning a wide weapon must not clip an ally. Attack rules remain unchanged.
                if clear then unit.facing=facing end
            end
		end
		local pose=CFrame.lookAt(unit.position,unit.position+unit.facing)
		unit.model:SetAttribute("State",unit.state); unit.model:SetAttribute("MovementCFrame",pose); unit.model:PivotTo(pose)
		return true
	end
	function api.ApplyDamage(id: string,amount: number): (number,boolean)
		if match.GetStatus()~="InProgress" or amount~=amount or amount<=0 or amount>=math.huge then return 0,false end
		local unit=units[id]; if not unit or unit.hp<=0 or unit.state=="Dead" then return 0,false end
  if damageFilter then amount=damageFilter(id,amount) end
		local loss=math.min(unit.hp,amount); unit.hp-=loss; unit.model:SetAttribute("HP",unit.hp)
		if unit.hp<=0 then
   if removed then removed(id) end
			unit.state="Dead"; unit.removeAt=clock()+CombatConfig.unitCombat.deathVisualSeconds
			counts[unit.faction]-=1; unit.model:SetAttribute("State","Dead"); unit.model:SetAttribute("TargetId",nil)
		end
		return loss,unit.state=="Dead"
	end
	function api.ClearUnits(): ()
		for id,unit in units do if removed then removed(id) end;unit.model:Destroy() end
		table.clear(units); table.clear(schedules); table.clear(order); counts.Human=0; counts.Undead=0
		skipped=0; errors=0; corrections=0
		blockedSpawns=0;blockedMoves=0;table.clear(obstacles)
	end
	function api.SyncBuildings(): ()
		if match.GetStatus()~="InProgress" then table.clear(schedules); table.clear(order); return end
		local present: {[string]:boolean}={}; local now=clock()
		for _,faction in FACTIONS do
			for _,record in buildings.GetBuildingsForFaction(faction :: Faction) do
				local stats=Levels.Snapshot(record.buildingId,record.level)
				if not stats.unitId then continue end
				present[record.instanceId]=true
				local schedule=schedules[record.instanceId]
				if not schedule then
					schedules[record.instanceId]={record=record,stats=stats,firstAt=now+Config.firstSpawnDelaySeconds,lastAttemptAt=nil,errorReported=false}
				elseif schedule.record.revision~=record.revision then
					-- Preserve first deadline / elapsed time; upgrade never creates another schedule.
					schedule.record=record; schedule.stats=stats
				end
			end
		end
		for id in schedules do if not present[id] then schedules[id]=nil end end
		table.clear(order); for id in schedules do table.insert(order,id) end
		table.sort(order,function(a: string,b: string): boolean return schedules[a].record.padId<schedules[b].record.padId end)
	end
	local function spawn(schedule: Schedule): ()
		local record=schedule.record; local stats=schedule.stats
		local unitId=stats.unitId; local definition=stats.unit; assert(unitId and definition,"E_PRODUCER_STATS")
		local pad=padsFolder:FindFirstChild(record.padId); assert(pad and pad:IsA("BasePart"),"E_UNIT_PAD")
		local model=createModel(unitId :: Types.UnitId)
		-- A faulty adapter must not destroy a parented imported original during cleanup.
		assert(model.Parent==nil,"E_UNIT_FACTORY_PARENT")
		local ok,failure=pcall(function(): boolean
			local size=Geometry.Measure(model)
			local start=Geometry.Start(record.model,pad,size)
			local path=routes.CreatePath(pad,record.laneId,record.faction,{spawn=start,radius=size.radius})
			if not free(path.start,size.radius,size.bodyRadius,size.height,record.faction,nil,path.direction,size.width,size.depth) then blockedSpawns+=1;model:Destroy();return false end
			serial+=1; local id=Http:GenerateGUID(false); local pose=CFrame.lookAt(path.start,path.start+path.direction)
			model.Name=unitId.."_"..serial
			local unit: Unit={instanceId=id,unitId=unitId :: Types.UnitId,faction=record.faction,laneId=record.laneId,hp=definition.health,maxHP=definition.health,
				speed=definition.speedStudsPerSecond,state="Moving",sourceBuildingId=record.instanceId,sourceBuildingType=record.buildingId,
				sourcePadId=record.padId,sourceLevel=record.level,stats=definition,position=path.start,model=model,path=path.points,nextPoint=1,facing=path.direction,publishElapsed=0,reachedCastle=false,removeAt=nil,radius=size.radius,bodyRadius=size.bodyRadius,height=size.height,width=size.width,depth=size.depth,laneOffset=if serial%2==0 then Navigation.preferredLateralOffset else -Navigation.preferredLateralOffset}
			model:SetAttribute("SystemOwner","CastleFightUnits"); model:SetAttribute("UnitInstanceId",id); model:SetAttribute("UnitId",unitId)
			model:SetAttribute("Faction",record.faction); model:SetAttribute("LaneId",record.laneId)
			model:SetAttribute("HP",unit.hp); model:SetAttribute("MaxHP",unit.maxHP); model:SetAttribute("Speed",unit.speed); model:SetAttribute("State",unit.state)
			model:SetAttribute("SourceBuildingId",record.instanceId); model:SetAttribute("SourceBuildingType",record.buildingId); model:SetAttribute("SourcePadId",record.padId)
			model:SetAttribute("SourceBuildingLevel",record.level); model:SetAttribute("BaseDamage",definition.damage); model:SetAttribute("DamageType",definition.damageType)
			model:SetAttribute("AttackRange",definition.attackRangeStuds); model:SetAttribute("AttackCooldown",definition.attackCooldownSeconds); model:SetAttribute("MatchId",match.GetMatchId())
			model:SetAttribute("MovementCFrame",pose); model:PivotTo(pose); model.Parent=active
			model:SetAttribute("NavigationRadius",size.radius);model:SetAttribute("BodyRadius",size.bodyRadius)
            model:SetAttribute("SpawnedAt",clock())
			units[id]=unit; counts[record.faction]+=1; return true
		end)
		if not ok then model:Destroy(); error(failure) end
	end
	function api.Step(dt: number): ()
		if match.GetStatus()~="InProgress" then return end
		if dt~=dt or dt<0 or dt==math.huge then return end
		table.clear(obstacles);for _,faction in FACTIONS do for _,record in buildings.GetBuildingsForFaction(faction :: Faction) do table.insert(obstacles,Geometry.ReadBounds(record.model)) end end
		local moving: {Unit}={};for _,u in units do table.insert(moving,u) end
		table.sort(moving,function(a: Unit,b: Unit): boolean
			if a.faction~=b.faction then return a.faction<b.faction end
			if a.position.X~=b.position.X then return if a.faction=="Human" then a.position.X>b.position.X else a.position.X<b.position.X end
			return a.instanceId<b.instanceId
		end)
		for _,unit in moving do
			local id=unit.instanceId
			if unit.model.Parent~=active then api.RemoveUnit(id); continue end
			if unit.state=="Dead" then if clock()>=(unit.removeAt :: number) then api.RemoveUnit(id) end; continue end
			if (unit.model:GetPivot().Position-unit.position).Magnitude>.05 then corrections+=1 end
			local before=unit.position; local budget=unit.speed*dt
            -- A front melee fighter makes room along the same attack circle when allies arrive.
            -- The circle is convex: this short reposition never exceeds the existing attack range.
            if unit.state=="Attacking" and unit.stats.attackRangeStuds<=3 and not unit.reachedCastle and unit.combatTarget then
                local needsRoom=false;local direction=if unit.faction=="Human" then 1 else -1
                for _,ally in moving do
                    local behind=direction*(unit.position.X-ally.position.X)
                    if ally.hp>0 and ally.faction==unit.faction and ally.laneId==unit.laneId and ally.state=="Moving" and behind>0 and behind<Navigation.allyLookahead then needsRoom=true;break end
                end
                if needsRoom then
                    local roadZ=MapConfig.origin.Z+(if unit.laneId=="Upper" then -20 else 20)
                    local extent=math.abs(unit.facing.X)*unit.width/2+math.abs(unit.facing.Z)*unit.depth/2
                    local best=math.huge;local goal: Vector3?=nil
                    for _,degrees in Navigation.meleeYieldAngles do
                        local angle=math.rad(degrees);local r=unit.stats.attackRangeStuds-Navigation.meleeSlotInset
                        local slot=(unit.combatTarget :: Vector3)+Vector3.new(-direction*math.cos(angle)*r,0,math.sin(angle)*r)
                        if math.abs(slot.Z-roadZ)+extent< MapConfig.laneWidth/2-Navigation.friendlyGap and free(slot,unit.radius,unit.bodyRadius,unit.height,unit.faction,id,unit.facing,unit.width,unit.depth) then
                            local distance=(slot-unit.position).Magnitude
                            if distance<best then best=distance;goal=slot end
                        end
                    end
                    if goal and best>.001 then
                        local step=math.min(best,budget,Navigation.maxMovementSlice);local candidate=unit.position+((goal :: Vector3)-unit.position).Unit*step
                        if free(candidate,unit.radius,unit.bodyRadius,unit.height,unit.faction,id,unit.facing,unit.width,unit.depth) then unit.position=candidate;budget-=step end
                    end
                end
            end
			while unit.state=="Moving" and budget>0 do
				local target=unit.path[unit.nextPoint]
				if not target then unit.state="WaitingAtCastle"; break end
                local direction=if unit.faction=="Human" then 1 else -1
                local roadZ=MapConfig.origin.Z+(if unit.laneId=="Upper" then -20 else 20)
                local onRoad=unit.nextPoint>=2 and math.abs(unit.position.X)<=96.01 and math.abs(target.X)<=96.01
                local aim=target
                local maxOffset=math.max(0,MapConfig.laneWidth/2-unit.width/2-Navigation.friendlyGap)
                if onRoad then
                    local desired=roadZ+math.clamp(unit.laneOffset,-maxOffset,maxOffset)
                    -- Navigation approaches an opponent; CombatService alone selects attack targets.
                    local enemyDistance=Navigation.enemyApproachLookahead;local enemy: Unit?=nil
                    for _,other in moving do
                        local ahead=direction*(other.position.X-unit.position.X)
                        local d=(other.position-unit.position).Magnitude
                        if other.hp>0 and other.faction~=unit.faction and other.laneId==unit.laneId and ahead>=0 and d<enemyDistance then
                            desired=other.position.Z;enemyDistance=d;enemy=other
                        end
                    end
                    local nearest=math.huge
                    for _,other in moving do
                        local ahead=direction*(other.position.X-unit.position.X)
                        if other.hp>0 and other.faction==unit.faction and other.laneId==unit.laneId and other.instanceId~=id
                            and ahead>0 and ahead<Navigation.allyLookahead and ahead<nearest and math.abs(desired-other.position.Z)<(unit.width+other.width)/2+Navigation.friendlyGap then
                            nearest=ahead
                            unit.laneOffset=if other.position.Z<=roadZ then maxOffset else -maxOffset
                            desired=roadZ+unit.laneOffset
                        end
                    end
                    aim=Vector3.new(target.X,target.Y,math.clamp(desired,roadZ-maxOffset,roadZ+maxOffset))
                    if enemy and unit.stats.attackRangeStuds<=3 then
                        local best=math.huge;local enemyPosition=enemy.position
                        for _,degrees in Navigation.meleeSlotAngles do
                            local angle=math.rad(degrees);local r=unit.stats.attackRangeStuds-Navigation.meleeSlotInset
                            local slot=enemyPosition+Vector3.new(-direction*math.cos(angle)*r,0,math.sin(angle)*r)
                            if math.abs(slot.Z-roadZ)<=maxOffset and direction*(slot.X-unit.position.X)>=-.05
                                and free(slot,unit.radius,unit.bodyRadius,unit.height,unit.faction,id,Vector3.new(direction,0,0),unit.width,unit.depth) then
                                local score=(slot-unit.position).Magnitude
                                if score<best then best=score;aim=slot end
                            end
                        end
                    end
                end
                local delta=aim-unit.position;local distance=delta.Magnitude
                if distance<.001 then
                    if not onRoad or direction*(unit.position.X-target.X)>=-.001 then unit.nextPoint+=1;continue end
                    break -- A temporary combat approach slot is not a completed waypoint.
                end
                local facing=if onRoad then Vector3.new(direction,0,0) else delta.Unit
                local step=math.min(distance,budget,Navigation.maxMovementSlice)
                local function allowed(candidate: Vector3): boolean
                    if onRoad and math.abs(candidate.Z-roadZ)>maxOffset+.001 then return false end
                    local hit=if map then workspace:Raycast(unit.position+Vector3.new(0,1.5,0),candidate-unit.position,rayParams) else nil
                    return not (hit and hit.Instance.CanCollide and math.abs(hit.Normal.Y)<.5)
                        and free(candidate,unit.radius,unit.bodyRadius,unit.height,unit.faction,id,facing,unit.width,unit.depth)
                end
                local candidate=unit.position+delta.Unit*step
                if not allowed(candidate) then
                    -- Bounded sidestep around a stationary ally, using the same movement budget.
                    local lateral=Vector3.new(0,0,aim.Z-unit.position.Z)
                    if not onRoad or lateral.Magnitude<.01 then blockedMoves+=1;break end
                    step=math.min(lateral.Magnitude,budget,Navigation.maxMovementSlice)
                    candidate=unit.position+lateral.Unit*step
                    if not allowed(candidate) then blockedMoves+=1;break end
                end
                unit.facing=facing;unit.position=candidate;budget-=step
                if (onRoad and direction*(unit.position.X-target.X)>=-.001) or (not onRoad and (unit.position-target).Magnitude<.001) then unit.nextPoint+=1 end
			end
			if unit.nextPoint>#unit.path then unit.reachedCastle=true; if unit.state~="Attacking" then unit.state="WaitingAtCastle" end end
			assert((unit.position-before).Magnitude<=unit.speed*dt+.01,"E_MOVEMENT_BUDGET")
			local pose=CFrame.lookAt(unit.position,unit.position+unit.facing); unit.model:PivotTo(pose)
			unit.publishElapsed+=dt
			if unit.publishElapsed>=1/Visual.snapshotHz or unit.model:GetAttribute("State")~=unit.state then
				unit.publishElapsed=0; unit.model:SetAttribute("MovementCFrame",pose); unit.model:SetAttribute("State",unit.state)
			end
		end
		local now=clock()
		for _,id in order do
			local schedule=schedules[id]
			local due=if schedule.lastAttemptAt then schedule.lastAttemptAt+(schedule.stats.spawnIntervalSeconds :: number) else schedule.firstAt
			if now<due then continue end
			schedule.lastAttemptAt=now -- Skip missed slots, never catch up with an unbounded burst.
			if counts[schedule.record.faction]>=Config.maxLivingUnitsPerSide then skipped+=1; continue end
			local ok,failure=pcall(function(): boolean spawn(schedule); return true end)
			if not ok then
				errors+=1
				if not schedule.errorReported then schedule.errorReported=true; warn("[UnitService] spawn failed: "..tostring(failure)) end
			end
		end
	end
	return table.freeze(api)
end
return table.freeze(UnitService)
