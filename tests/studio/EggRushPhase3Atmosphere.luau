--!nonstrict

local Test = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local baseline, sampledCamera = nil, nil
local baselineOrigin = "NotCaptured"
local properties = {
	Lighting = {"Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation", "ColorShift_Top", "ColorShift_Bottom", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "FogColor", "FogStart", "FogEnd", "GlobalShadows", "ShadowSoftness"},
	Sky = {"SkyboxFt", "SkyboxBk", "SkyboxLf", "SkyboxRt", "SkyboxUp", "SkyboxDn", "SkyboxOrientation", "CelestialBodiesShown", "StarCount", "SunAngularSize", "MoonAngularSize"},
	Atmosphere = {"Density", "Offset", "Haze", "Glare", "Color", "Decay"},
	ColorCorrectionEffect = {"Enabled", "Brightness", "Contrast", "Saturation", "TintColor"},
	BloomEffect = {"Enabled", "Intensity", "Size", "Threshold"},
	BlurEffect = {"Enabled", "Size"},
	DepthOfFieldEffect = {"Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"},
	SunRaysEffect = {"Enabled", "Intensity", "Spread"},
}

local function context()
	assert(RunService:IsStudio() and RunService:IsClient() and game.PlaceId == 85558151074819, "Use the owned Studio PlayClient")
	local player = assert(Players.LocalPlayer)
	local scripts = assert(player:FindFirstChild("PlayerScripts"))
	local flow = require(scripts.Controllers.RaceFlowController)
	return player, assert(flow.GetState(), "Actual RaceFlow snapshot required"), require(game.ReplicatedStorage.Config.EggRushAmbienceConfig)
end

local function lightingSnapshot()
	local result = {}
	local objects = Lighting:GetChildren()
	table.insert(objects, Lighting)
	for _, object in objects do
		local values = {Parent = object.Parent}
		for _, name in properties[object.ClassName] or {} do values[name] = object[name] end
		result[object] = values
	end
	return result
end

local function lightingDifferences(before)
	local current, differences = lightingSnapshot(), {}
	for object, values in before do
		local now = current[object]
		if not now then table.insert(differences, object.ClassName .. ": removed")
		else
			for name, value in values do
				if now[name] ~= value then table.insert(differences, object.ClassName .. "." .. name) end
			end
		end
	end
	for object in current do
		if not before[object] then table.insert(differences, object.ClassName .. ": added") end
	end
	return differences
end

local function ownedEffects(camera)
	local effects = {}
	if camera then
		for _, child in camera:GetChildren() do
			if child.Name == "EggRushWarmth" then table.insert(effects, child) end
		end
	end
	return effects
end

local function noLightingEffect()
	assert(not Lighting:FindFirstChild("EggRushWarmth", true), "Owned warmth effect must never be under Lighting")
end

local function actualRacer()
	local player, state, config = context()
	assert(state.courseId == config.CourseId and state.state == "Racing" and state.status == "Racing", "Actual ordinary Egg Rush Racing participant required")
	assert(player:GetAttribute("OnboardingReady") == true and player:GetAttribute("ArrivalPhase") == "Ready" and player:GetAttribute("ArrivalOpen") ~= true, "Ordinary arrival must be complete")
	assert(player:GetAttribute("TournamentPresentation") ~= true and player:GetAttribute("PracticeRoom") ~= true, "Finish the ordinary course handoff first")
	local character = assert(player.Character)
	local humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
	local root = assert(character:FindFirstChild("HumanoidRootPart"))
	assert(humanoid.Health > 0 and not root.Anchored, "Living unanchored actual racer required")
	local course = assert(workspace:FindFirstChild("RaceCourse"))
	assert(course:GetAttribute("EROwned") == true and course.CourseInfo:GetAttribute("CourseId") == config.CourseId, "Actual Egg Rush course required")
	return player, state, config, root, humanoid, course
end

