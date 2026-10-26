--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FormatTime = require(ReplicatedStorage.Shared.FormatTime)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local RaceUiController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("RaceUiController"))
local StudioDevController = require(script.Parent.Controllers.StudioDevController)

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

RaceUiController.Init({
	localPlayer = localPlayer,
	requestSpectateRemote = requestSpectateRemote,
	requestRaceLateRemote = requestRaceLateRemote,
	requestGhostRaceRemote = requestGhostRaceRemote,
})
StudioDevController.Init()

print("[ClientRaceDebug] Phase 6 race UI and remote debug listeners connected.")
