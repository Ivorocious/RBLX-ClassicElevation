--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local Probe = {}
local ATTRIBUTE = "MCPhase2Progress"
local finishBodyNames = {Head = true, UpperTorso = true, LowerTorso = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true,
	RightLowerArm = true, RightHand = true, LeftUpperLeg = true, LeftLowerLeg = true,
	LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true}

local function visibleFinishBody(character, part)
	if not character or not character:IsA("Model") or not part or not part:IsA("BasePart") or part.Parent ~= character
		or not finishBodyNames[part.Name] or part.Transparency >= 1 then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.RigType == Enum.HumanoidRigType.R15 and humanoid.Health > 0
end

local function resultFor(result, userId)
	if not result then return nil end
	for _, list in {result.activeRacers or {}, result.placements or {}, result.dnfs or {}} do
		for _, entry in list do if entry.userId == userId then return entry end end
	end
	return nil
end

local function inStaging(character, start)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not start then return false end
	local point = start.CFrame:PointToObjectSpace(root.Position)
	return math.abs(point.X) <= start.Size.X / 2 + 4 and math.abs(point.Z) <= start.Size.Z / 2 + 4
		and math.abs(point.Y) <= start.Size.Y / 2 + 12
end

function Probe.Start(services, options)
	assert(RunService:IsStudio() and RunService:IsServer(), "Studio server observer only")
	options = options or {}
	for _, name in {"CourseService", "RaceService", "PlayerRaceService", "CheckpointService", "ResultsService"} do
		assert(services[name], "Missing real shared service " .. name)
	end
	local records, states, samples = {}, {}, {}
	local active, elapsed, connection = true, 0, nil
	local boundCourse, boundFinish, finishConnection
	local report = {candidate = Config.CandidateId, source = "Actual shared services; read-only observer",
		startedAt = workspace:GetServerTimeNow(), sessions = records, samples = samples, actualClientsPeak = 0}
	local handle = {}
	local function sessionFor(player, raceId)
		local key = tostring(player.UserId) .. ":" .. raceId
		local state = states[key]
		if not state then
			assert(#records < 256, "Server observer session limit reached")
			state = {userId = player.UserId, raceId = raceId, characterSerial = 0,
				staged = false, events = {}, source = "shared-services"}
			states[key] = state
			table.insert(records, state)
		end
		if state.character ~= player.Character then
			state.character = player.Character
			state.characterSerial += 1
			state.finishContact, state.finishCourse = nil, nil
		end
		return state
	end
	local function bindFinish(course)
		local rightCourse = course ~= nil and services.CourseService.GetActiveCourseId() == Config.CourseId
			and course:GetAttribute("CandidateId") == Config.CandidateId
		local finish = rightCourse and (if services.CourseService.GetFinishPart then
			services.CourseService.GetFinishPart() else course:FindFirstChild("Finish")) or nil
		if finish and (not finish:IsA("BasePart") or not finish:IsDescendantOf(course)) then finish = nil end
		if boundCourse == course and boundFinish == finish then return end
		if finishConnection then finishConnection:Disconnect(); finishConnection = nil end
		boundCourse, boundFinish = course, finish
		if not finish then return end
		finishConnection = finish.Touched:Connect(function(part)
			local ok, reason = pcall(function()
				if not active or services.CourseService.GetActiveCourse() ~= course
					or services.CourseService.GetActiveCourseId() ~= Config.CourseId
					or course:GetAttribute("CandidateId") ~= Config.CandidateId
					or services.RaceService.GetRaceState() ~= "Racing" then return end
				local character = part and part.Parent
				if not visibleFinishBody(character, part) then return end
				local player = Players:GetPlayerFromCharacter(character)
				if not player or player.Parent ~= Players or player.Character ~= character then return end
				local raceId = services.RaceService.GetCurrentRaceId()
				local result = services.ResultsService.GetCurrentRaceResult()
				local status = services.PlayerRaceService.GetPlayerStatus(player)
				local checkpoint = services.CheckpointService.GetLatestCheckpointIndex(player)
				if raceId == "" or not result or result.raceId ~= raceId or not resultFor(result, player.UserId)
					or not services.PlayerRaceService.IsOfficialRacer(player) or checkpoint ~= 4
					or (status ~= "Racing" and status ~= "Finished") then return end
				local state = sessionFor(player, raceId)
				if state.finishContact and state.finishCourse == course then return end
				-- Shared finish may run first; retain the actual touch after its status/anchor change.
				state.finishContact = {source = "actual-server-Finish.Touched", partName = part.Name,
					partPath = part:GetFullName(), coursePath = course:GetFullName(), candidate = Config.CandidateId,
					courseId = Config.CourseId, raceId = raceId, userId = player.UserId,
					at = workspace:GetServerTimeNow(), official = true, checkpoint = checkpoint, status = status}
				state.finishCourse = course
			end)
			if not ok then report.failure = tostring(reason); handle.Stop() end
		end)
	end
	local function sample()
		local now = workspace:GetServerTimeNow()
		local course = services.CourseService.GetActiveCourse()
		bindFinish(course)
		local raceId = services.RaceService.GetCurrentRaceId()
		local raceState = services.RaceService.GetRaceState()
		local raceElapsed = services.RaceService.GetElapsedRaceTime()
		local result = services.ResultsService.GetCurrentRaceResult()
		local clients = Players:GetPlayers()
		report.actualClientsPeak = math.max(report.actualClientsPeak, #clients)
		for _, player in clients do
			local state = sessionFor(player, raceId)
			local status = services.PlayerRaceService.GetPlayerStatus(player)
			local rightCourse = course ~= nil and services.CourseService.GetActiveCourseId() == Config.CourseId
				and course:GetAttribute("CandidateId") == Config.CandidateId
			local official = services.PlayerRaceService.IsOfficialRacer(player)
			local checkpoint = services.CheckpointService.GetLatestCheckpointIndex(player)
			local playerResult = if result and result.raceId == raceId then resultFor(result, player.UserId) else nil
			local atStart = rightCourse and inStaging(player.Character, course:FindFirstChild("Start"))
			if status == "Queued" and raceId ~= "" and official and atStart
				and (raceState == "Intermission" or raceState == "Countdown") then
				state.staged = true
				state.stagedAt = now
				state.stagedCharacterSerial = state.characterSerial
				state.stagingEvidenceSource = "ObservedQueuedAtStart"
			end
			if raceState == "Racing" and not state.firstRacingSampleAt then
				state.firstRacingSampleAt = now
				if not state.staged and status == "Racing" and official and raceId ~= "" and atStart
					and typeof(raceElapsed) == "number" and raceElapsed >= 0 and raceElapsed <= 0.5
					and checkpoint == 0 and playerResult ~= nil and playerResult.falls == 0 then
					state.staged = true
					state.stagedAt = now
					state.stagedCharacterSerial = state.characterSerial
					state.stagingEvidenceSource = "FirstOfficialRacingSampleAtStartWithin0.5Seconds"
					state.entryElapsed = raceElapsed
				end
			end
			local splits = {}
			if playerResult then
				for _, split in playerResult.checkpointSplits or {} do
					table.insert(splits, {checkpoint = split.checkpointIndex, lap = split.lap, elapsed = split.elapsedTime})
				end
			end
			local current = {source = "shared-services", observedAt = now, raceId = raceId, raceState = raceState,
				courseId = services.CourseService.GetActiveCourseId(), coursePath = course and course:GetFullName(), candidate = course and course:GetAttribute("CandidateId"),
				status = status, official = official, raceElapsed = raceElapsed,
				staged = state.staged and state.stagedCharacterSerial == state.characterSerial,
				stagedAt = state.stagedAt, stagingEvidenceSource = state.stagingEvidenceSource, entryElapsed = state.entryElapsed,
				characterSerial = state.characterSerial, checkpoint = checkpoint, falls = playerResult and playerResult.falls,
				finished = playerResult ~= nil and playerResult.status == "Finished" and playerResult.finishTime ~= nil,
				finishTime = playerResult and playerResult.finishTime, splits = splits, actualClients = #clients,
				requiredLaps = playerResult and playerResult.requiredLaps, raceFormat = result and result.raceFormat,
				finishContact = if rightCourse and state.finishCourse == course then state.finishContact else nil}
			local signature = tostring(current.status) .. ":" .. tostring(current.checkpoint) .. ":"
				.. tostring(current.falls) .. ":" .. tostring(current.characterSerial) .. ":" .. raceState
				.. ":" .. tostring(current.finishContact and current.finishContact.at)
			if signature ~= state.signature then
				state.signature = signature
				table.insert(state.events, current)
			end
			state.latest = current
			player:SetAttribute(ATTRIBUTE, HttpService:JSONEncode(current))
		end
		if #samples < (options.maxSamples or 3600) then
			local diagnostic
			if options.diagnostics then diagnostic = options.diagnostics() end
			table.insert(samples, {at = now, raceId = raceId, state = raceState, actualClients = #clients,
				candidate = course and course:GetAttribute("CandidateId"), runtime = diagnostic})
		end
	end
	connection = RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if not active or elapsed < (options.interval or 0.08) then return end
		elapsed = 0
		local ok, reason = pcall(sample)
		if not ok then report.failure = tostring(reason); handle.Stop() end
	end)
	function handle.Stop()
		if not active then return report end
		active = false
		connection:Disconnect()
		if finishConnection then finishConnection:Disconnect(); finishConnection = nil end
		boundCourse, boundFinish = nil, nil
		for _, player in Players:GetPlayers() do player:SetAttribute(ATTRIBUTE, nil) end
		for _, state in records do state.character, state.finishCourse = nil, nil end
		report.stoppedAt = workspace:GetServerTimeNow()
		return report
	end
	function handle.Debug()
		local snapshot = table.clone(report)
		snapshot.sessions = {}
		for _, state in records do
			local entry = table.clone(state)
			entry.character, entry.signature, entry.finishCourse = nil, nil, nil
			table.insert(snapshot.sessions, entry)
		end
		return snapshot
	end
	function handle.AssertCleanFinish(userId, raceId)
		local state = assert(states[tostring(userId) .. ":" .. raceId], "No observed shared race")
		local final = assert(state.latest)
		assert(final.staged and final.official and final.finished and final.status == "Finished", "No staged official finish")
		assert(final.falls == 0 and final.checkpoint == 4 and final.requiredLaps == 1, "Unexpected fall, checkpoint or lap count")
		assert(#final.splits == 4, "Expected exactly four official checkpoint splits")
		for index, split in final.splits do assert(split.checkpoint == index and split.lap == 1, "Wrong official split order") end
		return final
	end
	local ok, reason = pcall(sample)
	if not ok then report.failure = tostring(reason); handle.Stop(); error(reason, 0) end
	return handle
end

return Probe
