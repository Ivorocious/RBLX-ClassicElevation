--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RaceConfig = require(ReplicatedStorage.Config.RaceConfig)

type ServiceContext = {
	Services: { [string]: any },
}

local StagingService = {}

local isInitialized = false
local isStarted = false

local FORMATION_COLUMNS = 3
local FORMATION_SPACING = 4

local function warnMissing(path: string)
	warn(string.format("[StagingService] %s was not found or was not a BasePart.", path))
end

local function getBasePart(instance: Instance?): BasePart?
	if instance ~= nil and instance:IsA("BasePart") then
		return instance
	end

	return nil
end

local function findFirstDescendantBasePart(parent: Instance): BasePart?
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end

	return nil
end

local function findLobbyPart(): BasePart?
	local lobby = Workspace:FindFirstChild(RaceConfig.LobbyModelName)

	if lobby == nil then
		warn(string.format("[StagingService] Workspace.%s was not found.", RaceConfig.LobbyModelName))
		return nil
	end

	local marker = getBasePart(lobby:FindFirstChild(RaceConfig.LobbySpawnMarkerName))

	if marker ~= nil then
		return marker
	end

	local fallback = getBasePart(lobby:FindFirstChild(RaceConfig.LobbyFallbackPartName))

	if fallback ~= nil then
		return fallback
	end

	local descendantFallback = findFirstDescendantBasePart(lobby)

	if descendantFallback == nil then
		warnMissing(string.format("Workspace.%s.%s", RaceConfig.LobbyModelName, RaceConfig.LobbySpawnMarkerName))
	end

	return descendantFallback
end

local function findRaceStartPart(): BasePart?
	local raceCourse = Workspace:FindFirstChild(RaceConfig.RaceCourseModelName)

	if raceCourse == nil then
		warn(string.format("[StagingService] Workspace.%s was not found.", RaceConfig.RaceCourseModelName))
		return nil
	end

	local startPart = getBasePart(raceCourse:FindFirstChild(RaceConfig.RaceStartPartName))

	if startPart == nil then
		warnMissing(string.format("Workspace.%s.%s", RaceConfig.RaceCourseModelName, RaceConfig.RaceStartPartName))
	end

	return startPart
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

local function getFormationOffset(index: number): Vector3
	local zeroBasedIndex = math.max(0, index - 1)
	local column = zeroBasedIndex % FORMATION_COLUMNS
	local row = math.floor(zeroBasedIndex / FORMATION_COLUMNS)
	local xOffset = (column - math.floor(FORMATION_COLUMNS / 2)) * FORMATION_SPACING
	local zOffset = row * FORMATION_SPACING

	return Vector3.new(xOffset, 0, zOffset)
end

local function getTargetCFrame(targetPart: BasePart, verticalOffset: number, index: number): CFrame
	local formationOffset = getFormationOffset(index)
	local cframeWithFormation = targetPart.CFrame * CFrame.new(formationOffset.X, formationOffset.Y, formationOffset.Z)

	return cframeWithFormation + Vector3.new(0, verticalOffset, 0)
end

local function movePlayerToPart(player: Player, targetPart: BasePart, verticalOffset: number, index: number, reason: string)
	if not RaceConfig.StagingTeleportEnabled then
		return
	end

	local character, humanoid, humanoidRootPart = getCharacterParts(player)

	if character == nil or humanoid == nil or humanoidRootPart == nil then
		warn(string.format("[StagingService] Could not move %s for %s; character is not ready.", player.Name, reason))
		return
	end

	if humanoid.Health <= 0 then
		return
	end

	humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
	character:PivotTo(getTargetCFrame(targetPart, verticalOffset, index))

	print(string.format("[StagingService] Moved %s to %s.", player.Name, reason))
end

function StagingService.Init(_context: ServiceContext?)
	if isInitialized then
		return
	end

	isInitialized = true
end

function StagingService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[StagingService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true
end

function StagingService.MovePlayersToRaceStart(players: { Player }, reason: string?)
	if not RaceConfig.StagingTeleportEnabled then
		return
	end

	local startPart = findRaceStartPart()

	if startPart == nil then
		return
	end

	for index, player in ipairs(players) do
		movePlayerToPart(player, startPart, RaceConfig.RacerStartVerticalOffset, index, reason or "race start")
	end
end

function StagingService.ReturnPlayersToLobby(players: { Player }, reason: string?)
	if not RaceConfig.StagingTeleportEnabled then
		return
	end

	local lobbyPart = findLobbyPart()

	if lobbyPart == nil then
		return
	end

	for index, player in ipairs(players) do
		movePlayerToPart(player, lobbyPart, RaceConfig.LobbyResetVerticalOffset, index, reason or "lobby")
	end
end

function StagingService.ReturnAllPlayersToLobby(reason: string?)
	StagingService.ReturnPlayersToLobby(Players:GetPlayers(), reason)
end

return StagingService
