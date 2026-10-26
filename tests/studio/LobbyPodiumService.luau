--!strict

-- Run from a temporary server Script during Studio Play. It creates and removes only ServerStorage.LobbyPodiumServiceTestFixture.
local LobbyPodiumServiceTest = {}

type SlotLabels = {
	slot: Model,
	winnerName: TextLabel,
	timeLabel: TextLabel,
}

local function createSlot(parent: Instance, slotName: string): SlotLabels
	local slot = Instance.new("Model")
	slot.Name = slotName
	slot.Parent = parent

	local marker = Instance.new("Part")
	marker.Name = "DisplayMarker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.Transparency = 1
	marker.Parent = slot

	local nameplate = Instance.new("Part")
	nameplate.Name = "Nameplate"
	nameplate.Anchored = true
	nameplate.CanCollide = false
	nameplate.Parent = slot

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Parent = nameplate

	local winnerName = Instance.new("TextLabel")
	winnerName.Name = "WinnerName"
	winnerName.Parent = surfaceGui

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Parent = surfaceGui

	return {
		slot = slot,
		winnerName = winnerName,
		timeLabel = timeLabel,
	}
end

local function assertSlot(labels: SlotLabels, expectedName: string, expectedTime: string)
	assert(labels.winnerName.Text == expectedName, string.format("Expected %s, got %s", expectedName, labels.winnerName.Text))
	assert(labels.timeLabel.Text == expectedTime, string.format("Expected %s, got %s", expectedTime, labels.timeLabel.Text))
end

function LobbyPodiumServiceTest.Run()
	assert(game:GetService("RunService"):IsStudio(), "Studio only")

	local serverStorage = game:GetService("ServerStorage")
	assert(not serverStorage:FindFirstChild("LobbyPodiumServiceTestFixture"), "Fixture already exists")

	local fixture = Instance.new("Folder")
	fixture.Name = "LobbyPodiumServiceTestFixture"
	fixture.Parent = serverStorage

	local ok, failure = xpcall(function()
		local lobby = Instance.new("Model")
		lobby.Name = "Lobby"
		lobby.Parent = fixture

		local podium = Instance.new("Model")
		podium.Name = "Podium"
		podium.Parent = lobby

		local slots = Instance.new("Folder")
		slots.Name = "Slots"
		slots.Parent = podium

		local first = createSlot(slots, "First")
		local second = createSlot(slots, "Second")
		local third = createSlot(slots, "Third")
		local currentResult: any = nil

		local services = game:GetService("ServerScriptService"):WaitForChild("Services")
		local podiumService = require(services:WaitForChild("LobbyPodiumService"))
		local controller = podiumService.CreateTestController(lobby, function()
			return currentResult
		end)

		controller.Refresh()
		assertSlot(first, "No result yet", "—")
		assertSlot(second, "No result yet", "—")
		assertSlot(third, "No result yet", "—")

		local priorAvatar = Instance.new("Model")
		priorAvatar.Name = "Avatar"
		priorAvatar:SetAttribute("LobbyPodiumGenerated", true)
		local humanoid = Instance.new("Humanoid")
		humanoid.Parent = priorAvatar
		priorAvatar.Parent = first.slot

		currentResult = {
			raceId = "race-active",
			duration = nil,
			placements = {
				{ userId = 10, displayName = "Ignored", finishTime = 1 },
			},
		}
		controller.Refresh()
		assertSlot(first, "No result yet", "—")
		assert(controller.GetLastDisplayedRaceId() == nil, "Incomplete result must not be displayed")

		currentResult = {
			raceId = "race-one",
			duration = 60,
			placements = {
				{ userId = 101, displayName = "Ada", finishTime = 65.432 },
				{ userId = 102, displayName = "Bea", finishTime = 9.001 },
				{ userId = 103, displayName = "Cy", finishTime = 59.999 },
				{ userId = 104, displayName = "Dee", finishTime = 70 },
			},
		}
		controller.Refresh()
		assertSlot(first, "Ada", "1:05.432")
		assertSlot(second, "Bea", "9.001")
		assertSlot(third, "Cy", "59.999")
		assert(controller.GetLastDisplayedRaceId() == "race-one", "Completed race must be remembered")
		assert(priorAvatar.Parent == nil, "A stale generated avatar must be removed before the new winner is shown")

		local priorThirdAvatar = Instance.new("Model")
		priorThirdAvatar.Name = "Avatar"
		priorThirdAvatar:SetAttribute("LobbyPodiumGenerated", true)
		local thirdHumanoid = Instance.new("Humanoid")
		thirdHumanoid.Parent = priorThirdAvatar
		priorThirdAvatar.Parent = third.slot

		currentResult = {
			raceId = "race-two",
			duration = nil,
			placements = {},
		}
		controller.Refresh()
		assertSlot(first, "Ada", "1:05.432")
		assertSlot(second, "Bea", "9.001")
		assertSlot(third, "Cy", "59.999")

		currentResult = {
			raceId = "race-two",
			duration = 42.5,
			placements = {
				{ userId = 201, displayName = "Eli", finishTime = 42.5 },
			},
		}
		controller.Refresh()
		assertSlot(first, "Eli", "42.500")
		assertSlot(second, "No result yet", "—")
		assertSlot(third, "No result yet", "—")
		assert(controller.GetLastDisplayedRaceId() == "race-two", "Next completed race must replace the podium")
		assert(priorThirdAvatar.Parent == nil, "A cleared podium slot must remove its stale generated avatar")
	end, debug.traceback)

	fixture:Destroy()

	if not ok then
		error(failure)
	end
end

return LobbyPodiumServiceTest
