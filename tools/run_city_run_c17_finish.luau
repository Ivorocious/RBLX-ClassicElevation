local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

assert(RunService:IsStudio() and RunService:IsServer(), "Run in Studio server Play")

local function sourceFactory(game, require, script)
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local RaceTypes = require(ReplicatedStorage.Shared.RaceTypes)

type RaceState = RaceTypes.RaceState
type PlayerRaceStatus = RaceTypes.PlayerRaceStatus
type PlayerRaceResult = RaceTypes.PlayerRaceResult

type ServiceContext = {
	Services: { [string]: any },
}

type FinishMovementLock = {
	rootPart: BasePart,
	wasAnchored: boolean,
}

local PlayerRaceService = {}

local isInitialized = false
local isStarted = false
local ghostService: any = nil
local currentRaceState: RaceState = RaceConstants.RaceState.WaitingForPlayers
local currentRaceId = ""

local playerStatuses: { [Player]: PlayerRaceStatus } = {}
local officialRaceEligible: { [Player]: boolean } = {}
local finishMovementLocks: { [Player]: FinishMovementLock } = {}
local characterAddedConnections: { [Player]: RBXScriptConnection } = {}

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local playerRaceStatusChangedRemote =
	remotesFolder:WaitForChild(RaceConstants.RemoteNames.PlayerRaceStatusChanged) :: RemoteEvent
local requestSpectateRemote =
	remotesFolder:WaitForChild(RaceConstants.RemoteNames.RequestSpectate) :: RemoteEvent
local requestRaceLateRemote =
	remotesFolder:WaitForChild(RaceConstants.RemoteNames.RequestRaceLate) :: RemoteEvent
local requestGhostRaceRemote =
	remotesFolder:WaitForChild(RaceConstants.RemoteNames.RequestGhostRace) :: RemoteEvent

local function getServerTime(): number
	return Workspace:GetServerTimeNow()
end

local function broadcastStatusChanged(
	player: Player,
	previousStatus: PlayerRaceStatus?,
	status: PlayerRaceStatus,
	reason: string?
)
	playerRaceStatusChangedRemote:FireAllClients({
		raceId = currentRaceId,
		userId = player.UserId,
		name = player.Name,
		displayName = player.DisplayName,
		previousStatus = previousStatus,
		status = status,
		reason = reason,
		serverTime = getServerTime(),
	})
end

local function buildResultRecord(player: Player, status: PlayerRaceStatus, reason: string?): PlayerRaceResult
	return {
		userId = player.UserId,
		name = player.Name,
		displayName = player.DisplayName,
		status = status,
		official = officialRaceEligible[player] == true,
		placement = nil,
		finishTime = nil,
		falls = 0,
		checkpointSplits = {},
		dnfReason = reason,
		isPersonalBest = false,
		summaryNotes = {},
	}
end

local function shouldQueuePlayerForCurrentState(): boolean
	return currentRaceState == RaceConstants.RaceState.Intermission
		or currentRaceState == RaceConstants.RaceState.Countdown
end

local function isAcceptingLateRaceChoices(): boolean
	return currentRaceState == RaceConstants.RaceState.Racing
end

local function warnRejectedRequest(player: Player, requestName: string)
	warn(
		string.format(
			"[PlayerRaceService] Rejected %s from %s in state %s with status %s.",
			requestName,
			player.Name,
			currentRaceState,
			tostring(playerStatuses[player])
		)
	)
end

local function releaseFinishMovementLock(player: Player)
	local movementLock = finishMovementLocks[player]
	finishMovementLocks[player] = nil

	if movementLock ~= nil and movementLock.rootPart.Parent ~= nil then
		movementLock.rootPart.Anchored = movementLock.wasAnchored
	end
end

local function applyFinishMovementLock(player: Player, character: Model?)
	local currentCharacter = character or player.Character

	if currentCharacter == nil then
		return
	end

	local rootPart = currentCharacter:FindFirstChild("HumanoidRootPart")

	if rootPart == nil or not rootPart:IsA("BasePart") then
		return
	end

	local currentLock = finishMovementLocks[player]

	if currentLock ~= nil and currentLock.rootPart == rootPart then
		rootPart.Anchored = true
		return
	end

	releaseFinishMovementLock(player)
	finishMovementLocks[player] = {
		rootPart = rootPart,
		wasAnchored = rootPart.Anchored,
	}
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.Anchored = true
end

