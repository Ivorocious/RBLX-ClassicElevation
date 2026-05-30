--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local RaceTypes = require(ReplicatedStorage.Shared.RaceTypes)

type RaceFormat = RaceTypes.RaceFormat
type RaceResult = RaceTypes.RaceResult
type PlayerRaceResult = RaceTypes.PlayerRaceResult
type CheckpointSplit = RaceTypes.CheckpointSplit

type ServiceContext = {
	Services: { [string]: any },
}

local ResultsService = {}

local isInitialized = false
local isStarted = false
local currentRaceResult: RaceResult? = nil
local playerResultsByUserId: { [number]: PlayerRaceResult } = {}
local finishedUserIds: { [number]: boolean } = {}
local dnfUserIds: { [number]: boolean } = {}

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local raceResultsUpdatedRemote =
	remotesFolder:WaitForChild(RaceConstants.RemoteNames.RaceResultsUpdated) :: RemoteEvent

local function syncActiveRacers()
	if currentRaceResult == nil then
		return
	end

	local activeRacers = {}

	for _, playerResult in pairs(playerResultsByUserId) do
		if playerResult.status ~= RaceConstants.PlayerRaceStatus.Finished
			and playerResult.status ~= RaceConstants.PlayerRaceStatus.DNF
		then
			table.insert(activeRacers, playerResult)
		end
	end

	currentRaceResult.activeRacers = activeRacers
end

local function createPlayerRaceResult(player: Player): PlayerRaceResult
	local requiredLaps = 1

	if currentRaceResult ~= nil and currentRaceResult.requiredLaps ~= nil then
		requiredLaps = currentRaceResult.requiredLaps
	end

	return {
		userId = player.UserId,
		name = player.Name,
		displayName = player.DisplayName,
		status = RaceConstants.PlayerRaceStatus.Racing,
		official = true,
		placement = nil,
		finishTime = nil,
		falls = 0,
		checkpointSplits = {},
		currentLap = 1,
		requiredLaps = requiredLaps,
		nextCheckpointIndex = 1,
		checkpointCount = nil,
		lapTimes = {},
		dnfReason = nil,
		isPersonalBest = false,
		summaryNotes = {},
	}
end

local function getOrCreatePlayerResult(player: Player): PlayerRaceResult
	local playerResult = playerResultsByUserId[player.UserId]

	if playerResult == nil then
		playerResult = createPlayerRaceResult(player)
		playerResultsByUserId[player.UserId] = playerResult
	end

	return playerResult
end

local function findCheckpointSplit(playerResult: PlayerRaceResult, checkpointIndex: number, lap: number): CheckpointSplit?
	for _, checkpointSplit in ipairs(playerResult.checkpointSplits) do
		if checkpointSplit.checkpointIndex == checkpointIndex and checkpointSplit.lap == lap then
			return checkpointSplit
		end
	end

	return nil
end

local function applyDnfResult(dnfResult: PlayerRaceResult): boolean
	if currentRaceResult == nil then
		return false
	end

	if finishedUserIds[dnfResult.userId] == true or dnfUserIds[dnfResult.userId] == true then
		return false
	end

	local playerResult = playerResultsByUserId[dnfResult.userId]

	if playerResult ~= nil then
		if playerResult.status == RaceConstants.PlayerRaceStatus.Finished then
			finishedUserIds[dnfResult.userId] = true
			return false
		end

		playerResult.status = RaceConstants.PlayerRaceStatus.DNF
		playerResult.dnfReason = dnfResult.dnfReason
		table.insert(currentRaceResult.dnfs, playerResult)
	else
		playerResultsByUserId[dnfResult.userId] = dnfResult
		table.insert(currentRaceResult.dnfs, dnfResult)
	end

	dnfUserIds[dnfResult.userId] = true
	return true
end

