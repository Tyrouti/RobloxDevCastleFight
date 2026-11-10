--!strict
-- One initial overview on spawn; afterwards Roblox's normal orbit/zoom and character controls remain active.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Camera={};local started=false
local function stateLobbyEnabled(): boolean
 local state=game.ReplicatedStorage:FindFirstChild("CastleFightState")
 return state~=nil and state:GetAttribute("LobbyEnabled")==true
end
function Camera.Start(): ()
 if started then return end;started=true
 local player=Players.LocalPlayer
 local normalMinimum=player.CameraMinZoomDistance
 local function overview(character: Model): ()
  local root=character:WaitForChild("HumanoidRootPart",10)
  if not root or not root:IsA("BasePart") then return end
  task.wait(.2)
  local camera=workspace.CurrentCamera;if not camera or character~=player.Character then return end
  local previousMaximum=player.CameraMaxZoomDistance
  local aspect=camera.ViewportSize.X/math.max(camera.ViewportSize.Y,1)
  local inLobby=player:GetAttribute("CastleFightLocation")~="Match" and stateLobbyEnabled()
  local offset=(if inLobby then Vector3.new(0,10,36) else Vector3.new(0,90,105))*math.max(1,.95/math.max(.45,aspect))
  local distance=offset.Magnitude
  player.CameraMaxZoomDistance=math.max(320,distance)
  player.CameraMinZoomDistance=distance
  RunService.RenderStepped:Wait()
  camera.CFrame=CFrame.lookAt(root.Position+offset,root.Position)
  RunService.RenderStepped:Wait()
  player.CameraMinZoomDistance=normalMinimum
  player.CameraMaxZoomDistance=if inLobby then 80 else math.max(previousMaximum,320)
 end
 player.CharacterAdded:Connect(function(c: Model): () task.spawn(overview,c) end)
 player:GetAttributeChangedSignal("CastleFightLocation"):Connect(function(): () if player.Character and player:GetAttribute("CastleFightLocation")~="Transition" then task.spawn(overview,player.Character) end end)
 if player.Character then task.spawn(overview,player.Character) end
end
return table.freeze(Camera)
