--!strict
-- Client assertions against actual replicated state and actual rendered UI; no synthetic HP.
local Tests={}
local function child(parent: Instance,name: string): Instance local o=parent:FindFirstChild(name);assert(o,"Missing "..name);return o end
function Tests.Check(): {passed: number,viewport: Vector2,matchId: any,panels: {any}}
 local player=game:GetService("Players").LocalPlayer
 local gui=child(player.PlayerGui,"CastleFightCastleHud") :: ScreenGui
 local safe=child(gui,"SafeCanvas") :: Frame;local root=child(safe,"Root") :: Frame
 local state=child(game:GetService("ReplicatedStorage"),"CastleFightState");local castles=child(state,"Castles")
 local passed=0;local rows={}
 local function check(ok: boolean,label: string): () assert(ok,label);passed+=1 end
 check(gui.ScreenInsets==Enum.ScreenInsets.CoreUISafeInsets and gui.ClipToDeviceSafeArea,"safe insets")
 check(root.AbsolutePosition.X>=safe.AbsolutePosition.X and root.AbsolutePosition.X+root.AbsoluteSize.X<=safe.AbsolutePosition.X+safe.AbsoluteSize.X+1,"fits safe width")
 local human=child(root,"Human") :: Frame;local undead=child(root,"Undead") :: Frame
 check(human.AbsolutePosition.X+human.AbsoluteSize.X<undead.AbsolutePosition.X,"faction panels separated")
 for _,faction in {"Human","Undead"} do
  local panel=child(root,faction) :: Frame;local record=child(castles,faction)
  local hp=record:GetAttribute("HP");local maximum=record:GetAttribute("MaxHP");assert(typeof(hp)=="number" and typeof(maximum)=="number")
  check(panel:GetAttribute("DisplayedHP")==hp and panel:GetAttribute("DisplayedMaxHP")==maximum,"HUD matches replicated HP")
  local text=child(panel,"Health") :: TextLabel;check(text.TextFits,"HP numbers fit")
  check(panel:GetAttribute("Destroyed")== (hp<=0),"destruction display")
  check(panel:GetAttribute("Critical")== (hp>0 and hp/maximum<=.25),"critical state")
  table.insert(rows,{faction=faction,hp=hp,maxHP=maximum,text=text.Text,critical=panel:GetAttribute("Critical"),destroyed=panel:GetAttribute("Destroyed"),position=panel.AbsolutePosition,size=panel.AbsoluteSize})
 end
 for _,o in player.PlayerGui:GetDescendants() do if o:IsA("BillboardGui") and string.find(o.Name,"Castle") then check(not o.Enabled,"old billboard disabled") end end
 return {passed=passed,viewport=workspace.CurrentCamera.ViewportSize,matchId=state:GetAttribute("MatchId"),panels=rows}
end
return table.freeze(Tests)