local function handlePlayerRemoving(player: Player)
	if currentRaceResult == nil then
		return
	end

	local playerResult = playerResultsByUserId[player.UserId]

	if playerResult == nil or playerResult.official ~= true then
		return
	end

	local didDnf = applyDnfResult({
		userId = playerResult.userId,
		name = playerResult.name,
		displayName = playerResult.displayName,
		status = RaceConstants.PlayerRaceStatus.DNF,
		official = true,
		placement = nil,
		finishTime = nil,
		falls = playerResult.falls,
		checkpointSplits = playerResult.checkpointSplits,
		currentLap = playerResult.currentLap,
		requiredLaps = playerResult.requiredLaps,
		nextCheckpointIndex = playerResult.nextCheckpointIndex,
		checkpointCount = playerResult.checkpointCount,
		lapTimes = playerResult.lapTimes,
		dnfReason = "Left race",
		isPersonalBest = false,
		summaryNotes = {},
	})

	if not didDnf then
		return
	end

	syncActiveRacers()
	ResultsService.BroadcastCurrentRaceResults()
	print(string.format("[ResultsService] %s marked DNF after leaving.", player.Name))
end

function ResultsService.Init(_context: ServiceContext?)
	if isInitialized then
		return
	end

	isInitialized = true
end

function ResultsService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[ResultsService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true
	Players.PlayerRemoving:Connect(handlePlayerRemoving)
end

function ResultsService.StartRace(
	raceId: string,
	courseId: string,
	format: RaceFormat,
	startedAt: number,
	courseDisplayName: string?,
	lapCount: number?,
	checkpointCount: number?
)
	playerResultsByUserId = {}
	finishedUserIds = {}
	dnfUserIds = {}
	local requiredLaps = math.max(1, lapCount or 1)

	currentRaceResult = {
		raceId = raceId,
		courseId = courseId,
		courseDisplayName = courseDisplayName,
		format = format,
		raceFormat = format,
		lapCount = requiredLaps,
		requiredLaps = requiredLaps,
		checkpointCount = checkpointCount,
		startedAt = startedAt,
		duration = nil,
		activeRacers = {},
		placements = {},
		dnfs = {},
		unofficialRuns = {},
	}

	print(string.format("[ResultsService] Started result record for %s.", raceId))
end

function ResultsService.RegisterActiveRacers(players: { Player })
	if currentRaceResult == nil then
		warn("[ResultsService] RegisterActiveRacers called before StartRace.")
		return
	end

	for _, player in ipairs(players) do
		local playerResult = getOrCreatePlayerResult(player)
		playerResult.status = RaceConstants.PlayerRaceStatus.Racing
		playerResult.official = true
		playerResult.currentLap = 1
		playerResult.requiredLaps = currentRaceResult.requiredLaps
		playerResult.nextCheckpointIndex = 1
		playerResult.checkpointCount = currentRaceResult.checkpointCount
		playerResult.lapTimes = playerResult.lapTimes or {}
	end

	syncActiveRacers()
	ResultsService.BroadcastCurrentRaceResults()
end

function ResultsService.UpdateCheckpointProgress(
	player: Player,
	currentLap: number,
	requiredLaps: number,
	nextCheckpointIndex: number,
	checkpointCount: number
): boolean
	if currentRaceResult == nil then
		return false
	end

	if finishedUserIds[player.UserId] == true then
		return false
	end

	local playerResult = getOrCreatePlayerResult(player)

	playerResult.currentLap = currentLap
	playerResult.requiredLaps = requiredLaps
	playerResult.nextCheckpointIndex = nextCheckpointIndex
	playerResult.checkpointCount = checkpointCount

	syncActiveRacers()
	ResultsService.BroadcastCurrentRaceResults()
	return true
end

function ResultsService.RecordCheckpointSplit(
	player: Player,
	checkpointIndex: number,
	checkpointName: string,
	lap: number,
	elapsedTime: number
): boolean
	if currentRaceResult == nil then
		warn("[ResultsService] RecordCheckpointSplit called before StartRace.")
		return false
	end

	if finishedUserIds[player.UserId] == true then
		return false
	end

	local playerResult = getOrCreatePlayerResult(player)

	if findCheckpointSplit(playerResult, checkpointIndex, lap) ~= nil then
		return false
	end

	table.insert(playerResult.checkpointSplits, {
		checkpointIndex = checkpointIndex,
		checkpointName = checkpointName,
		lap = lap,
		elapsedTime = elapsedTime,
		deltaFromPersonalBest = nil,
	})

	print(
		string.format(
			"[ResultsService] %s split %s at %.3fs.",
			player.Name,
			checkpointName,
			elapsedTime
		)
	)

	syncActiveRacers()
	ResultsService.BroadcastCurrentRaceResults()
	return true
end

function ResultsService.RecordLapComplete(
	player: Player,
	lap: number,
	lapTime: number,
	nextLap: number,
	requiredLaps: number
): boolean
	if currentRaceResult == nil then
		warn("[ResultsService] RecordLapComplete called before StartRace.")
		return false
	end

	if finishedUserIds[player.UserId] == true then
		return false
	end

	local playerResult = getOrCreatePlayerResult(player)
	local lapTimes = playerResult.lapTimes

	if lapTimes == nil then
		lapTimes = {}
		playerResult.lapTimes = lapTimes
	end

	lapTimes[lap] = lapTime
	playerResult.currentLap = math.min(nextLap, requiredLaps)
	playerResult.requiredLaps = requiredLaps

	if lap >= requiredLaps then
		local checkpointCount = playerResult.checkpointCount

		if checkpointCount == nil and currentRaceResult ~= nil then
			checkpointCount = currentRaceResult.checkpointCount
		end

		playerResult.nextCheckpointIndex = (checkpointCount or 0) + 1
	else
		playerResult.nextCheckpointIndex = 1
	end

	syncActiveRacers()
	ResultsService.BroadcastCurrentRaceResults()
	print(string.format("[ResultsService] %s completed lap %d at %.3fs.", player.Name, lap, lapTime))
	return true
end

function ResultsService.RecordFall(player: Player): number?
	if currentRaceResult == nil then
		warn("[ResultsService] RecordFall called before StartRace.")
		return nil
	end

	if finishedUserIds[player.UserId] == true then
		return nil
	end

	local playerResult = getOrCreatePlayerResult(player)

	if playerResult.status == RaceConstants.PlayerRaceStatus.Finished
		or playerResult.status == RaceConstants.PlayerRaceStatus.DNF
	then
		return nil
	end

	playerResult.falls += 1
	syncActiveRacers()
	ResultsService.BroadcastCurrentRaceResults()
	print(string.format("[ResultsService] %s fall count -> %d.", player.Name, playerResult.falls))

	return playerResult.falls
end

function ResultsService.RecordFinish(player: Player, elapsedTime: number): PlayerRaceResult?
	if currentRaceResult == nil then
		warn("[ResultsService] RecordFinish called before StartRace.")
		return nil
	end

	if finishedUserIds[player.UserId] == true then
		return nil
	end

	local playerResult = getOrCreatePlayerResult(player)

	if playerResult.status == RaceConstants.PlayerRaceStatus.Finished then
		finishedUserIds[player.UserId] = true
		return nil
	end

	local placement = #currentRaceResult.placements + 1

	playerResult.status = RaceConstants.PlayerRaceStatus.Finished
	playerResult.placement = placement
	playerResult.finishTime = elapsedTime
	playerResult.dnfReason = nil
	playerResult.currentLap = playerResult.requiredLaps or playerResult.currentLap
	finishedUserIds[player.UserId] = true

	syncActiveRacers()
	table.insert(currentRaceResult.placements, playerResult)
	ResultsService.BroadcastCurrentRaceResults()

	print(
		string.format(
			"[ResultsService] %s finished place %d at %.3fs.",
			player.Name,
			placement,
			elapsedTime
		)
	)

	return playerResult
end

function ResultsService.RecordDNFs(dnfResults: { PlayerRaceResult })
	if currentRaceResult == nil then
		warn("[ResultsService] RecordDNFs called before StartRace.")
		return
	end

	for _, dnfResult in ipairs(dnfResults) do
		applyDnfResult(dnfResult)
	end

	syncActiveRacers()
	ResultsService.BroadcastCurrentRaceResults()
end

function ResultsService.SetRaceDuration(duration: number)
	if currentRaceResult == nil then
		return
	end

	currentRaceResult.duration = duration
end

function ResultsService.GetCurrentRaceResult(): RaceResult?
	return currentRaceResult
end

function ResultsService.BroadcastCurrentRaceResults()
	if currentRaceResult == nil then
		warn("[ResultsService] BroadcastCurrentRaceResults called with no current race result.")
		return
	end

	raceResultsUpdatedRemote:FireAllClients(currentRaceResult)
	print(string.format("[ResultsService] Broadcast results for %s.", currentRaceResult.raceId))
end

return ResultsService
