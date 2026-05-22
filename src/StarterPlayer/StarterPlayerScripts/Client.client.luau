--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local FormatTime = require(ReplicatedStorage.Shared.FormatTime)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

local function getRemoteEvent(remoteName: string): RemoteEvent?
	local remote = remotesFolder:WaitForChild(remoteName)

	if not remote:IsA("RemoteEvent") then
		warn(string.format("[ClientRaceDebug] %s is not a RemoteEvent.", remoteName))
		return nil
	end

	return remote
end

local raceStateChangedRemote = getRemoteEvent(RaceConstants.RemoteNames.RaceStateChanged)
local raceTimerUpdatedRemote = getRemoteEvent(RaceConstants.RemoteNames.RaceTimerUpdated)
local playerRaceStatusChangedRemote = getRemoteEvent(RaceConstants.RemoteNames.PlayerRaceStatusChanged)
local raceResultsUpdatedRemote = getRemoteEvent(RaceConstants.RemoteNames.RaceResultsUpdated)
local requestSpectateRemote = getRemoteEvent(RaceConstants.RemoteNames.RequestSpectate)
local requestRaceLateRemote = getRemoteEvent(RaceConstants.RemoteNames.RequestRaceLate)
local requestGhostRaceRemote = getRemoteEvent(RaceConstants.RemoteNames.RequestGhostRace)
local requestDevRaceStateRemote = getRemoteEvent(RaceConstants.RemoteNames.RequestDevRaceState)

local localPlayer = Players.LocalPlayer
local currentRaceId = ""
local currentRaceState: string? = nil
local localPlayerStatus: string? = RaceConstants.PlayerRaceStatus.Lobby
local lateChoiceSubmittedRaceId: string? = nil
local finishedChoiceSubmittedRaceId: string? = nil
local lateJoinGui: ScreenGui? = nil
local finishedOptionsGui: ScreenGui? = nil

local function rememberRaceId(raceId: any)
	if typeof(raceId) ~= "string" or raceId == currentRaceId then
		return
	end

	currentRaceId = raceId
	lateChoiceSubmittedRaceId = nil
	finishedChoiceSubmittedRaceId = nil
end

local function updateChoiceUi()
	local isRacingState = currentRaceState == RaceConstants.RaceState.Racing
	local canShowLateJoin = isRacingState
		and localPlayerStatus == RaceConstants.PlayerRaceStatus.Lobby
		and lateChoiceSubmittedRaceId ~= currentRaceId
	local canShowFinishedOptions = isRacingState
		and localPlayerStatus == RaceConstants.PlayerRaceStatus.Finished
		and finishedChoiceSubmittedRaceId ~= currentRaceId

	if lateJoinGui ~= nil then
		lateJoinGui.Enabled = canShowLateJoin
	end

	if finishedOptionsGui ~= nil then
		finishedOptionsGui.Enabled = canShowFinishedOptions
	end
end

local function createButton(parent: Instance, name: string, label: string, order: number, onActivated: () -> ())
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.fromOffset(12, 42 + (order - 1) * 36)
	button.Size = UDim2.new(1, -24, 0, 30)
	button.BackgroundColor3 = Color3.fromRGB(55, 68, 86)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.Gotham
	button.Text = label
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 13
	button.Parent = parent

	button.Activated:Connect(onActivated)
end

local function createChoiceGui(guiName: string, titleText: string): ScreenGui
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local existingGui = playerGui:FindFirstChild(guiName)

	if existingGui ~= nil then
		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = guiName
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.DisplayOrder = 10
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "Panel"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.fromScale(0.5, 0.18)
	frame.Size = UDim2.fromOffset(220, 120)
	frame.BackgroundColor3 = Color3.fromRGB(25, 28, 34)
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 38)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = titleText
	title.TextColor3 = Color3.fromRGB(235, 235, 235)
	title.TextSize = 15
	title.Parent = frame

	return screenGui
end

local function createRaceChoiceUis()
	local lateJoinScreenGui = createChoiceGui("LateJoinUI", "Join Current Race?")
	lateJoinGui = lateJoinScreenGui

	local lateJoinPanel = lateJoinScreenGui:FindFirstChild("Panel")

	if lateJoinPanel ~= nil then
		createButton(lateJoinPanel, "Spectate", "Spectate", 1, function()
			lateChoiceSubmittedRaceId = currentRaceId
			lateJoinScreenGui.Enabled = false

			if requestSpectateRemote ~= nil then
				requestSpectateRemote:FireServer()
			end
		end)

		createButton(lateJoinPanel, "RaceLate", "Race Late", 2, function()
			lateChoiceSubmittedRaceId = currentRaceId
			lateJoinScreenGui.Enabled = false

			if requestRaceLateRemote ~= nil then
				requestRaceLateRemote:FireServer()
			end
		end)
	end

	local finishedOptionsScreenGui = createChoiceGui("FinishedOptionsUI", "Finished")
	finishedOptionsGui = finishedOptionsScreenGui

	local finishedOptionsPanel = finishedOptionsScreenGui:FindFirstChild("Panel")

	if finishedOptionsPanel ~= nil then
		createButton(finishedOptionsPanel, "Spectate", "Spectate", 1, function()
			finishedChoiceSubmittedRaceId = currentRaceId
			finishedOptionsScreenGui.Enabled = false

			if requestSpectateRemote ~= nil then
				requestSpectateRemote:FireServer()
			end
		end)

		createButton(finishedOptionsPanel, "GhostRace", "Ghost Race", 2, function()
			finishedChoiceSubmittedRaceId = currentRaceId
			finishedOptionsScreenGui.Enabled = false

			if requestGhostRaceRemote ~= nil then
				requestGhostRaceRemote:FireServer()
			end
		end)
	end

	updateChoiceUi()
