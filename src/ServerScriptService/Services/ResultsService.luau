--!strict

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

local function findCheckpointSplit(playerResult: PlayerRaceResult, checkpointIndex: number): CheckpointSplit?
	for _, checkpointSplit in ipairs(playerResult.checkpointSplits) do
		if checkpointSplit.checkpointIndex == checkpointIndex then
			return checkpointSplit
		end
	end

	return nil
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
end

function ResultsService.StartRace(raceId: string, courseId: string, format: RaceFormat, startedAt: number)
	playerResultsByUserId = {}
	finishedUserIds = {}
	dnfUserIds = {}

	currentRaceResult = {
		raceId = raceId,
		courseId = courseId,
		format = format,
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
	end

	syncActiveRacers()
	ResultsService.BroadcastCurrentRaceResults()
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

	if findCheckpointSplit(playerResult, checkpointIndex) ~= nil then
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
		if finishedUserIds[dnfResult.userId] ~= true and dnfUserIds[dnfResult.userId] ~= true then
			local playerResult = playerResultsByUserId[dnfResult.userId]

			if playerResult ~= nil then
				playerResult.status = RaceConstants.PlayerRaceStatus.DNF
				playerResult.dnfReason = dnfResult.dnfReason
				table.insert(currentRaceResult.dnfs, playerResult)
			else
				playerResultsByUserId[dnfResult.userId] = dnfResult
				table.insert(currentRaceResult.dnfs, dnfResult)
			end

			dnfUserIds[dnfResult.userId] = true
		end
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
