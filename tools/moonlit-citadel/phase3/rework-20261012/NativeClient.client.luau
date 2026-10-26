--!nonstrict
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CANDIDATE = "MC_P3_REWORK_R04"
assert(RunService:IsStudio() and RunService:IsRunning() and RunService:IsClient(), "Actual Studio LocalScript only")
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177, "Original Obby Tournament only")
assert(script:GetAttribute("OwnedMoonlitTest") == true and script:GetAttribute("RunNativeCommands") == true, "Explicit native driver opt-in required")
local player = Players.LocalPlayer
assert(player.UserId == 86069177, "Actual owner avatar only")
local tools = assert(game.ReplicatedStorage:WaitForChild("MoonlitPhase3Tools", 30))
tools:SetAttribute("NativeClientReady", false)
local Runner, runHandle
local viewState
local function restoreView()
	if not viewState then return end
	RunService:UnbindFromRenderStep("MoonlitReworkOwnedView")
	local camera = workspace.CurrentCamera
	camera.CFrame, camera.Focus, camera.CameraType, camera.FieldOfView = viewState.cf, viewState.focus, viewState.kind, viewState.fov
	game.Lighting.ClockTime = viewState.clock
	for gui, enabled in viewState.guis do if gui.Parent then gui.Enabled = enabled end end
	viewState = nil
