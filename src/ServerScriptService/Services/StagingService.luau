--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RaceConfig = require(ReplicatedStorage.Config.RaceConfig)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)

type ServiceContext = {
	Services: { [string]: any },
}

type GateVisualState = {
	transparency: number,
	canCollide: boolean,
}

local StagingService = {}

local isInitialized = false
local isStarted = false
local isStagingActive = false
local courseService: any = nil
local playerRaceService: any = nil

local activeCourse: Model? = nil
local activeStartPart: BasePart? = nil
local activeStartGate: BasePart? = nil
local gateVisualStates: { [BasePart]: GateVisualState } = {}
local formationIndexByPlayer: { [Player]: number } = {}
local stagedCharacterByPlayer: { [Player]: Model } = {}
local characterAddedConnections: { [Player]: RBXScriptConnection } = {}
local heartbeatAccumulator = 0
local nextFormationIndex = 1

local FORMATION_COLUMNS = 3
local FORMATION_SPACING = 4
local ESCAPE_CHECK_INTERVAL = 0.25
local HORIZONTAL_ESCAPE_MARGIN = 4
local LOWER_ESCAPE_MARGIN = 6
local UPPER_ESCAPE_MARGIN = 20

local function warnMissing(path: string)
	warn(string.format("[StagingService] %s was not found or was not a BasePart.", path))
end

local function getBasePart(instance: Instance?): BasePart?
	if instance ~= nil and instance:IsA("BasePart") then
		return instance
	end

	return nil
end

local function findFirstDescendantBasePart(parent: Instance): BasePart?
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end

	return nil
end

local function findLobbyPart(): BasePart?
	local lobby = Workspace:FindFirstChild(RaceConfig.LobbyModelName)

	if lobby == nil then
		warn(string.format("[StagingService] Workspace.%s was not found.", RaceConfig.LobbyModelName))
		return nil
	end

	local marker = getBasePart(lobby:FindFirstChild(RaceConfig.LobbySpawnMarkerName))

	if marker ~= nil then
		return marker
	end

	local fallback = getBasePart(lobby:FindFirstChild(RaceConfig.LobbyFallbackPartName))

	if fallback ~= nil then
		return fallback
	end

	local descendantFallback = findFirstDescendantBasePart(lobby)

	if descendantFallback == nil then
		warnMissing(
			string.format("Workspace.%s.%s", RaceConfig.LobbyModelName, RaceConfig.LobbySpawnMarkerName)
		)
	end

	return descendantFallback
end

