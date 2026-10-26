--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local LobbyUi = require(script.Parent.LobbyUiController)
local VisitBests = require(script.Parent.VisitBests)
local LobbyPresentation = require(script.Parent.LobbyPresentation)
local Onboarding = require(script.Parent.OnboardingController)
local Flow = require(script.Parent.RaceFlowController)
local Hud = require(script.Parent.RaceHudController)
local ResultsScreen = require(script.Parent.ResultsScreen)
local RacePresentation = require(script.Parent.RacePresentation)

type ControllerConfig = {
	localPlayer: Player?,
	requestSpectateRemote: RemoteEvent?,
	requestRaceLateRemote: RemoteEvent?,
	requestGhostRaceRemote: RemoteEvent?,
}

local RaceUiController = {}

local localPlayer: Player = Players.LocalPlayer
local requestSpectateRemote: RemoteEvent? = nil
local requestRaceLateRemote: RemoteEvent? = nil
local requestGhostRaceRemote: RemoteEvent? = nil

local currentRaceId = ""
local currentRaceState: string? = nil
local currentRemainingTime: number? = nil
local currentPhaseDuration: number? = nil
local currentCourseDisplayName = "-"
local currentRaceFormat: string? = nil
local localPlayerStatus: string = RaceConstants.PlayerRaceStatus.Lobby
local currentRaceResult: any = nil
local lateChoiceSubmittedRaceId: string? = nil
local choiceRequestVersion = 0
local CHOICE_RESPONSE_TIMEOUT = 6

local arrivalConnections: {RBXScriptConnection} = {}

local function rememberRaceId(raceId: any)
	if typeof(raceId) ~= "string" or raceId == currentRaceId then
		return
	end

	currentRaceId = raceId
	currentRemainingTime,currentPhaseDuration = nil,nil
	currentRaceResult = nil
	currentCourseDisplayName = "-"
	currentRaceFormat = nil
	lateChoiceSubmittedRaceId = nil
end

local function applyCourseMetadata(payload: any)
	if typeof(payload) ~= "table" then
		return
	end

	-- Every later screen reads the cleaned name from this same payload.
	payload.courseDisplayName = RacePresentation.CourseName(payload.courseDisplayName)
	if typeof(payload.courseDisplayName) == "string" and payload.courseDisplayName ~= "" then
		currentCourseDisplayName = payload.courseDisplayName
	elseif typeof(payload.courseId) == "string" and payload.courseId ~= "" then
		currentCourseDisplayName = payload.courseId
	end

	if typeof(payload.raceFormat) == "string" then
		currentRaceFormat = payload.raceFormat
	elseif typeof(payload.format) == "string" then
		currentRaceFormat = payload.format
	end
end

local function updateAll()
	LobbyUi.Update(currentRaceState, localPlayerStatus, currentRemainingTime, currentCourseDisplayName, currentRaceFormat, lateChoiceSubmittedRaceId == currentRaceId, currentPhaseDuration)
	Flow.SetRaceClock(currentRaceState, currentRemainingTime)
	ResultsScreen.HandleRaceState(currentRaceState, currentRemainingTime, currentPhaseDuration, currentRaceId)
end

local function requestChoice(action: string)
 if action=="Spectate" then Flow.Action("Watch") else Flow.Open() end
end

function RaceUiController.Init(config: ControllerConfig?)
	choiceRequestVersion += 1
	if config ~= nil then
		if config.localPlayer ~= nil then
			localPlayer = config.localPlayer
		end

		requestSpectateRemote = config.requestSpectateRemote
		requestRaceLateRemote = config.requestRaceLateRemote
		requestGhostRaceRemote = config.requestGhostRaceRemote
	end

	Hud.Init({KeepRacing = function() Flow.Action("KeepRacing") end, Watch = function(id: string) if Flow.Activate then Flow.Activate(id) end end})
	ResultsScreen.Init()
	LobbyUi.Init(localPlayer,{
		MyRacer=Onboarding.OpenRacer,
		CanEditRacer=Onboarding.CanOpenRacer,
		Spectate=function() requestChoice("Spectate") end,
		RaceLate=function() Flow.Open() end,
		RaceOptions=function()
			Flow.Open()
		end,
		Join=function() Flow.Action("Join") end,
		Break=function() Flow.Action("Break") end,
		Watch=function() Flow.Action("Watch") end,
		Practice=function() if Flow.Activate then Flow.Activate("EnterPractice") end end,
	})
	for _, connection in arrivalConnections do connection:Disconnect() end
	table.clear(arrivalConnections)
	for _, name in {"OnboardingReady","ArrivalOpen","ArrivalPhase","TournamentPresentation"} do
		table.insert(arrivalConnections,localPlayer:GetAttributeChangedSignal(name):Connect(updateAll))
	end
	Flow.Init({
		Flow = function(state: any, open: boolean) Hud.HandleFlow(state, open); ResultsScreen.HandleFlow(state) end,
		Tournament = function(snapshot: any) Hud.HandleTournament(snapshot); LobbyUi.UpdateEvent(snapshot); ResultsScreen.HandleEvent(snapshot) end,
		LauncherSlot = function(): Vector2? return Hud.LauncherSlot() end,
		Watch = function(info: any?) Hud.HandleWatch(info) end,
	})
	updateAll()
end

function RaceUiController.HandleRaceStateChanged(payload: any)
	if typeof(payload) ~= "table" then
		return
	end

	rememberRaceId(payload.raceId)
	applyCourseMetadata(payload)

	if typeof(payload.state) == "string" then
		currentRaceState = payload.state
	end

	currentPhaseDuration = LobbyPresentation.Duration(payload.duration)
	Hud.HandleRaceState(payload)
	if typeof(payload.remainingTime) == "number" then
		currentRemainingTime = payload.remainingTime
	elseif currentRaceState ~= "Racing" and currentPhaseDuration then
		currentRemainingTime = currentPhaseDuration
	else
		currentRemainingTime = nil
	end

	updateAll()
end

function RaceUiController.HandleRaceTimerUpdated(payload: any)
	if typeof(payload) ~= "table" then
		return
	end

	rememberRaceId(payload.raceId)
	applyCourseMetadata(payload)

	if typeof(payload.state) == "string" then
		currentRaceState = payload.state
	end
	currentPhaseDuration = LobbyPresentation.Duration(payload.duration)

	if typeof(payload.remainingTime) == "number" then
		currentRemainingTime = payload.remainingTime
	else
		currentRemainingTime = nil
	end

	updateAll()
end

function RaceUiController.HandlePlayerRaceStatusChanged(payload: any)
	if typeof(payload) ~= "table" then
		return
	end

	rememberRaceId(payload.raceId)

	if payload.userId == localPlayer.UserId and typeof(payload.status) == "string" then
		localPlayerStatus = payload.status

		if localPlayerStatus == RaceConstants.PlayerRaceStatus.Lobby then
			lateChoiceSubmittedRaceId = nil
		end
		Hud.HandleStatus(localPlayerStatus)

		updateAll()
	end
end

function RaceUiController.HandleRaceResultsUpdated(payload: any)
	if typeof(payload) ~= "table" then
		return
	end

	rememberRaceId(payload.raceId)
	payload.courseDisplayName = RacePresentation.CourseName(payload.courseDisplayName)
	currentRaceResult = payload
	VisitBests.Record(payload)
	LobbyUi.UpdateRecords(payload)
	applyCourseMetadata(payload)
	Hud.HandleResults(payload)
	ResultsScreen.HandleResults(payload)
	updateAll()
end

return RaceUiController
