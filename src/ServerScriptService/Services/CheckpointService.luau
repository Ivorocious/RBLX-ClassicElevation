--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CheckpointConfig = require(ReplicatedStorage.Config.CheckpointConfig)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local RaceTypes = require(ReplicatedStorage.Shared.RaceTypes)

type PlayerRaceStatus = RaceTypes.PlayerRaceStatus
type RaceFormat = RaceTypes.RaceFormat

type ServiceContext = {
	Services: { [string]: any },
}

type CheckpointDefinition = {
	index: number,
	name: string,
	part: BasePart,
}

type PlayerCheckpointProgress = {
	raceId: string,
	raceFormat: RaceFormat,
	currentLap: number,
	requiredLaps: number,
	lapStartedAt: number,
	nextCheckpointIndex: number,
	finished: boolean,
	completedCheckpointIndexes: { [number]: boolean },
}

local CheckpointService = {}

local isInitialized = false
local isStarted = false
local raceService: any = nil
local courseService: any = nil
local playerRaceService: any = nil
local resultsService: any = nil
local checkpointDefinitions: { CheckpointDefinition } = {}
local finishPart: BasePart? = nil
local startPart: BasePart? = nil
local playerProgressByUserId: { [number]: PlayerCheckpointProgress } = {}
local touchConnections: { RBXScriptConnection } = {}
local RESPAWN_VERTICAL_OFFSET = 5

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

local function getElapsedRaceTime(): number?
	if raceService == nil or raceService.GetElapsedRaceTime == nil then
		return nil
	end

	return raceService.GetElapsedRaceTime()
end

local function getPlayerStatus(player: Player): PlayerRaceStatus?
	if playerRaceService == nil or playerRaceService.GetPlayerStatus == nil then
		return nil
	end

	return playerRaceService.GetPlayerStatus(player)
end

local function getActiveRaceFormat(): RaceFormat
	if courseService ~= nil and courseService.GetRaceFormat ~= nil then
		local raceFormat = courseService.GetRaceFormat()

		if raceFormat == RaceConstants.RaceFormat.LapBased then
			return RaceConstants.RaceFormat.LapBased
		end
	end

	return RaceConstants.RaceFormat.PointToPoint
end

local function getRequiredLaps(raceFormat: RaceFormat): number
	if raceFormat ~= RaceConstants.RaceFormat.LapBased then
		return 1
	end

	if courseService ~= nil and courseService.GetLapCount ~= nil then
		return math.max(1, courseService.GetLapCount())
	end

	return 1
end

local function isOfficialRacer(player: Player): boolean
	return playerRaceService ~= nil
		and playerRaceService.IsOfficialRacer ~= nil
		and playerRaceService.IsOfficialRacer(player) == true
end

local function isValidOfficialRacer(player: Player): boolean
	return isRaceActive()
		and isOfficialRacer(player)
		and getPlayerStatus(player) == RaceConstants.PlayerRaceStatus.Racing
end

local function getOrCreatePlayerProgress(player: Player, raceId: string): PlayerCheckpointProgress
	local playerProgress = playerProgressByUserId[player.UserId]

	if playerProgress == nil or playerProgress.raceId ~= raceId then
		local raceFormat = getActiveRaceFormat()

		playerProgress = {
			raceId = raceId,
			raceFormat = raceFormat,
			currentLap = CheckpointConfig.DefaultLapNumber,
			requiredLaps = getRequiredLaps(raceFormat),
			lapStartedAt = 0,
			nextCheckpointIndex = CheckpointConfig.StartingCheckpointIndex + 1,
			finished = false,
			completedCheckpointIndexes = {},
		}
		playerProgressByUserId[player.UserId] = playerProgress
	end

	return playerProgress
end

local function hasCompletedAllCheckpoints(playerProgress: PlayerCheckpointProgress): boolean
	return playerProgress.nextCheckpointIndex > #checkpointDefinitions
end

local function updateResultCheckpointProgress(player: Player, playerProgress: PlayerCheckpointProgress)
	if resultsService == nil or resultsService.UpdateCheckpointProgress == nil then
		return
	end

	resultsService.UpdateCheckpointProgress(
		player,
		playerProgress.currentLap,
		playerProgress.requiredLaps,
		playerProgress.nextCheckpointIndex,
		#checkpointDefinitions
	)
