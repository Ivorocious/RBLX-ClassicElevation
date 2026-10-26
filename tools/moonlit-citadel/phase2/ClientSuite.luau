--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local Probe = require(script.Parent.ClientProbe)
local Suite = {}
local latest, active = nil, nil

local function decode(value)
	if type(value) ~= "table" then return value end
	if value._t == "v" then return Vector3.new(table.unpack(value.value)) end
	local result = {}
	for key, child in value do result[key] = decode(child) end
	return result
end

function Suite.Start(schedule, options)
	assert(RunService:IsStudio() and RunService:IsClient() and game.PlaceId == 0 and game.GameId == 0, "Owned native Studio client only")
	assert(not active and type(schedule) == "table" and #schedule > 0, "Supply a fresh bounded schedule")
	options = options or {}
	local startDelay = options.startDelaySeconds or 0
	assert(type(startDelay) == "number" and startDelay >= 0 and startDelay <= 15, "Use a bounded native trial start delay")
	local player = Players.LocalPlayer
	local report = {candidate = Config.CandidateId, userId = player.UserId, state = "Waiting", trials = {},
		startedAt = workspace:GetServerTimeNow(), startDelaySeconds = startDelay,
		evidenceKind = "Ordinary native routes in successive actual shared inspection races"}
	latest = report
	local running, index, lastRace, started, connection = nil, 1, nil, os.clock(), nil
	local waitingRace, releaseAt = nil, nil
	local handle = {}
	active = handle
	local function stop(reason)
		if connection then connection:Disconnect(); connection = nil end
		if running then Probe.Stop(reason or "Suite stopped") end
		if active == handle then active = nil end
		report.failure, report.endedAt = reason, workspace:GetServerTimeNow()
		report.state = if reason then "Failed" else "Complete"
	end
	connection = RunService.Heartbeat:Connect(function()
		local ok, reason = xpcall(function()
			assert(os.clock() - started <= (options.watchdogSeconds or 1200), "Suite watchdog expired")
			if running then
				local result = Probe.Current()
				if result.state == "Failed" then
					table.insert(report.trials, {name = running.name, catch = running.catch, report = result})
					running = nil
					error("Directed trial failed: " .. tostring(result.failure))
				end
				if result.state ~= "Complete" then return end
				table.insert(report.trials, {name = running.name, catch = running.catch, report = result})
				lastRace, running, index = result.raceId, nil, index + 1
				if index > #schedule then stop(); return end
			end
			report.state, report.waitingForTrial = "Waiting", index
			local encoded = player:GetAttribute("MCPhase2Progress")
			if type(encoded) ~= "string" then return end
			local state = HttpService:JSONDecode(encoded)
			if state.raceId == lastRace or state.raceState ~= "Racing" or state.status ~= "Racing" then return end
			assert(state.source == "shared-services" and workspace:GetServerTimeNow() - state.observedAt <= 1.5, "Shared observer stale")
			assert(state.candidate == Config.CandidateId and state.courseId == Config.CourseId, "Unexpected shared course")
			assert(state.official and state.staged and state.checkpoint == 0 and state.falls == 0, "Next trial did not enter a clean actual shared race")
			assert(player:GetAttribute("ArrivalOpen") == false, "Complete the actual lobby arrival before the race")
			if waitingRace ~= state.raceId then
				waitingRace, releaseAt = state.raceId, workspace:GetServerTimeNow() + startDelay
			end
			if workspace:GetServerTimeNow() < releaseAt then return end
			local course = assert(workspace:FindFirstChild("RaceCourse"), "Active shared course missing")
			assert(state.coursePath == course:GetFullName(), "Shared course identity changed")
			local trial = schedule[index]
			assert(type(trial.name) == "string" and trial.name:match("^[NE][NE][NE]$"), "Unknown route choice")
			local packet = decode(HttpService:JSONDecode(assert(script.Parent:FindFirstChild("Routes_" .. trial.name)).Value))
			assert(packet.candidate == Config.CandidateId, "Route packet candidate changed")
			local settings = {choices = packet.choices, bays = packet.bays, crownLaneOffset = options.crownLaneOffset or 0,
				liftLaneOffset = options.liftLaneOffset or 0}
			if trial.catch == "Arch" then settings.catchRoutes = {CP01Terrace = packet.catchArch}
			elseif trial.catch == "Upper" then settings.catchRoutes = {CP04Terrace = packet.catchUpper}
			else assert(trial.catch == nil, "Unknown catch return") end
			Probe.Start(course, packet.nodes, settings)
			running, report.state, report.currentTrial = trial, "Running", trial.name
		end, debug.traceback)
		if not ok then stop(tostring(reason)) end
	end)
	function handle.Stop(reason) stop(reason or "Stopped by lead") end
	return handle
end

function Suite.Current() return latest end
function Suite.Stop(reason) if active then active.Stop(reason) end; return latest end
return Suite
