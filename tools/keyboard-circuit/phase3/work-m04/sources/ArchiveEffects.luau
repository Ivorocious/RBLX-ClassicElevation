--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Http = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local SkyConfig = require(script.Parent.ArchiveSkyConfig)
local Effects = {}
local running = setmetatable({}, {__mode = "k"})

local lightingProfile = {
	Ambient = Color3.fromRGB(88, 103, 112), OutdoorAmbient = Color3.fromRGB(106, 118, 125),
	Brightness = 1.25, ClockTime = 19.2, ExposureCompensation = .1,
	ColorShift_Top = Color3.new(), ColorShift_Bottom = Color3.new(),
	EnvironmentDiffuseScale = .55, EnvironmentSpecularScale = .18,
	FogColor = Color3.fromRGB(29, 43, 48), FogStart = 1000, FogEnd = 100000,
}
local skyFaces = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}
local readyColor = Color3.fromRGB(156, 222, 191)
local preparingColor = Color3.fromRGB(245, 198, 85)

function Effects.ValidateSkyConfig(config: any)
	local result: any = {valid = false, textureIds = {}, assets = {}, reason = "awaiting real sky assets"}
	local profile = if type(config) == "table" and type(config.Sky) == "table" then config.Sky else {}
	for _, name in skyFaces do result.textureIds[name] = profile[name] or "" end
	if type(config) ~= "table" or config.Ready ~= true then return result end
	local seen = {}
	for _, name in skyFaces do
		local id = profile[name]
		if type(id) ~= "string" or not id:match("^rbxassetid://[1-9]%d*$") then
			result.reason = "missing or invalid " .. name
			return result
		end
		if seen[id] then result.reason = "duplicate face asset: " .. name; return result end
		seen[id] = true
		table.insert(result.assets, id)
	end
	if typeof(profile.SkyboxOrientation) ~= "Vector3" then result.reason = "missing sky orientation"; return result end
	result.valid, result.reason = true, "configured; loading not yet verified"
	result.profile = {
		SkyboxOrientation = profile.SkyboxOrientation, CelestialBodiesShown = false,
		StarCount = 0, SunAngularSize = 0, MoonAngularSize = 0,
	}
	for _, name in skyFaces do result.profile[name] = profile[name] end
	return result
end

function Effects.SampleWave(family: string, age: number, index: number, strength: number): number
	if age < 0 or age > 1.5 then return 0 end
	local middle = 1 - math.abs(index - 4) / 5
	if family == "Creamy" then return math.exp(-age * 3.6) * (1 - math.exp(-age * 22)) * middle * strength end
	if family == "Thocky" then return math.exp(-age * 4.3) * (1 - math.exp(-age * 45)) * (1.2 - math.abs(index - 4) / 9) * strength end
	if family == "Clacky" then
		local alternating = if (math.floor(age * 12) + index) % 2 == 0 then 1 else .28
		return math.exp(-age * 5.5) * alternating * middle * strength
	end
	return math.exp(-age * 15) * (if index == 4 or index == 2 or index == 6 then 1 else .55) * strength
end

function Effects.SampleContact(state: any, index: number, now: number, lapSweepAt: number): number
	if state.state ~= "loading" and state.state ~= "ready" and state.state ~= "degraded" then return 0 end
	local sweep = now - lapSweepAt - (index - 1) * .1
	if sweep >= 0 and sweep < .42 then return 1 - sweep / .52 end
	if state.state == "ready" then return .74 end
	if state.state == "degraded" then return .44 end
	if state.state ~= "loading" then return 0 end
	local progress = if type(state.total) == "number" and state.total > 0 then (state.loaded or 0) / state.total else 0
	if index <= math.floor(progress * 4) then return .56 end
	if index == math.min(4, math.floor(progress * 4) + 1) then return .24 + .10 * math.sin(now * 4) end
	return .08
end

local function findEffectAnchors(candidate: Model): Instance?
	local environment = candidate:FindFirstChild("MapEnvironment")
	return if environment then environment:FindFirstChild("ArchiveEffectParts") else nil
end

