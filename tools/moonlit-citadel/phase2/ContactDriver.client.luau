--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MARKER, CANDIDATE = "MoonlitContactDriver1", "MC_P2_C01_R04"
local CHUNK_BYTES, MAX_BYTES = 16000, 900000
assert(RunService:IsStudio() and RunService:IsClient() and game.PlaceId == 0 and game.GameId == 0, "Unpublished native Studio client only")
assert(script:GetAttribute("RunContactDriver") == true, "Explicitly enable this isolated client contact driver")
local player = Players.LocalPlayer
assert(player.UserId == -1 or player.UserId == -2, "Actual native client -1 or -2 required")
local tools = assert(ReplicatedStorage:FindFirstChild("MoonlitPhase2Tools"))
local Cases, Probe, Suite = require(tools.ContactCases), require(tools.ClientProbe), require(tools.ClientSuite)
local function terminal(state) return state == nil or state == "Complete" or state == "Failed" or state == "Observed" end
local function inactive()
	local probe, suite, contact = Probe.Current(), Suite.Current(), Cases.Current()
	assert(terminal(probe and probe.state) and terminal(suite and suite.state) and terminal(contact and contact.state), "Stop prior native client probes before contact driving")
	assert(player:GetAttribute("ArrivalOpen") == false and player:GetAttribute("OnboardingReady") == true
		and player:GetAttribute("ArrivalPhase") == "Ready", "Actual local arrival and authoritative onboarding must be complete")
	return {userId = player.UserId, routeProbeState = probe and probe.state, suiteState = suite and suite.state, contactState = contact and contact.state,
		localArrivalOpen = player:GetAttribute("ArrivalOpen"), onboardingReady = player:GetAttribute("OnboardingReady"), arrivalPhase = player:GetAttribute("ArrivalPhase")}
end
inactive()
local remotes = assert(ReplicatedStorage:FindFirstChild("Remotes"))
local remote, deadline = nil, os.clock() + 60
repeat
	for _, item in remotes:GetChildren() do
		if item:IsA("RemoteEvent") and item:GetAttribute("CreatedBy") == MARKER and item:GetAttribute("DriverActive") == true then
			assert(not remote or remote == item, "Multiple active contact drivers")
			remote = item
		end
	end
	if not remote then task.wait(0.05) end
until remote or os.clock() >= deadline
assert(remote, "Native server contact driver transport absent")
assert(remote:GetAttribute("CandidateId") == CANDIDATE, "Wrong native contact driver candidate")
local owner = assert(remote:GetAttribute("DriverOwner"))
local context = {nonce = assert(remote:GetAttribute("HandshakeNonce")), caseId = "", raceId = ""}
local evidence = Instance.new("Folder")
evidence.Name, evidence.Parent = owner, player:WaitForChild("PlayerScripts")
evidence:SetAttribute("CreatedBy", MARKER); evidence:SetAttribute("DriverOwner", owner)
local status = Instance.new("StringValue")
status.Name, status.Parent = "StatusJSON", evidence
local state = "Handshake"
local started = os.clock()
local observer, connection
local function update(failure)
	status.Value = HttpService:JSONEncode({candidate = CANDIDATE, owner = owner, userId = player.UserId, state = state,
		caseId = context.caseId, raceId = context.raceId, failure = failure, evidencePath = evidence:GetFullName()})
	script:SetAttribute("DriverState", state)
	script:SetAttribute("DriverEvidencePath", evidence:GetFullName())
