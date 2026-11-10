--!strict
local Config=require(game.ReplicatedStorage.CastleFightShared.Config.LobbyConfig)
local Policy={}
function Policy.Validate(mode: string,position: Vector3?,portal: Vector3?,alive: boolean,phase: string): (boolean,string)
 if not Config.modes[mode] then return false,"UnknownMode" end
 if phase~="Lobby" then return false,"Busy" end
 if not alive or not position or not portal then return false,"NotReady" end
 if (position-portal).Magnitude>Config.promptDistance+1 then return false,"TooFar" end
 return true,"OK"
end
return table.freeze(Policy)
