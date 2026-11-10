--!strict
local Config=require(game.ReplicatedStorage.CastleFightShared.Config.LobbyConfig)
local Queue=require(script.Parent.LobbyQueue)
local Policy=require(script.Parent.LobbyPolicy)
local Economy=require(script.Parent.EconomyService)
local Match=require(script.Parent.MatchService)
local GameConfig=require(game.ReplicatedStorage.CastleFightShared.Config.GameConfig)
local Tests={}
function Tests.Run(): any
 assert(game:GetService("RunService"):IsStudio(),"E_STUDIO_ONLY")
 local names={};local function check(name: string,value: boolean): () assert(value,"FAIL:"..name);table.insert(names,name) end
 check("bot genuinely unavailable",not Config.modes.Bot.available)
 check("duel server-local enabled",Config.modes.Duel.available)
 check("future modes unavailable",not Config.modes.Teams.available and not Config.modes.Arena.available)
 local ok,code=Policy.Validate("Duel",Vector3.zero,Vector3.zero,true,"Lobby");check("near living lobby character valid",ok and code=="OK")
 ok,code=Policy.Validate("Duel",Vector3.new(0,0,12),Vector3.zero,true,"Lobby");check("distant request rejected",not ok and code=="TooFar")
 ok=Policy.Validate("Duel",Vector3.new(0,12,0),Vector3.zero,true,"Lobby");check("vertical distance validated",not ok)
 ok=Policy.Validate("Duel",nil,Vector3.zero,true,"Lobby");check("missing root rejected",not ok)
 ok=Policy.Validate("Duel",Vector3.zero,Vector3.zero,false,"Lobby");check("dead character rejected",not ok)
 ok=Policy.Validate("Duel",Vector3.zero,Vector3.zero,true,"Match");check("match participant cannot re-enter",not ok)
 ok=Policy.Validate("Duel",Vector3.zero,Vector3.zero,true,"Transition");check("transition cannot restart",not ok)
 ok=Policy.Validate("InjectedMode",Vector3.zero,Vector3.zero,true,"Lobby");check("unknown mode rejected",not ok)
 local ready: {[number]:boolean}={[1]=true,[2]=true,[3]=true};local starts=0
 local economy=Economy.new(GameConfig,function(_: Economy.Faction,_: number): () end)
 local match=Match.new(economy,function(_: Match.Status,_: number): () end)
 local queue=Queue.new(function(id: number): boolean return ready[id]==true end,function(a: number,b: number): boolean
  starts+=1;assert(a==1 and b==2,"FIFO roster");return match.Start()
 end)
 ok,code=queue.Join(1);check("first player really queued",ok and code=="Queued" and #queue.Snapshot().waiting==1 and match.GetStatus()=="Waiting")
 ok,code=queue.Join(1);check("duplicate queue entry refused",not ok and code=="AlreadyQueued" and #queue.Snapshot().waiting==1)
 ok,code=queue.Join(2);check("two real entries start existing MatchService",ok and code=="Started" and match.GetStatus()=="InProgress" and starts==1)
 check("single active roster",#queue.Snapshot().active==2 and #queue.Snapshot().waiting==0)
 ok,code=queue.Join(3);check("occupied arena refuses another match",not ok and code=="Busy" and starts==1)
 check("active removal reports cancellation need",queue.Remove(1));match.Finish(nil,"ParticipantLeft");queue.Finish()
 check("finish clears active queue",#queue.Snapshot().active==0 and #queue.Snapshot().waiting==0)
 ok=queue.Join(1);check("new match accepts fresh queue",ok)
 check("queued cancel succeeds",queue.Cancel(1));check("duplicate cancel harmless",not queue.Cancel(1))
 ready[3]=false;ok,code=queue.Join(3);check("unready player cannot join",not ok and code=="NotReady")
 local failed=Queue.new(function(_: number): boolean return true end,function(_: number,_: number): boolean return false end)
 failed.Join(1);ok,code=failed.Join(2);check("failed start not reported successful",not ok and code=="StartFailed")
 check("failed transition cleans queue",#failed.Snapshot().active==0 and #failed.Snapshot().waiting==0)
 local stale=Queue.new(function(id: number): boolean return ready[id]==true end,function(_: number,_: number): boolean return true end)
 stale.Join(1);ready[1]=false;stale.Join(2);check("disconnected stale entry pruned",#stale.Snapshot().waiting==1 and stale.Snapshot().waiting[1]==2)
 local reentrant: Queue.Service?=nil;local reentryBlocked=false
 reentrant=Queue.new(function(_: number): boolean return true end,function(_: number,_: number): boolean local q=reentrant;assert(q);local success,result=q.Join(3);reentryBlocked=not success and result=="Busy";return true end)
 assert(reentrant)
 reentrant.Join(1);reentrant.Join(2);check("reentrant start cannot duplicate transition",reentryBlocked)
 local snapshot=reentrant.Snapshot();table.clear(snapshot.active);check("snapshot cannot mutate private roster",#reentrant.Snapshot().active==2)
 local lobby=workspace:FindFirstChild(Config.modelName);assert(lobby and lobby:IsA("Model"))
 check("lobby is separate from arena",not lobby:IsDescendantOf(workspace.Map) and (Config.origin-workspace.Map:GetPivot().Position).Magnitude>300)
 local spawn=lobby:FindFirstChild("LobbySpawn");check("neutral lobby spawn enabled",spawn~=nil and spawn:IsA("SpawnLocation") and spawn.Enabled and spawn.Neutral)
 local portalFolder=lobby:FindFirstChild("Portals");assert(portalFolder)
 check("four unique portals",#portalFolder:GetChildren()==4)
 for _,id in Config.modeOrder do
  local portal=portalFolder:FindFirstChild(id);assert(portal)
  local anchor=portal:FindFirstChild("Interaction");assert(anchor and anchor:IsA("BasePart"))
  local prompt=anchor:FindFirstChildOfClass("ProximityPrompt");assert(prompt)
  check("physical interaction "..id,prompt.MaxActivationDistance==Config.promptDistance and prompt.KeyboardKeyCode==Enum.KeyCode.E)
  check("touch and gamepad interaction "..id,prompt.ClickablePrompt and prompt.GamepadKeyCode==Enum.KeyCode.ButtonX)
 end
 local parts=0;local anchored=true;local scripts=0
 for _,obj in lobby:GetDescendants() do if obj:IsA("BasePart") then parts+=1;anchored=anchored and obj.Anchored elseif obj:IsA("LuaSourceContainer") then scripts+=1 end end
 check("substantial decorated courtyard",parts>=800);check("geometry anchored",anchored);check("no scripts embedded in geometry",scripts==0)
 local outsideSpawns=0;for _,obj in workspace:GetDescendants() do if obj:IsA("SpawnLocation") and obj.Enabled and not obj:IsDescendantOf(lobby) then outsideSpawns+=1 end end
 check("no enabled arena spawn",outsideSpawns==0)
 local parameters=RaycastParams.new();parameters.FilterType=Enum.RaycastFilterType.Include;parameters.FilterDescendantsInstances={lobby};parameters.RespectCanCollide=true
 local hit=workspace:Raycast(Config.origin+Config.spawnOffset+Vector3.new(0,5,0),Vector3.new(0,-20,0),parameters)
 check("spawn has safe collision floor",hit~=nil and hit.Instance.CanCollide)
 return {passed=#names,names=names,parts=parts,portals=4,localMatchStarts=starts}
end
return table.freeze(Tests)
