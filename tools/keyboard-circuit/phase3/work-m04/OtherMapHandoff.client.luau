--!strict
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient())
assert(not shared.KCP2I09Race or not shared.KCP2I09Race.active)
local player = game.Players.LocalPlayer
local candidate = workspace.KeyboardCircuit_P3_M04_01
local race = assert(workspace:FindFirstChild("RaceCourse"))
assert(race:GetAttribute("KCM04OwnedAmbienceFixture") == true)
assert(race.CourseInfo:GetAttribute("CourseId") == "city_run")
if workspace.StreamingEnabled then player:RequestStreamAroundAsync(Vector3.new(21462, 8, -1055), 5) end
local start = assert(race:WaitForChild("Start", 6))
assert(start:IsA("BasePart"))
local profile = require(game.ReplicatedStorage.Config.CityRunAmbienceConfig)
local function configMatches(actual, expected)
 if typeof(actual) == "number" and typeof(expected) == "number" then return math.abs(actual - expected) <= .001 end
 return actual == expected
end
local Lighting = game:GetService("Lighting")
local lightingNames = {"Ambient", "OutdoorAmbient", "Brightness", "ClockTime", "ExposureCompensation", "ColorShift_Top", "ColorShift_Bottom",
	"EnvironmentDiffuseScale", "EnvironmentSpecularScale", "FogColor", "FogStart", "FogEnd", "GlobalShadows", "ShadowSoftness"}
