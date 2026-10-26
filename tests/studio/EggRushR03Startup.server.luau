--!nonstrict
local started=DateTime.now().UnixTimestampMillis
script:SetAttribute("ServerEnteredUnixMs",started)
script:SetAttribute("ServerGameTime",time())
local function character(character)
 local root=character:WaitForChild("HumanoidRootPart",30)
 if root then script:SetAttribute("CharacterRootUnixMs",DateTime.now().UnixTimestampMillis) end
end
local function player(player)
 script:SetAttribute("PlayerUnixMs",DateTime.now().UnixTimestampMillis)
 player.CharacterAdded:Connect(character)
 if player.Character then task.spawn(character,player.Character) end
end
game.Players.PlayerAdded:Connect(player)
for _,p in game.Players:GetPlayers() do task.spawn(player,p) end
game:GetService("RunService").Heartbeat:Once(function() script:SetAttribute("FirstServerHeartbeatUnixMs",DateTime.now().UnixTimestampMillis) end)
