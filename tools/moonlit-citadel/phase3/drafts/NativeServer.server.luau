--!nonstrict
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CANDIDATE = "MC_P3_M01_R01"
assert(RunService:IsStudio() and RunService:IsRunning() and RunService:IsServer(), "Native Studio server Script only")
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177, "Original Obby Tournament only")
assert(script:GetAttribute("OwnedMoonlitTest") == true and script:GetAttribute("RunNativeCommands") == true, "Explicit native driver opt-in required")
assert(not script:FindFirstAncestorWhichIsA("Actor"), "Use Main's ordinary server VM")
local tools = assert(game.ReplicatedStorage:FindFirstChild("MoonlitPhase3Tools"))
tools:SetAttribute("NativeServerReady", false)
local observer
local ok, failure = xpcall(function()
	local sourceHash = tools:GetAttribute("SourceHash")
	assert(type(sourceHash) == "string" and #sourceHash == 64 and sourceHash:match("^%x+$"), "Set final SourceHash before Play")
	local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
	assert(Config.CandidateId == CANDIDATE, "Install final Phase 3 candidate first")
	local services = {}
	for _, name in {"CourseService", "RaceService", "PlayerRaceService", "CheckpointService", "ResultsService", "MoonlitCitadelService"} do
		-- Native Scripts share Main's required module tables; do not repeat Init or Start.
		services[name] = require(game.ServerScriptService.Services:WaitForChild(name))
	end
	local deadline = os.clock() + 90
	repeat task.wait(.05) until services.RaceService.IsStudioHoldingLobby() or os.clock() >= deadline
	assert(services.RaceService.IsStudioHoldingLobby(), "Main did not initialize its held Studio lobby; do not release early")
	assert(game.ReplicatedStorage.Remotes:FindFirstChild("StudioDevControl"), "Main's real developer controls absent")
	local Server = require(game.ServerStorage.MoonlitPhase3Tools.TestServer)
	local Check = require(game.ServerStorage.MoonlitPhase3Tools.CheckLayout)
	local Layout = require(game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.Layout)
	observer = Server.Start(services, {interval = .08, diagnostics = services.MoonlitCitadelService.GetDiagnostics})
	local history = Instance.new("Folder")
	history.Name, history.Parent = "Native_" .. HttpService:GenerateGUID(false):gsub("%-", ""), game.ServerStorage.MoonlitPhase3Tools
	history:SetAttribute("OwnedMoonlitTest", true)
	history:SetAttribute("Candidate", CANDIDATE)
	history:SetAttribute("SourceHash", sourceHash)
	local receipts, seen, focusSetups = 0, {}, {}
	local initialRaw = tools:GetAttribute("NativeCommand")
	if type(initialRaw) == "string" then
		local decoded, request = pcall(HttpService.JSONDecode, HttpService, initialRaw)
		if decoded and type(request) == "table" and type(request.id) == "string" then seen[request.id] = true end
		history:SetAttribute("InitialCommandIgnored", initialRaw:sub(1, 12000))
	end
	local function save(name, value)
		assert(not history:FindFirstChild(name), "Keep earlier native JSON")
		local encoded = HttpService:JSONEncode(value)
		local folder = Instance.new("Folder")
		folder.Name, folder.Parent = name, history
		folder:SetAttribute("JSONBytes", #encoded)
		for offset = 1, #encoded, 140000 do
			local chunk = Instance.new("StringValue")
			chunk.Name, chunk.Value, chunk.Parent = string.format("JSON_%03d", math.ceil(offset/140000)), encoded:sub(offset, offset+139999), folder
		end
		return folder:GetFullName()
	end
	local function owner()
		local clients = Players:GetPlayers()
		assert(#clients == 1 and clients[1].UserId == 86069177, "One actual owner client only")
		return clients[1]
	end
	local function readyOwner()
		local player = owner()
		assert(player:GetAttribute("OnboardingReady") == true and player:GetAttribute("ArrivalPhase") == "Ready"
			and player:HasAppearanceLoaded(), "Complete real arrival without driver bypasses")
		return player
	end
	local function activeCourse()
		local course = assert(services.CourseService.GetActiveCourse(), "No actual active shared course")
		assert(course == workspace:FindFirstChild("RaceCourse") and course:GetAttribute("CandidateId") == CANDIDATE
			and services.CourseService.GetActiveCourseId() == Config.CourseId and services.CourseService.GetLapCount() == 1, "Wrong candidate/course/lap count")
		return course
	end
	local function decodeVectors(value)
		if type(value) ~= "table" then return value end
		if value._t == "v" then return Vector3.new(table.unpack(value.value)) end
		local result = {}
		for key, child in value do result[key] = decodeVectors(child) end
		return result
	end
	local function execute(request)
		owner()
		assert(observer and not observer.Debug().failure, "Real server observer is unavailable or failed")
		if request.action == "State" then
			local player = owner()
			return {raceId = services.RaceService.GetCurrentRaceId(), raceState = services.RaceService.GetRaceState(),
				courseId = services.CourseService.GetActiveCourseId(), holdInLobby = services.RaceService.IsStudioHoldingLobby(),
				arrivalPhase = player:GetAttribute("ArrivalPhase"), onboardingReady = player:GetAttribute("OnboardingReady"),
				progress = player:GetAttribute("MCPhase3Progress"), runtime = services.MoonlitCitadelService.GetDiagnostics()}
		elseif request.action == "Prepare" then
			local spec = decodeVectors(assert(request.spec, "Route spec required"))
			assert(spec.sourceHash == nil or spec.sourceHash == sourceHash, "Spec source hash differs")
			spec.sourceHash = sourceHash
			return Server.Prepare(Layout, spec)
		elseif request.action == "PlaceFocus" then
			local player = readyOwner()
			activeCourse()
			assert(type(request.packet) == "string", "Focused packet name required")
			local key = services.RaceService.GetCurrentRaceId() .. ":" .. request.packet
			assert(not focusSetups[key], "This focused packet already had its one setup placement in this race")
			local receipt = Server.PlaceFocus(player, request.packet)
			focusSetups[key] = true
			return receipt
		elseif request.action == "Restart" then
			readyOwner()
			assert(services.CourseService.SelectCourseForStudio(Config.CourseId), "Existing Studio map selection rejected")
			assert(services.RaceService.ApplyStudioAction("RestartRace"), "Existing shared restart rejected")
			return {requested = "RestartRace", requestedAt = workspace:GetServerTimeNow(), priorRaceId = services.RaceService.GetCurrentRaceId()}
		elseif request.action == "HoldLobby" then
			assert(services.RaceService.ApplyStudioAction("HoldLobby"), "Existing shared HoldLobby rejected")
			return {requested = "HoldLobby"}
		elseif request.action == "Static" then
			local report = Check.Static(Layout, sourceHash)
			return {evidencePath = save("Static_" .. request.id, report), ok = report.ok, routes = #report.routes,
				contacts = report.contacts, tightJumps = #report.tightJumps, issues = #report.issues}
		elseif request.action == "Resources" then
			assert(type(request.meshTriangles) == "table" and type(request.baselineCounts) == "table", "Supply verified combined triangle map and complete R07 baseline")
			local report = Check.Resources(activeCourse(), request.meshTriangles, request.baselineCounts)
			report.sourceHash = sourceHash
			return {evidencePath = save("Resources_" .. request.id, report), counts = report.counts, triangleMappingComplete = report.triangleMappingComplete}
		elseif request.action == "AssertCleanFinish" then
			assert(type(request.raceId) == "string" and #request.raceId > 0, "Exact completed native race ID required")
			return observer.AssertCleanFinish(owner().UserId, request.raceId)
		elseif request.action == "SaveObserver" then
			local report = observer.Debug()
			report.sourceHash = sourceHash
			return {evidencePath = save("Observer_" .. request.id, report), failure = report.failure, sessions = #report.sessions}
		elseif request.action == "StopObserver" then
			local report = observer.Stop()
			report.sourceHash = sourceHash
			local path = save("ObserverStopped_" .. request.id, report)
			observer = nil
			tools:SetAttribute("NativeServerReady", false)
			return {evidencePath = path, stopped = true}
		end
		error("Unknown server native command")
	end
	tools:SetAttribute("NativeServerHistory", history:GetFullName())
	tools:SetAttribute("NativeServerReady", true)
	local started, previousRaw = os.clock(), initialRaw
	while script.Parent and tools.Parent and script:GetAttribute("RunNativeCommands") == true
		and script:GetAttribute("OwnedMoonlitTest") == true and observer ~= nil and os.clock()-started < 3600 and receipts < 128 do
		assert(tools:GetAttribute("SourceHash") == sourceHash, "SourceHash changed; end Play and install fresh helpers")
		local raw = tools:GetAttribute("NativeCommand")
		if type(raw) == "string" and raw ~= previousRaw then
			previousRaw = raw
			local request
			local didRun, result = xpcall(function()
				assert(#raw <= 12000, "Bound each native command to 12000 bytes")
				request = HttpService:JSONDecode(raw)
				assert(type(request) == "table" and type(request.id) == "string" and #request.id <= 80
					and request.id:match("^[%w_]+$") and request.candidate == CANDIDATE and request.sourceHash == sourceHash, "Wrong native command binding")
				assert(request.side == "Server" or request.side == "Client", "Explicit command side required")
				if request.side == "Client" then return end
				assert(not seen[request.id], "Keep command IDs unique")
				seen[request.id] = true
				return execute(request)
			end, debug.traceback)
			if not didRun or (type(request) == "table" and request.side == "Server") then
				receipts += 1
				local receipt = {id = type(request) == "table" and request.id, action = type(request) == "table" and request.action,
					ok = didRun, result = result, at = workspace:GetServerTimeNow(), candidate = CANDIDATE, sourceHash = sourceHash}
				save(string.format("Command_%03d", receipts), receipt)
				tools:SetAttribute("NativeServerResult", HttpService:JSONEncode(receipt))
			end
		end
		task.wait(.05)
	end
	if observer then
		local report = observer.Stop()
		report.sourceHash = sourceHash
		save("ObserverAtDriverStop", report)
		observer = nil
	end
end, debug.traceback)
tools:SetAttribute("NativeServerReady", false)
if not ok then
	if observer then pcall(observer.Stop) end
	tools:SetAttribute("NativeServerFailure", tostring(failure))
	warn("[Moonlit Phase3 native server] " .. tostring(failure))
end
