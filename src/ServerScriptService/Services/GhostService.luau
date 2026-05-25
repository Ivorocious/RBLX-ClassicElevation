--!strict

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)

type ServiceContext = {
	Services: { [string]: any },
}

local GhostService = {}

local isInitialized = false
local isStarted = false
local collisionGroupsInitialized = false
local ghostPlayers: { [Player]: boolean } = {}
local playerConnections: { [Player]: RBXScriptConnection } = {}
local characterConnections: { [Player]: RBXScriptConnection } = {}
local originalTransparencyByPart: { [BasePart]: number } = {}

local RACE_CHARACTER_GROUP = RaceConstants.CollisionGroups.RaceCharacter
local GHOST_CHARACTER_GROUP = RaceConstants.CollisionGroups.GhostCharacter
local DEFAULT_GROUP = RaceConstants.CollisionGroups.Default
local GHOST_TRANSPARENCY = 0.45

local function registerCollisionGroup(collisionGroupName: string)
	local didRegister = pcall(function()
		PhysicsService:RegisterCollisionGroup(collisionGroupName)
	end)

	if didRegister then
		return
	end

	pcall(function()
		PhysicsService:CreateCollisionGroup(collisionGroupName)
	end)
end

local function setGroupsCollidable(firstGroupName: string, secondGroupName: string, areCollidable: boolean)
	local didSet, errorMessage = pcall(function()
		PhysicsService:CollisionGroupSetCollidable(firstGroupName, secondGroupName, areCollidable)
	end)

	if not didSet then
		warn(
			string.format(
				"[GhostService] Failed to set %s/%s collidable=%s: %s",
				firstGroupName,
				secondGroupName,
				tostring(areCollidable),
				tostring(errorMessage)
			)
		)
	end
end

local function ensureCollisionGroups()
	if collisionGroupsInitialized then
		return
	end

	registerCollisionGroup(RACE_CHARACTER_GROUP)
	registerCollisionGroup(GHOST_CHARACTER_GROUP)

	setGroupsCollidable(RACE_CHARACTER_GROUP, RACE_CHARACTER_GROUP, true)
	setGroupsCollidable(RACE_CHARACTER_GROUP, DEFAULT_GROUP, true)
	setGroupsCollidable(GHOST_CHARACTER_GROUP, DEFAULT_GROUP, true)
	setGroupsCollidable(RACE_CHARACTER_GROUP, GHOST_CHARACTER_GROUP, false)
	setGroupsCollidable(GHOST_CHARACTER_GROUP, GHOST_CHARACTER_GROUP, false)

	collisionGroupsInitialized = true
end

local function setPartCollisionGroup(part: BasePart, collisionGroupName: string)
	local didSet = pcall(function()
		part.CollisionGroup = collisionGroupName
	end)

	if didSet then
		return
	end

	pcall(function()
		PhysicsService:SetPartCollisionGroup(part, collisionGroupName)
	end)
end

local function applyGhostVisual(part: BasePart)
	if originalTransparencyByPart[part] == nil then
		originalTransparencyByPart[part] = part.Transparency
	end

	part.Transparency = math.max(part.Transparency, GHOST_TRANSPARENCY)
end

local function restoreVisual(part: BasePart)
	local originalTransparency = originalTransparencyByPart[part]

	if originalTransparency == nil then
		return
	end

	part.Transparency = originalTransparency
	originalTransparencyByPart[part] = nil
end

local function applyPartMode(part: BasePart, isGhost: boolean)
	ensureCollisionGroups()

	if isGhost then
		setPartCollisionGroup(part, GHOST_CHARACTER_GROUP)
		applyGhostVisual(part)
	else
		setPartCollisionGroup(part, RACE_CHARACTER_GROUP)
		restoreVisual(part)
	end
end

local function applyCharacterMode(player: Player, isGhost: boolean)
	local character = player.Character

	if character == nil then
		return
	end

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") then
			applyPartMode(descendant, isGhost)
		end
	end
end

local function disconnectCharacterConnection(player: Player)
	local connection = characterConnections[player]

	if connection ~= nil then
		connection:Disconnect()
		characterConnections[player] = nil
	end
end

local function bindCharacter(player: Player, character: Model)
	disconnectCharacterConnection(player)

	characterConnections[player] = character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			applyPartMode(descendant, ghostPlayers[player] == true)
		end
	end)

	applyCharacterMode(player, ghostPlayers[player] == true)
end

local function handlePlayerAdded(player: Player)
	playerConnections[player] = player.CharacterAdded:Connect(function(character)
		bindCharacter(player, character)
	end)

	if player.Character ~= nil then
		bindCharacter(player, player.Character)
	end
end

local function handlePlayerRemoving(player: Player)
	GhostService.SetPlayerGhostMode(player, false)
	disconnectCharacterConnection(player)

	local connection = playerConnections[player]

	if connection ~= nil then
		connection:Disconnect()
		playerConnections[player] = nil
	end

	ghostPlayers[player] = nil
end

function GhostService.Init(_context: ServiceContext?)
	if isInitialized then
		return
	end

	ensureCollisionGroups()
	isInitialized = true
end

function GhostService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[GhostService] Start called before Init.")
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
end

function GhostService.SetPlayerGhostMode(player: Player, isGhost: boolean)
	if isGhost then
		ghostPlayers[player] = true
	else
		ghostPlayers[player] = nil
	end

	applyCharacterMode(player, isGhost)
end

return GhostService
