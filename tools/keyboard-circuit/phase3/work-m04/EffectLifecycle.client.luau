--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient(), "Run this fixture only in root-owned Studio Play")
assert(not shared.KCP2I09Race or not shared.KCP2I09Race.active, "Finish the owned traversal fixture first")
assert(not shared.KCP3M04Lifecycle01 or not shared.KCP3M04Lifecycle01.running, "Lifecycle fixture already running")

local player = Players.LocalPlayer
local candidate = assert(Workspace:FindFirstChild("KeyboardCircuit_P3_M04_01")) :: Model
local remote = ReplicatedStorage.Remotes.StudioDevControl :: RemoteFunction
local general = assert(player.PlayerScripts:FindFirstChild("ClassicAscentAmbience")) :: LocalScript
local began = os.clock()
local receipt: any = {candidate = candidate.Name, running = true, passed = false, steps = {}, failures = {}, limits = {},
	boundary = "Owned native client fixture through real StudioDevControl actions. Local preview flags and temporary client-only parent changes are restored. No computer/camera input, new authority, stored data, source or server hierarchy edits."}
shared.KCP3M04Lifecycle01 = receipt

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
local connections = {}
local holder: Folder? = nil
local originalParent = candidate.Parent
local originalPreview = candidate:GetAttribute("KCPhase2PreviewEnabled")
local fixtureToken = "Fixture/KeyboardCircuitLifecycle/" .. Http:GenerateGUID(false)
local lastRequestAt = -math.huge
local baseline: any

local function await(label: string, timeout: number, predicate)
	local deadline = os.clock() + timeout
	repeat
		local value = predicate()
		if value then return value end
		task.wait(.05)
	until os.clock() >= deadline
	error(label .. " timed out after " .. timeout .. " seconds")
end

local function request(payload: any)
	local remaining = .2 - (os.clock() - lastRequestAt)
	if remaining > 0 then task.wait(remaining) end
	lastRequestAt = os.clock()
	local result = remote:InvokeServer(payload)
	assert(result and result.ok == true, (result and result.message) or "Studio request failed")
	return result
end

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
		if (Lighting :: any)[name] ~= value then table.insert(failures, "Lighting." .. name .. ": " .. tostring((Lighting :: any)[name]) .. " != " .. tostring(value)) end
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

local function ownedGone(): boolean
	return not Workspace:FindFirstChild("KeyboardCircuitArchiveVisuals")
		and not player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects")
		and not Lighting:FindFirstChild("KeyboardArchiveBloom") and not Lighting:FindFirstChild("KeyboardArchiveSky")
		and player:GetAttribute("KCArchiveLightingOwner") == nil
end

local function diagnostics()
	local probes = player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects")
	local identity = if probes then probes:FindFirstChild("Candidate") else nil
	local diagnostic = if probes then probes:FindFirstChild("Diagnostics") else nil
	if not identity or not identity:IsA("ObjectValue") or identity.Value ~= candidate or not diagnostic or not diagnostic:IsA("BindableFunction") then return nil end
	local ok, result = pcall(function() return diagnostic:Invoke() end)
	return if ok then result else nil
end

