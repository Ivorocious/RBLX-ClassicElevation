--!strict
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local RaceConfig = require(ReplicatedStorage.Config.RaceConfig)
local Delivery = {}
local retained = {}

function Delivery.Release(player)
	local model = retained[player]
	if model and model.Parent and model.ModelStreamingMode == Enum.ModelStreamingMode.PersistentPerPlayer then
		model:RemovePersistentPlayer(player)
	end
	retained[player] = nil
end

function Delivery.Prepare(player, preset)
	Delivery.Release(player)
	local lobby = workspace:FindFirstChild(RaceConfig.LobbyModelName)
	assert(lobby and lobby:IsA("Model"), "Lobby unavailable")
	local spawn = lobby:FindFirstChild(RaceConfig.LobbySpawnMarkerName)
	assert(spawn and spawn:IsA("BasePart"), "Lobby spawn unavailable")
	if lobby.ModelStreamingMode ~= Enum.ModelStreamingMode.Persistent then
		lobby.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
		lobby:AddPersistentPlayer(player)
		retained[player] = lobby
	end
	local count = 0
	for _, item in lobby:GetDescendants() do
		if item:IsA("BasePart") then count += 1 end
	end
	local bounds, size = lobby:GetBoundingBox()
	return {token=HttpService:GenerateGUID(false), lobby=lobby.Name, spawn=spawn.Name, position=spawn.Position,
		center=bounds.Position, size=size, partCount=count,
		delaySeconds=if RunService:IsStudio() and preset == "Slow lobby delivery" then 8 else 0,
		failOnce=RunService:IsStudio() and preset == "Lobby delivery failure"}
end

function Delivery.CanEnter(player, payload, session)
	if session.phase ~= "Entering" or not session.delivery or payload.token ~= session.delivery.token then return false end
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	return root ~= nil and humanoid ~= nil and humanoid.Health > 0
		and (root.Position-session.delivery.position).Magnitude < 30
end

return Delivery
