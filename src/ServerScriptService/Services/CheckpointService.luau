--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CheckpointConfig = require(ReplicatedStorage.Config.CheckpointConfig)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local RaceTypes = require(ReplicatedStorage.Shared.RaceTypes)

type PlayerRaceStatus = RaceTypes.PlayerRaceStatus

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
	nextCheckpointIndex: number,
	finished: boolean,
	completedCheckpointIndexes: { [number]: boolean },
}

local CheckpointService = {}

local isInitialized = false
local isStarted = false
local raceService: any = nil
local playerRaceService: any = nil
local resultsService: any = nil
local checkpointDefinitions: { CheckpointDefinition } = {}
local finishPart: BasePart? = nil
local playerProgressByUserId: { [number]: PlayerCheckpointProgress } = {}
local touchConnections: { RBXScriptConnection } = {}

local function parseCheckpointIndex(checkpointName: string): number?
	local prefix = CheckpointConfig.CheckpointNamePrefix
	local padding = CheckpointConfig.CheckpointNumberPadding
	local digits = string.match(checkpointName, "^" .. prefix .. "_(%d+)$")

	if digits == nil or #digits ~= padding then
		return nil
	end

	return tonumber(digits)
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
		playerProgress = {
			raceId = raceId,
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
				CheckpointConfig.DefaultLapNumber,
				elapsedRaceTime
			)
		end

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

local function discoverCheckpointDefinitions(checkpointsFolder: Instance): { CheckpointDefinition }
	local discoveredCheckpoints = {}

	for _, child in ipairs(checkpointsFolder:GetChildren()) do
		if child:IsA("BasePart") then
			local checkpointIndex = parseCheckpointIndex(child.Name)

			if checkpointIndex ~= nil then
				table.insert(discoveredCheckpoints, {
					index = checkpointIndex,
					name = child.Name,
					part = child,
				})
			else
				warn(
					string.format(
						"[CheckpointService] Ignoring checkpoint with invalid name %s. Expected %s.",
						child.Name,
						CheckpointConfig.CheckpointNamingConvention
					)
				)
			end
		end
	end

	table.sort(discoveredCheckpoints, function(left, right)
		return left.index < right.index
	end)

	return discoveredCheckpoints
end

local function bindCourse()
	for _, connection in ipairs(touchConnections) do
		connection:Disconnect()
	end

	touchConnections = {}
	checkpointDefinitions = {}
	finishPart = nil

	local raceCourse = Workspace:FindFirstChild(CheckpointConfig.CourseModelName)

	if raceCourse == nil then
		warn(string.format("[CheckpointService] Workspace.%s was not found.", CheckpointConfig.CourseModelName))
		return
	end

	local checkpointsFolder = raceCourse:FindFirstChild(CheckpointConfig.CheckpointsFolderName)

	if checkpointsFolder == nil then
		warn(
			string.format(
				"[CheckpointService] %s.%s was not found.",
				CheckpointConfig.CourseModelName,
				CheckpointConfig.CheckpointsFolderName
			)
		)
		return
	end

	local finishInstance = raceCourse:FindFirstChild(CheckpointConfig.FinishPartName)

	if finishInstance == nil or not finishInstance:IsA("BasePart") then
		warn(
			string.format(
				"[CheckpointService] %s.%s must be a BasePart.",
				CheckpointConfig.CourseModelName,
				CheckpointConfig.FinishPartName
			)
		)
		return
	end

	checkpointDefinitions = discoverCheckpointDefinitions(checkpointsFolder)
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

function CheckpointService.Init(context: ServiceContext?)
	if isInitialized then
		return
	end

	if context ~= nil then
		raceService = context.Services.RaceService
		playerRaceService = context.Services.PlayerRaceService
		resultsService = context.Services.ResultsService
	end

	if raceService == nil then
		warn("[CheckpointService] RaceService dependency is missing.")
	end

	if playerRaceService == nil then
		warn("[CheckpointService] PlayerRaceService dependency is missing.")
	end

	if resultsService == nil then
		warn("[CheckpointService] ResultsService dependency is missing.")
	end

	isInitialized = true
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
	bindCourse()
end

return CheckpointService
