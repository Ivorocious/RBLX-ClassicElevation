--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

type ServiceContext = {
	Services: { [string]: any },
}

type PodiumWinner = {
	userId: number,
	displayName: string,
	finishTime: number,
}

type AvatarUpdater = (Model, PodiumWinner?, number, () -> boolean) -> ()

type PodiumController = {
	getLobby: () -> Instance?,
	getCurrentRaceResult: () -> any,
	updateAvatar: AvatarUpdater,
	lastDisplayedRaceId: string?,
	displayGeneration: number,
	hasAppliedInitialState: boolean,
}

export type TestPodiumController = {
	Refresh: () -> (),
	GetLastDisplayedRaceId: () -> string?,
}

local LobbyPodiumService = {}

local isInitialized = false
local isStarted = false
local resultsService: any = nil
local heartbeatAccumulator = 0
local warnedPaths: { [string]: boolean } = {}
local podiumController: PodiumController? = nil

local REFRESH_INTERVAL = 0.5
local SLOT_NAMES = { "First", "Second", "Third" }
local PLACEHOLDER_NAME = "No result yet"
local PLACEHOLDER_TIME = "—"
local NEUTRAL_SKIN_COLOR = Color3.fromRGB(226, 220, 188)
local NEUTRAL_TORSO_COLOR = Color3.fromRGB(45, 93, 154)
local NEUTRAL_LEG_COLOR = Color3.fromRGB(28, 45, 75)

local function warnOnce(path: string)
	if warnedPaths[path] then
		return
	end

	warnedPaths[path] = true
	warn(string.format("[LobbyPodiumService] Missing required podium instance: %s", path))
end

local function getSlot(lobby: Instance?, slotName: string): Model?
	if lobby == nil then
		warnOnce("Workspace.Lobby")
		return nil
	end

	local podium = lobby:FindFirstChild("Podium")

	if podium == nil then
		warnOnce("Workspace.Lobby.Podium")
		return nil
	end

	local slots = podium:FindFirstChild("Slots")

	if slots == nil then
		warnOnce("Workspace.Lobby.Podium.Slots")
		return nil
	end

	local slot = slots:FindFirstChild(slotName)

	if slot == nil or not slot:IsA("Model") then
		warnOnce(string.format("Workspace.Lobby.Podium.Slots.%s", slotName))
		return nil
	end

	return slot
end

local function getSlots(lobby: Instance?): { Model }?
	local slots = {}

	for _, slotName in ipairs(SLOT_NAMES) do
		local slot = getSlot(lobby, slotName)

		if slot == nil then
			return nil
		end

		table.insert(slots, slot)
	end

	return slots
end

local function findTextLabel(slot: Model, labelName: string): TextLabel?
	local label = slot:FindFirstChild(labelName, true)

	if label ~= nil and label:IsA("TextLabel") then
		return label
	end

	warnOnce(string.format("%s.%s", slot:GetFullName(), labelName))
	return nil
end

local function getDisplayMarker(slot: Model): BasePart?
	local marker = slot:FindFirstChild("DisplayMarker", true)

	if marker ~= nil and marker:IsA("BasePart") then
		return marker
	end

	warnOnce(string.format("%s.DisplayMarker", slot:GetFullName()))
	return nil
end

local function findAvatar(slot: Model): Model?
	local namedAvatar = slot:FindFirstChild("Avatar", true)

	if namedAvatar ~= nil and namedAvatar:IsA("Model") and namedAvatar:FindFirstChildOfClass("Humanoid") ~= nil then
		return namedAvatar
	end

	for _, descendant in ipairs(slot:GetDescendants()) do
		if descendant:IsA("Humanoid") and descendant.Parent ~= nil and descendant.Parent:IsA("Model") then
			return descendant.Parent
		end
	end

	return nil
end

local function removeGeneratedAvatar(slot: Model)
	local avatar = findAvatar(slot)

	if avatar ~= nil and avatar:GetAttribute("LobbyPodiumGenerated") == true then
		avatar:Destroy()
	end
end

local function moveAvatarToMarker(avatar: Model, marker: BasePart)
	local scale = marker:GetAttribute("AvatarScale")
	if typeof(scale) == "number" and scale >= 1 and scale <= 4 then
		avatar:ScaleTo(scale)
	end
	local sourcePivot = avatar:GetPivot()
	local sourceBounds, sourceSize = avatar:GetBoundingBox()
	local pivotToBounds = sourcePivot:ToObjectSpace(sourceBounds)
	local targetBounds = marker.CFrame * CFrame.new(0, sourceSize.Y / 2, 0)
	avatar:PivotTo(targetBounds * pivotToBounds:Inverse())
