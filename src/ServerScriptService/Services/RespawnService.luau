--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RaceConfig = require(ReplicatedStorage.Config.RaceConfig)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local RaceTypes = require(ReplicatedStorage.Shared.RaceTypes)

type PlayerRaceStatus = RaceTypes.PlayerRaceStatus

type ServiceContext = {
	Services: { [string]: any },
}

local RespawnService = {}

local isInitialized = false
local isStarted = false
local raceService: any = nil
local courseService: any = nil
local playerRaceService: any = nil
local checkpointService: any = nil
local resultsService: any = nil
local fallZoneConnections: { RBXScriptConnection } = {}
local heartbeatConnection: RBXScriptConnection? = nil
local lastRespawnAtByUserId: { [number]: number } = {}
local pendingDeathRespawnRaceIdByUserId: { [number]: string } = {}
local characterAddedConnections: { [Player]: RBXScriptConnection } = {}
local humanoidDiedConnections: { [Player]: RBXScriptConnection } = {}

local RESPAWN_COOLDOWN = 1.5
local RECOVERY_IMMUNITY_DURATION = 1
local HEARTBEAT_CHECK_INTERVAL = 0.25
local heartbeatAccumulator = 0

local function getServerTime(): number
	return Workspace:GetServerTimeNow()
end

local function getPlayerFromTouchedPart(touchedPart: BasePart): Player?
	local character = touchedPart:FindFirstAncestorWhichIsA("Model")

	if character == nil then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function isRaceActive(): boolean
	return raceService ~= nil and raceService.IsRaceActive ~= nil and raceService.IsRaceActive() == true
end

local function getCurrentRaceId(): string
	if raceService == nil or raceService.GetCurrentRaceId == nil then
		return ""
	end

	return raceService.GetCurrentRaceId()
end

local function getPlayerStatus(player: Player): PlayerRaceStatus?
	if playerRaceService == nil or playerRaceService.GetPlayerStatus == nil then
		return nil
	end

	return playerRaceService.GetPlayerStatus(player)
end

local function isOfficialRacer(player: Player): boolean
	return playerRaceService ~= nil
		and playerRaceService.IsOfficialRacer ~= nil
		and playerRaceService.IsOfficialRacer(player) == true
end

local function isValidFallRespawnPlayer(player: Player): boolean
	return isRaceActive()
		and isOfficialRacer(player)
		and getPlayerStatus(player) == RaceConstants.PlayerRaceStatus.Racing
end