function Effects.ReconcileAnchors(anchors: Instance?, seen: {[string]: boolean}, economical: boolean, accept: any): number
	if not anchors then return 0 end
	local added = 0
	local function offer(parent: Instance?, name: string, path: string, kind: string, family: string?, index: number?)
		if not parent or seen[path] then return end
		local part = parent:FindFirstChild(name)
		if part and part:IsA("BasePart") and accept(part, kind, family, index) == true then
			seen[path] = true
			added += 1
		end
	end
	local underlights = anchors:FindFirstChild("Underlights")
	for index = 1, 64 do
		local name = "Strip" .. index
		offer(underlights, name, "Underlights." .. name, "Underlight", nil, nil)
	end
	local waves = anchors:FindFirstChild("LandmarkWaves")
	for _, family in {"Creamy", "Thocky", "Clacky", "Clicky"} do
		local group = if waves then waves:FindFirstChild(family) else nil
		for index = 1, 7 do
			local name = "Bar" .. index
			offer(group, name, "LandmarkWaves." .. family .. "." .. name, "WaveBar", family, index)
		end
	end
	local contacts = anchors:FindFirstChild("USBContacts")
	for index = 1, 4 do
		local name = "Contact" .. index
		offer(contacts, name, "USBContacts." .. name, "USBContact", nil, index)
	end
	if not economical then offer(anchors:FindFirstChild("InteriorDepth"), "LowLayer", "InteriorDepth.LowLayer", "Depth", nil, nil) end
	return added
end

function Effects.ResolveTraceSource(candidate: Model, index: number): BasePart?
	local anchors = findEffectAnchors(candidate)
	local paths = if anchors then anchors:FindFirstChild("TracePaths") else nil
	local link = if paths then paths:FindFirstChild("Trace" .. index) else nil
	local part = if link and link:IsA("ObjectValue") then link.Value else nil
	return if part and part:IsA("BasePart") and part:IsDescendantOf(candidate) then part else nil
end

local function copyPart(original: BasePart, parent: Instance): BasePart
	local clone = original:Clone()
	clone.Name = "Local" .. original.Name
	for _, child in clone:GetChildren() do child:Destroy() end
	clone.Anchored, clone.CanCollide, clone.CanTouch, clone.CanQuery, clone.CastShadow = true, false, false, false, false
	clone.LocalTransparencyModifier = 0
	clone.Transparency = original:GetAttribute("ActiveTransparency") or .2
	clone.Parent = parent
	return clone
end

