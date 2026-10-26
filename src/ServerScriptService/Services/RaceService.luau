--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RaceConfig = require(ReplicatedStorage.Config.RaceConfig)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local RaceTypes = require(ReplicatedStorage.Shared.RaceTypes)
local Deadline = require(ReplicatedStorage.Shared.RaceDeadline)
local Identity = require(ReplicatedStorage.Shared.CourseVisitIdentity)

type RaceState = RaceTypes.RaceState
type RaceFormat = RaceTypes.RaceFormat

type ServiceContext = {
	Services: { [string]: any },
}

type CoursePayload = {
	courseId: string,
	courseDisplayName: string,
	raceFormat: RaceFormat,
	lapCount: number,
	checkpointCount: number?,
}

local RaceService = {}

local isInitialized = false
local isStarted = false
local roundLoopStarted = false

local playerRaceService: any = nil
local resultsService: any = nil
local lobbyActivityService: any = nil
local stagingService: any = nil
local courseHazardService: any = nil
local courseService: any = nil
local tournamentService: any = nil
local studioStandalone = false
local checkpointService: any = nil
local respawnService: any = nil
local visitProgressService: any = nil
local standalonePreparation: any = nil
local cachedCourseModel: Model? = nil
local cachedCourseInfo: any = nil

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
local inspectionRestartRequested = false
local inspectionUnlimitedTime = false
local studioHoldInLobby = false
local devStateEndRequested = false
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

local function isUnlimitedInspectionRace(): boolean
	return RunService:IsStudio()
		and inspectionUnlimitedTime
		and currentRaceState == RaceConstants.RaceState.Racing
end

local function getRemainingTime(): number?
	if stateEndsAt == nil or isUnlimitedInspectionRace() then
		return nil
	end

	return math.max(0, stateEndsAt - getServerTime())
end

local function getActiveCoursePayload(): CoursePayload
	if courseService ~= nil and courseService.GetActiveCourseInfo ~= nil then
		local courseInfo = courseService.GetActiveCourseInfo()

		if typeof(courseInfo) == "table" then
			local courseId = RaceConfig.DefaultCourseId
			local displayName = courseId
			local raceFormat = RaceConstants.RaceFormat.PointToPoint
			local lapCount = 1
			local checkpointCount: number? = nil

			if typeof(courseInfo.courseId) == "string" then
				courseId = courseInfo.courseId
			end

			if typeof(courseInfo.displayName) == "string" then
				displayName = courseInfo.displayName
			else
				displayName = courseId
			end

			if courseInfo.raceFormat == RaceConstants.RaceFormat.LapBased then
				raceFormat = RaceConstants.RaceFormat.LapBased
			end

			if typeof(courseInfo.lapCount) == "number" then
				lapCount = math.max(1, courseInfo.lapCount)
			end

			if courseService.GetOrderedCheckpoints ~= nil then
				checkpointCount = #courseService.GetOrderedCheckpoints()
			end

			return {
				courseId = courseId,
				courseDisplayName = displayName,
				raceFormat = raceFormat,
				lapCount = lapCount,
				checkpointCount = checkpointCount,
			}
		end
	end

	return {
		courseId = RaceConfig.DefaultCourseId,
		courseDisplayName = RaceConfig.DefaultCourseId,
		raceFormat = RaceConfig.RaceFormat,
		lapCount = 1,
		checkpointCount = nil,
	}
end

local function addCoursePayload(payload: { [string]: any })
	local activeCourse = getActiveCoursePayload()

	payload.courseId = activeCourse.courseId
	payload.courseDisplayName = activeCourse.courseDisplayName
	payload.raceFormat = activeCourse.raceFormat
	payload.lapCount = activeCourse.lapCount
	payload.checkpointCount = activeCourse.checkpointCount
end