end

local function anchorAvatar(avatar: Model)
	for _, descendant in ipairs(avatar:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end
end

local function createNeutralDescription(): HumanoidDescription
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = NEUTRAL_SKIN_COLOR
	description.LeftArmColor = NEUTRAL_SKIN_COLOR
	description.RightArmColor = NEUTRAL_SKIN_COLOR
	description.TorsoColor = NEUTRAL_TORSO_COLOR
	description.LeftLegColor = NEUTRAL_LEG_COLOR
	description.RightLegColor = NEUTRAL_LEG_COLOR

	return description
end

local function setSlotText(slot: Model, winner: PodiumWinner?)
	local winnerName = findTextLabel(slot, "WinnerName")
	local timeLabel = findTextLabel(slot, "TimeLabel")

	if winnerName ~= nil then
		winnerName.Text = if winner ~= nil then winner.displayName else PLACEHOLDER_NAME
	end

	if timeLabel ~= nil then
		if winner ~= nil then
			local totalMilliseconds = math.floor((winner.finishTime * 1000) + 0.5)
			local minutes = math.floor(totalMilliseconds / 60000)
			local remainingMilliseconds = totalMilliseconds % 60000
			local wholeSeconds = math.floor(remainingMilliseconds / 1000)
			local milliseconds = remainingMilliseconds % 1000
			timeLabel.Text = if minutes > 0
				then string.format("%d:%02d.%03d", minutes, wholeSeconds, milliseconds)
				else string.format("%d.%03d", wholeSeconds, milliseconds)
		else
			timeLabel.Text = PLACEHOLDER_TIME
		end
	end
end

local function applyAvatarAppearance(slot: Model, winner: PodiumWinner?, _generation: number, isCurrent: () -> boolean)
	task.spawn(function()
		local description: HumanoidDescription? = nil

		if winner == nil then
			description = createNeutralDescription()
		else
			local didLoad, loadedDescription = pcall(function()
				return Players:GetHumanoidDescriptionFromUserId(winner.userId)
			end)

			if not didLoad or loadedDescription == nil or not loadedDescription:IsA("HumanoidDescription") then
				warn(string.format("[LobbyPodiumService] Could not load avatar for user %d.", winner.userId))
				return
			end

			description = loadedDescription
		end

		local resolvedDescription = description :: HumanoidDescription

		if not isCurrent() or slot.Parent == nil then
			resolvedDescription:Destroy()
			return
		end

		local marker = getDisplayMarker(slot)

		if marker == nil then
			resolvedDescription:Destroy()
			return
		end

		local didCreate, createdAvatar = pcall(function()
			return Players:CreateHumanoidModelFromDescriptionAsync(resolvedDescription, Enum.HumanoidRigType.R15)
		end)
		resolvedDescription:Destroy()

		if not didCreate or createdAvatar == nil or not createdAvatar:IsA("Model") then
			warn("[LobbyPodiumService] Could not create podium mannequin.")
			return
		end

		if not isCurrent() or slot.Parent == nil then
			createdAvatar:Destroy()
			return
		end

		local humanoid = createdAvatar:FindFirstChildOfClass("Humanoid")

		if humanoid ~= nil then
			humanoid.DisplayName = if winner ~= nil then winner.displayName else PLACEHOLDER_NAME
		end

		anchorAvatar(createdAvatar)
		local didMove, errorMessage = pcall(moveAvatarToMarker, createdAvatar, marker)

		if not didMove then
			warn(string.format("[LobbyPodiumService] Could not place podium mannequin: %s", tostring(errorMessage)))
			createdAvatar:Destroy()
			return
		end

		if not isCurrent() or slot.Parent == nil then
			createdAvatar:Destroy()
			return
		end

		local previousAvatar = findAvatar(slot)
		createdAvatar.Name = "Avatar"
		createdAvatar:SetAttribute("LobbyPodiumGenerated", true)
		createdAvatar.Parent = slot

		if previousAvatar ~= nil and previousAvatar ~= createdAvatar then
			previousAvatar:Destroy()
		end
	end)
end

local function getCompletedWinners(getCurrentRaceResult: () -> any): (string?, { PodiumWinner }?)
	local raceResult = getCurrentRaceResult()

	if typeof(raceResult) ~= "table"
		or typeof(raceResult.raceId) ~= "string"
		or raceResult.raceId == ""
		or typeof(raceResult.duration) ~= "number"
	then
		return nil, nil
	end

	local placements = raceResult.placements

	if typeof(placements) ~= "table" then
		return raceResult.raceId, {}
	end

	local winners = {}

	for _, placement in ipairs(placements) do
		if #winners >= #SLOT_NAMES then
			break
		end

		if typeof(placement) == "table"
			and typeof(placement.userId) == "number"
			and placement.userId >= 0
			and typeof(placement.finishTime) == "number"
			and placement.finishTime >= 0
			and placement.finishTime < math.huge
		then
			local displayName = placement.displayName

			if typeof(displayName) ~= "string" or displayName == "" then
				displayName = "Unknown racer"
			end

			table.insert(winners, {
				userId = placement.userId,
				displayName = string.sub(displayName, 1, 32),
				finishTime = placement.finishTime,
			})
		end
	end

	return raceResult.raceId, winners
end

local function applyPodium(controller: PodiumController, slots: { Model }, winners: { PodiumWinner })
	controller.displayGeneration += 1
	local generation = controller.displayGeneration

	for index, slot in ipairs(slots) do
		local winner = winners[index]
		removeGeneratedAvatar(slot)
		setSlotText(slot, winner)
		controller.updateAvatar(slot, winner, generation, function()
			return controller.displayGeneration == generation
		end)
	end
end

local function refreshPodium(controller: PodiumController)
	local slots = getSlots(controller.getLobby())

	if slots == nil then
		return
	end

	if not controller.hasAppliedInitialState then
		applyPodium(controller, slots, {})
		controller.hasAppliedInitialState = true
	end

	local raceId, winners = getCompletedWinners(controller.getCurrentRaceResult)

	if raceId == nil or winners == nil or raceId == controller.lastDisplayedRaceId then
		return
	end

	applyPodium(controller, slots, winners)
	controller.lastDisplayedRaceId = raceId
	print(string.format("[LobbyPodiumService] Displayed winners from %s.", raceId))
end

local function getProductionRaceResult(): any
	if resultsService == nil or resultsService.GetCurrentRaceResult == nil then
		return nil
	end

	return resultsService.GetCurrentRaceResult()
end

function LobbyPodiumService.Init(context: ServiceContext?)
	if isInitialized then
		return
	end

	if context ~= nil then
		resultsService = context.Services.ResultsService
	end

	if resultsService == nil then
		warn("[LobbyPodiumService] ResultsService dependency is missing.")
	end

	podiumController = {
		getLobby = function()
			return Workspace:FindFirstChild("Lobby")
		end,
		getCurrentRaceResult = getProductionRaceResult,
		updateAvatar = applyAvatarAppearance,
		lastDisplayedRaceId = nil,
		displayGeneration = 0,
		hasAppliedInitialState = false,
	}

	isInitialized = true
end

function LobbyPodiumService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[LobbyPodiumService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true

	if podiumController ~= nil then
		refreshPodium(podiumController)
	end

	game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		heartbeatAccumulator += deltaTime

		if heartbeatAccumulator < REFRESH_INTERVAL then
			return
		end

		heartbeatAccumulator = 0

		if podiumController ~= nil then
			refreshPodium(podiumController)
		end
	end)
end

function LobbyPodiumService.RefreshNow()
	if podiumController ~= nil then
		refreshPodium(podiumController)
	end
end

function LobbyPodiumService.GetLastDisplayedRaceId(): string?
	if podiumController == nil then
		return nil
	end

	return podiumController.lastDisplayedRaceId
end

function LobbyPodiumService.CreateTestController(lobby: Instance, getCurrentRaceResult: () -> any): TestPodiumController
	local controller: PodiumController = {
		getLobby = function()
			return lobby
		end,
		getCurrentRaceResult = getCurrentRaceResult,
		updateAvatar = function(_slot: Model, _winner: PodiumWinner?, _generation: number, _isCurrent: () -> boolean)
		end,
		lastDisplayedRaceId = nil,
		displayGeneration = 0,
		hasAppliedInitialState = false,
	}

	return {
		Refresh = function()
			refreshPodium(controller)
		end,
		GetLastDisplayedRaceId = function()
			return controller.lastDisplayedRaceId
		end,
	}
end

return LobbyPodiumService