local function updateFinishMovementLock(player: Player, status: PlayerRaceStatus)
	if status == RaceConstants.PlayerRaceStatus.Finished then
		applyFinishMovementLock(player, nil)
	else
		releaseFinishMovementLock(player)
	end
end

local function handleCharacterAdded(player: Player, character: Model)
	task.defer(function()
		local rootPart = character:WaitForChild("HumanoidRootPart", 10)

		if rootPart ~= nil
			and player.Character == character
			and playerStatuses[player] == RaceConstants.PlayerRaceStatus.Finished
		then
			applyFinishMovementLock(player, character)
		end
	end)
end

local function handlePlayerAdded(player: Player)
	characterAddedConnections[player] = player.CharacterAdded:Connect(function(character)
		handleCharacterAdded(player, character)
	end)

	if shouldQueuePlayerForCurrentState() then
		PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Queued, "Joined before race start")
		officialRaceEligible[player] = true
	else
		PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Lobby, "Joined server")
		officialRaceEligible[player] = false
	end
end

local function handlePlayerRemoving(player: Player)
	releaseFinishMovementLock(player)

	local characterAddedConnection = characterAddedConnections[player]

	if characterAddedConnection ~= nil then
		characterAddedConnection:Disconnect()
		characterAddedConnections[player] = nil
	end

	playerStatuses[player] = nil
	officialRaceEligible[player] = nil
end

local function updateGhostMode(player: Player, _previousStatus: PlayerRaceStatus?, nextStatus: PlayerRaceStatus)
	if ghostService == nil or ghostService.SetPlayerGhostMode == nil then
		return
	end

	local shouldGhost = nextStatus == RaceConstants.PlayerRaceStatus.GhostRacing

	local didUpdate, errorMessage = pcall(ghostService.SetPlayerGhostMode, player, shouldGhost)

	if not didUpdate then
		warn(
			string.format(
				"[PlayerRaceService] Ghost mode update failed for %s: %s",
				player.Name,
				tostring(errorMessage)
			)
		)
	end
end

function PlayerRaceService.Init(context: ServiceContext?)
	if isInitialized then
		return
	end

	if context ~= nil then
		ghostService = context.Services.GhostService
	end

	if ghostService == nil then
		warn("[PlayerRaceService] GhostService dependency is missing.")
	end

	isInitialized = true
end

function PlayerRaceService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[PlayerRaceService] Start called before Init.")
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

	requestSpectateRemote.OnServerEvent:Connect(function(player)
		PlayerRaceService.RequestSpectate(player)
	end)

	requestRaceLateRemote.OnServerEvent:Connect(function(player)
		PlayerRaceService.RequestRaceLate(player)
	end)

	requestGhostRaceRemote.OnServerEvent:Connect(function(player)
		PlayerRaceService.RequestGhostRace(player)
	end)
end

function PlayerRaceService.OnRaceStateChanged(nextRaceState: RaceState, raceId: string?)
	currentRaceState = nextRaceState
	currentRaceId = raceId or currentRaceId
end

function PlayerRaceService.GetEligiblePlayerCount(): number
	local count = 0

	for _, player in ipairs(Players:GetPlayers()) do
		local status = playerStatuses[player]

		if status == nil
			or status == RaceConstants.PlayerRaceStatus.Lobby
			or status == RaceConstants.PlayerRaceStatus.Queued
		then
			count += 1
		end
	end

	return count
end

function PlayerRaceService.GetPlayerStatus(player: Player): PlayerRaceStatus?
	return playerStatuses[player]
end

function PlayerRaceService.GetQueuedPlayers(): { Player }
	local queuedPlayers = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if playerStatuses[player] == RaceConstants.PlayerRaceStatus.Queued then
			table.insert(queuedPlayers, player)
		end
	end

	return queuedPlayers
end

function PlayerRaceService.IsOfficialRacer(player: Player): boolean
	return officialRaceEligible[player] == true
end

function PlayerRaceService.SetPlayerStatus(player: Player, status: PlayerRaceStatus, reason: string?)
	local previousStatus = playerStatuses[player]

	if previousStatus == status then
		updateGhostMode(player, previousStatus, status)
		updateFinishMovementLock(player, status)
		return
	end

	playerStatuses[player] = status
	updateGhostMode(player, previousStatus, status)
	updateFinishMovementLock(player, status)
	broadcastStatusChanged(player, previousStatus, status, reason)
	print(string.format("[PlayerRaceService] %s status -> %s", player.Name, status))
