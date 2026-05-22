--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RaceConfig = require(ReplicatedStorage.Config.RaceConfig)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local RaceTypes = require(ReplicatedStorage.Shared.RaceTypes)

type RaceState = RaceTypes.RaceState

type ServiceContext = {
	Services: { [string]: any },
}

local RaceService = {}

local isInitialized = false
local isStarted = false
local roundLoopStarted = false

local playerRaceService: any = nil
local resultsService: any = nil

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local raceStateChangedRemote = remotesFolder:WaitForChild(RaceConstants.RemoteNames.RaceStateChanged) :: RemoteEvent
local raceTimerUpdatedRemote = remotesFolder:WaitForChild(RaceConstants.RemoteNames.RaceTimerUpdated) :: RemoteEvent
local requestDevRaceStateRemote = remotesFolder:WaitForChild(RaceConstants.RemoteNames.RequestDevRaceState) :: RemoteEvent

local currentRaceState: RaceState = RaceConstants.RaceState.WaitingForPlayers
local currentRaceId = ""
local currentRaceStartedAt: number? = nil
local stateStartedAt = 0
local stateEndsAt: number? = nil
local raceCounter = 0
local devStartRaceNowRequested = false
local devRemoteConnection: RBXScriptConnection? = nil

local function getServerTime(): number
	return Workspace:GetServerTimeNow()
end

local function buildRaceId(): string
	raceCounter += 1

	return string.format("race-%d-%03d", math.floor(getServerTime()), raceCounter)
end

local function getStateDuration(): number?
	if stateEndsAt == nil then
		return nil
	end

	return stateEndsAt - stateStartedAt
end

local function getRemainingTime(): number?
	if stateEndsAt == nil then
		return nil
	end

	return math.max(0, stateEndsAt - getServerTime())
end

local function broadcastTimerUpdate()
	raceTimerUpdatedRemote:FireAllClients({
		raceId = currentRaceId,
		state = currentRaceState,
		serverTime = getServerTime(),
		startedAt = stateStartedAt,
		endsAt = stateEndsAt,
		duration = getStateDuration(),
		remainingTime = getRemainingTime(),
	})
end

local function notifyPlayerRaceServiceStateChanged()
	if playerRaceService == nil or playerRaceService.OnRaceStateChanged == nil then
		return
	end

	local didNotify, errorMessage = pcall(playerRaceService.OnRaceStateChanged, currentRaceState, currentRaceId)

	if not didNotify then
		warn(string.format("[RaceService] PlayerRaceService.OnRaceStateChanged failed: %s", tostring(errorMessage)))
	end
end

local function setRaceState(nextRaceState: RaceState, duration: number?)
	local previousRaceState = currentRaceState

	currentRaceState = nextRaceState
	stateStartedAt = getServerTime()
	stateEndsAt = nil

	if duration ~= nil then
		stateEndsAt = stateStartedAt + duration
	end

	print(string.format("[RaceService] State %s -> %s", previousRaceState, currentRaceState))

	raceStateChangedRemote:FireAllClients({
		raceId = currentRaceId,
		previousState = previousRaceState,
		state = currentRaceState,
		serverTime = stateStartedAt,
		startedAt = stateStartedAt,
		endsAt = stateEndsAt,
		duration = duration,
	})

	notifyPlayerRaceServiceStateChanged()
	broadcastTimerUpdate()
end

local function runTimedState(nextRaceState: RaceState, duration: number, onEntered: (() -> ())?)
	setRaceState(nextRaceState, duration)

	if onEntered ~= nil then
		local didRun, errorMessage = pcall(onEntered)

		if not didRun then
			warn(string.format("[RaceService] %s entry action failed: %s", nextRaceState, tostring(errorMessage)))
		end
	end

	while true do
		local remainingTime = getRemainingTime()

		if remainingTime == nil or remainingTime <= 0 then
			break
		end

		task.wait(math.min(1, remainingTime))
		broadcastTimerUpdate()
	end

	broadcastTimerUpdate()