end
local ok, failure = xpcall(function()
	local sourceHash = tools:GetAttribute("SourceHash")
	assert(type(sourceHash) == "string" and #sourceHash == 64 and sourceHash:match("^%x+$"), "Set final SourceHash before Play")
	assert(require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig).CandidateId == CANDIDATE)
	Runner = require(tools:WaitForChild("TestClient", 30))
	local gui = assert(player:WaitForChild("PlayerGui", 30))
	local historyRoot = gui:FindFirstChild("MoonlitPhase3NativeCommands")
	if not historyRoot then historyRoot = Instance.new("Folder"); historyRoot.Name, historyRoot.Parent = "MoonlitPhase3NativeCommands", gui end
	local history = Instance.new("Folder")
	history.Name, history.Parent = "Native_" .. HttpService:GenerateGUID(false):gsub("%-", ""), historyRoot
	history:SetAttribute("OwnedMoonlitTest", true)
	history:SetAttribute("Candidate", CANDIDATE)
	history:SetAttribute("SourceHash", sourceHash)
	local receipts, seen = 0, {}
	local initialRaw = tools:GetAttribute("NativeCommand")
	if type(initialRaw) == "string" then
		local decoded, request = pcall(HttpService.JSONDecode, HttpService, initialRaw)
		if decoded and type(request) == "table" and type(request.id) == "string" then seen[request.id] = true end
		history:SetAttribute("InitialCommandIgnored", initialRaw:sub(1, 12000))
	end
	local function current()
		local report = Runner.Current()
		if not report then return {state = "Idle"} end
		return {state = report.state, packet = report.packet, mode = report.mode, failure = report.failure, sourceHash = report.sourceHash,
			evidencePath = report.evidencePath, currentStep = report.currentStep, waiting = report.waiting, elapsed = report.elapsed,
			deaths = report.deaths or report.actualDeaths, characterReplacements = report.characterReplacements,
			final = report.final, timing = report.timing}
	end
	local function ready()
		assert(tools:GetAttribute("NativeServerReady") == true, "Bind real server observer before client actions")
		assert(player:GetAttribute("OnboardingReady") == true and player:GetAttribute("ArrivalPhase") == "Ready"
			and player:GetAttribute("ArrivalOpen") == false and player:HasAppearanceLoaded(), "Complete actual arrival without bypasses")
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		assert(humanoid and humanoid.Health > 0 and humanoid.RigType == Enum.HumanoidRigType.R15, "Keep actual loaded default R15 avatar")
	end
	local function execute(request)
		if request.action == "Current" then return current() end
		if request.action == "RestoreView" then restoreView(); return {restored = true} end
		if request.action == "Stop" then
			if runHandle then runHandle.Stop(); runHandle = nil end
			Runner.Stop("Stopped by lead")
			return current()
		end
		ready()
		if request.action == "View" then
			restoreView()
			assert(type(request.position) == "table" and #request.position == 3 and type(request.target) == "table" and #request.target == 3)
			local duration = request.durationSeconds or 60
			assert(duration > 0 and duration <= 120)
			local camera, guis = workspace.CurrentCamera, {}
			for _, gui in player.PlayerGui:GetChildren() do if gui:IsA("ScreenGui") then guis[gui] = gui.Enabled end end
			local snapshot = {cf = camera.CFrame, focus = camera.Focus, kind = camera.CameraType, fov = camera.FieldOfView,
				clock = game.Lighting.ClockTime, guis = guis}
			viewState = snapshot
			local frame = CFrame.lookAt(Vector3.new(table.unpack(request.position)), Vector3.new(table.unpack(request.target)))
			local untilTime = os.clock() + duration
			RunService:BindToRenderStep("MoonlitReworkOwnedView", Enum.RenderPriority.Camera.Value + 200, function()
				if viewState ~= snapshot then return end
				if os.clock() > untilTime then restoreView(); return end
				camera.CameraType, camera.CFrame, camera.FieldOfView = Enum.CameraType.Scriptable, frame, request.fieldOfView or 70
				if request.dayPreview then game.Lighting.ClockTime = 14.5 end
				for gui in guis do if gui.Parent then gui.Enabled = false end end
			end)
			return {ownedPhotoView = true, duration = duration, dayPreview = request.dayPreview == true,
				position = request.position, target = request.target, sourceHash = sourceHash, avatarMoved = false}
		end
		if request.action == "Run" then
			assert(type(request.packet) == "string", "Prepared packet name required")
			runHandle = Runner.Run(request.packet)
			return current()
		elseif request.action == "Observe" then
			assert(tools:GetAttribute("ClientWaitingPacket") == nil, "Cancel pending continuous release before observation")
			assert(type(request.options) == "table" and type(request.options.durationSeconds) == "number"
				and request.options.durationSeconds > 0 and request.options.durationSeconds <= 120, "One bounded passive observation required")
			local course = assert(workspace:FindFirstChild("RaceCourse"))
			runHandle = Runner.Observe(course, request.options)
			local report = Runner.Current()
			report.sourceHash, report.stimulus = sourceHash, request.stimulus
			local results = assert(gui:FindFirstChild("MoonlitPhase3Results"))
			for _, record in results:GetChildren() do
				if record:GetFullName() == report.evidencePath then record:SetAttribute("SourceHash", sourceHash); break end
			end
			return current()
		end
		error("Unknown client native command")
	end
	tools:SetAttribute("NativeClientHistory", history:GetFullName())
	tools:SetAttribute("NativeClientReady", true)
	local started, previousRaw = os.clock(), initialRaw
	while script.Parent and tools.Parent and script:GetAttribute("RunNativeCommands") == true
		and script:GetAttribute("OwnedMoonlitTest") == true and os.clock()-started < 3600 and receipts < 128 do
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
				if request.side == "Server" then return end
				assert(not seen[request.id], "Keep command IDs unique")
				seen[request.id] = true
				return execute(request)
			end, debug.traceback)
			if not didRun or (type(request) == "table" and request.side == "Client") then
				receipts += 1
				local receipt = {id = type(request) == "table" and request.id, action = type(request) == "table" and request.action,
					ok = didRun, result = result, at = workspace:GetServerTimeNow(), candidate = CANDIDATE, sourceHash = sourceHash}
				local chunk = Instance.new("StringValue")
				chunk.Name, chunk.Value, chunk.Parent = string.format("Command_%03d", receipts), HttpService:JSONEncode(receipt), history
				tools:SetAttribute("NativeClientResult", chunk.Value)
			end
		end
		task.wait(.05)
	end
	if runHandle then runHandle.Stop(); runHandle = nil end
	restoreView()
	Runner.Stop("Native driver stopped")
end, debug.traceback)
tools:SetAttribute("NativeClientReady", false)
if not ok then
	restoreView()
	if runHandle then pcall(runHandle.Stop) end
	if Runner then pcall(Runner.Stop, "Native driver failed") end
	tools:SetAttribute("NativeClientFailure", tostring(failure))
	warn("[Moonlit Phase3 native client] " .. tostring(failure))
end