function Test.BeginLobby()
	local _, state = context()
	assert(state.status == "Lobby", "Call after actual return to lobby, before ordinary joining")
	task.wait(0.6)
	local _, settled = context()
	assert(settled.status == "Lobby", "Lobby changed during baseline")
	assert(#ownedEffects(workspace.CurrentCamera) == 0, "Warmth leaked into lobby")
	noLightingEffect()
	baseline, baselineOrigin = lightingSnapshot(), "ActualLobby"
	return {ok = true, baseline = baselineOrigin, cameraWrites = 0, playerStateWrites = 0}
end

function Test.Sample()
	local _, state, config = actualRacer()
	if not baseline then baseline, baselineOrigin = lightingSnapshot(), "AlreadyRacing" end
	task.wait(0.6)
	actualRacer()
	local camera = assert(workspace.CurrentCamera)
	local effects = ownedEffects(camera)
	assert(#effects == 1 and effects[1]:IsA("ColorCorrectionEffect"), "Expected exactly one actual camera warmth effect")
	local effect, grade = effects[1], config.ColorCorrection
	assert(effect.Enabled, "Warmth is disabled")
	for _, key in {"Brightness", "Contrast", "Saturation", "TintColor"} do
		local actual, expected = effect[key], grade[key]
		local difference = if typeof(actual) == "number" then math.abs(actual - expected)
			else math.max(math.abs(actual.R - expected.R), math.abs(actual.G - expected.G), math.abs(actual.B - expected.B))
		assert(difference < 0.000001, "Camera grade differs from frozen config: " .. key)
	end
	assert(math.abs(grade.Brightness) <= 0.01 and math.abs(grade.Contrast) <= 0.03 and math.abs(grade.Saturation) <= 0.03, "Expected a mild grade")
	assert(math.min(grade.TintColor.R, grade.TintColor.G, grade.TintColor.B) >= 0.95, "Tint must retain warning colors")
	local differences = lightingDifferences(baseline)
	assert(#differences == 0, "Global lighting changed: " .. table.concat(differences, ", "))
	noLightingEffect()
	sampledCamera = camera
	return {ok = true, courseId = state.courseId, raceId = state.raceId, status = state.status, baseline = baselineOrigin,
		brightness = effect.Brightness, contrast = effect.Contrast, saturation = effect.Saturation,
		tint = {effect.TintColor.R, effect.TintColor.G, effect.TintColor.B}, cameraEffects = #effects,
		lightingDifferences = differences, cameraWrites = 0, playerStateWrites = 0,
		limits = "Observed actual client effect and lighting stability; entry lighting comparison requires BeginLobby before joining; visual hazard contrast still needs native judgment"}
end

function Test.VerifyExit()
	assert(sampledCamera and baseline, "Run Sample during the real race first")
	local _, state, config = context()
	local reason = if state.status == "Lobby" then "ActualLobby" elseif state.courseId ~= config.CourseId then "ActualOtherCourse" else nil
	assert(reason, "Leave through actual game flow before VerifyExit; this test never changes player state")
	task.wait(0.6)
	local _, settled = context()
	assert(settled.status == "Lobby" or settled.courseId ~= config.CourseId, "Player re-entered Egg Rush during exit check")
	assert(#ownedEffects(workspace.CurrentCamera) == 0 and #ownedEffects(sampledCamera) == 0, "Warmth remains on current or previously sampled camera")
	noLightingEffect()
	local differences = lightingDifferences(baseline)
	if settled.status == "Lobby" then assert(#differences == 0, "Lobby lighting differs from baseline: " .. table.concat(differences, ", ")) end
	return {ok = true, reason = reason, status = settled.status, courseId = settled.courseId, cameraEffects = 0,
		lightingDifferences = differences, cameraWrites = 0, playerStateWrites = 0,
		cameraReplacement = if workspace.CurrentCamera ~= sampledCamera then "Natural replacement observed; both cameras clear" else "Unverified; no natural replacement observed",
		limits = "Other-course profiles may legitimately change global lighting; exact baseline equality is asserted for actual Lobby exit only"}
end

function Test.SampleOccupied15(label, evidence)
	local _, state, _, root, humanoid, course = actualRacer()
	local camera = assert(workspace.CurrentCamera)
	local frame, focus, fov, viewport = camera.CFrame, camera.Focus, camera.FieldOfView, camera.ViewportSize
	local startFrame, startPosition = root.CFrame, root.Position
	local times, maximumDrift = {}, 0
	evidence = evidence or {}
	local inputReport = evidence.inputReport
	local inputState = if inputReport then inputReport:GetAttribute("State") else "Unverified"
	local started = os.clock()
	local connection = RunService.RenderStepped:Connect(function(delta)
		table.insert(times, delta * 1000)
		maximumDrift = math.max(maximumDrift, (root.Position - startPosition).Magnitude)
	end)
	task.wait(15)
	connection:Disconnect()
	local seconds = os.clock() - started
	local _, after = context()
	assert(after.raceId == state.raceId and after.status == "Racing" and after.courseId == state.courseId and workspace:FindFirstChild("RaceCourse") == course, "Actual race/course changed during occupied sample")
	assert(workspace.CurrentCamera == camera and humanoid.Health > 0, "Camera/character changed during occupied sample")
	assert(#times > 0, "No rendered frames observed")
	table.sort(times)
	local middle = math.floor(#times / 2)
	local median = if #times % 2 == 0 then (times[middle] + times[middle + 1]) / 2 else times[middle + 1]
	return {label = label or "Occupied Phase3 after world", seconds = seconds, samples = #times,
		medianMs = median, p95Ms = times[math.ceil(#times * 0.95)], maximumMs = times[#times], memoryMb = Stats:GetTotalMemoryUsageMb(),
		root = {startFrame:GetComponents()}, camera = {frame:GetComponents()}, focus = {focus:GetComponents()},
		fov = fov, viewport = {viewport.X, viewport.Y}, health = humanoid.Health, drift = (root.Position - startPosition).Magnitude,
		maximumDrift = maximumDrift, inputIsolated = inputState,
		cameraDriftStuds = (camera.CFrame.Position - frame.Position).Magnitude,
		focusDriftStuds = (camera.Focus.Position - focus.Position).Magnitude,
		inputIsolationStable = inputReport ~= nil and inputState == "Isolated" and inputReport:GetAttribute("State") == inputState,
		ordinaryJoin = evidence.ordinaryJoin == true, ordinaryVote = evidence.ordinaryVote == true,
		cameraWrites = 0, playerStateWrites = 0,
		limit = "Single occupied small Studio viewport; no crowd/device FPS proof; join/vote flags are caller-supplied evidence labels"}
end

return Test