local function getCharacterParts(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character

	if character == nil then
		return nil, nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local humanoidRootPart = getBasePart(character:FindFirstChild("HumanoidRootPart"))

	return character, humanoid, humanoidRootPart
end

local function getFormationOffset(index: number, startPart: BasePart): Vector3
	local zeroBasedIndex = math.max(0, index - 1)
	local column = zeroBasedIndex % FORMATION_COLUMNS
	local row = math.floor(zeroBasedIndex / FORMATION_COLUMNS)
	local xOffset = (column - math.floor(FORMATION_COLUMNS / 2)) * FORMATION_SPACING
	local maximumBackOffset = math.max(0, startPart.Size.Z / 2 - 3)
	local zOffset = math.min(row * FORMATION_SPACING, maximumBackOffset)

	return Vector3.new(xOffset, 0, zOffset)
end

local function getTargetCFrame(targetPart: BasePart, verticalOffset: number, index: number): CFrame
	local formationOffset = getFormationOffset(index, targetPart)
	local cframeWithFormation = targetPart.CFrame * CFrame.new(formationOffset)

	return cframeWithFormation + Vector3.new(0, verticalOffset, 0)
end

local function movePlayerToPart(
	player: Player,
	targetPart: BasePart,
	verticalOffset: number,
	index: number,
	reason: string
): Model?
	if not RaceConfig.StagingTeleportEnabled then
		return nil
	end

	local character, humanoid, humanoidRootPart = getCharacterParts(player)

	if character == nil or humanoid == nil or humanoidRootPart == nil or humanoid.Health <= 0 then
		return nil
	end

	humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
	humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
	character:PivotTo(getTargetCFrame(targetPart, verticalOffset, index))

	print(string.format("[StagingService] Moved %s to %s.", player.Name, reason))
	return character
end

local function openStartGate()
	if activeStartGate ~= nil and activeStartGate.Parent ~= nil then
		activeStartGate.CanCollide = false
	end

	for visualPart in pairs(gateVisualStates) do
		if visualPart.Parent ~= nil then
			visualPart.Transparency = 1
			visualPart.CanCollide = false
		end
	end
end

local function lockStartGate()
	if activeStartGate ~= nil and activeStartGate.Parent ~= nil then
		activeStartGate.CanCollide = true
	end

	for visualPart, authoredState in pairs(gateVisualStates) do
		if visualPart.Parent ~= nil then
			visualPart.Transparency = authoredState.transparency
			visualPart.CanCollide = authoredState.canCollide
		end
	end
end

local function bindActiveCourse()
	local course: Model? = nil

	if courseService ~= nil and courseService.GetActiveCourse ~= nil then
		local candidate = courseService.GetActiveCourse()

		if candidate ~= nil and candidate:IsA("Model") then
			course = candidate
		end
	end

	if course == nil then
		activeCourse = nil
		activeStartPart = nil
		activeStartGate = nil
		table.clear(gateVisualStates)
		warn("[StagingService] Active course is unavailable.")
		return
	end

	if course ~= activeCourse then
		activeCourse = course
		activeStartGate = nil
		table.clear(gateVisualStates)
	end

	activeStartPart = getBasePart(course:FindFirstChild(RaceConfig.RaceStartPartName))

	if activeStartPart == nil and courseService.GetStartPart ~= nil then
		activeStartPart = getBasePart(courseService.GetStartPart())
	end

	if activeStartPart == nil then
		warnMissing("active course Start")
	end

	local startPen = course:FindFirstChild("StartPen")

	if startPen == nil then
		return
	end

	activeStartGate = getBasePart(startPen:FindFirstChild("StartGate"))
	local gateVisuals = startPen:FindFirstChild("GateVisuals")

	if gateVisuals ~= nil then
		for _, descendant in ipairs(gateVisuals:GetDescendants()) do
			if descendant:IsA("BasePart") and gateVisualStates[descendant] == nil then
				gateVisualStates[descendant] = {
					transparency = descendant.Transparency,
					canCollide = descendant.CanCollide,
				}
			end
		end
	end
end

local function isQueuedPlayer(player: Player): boolean
	if playerRaceService == nil or playerRaceService.GetPlayerStatus == nil then
		return false
	end

	return playerRaceService.GetPlayerStatus(player) == RaceConstants.PlayerRaceStatus.Queued
end

local function addPlayerToStaging(player: Player, reason: string)
	if activeStartPart == nil then
		return
	end

	local formationIndex = formationIndexByPlayer[player]

	if formationIndex == nil then
		formationIndex = nextFormationIndex
		nextFormationIndex += 1
		formationIndexByPlayer[player] = formationIndex
	end

	local character = player.Character

	if character ~= nil and stagedCharacterByPlayer[player] == character then
		return
	end

	local stagedCharacter = movePlayerToPart(
		player,
		activeStartPart,
		RaceConfig.RacerStartVerticalOffset,
		formationIndex,
		reason
	)

	if stagedCharacter ~= nil then
		stagedCharacterByPlayer[player] = stagedCharacter
	end
end

local function isOutsideStartBounds(position: Vector3): boolean
	local startPart = activeStartPart

	if startPart == nil then
		return false
	end

	local localPosition = startPart.CFrame:PointToObjectSpace(position)
	local halfWidth = startPart.Size.X / 2 + HORIZONTAL_ESCAPE_MARGIN
	local halfDepth = startPart.Size.Z / 2 + HORIZONTAL_ESCAPE_MARGIN

	return math.abs(localPosition.X) > halfWidth
		or math.abs(localPosition.Z) > halfDepth
		or localPosition.Y < -LOWER_ESCAPE_MARGIN
		or localPosition.Y > UPPER_ESCAPE_MARGIN
end

local function refreshStagedPlayers()
	if not isStagingActive then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if formationIndexByPlayer[player] == nil and isQueuedPlayer(player) then
			addPlayerToStaging(player, "joined staging")
		else
			local _character, humanoid, humanoidRootPart = getCharacterParts(player)

			if formationIndexByPlayer[player] ~= nil
				and humanoid ~= nil
				and humanoid.Health > 0
				and humanoidRootPart ~= nil
				and isOutsideStartBounds(humanoidRootPart.Position)
			then
				stagedCharacterByPlayer[player] = nil
				addPlayerToStaging(player, "start pen recovery")
			end
		end
	end
end

local function handleCharacterAdded(player: Player, character: Model)
	task.delay(0.2, function()
		if not isStagingActive or player.Character ~= character then
			return
		end

		if formationIndexByPlayer[player] ~= nil or isQueuedPlayer(player) then
			stagedCharacterByPlayer[player] = nil
			addPlayerToStaging(player, "staging respawn")
		end
	end)
end

local function handlePlayerAdded(player: Player)
	characterAddedConnections[player] = player.CharacterAdded:Connect(function(character)
		handleCharacterAdded(player, character)
	end)

	if player.Character ~= nil then
		handleCharacterAdded(player, player.Character)
	end
end

local function handlePlayerRemoving(player: Player)
	formationIndexByPlayer[player] = nil
	stagedCharacterByPlayer[player] = nil

	local connection = characterAddedConnections[player]

	if connection ~= nil then
		connection:Disconnect()
		characterAddedConnections[player] = nil
	end
end

function StagingService.Init(context: ServiceContext?)
	if isInitialized then
		return
	end

	if context ~= nil then
		courseService = context.Services.CourseService
		playerRaceService = context.Services.PlayerRaceService
	end

	if courseService == nil then
		warn("[StagingService] CourseService dependency is missing.")
	end

	if playerRaceService == nil then
		warn("[StagingService] PlayerRaceService dependency is missing.")
	end

	isInitialized = true
end

function StagingService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[StagingService] Start called before Init.")
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

	RunService.Heartbeat:Connect(function(deltaTime)
		heartbeatAccumulator += deltaTime

		if heartbeatAccumulator < ESCAPE_CHECK_INTERVAL then
			return
		end

		heartbeatAccumulator = 0
		refreshStagedPlayers()
	end)
end

function StagingService.BeginStaging(players: { Player }, reason: string?)
	if not RaceConfig.StagingTeleportEnabled then
		return
	end

	table.clear(formationIndexByPlayer)
	table.clear(stagedCharacterByPlayer)
	nextFormationIndex = 1
	bindActiveCourse()
	isStagingActive = activeStartPart ~= nil
	lockStartGate()

	for _, player in ipairs(players) do
		addPlayerToStaging(player, reason or "intermission staging")
	end
end

function StagingService.MovePlayersToRaceStart(players: { Player }, reason: string?)
	if not RaceConfig.StagingTeleportEnabled then
		return
	end

	if not isStagingActive then
		bindActiveCourse()
		isStagingActive = activeStartPart ~= nil
		lockStartGate()
	end

	for _, player in ipairs(players) do
		addPlayerToStaging(player, reason or "race start")
	end
end

function StagingService.OnRaceStarted()
	openStartGate()
	isStagingActive = false
end

function StagingService.ClearStaging()
	openStartGate()
	isStagingActive = false
	table.clear(formationIndexByPlayer)
	table.clear(stagedCharacterByPlayer)
	nextFormationIndex = 1
end

function StagingService.ReturnPlayersToLobby(players: { Player }, reason: string?)
	if not RaceConfig.StagingTeleportEnabled then
		return
	end

	local lobbyPart = findLobbyPart()

	if lobbyPart == nil then
		return
	end

	for index, player in ipairs(players) do
		movePlayerToPart(player, lobbyPart, RaceConfig.LobbyResetVerticalOffset, index, reason or "lobby")
	end
end

function StagingService.ReturnAllPlayersToLobby(reason: string?)
	StagingService.ClearStaging()
	StagingService.ReturnPlayersToLobby(Players:GetPlayers(), reason)
end

return StagingService