local function getCharacterParts(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character

	if character == nil then
		return nil, nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart ~= nil and not humanoidRootPart:IsA("BasePart") then
		humanoidRootPart = nil
	end

	return character, humanoid, humanoidRootPart
end

local function canRespawnNow(player: Player): boolean
	local now = getServerTime()
	local lastRespawnAt = lastRespawnAtByUserId[player.UserId]

	if lastRespawnAt ~= nil and now - lastRespawnAt < RESPAWN_COOLDOWN then
		return false
	end

	return true
end

local function markRespawnNow(player: Player)
	lastRespawnAtByUserId[player.UserId] = getServerTime()
end

local function getFallbackStartRespawnCFrame(): CFrame?
	if courseService == nil or courseService.GetStartPart == nil then
		return nil
	end

	local startPart = courseService.GetStartPart()

	if startPart == nil then
		return nil
	end

	return CFrame.new(startPart.Position + Vector3.new(0, RaceConfig.RacerStartVerticalOffset, 0))
end

local function getCheckpointRespawnCFrame(player: Player): CFrame?
	if checkpointService ~= nil and checkpointService.GetCheckpointRespawnCFrame ~= nil then
		local checkpointRespawnCFrame = checkpointService.GetCheckpointRespawnCFrame(player)

		if checkpointRespawnCFrame ~= nil then
			return checkpointRespawnCFrame
		end
	end

	return getFallbackStartRespawnCFrame()
end

local function recoverPlayer(player: Player, source: string, ignoreCooldown: boolean?): boolean
	if not isValidFallRespawnPlayer(player) then
		return false
	end

	local character, humanoid, humanoidRootPart = getCharacterParts(player)

	if character == nil or humanoid == nil or humanoidRootPart == nil then
		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	local respawnCFrame = getCheckpointRespawnCFrame(player)

	if respawnCFrame == nil then
		warn(string.format("[RespawnService] No respawn CFrame available for %s.", player.Name))
		return false
	end

	if ignoreCooldown ~= true and not canRespawnNow(player) then
		return false
	end

	markRespawnNow(player)
	character:SetAttribute("RecoveryUntil", getServerTime() + RECOVERY_IMMUNITY_DURATION)
	humanoid.Health = humanoid.MaxHealth
	humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
	character:PivotTo(respawnCFrame)

	if resultsService ~= nil and resultsService.RecordFall ~= nil then
		resultsService.RecordFall(player)
	end

	print(string.format("[RespawnService] Respawned %s after %s.", player.Name, source))
	return true
end

local function bindFallZones()
	for _, connection in ipairs(fallZoneConnections) do
		connection:Disconnect()
	end
	table.clear(fallZoneConnections)

	if courseService == nil then
		warn("[RespawnService] CourseService dependency is missing.")
		return
	end

	if courseService.GetActiveCourse() == nil then
		return
	end

	local fallZones = courseService.GetFallZones()

	if #fallZones == 0 then
		warn("[RespawnService] Active course fall zones are unavailable.")
		return
	end

	for _, fallZone in ipairs(fallZones) do
		local connection = fallZone.Touched:Connect(function(touchedPart)
			local player = getPlayerFromTouchedPart(touchedPart)

			if player ~= nil then
				RespawnService.RecoverPlayer(player, fallZone.Name)
			end
		end)
		table.insert(fallZoneConnections, connection)
	end

	print(string.format("[RespawnService] Bound %d fall zone(s).", #fallZoneConnections))
end

local function checkFallYThreshold()
	for _, player in ipairs(Players:GetPlayers()) do
		if isValidFallRespawnPlayer(player) then
			local _character, humanoid, humanoidRootPart = getCharacterParts(player)

			if humanoid ~= nil and humanoid.Health > 0 and humanoidRootPart ~= nil then
				if humanoidRootPart.Position.Y <= RaceConfig.FallYThreshold then
					RespawnService.RecoverPlayer(player, "FallYThreshold")
				end
			end
		end
	end
end

local function bindFallYThreshold()
	if heartbeatConnection ~= nil then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end

	heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		heartbeatAccumulator += deltaTime

		if heartbeatAccumulator < HEARTBEAT_CHECK_INTERVAL then
			return
		end

		heartbeatAccumulator = 0
		checkFallYThreshold()
	end)
end

local function disconnectHumanoidDied(player: Player)
	local connection = humanoidDiedConnections[player]

	if connection ~= nil then
		connection:Disconnect()
		humanoidDiedConnections[player] = nil
	end
end

local function bindHumanoidDied(player: Player, character: Model)
	disconnectHumanoidDied(player)

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid == nil then
		task.delay(0.2, function()
			if player.Character ~= character then
				return
			end

			bindHumanoidDied(player, character)
		end)
		return
	end

	humanoidDiedConnections[player] = humanoid.Died:Connect(function()
		if not isValidFallRespawnPlayer(player) then
			return
		end

		local raceId = getCurrentRaceId()

		if raceId == "" then
			return
		end

		pendingDeathRespawnRaceIdByUserId[player.UserId] = raceId
		print(string.format("[RespawnService] Queued checkpoint respawn for %s after character death.", player.Name))
	end)
end

local function handleCharacterAdded(player: Player, character: Model)
	bindHumanoidDied(player, character)

	local pendingRaceId = pendingDeathRespawnRaceIdByUserId[player.UserId]

	if pendingRaceId == nil then
		return
	end

	pendingDeathRespawnRaceIdByUserId[player.UserId] = nil

	task.delay(0.25, function()
		if getCurrentRaceId() ~= pendingRaceId then
			return
		end

		recoverPlayer(player, "CharacterRespawn", true)
	end)
end

local function handlePlayerAdded(player: Player)
	characterAddedConnections[player] = player.CharacterAdded:Connect(function(character)
		handleCharacterAdded(player, character)
	end)

	if player.Character ~= nil then
		bindHumanoidDied(player, player.Character)
	end
end

local function handlePlayerRemoving(player: Player)
	lastRespawnAtByUserId[player.UserId] = nil
	pendingDeathRespawnRaceIdByUserId[player.UserId] = nil
	disconnectHumanoidDied(player)

	local connection = characterAddedConnections[player]

	if connection ~= nil then
		connection:Disconnect()
		characterAddedConnections[player] = nil
	end
end

function RespawnService.Init(context: ServiceContext?)
	if isInitialized then
		return
	end

	if context ~= nil then
		raceService = context.Services.RaceService
		courseService = context.Services.CourseService
		playerRaceService = context.Services.PlayerRaceService
		checkpointService = context.Services.CheckpointService
		resultsService = context.Services.ResultsService
	end

	if raceService == nil then
		warn("[RespawnService] RaceService dependency is missing.")
	end

	if courseService == nil then
		warn("[RespawnService] CourseService dependency is missing.")
	end

	if playerRaceService == nil then
		warn("[RespawnService] PlayerRaceService dependency is missing.")
	end

	if checkpointService == nil then
		warn("[RespawnService] CheckpointService dependency is missing.")
	end

	if resultsService == nil then
		warn("[RespawnService] ResultsService dependency is missing.")
	end

	isInitialized = true
end

function RespawnService.BindActiveCourse()
	bindFallZones()
end

function RespawnService.RecoverPlayer(player: Player, source: string): boolean
	return recoverPlayer(player, source, false)
end

function RespawnService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[RespawnService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true
	Players.PlayerAdded:Connect(handlePlayerAdded)
	Players.PlayerRemoving:Connect(handlePlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		handlePlayerAdded(player)
	end

	RespawnService.BindActiveCourse()
	bindFallYThreshold()
end

return RespawnService