end

local function endCurrentTimedStateNow(reason: string)
	if stateEndsAt == nil then
		print(string.format("[RaceService] Dev control ignored %s; %s has no timer.", reason, currentRaceState))
		return
	end

	stateEndsAt = getServerTime()
	broadcastTimerUpdate()
	print(string.format("[RaceService] Dev control ended %s: %s.", currentRaceState, reason))
end

local function getEligiblePlayerCount(): number
	if playerRaceService == nil or playerRaceService.GetEligiblePlayerCount == nil then
		return 0
	end

	return playerRaceService.GetEligiblePlayerCount()
end

local function resetPlayersForNextRound(reason: string)
	if playerRaceService ~= nil and playerRaceService.ResetPlayersForNextRound ~= nil then
		playerRaceService.ResetPlayersForNextRound(reason)
	end
end

local function waitForMinimumPlayers()
	currentRaceId = ""
	currentRaceStartedAt = nil
	setRaceState(RaceConstants.RaceState.WaitingForPlayers, nil)

	while getEligiblePlayerCount() < RaceConfig.MinPlayers do
		broadcastTimerUpdate()
		task.wait(1)
	end
end

local function runRoundLoop()
	while true do
		waitForMinimumPlayers()

		currentRaceId = buildRaceId()

		if playerRaceService ~= nil and playerRaceService.QueueEligiblePlayers ~= nil then
			playerRaceService.QueueEligiblePlayers()
		end

		local intermissionDuration = RaceConfig.IntermissionDuration

		if devStartRaceNowRequested then
			intermissionDuration = 0
		end

		runTimedState(RaceConstants.RaceState.Intermission, intermissionDuration, nil)

		if getEligiblePlayerCount() < RaceConfig.MinPlayers then
			print("[RaceService] Not enough players after Intermission; resetting to wait for players.")
			runTimedState(RaceConstants.RaceState.Resetting, RaceConfig.ResettingDuration, function()
				resetPlayersForNextRound("Not enough players")
			end)
			devStartRaceNowRequested = false
			continue
		end

		if playerRaceService ~= nil and playerRaceService.QueueEligiblePlayers ~= nil then
			playerRaceService.QueueEligiblePlayers()
		end

		local shouldSkipCountdown = devStartRaceNowRequested
		devStartRaceNowRequested = false

		if not shouldSkipCountdown then
			runTimedState(RaceConstants.RaceState.Countdown, RaceConfig.CountdownDuration, nil)
		end

		if getEligiblePlayerCount() < RaceConfig.MinPlayers then
			print("[RaceService] Not enough players after Countdown; resetting to wait for players.")
			runTimedState(RaceConstants.RaceState.Resetting, RaceConfig.ResettingDuration, function()
				resetPlayersForNextRound("Not enough players")
			end)
			devStartRaceNowRequested = false
			continue
		end

		devStartRaceNowRequested = false

		local raceStartedAt = getServerTime()
		currentRaceStartedAt = raceStartedAt

		if resultsService ~= nil and resultsService.StartRace ~= nil then
			resultsService.StartRace(currentRaceId, RaceConfig.DefaultCourseId, RaceConfig.RaceFormat, raceStartedAt)
		end

		local startedPlayers: { Player } = {}

		if playerRaceService ~= nil and playerRaceService.StartQueuedPlayers ~= nil then
			startedPlayers = playerRaceService.StartQueuedPlayers()
		end

		if resultsService ~= nil and resultsService.RegisterActiveRacers ~= nil then
			resultsService.RegisterActiveRacers(startedPlayers)
		end

		runTimedState(RaceConstants.RaceState.Racing, RaceConfig.RaceDuration, nil)

		local raceDuration = getServerTime() - raceStartedAt
		local dnfResults = {}

		if playerRaceService ~= nil and playerRaceService.MarkUnfinishedRacersDNF ~= nil then
			dnfResults = playerRaceService.MarkUnfinishedRacersDNF("Race timer ended")
		end

		if resultsService ~= nil then
			if resultsService.SetRaceDuration ~= nil then
				resultsService.SetRaceDuration(raceDuration)
			end

			if resultsService.RecordDNFs ~= nil then
				resultsService.RecordDNFs(dnfResults)
			end
		end

		runTimedState(RaceConstants.RaceState.RaceEnding, RaceConfig.RaceEndingDuration, nil)
		runTimedState(RaceConstants.RaceState.Results, RaceConfig.ResultsDuration, function()
			if resultsService ~= nil and resultsService.BroadcastCurrentRaceResults ~= nil then
				resultsService.BroadcastCurrentRaceResults()
			end
		end)
		runTimedState(RaceConstants.RaceState.Resetting, RaceConfig.ResettingDuration, function()
			resetPlayersForNextRound("Round reset")
		end)
	end