end

if raceStateChangedRemote ~= nil then
	raceStateChangedRemote.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			warn("[ClientRaceDebug] RaceStateChanged payload was not a table.")
			return
		end

		rememberRaceId(payload.raceId)

		if typeof(payload.state) == "string" then
			currentRaceState = payload.state
		end

		updateChoiceUi()

		print(
			string.format(
				"[ClientRaceDebug] Race state: %s -> %s (%s)",
				tostring(payload.previousState),
				tostring(payload.state),
				tostring(payload.raceId)
			)
		)
	end)
end

if raceTimerUpdatedRemote ~= nil then
	raceTimerUpdatedRemote.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			warn("[ClientRaceDebug] RaceTimerUpdated payload was not a table.")
			return
		end

		rememberRaceId(payload.raceId)

		if typeof(payload.state) == "string" then
			currentRaceState = payload.state
		end

		updateChoiceUi()

		local remainingText = "waiting"

		if typeof(payload.remainingTime) == "number" then
			remainingText = FormatTime.fromSeconds(payload.remainingTime)
		end

		print(
			string.format(
				"[ClientRaceDebug] Timer: state=%s remaining=%s",
				tostring(payload.state),
				remainingText
			)
		)
	end)
end

if playerRaceStatusChangedRemote ~= nil then
	playerRaceStatusChangedRemote.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			warn("[ClientRaceDebug] PlayerRaceStatusChanged payload was not a table.")
			return
		end

		if payload.userId == localPlayer.UserId and typeof(payload.status) == "string" then
			localPlayerStatus = payload.status

			if localPlayerStatus == RaceConstants.PlayerRaceStatus.Finished then
				finishedChoiceSubmittedRaceId = nil
			end

			updateChoiceUi()
		end

		print(
			string.format(
				"[ClientRaceDebug] Player status: %s %s -> %s (%s)",
				tostring(payload.displayName),
				tostring(payload.previousStatus),
				tostring(payload.status),
				tostring(payload.reason)
			)
		)
	end)
end

if raceResultsUpdatedRemote ~= nil then
	raceResultsUpdatedRemote.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			warn("[ClientRaceDebug] RaceResultsUpdated payload was not a table.")
			return
		end

		local placements = payload.placements
		local dnfs = payload.dnfs
		local activeRacers = payload.activeRacers
		local placementCount = if typeof(placements) == "table" then #placements else 0
		local dnfCount = if typeof(dnfs) == "table" then #dnfs else 0
		local fallCount = 0
		local leaderText = "none"

		local function addFallsFromResults(results)
			if typeof(results) ~= "table" then
				return
			end

			for _, playerResult in ipairs(results) do
				if typeof(playerResult) == "table" and typeof(playerResult.falls) == "number" then
					fallCount += playerResult.falls
				end
			end
		end

		addFallsFromResults(activeRacers)
		addFallsFromResults(placements)
		addFallsFromResults(dnfs)

		if placementCount > 0 then
			local leader = placements[1]

			if typeof(leader) == "table" then
				local finishTime = leader.finishTime
				local finishTimeText = "unknown"

				if typeof(finishTime) == "number" then
					finishTimeText = FormatTime.fromSeconds(finishTime)
				end

				leaderText = string.format("%s at %s", tostring(leader.displayName), finishTimeText)
			end
		end

		print(
			string.format(
				"[ClientRaceDebug] Results: race=%s placements=%d dnfs=%d leader=%s",
				tostring(payload.raceId),
				placementCount,
				dnfCount,
				leaderText
			)
		)
		print(string.format("[ClientRaceDebug] Result falls: total=%d", fallCount))
	end)
end

local function createDevRaceControls()
	if not RunService:IsStudio() or requestDevRaceStateRemote == nil then
		return
	end

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local existingGui = playerGui:FindFirstChild("DevRaceControls")

	if existingGui ~= nil then
		existingGui:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DevRaceControls"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "Panel"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.fromScale(0.985, 0.12)
	frame.Size = UDim2.fromOffset(150, 132)
	frame.BackgroundColor3 = Color3.fromRGB(25, 28, 34)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Text = "DEV RACE"
	title.TextColor3 = Color3.fromRGB(235, 235, 235)
	title.TextSize = 14
	title.Parent = frame

	local buttons = {
		{ label = "Start Race", action = "StartRaceNow" },
		{ label = "Skip State", action = "SkipState" },
		{ label = "End Race", action = "EndRace" },
	}

	for index, buttonConfig in ipairs(buttons) do
		local button = Instance.new("TextButton")
		button.Name = buttonConfig.action
		button.Position = UDim2.fromOffset(10, 28 + (index - 1) * 32)
		button.Size = UDim2.new(1, -20, 0, 28)
		button.BackgroundColor3 = Color3.fromRGB(55, 68, 86)
		button.BorderSizePixel = 0
		button.Font = Enum.Font.Gotham
		button.Text = buttonConfig.label
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextSize = 13
		button.Parent = frame

		button.Activated:Connect(function()
			requestDevRaceStateRemote:FireServer({
				action = buttonConfig.action,
			})
		end)
	end
end

createRaceChoiceUis()
createDevRaceControls()

print("[ClientRaceDebug] Phase 5 race remote debug listeners connected.")
