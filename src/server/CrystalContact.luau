--!strict
-- Functional boundary is the existing physical pedestal, never the common plaza.
local Config=require(game.ReplicatedStorage.CastleFightShared.Config.UnitNavigation)
local Contact={}
export type Zone={center: Vector3,radius: number,bottom: number,top: number}
function Contact.Read(castle: Model): Zone
 local art=castle:FindFirstChild("Sanctum17B");local base=art and art:FindFirstChild("Octave1")
 local keep=castle:FindFirstChild("Keep");assert(base and base:IsA("BasePart") and keep and keep:IsA("BasePart"),"E_CRYSTAL_PHYSICAL_BOUNDARY")
 local verticalExtent=(math.abs(base.CFrame.RightVector.Y)*base.Size.X+math.abs(base.CFrame.UpVector.Y)*base.Size.Y+math.abs(base.CFrame.LookVector.Y)*base.Size.Z)/2
 return {center=base.Position,radius=math.max(base.Size.X,base.Size.Y,base.Size.Z)/2,bottom=base.Position.Y-verticalExtent,top=keep.Position.Y+keep.Size.Y/2}
end
function Contact.Gap(zone: Zone,position: Vector3,radius: number,height: number): number
 local delta=Vector3.new(position.X-zone.center.X,0,position.Z-zone.center.Z)
 local horizontal=delta.Magnitude-zone.radius-radius
 local vertical=math.max(zone.bottom-(position.Y+height),position.Y-zone.top,0)
 return if vertical>0 then math.sqrt(math.max(horizontal,0)^2+vertical^2) else horizontal
end
function Contact.CanAttack(zone: Zone,position: Vector3,radius: number,height: number,faction: string,lane: string): boolean
 local gap=Contact.Gap(zone,position,radius,height)
 local ownApproach=if faction=="Human" then position.X<zone.center.X else position.X>zone.center.X
 local ownLane=if lane=="Upper" then position.Z<zone.center.Z else position.Z>zone.center.Z
 return ownApproach and ownLane and gap>=-Config.epsilon and gap<=Config.crystalContactGap+Config.epsilon
end
function Contact.Stop(zone: Zone,a: Vector3,b: Vector3,radius: number): Vector3
 -- First intersection of the final approach with the expanded pedestal boundary.
 local d=b-a;local lo=0;local hi=1
 assert(Contact.Gap(zone,a,radius,5)>Config.crystalContactGap,"E_APPROACH_START_INSIDE")
 for _=1,32 do local t=(lo+hi)/2;if Contact.Gap(zone,a+d*t,radius,5)>Config.crystalContactGap then lo=t else hi=t end end
 return a+d*((lo+hi)/2)
end
function Contact.Surface(zone: Zone,position: Vector3): Vector3
 local d=Vector3.new(position.X-zone.center.X,0,position.Z-zone.center.Z)
 return Vector3.new(zone.center.X,position.Y,zone.center.Z)+d.Unit*zone.radius
end
return table.freeze(Contact)