end

function PlayerRaceService.CanSpectate(player: Player): boolean
	local status = playerStatuses[player]

	return isAcceptingLateRaceChoices()
		and (
			status == RaceConstants.PlayerRaceStatus.Lobby
			or status == RaceConstants.PlayerRaceStatus.Finished
			or status == RaceConstants.PlayerRaceStatus.Spectating
			or status == RaceConstants.PlayerRaceStatus.LateRacing
		)
end

function PlayerRaceService.CanRaceLate(player: Player): boolean
	local status = playerStatuses[player]

	return isAcceptingLateRaceChoices()
		and (
			status == RaceConstants.PlayerRaceStatus.Lobby
			or status == RaceConstants.PlayerRaceStatus.Spectating
			or status == RaceConstants.PlayerRaceStatus.LateRacing
		)
end

function PlayerRaceService.CanGhostRace(player: Player): boolean
	return isAcceptingLateRaceChoices()
		and playerStatuses[player] == RaceConstants.PlayerRaceStatus.Finished
end

function PlayerRaceService.RequestSpectate(player: Player): boolean
	if not PlayerRaceService.CanSpectate(player) then
		warnRejectedRequest(player, RaceConstants.RemoteNames.RequestSpectate)
		return false
	end

	officialRaceEligible[player] = false
	PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Spectating, "Requested spectate")
	return true
end

function PlayerRaceService.RequestRaceLate(player: Player): boolean
	if not PlayerRaceService.CanRaceLate(player) then
		warnRejectedRequest(player, RaceConstants.RemoteNames.RequestRaceLate)
		return false
	end

	officialRaceEligible[player] = false
	PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.LateRacing, "Requested late race")
	return true
end

function PlayerRaceService.RequestGhostRace(player: Player): boolean
	if not PlayerRaceService.CanGhostRace(player) then
		warnRejectedRequest(player, RaceConstants.RemoteNames.RequestGhostRace)
		return false
	end

	officialRaceEligible[player] = false
	PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.GhostRacing, "Requested ghost race")
	return true
end

function PlayerRaceService.QueueEligiblePlayers()
	for _, player in ipairs(Players:GetPlayers()) do
		local status = playerStatuses[player]

		if status == nil or status == RaceConstants.PlayerRaceStatus.Lobby then
			officialRaceEligible[player] = true
			PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Queued, "Queued for next race")
		end
	end
end

function PlayerRaceService.StartQueuedPlayers(): { Player }
	local startedPlayers = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if playerStatuses[player] == RaceConstants.PlayerRaceStatus.Queued then
			officialRaceEligible[player] = true
			table.insert(startedPlayers, player)
			PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Racing, "Race started")
		end
	end

	return startedPlayers
end

function PlayerRaceService.MarkUnfinishedRacersDNF(reason: string): { PlayerRaceResult }
	local dnfResults = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local status = playerStatuses[player]

		if officialRaceEligible[player] == true
			and (status == RaceConstants.PlayerRaceStatus.Racing or status == RaceConstants.PlayerRaceStatus.Queued)
		then
			PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.DNF, reason)
			table.insert(dnfResults, buildResultRecord(player, RaceConstants.PlayerRaceStatus.DNF, reason))
		end
	end

	return dnfResults
end

function PlayerRaceService.ResetPlayersForNextRound(reason: string?)
	for _, player in ipairs(Players:GetPlayers()) do
		officialRaceEligible[player] = false
		PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Lobby, reason or "Round reset")
	end
end

return PlayerRaceService
end

local function newSignal()
	local handlers = {}

	return {
		Connect = function(_self, handler)
			table.insert(handlers, handler)
			local connected = true

			return {
				Disconnect = function()
					if not connected then
						return
					end

					connected = false
					local index = table.find(handlers, handler)

					if index ~= nil then
						table.remove(handlers, index)
					end
				end,
			}
		end,
		Fire = function(_self, ...)
			for _, handler in ipairs(table.clone(handlers)) do
				handler(...)
			end
		end,
	}
end

local statusChangedRemote = {
	OnServerEvent = newSignal(),
	FireAllClients = function() end,
}
local requestSpectateRemote = {
	OnServerEvent = newSignal(),
	FireAllClients = function() end,
}
local requestRaceLateRemote = {
	OnServerEvent = newSignal(),
	FireAllClients = function() end,
}
local requestGhostRaceRemote = {
	OnServerEvent = newSignal(),
	FireAllClients = function() end,
}