local function activeReady(label: string)
	local skyConfig = require(candidate.SourceSnapshot.ArchiveSkyConfig)
	assert(skyConfig.Ready == true, label .. ": ready archive sky configuration required")
	return await(label, 16, function()
		local row = diagnostics()
		if not row or not row.active or not row.lightingApplied or not row.ownsLighting or row.readiness.state == "loading" then return nil end
		if row.sky and (row.sky.state == "failed" or row.sky.state == "unconfigured") then error(label .. ": archive sky failed: " .. tostring(row.sky.reason)) end
		if not row.skyReady or not row.skyApplied then return nil end
		assert(row.sky and row.sky.state == "ready" and row.sky.loaded == 6 and row.sky.failed == 0, label .. ": six successful sky face fetches required")
		local actualSky = assert(Lighting:FindFirstChildOfClass("Sky"), label .. ": actual Lighting Sky missing")
		local faces = {}
		for _, name in {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"} do
			local expected = skyConfig.Sky[name]
			assert(row.sky.statuses[expected] == "Success" and row.sky.textureIds[name] == expected, label .. ": fetch or diagnostic face mismatch: " .. name)
			assert((actualSky :: any)[name] == expected, label .. ": actual Lighting Sky face mismatch: " .. name)
			table.insert(faces, {property = name, configured = expected, actual = (actualSky :: any)[name], fetchStatus = row.sky.statuses[expected]})
		end
		assert(actualSky.SkyboxOrientation == skyConfig.Sky.SkyboxOrientation, label .. ": actual sky orientation mismatch")
		local orientation = actualSky.SkyboxOrientation
		row.skyProof = {passed = true, skyReady = row.skyReady, skyApplied = row.skyApplied, loaded = row.sky.loaded, failed = row.sky.failed,
			actualSky = actualSky:GetFullName(), faces = faces, orientation = {orientation.X, orientation.Y, orientation.Z}}
		receipt.skyProofs = receipt.skyProofs or {}
		table.insert(receipt.skyProofs, {activation = label, proof = row.skyProof})
		assert(row.readiness.state == "ready" or row.readiness.state == "degraded", label .. ": readiness cancelled")
		assert(general.Enabled and general:GetAttribute("KCArchiveYielded") == candidate.Name, label .. ": missing general-controller acknowledgement")
		assert(typeof(row.lightingOwnerToken) == "string" and player:GetAttribute("KCArchiveLightingOwner") == row.lightingOwnerToken, label .. ": ownership token")
		assert(row.updateConnections == 1 and row.entryConnections == 1, label .. ": cosmetic connection budget")
		local economical = row.quality > 0 and row.quality <= 3
		assert(row.localPartCount == (if economical then 98 else 101), label .. ": local part pool")
		assert(row.tracePoolCount == (if economical then 2 else 4), label .. ": trace pool")
		assert(row.depthLayerCount == (if economical then 0 else 1), label .. ": depth quality cap")
		assert(row.dynamicLights == 0 and row.particleEmitters == 0 and row.restoreFailures == 0, label .. ": effect budget or restoration failure")
		local world = assert(Workspace:FindFirstChild("KeyboardCircuitArchiveVisuals"))
		local parts = 0
		for _, object in world:GetDescendants() do
			assert(not object:IsA("Light") and not object:IsA("ParticleEmitter"), label .. ": unexpected emitter")
			if object:IsA("BasePart") then
				parts += 1
				assert(object.Anchored and not object.CanCollide and not object.CanTouch and not object.CanQuery and not object.CastShadow, label .. ": interactive cosmetic part")
			end
		end
		assert(parts == row.localPartCount, label .. ": observed local part count")
		return row
	end)
end

local function checkRestored(label: string)
	await(label .. " owned cleanup", 5, ownedGone)
	local ok, failures = comparison(baseline)
	assert(ok, label .. ": " .. table.concat(failures, "; "))
	return {exactLightingRestored = true, originalObjectReferencesRetained = true, ownedObjectsGone = true}
end

local function step(name: string, callback)
	local started = os.clock()
	receipt.currentStep = name
	local result = callback()
	table.insert(receipt.steps, {name = name, passed = true, elapsedSeconds = os.clock() - started, result = result})
	return result
end

task.spawn(function()
	local ok, problem = xpcall(function()
		assert(general.Enabled, "General ambience controller must be enabled for real handoff checks")
		request({action = "Teleport", destination = "Lobby"})
		await("initial Lobby detach", 5, function() return player:GetAttribute("KCPhase2Candidate") == nil and ownedGone() end)
		await("general Lobby handback", 2, function() return general:GetAttribute("KCArchiveYielded") == nil end)
		baseline = capture()
		task.wait(.65)
		local stable, changes = comparison(baseline)
		assert(stable, "Lobby lighting is changing independently: " .. table.concat(changes, "; "))
		receipt.baseline = describe(baseline)
		shared.KCP3M04LifecycleBaselineCheck = function() return comparison(baseline) end

		local first = step("real F6 entry and resolved readiness", function()
			local reply = request({action = "KeyboardCircuitTest"})
			local row = activeReady("F6 activation")
			assert(player:GetAttribute("KCPhase2Candidate") == candidate.Name and player:GetAttribute("KCPhase2CompletedLaps") == 0, "F6 server state")
			task.wait(.25)
			local sample = assert(diagnostics())
			assert(sample.updates > 0 and sample.callbackSeconds >= 0 and sample.maximumCallbackSeconds >= 0, "Callback measurements unavailable")
			return {reply = reply, diagnostics = sample}
		end)
		local oldProbe = assert(player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects"))
		local oldWorld = assert(Workspace:FindFirstChild("KeyboardCircuitArchiveVisuals"))
		local oldToken = first.diagnostics.lightingOwnerToken
		step("real F6 restart removes old client state", function()
			local reply = request({action = "KeyboardCircuitTest"})
			await("old restart folders", 5, function() return oldProbe.Parent == nil and oldWorld.Parent == nil end)
			local row = activeReady("restart activation")
			assert(row.lightingOwnerToken ~= oldToken and row.completedLaps == 0 and row.lapSweeps == 0, "Restart reused cosmetic ownership or replayed an old lap")
			return {reply = reply, oldFoldersRemoved = true, newToken = true, diagnostics = row}
		end)

		step("Lobby cleanup and exact baseline", function()
			local reply = request({action = "Teleport", destination = "Lobby"})
			await("Lobby selection cleared", 5, function() return player:GetAttribute("KCPhase2Candidate") == nil end)
			local row = checkRestored("Lobby")
			task.wait(.65)
			local exact, failures = comparison(baseline)
			assert(exact, "General handback changed baseline: " .. table.concat(failures, "; "))
			row.reply, row.afterGeneralTick = reply, true
			return row
		end)

		step("ownership-token exit ordering", function()
			request({action = "KeyboardCircuitTest"})
			local row = activeReady("token entry")
			player:SetAttribute("KCArchiveLightingOwner", fixtureToken)
			request({action = "Teleport", destination = "Lobby"})
			await("token test selection cleared", 5, function() return player:GetAttribute("KCPhase2Candidate") == nil end)
			await("token test archive removed", 5, function()
				return not Workspace:FindFirstChild("KeyboardCircuitArchiveVisuals") and not player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects") and not Lighting:FindFirstChild("KeyboardArchiveBloom")
			end)
			task.wait(.75)
			assert(player:GetAttribute("KCArchiveLightingOwner") == fixtureToken and general:GetAttribute("KCArchiveYielded") == candidate.Name, "General controller resumed before ownership release")
			local exact, failures = comparison(baseline)
			assert(exact, "Archive restoration under retained token failed: " .. table.concat(failures, "; "))
			player:SetAttribute("KCArchiveLightingOwner", nil)
			await("token release handback", 2, function() return general:GetAttribute("KCArchiveYielded") == nil end)
			checkRestored("token release")
			return {actualPreviousToken = row.lightingOwnerToken, stubHeldAfterSelectionClearSeconds = .75, generalYieldPreserved = true, exactBaseline = true, tokenReleased = true}
		end)

		step("local preview-disable cleanup and reactivation", function()
			request({action = "KeyboardCircuitTest"})
			local before = activeReady("preview-disable entry")
			candidate:SetAttribute("KCPhase2PreviewEnabled", false)
			local restored = checkRestored("preview disabled")
			candidate:SetAttribute("KCPhase2PreviewEnabled", originalPreview)
			local after = activeReady("preview reactivated")
			assert(before.lightingOwnerToken ~= after.lightingOwnerToken, "Preview reactivation reused owner token")
			return {restored = restored, localFlagRestored = true, newOwner = true}
		end)

		step("client-local candidate removal and restoration", function()
			local before = activeReady("removal entry")
			holder = Instance.new("Folder")
			holder.Name, holder.Parent = "KCM04LifecycleOwnedHolder", Workspace
			candidate.Parent = holder
			local restored = checkRestored("candidate top-level removal")
			candidate.Parent = originalParent
			holder:Destroy(); holder = nil
			local after = activeReady("candidate restored")
			assert(before.lightingOwnerToken ~= after.lightingOwnerToken, "Removal restoration reused owner token")
			return {restored = restored, clientParentRestored = true, serverHierarchyUntouched = true, newOwner = true}
		end)

		step("actual audio cancellation stops the cosmetic profile", function()
			local audition = assert(player.PlayerGui:FindFirstChild("KeyboardCircuitAudition"))
			local stop = assert(audition:FindFirstChild("StopFeedback")) :: BindableFunction
			stop:Invoke()
			local restored = checkRestored("feedback cancellation")
			request({action = "Teleport", destination = "Lobby"})
			await("cancelled selection leaves", 5, function() return player:GetAttribute("KCPhase2Candidate") == nil end)
			request({action = "KeyboardCircuitTest"})
			local row = activeReady("fresh entry after cancellation")
			return {restored = restored, realFeedbackStop = true, reenteredThroughLobby = true, diagnostics = row}
		end)

		step("server-supported respawn cleanup and fresh client", function()
			local before = activeReady("respawn entry")
			local character = assert(player.Character)
			local humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
			local previousProbe = assert(player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects"))
			local previousWorld = assert(Workspace:FindFirstChild("KeyboardCircuitArchiveVisuals"))
			local deathObserved, removingObserved = false, false
			table.insert(connections, humanoid.Died:Connect(function() deathObserved = true end))
			table.insert(connections, player.CharacterRemoving:Connect(function(old) if old == character then removingObserved = true end end))
			local reply = request({action = "Respawn"})
			await("old respawn state removed", 5, function() return removingObserved and previousProbe.Parent == nil and previousWorld.Parent == nil and player.Character ~= character end)
			local after = activeReady("respawn activation")
			assert(after.lightingOwnerToken ~= before.lightingOwnerToken, "Respawn reused cosmetic ownership")
			if not deathObserved then table.insert(receipt.limits, "Server-supported Respawn proved character replacement; a real Humanoid death path was not triggered by this fixture.") end
			request({action = "Teleport", destination = "Lobby"})
			local restored = checkRestored("respawn Lobby")
			return {reply = reply, oldCharacterRemoved = true, oldFoldersRemoved = true, newOwner = true, healthDeathObserved = deathObserved, exactBaseline = restored}
		end)

		receipt.separateOtherMapHandoffRequired = true
	end, debug.traceback)
	if not ok then table.insert(receipt.failures, tostring(problem)) end

	-- Restore fixture-local changes before returning the owned test to its normal entry point.
	for _, connection in connections do connection:Disconnect() end
	if candidate.Parent ~= originalParent then candidate.Parent = originalParent end
	candidate:SetAttribute("KCPhase2PreviewEnabled", originalPreview)
	if holder then holder:Destroy(); holder = nil end
	if player:GetAttribute("KCArchiveLightingOwner") == fixtureToken then player:SetAttribute("KCArchiveLightingOwner", nil) end
	local returned, returnProblem = xpcall(function()
		request({action = "Teleport", destination = "Lobby"})
		await("final clean Lobby", 5, function() return player:GetAttribute("KCPhase2Candidate") == nil and ownedGone() end)
		if baseline then checkRestored("final Lobby") end
		request({action = "KeyboardCircuitTest"})
		local row = activeReady("final owner start")
		assert(player:GetAttribute("KCPhase2CompletedLaps") == 0 and player:GetAttribute("KCPhase2CheckpointOrdinal") == 0, "Final owner progression is not reset")
		local root = assert(player.Character and player.Character:FindFirstChild("HumanoidRootPart")) :: BasePart
		local ray = RaycastParams.new()
		ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {candidate}, true
		local support = Workspace:Raycast(root.Position, Vector3.new(0, -8, 0), ray)
		assert(support and support.Instance == candidate.CheckpointBays.F00.BankContact, "Final owner lacks permanent start support")
		receipt.ownerReady = {candidate = candidate.Name, support = support.Instance:GetFullName(), diagnostics = row}
	end, debug.traceback)
	if not returned then table.insert(receipt.failures, "Final handoff: " .. tostring(returnProblem)) end
	receipt.elapsedSeconds, receipt.running, receipt.passed = os.clock() - began, false, #receipt.failures == 0
	shared.KCP3M04Lifecycle01 = receipt
end)

return Http:JSONEncode({started = true, candidate = candidate.Name, receipt = "shared.KCP3M04Lifecycle01", boundary = receipt.boundary})
