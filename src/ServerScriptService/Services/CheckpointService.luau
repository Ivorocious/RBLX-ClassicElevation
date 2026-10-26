--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ForwardGate = require(ReplicatedStorage.Shared.ForwardGate)

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
	lastCheckpointPart: BasePart?,
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

local function bindCheckpointPart(checkpointDefinition: CheckpointDefinition, triggerPart: BasePart)
	local connection = triggerPart.Touched:Connect(function(touchedPart)
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
		playerProgress.lastCheckpointPart = triggerPart
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
	local function acceptFinish(player: Player?)

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
				playerProgress.lastCheckpointPart = nil
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
	end
	local connection
	if part:GetAttribute("RequireForwardCrossing") == true then
		local samples = {}
		connection = RunService.Heartbeat:Connect(function(dt)
			for _, player in Players:GetPlayers() do
				local character = player.Character
				local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
				local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
				local immune = character and (character:GetAttribute("RecoveryUntil") or 0) > workspace:GetServerTimeNow()
				local old = samples[player.UserId]
				if root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 and not immune and isValidOfficialRacer(player) then
					if old and old.character == character and old.raceId == getCurrentRaceId()
						and ForwardGate.Crossed(part.CFrame, part.Size, old.position, root.Position, dt) then
						acceptFinish(player)
					end
					samples[player.UserId] = {position=root.Position, character=character, raceId=getCurrentRaceId()}
				else
					samples[player.UserId] = nil
				end
			end
		end)
	else
		connection = part.Touched:Connect(function(touchedPart)
			acceptFinish(getPlayerFromTouchedPart(touchedPart))
		end)
	end

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

		bindCheckpointPart(checkpointDefinition, checkpointDefinition.part)
		local alternatives = checkpointDefinition.part:FindFirstChild("AlternateTriggers")
		if alternatives then
			for _, trigger in alternatives:GetChildren() do
				if trigger:IsA("BasePart") then bindCheckpointPart(checkpointDefinition, trigger) end
			end
		end
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

function CheckpointService.SkipCheckpointForStudio(player: Player)
	if not game:GetService("RunService"):IsStudio() or not isValidOfficialRacer(player) then return end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return end
	local nextCheckpoint = getCheckpointDefinitionByIndex(CheckpointService.GetLatestCheckpointIndex(player) + 1)
	local target = if nextCheckpoint then nextCheckpoint.part else finishPart
	if not target then return end
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	character:PivotTo(target.CFrame + Vector3.new(0, RESPAWN_VERTICAL_OFFSET, 0))
	-- Landing uses the normal checkpoint touch validation and saves recovery progress.
end

function CheckpointService.SetInspectionCheckpointForStudio(player: Player, checkpointIndex: number): BasePart?
	if not game:GetService("RunService"):IsStudio()
		or courseService == nil
		or playerRaceService == nil
		or playerRaceService.GetPlayerStatus == nil
		or playerRaceService.IsOfficialRacer == nil
	then
		return nil
	end

	local status = playerRaceService.GetPlayerStatus(player)
	if (status ~= RaceConstants.PlayerRaceStatus.Racing and status ~= RaceConstants.PlayerRaceStatus.Finished)
		or playerRaceService.IsOfficialRacer(player) ~= true
	then
		return nil
	end

	local raceId = getCurrentRaceId()
	if raceId == "" then return nil end
	local targetPart = startPart
	if checkpointIndex ~= CheckpointConfig.StartingCheckpointIndex then
		local definition = getCheckpointDefinitionByIndex(checkpointIndex)
		targetPart = if definition ~= nil then definition.part else nil
	end
	if targetPart == nil then return nil end

	if status == RaceConstants.PlayerRaceStatus.Finished and playerRaceService.SetPlayerStatus ~= nil then
		playerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Racing, "Inspection checkpoint jump")
		if playerRaceService.GetPlayerStatus(player) ~= RaceConstants.PlayerRaceStatus.Racing then return nil end
	end

	local progress = getOrCreatePlayerProgress(player, raceId)
	progress.currentLap = CheckpointConfig.DefaultLapNumber
	progress.finished = false
	progress.completedCheckpointIndexes = {}
	if checkpointIndex == CheckpointConfig.StartingCheckpointIndex then
		progress.nextCheckpointIndex = CheckpointConfig.StartingCheckpointIndex + 1
		progress.lastCheckpointPart = nil
	else
		for _, definition in ipairs(checkpointDefinitions) do
			if definition.index <= checkpointIndex then progress.completedCheckpointIndexes[definition.index] = true end
		end
		progress.nextCheckpointIndex = checkpointIndex + 1
		progress.lastCheckpointPart = targetPart
	end
	updateResultCheckpointProgress(player, progress)
	return targetPart
end

function CheckpointService.GetCheckpointRespawnCFrame(player: Player): CFrame?
	local latestCheckpointIndex = CheckpointService.GetLatestCheckpointIndex(player)
	local respawnPart = startPart

	if latestCheckpointIndex > CheckpointConfig.StartingCheckpointIndex then
		local checkpointDefinition = getCheckpointDefinitionByIndex(latestCheckpointIndex)

		if checkpointDefinition ~= nil then
			respawnPart = checkpointDefinition.part
			local progress = playerProgressByUserId[player.UserId]
			local lastPart = progress and progress.lastCheckpointPart
			if lastPart and (lastPart == respawnPart or lastPart:IsDescendantOf(respawnPart)) then
				respawnPart = lastPart
			end
		end
	end

	if respawnPart == nil then
		return nil
	end

	local authoredRespawn = respawnPart:GetAttribute("RespawnCFrame")
	if typeof(authoredRespawn) == "CFrame" then
		local area = respawnPart:GetAttribute("RespawnAreaSize")
		if typeof(area) == "Vector3" and area.X >= 6 and area.Z >= 6 then
			local racers = game:GetService("Players"):GetPlayers()
			table.sort(racers, function(left, right) return left.UserId < right.UserId end)
			local index = table.find(racers, player) or 1
			local columns = math.max(1, 1 + math.floor((area.X - 3) / 4.5))
			local rows = math.max(1, 1 + math.floor((area.Z - 3) / 4.5))
			local capacity = columns * rows
			local fallback: CFrame? = nil
			for attempt = 0, capacity - 1 do
				local slot = (index - 1 + attempt) % capacity
				local x = (slot % columns - (columns - 1) / 2) * 4.5
				local z = (math.floor(slot / columns) - (rows - 1) / 2) * 4.5
				local candidate = authoredRespawn * CFrame.new(x, 0, z)
				fallback = fallback or candidate
				local occupied = false
				for _, racer in ipairs(racers) do
					local character = racer.Character
					local root = character and character:FindFirstChild("HumanoidRootPart")
					if racer ~= player and root and root:IsA("BasePart") then
						local delta = root.Position - candidate.Position
						if math.abs(delta.Y) < 8 and Vector3.new(delta.X, 0, delta.Z).Magnitude < 4 then
							occupied = true
							break
						end
					end
				end
				if not occupied then return candidate end
			end
			return fallback
		end
		return authoredRespawn
	end

	return respawnPart.CFrame + Vector3.new(0, RESPAWN_VERTICAL_OFFSET, 0)
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