local skyNames = {"CelestialBodiesShown", "StarCount", "SunAngularSize", "MoonAngularSize", "SunTextureId", "MoonTextureId",
	"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "SkyboxOrientation"}
local atmosphereNames = {"Color", "Decay", "Density", "Glare", "Haze", "Offset"}
local postNames = {
	BloomEffect = {"Enabled", "Intensity", "Size", "Threshold"},
	BlurEffect = {"Enabled", "Size"},
	ColorCorrectionEffect = {"Enabled", "Brightness", "Contrast", "Saturation", "TintColor"},
	DepthOfFieldEffect = {"Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"},
	SunRaysEffect = {"Enabled", "Intensity", "Spread"},
}
local function capture()
	local snapshot = {values = {}, objects = {}, inventory = {}}
	for _, name in lightingNames do snapshot.values[name] = (Lighting :: any)[name] end
	for _, object in Lighting:GetChildren() do
		local names
		if object:IsA("Sky") then names = skyNames
		elseif object:IsA("Atmosphere") then names = atmosphereNames
		elseif object:IsA("PostEffect") then names = postNames[object.ClassName] or {"Enabled"} end
		if not names then continue end
		local record = {object = object, name = object.Name, className = object.ClassName, values = {}}
		for _, name in names do record.values[name] = (object :: any)[name] end
		table.insert(snapshot.objects, record)
		snapshot.inventory[object] = true
	end
	return snapshot
end

local function comparison(snapshot: any)
	local failures = {}
	for name, value in snapshot.values do
		if not configMatches((Lighting :: any)[name], value) then table.insert(failures, "Lighting." .. name .. ": " .. tostring((Lighting :: any)[name]) .. " != " .. tostring(value)) end
	end
	for _, record in snapshot.objects do
		if record.object.Parent ~= Lighting then table.insert(failures, record.name .. ": original object reference was not retained"); continue end
		for name, value in record.values do
			if (record.object :: any)[name] ~= value then table.insert(failures, record.name .. "." .. name .. ": property changed") end
		end
	end
	for _, object in Lighting:GetChildren() do
		if (object:IsA("Sky") or object:IsA("Atmosphere") or object:IsA("PostEffect")) and not snapshot.inventory[object] then
			table.insert(failures, object.Name .. ": unexpected lighting object")
		end
	end
	return #failures == 0, failures
end

local function describe(snapshot: any)
	local output = {lighting = {}, objects = {}}
	for name, value in snapshot.values do output.lighting[name] = if typeof(value) == "number" or typeof(value) == "boolean" or typeof(value) == "string" then value else tostring(value) end
	for _, record in snapshot.objects do
		local values = {}
		for name, value in record.values do values[name] = if typeof(value) == "number" or typeof(value) == "boolean" or typeof(value) == "string" then value else tostring(value) end
		table.insert(output.objects, {name = record.name, className = record.className, values = values})
	end
	return output
end


local baselineState: any
local function baseline() return comparison(baselineState) end
local remote = game.ReplicatedStorage.Remotes.StudioDevControl
local function await(label, timeout, predicate)
	local deadline = os.clock() + timeout
	repeat
		local value = predicate()
		if value then return value end
		task.wait(.05)
	until os.clock() > deadline
	error(label .. " timed out")
end
local function request(payload)
	task.wait(.25)
	local row = remote:InvokeServer(payload)
	assert(row.ok, row.message)
	return row
end
local function diagnostic()
	local folder = player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects")
	if not folder then return nil end
	local row = folder.Diagnostics:Invoke()
	return if row.active and row.skyReady and row.skyApplied and row.ownsLighting and row.streamingComplete and row.pendingAnchorCount == 0 and row.localPartCount == 101 and row.waveBarCount == 28 and row.underlightCount == 64 then row else nil
end
assert(player:GetAttribute("ArrivalOpen") ~= true and player:GetAttribute("OnboardingReady") == true)
-- Establish the existing controller's inactive property baseline after one real profile cycle.
local primeArchive = await("active Archive before profile control", 16, diagnostic)
local primeReply = request({action = "Teleport", destination = "Start"})
await("existing City Run control profile", 5, function()
 if player:GetAttribute("KCPhase2Candidate") ~= nil or player:GetAttribute("KCArchiveLightingOwner") ~= nil then return nil end
 for name, value in profile.Lighting do if not configMatches((Lighting :: any)[name], value) then return nil end end
 return Lighting.CourseColor.Enabled
end)
request({action = "Teleport", destination = "Lobby"})
await("existing controller inactive after control", 5, function()
 return player:GetAttribute("KCPhase2Candidate") == nil and not Lighting.CourseColor.Enabled and player.PlayerScripts.ClassicAscentAmbience:GetAttribute("KCArchiveYielded") == nil
end)
task.wait(.7)
baselineState = capture()
task.wait(.7)
assert(baseline(), "Actual pre-Archive Lobby baseline must be stable")
local baselineDescription = describe(baselineState)
request({action = "KeyboardCircuitTest"})
local before = await("active Archive before direct handoff", 16, diagnostic)
local reply = request({action = "Teleport", destination = "Start"})
await("actual City Run ambience profile", 5, function()
	if player:GetAttribute("KCPhase2Candidate") ~= nil or player:GetAttribute("KCArchiveLightingOwner") ~= nil then return nil end
	if player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects") or workspace:FindFirstChild("KeyboardCircuitArchiveVisuals") then return nil end
	for name, value in profile.Lighting do if not configMatches((game.Lighting :: any)[name], value) then return nil end end
	local sky = game.Lighting:FindFirstChildOfClass("Sky")
	if not sky then return nil end
	for name, value in profile.Sky do if not configMatches((sky :: any)[name], value) then return nil end end
	return game.Lighting.CourseColor.Enabled
end)
local actualOther = {brightness = game.Lighting.Brightness, clockTime = game.Lighting.ClockTime,
	start = tostring(start.Position), root = tostring(player.Character.HumanoidRootPart.Position)}
request({action = "Teleport", destination = "Lobby"})
await("exact original Lobby after City Run", 5, baseline)
task.wait(.7)
local exact, failures = baseline()
assert(exact, table.concat(failures, "; "))
request({action = "KeyboardCircuitTest"})
local after = await("fresh owner course start", 16, diagnostic)
shared.KCP3M04OtherMapHandoff01 = {candidate = candidate.Name, revision = "KC_P3_M04_01", passed = true,
	baselineAfterExistingProfileControl = true, profileControlReply = primeReply, actualPreArchiveBaseline = baselineDescription,
 courseId = "city_run", directArchiveHandoff = true, realServerTeleport = true, reply = reply,
	expectedLightingAndSkyApplied = true, originalLobbyRestored = true, originalObjectReferencesRetained = true,
	before = before, actualOther = actualOther, after = after,
	boundary = "Supported direct Archive-to-existing-City-Run profile and Start actions, followed by Lobby and fresh F6. Only the owned inert runtime copy is placed far enough away to isolate the ambience zones. The unchanged general controller retains disabled CourseColor tuning, so one real City Run/Lobby control establishes the stable pre-Archive baseline before the deciding direct handoff. The fixture includes one owned landing pad beneath the existing Start and explicitly requests far-region streaming. Original CourseLibrary and saved maps remain untouched; no other-map gameplay or human render claim."}
return game.HttpService:JSONEncode(shared.KCP3M04OtherMapHandoff01)
