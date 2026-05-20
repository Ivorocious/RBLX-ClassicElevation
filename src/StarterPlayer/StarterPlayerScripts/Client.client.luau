--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

if raceStateChangedRemote ~= nil then
	raceStateChangedRemote.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			warn("[ClientRaceDebug] RaceStateChanged payload was not a table.")
			return
		end

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
		local placementCount = if typeof(placements) == "table" then #placements else 0
		local dnfCount = if typeof(dnfs) == "table" then #dnfs else 0
		local leaderText = "none"

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
	end)
end

print("[ClientRaceDebug] Phase 3B race remote debug listeners connected.")