end

local function getCheckpointDefinitionByIndex(checkpointIndex: number): CheckpointDefinition?
	for _, checkpointDefinition in ipairs(checkpointDefinitions) do
		if checkpointDefinition.index == checkpointIndex then
			return checkpointDefinition
		end
	end

	return nil
end

local function bindCheckpointPart(checkpointDefinition: CheckpointDefinition)
	local connection = checkpointDefinition.part.Touched:Connect(function(touchedPart)
		local player = getPlayerFromTouchedPart(touchedPart)

		if player == nil or not isValidOfficialRacer(player) then
			return
		end

		local raceId = getCurrentRaceId()

		if raceId == "" then
			return
		end

		local playerProgress = getOrCreatePlayerProgress(player, raceId)

		if playerProgress.finished then
			return
		end

		if playerProgress.completedCheckpointIndexes[checkpointDefinition.index] == true then
			return
		end

		if checkpointDefinition.index ~= playerProgress.nextCheckpointIndex then
			return
		end

		local elapsedRaceTime = getElapsedRaceTime()

		if elapsedRaceTime == nil then
			return
		end

		playerProgress.completedCheckpointIndexes[checkpointDefinition.index] = true
		playerProgress.nextCheckpointIndex += 1

		if resultsService ~= nil and resultsService.RecordCheckpointSplit ~= nil then
			resultsService.RecordCheckpointSplit(
				player,
				checkpointDefinition.index,
				checkpointDefinition.name,
				playerProgress.currentLap,
				elapsedRaceTime
			)
		end

		updateResultCheckpointProgress(player, playerProgress)

		print(
			string.format(
				"[CheckpointService] %s completed %s.",
				player.Name,
				checkpointDefinition.name
			)
		)
	end)

	table.insert(touchConnections, connection)
end

local function bindFinishPart(part: BasePart)
	local connection = part.Touched:Connect(function(touchedPart)
		local player = getPlayerFromTouchedPart(touchedPart)

		if player == nil or not isValidOfficialRacer(player) then
			return
		end

		local raceId = getCurrentRaceId()

		if raceId == "" then
			return
		end

		local playerProgress = getOrCreatePlayerProgress(player, raceId)

		if playerProgress.finished or not hasCompletedAllCheckpoints(playerProgress) then
			return
		end

		local elapsedRaceTime = getElapsedRaceTime()

		if elapsedRaceTime == nil then
			return
		end

		if resultsService == nil or resultsService.RecordFinish == nil then
			return
		end

		if playerProgress.raceFormat == RaceConstants.RaceFormat.LapBased then
			local lapTime = elapsedRaceTime - playerProgress.lapStartedAt
			local nextLap = math.min(playerProgress.currentLap + 1, playerProgress.requiredLaps)

			if resultsService.RecordLapComplete ~= nil then
				resultsService.RecordLapComplete(
					player,
					playerProgress.currentLap,
					lapTime,
					nextLap,
					playerProgress.requiredLaps
				)
			end

			if playerProgress.currentLap < playerProgress.requiredLaps then
				print(
					string.format(
						"[CheckpointService] %s completed lap %d/%d.",
						player.Name,
						playerProgress.currentLap,
						playerProgress.requiredLaps
					)
				)

				playerProgress.currentLap += 1
				playerProgress.lapStartedAt = elapsedRaceTime
				playerProgress.nextCheckpointIndex = CheckpointConfig.StartingCheckpointIndex + 1
				playerProgress.completedCheckpointIndexes = {}
				updateResultCheckpointProgress(player, playerProgress)
				return
			end
		end

		local finishResult = resultsService.RecordFinish(player, elapsedRaceTime)

		if finishResult == nil then
			return
		end

		playerProgress.finished = true

		if playerRaceService ~= nil and playerRaceService.SetPlayerStatus ~= nil then
			playerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Finished, "Finished race")
		end

		print(
			string.format(
				"[CheckpointService] %s finished %s in %.3fs.",
				player.Name,
				raceId,
				elapsedRaceTime
			)
		)
	end)

	table.insert(touchConnections, connection)
end

