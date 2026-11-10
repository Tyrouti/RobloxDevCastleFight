--!strict
-- Cosmetic only. Server attributes reconstruct active effects for late joins; the existing event flashes refreshes.
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Debris=game:GetService("Debris")
type Visual={part: Part,emitter: ParticleEmitter,tween: Tween?,height: number}
local Visuals={};local started=false
function Visuals.Start(): ()
 if started then return end;started=true
 local state=ReplicatedStorage:WaitForChild("CastleFightState")
 local units=workspace:WaitForChild("ActiveUnits")
 local remote=ReplicatedStorage:WaitForChild("CastleFightCombatRemotes"):WaitForChild("Effect") :: RemoteEvent
 local root=Instance.new("Folder");root.Name="CastleFightLocalStatusFX";root.Parent=workspace
 local records: {[Model]:{[string]:Visual}}={};local pending: {[Model]:{[string]:boolean}}={}
 local function clear(model: Model,kind: string): ()
  local row=records[model];local v=if row then row[kind] else nil;if not v then return end
  if v.tween then v.tween:Cancel() end
  v.emitter.Enabled=false;v.emitter:Clear()
  TweenService:Create(v.part,TweenInfo.new(.15),{Transparency=1,Size=v.part.Size*.85}):Play();Debris:AddItem(v.part,.2)
  row[kind]=nil;if next(row)==nil then records[model]=nil end
 end
 local function clearAll(): ()
  for model,row in records do for kind in row do clear(model,kind) end end;table.clear(pending)
 end
 local function create(model: Model,kind: string): Visual
  local p=Instance.new("Part");p.Name=kind;p.Shape=Enum.PartType.Ball;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  p.Material=if kind=="Shield" then Enum.Material.SmoothPlastic else Enum.Material.Neon
  p.Color=if kind=="Shield" then Color3.fromRGB(80,205,255) elseif kind=="Curse" then Color3.fromRGB(180,65,240) else Color3.fromRGB(86,235,142)
  p:SetAttribute("UnitInstanceId",model:GetAttribute("UnitInstanceId"))
  local _,size=model:GetBoundingBox()
  local diameter=if kind=="Shield" then math.max(size.X,size.Y,size.Z)+1 else math.max(size.X,size.Z)+.5
  p.Size=Vector3.one*diameter
  p.Transparency=if kind=="Shield" then .78 else .9;p.CFrame=model:GetPivot()+Vector3.new(0,size.Y/2,0);p.Parent=root
  local a=Instance.new("Attachment");a.Parent=p
  local e=Instance.new("ParticleEmitter");e.Name="Aura";e.Color=ColorSequence.new(p.Color,if kind=="DamageOverTime" then Color3.fromRGB(157,83,219) else p.Color)
  e.Texture="rbxasset://textures/particles/sparkles_main.dds";e.LightEmission=.8;e.Lifetime=NumberRange.new(.4,.8);e.Speed=NumberRange.new(.3,1)
  e.SpreadAngle=Vector2.new(180,180);e.Rate=if kind=="Shield" then 2 else 8
  e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.22),NumberSequenceKeypoint.new(1,0)})
  e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(1,1)});e.Parent=a
  local v: Visual={part=p,emitter=e,tween=nil,height=size.Y};return v
 end
 local connections: {RBXScriptConnection}={}
 table.insert(connections,remote.OnClientEvent:Connect(function(message: any): ()
  if typeof(message)~="table" or message.kind~="StatusEffect" then return end
  local model=message.targetModel;local kind=message.effect
  if typeof(model)~="Instance" or not model:IsA("Model") or (kind~="Shield" and kind~="Curse" and kind~="DamageOverTime") then return end
  if message.action=="Applied" or message.action=="Updated" then
   pending[model]=pending[model] or {};pending[model][kind]=true
  else clear(model,kind);local row=pending[model];if row then row[kind]=nil end end
 end))
 table.insert(connections,state:GetAttributeChangedSignal("MatchStatus"):Connect(function(): () if state:GetAttribute("MatchStatus")~="InProgress" then clearAll() end end))
 table.insert(connections,RunService.RenderStepped:Connect(function(): ()
  if state:GetAttribute("MatchStatus")~="InProgress" then return end
  local present: {[Model]:boolean}={};local now=workspace:GetServerTimeNow()
  for _,obj in units:GetChildren() do
   if not obj:IsA("Model") or (obj:GetAttribute("HP") or 0)<=0 then continue end
   present[obj]=true
   for _,kind in {"Shield","Curse","DamageOverTime"} do
    local expires=obj:GetAttribute("Effect"..kind)
    if typeof(expires)~="number" or expires<=now then clear(obj,kind);continue end
    local row=records[obj] or {};records[obj]=row;local v=row[kind]
    if not v then v=create(obj,kind);row[kind]=v end
    local pulse=pending[obj]
    if pulse and pulse[kind] then
     pulse[kind]=nil;v.emitter:Emit(10)
     if v.tween then v.tween:Cancel() end
     v.part.Transparency=.3;v.tween=TweenService:Create(v.part,TweenInfo.new(.3),{Transparency=if kind=="Shield" then .78 else .9});v.tween:Play()
    end
    v.part.CFrame=obj:GetPivot()+Vector3.new(0,v.height/2,0)
   end
  end
  for model,row in records do if not present[model] then for kind in row do clear(model,kind) end end end
  for model in pending do if not present[model] then pending[model]=nil end end
  root:SetAttribute("ActiveVisuals",#root:GetChildren())
 end))
 table.insert(connections,script.Destroying:Connect(function(): () for _,c in connections do c:Disconnect() end;clearAll();root:Destroy() end))
end
return table.freeze(Visuals)
