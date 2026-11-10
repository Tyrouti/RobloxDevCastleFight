--!strict
local Players=game:GetService("Players")
local Prompts=game:GetService("ProximityPromptService")
local RunService=game:GetService("RunService")
local Controller={};local started=false
function Controller.Start(): ()
 if started then return end;started=true
 local state=game.ReplicatedStorage:WaitForChild("CastleFightState");if state:GetAttribute("LobbyEnabled")~=true then return end
 local player=Players.LocalPlayer;local playerGui=player:WaitForChild("PlayerGui")
 local cancel=game.ReplicatedStorage:WaitForChild("CastleFightLobbyRemotes"):WaitForChild("CancelQueue") :: RemoteEvent
 local lobby=workspace:WaitForChild("Lobby23");local near: string?=nil;local currentPrompt: ProximityPrompt?=nil;local holding=false
 local view=require(script.Parent.LobbyUI).Create(player,function(): () cancel:FireServer() end,function(): ()
  local prompt=currentPrompt;if not prompt or holding or player:GetAttribute("CastleFightLocation")~="Lobby" then return end
  holding=true;prompt:InputHoldBegin()
  task.delay(prompt.HoldDuration+.05,function(): () if prompt.Parent then prompt:InputHoldEnd() end;holding=false end)
 end)
 local combatNames={CastleFightCastleHud=true,CastleFightEconomyHud=true,CastleFightBuildMenu=true}
 local function render(): ()
  local location=player:GetAttribute("CastleFightLocation") or "Lobby"
  for _,gui in playerGui:GetChildren() do if gui:IsA("ScreenGui") and combatNames[gui.Name] then gui.Enabled=location=="Match" end end
  view.Render(location :: string,(player:GetAttribute("LobbyStatus") or "Idle") :: string,(player:GetAttribute("LobbyMode") or "") :: string,(state:GetAttribute("LobbyQueueCount") or 0) :: number,near)
 end
 local connections: {RBXScriptConnection}={}
 for _,attr in {"CastleFightLocation","LobbyStatus","LobbyMode"} do table.insert(connections,player:GetAttributeChangedSignal(attr):Connect(render)) end
 table.insert(connections,state:GetAttributeChangedSignal("LobbyQueueCount"):Connect(render));table.insert(connections,playerGui.ChildAdded:Connect(render))
 table.insert(connections,Prompts.PromptShown:Connect(function(prompt: ProximityPrompt): ()
  if prompt:IsDescendantOf(lobby) and prompt.Parent and prompt.Parent.Parent then near=prompt.Parent.Parent.Name;currentPrompt=prompt;render() end
 end))
 table.insert(connections,Prompts.PromptHidden:Connect(function(prompt: ProximityPrompt): () if currentPrompt==prompt then near=nil;currentPrompt=nil;render() end end))
 local cores: {[BasePart]:number}={};for _,obj in lobby:GetDescendants() do if obj:IsA("BasePart") and obj.Name=="PortalCore" then cores[obj]=obj.Transparency end end
 table.insert(connections,RunService.RenderStepped:Connect(function(): ()
  if player:GetAttribute("CastleFightLocation")=="Match" then return end
  local t=os.clock();for part,base in cores do if part.Parent then part.Transparency=base+math.sin(t*1.3)*.06 end end
 end))
 view.gui.Destroying:Connect(function(): () for _,connection in connections do connection:Disconnect() end end)
 render()
end
return table.freeze(Controller)
