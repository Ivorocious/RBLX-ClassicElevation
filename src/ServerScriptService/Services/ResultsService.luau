--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local RaceTypes = require(ReplicatedStorage.Shared.RaceTypes)

type RaceFormat = RaceTypes.RaceFormat
type RaceResult = RaceTypes.RaceResult
type PlayerRaceResult = RaceTypes.PlayerRaceResult

type ServiceContext = {
	Services: { [string]: any },
}

local ResultsService = {}

local isInitialized = false
local isStarted = false
local currentRaceResult: RaceResult? = nil

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local raceResultsUpdatedRemote =
	remotesFolder:WaitForChild(RaceConstants.RemoteNames.RaceResultsUpdated) :: RemoteEvent

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
	currentRaceResult = {
		raceId = raceId,
		courseId = courseId,
		format = format,
		startedAt = startedAt,
		duration = nil,
		placements = {},
		dnfs = {},
		unofficialRuns = {},
	}

	print(string.format("[ResultsService] Started result record for %s.", raceId))
end

function ResultsService.RecordDNFs(dnfResults: { PlayerRaceResult })
	if currentRaceResult == nil then
		warn("[ResultsService] RecordDNFs called before StartRace.")
		return
	end

	for _, dnfResult in ipairs(dnfResults) do
		table.insert(currentRaceResult.dnfs, dnfResult)
	end
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