local remotesByName = {
	PlayerRaceStatusChanged = statusChangedRemote,
	RequestSpectate = requestSpectateRemote,
	RequestRaceLate = requestRaceLateRemote,
	RequestGhostRace = requestGhostRaceRemote,
}
local remotesFolder = {
	WaitForChild = function(_self, name)
		return assert(remotesByName[name], "Unexpected remote " .. tostring(name))
	end,
}
local raceConstantsToken = {}
local raceTypesToken = {}
local raceConstants = {
	RaceState = {
		WaitingForPlayers = "WaitingForPlayers",
		Intermission = "Intermission",
		Countdown = "Countdown",
		Racing = "Racing",
	},
	PlayerRaceStatus = {
		Lobby = "Lobby",
		Queued = "Queued",
		Racing = "Racing",
		LateRacing = "LateRacing",
		Finished = "Finished",
		DNF = "DNF",
		Spectating = "Spectating",
		GhostRacing = "GhostRacing",
	},
	RemoteNames = {
		PlayerRaceStatusChanged = "PlayerRaceStatusChanged",
		RequestSpectate = "RequestSpectate",
		RequestRaceLate = "RequestRaceLate",
		RequestGhostRace = "RequestGhostRace",
	},
}
local fakeReplicatedStorage = {
	Shared = {
		RaceConstants = raceConstantsToken,
		RaceTypes = raceTypesToken,
	},
	WaitForChild = function(_self, name)
		assert(name == "Remotes", "Unexpected ReplicatedStorage child " .. tostring(name))
		return remotesFolder
	end,
}
local fakePlayerList = {}
local fakePlayers = {
	PlayerAdded = newSignal(),
	PlayerRemoving = newSignal(),
	GetPlayers = function()
		return fakePlayerList
	end,
}
local fakeWorkspace = {
	GetServerTimeNow = function()
		return workspace:GetServerTimeNow()
	end,
}
local fakeGame = {
	GetService = function(_self, name)
		if name == "Players" then
			return fakePlayers
		elseif name == "ReplicatedStorage" then
			return fakeReplicatedStorage
		elseif name == "Workspace" then
			return fakeWorkspace
		end

		error("Unexpected service " .. tostring(name))
	end,
}

local function resolveRequire(moduleToken)
	if moduleToken == raceConstantsToken then
		return raceConstants
	elseif moduleToken == raceTypesToken then
		return {}
	end

	error("Unexpected module dependency")
end

local PlayerRaceService = sourceFactory(fakeGame, resolveRequire, nil)
local ghostCalls = {}
local ghostService = {
	SetPlayerGhostMode = function(player, isGhost)
		table.insert(ghostCalls, {
			player = player.Name,
			isGhost = isGhost,
			anchoredAtCall = player.Character.HumanoidRootPart.Anchored,
		})
	end,
}
PlayerRaceService.Init({
	Services = {
		GhostService = ghostService,
	},
})
PlayerRaceService.OnRaceStateChanged(raceConstants.RaceState.Racing, "c17-finish-test")
PlayerRaceService.Start()

local fixture = Instance.new("Folder")
fixture.Name = "__C17FinishLockTest"
fixture.Parent = workspace

local function newCharacter(name)
	local character = Instance.new("Model")
	character.Name = name

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = false
	root.AssemblyLinearVelocity = Vector3.new(12, 8, -4)
	root.AssemblyAngularVelocity = Vector3.new(1, 2, 3)
	root.Parent = character

	character.Parent = fixture
	root.AssemblyLinearVelocity = Vector3.new(12, 8, -4)
	root.AssemblyAngularVelocity = Vector3.new(1, 2, 3)
	return character, root
end

local function newPlayer(name, userId)
	local characterAdded = newSignal()
	local character = newCharacter(name .. "_Character")
	local player = {
		Name = name,
		DisplayName = name,
		UserId = userId,
		Character = character,
		CharacterAdded = characterAdded,
	}
	table.insert(fakePlayerList, player)
	fakePlayers.PlayerAdded:Fire(player)

	return player, characterAdded, character
end

local checks = {}
local function record(name, passed, detail)
	assert(passed, name .. ": " .. detail)
	table.insert(checks, {
		name = name,
		passed = true,
		detail = detail,
	})
end

