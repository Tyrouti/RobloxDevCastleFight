--!strict
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage.CastleFightShared.Config.LobbyConfig)
local Queue=require(script.Parent.LobbyQueue)
local Policy=require(script.Parent.LobbyPolicy)
local Match=require(script.Parent.MatchService)
type Record={phase: string,status: string,mode: string,lastRequest: number,ticket: number,characterConnection: RBXScriptConnection?}
export type Service={Request: (Player,string) -> (boolean,string),Cancel: (Player) -> (),Admit: ({Player}) -> (),MatchEnded: () -> (),Destroy: () -> (),Snapshot: () -> any}
local Lobby={}
function Lobby.new(model: Model,state: Folder,match: Match.Match,startPair: (Player,Player) -> boolean): Service
 assert(model:GetAttribute("SystemOwner")=="CastleFightLobby23","E_LOBBY_OWNER")
 local spawn=model:FindFirstChild("LobbySpawn");assert(spawn and spawn:IsA("SpawnLocation"),"E_LOBBY_SPAWN")
 local records: {[Player]:Record}={};local members: {[number]:string}={};local connections: {RBXScriptConnection}={};local stopped=false
 local remotes=Instance.new("Folder");remotes.Name="CastleFightLobbyRemotes"
 local cancel=Instance.new("RemoteEvent");cancel.Name="CancelQueue";cancel.Parent=remotes;remotes.Parent=game.ReplicatedStorage
 local api={} :: Service
 local function ready(id: number): boolean
  local p=Players:GetPlayerByUserId(id);local r=if p then records[p] else nil;local h=if p and p.Character then p.Character:FindFirstChildOfClass("Humanoid") else nil
  local root=if p and p.Character then p.Character:FindFirstChild("HumanoidRootPart") else nil
  return p~=nil and r~=nil and r.phase=="Lobby" and h~=nil and h.Health>0 and root~=nil and root:IsA("BasePart")
 end
 local queue=Queue.new(ready,function(a: number,b: number): boolean
  local first=Players:GetPlayerByUserId(a);local second=Players:GetPlayerByUserId(b);if not first or not second then return false end
  return startPair(first,second)
 end)
 local function publish(player: Player): ()
  local r=records[player];if not r then return end
  player:SetAttribute("CastleFightLocation",r.phase);player:SetAttribute("LobbyStatus",r.status);player:SetAttribute("LobbyMode",r.mode)
  state:SetAttribute("LobbyQueueCount",#queue.Snapshot().waiting)
 end
 local function place(player: Player,character: Model): ()
  local root=character:WaitForChild("HumanoidRootPart",10)
  if stopped or not root or player.Character~=character or not records[player] then return end
  local r=records[player];local faction=members[player.UserId]
  if faction and match.GetStatus()=="InProgress" then
   local position=if faction=="Human" then Config.humanArenaSpawn else Config.undeadArenaSpawn
   character:PivotTo(CFrame.lookAt(position,position+Vector3.new(if faction=="Human" then 1 else -1,0,0)))
   r.phase="Match";r.status="Match"
  else character:PivotTo(CFrame.lookAt(Config.origin+Config.spawnOffset,Config.origin+Vector3.new(0,3.5,0)));r.phase="Lobby" end
  if root:IsA("BasePart") then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
  publish(player)
 end
 function api.Admit(roster: {Player}): ()
  for index,player in roster do
   local r=records[player];if not r then continue end
   members[player.UserId]=if index==1 then "Human" else "Undead"
   r.phase="Transition";r.status="Transition";r.mode="Duel";r.ticket+=1;local ticket=r.ticket;publish(player)
   task.delay(Config.transitionSeconds,function(): () if not stopped and records[player]==r and r.ticket==ticket and match.GetStatus()=="InProgress" and player.Character then place(player,player.Character) end end)
  end
 end
 function api.Request(player: Player,mode: string): (boolean,string)
  local r=records[player];if not r or player.Parent~=Players then return false,"NotReady" end
  if os.clock()-r.lastRequest<Config.requestCooldown then return false,"RateLimit" end;r.lastRequest=os.clock()
  local portals=model:FindFirstChild("Portals");local portal=if portals then portals:FindFirstChild(mode) else nil
  local anchor=portal and portal:FindFirstChild("Interaction");local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart");local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  local valid,code=Policy.Validate(mode,if root and root:IsA("BasePart") then root.Position else nil,if anchor and anchor:IsA("BasePart") then anchor.Position else nil,humanoid~=nil and humanoid.Health>0,r.phase)
  if not valid then return false,code end
  if r.mode~=mode then queue.Cancel(player.UserId) end;r.mode=mode
  if not Config.modes[mode].available then r.status="Unavailable";publish(player);return false,"Unavailable" end
  local ok,result=queue.Join(player.UserId)
  if result=="Started" then
   local ids=queue.Snapshot().active;local a=Players:GetPlayerByUserId(ids[1]);local b=Players:GetPlayerByUserId(ids[2]);if a and b then api.Admit({a,b}) end
  elseif result=="Queued" or result=="AlreadyQueued" then r.status="Queued";publish(player)
  else r.status=result;publish(player) end
  local waiting=queue.Snapshot().waiting
  for other,record in records do if record.phase=="Lobby" and record.status=="Queued" and not table.find(waiting,other.UserId) then record.status=if result=="StartFailed" then "StartFailed" else "Idle";publish(other) end end
  state:SetAttribute("LobbyQueueCount",#queue.Snapshot().waiting)
  return ok,result
 end
 function api.Cancel(player: Player): ()
  local r=records[player];if not r or r.phase~="Lobby" then return end
  queue.Cancel(player.UserId);r.status="Idle";publish(player)
 end
 function api.MatchEnded(): ()
  local returning=table.clone(members);queue.Finish();table.clear(members)
  for player,r in records do
   if not returning[player.UserId] and r.phase=="Lobby" then if r.status=="Queued" or r.status=="Busy" or r.status=="StartFailed" then r.status="Idle";publish(player) end;continue end
   r.ticket+=1;r.phase="Transition";r.status="Returning";local ticket=r.ticket;publish(player)
   task.delay(Config.transitionSeconds,function(): ()
    if not stopped and records[player]==r and r.ticket==ticket then r.phase="Lobby";r.status="Idle";if player.Character then place(player,player.Character) else publish(player) end end
   end)
  end
 end
 local function add(player: Player): ()
  if records[player] then return end
  local r: Record={phase="Lobby",status="Idle",mode="",lastRequest=-math.huge,ticket=0,characterConnection=nil};records[player]=r;player.RespawnLocation=spawn
  publish(player)
  r.characterConnection=player.CharacterAdded:Connect(function(character: Model): ()
   if not members[player.UserId] then api.Cancel(player) end;task.spawn(place,player,character)
  end)
  if player.Character then task.spawn(place,player,player.Character) end
 end
 table.insert(connections,Players.PlayerAdded:Connect(add))
 table.insert(connections,Players.PlayerRemoving:Connect(function(player: Player): ()
  local r=records[player];if r and r.characterConnection then r.characterConnection:Disconnect() end;records[player]=nil
  local wasActive=queue.Remove(player.UserId) or members[player.UserId]~=nil;members[player.UserId]=nil
  if wasActive and match.GetStatus()=="InProgress" then match.Finish(nil,"ParticipantLeft") end
  state:SetAttribute("LobbyQueueCount",#queue.Snapshot().waiting)
 end))
 table.insert(connections,cancel.OnServerEvent:Connect(function(player: Player,...: any): () if select("#",...)==0 then api.Cancel(player) end end))
 for _,player in Players:GetPlayers() do add(player) end
 local portals=model:FindFirstChild("Portals");assert(portals)
 for _,portal in portals:GetChildren() do
  local anchor=portal:FindFirstChild("Interaction");local prompt=anchor and anchor:FindFirstChildOfClass("ProximityPrompt");assert(prompt,"E_LOBBY_PROMPT")
  table.insert(connections,prompt.Triggered:Connect(function(player: Player): () api.Request(player,portal.Name) end))
 end
 function api.Snapshot(): any
  local users={};for player,r in records do table.insert(users,{userId=player.UserId,phase=r.phase,status=r.status,mode=r.mode}) end
  return {queue=queue.Snapshot(),users=users}
 end
 function api.Destroy(): ()
  if stopped then return end;stopped=true;queue.Finish()
  for _,c in connections do c:Disconnect() end
  for _,r in records do if r.characterConnection then r.characterConnection:Disconnect() end end
  table.clear(records);table.clear(members);remotes:Destroy()
 end
 return table.freeze(api)
end
return table.freeze(Lobby)