end

local function handleDevRaceStateRequest(player: Player, payload)
	if not RunService:IsStudio() then
		return
	end

	if typeof(payload) ~= "table" then
		warn(string.format("[RaceService] Ignored dev request from %s; payload was not a table.", player.Name))
		return
	end

	local action = payload.action

	if typeof(action) ~= "string" then
		warn(string.format("[RaceService] Ignored dev request from %s; action was missing.", player.Name))
		return
	end

	if action == "StartRaceNow" then
		if currentRaceState == RaceConstants.RaceState.WaitingForPlayers
			or currentRaceState == RaceConstants.RaceState.Intermission
			or currentRaceState == RaceConstants.RaceState.Countdown
		then
			devStartRaceNowRequested = true
			endCurrentTimedStateNow("StartRaceNow")
		else
			print(string.format("[RaceService] Dev StartRaceNow ignored in state %s.", currentRaceState))
		end
	elseif action == "SkipState" then
		endCurrentTimedStateNow("SkipState")
	elseif action == "EndRace" then
		if currentRaceState == RaceConstants.RaceState.Racing then
			endCurrentTimedStateNow("EndRace")
		else
			print(string.format("[RaceService] Dev EndRace ignored in state %s.", currentRaceState))
		end
	else
		warn(string.format("[RaceService] Ignored unknown dev action %s from %s.", action, player.Name))
	end
end

function RaceService.Init(context: ServiceContext?)
	if isInitialized then
		return
	end

	if context ~= nil then
		playerRaceService = context.Services.PlayerRaceService
		resultsService = context.Services.ResultsService
	end

	if playerRaceService == nil then
		warn("[RaceService] PlayerRaceService dependency is missing.")
	end

	if resultsService == nil then
		warn("[RaceService] ResultsService dependency is missing.")
	end

	stateStartedAt = getServerTime()
	isInitialized = true
end

function RaceService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[RaceService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true

	if RunService:IsStudio() and devRemoteConnection == nil then
		devRemoteConnection = requestDevRaceStateRemote.OnServerEvent:Connect(handleDevRaceStateRequest)
		print("[RaceService] Studio-only dev race controls enabled.")
	end

	if roundLoopStarted then
		return
	end

	roundLoopStarted = true
	task.spawn(runRoundLoop)
end

function RaceService.GetRaceState(): RaceState
	return currentRaceState
end

function RaceService.GetRaceId(): string
	return currentRaceId
end

function RaceService.GetCurrentRaceId(): string
	return currentRaceId
end

function RaceService.IsRaceActive(): boolean
	return currentRaceState == RaceConstants.RaceState.Racing and currentRaceStartedAt ~= nil
end

function RaceService.GetRaceStartTime(): number?
	return currentRaceStartedAt
end

function RaceService.GetElapsedRaceTime(): number?
	if currentRaceStartedAt == nil then
		return nil
	end

	return getServerTime() - currentRaceStartedAt
end

return RaceService
