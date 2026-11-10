--!strict
local Config=require(game.ReplicatedStorage.CastleFightShared.Config.UnitNavigation)
local Geometry={}
export type Size={radius: number,bodyRadius: number,height: number,depth: number,width: number}
export type Bounds={cf: CFrame,size: Vector3}
function Geometry.ReadBounds(model: Model): Bounds local cf,size=model:GetBoundingBox();return {cf=cf,size=size} end
function Geometry.Measure(model: Model): Size
 local _,bounds=model:GetBoundingBox()
 local torso=model:FindFirstChild("Torso",true)
 local body=if torso and torso:IsA("BasePart") then math.max(torso.Size.X,torso.Size.Z)/2 else math.min(bounds.X,bounds.Z)/2
 return {radius=Vector2.new(bounds.X,bounds.Z).Magnitude/2,bodyRadius=body,height=bounds.Y,depth=bounds.Z,width=bounds.X}
end
-- SAT on horizontal oriented bounding rectangles. Includes weapons, not just torsos.
function Geometry.Overlap(a: Vector3,af: Vector3,aw: number,ad: number,b: Vector3,bf: Vector3,bw: number,bd: number,gap: number): boolean
 local ar=Vector3.new(-af.Z,0,af.X);local br=Vector3.new(-bf.Z,0,bf.X);local delta=b-a
 for _,axis in {af,ar,bf,br} do
  local ra=math.abs(axis:Dot(ar))*aw/2+math.abs(axis:Dot(af))*ad/2
  local rb=math.abs(axis:Dot(br))*bw/2+math.abs(axis:Dot(bf))*bd/2
  if math.abs(delta:Dot(axis))>=ra+rb+gap-.001 then return false end
 end
 return true
end
function Geometry.Start(building: Model,pad: BasePart,size: Size): Vector3
 local anchor=building:FindFirstChild("UnitSpawn",true);assert(anchor and anchor:IsA("Attachment"),"E_BUILDING_UNIT_SPAWN")
 local p=anchor.WorldPosition+anchor.WorldCFrame.LookVector*(size.radius+Config.spawnClearance)
 return Vector3.new(p.X,pad.Position.Y,p.Z)
end
function Geometry.IntersectsBuilding(position: Vector3,radius: number,height: number,building: Model): boolean
 return Geometry.IntersectsBounds(position,radius,height,Geometry.ReadBounds(building))
end
function Geometry.IntersectsBounds(position: Vector3,radius: number,height: number,bounds: Bounds): boolean
 local cf=bounds.cf;local size=bounds.size;local localP=cf:PointToObjectSpace(position)
 local x=math.max(math.abs(localP.X)-size.X/2,0);local z=math.max(math.abs(localP.Z)-size.Z/2,0)
 return Vector2.new(x,z).Magnitude<radius and position.Y<cf.Y+size.Y/2-.1 and position.Y+height>cf.Y-size.Y/2+.1
end
return table.freeze(Geometry)