local ok, failure = xpcall(function()
	local spectatePlayer, _, spectateCharacter = newPlayer("C17Spectate", 17001)
	local spectateRoot = spectateCharacter.HumanoidRootPart

	PlayerRaceService.SetPlayerStatus(spectatePlayer, raceConstants.PlayerRaceStatus.Racing, "test setup")
	PlayerRaceService.SetPlayerStatus(spectatePlayer, raceConstants.PlayerRaceStatus.Finished, "test finish")
	record(
		"FinishedLocksNormalRoot",
		spectateRoot.Anchored
			and spectateRoot.AssemblyLinearVelocity == Vector3.zero
			and spectateRoot.AssemblyAngularVelocity == Vector3.zero,
		"Finished must anchor the root and clear linear/angular velocity"
	)

	local invalidAccepted = PlayerRaceService.RequestRaceLate(spectatePlayer)
	record(
		"RejectedChoiceStaysLocked",
		not invalidAccepted
			and PlayerRaceService.GetPlayerStatus(spectatePlayer) == raceConstants.PlayerRaceStatus.Finished
			and spectateRoot.Anchored,
		"Race Late is invalid after finishing and must not release the lock"
	)

	local spectateAccepted = PlayerRaceService.RequestSpectate(spectatePlayer)
	record(
		"AcceptedSpectateUnlocks",
		spectateAccepted
			and PlayerRaceService.GetPlayerStatus(spectatePlayer) == raceConstants.PlayerRaceStatus.Spectating
			and not spectateRoot.Anchored,
		"Accepted Spectate must release the finish lock"
	)

	local ghostPlayer, _, ghostCharacter = newPlayer("C17Ghost", 17002)
	local ghostRoot = ghostCharacter.HumanoidRootPart
	PlayerRaceService.SetPlayerStatus(ghostPlayer, raceConstants.PlayerRaceStatus.Racing, "test setup")
	PlayerRaceService.SetPlayerStatus(ghostPlayer, raceConstants.PlayerRaceStatus.Finished, "test finish")
	local ghostCallStart = #ghostCalls
	local ghostAccepted = PlayerRaceService.RequestGhostRace(ghostPlayer)
	local ghostCall = ghostCalls[#ghostCalls]
	record(
		"AcceptedGhostUnlocks",
		ghostAccepted
			and PlayerRaceService.GetPlayerStatus(ghostPlayer) == raceConstants.PlayerRaceStatus.GhostRacing
			and not ghostRoot.Anchored,
		"Accepted Ghost Race must release the finish lock"
	)
	record(
		"GhostUpdatePrecedesSafeRelease",
		#ghostCalls == ghostCallStart + 1 and ghostCall.isGhost and ghostCall.anchoredAtCall,
		"Ghost mode runs while still anchored, then the finish lock restores the prior state"
	)

	local respawnPlayer, characterAdded, firstCharacter = newPlayer("C17Respawn", 17003)
	local firstRoot = firstCharacter.HumanoidRootPart
	PlayerRaceService.SetPlayerStatus(respawnPlayer, raceConstants.PlayerRaceStatus.Racing, "test setup")
	PlayerRaceService.SetPlayerStatus(respawnPlayer, raceConstants.PlayerRaceStatus.Finished, "test finish")
	local secondCharacter, secondRoot = newCharacter("C17Respawn_Replacement")
	respawnPlayer.Character = secondCharacter
	characterAdded:Fire(secondCharacter)
	task.wait()
	record(
		"FinishedRespawnRelocks",
		not firstRoot.Anchored and secondRoot.Anchored,
		"Replacement character is locked and the old character's prior anchor state is restored"
	)

	PlayerRaceService.ResetPlayersForNextRound("round reset")
	record(
		"RoundResetReleasesLock",
		not secondRoot.Anchored,
		"Round reset releases the lock because finish options are no longer available"
	)
end, debug.traceback)

local result = Instance.new("StringValue")
result.Name = "C17FinishLockResult"
result.Value = HttpService:JSONEncode({
	build = "C17",
	passed = ok,
	checks = checks,
	error = if ok then nil else failure,
	method = "Inline exact PlayerRaceService source with only service, remote, player, and race-constant dependencies stubbed",
	limitation = "This isolates server status and character-root behavior. It does not exercise the live UI/camera. Round reset intentionally releases the lock because the finish choices disappear.",
})
result.Parent = game.ServerStorage

fixture:Destroy()
assert(ok, failure)
return result.Value
