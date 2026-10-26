--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MARKER, CANDIDATE = "MoonlitContactDriver1", "MC_P2_C01_R04"
local CHUNK_BYTES, MAX_BYTES = 16000, 900000
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 0 and game.GameId == 0, "Unpublished native Studio server only")
assert(script:GetAttribute("RunContactDriver") == true, "Explicitly enable this isolated contact driver")
local Config = require(ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
assert(Config.CandidateId == CANDIDATE, "Contact driver belongs to R04")
local Cases = require(ServerStorage.MoonlitPhase2Tools.ContactCases)
local Control = require(ServerStorage.MoonlitPhase2Tools.TrialControl)
local services = Control.Services()
local remotes = assert(ReplicatedStorage:FindFirstChild("Remotes"), "Existing Remotes folder required")
for _, item in remotes:GetChildren() do
	assert(item:GetAttribute("CreatedBy") ~= MARKER or item:GetAttribute("DriverActive") ~= true, "Another contact driver is active")
end
local owner = "MC_P2_C01_R04_ContactDriver_" .. HttpService:GenerateGUID(false):gsub("%-", "")
local nonce = HttpService:GenerateGUID(false)
local player1 = assert(Players:GetPlayerByUserId(-1), "Actual native client -1 absent")
local player2 = assert(Players:GetPlayerByUserId(-2), "Actual native client -2 absent")
local players = {player1, player2}
local function course(allowReload)
	assert(RunService:IsStudio() and game.PlaceId == 0 and game.GameId == 0, "Fixture identity changed")
	assert(#Players:GetPlayers() == 2 and Players:GetPlayerByUserId(-1) == players[1] and Players:GetPlayerByUserId(-2) == players[2], "Require exactly the original two native Players")
	local root = workspace:FindFirstChild("RaceCourse")
	if allowReload and (not root or not services.CourseService.GetActiveCourse()) then return nil end
	assert(root, "Actual RaceCourse absent")
	assert(root:GetAttribute("CandidateId") == CANDIDATE and root:GetAttribute("CourseId") == Config.CourseId
		and services.CourseService.GetActiveCourse() == root, "Wrong active native R04 course")
	return root
end
local function resolve(root, path)
	for name in path:gmatch("[^/]+") do root = assert(root:FindFirstChild(name), "Missing native contact " .. path) end
	return root
end
course()
local previous = Cases.Current()
assert(not previous or previous.state == "Complete" or previous.state == "Failed", "Prior contact case remains active")
local evidenceRoot = ServerStorage:FindFirstChild("MoonlitPhase2Evidence")
if not evidenceRoot then evidenceRoot = Instance.new("Folder"); evidenceRoot.Name = "MoonlitPhase2Evidence"; evidenceRoot.Parent = ServerStorage end
local evidence = Instance.new("Folder")
evidence.Name, evidence.Parent = owner, evidenceRoot
evidence:SetAttribute("CreatedBy", MARKER)
evidence:SetAttribute("DriverOwner", owner)
local status = Instance.new("StringValue")
status.Name, status.Parent = "StatusJSON", evidence
local remote = Instance.new("RemoteEvent")
remote.Name = owner
remote:SetAttribute("CreatedBy", MARKER)
remote:SetAttribute("DriverOwner", owner)
remote:SetAttribute("HandshakeNonce", nonce)
remote:SetAttribute("CandidateId", CANDIDATE)
remote:SetAttribute("DriverActive", true)
local report = {candidate = CANDIDATE, driverOwner = owner, evidenceKind = "Controlled native placement; not continuous traversal or 20-client evidence",
	actualClientUserIds = {-1, -2}, startedAt = workspace:GetServerTimeNow(), state = "Handshake", cases = {}, rejectedPackets = 0}
local context = {caseId = "", raceId = "", nonce = nonce, allowed = {hello = true, error = true}, packets = {}, incoming = {}}
local started = os.clock()
local function persist(parent, name, value)
	assert(parent:IsDescendantOf(evidence) or parent == evidence, "Evidence storage must remain driver-owned")
	assert(not parent:FindFirstChild(name), "Keep previous driver evidence")
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = name, parent
	folder:SetAttribute("CreatedBy", MARKER)
	folder:SetAttribute("DriverOwner", owner)
	local encoded = HttpService:JSONEncode(value)
	folder:SetAttribute("JSONBytes", #encoded)
	folder:SetAttribute("JSONChunks", math.ceil(#encoded / 60000))
	for offset = 1, #encoded, 60000 do
		local part = Instance.new("StringValue")
		part.Name, part.Value, part.Parent = string.format("JSON_%03d", math.ceil(offset / 60000)), encoded:sub(offset, offset + 59999), folder
	end
	return folder:GetFullName()
end
local function update()
	local actual = Cases.Current()
	status.Value = HttpService:JSONEncode({candidate = CANDIDATE, owner = owner, state = report.state, caseIndex = report.caseIndex,
		caseName = report.caseName, caseId = context.caseId, completed = #report.cases, failure = report.failure,
		contactState = actual and actual.caseId == context.caseId and actual.state or nil,
		waiting = actual and actual.caseId == context.caseId and actual.waiting or nil,
		evidencePath = evidence:GetFullName(), rejectedPackets = report.rejectedPackets, elapsedSeconds = os.clock() - started})
	script:SetAttribute("DriverState", report.state)
	script:SetAttribute("DriverEvidencePath", evidence:GetFullName())
end
local function guard(allowReload)
	course(allowReload)
	assert(script:GetAttribute("StopContactDriver") ~= true, "Stopped by lead")
	assert(os.clock() - started <= 1800, "Contact driver suite watchdog expired")
	assert(not context.failure, context.failure or "Client transport failed")
end
local function waitFor(label, predicate, seconds, allowFailure, allowReload)
	local deadline = os.clock() + seconds
	repeat
		if not allowFailure then guard(allowReload) end
		if predicate() then return end
		update(); task.wait(0.05)
	until os.clock() >= deadline
	error("Contact driver timed out: " .. label)
end
local function request(command, data, missingKind)
	for _, player in players do
		if missingKind and context.packets[player.UserId] and context.packets[player.UserId][missingKind] then continue end
		remote:FireClient(player, {protocol = MARKER, owner = owner, candidate = CANDIDATE, nonce = context.nonce,
			caseId = context.caseId, raceId = context.raceId, command = command, data = data})
	end
end
local function paired(kind)
	local first, second = context.packets[-1], context.packets[-2]
	return first and second and first[kind] and second[kind]
end
local function entries(kind, ids)
	return {context.packets[ids[1]][kind], context.packets[ids[2]][kind]}
end
local function terminal(state) return state == nil or state == "Complete" or state == "Failed" or state == "Observed" end
local connection = remote.OnServerEvent:Connect(function(player, packet)
	local valid = type(packet) == "table" and (player == players[1] or player == players[2]) and Players:GetPlayerByUserId(player.UserId) == player
		and packet.protocol == MARKER and packet.owner == owner and packet.candidate == CANDIDATE and packet.nonce == context.nonce
		and packet.caseId == context.caseId and packet.raceId == context.raceId and context.allowed[packet.kind] == true
		and type(packet.chunk) == "string" and #packet.chunk <= CHUNK_BYTES and type(packet.index) == "number" and packet.index % 1 == 0
		and type(packet.total) == "number" and packet.total % 1 == 0 and packet.total >= 1 and packet.total <= 60
	if not valid then report.rejectedPackets += 1; return end
	local ok, failure = xpcall(function()
		local userId = player.UserId
		context.packets[userId] = context.packets[userId] or {}
		assert(not context.packets[userId][packet.kind], "Duplicate completed client packet")
		context.incoming[userId] = context.incoming[userId] or {}
		local incoming = context.incoming[userId][packet.kind]
		if not incoming then incoming = {chunks = {}, total = packet.total, bytes = 0}; context.incoming[userId][packet.kind] = incoming end
		assert(packet.total == incoming.total and packet.index == #incoming.chunks + 1, "Out-of-order contact evidence chunks")
		incoming.bytes += #packet.chunk
		assert(incoming.bytes <= MAX_BYTES and (packet.kind ~= "slice" or incoming.bytes < 95000), "Client evidence exceeded the bounded exact transport")
		table.insert(incoming.chunks, packet.chunk)
		if packet.index ~= incoming.total then return end
		local decoded = HttpService:JSONDecode(table.concat(incoming.chunks))
		assert(type(decoded) == "table" and decoded.userId == userId, "Client packet caller identity mismatch")
		if packet.kind == "hello" then
			assert(terminal(decoded.routeProbeState) and terminal(decoded.suiteState) and terminal(decoded.contactState), "Prior native client probe remains active")
			assert(decoded.localArrivalOpen == false and decoded.onboardingReady == true and decoded.arrivalPhase == "Ready"
				and player:GetAttribute("OnboardingReady") == true and player:GetAttribute("ArrivalPhase") == "Ready", "Actual native onboarding is not complete")
		elseif packet.kind == "error" then
			context.failure = "Native client " .. userId .. ": " .. tostring(decoded.failure)
		else
			assert(decoded.caseId == context.caseId and decoded.raceId == context.raceId and decoded.candidate == CANDIDATE, "Client payload belongs to a different native case")
			if packet.kind ~= "observing" then assert(decoded.source == "native-client-contact-observer", "Require the actual ContactCases observer report") end
		end
		context.packets[userId][packet.kind] = decoded
		context.incoming[userId][packet.kind] = nil
	end, debug.traceback)
	if not ok then context.failure = tostring(failure) end
end)
remote.Parent = remotes
update()
local function defaultPlan()
	local plan = {}
	for _, stage in {"Lower", "Upper"} do
		for bay = 1, 2 do table.insert(plan, {name = "Adjacent_" .. stage .. bay, case = "adjacent", stage = stage, bay = bay, durationSeconds = 16, userIds = {-1, -2}}) end
	end
	for _, caseName in {"overhead", "side"} do
		for _, stage in {"Lower", "Upper"} do
			for bay = 1, 2 do
				for _, ids in {{-1, -2}, {-2, -1}} do
					table.insert(plan, {name = caseName .. "_" .. stage .. bay .. "_Actor" .. math.abs(ids[1]), case = caseName,
						stage = stage, bay = bay, durationSeconds = 6, userIds = ids})
				end
			end
		end
	end
	local targets = {}
	for _, part in course():GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("Role") == "VisibleResetContact" and part:GetAttribute("MoonlitHazard") == true
			and part.Material == Enum.Material.Neon and part.Transparency < 1 then
			local names, cursor = {}, part
			while cursor ~= course() do table.insert(names, 1, cursor.Name); cursor = cursor.Parent end
			table.insert(targets, table.concat(names, "/"))
		end
	end
	table.sort(targets)
	table.insert(plan, {name = "RedBody", case = "red-body", targetPath = assert(targets[1], "No real authored visible red hazard"), userIds = {-1, -2}})
	for band = 1, 3 do table.insert(plan, {name = "CageBody" .. band, case = "cage-body", targetPath = "Obstacles/SwingLanterns/SwingBand" .. band, userIds = {-1, -2}}) end
	for _, caseName in {"light-miss", "accessory-miss"} do
		table.insert(plan, {name = caseName, case = caseName, targetPath = "Obstacles/SwingLanterns/SwingBand1",
			standPath = "Obstacles/Gallery/NormalWaitBefore1/Contact", standOffset = Vector3.zero, userIds = {-1, -2}})
	end
	local negativeJson = script:GetAttribute("NegativePlanJSON")
	if negativeJson then
		assert(type(negativeJson) == "string" and #negativeJson <= 6000, "Bound the explicit measured negative plan")
		local negative = HttpService:JSONDecode(negativeJson)
		assert(type(negative) == "table" and #negative >= 1 and #negative <= 2, "Provide one or two explicit negative cases")
		for _, entry in negative do
			assert((entry.case == "light-miss" or entry.case == "accessory-miss") and entry.measuredSafeStand == true,
				"Only explicit measured negative placements are allowed")
			local stand = resolve(course(), assert(entry.standPath))
			assert(stand:IsA("BasePart") and stand.CanCollide and stand:GetAttribute("MCWalkable") == true, "Use an actual measured walkable contact")
			assert(resolve(course(), assert(entry.targetPath)):FindFirstChild("CageAndCore", true), "Use an actual native SwingBand")
			local offset = entry.standOffset or {0, 0, 0}
			assert(#offset == 3 and offset[2] == 0 and type(offset[1]) == "number" and type(offset[3]) == "number"
				and math.abs(offset[1]) <= stand.Size.X / 2 and math.abs(offset[3]) <= stand.Size.Z / 2, "Measured local horizontal offset must stay within the actual contact")
			for _, original in plan do
				if original.case == entry.case then
					original.targetPath, original.standPath, original.standOffset = entry.targetPath, entry.standPath, Vector3.new(offset[1], 0, offset[3])
					original.explicitMeasuredNegativePlan = entry
				end
			end
		end
	end
	local subset = script:GetAttribute("CaseNamesJSON")
	if subset then
		assert(type(subset) == "string" and #subset <= 4000, "Bound the fixed-case subset")
		local names, selected, seen = HttpService:JSONDecode(subset), {}, {}
		assert(type(names) == "table" and #names > 0 and #names <= #plan, "Use a bounded nonempty subset of fixed case names")
		for _, name in names do
			assert(not seen[name], "Duplicate selected contact case")
			seen[name] = true
			local found
			for _, entry in plan do if entry.name == name then found = entry; break end end
			local selectedCase = assert(found, "Unknown fixed contact case " .. tostring(name))
			table.insert(selected, selectedCase)
		end
		plan = selected
	end
	return plan
end
local function freshRace(previousRace)
	local restarted = Control.Restart()
	assert(restarted.courseId == Config.CourseId, "Actual shared restart selected another course")
	waitFor("fresh actual shared Racing CP0/f0", function()
		local root = course(true)
		if not root then return false end
		local raceId = services.RaceService.GetCurrentRaceId()
		if raceId == "" or raceId == previousRace or not services.RaceService.IsRaceActive() then return false end
		for _, player in players do
			local encoded = player:GetAttribute("MCPhase2Progress")
			if type(encoded) ~= "string" then return false end
			local progress = HttpService:JSONDecode(encoded)
			if progress.raceId ~= raceId or progress.raceState ~= "Racing" or progress.status ~= "Racing" then return false end
			assert(progress.source == "shared-services" and workspace:GetServerTimeNow() - progress.observedAt <= 1.5, "Actual shared observer bridge is stale")
			assert(progress.candidate == CANDIDATE and progress.coursePath == root:GetFullName() and progress.courseId == Config.CourseId
				and progress.official and progress.staged and progress.checkpoint == 0 and progress.falls == 0 and not progress.finished, "Actual shared restart is not clean CP0/f0")
			assert(services.PlayerRaceService.IsOfficialRacer(player) and services.PlayerRaceService.GetPlayerStatus(player) == "Racing"
				and services.CheckpointService.GetLatestCheckpointIndex(player) == 0, "Actual server racer state differs from the observer")
			assert(player:GetAttribute("OnboardingReady") == true and player:GetAttribute("ArrivalPhase") == "Ready",
				"Actual authoritative onboarding/arrival must already be completed")
		end
		return true
	end, 35, false, true)
	return services.RaceService.GetCurrentRaceId()
end
local function retainRaw(caseFolder)
	context.allowed.raw = true
	if not paired("raw") then request("Raw", nil, "raw") end
	waitFor("both complete original client observer reports", function() return paired("raw") end, 20, true)
	for _, player in players do
		local raw = context.packets[player.UserId].raw
		local name = "Client" .. math.abs(player.UserId) .. "Raw"
		if not caseFolder:FindFirstChild(name) then persist(caseFolder, name, raw) end
	end
end
local ok, failure = xpcall(function()
	waitFor("both inactive native client drivers", function() return paired("hello") end, 30)
	persist(evidence, "InitialClientHandshake", entries("hello", {-1, -2}))
	local plan = defaultPlan()
	report.plannedCaseNames = {}
	for _, entry in plan do table.insert(report.plannedCaseNames, entry.name) end
	local lastRace = services.RaceService.GetCurrentRaceId()
	for index, entry in plan do
		guard()
		context.handle, context.folder = nil, nil
		report.caseIndex, report.caseName, report.state = index, entry.name, "Restarting"
		update()
		local raceId = freshRace(lastRace)
		lastRace = raceId
		local options = {case = entry.case, stage = entry.stage, bay = entry.bay, durationSeconds = entry.durationSeconds,
			userIds = entry.userIds, targetPath = entry.targetPath, standPath = entry.standPath, standOffset = entry.standOffset}
		local handle = Cases.Start(services, options)
		local actual = handle.Debug()
		context = {caseId = actual.caseId, raceId = raceId, nonce = HttpService:GenerateGUID(false),
			allowed = {observing = true, error = true}, incoming = {}, packets = {}}
		local caseFolder = Instance.new("Folder")
		caseFolder.Name, caseFolder.Parent = string.format("Case_%02d_%s", index, entry.name), evidence
		caseFolder:SetAttribute("CreatedBy", MARKER); caseFolder:SetAttribute("DriverOwner", owner)
		context.folder, context.handle = caseFolder, handle
		request("Observe", {stage = entry.stage or "Lower", bay = entry.bay or 1})
		waitFor("both actual native observers", function() return paired("observing") end, 5)
		local liftCase = entry.case == "adjacent" or entry.case == "overhead" or entry.case == "side"
		local began, submitted, caseStarted = false, false, os.clock()
		report.state = "CaseRunning"
		repeat
			guard(); actual = Cases.Current()
			assert(actual and actual.caseId == context.caseId, "Actual controlled case changed")
			assert(not actual.failure and actual.state ~= "Failed", actual.failure or "Controlled case failed")
			assert(os.clock() - caseStarted <= 115, "Contact driver case watchdog expired")
			if liftCase and actual.state == "Armed" and not began then
				if not context.allowed.readiness then context.allowed.readiness = true; request("Readiness") end
				if paired("readiness") then Cases.Begin(entries("readiness", entry.userIds)); began = true end
			end
			if liftCase and actual.state == "AwaitingClientEvidence" and not submitted then
				if not context.allowed.slice then
					context.allowed.slice = true
					request("Slice", {startAt = actual.measurementStartedAt, endAt = actual.measurementEndedAt})
				end
				if paired("slice") then Cases.SubmitClientEvidence(entries("slice", entry.userIds)); submitted = true end
			end
			update(); task.wait(0.05)
		until actual.state == "Complete"
		assert(actual.passed == true and not actual.storageFailure, actual.storageFailure or "Actual controlled case did not pass")
		persist(caseFolder, "ServerRaw", actual)
		if not paired("slice") then
			context.allowed.slice = true
			request("Slice", {startAt = actual.measurementStartedAt, endAt = actual.measurementEndedAt})
			waitFor("both exact measured native client slices", function() return paired("slice") end, 15)
		end
		for _, player in players do persist(caseFolder, "Client" .. math.abs(player.UserId) .. "ExactSlice", context.packets[player.UserId].slice) end
		retainRaw(caseFolder)
		for _, player in players do
			local raw = context.packets[player.UserId].raw
			assert(raw.failure == nil and raw.state == "Observed", "Complete original native client observer failed: " .. tostring(raw.failure))
		end
		table.insert(report.cases, {name = entry.name, caseId = actual.caseId, raceId = raceId, passed = actual.passed,
			evidencePath = caseFolder:GetFullName(), nativeEvidencePath = actual.evidencePath,
			measurementStartedAt = actual.measurementStartedAt, measurementEndedAt = actual.measurementEndedAt})
	end
	report.state, report.passed = "Complete", true
end, debug.traceback)
if not ok then
	report.state, report.failure, report.passed = "Failed", tostring(failure), false
	if context.handle then
		local actual = Cases.Current()
		report.failedCaseId = context.caseId
		local detectionSaved, detectionFailure = pcall(persist, context.folder, "ServerFailureAtDetection", actual)
		if not detectionSaved then report.failureDetectionStorageFailure = tostring(detectionFailure) end
		if actual and actual.caseId == context.caseId and actual.state ~= "Complete" and actual.state ~= "Failed" then context.handle.Stop("Contact driver failure") end
		task.wait(0.2)
		local captured, captureFailure = pcall(function()
			persist(context.folder, "ServerFailureRaw", Cases.Current())
			local transport = {}
			for _, player in players do table.insert(transport, {userId = player.UserId,
				completedPackets = context.packets[player.UserId], partialPackets = context.incoming[player.UserId]}) end
			persist(context.folder, "TransportAtFailure", {caseId = context.caseId, raceId = context.raceId,
				failure = context.failure, clients = transport})
			retainRaw(context.folder)
		end)
		if not captured then report.failureCaptureFailure = tostring(captureFailure) end
	end
end
report.endedAt = workspace:GetServerTimeNow()
report.elapsedSeconds = os.clock() - started
connection:Disconnect()
assert(remote:GetAttribute("CreatedBy") == MARKER and remote:GetAttribute("DriverOwner") == owner, "Driver transport ownership changed")
remote:SetAttribute("DriverActive", false)
local notified, notifyFailure = pcall(request, "Done", {passed = report.passed, failure = report.failure})
if not notified then
	report.finalTransportFailure = tostring(notifyFailure)
	report.state, report.passed = "Failed", false
end
local saved, saveFailure = pcall(persist, evidence, "SuiteRaw", report)
if not saved then report.storageFailure = tostring(saveFailure); report.state, report.passed = "Failed", false end
update()
-- Keep this owned transport and all reports for inspection; do not stop the shared race.
