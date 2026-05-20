--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local RaceTypes = require(ReplicatedStorage.Shared.RaceTypes)

type RaceState = RaceTypes.RaceState
type PlayerRaceStatus = RaceTypes.PlayerRaceStatus
type PlayerRaceResult = RaceTypes.PlayerRaceResult

type ServiceContext = {
	Services: { [string]: any },
}

local PlayerRaceService = {}

local isInitialized = false
local isStarted = false
local currentRaceState: RaceState = RaceConstants.RaceState.WaitingForPlayers
local currentRaceId = ""

local playerStatuses: { [Player]: PlayerRaceStatus } = {}
local officialRaceEligible: { [Player]: boolean } = {}

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local playerRaceStatusChangedRemote =
	remotesFolder:WaitForChild(RaceConstants.RemoteNames.PlayerRaceStatusChanged) :: RemoteEvent

local function getServerTime(): number
	return Workspace:GetServerTimeNow()
end

local function broadcastStatusChanged(
	player: Player,
	previousStatus: PlayerRaceStatus?,
	status: PlayerRaceStatus,
	reason: string?
)
	playerRaceStatusChangedRemote:FireAllClients({
		raceId = currentRaceId,
		userId = player.UserId,
		name = player.Name,
		displayName = player.DisplayName,
		previousStatus = previousStatus,
		status = status,
		reason = reason,
		serverTime = getServerTime(),
	})
end

local function buildResultRecord(player: Player, status: PlayerRaceStatus, reason: string?): PlayerRaceResult
	return {
		userId = player.UserId,
		displayName = player.DisplayName,
		status = status,
		official = officialRaceEligible[player] == true,
		placement = nil,
		finishTime = nil,
		falls = 0,
		checkpointSplits = {},
		dnfReason = reason,
		isPersonalBest = false,
		summaryNotes = {},
	}
end

local function shouldQueuePlayerForCurrentState(): boolean
	return currentRaceState == RaceConstants.RaceState.Intermission
		or currentRaceState == RaceConstants.RaceState.Countdown
end

local function handlePlayerAdded(player: Player)
	if shouldQueuePlayerForCurrentState() then
		PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Queued, "Joined before race start")
		officialRaceEligible[player] = true
	else
		PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Lobby, "Joined server")
		officialRaceEligible[player] = false
	end
end

local function handlePlayerRemoving(player: Player)
	playerStatuses[player] = nil
	officialRaceEligible[player] = nil
end

function PlayerRaceService.Init(_context: ServiceContext?)
	if isInitialized then
		return
	end

	isInitialized = true
end

function PlayerRaceService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[PlayerRaceService] Start called before Init.")
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
end

function PlayerRaceService.OnRaceStateChanged(nextRaceState: RaceState, raceId: string?)
	currentRaceState = nextRaceState
	currentRaceId = raceId or currentRaceId
end

function PlayerRaceService.GetEligiblePlayerCount(): number
	local count = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local status = playerStatuses[player]

		if status == nil
			or status == RaceConstants.PlayerRaceStatus.Lobby
			or status == RaceConstants.PlayerRaceStatus.Queued
		then
			count += 1
		end
	end

	return count
end

function PlayerRaceService.GetPlayerStatus(player: Player): PlayerRaceStatus?
	return playerStatuses[player]
end

function PlayerRaceService.IsOfficialRacer(player: Player): boolean
	return officialRaceEligible[player] == true
end

function PlayerRaceService.SetPlayerStatus(player: Player, status: PlayerRaceStatus, reason: string?)
	local previousStatus = playerStatuses[player]

	if previousStatus == status then
		return
	end

	playerStatuses[player] = status
	broadcastStatusChanged(player, previousStatus, status, reason)
	print(string.format("[PlayerRaceService] %s status -> %s", player.Name, status))
end

function PlayerRaceService.QueueEligiblePlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local status = playerStatuses[player]

		if status == nil or status == RaceConstants.PlayerRaceStatus.Lobby then
			officialRaceEligible[player] = true
			PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Queued, "Queued for next race")
		end
	end
end

function PlayerRaceService.StartQueuedPlayers(): { Player }
	local startedPlayers = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if playerStatuses[player] == RaceConstants.PlayerRaceStatus.Queued then
			officialRaceEligible[player] = true
			table.insert(startedPlayers, player)
			PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Racing, "Race started")
		end
	end

	return startedPlayers
end

function PlayerRaceService.MarkUnfinishedRacersDNF(reason: string): { PlayerRaceResult }
	local dnfResults = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local status = playerStatuses[player]

		if officialRaceEligible[player] == true
			and (status == RaceConstants.PlayerRaceStatus.Racing or status == RaceConstants.PlayerRaceStatus.Queued)
		then
			PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.DNF, reason)
			table.insert(dnfResults, buildResultRecord(player, RaceConstants.PlayerRaceStatus.DNF, reason))
		end
	end

	return dnfResults
end

function PlayerRaceService.ResetPlayersForNextRound(reason: string?)
	for _, player in ipairs(Players:GetPlayers()) do
		officialRaceEligible[player] = false
		PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Lobby, reason or "Round reset")
	end
end

return PlayerRaceService
