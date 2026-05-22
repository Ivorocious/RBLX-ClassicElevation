--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local FormatTime = require(ReplicatedStorage.Shared.FormatTime)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local RaceUiController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("RaceUiController"))

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

if raceStateChangedRemote ~= nil then
	raceStateChangedRemote.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			warn("[ClientRaceDebug] RaceStateChanged payload was not a table.")
			return
		end

		RaceUiController.HandleRaceStateChanged(payload)

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

		RaceUiController.HandleRaceTimerUpdated(payload)

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

		RaceUiController.HandlePlayerRaceStatusChanged(payload)

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

		RaceUiController.HandleRaceResultsUpdated(payload)

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
	frame.Position = UDim2.new(1, -32, 0, 210)
	frame.Size = UDim2.fromOffset(180, 142)
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
		button.Position = UDim2.fromOffset(12, 32 + (index - 1) * 34)
		button.Size = UDim2.new(1, -24, 0, 30)
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

RaceUiController.Init({
	localPlayer = localPlayer,
	requestSpectateRemote = requestSpectateRemote,
	requestRaceLateRemote = requestRaceLateRemote,
	requestGhostRaceRemote = requestGhostRaceRemote,
})
createDevRaceControls()

print("[ClientRaceDebug] Phase 6 race UI and remote debug listeners connected.")