local function broadcastTimerUpdate()
	local payload = {
		raceId = currentRaceId,
		state = currentRaceState,
		serverTime = getServerTime(),
		startedAt = stateStartedAt,
		endsAt = stateEndsAt,
		duration = getStateDuration(),
		remainingTime = getRemainingTime(),
	}

	addCoursePayload(payload)
	raceTimerUpdatedRemote:FireAllClients(payload)
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

	local payload = {
		raceId = currentRaceId,
		previousState = previousRaceState,
		state = currentRaceState,
		serverTime = stateStartedAt,
		startedAt = stateStartedAt,
		endsAt = stateEndsAt,
		duration = duration,
	}

	addCoursePayload(payload)
	raceStateChangedRemote:FireAllClients(payload)

	notifyPlayerRaceServiceStateChanged()
	broadcastTimerUpdate()
end

local function haveAllOfficialRacersResolved(): boolean
	if resultsService == nil or resultsService.GetCurrentRaceResult == nil then
		return false
	end

	local result = resultsService.GetCurrentRaceResult()

	return result ~= nil and result.raceId == currentRaceId and #result.activeRacers == 0
end

local function runTimedState(nextRaceState: RaceState, duration: number, onEntered: (() -> ())?)
	devStateEndRequested = false
	setRaceState(nextRaceState, duration)

	if onEntered ~= nil then
		local didRun, errorMessage = pcall(onEntered)

		if not didRun then
			warn(string.format("[RaceService] %s entry action failed: %s", nextRaceState, tostring(errorMessage)))
		end
	end

	while true do
		if inspectionRestartRequested or devStateEndRequested then break end
		if nextRaceState == RaceConstants.RaceState.Racing and haveAllOfficialRacersResolved() then
			print("[RaceService] All official racers finished or left; ending the race early.")
			break
		end

		local remainingTime = getRemainingTime()
		if nextRaceState == RaceConstants.RaceState.Racing and inspectionUnlimitedTime and RunService:IsStudio() then remainingTime = 1 end
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

	devStateEndRequested = true
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
	if tournamentService then tournamentService.AbortPreparation() end
 if stagingService and playerRaceService then
  local returning={}
  for _,player in game:GetService("Players"):GetPlayers() do
   if playerRaceService.GetPlayerStatus(player) ~= "Lobby" then table.insert(returning,player) end
  end
  stagingService.ClearStaging()
  stagingService.ReturnPlayersToLobby(returning,reason)
 end

	if playerRaceService ~= nil and playerRaceService.ResetPlayersForNextRound ~= nil then
		playerRaceService.ResetPlayersForNextRound(reason)
	end

	if courseService ~= nil then
		courseService.UnloadActiveCourse()
	end
end

local function getQueuedPlayers(): { Player }
	if playerRaceService == nil or playerRaceService.GetQueuedPlayers == nil then
		return {}
	end

	return playerRaceService.GetQueuedPlayers()
end

local function stageQueuedPlayersAtStart(reason: string)
	if stagingService ~= nil and stagingService.MovePlayersToRaceStart ~= nil then
		stagingService.MovePlayersToRaceStart(getQueuedPlayers(), reason)
	end
end

local function beginStagingQueuedPlayers(reason: string)
	if stagingService == nil then
		return
	end

	if stagingService.BeginStaging ~= nil then
		stagingService.BeginStaging(getQueuedPlayers(), reason)
	elseif stagingService.MovePlayersToRaceStart ~= nil then
		stagingService.MovePlayersToRaceStart(getQueuedPlayers(), reason)
	end
end

local function openStartForRace()
	if stagingService ~= nil and stagingService.OnRaceStarted ~= nil then
		stagingService.OnRaceStarted()
	end
end

local function bindActiveCourseReferences(reason: string, alreadyLoaded: boolean?)
	if not alreadyLoaded and courseService ~= nil and courseService.EnsureActiveCourse ~= nil then
		courseService.EnsureActiveCourse()
	end

	if checkpointService ~= nil and checkpointService.BindActiveCourse ~= nil then
		checkpointService.BindActiveCourse()
	end

	if respawnService ~= nil and respawnService.BindActiveCourse ~= nil then
		respawnService.BindActiveCourse()
	end

	if courseHazardService ~= nil then courseHazardService.BindActiveCourse() end

	local activeCourse = getActiveCoursePayload()
	print(
		string.format(
			"[RaceService] Bound active course references for %s: %s.",
			reason,
			activeCourse.courseDisplayName
		)
	)