end
local function persist(name, value)
	assert(not evidence:FindFirstChild(name), "Preserve prior native client report")
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = name, evidence
	folder:SetAttribute("CreatedBy", MARKER); folder:SetAttribute("DriverOwner", owner)
	local encoded = HttpService:JSONEncode(value)
	folder:SetAttribute("JSONBytes", #encoded); folder:SetAttribute("JSONChunks", math.ceil(#encoded / 60000))
	for offset = 1, #encoded, 60000 do
		local part = Instance.new("StringValue")
		part.Name, part.Value, part.Parent = string.format("JSON_%03d", math.ceil(offset / 60000)), encoded:sub(offset, offset + 59999), folder
	end
end
local function send(kind, value, expected)
	expected = expected or context
	local encoded = HttpService:JSONEncode(value)
	assert(#encoded <= MAX_BYTES and (kind ~= "slice" or #encoded < 95000), "Original client evidence exceeds bounded transport; retain locally and fail")
	local total = math.ceil(#encoded / CHUNK_BYTES)
	for index = 1, total do
		assert(context == expected, "Client case changed during evidence transmission")
		remote:FireServer({protocol = MARKER, owner = owner, candidate = CANDIDATE, nonce = expected.nonce,
			caseId = expected.caseId, raceId = expected.raceId, kind = kind, index = index, total = total,
			chunk = encoded:sub((index - 1) * CHUNK_BYTES + 1, index * CHUNK_BYTES)})
		if index < total then task.wait(0.04) end
	end
end
local function guard(expected)
	assert(context == expected and RunService:IsStudio() and game.PlaceId == 0 and game.GameId == 0, "Native client context changed")
	assert(os.clock() - started <= 1800 and script:GetAttribute("StopContactDriver") ~= true, "Native client driver stopped or watchdog expired")
	assert(player:GetAttribute("ArrivalOpen") == false and player:GetAttribute("OnboardingReady") == true
		and player:GetAttribute("ArrivalPhase") == "Ready", "Native local arrival or authoritative readiness changed")
	local probe, suite = Probe.Current(), Suite.Current()
	assert(terminal(probe and probe.state) and terminal(suite and suite.state), "A native route probe restarted during contact evidence")
	assert(#Players:GetPlayers() == 2 and Players:GetPlayerByUserId(-1) and Players:GetPlayerByUserId(-2), "Exactly two actual native clients required")
	local course = assert(workspace:FindFirstChild("RaceCourse"), "Actual native RaceCourse absent")
	assert(course:GetAttribute("CandidateId") == CANDIDATE, "Actual native candidate changed")
	local progress = HttpService:JSONDecode(assert(player:GetAttribute("MCPhase2Progress")))
	assert(progress.source == "shared-services" and progress.raceId == expected.raceId and progress.candidate == CANDIDATE
		and progress.coursePath == course:GetFullName() and workspace:GetServerTimeNow() - progress.observedAt <= 1.5, "Actual shared observer stale or belongs to another race")
	return course
end
local function readiness(expected)
	local deadline = os.clock() + 25
	repeat
		guard(expected)
		local current = Cases.Current()
		assert(current and current.caseId == expected.caseId and current.failure == nil, current and current.failure or "Actual native observer absent")
		if #current.samples >= 3 then
			local ready = Cases.Readiness()
			local valid = true
			for _, sample in ready.samples do
				if workspace:GetServerTimeNow() - sample.at > 1.5 or sample.at > workspace:GetServerTimeNow() + 0.2
					or sample.support ~= current.deck or sample.floor == "Air" or (sample.normalY or 0) < 0.95
					or not sample.footGap or math.abs(sample.footGap) > 0.6 or sample.status ~= "Racing" or not sample.official
					or not sample.alive or sample.anchored or sample.cp ~= 0 or sample.falls ~= 0 then valid = false end
			end
			if valid then send("readiness", ready, expected); return end
		end
		task.wait(0.05)
	until os.clock() >= deadline
	error("Both actual native readiness samples were not established within the original arm window")
end
connection = remote.OnClientEvent:Connect(function(packet)
	if type(packet) ~= "table" or packet.protocol ~= MARKER or packet.owner ~= owner or packet.candidate ~= CANDIDATE then return end
	if packet.command == "Observe" then
		if type(packet.nonce) ~= "string" or type(packet.caseId) ~= "string" or packet.caseId == "" or type(packet.raceId) ~= "string" or packet.raceId == "" then return end
		context = {nonce = packet.nonce, caseId = packet.caseId, raceId = packet.raceId}
	elseif packet.nonce ~= context.nonce or packet.caseId ~= context.caseId or packet.raceId ~= context.raceId then return end
	local expected = context
	task.spawn(function()
		local ok, failure = xpcall(function()
			if packet.command == "Observe" then
				inactive()
				local course = guard(expected)
				observer = Cases.ObserveClient(course, {caseId = expected.caseId, stage = packet.data.stage, bay = packet.data.bay, durationSeconds = 90})
				state = "Observing"
				send("observing", {userId = player.UserId, candidate = CANDIDATE, caseId = expected.caseId, raceId = expected.raceId}, expected)
			elseif packet.command == "Readiness" then
				readiness(expected)
			elseif packet.command == "Slice" then
				local startAt, endAt = packet.data.startAt, packet.data.endAt
				assert(type(startAt) == "number" and type(endAt) == "number" and endAt >= startAt, "Use the exact server measurement window")
				while workspace:GetServerTimeNow() < endAt + 0.35 do guard(expected); task.wait(0.025) end
				guard(expected)
				local slice = Cases.EvidenceSlice(startAt, endAt)
				persist(expected.caseId .. "_ExactSlice", slice)
				send("slice", slice, expected)
			elseif packet.command == "Raw" then
				local current = Cases.Current()
				assert(current and current.caseId == expected.caseId, "No original client observer for this exact case")
				if observer and current.state == "Observing" then observer.Stop() end
				observer = nil
				current = Cases.Current()
				if not evidence:FindFirstChild(expected.caseId .. "_Raw") then persist(expected.caseId .. "_Raw", current) end
				state = "Retained"
				send("raw", current, expected)
			elseif packet.command == "Done" then
				state = if packet.data.passed then "Complete" else "Failed"
				update(packet.data.failure)
				if connection then connection:Disconnect(); connection = nil end
				return
			else error("Unknown contact driver command") end
			update()
		end, debug.traceback)
		if not ok then
			state = "Failed"
			update(tostring(failure))
			local raw = Cases.Current()
			pcall(persist, expected.caseId .. "_DriverFailure", {userId = player.UserId, failure = tostring(failure), originalObserver = raw})
			pcall(send, "error", {userId = player.UserId, failure = tostring(failure)}, expected)
		end
	end)
end)
update()
send("hello", inactive())