local function bindCourse()
	for _, connection in ipairs(touchConnections) do
		connection:Disconnect()
	end

	touchConnections = {}
	checkpointDefinitions = {}
	finishPart = nil
	startPart = nil

	if courseService == nil then
		warn("[CheckpointService] CourseService dependency is missing.")
		return
	end

	local activeCourse = if courseService.GetActiveCourseModel ~= nil then courseService.GetActiveCourseModel() else nil
	local activeCourseName = if activeCourse ~= nil then activeCourse.Name else "active course"
	local startInstance = if courseService.GetStartPart ~= nil then courseService.GetStartPart() else nil
	local finishInstance = if courseService.GetFinishPart ~= nil then courseService.GetFinishPart() else nil
	local orderedCheckpoints = if courseService.GetOrderedCheckpoints ~= nil then courseService.GetOrderedCheckpoints() else {}

	if activeCourse == nil then
		warn("[CheckpointService] CourseService did not provide an active course.")
		return
	end

	if startInstance == nil then
		warn(string.format("[CheckpointService] %s start part is unavailable.", activeCourseName))
		return
	end

	if finishInstance == nil then
		warn(string.format("[CheckpointService] %s finish part is unavailable.", activeCourseName))
		return
	end

	checkpointDefinitions = orderedCheckpoints
	startPart = startInstance
	finishPart = finishInstance

	if #checkpointDefinitions == 0 then
		warn("[CheckpointService] No valid checkpoint parts were found.")
		return
	end

	for expectedIndex, checkpointDefinition in ipairs(checkpointDefinitions) do
		if checkpointDefinition.index ~= expectedIndex then
			warn(
				string.format(
					"[CheckpointService] Checkpoint order has a gap: expected index %d, found %d.",
					expectedIndex,
					checkpointDefinition.index
				)
			)
		end

		bindCheckpointPart(checkpointDefinition)
	end

	bindFinishPart(finishInstance)
	print(string.format("[CheckpointService] Bound %d checkpoints and finish part.", #checkpointDefinitions))
end

local function handlePlayerRemoving(player: Player)
	playerProgressByUserId[player.UserId] = nil
end

function CheckpointService.GetLatestCheckpointIndex(player: Player): number
	local raceId = getCurrentRaceId()
	local playerProgress = playerProgressByUserId[player.UserId]

	if raceId == "" or playerProgress == nil or playerProgress.raceId ~= raceId then
		return CheckpointConfig.StartingCheckpointIndex
	end

	return math.max(CheckpointConfig.StartingCheckpointIndex, playerProgress.nextCheckpointIndex - 1)
end

function CheckpointService.GetCheckpointRespawnCFrame(player: Player): CFrame?
	local latestCheckpointIndex = CheckpointService.GetLatestCheckpointIndex(player)
	local respawnPart = startPart

	if latestCheckpointIndex > CheckpointConfig.StartingCheckpointIndex then
		local checkpointDefinition = getCheckpointDefinitionByIndex(latestCheckpointIndex)

		if checkpointDefinition ~= nil then
			respawnPart = checkpointDefinition.part
		end
	end

	if respawnPart == nil then
		return nil
	end

	return CFrame.new(respawnPart.Position + Vector3.new(0, RESPAWN_VERTICAL_OFFSET, 0))
end

function CheckpointService.Init(context: ServiceContext?)
	if isInitialized then
		return
	end

	if context ~= nil then
		raceService = context.Services.RaceService
		courseService = context.Services.CourseService
		playerRaceService = context.Services.PlayerRaceService
		resultsService = context.Services.ResultsService
	end

	if raceService == nil then
		warn("[CheckpointService] RaceService dependency is missing.")
	end

	if courseService == nil then
		warn("[CheckpointService] CourseService dependency is missing.")
	end

	if playerRaceService == nil then
		warn("[CheckpointService] PlayerRaceService dependency is missing.")
	end

	if resultsService == nil then
		warn("[CheckpointService] ResultsService dependency is missing.")
	end

	isInitialized = true
end

function CheckpointService.BindActiveCourse()
	bindCourse()
end

function CheckpointService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[CheckpointService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true
	Players.PlayerRemoving:Connect(handlePlayerRemoving)
	CheckpointService.BindActiveCourse()
end

return CheckpointService