end

local function returnAllPlayersToLobby(reason: string)
	if stagingService ~= nil and stagingService.ReturnAllPlayersToLobby ~= nil then
		stagingService.ReturnAllPlayersToLobby(reason)
	end
end

local function waitForMinimumPlayers()
	currentRaceId = ""
	currentRaceStartedAt = nil
	setRaceState(RaceConstants.RaceState.WaitingForPlayers, nil)


	while getEligiblePlayerCount() < RaceConfig.MinPlayers or (RunService:IsStudio() and studioHoldInLobby) do
		broadcastTimerUpdate()
		task.wait(1)
	end
end

local function stagePreparedPlayers()
 bindActiveCourseReferences("prepared course",true)
 playerRaceService.PreparePlayersForCourse()
 stagingService.MovePlayersToRaceStart(playerRaceService.GetQueuedPlayers(),"Course delivery")
 return true
end

local function abandonPreparation(message: string)
 for _,player in playerRaceService.GetEnrolledPlayers() do
  playerRaceService.FailPreparation(player,message)
 end
 if tournamentService then tournamentService.Cancel() end
 resetPlayersForNextRound(message)
 standalonePreparation = nil
 devStartRaceNowRequested = false
end

local function runRoundLoop()
 local transitionStartedAt: number? = nil
 while true do
  inspectionRestartRequested = false
  if getEligiblePlayerCount() < RaceConfig.MinPlayers or (RunService:IsStudio() and studioHoldInLobby) then
   transitionStartedAt = nil
   if tournamentService then tournamentService.Cancel() end
   waitForMinimumPlayers()
  end
  currentRaceId = buildRaceId()
  currentRaceStartedAt = nil
  cachedCourseModel,cachedCourseInfo = nil,nil
  setRaceState(RaceConstants.RaceState.Intermission,nil)
  playerRaceService.OpenAdmission()
  local selected: string? = nil
  local devBypass = RunService:IsStudio() and (devStartRaceNowRequested or studioStandalone)
  if tournamentService and not devBypass then
   local ok,courseOrMessage = tournamentService.PrepareNextCourse({
    transitionStartedAt=transitionStartedAt,onCourseLoaded=stagePreparedPlayers,
   })
   if not ok then
    if inspectionRestartRequested or devStartRaceNowRequested or studioStandalone then
     resetPlayersForNextRound("Studio preparation cancelled")
     transitionStartedAt=nil
     continue
    end
    abandonPreparation(courseOrMessage or "Course delivery failed")
    transitionStartedAt = nil
    continue
   end
   selected = courseOrMessage
  end
  if not selected then
   bindActiveCourseReferences("ordinary round",false)
   local active = courseService.GetActiveCourse()
   local start = courseService.GetStartPart()
   if not active or not start then
    abandonPreparation("No playable course could be delivered")
    transitionStartedAt = nil
    continue
   end
   local partCount=0
   for _,part in active:GetDescendants() do if part:IsA("BasePart") then partCount+=1 end end
   standalonePreparation={token=currentRaceId,courseId=getActiveCoursePayload().courseId,status="Ready",
    startedAt=getServerTime(),previewAt=getServerTime(),handoffAt=getServerTime(),
    delivery={modelName=active.Name,startPosition=start.Position,expectedParts=partCount,
     bounds={center=start.Position,size=Vector3.new(64,64,64)}}}
   for _,player in playerRaceService.GetEnrolledPlayers() do player:SetAttribute("TournamentCourseReady",false) end
   stagePreparedPlayers()
   playerRaceService.PublishFlow()
  end
  if inspectionRestartRequested then
   resetPlayersForNextRound("Inspection map switch")
   transitionStartedAt=nil
   continue
  end
  local token = tournamentService and tournamentService.GetCourseToken() or nil
  token = token or (standalonePreparation and standalonePreparation.token) or currentRaceId
  local currentPrep=tournamentService and tournamentService.GetPreparation() or standalonePreparation
  local deadline=(currentPrep and currentPrep.readyUntil) or (getServerTime()+RaceConfig.CameraReadyTimeout)
  while not devBypass and getServerTime()<deadline and not inspectionRestartRequested
   and (playerRaceService.ReadyToAdmitCount(token)==0 or playerRaceService.ReadyToAdmitCount(token)<#getQueuedPlayers()) do
   if getEligiblePlayerCount()==0 then break end
   stagePreparedPlayers()
   task.wait(.1)
  end
  if inspectionRestartRequested then
   resetPlayersForNextRound("Inspection map switch");transitionStartedAt=nil;continue
  end
  local admitted = playerRaceService.CloseAdmission(token,devBypass)
  if #admitted==0 then
   abandonPreparation("Course or camera delivery was not ready. Stay in the lobby and retry.")
   transitionStartedAt=nil
   continue
  end
  devStartRaceNowRequested=false
  runTimedState(RaceConstants.RaceState.Countdown,RaceConfig.CountdownDuration,nil)
  if inspectionRestartRequested then resetPlayersForNextRound("Inspection map switch");transitionStartedAt=nil;continue end
  local startedPlayers=playerRaceService.StartQueuedPlayers()
  if #startedPlayers==0 then
   resetPlayersForNextRound("No ready characters remained at start")
   if tournamentService then tournamentService.Cancel() end
   transitionStartedAt=nil
   continue
  end
  local startedAt=getServerTime()
  currentRaceStartedAt=startedAt
  local info=RaceService.GetCourseInfo()
  if selected then tournamentService.BindRace(currentRaceId,info.courseId) end
  resultsService.StartRace(currentRaceId,info.courseId,info.raceFormat,startedAt,info.displayName,info.lapCount,info.checkpointCount)
  resultsService.SetCourseIdentity(info)
  resultsService.RegisterActiveRacers(startedPlayers)
  for _,player in startedPlayers do
   if visitProgressService then visitProgressService.EnterRace(player,currentRaceId,info) end
  end
  playerRaceService.PublishFlow()
  runTimedState(RaceConstants.RaceState.Racing,Deadline.Seconds(info,RaceConfig),openStartForRace)
  if inspectionRestartRequested then
   for _,player in playerRaceService.GetRacingPlayers() do resultsService.WithdrawPlayer(player,"Studio inspection restarted") end
   resetPlayersForNextRound("Inspection map switch");transitionStartedAt=nil;continue
  end
  local dnfs=playerRaceService.MarkUnfinishedRacersDNF("Time expired")
  resultsService.SetRaceDuration(getServerTime()-startedAt)
  resultsService.RecordDNFs(dnfs)
  transitionStartedAt=getServerTime()
  if lobbyActivityService then lobbyActivityService.RecordCompletedRace() end
  if selected then tournamentService.CaptureRace(resultsService.GetCurrentRaceResult()) end
  runTimedState(RaceConstants.RaceState.Results,RaceConfig.ResultsDuration,function()
   resultsService.BroadcastCurrentRaceResults()
  end)
  if selected and not inspectionRestartRequested then tournamentService.CompleteRace() end
  local complete = selected and tournamentService.IsEventComplete()
  resetPlayersForNextRound("Next race preparation")
  standalonePreparation=nil
  if complete then
   local snapshot=tournamentService.GetSnapshot(nil)
   if snapshot.finaleUntil then
    runTimedState(RaceConstants.RaceState.RaceEnding,math.max(0,snapshot.finaleUntil-getServerTime()),nil)
   end
   transitionStartedAt=nil
  end
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
   studioHoldInLobby = false
   playerRaceService.ForceEnrollReadyPlayersForStudio()
			endCurrentTimedStateNow("StartRaceNow")
		else
			print(string.format("[RaceService] Dev StartRaceNow ignored in state %s.", currentRaceState))
		end
	elseif action == "SkipState" then
		endCurrentTimedStateNow("SkipState")
	elseif action == "SkipCheckpoint" then
		if checkpointService ~= nil then checkpointService.SkipCheckpointForStudio(player) end
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
		lobbyActivityService = context.Services.LobbyActivityService
		stagingService = context.Services.StagingService
		courseHazardService = context.Services.CourseHazardService
		courseService = context.Services.CourseService
		tournamentService = context.Services.TournamentService
		checkpointService = context.Services.CheckpointService
		respawnService = context.Services.RespawnService
		visitProgressService = context.Services.VisitProgressService
	end

	if playerRaceService == nil then
		warn("[RaceService] PlayerRaceService dependency is missing.")
	end

	if resultsService == nil then
		warn("[RaceService] ResultsService dependency is missing.")
	end

	if stagingService == nil then
		warn("[RaceService] StagingService dependency is missing.")
	end

	if courseService == nil then
		warn("[RaceService] CourseService dependency is missing.")
	end

	if checkpointService == nil then
		warn("[RaceService] CheckpointService dependency is missing.")
	end

	if respawnService == nil then
		warn("[RaceService] RespawnService dependency is missing.")
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

	if RunService:IsStudio() and RaceConfig.StudioLobbyPreview then
		studioHoldInLobby = true
		print("[RaceService] Starting in lobby; use Studio developer controls to begin a race.")
	end

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

function RaceService.RestartInspectionRound()
	if not RunService:IsStudio() then return end
	studioStandalone = true
	if tournamentService then tournamentService.Cancel() end
	inspectionRestartRequested = true
	devStartRaceNowRequested = true
	endCurrentTimedStateNow("inspection map switch")
end

function RaceService.SetInspectionUnlimitedTime(value: boolean)
	if not RunService:IsStudio() then return end
	inspectionUnlimitedTime = value
	if currentRaceState == RaceConstants.RaceState.Racing then broadcastTimerUpdate() end
end

function RaceService.IsInspectionUnlimitedTime(): boolean
	return RunService:IsStudio() and inspectionUnlimitedTime
end
function RaceService.ApplyStudioAction(action: string): boolean
    if not RunService:IsStudio() then return false end
    if action == "StartEvent" then
        if currentRaceState ~= RaceConstants.RaceState.WaitingForPlayers then return false end
        studioHoldInLobby,studioStandalone,devStartRaceNowRequested = false,false,false
        return true
    end
    if action == "StartRace" or action == "RestartRace" or action == "HoldLobby" then
        studioStandalone = true
        if action ~= "HoldLobby" then playerRaceService.ForceEnrollReadyPlayersForStudio() end
        if tournamentService then tournamentService.Cancel() end
    end
    if action == "HoldLobby" then
        studioHoldInLobby = true
        RaceService.RestartInspectionRound()
    elseif action == "RestartRace" then
        studioHoldInLobby = false
        RaceService.RestartInspectionRound()
    elseif action == "StartRace" then
        studioHoldInLobby = false
        if currentRaceState == RaceConstants.RaceState.WaitingForPlayers
            or currentRaceState == RaceConstants.RaceState.Intermission
            or currentRaceState == RaceConstants.RaceState.Countdown then
            devStartRaceNowRequested = true
            endCurrentTimedStateNow("Studio start")
        else return false end
    elseif action == "NextState" then
        if currentRaceState == RaceConstants.RaceState.WaitingForPlayers then return false end
        endCurrentTimedStateNow("Studio next state")
    elseif action == "EndRace" then
        if currentRaceState ~= RaceConstants.RaceState.Racing then return false end
        endCurrentTimedStateNow("Studio end race")
    else return false end
    return true
end

function RaceService.IsStudioHoldingLobby(): boolean
    return RunService:IsStudio() and studioHoldInLobby
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

function RaceService.GetPreparation() return standalonePreparation end
function RaceService.GetCourseInfo(): any
 local model=courseService and courseService.GetActiveCourse()
 if model and model==cachedCourseModel and cachedCourseInfo then return table.clone(cachedCourseInfo) end
 local info=courseService and courseService.GetActiveCourseInfo() or {}
 if courseService then info=table.clone(info);info.checkpointCount=#courseService.GetOrderedCheckpoints() end
 cachedCourseModel=model
 cachedCourseInfo=Identity.Read(model,info)
 return table.clone(cachedCourseInfo)
end

return RaceService