function Effects.Start(candidate: Model, feedback: any)
	assert(RunService:IsClient(), "Archive effects belong to the selected player's client")
	if running[candidate] then return running[candidate] end
	assert(candidate:GetAttribute("KCArchiveAmbience") == true, "Archive effects require the course profile")
	local player = Players.LocalPlayer
	assert(player:GetAttribute("KCPhase2Candidate") == candidate.Name, "Archive effects require the real selected candidate")
	local originalCharacter = player.Character
	local originalRun = candidate:GetAttribute("KCPhase2RunId")
	local originalFeedbackRun = player:GetAttribute("KCPhase2FeedbackRun")
	local ownershipToken = candidate.Name .. "/" .. tostring(originalRun) .. "/" .. Http:GenerateGUID(false)
	local active, lightingApplied, accumulator = true, false, 0
	local sky = Effects.ValidateSkyConfig(SkyConfig)
	local skyState: any = {state = if sky.valid then "loading" else "unconfigured", reason = sky.reason,
		configReady = SkyConfig.Ready == true, valid = sky.valid, textureIds = sky.textureIds, loaded = 0, total = 6, failed = 0, statuses = {}}
	local skyApplied = false
	local skyLoadTask: thread? = nil
	local skyProbe: Sky? = nil
	local readiness: any = {state = "loading", loaded = 0, total = 8}
	local completed = player:GetAttribute("KCPhase2CompletedLaps") or 0
	local lapSweepAt = -math.huge
	local loop: RBXScriptConnection? = nil
	local entryConnection: RBXScriptConnection? = nil
	local world: Folder? = nil
	local probes: Folder? = nil
	local savedLighting, savedObjects, createdObjects = {}, {}, {}
	local strips, waves, contacts, traces = {}, {}, {}, {}
	local seenAnchors: {[string]: boolean} = {}
	local stats = {updates = 0, entries = 0, localEntries = 0, nearbyEntries = 0, lapSweeps = 0, tracePulses = 0, writes = 0,
		callbackSeconds = 0, maximumCallbackSeconds = 0, localPartCount = 0, underlightCount = 0, waveBarCount = 0, depthLayerCount = 0, restoreFailures = 0,
		clonedAnchorCount = 0, reconciliationPasses = 0}
	local quality = UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	local economical = quality > 0 and quality <= 3
	local expectedAnchorCount = if economical then 96 else 97
	local interval, visibleRadius = if economical then 1 / 20 else 1 / 30, if economical then 155 else 210
	local nextVisibilityAt = 0
	local function isCurrent(): boolean
		return active and candidate.Parent == Workspace and candidate:GetAttribute("KCPhase2RunId") == originalRun
			and candidate:GetAttribute("KCPhase2PreviewEnabled") == true and player:GetAttribute("KCPhase2Candidate") == candidate.Name
			and player:GetAttribute("KCPhase2FeedbackRun") == originalFeedbackRun and player.Character == originalCharacter
	end
	local function write(object: Instance, name: string, value: any)
		if (object :: any)[name] ~= value then (object :: any)[name] = value; stats.writes += 1 end
	end
	local function saveAndSet(object: Instance, properties: {[string]: any})
		local record = {object = object, values = {}}
		table.insert(savedObjects, record)
		for name, value in properties do record.values[name] = (object :: any)[name]; (object :: any)[name] = value end
	end
	local controller: any
	local function stop()
		if not active then return end
		active = false
		running[candidate] = nil
		if loop then loop:Disconnect(); loop = nil end
		if entryConnection then entryConnection:Disconnect(); entryConnection = nil end
		if skyLoadTask then pcall(task.cancel, skyLoadTask); skyLoadTask = nil end
		if skyProbe then skyProbe:Destroy(); skyProbe = nil end
		for _, object in createdObjects do pcall(function() object:Destroy() end) end
		for _, record in savedObjects do
			if record.object.Parent ~= Lighting then continue end
			for name, value in record.values do
				local restored = pcall(function() (record.object :: any)[name] = value end)
				if not restored then stats.restoreFailures += 1 end
			end
		end
		for name, value in savedLighting do
			local restored = pcall(function() (Lighting :: any)[name] = value end)
			if not restored then stats.restoreFailures += 1 end
		end
		lightingApplied = false
		skyApplied, skyState.state = false, "stopped"
		if world then world:Destroy() end
		if probes then probes:Destroy() end
		if player:GetAttribute("KCArchiveLightingOwner") == ownershipToken then player:SetAttribute("KCArchiveLightingOwner", nil) end
	end
	local function applySky()
		if not isCurrent() or skyApplied or skyState.state ~= "ready" then return end
		local object = Lighting:FindFirstChildOfClass("Sky")
		if object then saveAndSet(object, sky.profile)
		else
			object = Instance.new("Sky")
			object.Name = "KeyboardArchiveSky"
			table.insert(createdObjects, object)
			for name, value in sky.profile do (object :: any)[name] = value end
			object.Parent = Lighting
		end
		skyApplied = true
	end
	local function applyLighting()
		if not isCurrent() then return end
		assert(player:GetAttribute("KCArchiveLightingOwner") == nil, "Another archive profile still owns Lighting")
		player:SetAttribute("KCArchiveLightingOwner", ownershipToken)
		for name, value in lightingProfile do savedLighting[name] = (Lighting :: any)[name]; (Lighting :: any)[name] = value end
		for _, object in Lighting:GetChildren() do
			if object:IsA("PostEffect") then saveAndSet(object, {Enabled = false}) end
			if object:IsA("Atmosphere") then saveAndSet(object, {Density = 0, Haze = 0, Glare = 0}) end
		end
		applySky()
		local bloom = Instance.new("BloomEffect")
		bloom.Name, bloom.Intensity, bloom.Size, bloom.Threshold = "KeyboardArchiveBloom", .08, 14, 1.25
		bloom.Enabled = not economical
		table.insert(createdObjects, bloom)
		bloom.Parent = Lighting
		lightingApplied = true
	end
	local function getRoot(): BasePart?
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if character ~= originalCharacter or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil end
		return root
	end
	local function receiveAnchor(anchor: BasePart, kind: string, family: string?, index: number?): boolean
		if not isCurrent() or not world or not world.Parent then return false end
		if kind == "Underlight" then
			table.insert(strips, {part = copyPart(anchor, world), frame = anchor.CFrame, transparency = anchor:GetAttribute("ActiveTransparency")})
			stats.underlightCount += 1
		elseif kind == "WaveBar" then
			local group = anchor.Parent
			if not family or not group or group:GetAttribute("KeyFamily") ~= family or anchor:GetAttribute("BarIndex") ~= index then return false end
			local wave = waves[family]
			if not wave then
				wave = {at = -math.huge, strength = 0, center = anchor.Position, radius = group:GetAttribute("ReceiveRadius") or 135,
					bars = {}, entries = 0, ownEntries = 0, nearbyEntries = 0}
				waves[family] = wave
			end
			table.insert(wave.bars, {part = copyPart(anchor, world), frame = anchor.CFrame, size = anchor.Size, index = index})
			local center = Vector3.zero
			for _, bar in wave.bars do center += bar.frame.Position end
			wave.center = center / #wave.bars
			stats.waveBarCount += 1
		elseif kind == "USBContact" then
			if anchor:GetAttribute("ContactIndex") ~= index then return false end
			table.insert(contacts, {part = copyPart(anchor, world), index = index})
		elseif kind == "Depth" then
			copyPart(anchor, world)
			stats.depthLayerCount += 1
		else return false end
		stats.localPartCount += 1
		return true
	end
	local function reconcile()
		if not isCurrent() or not world or not world.Parent or stats.clonedAnchorCount >= expectedAnchorCount then return end
		stats.reconciliationPasses += 1
		stats.clonedAnchorCount += Effects.ReconcileAnchors(findEffectAnchors(candidate), seenAnchors, economical, receiveAnchor)
	end
	controller = {
		NotifyReady = function(state: any)
			if not active then return end
			readiness = {state = state.state, loaded = state.loaded or 0, total = state.total or 8, reason = state.reason}
			if state.state == "cancelled" or state.state == "stopped" then stop() end
		end,
		Diagnostics = function()
			local result = table.clone(stats)
			result.active, result.lightingApplied, result.ambienceWaiting = active, lightingApplied, active and not lightingApplied
			result.sky = table.clone(skyState)
			result.sky.textureIds, result.sky.statuses = table.clone(skyState.textureIds), table.clone(skyState.statuses)
			result.skyReady, result.skyApplied = skyState.state == "ready", skyApplied
			result.skyLoadTasks = if skyLoadTask and coroutine.status(skyLoadTask) ~= "dead" then 1 else 0
			result.skyPreloadProbes = if skyProbe then 1 else 0
			result.lightingOwnerToken, result.ownsLighting = player:GetAttribute("KCArchiveLightingOwner"), player:GetAttribute("KCArchiveLightingOwner") == ownershipToken
			result.readiness, result.completedLaps, result.finished = table.clone(readiness), completed, player:GetAttribute("KCPhase2Finished") == true
			result.updateConnections, result.entryConnections = if loop then 1 else 0, if entryConnection then 1 else 0
			result.interval, result.quality, result.tracePoolCount = interval, quality, #traces
			result.createdPartCount = stats.localPartCount
			result.expectedAnchorCount, result.pendingAnchorCount = expectedAnchorCount, expectedAnchorCount - stats.clonedAnchorCount
			result.streamingComplete = stats.clonedAnchorCount == expectedAnchorCount
			result.localPartCount = if world and world.Parent then #world:GetChildren() else 0
			result.ownedLightingObjects = 0
			for _, object in createdObjects do if object.Parent == Lighting then result.ownedLightingObjects += 1 end end
			result.dynamicLights, result.particleEmitters = 0, 0
			result.meanCallbackSeconds = if stats.updates > 0 then stats.callbackSeconds / stats.updates else 0
			result.waveStates = {}
			for family, wave in waves do
				result.waveStates[family] = {entries = wave.entries, ownEntries = wave.ownEntries, nearbyEntries = wave.nearbyEntries,
					lastEntryAt = if wave.at > -math.huge then wave.at else nil}
			end
			return result
		end,
		Stop = stop,
	}
	local ok, err = xpcall(function()
		if sky.valid then
			skyLoadTask = task.spawn(function()
				if not active then return end
				local assets = {}
				for _, id in sky.assets do assets[id] = true end
				local loaded, failed = {}, {}
				local fetched, problem = pcall(function()
					skyProbe = Instance.new("Sky")
					skyProbe.Name = "KeyboardArchiveSkyPreload"
					for name, value in sky.profile do (skyProbe :: any)[name] = value end
					ContentProvider:PreloadAsync({skyProbe}, function(id: string, status: Enum.AssetFetchStatus)
						if not active or not skyProbe or not assets[id] then return end
						skyState.statuses[id] = status.Name
						if status == Enum.AssetFetchStatus.Success then loaded[id], failed[id] = true, nil
						elseif status == Enum.AssetFetchStatus.Failure or status == Enum.AssetFetchStatus.TimedOut then failed[id], loaded[id] = true, nil end
						local readyCount, failCount = 0, 0
						for _ in loaded do readyCount += 1 end
						for _ in failed do failCount += 1 end
						skyState.loaded, skyState.failed = readyCount, failCount
					end)
				end)
				if skyProbe then skyProbe:Destroy(); skyProbe = nil end
				if not active then return end
				if fetched and skyState.loaded == 6 and skyState.failed == 0 then
					skyState.state, skyState.reason = "ready", "six face assets loaded"
				else
					skyState.state, skyState.reason = "failed", if fetched then "six successful face loads were not observed" else tostring(problem)
				end
			end)
		end
		world = Instance.new("Folder")
		world.Name, world.Parent = "KeyboardCircuitArchiveVisuals", Workspace
		reconcile()
		for index = 1, if economical then 2 else 4 do
			local part = Instance.new("Part")
			part.Name, part.Size, part.Material = "LocalTracePulse" .. index, Vector3.new(.7, .13, .7), Enum.Material.Neon
			part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow, part.Transparency = true, false, false, false, false, 1
			part.Color, part.Parent = readyColor, world
			table.insert(traces, {part = part, path = nil, began = -math.huge, nextAt = os.clock() + index * 1.3, cursor = index})
			stats.localPartCount += 1
		end
		entryConnection = feedback.SubscribeKeyEntries(function(family: string, position: Vector3, own: boolean, _distance: number)
			if not active then return end
			local wave = waves[family]
			if not wave or (position - wave.center).Magnitude > wave.radius then return end
			local root = getRoot()
			if not root or (root.Position - wave.center).Magnitude > visibleRadius then return end
			wave.at, wave.strength = os.clock(), if own then 1 else .48
			wave.entries += 1
			stats.entries += 1
			if own then wave.ownEntries += 1; stats.localEntries += 1 else wave.nearbyEntries += 1; stats.nearbyEntries += 1 end
		end)
		probes = Instance.new("Folder")
		probes.Name, probes.Parent = "KeyboardCircuitArchiveEffects", player.PlayerGui
		local identity = Instance.new("ObjectValue")
		identity.Name, identity.Value, identity.Parent = "Candidate", candidate, probes
		if RunService:IsStudio() then
			for name, callback in {Diagnostics = controller.Diagnostics, StopEffects = controller.Stop} do
				local probe = Instance.new("BindableFunction")
				probe.Name, probe.OnInvoke, probe.Parent = name, callback, probes
			end
		end
		local function update(delta: number)
			if not active then return end
			if not isCurrent() then stop(); return end
			local root = getRoot()
			if not root then stop(); return end
			accumulator += delta
			if accumulator < interval then return end
			accumulator = 0
			local started = os.clock()
			if not lightingApplied then
				local scripts = player:FindFirstChild("PlayerScripts")
				local general = if scripts then scripts:FindFirstChild("ClassicAscentAmbience") else nil
				if not general or (general:IsA("LocalScript") and not general.Enabled) or general:GetAttribute("KCArchiveYielded") == candidate.Name then applyLighting() end
			end
			if lightingApplied and not skyApplied and skyState.state == "ready" then applySky() end
			local laps = player:GetAttribute("KCPhase2CompletedLaps")
			if type(laps) == "number" and laps > completed then completed, lapSweepAt = laps, started; stats.lapSweeps += 1 end
			if started >= nextVisibilityAt then
				nextVisibilityAt = started + .2
				local ready, audio = pcall(feedback.Readiness)
				if not active then return end
				if not isCurrent() or not getRoot() then stop(); return end
				if not ready or (type(audio) == "table" and (audio.state == "stopped" or audio.state == "cancelled")) then
					readiness = {state = "cancelled", reason = if ready then audio.state else "feedback", loaded = 0, total = 8}
					stop()
					return
				end
				reconcile()
				for _, strip in strips do write(strip.part, "LocalTransparencyModifier", if (root.Position - strip.frame.Position).Magnitude <= visibleRadius then 0 else 1) end
			end
			for family, wave in waves do
				local visible = (root.Position - wave.center).Magnitude <= visibleRadius
				for _, bar in wave.bars do
					local amount = if visible then Effects.SampleWave(family, started - wave.at, bar.index, wave.strength) else 0
					amount = math.floor(amount * 60 + .5) / 60
					local height = .8 + amount * (if family == "Thocky" then 4.2 else 3.1)
					write(bar.part, "Size", Vector3.new(bar.size.X, height, bar.size.Z))
					write(bar.part, "CFrame", bar.frame * CFrame.new(0, (height - bar.size.Y) / 2, 0))
					write(bar.part, "Transparency", if visible then .22 + (1 - math.min(1, amount)) * .36 else 1)
				end
			end
			for _, contact in contacts do
				local level = Effects.SampleContact(readiness, contact.index, started, lapSweepAt)
				level = math.floor(level * 50 + .5) / 50
				write(contact.part, "Color", if readiness.state == "loading" or readiness.state == "degraded" then preparingColor else readyColor)
				write(contact.part, "Transparency", 1 - level * .85)
				write(contact.part, "LocalTransparencyModifier", if (root.Position - contact.part.Position).Magnitude <= visibleRadius then 0 else 1)
			end
			for _, trace in traces do
				if started >= trace.nextAt then
					trace.nextAt, trace.path = started + 5.8, nil
					for _ = 1, 16 do
						trace.cursor = trace.cursor % 16 + 1
						local source = Effects.ResolveTraceSource(candidate, trace.cursor)
						if source and (root.Position - source.Position).Magnitude < visibleRadius then trace.path = trace.cursor; trace.began = started; stats.tracePulses += 1; break end
					end
				end
				local progress = (started - trace.began) / 1.6
				local source = if trace.path and progress >= 0 and progress <= 1 then Effects.ResolveTraceSource(candidate, trace.path) else nil
				if source and progress >= 0 and progress <= 1 and (root.Position - source.Position).Magnitude < visibleRadius then
					write(trace.part, "CFrame", source.CFrame * CFrame.new((progress - .5) * math.max(.1, source.Size.X - .7), .025, 0))
					write(trace.part, "Transparency", .25 + .5 * math.abs(progress - .5) * 2)
				else write(trace.part, "Transparency", 1) end
			end
			stats.updates += 1
			local elapsed = os.clock() - started
			stats.callbackSeconds += elapsed
			stats.maximumCallbackSeconds = math.max(stats.maximumCallbackSeconds, elapsed)
		end
		loop = RunService.Heartbeat:Connect(function(delta)
			local success, problem = xpcall(update, debug.traceback, delta)
			if not success then stop(); warn("[KeyboardCircuit Archive] Effects stopped: " .. tostring(problem)) end
		end)
	end, debug.traceback)
	if not ok then stop(); error(err) end
	running[candidate] = controller
	return controller
end

function Effects.Get(candidate: Model)
	if running[candidate] then return running[candidate] end
	local player = Players.LocalPlayer
	local folder = player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects")
	local identity = if folder then folder:FindFirstChild("Candidate") else nil
	if not folder or not identity or not identity:IsA("ObjectValue") or identity.Value ~= candidate then return nil end
	local diagnostics, stop = folder:FindFirstChild("Diagnostics"), folder:FindFirstChild("StopEffects")
	if not diagnostics or not diagnostics:IsA("BindableFunction") or not stop or not stop:IsA("BindableFunction") then return nil end
	return {Diagnostics = function() return diagnostics:Invoke() end, Stop = function() if folder.Parent then stop:Invoke() end end}
end

return Effects
