--!strict
local modes={
 Bot=table.freeze({title="1 VS BOT",available=false,status="COMING SOON",description="Solo battle · bot not available yet",position=Vector3.new(-53,0,-29),color=Color3.fromRGB(92,202,245)}),
 Duel=table.freeze({title="1 VS 1",available=true,status="LOCAL MATCH",description="Two players on this server · local matchmaking",position=Vector3.new(53,0,-29),color=Color3.fromRGB(183,119,239)}),
 Teams=table.freeze({title="2 VS 2",available=false,status="COMING SOON",description="Team battles · planned mode",position=Vector3.new(-76,0,34),color=Color3.fromRGB(121,154,169)}),
 Arena=table.freeze({title="ARENA",available=false,status="COMING SOON",description="New challenges · planned mode",position=Vector3.new(76,0,34),color=Color3.fromRGB(151,131,167)}),
}
return table.freeze({origin=Vector3.new(0,8,420),spawnOffset=Vector3.new(0,3.5,48),
 promptDistance=10,requestCooldown=.8,transitionSeconds=.35,modelName="Lobby23",modes=table.freeze(modes),
 modeOrder=table.freeze({"Bot","Duel","Teams","Arena"}),
 humanArenaSpawn=Vector3.new(-115,6,-144),undeadArenaSpawn=Vector3.new(115,6,-144)})
