--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Http = game:GetService("HttpService")
local Effects = {}
local running = setmetatable({}, {__mode = "k"})

local lightingProfile = {
	Ambient = Color3.fromRGB(88, 103, 112), OutdoorAmbient = Color3.fromRGB(106, 118, 125),
	Brightness = 1.25, ClockTime = 19.2, ExposureCompensation = .1,
	ColorShift_Top = Color3.new(), ColorShift_Bottom = Color3.new(),
	EnvironmentDiffuseScale = .55, EnvironmentSpecularScale = .18,
	FogColor = Color3.fromRGB(29, 43, 48), FogStart = 1000, FogEnd = 100000,
}
local skyProfile = {CelestialBodiesShown = false, StarCount = 0, SunAngularSize = 0, MoonAngularSize = 0}
local readyColor = Color3.fromRGB(156, 222, 191)
local preparingColor = Color3.fromRGB(245, 198, 85)

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
	local environment = assert(candidate:FindFirstChild("MapEnvironment"))
	local anchors = assert(environment:FindFirstChild("ArchiveEffectParts"))
	local originalCharacter = player.Character
	local originalRun = candidate:GetAttribute("KCPhase2RunId")
	local ownershipToken = candidate.Name .. "/" .. tostring(originalRun) .. "/" .. Http:GenerateGUID(false)
	local active, lightingApplied, accumulator = true, false, 0
	local readiness: any = {state = "loading", loaded = 0, total = 8}
	local completed = player:GetAttribute("KCPhase2CompletedLaps") or 0
	local lapSweepAt = -math.huge
	local loop: RBXScriptConnection? = nil
	local entryConnection: RBXScriptConnection? = nil
	local world: Folder? = nil
	local probes: Folder? = nil
	local savedLighting, savedObjects, createdObjects = {}, {}, {}
	local strips, waves, contacts, traces = {}, {}, {}, {}
	local stats = {updates = 0, entries = 0, localEntries = 0, nearbyEntries = 0, lapSweeps = 0, tracePulses = 0, writes = 0,
		callbackSeconds = 0, maximumCallbackSeconds = 0, localPartCount = 0, underlightCount = 0, waveBarCount = 0, depthLayerCount = 0, restoreFailures = 0}
	local quality = UserSettings():GetService("UserGameSettings").SavedQualityLevel.Value
	local economical = quality > 0 and quality <= 3
	local interval, visibleRadius = if economical then 1 / 20 else 1 / 30, if economical then 155 else 210
	local nextVisibilityAt = 0
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
		if world then world:Destroy() end
		if probes then probes:Destroy() end
		if player:GetAttribute("KCArchiveLightingOwner") == ownershipToken then player:SetAttribute("KCArchiveLightingOwner", nil) end
	end
	local function applyLighting()
		assert(player:GetAttribute("KCArchiveLightingOwner") == nil, "Another archive profile still owns Lighting")
		player:SetAttribute("KCArchiveLightingOwner", ownershipToken)
		for name, value in lightingProfile do savedLighting[name] = (Lighting :: any)[name]; (Lighting :: any)[name] = value end
		for _, object in Lighting:GetChildren() do
			if object:IsA("PostEffect") then saveAndSet(object, {Enabled = false}) end
			if object:IsA("Atmosphere") then saveAndSet(object, {Density = 0, Haze = 0, Glare = 0}) end
		end
		local sky = Lighting:FindFirstChildOfClass("Sky")
		if sky then saveAndSet(sky, skyProfile)
		else
			sky = Instance.new("Sky")
			sky.Name = "KeyboardArchiveSky"
			table.insert(createdObjects, sky)
			for name, value in skyProfile do (sky :: any)[name] = value end
			sky.Parent = Lighting
		end
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
	controller = {
		NotifyReady = function(state: any)
			if not active then return end
			readiness = {state = state.state, loaded = state.loaded or 0, total = state.total or 8, reason = state.reason}
			if state.state == "cancelled" or state.state == "stopped" then stop() end
		end,
		Diagnostics = function()
			local result = table.clone(stats)
			result.active, result.lightingApplied, result.ambienceWaiting = active, lightingApplied, active and not lightingApplied
			result.lightingOwnerToken, result.ownsLighting = player:GetAttribute("KCArchiveLightingOwner"), player:GetAttribute("KCArchiveLightingOwner") == ownershipToken
			result.readiness, result.completedLaps, result.finished = table.clone(readiness), completed, player:GetAttribute("KCPhase2Finished") == true
			result.updateConnections, result.entryConnections = if loop then 1 else 0, if entryConnection then 1 else 0
			result.interval, result.quality, result.tracePoolCount = interval, quality, #traces
			result.createdPartCount = stats.localPartCount
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
		world = Instance.new("Folder")
		world.Name, world.Parent = "KeyboardCircuitArchiveVisuals", Workspace
		for _, anchor in anchors.Underlights:GetChildren() do
			if not anchor:IsA("BasePart") then continue end
			table.insert(strips, {part = copyPart(anchor, world :: Folder), frame = anchor.CFrame, transparency = anchor:GetAttribute("ActiveTransparency")})
		end
		stats.underlightCount = #strips
		for _, group in anchors.LandmarkWaves:GetChildren() do
			if not group:IsA("Model") then continue end
			local family = group:GetAttribute("KeyFamily")
			local wave = {at = -math.huge, strength = 0, center = group:GetPivot().Position, radius = group:GetAttribute("ReceiveRadius") or 135, bars = {}, entries = 0, ownEntries = 0, nearbyEntries = 0}
			for _, anchor in group:GetChildren() do
				if not anchor:IsA("BasePart") then continue end
				table.insert(wave.bars, {part = copyPart(anchor, world :: Folder), frame = anchor.CFrame, size = anchor.Size, index = anchor:GetAttribute("BarIndex")})
				stats.waveBarCount += 1
			end
			waves[family] = wave
		end
		for _, anchor in anchors.USBContacts:GetChildren() do
			if anchor:IsA("BasePart") then table.insert(contacts, {part = copyPart(anchor, world :: Folder), index = anchor:GetAttribute("ContactIndex")}) end
		end
		for _, anchor in anchors.InteriorDepth:GetChildren() do
			if not anchor:IsA("BasePart") or economical then continue end
			copyPart(anchor, world :: Folder)
			stats.depthLayerCount += 1
		end
		local paths = {}
		for _, link in anchors.TracePaths:GetChildren() do
			if link:IsA("ObjectValue") and link.Value and link.Value:IsA("BasePart") then table.insert(paths, link.Value) end
		end
		for index = 1, if economical then 2 else 4 do
			local part = Instance.new("Part")
			part.Name, part.Size, part.Material = "LocalTracePulse" .. index, Vector3.new(.7, .13, .7), Enum.Material.Neon
			part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow, part.Transparency = true, false, false, false, false, 1
			part.Color, part.Parent = readyColor, world
			table.insert(traces, {part = part, source = nil, began = -math.huge, nextAt = os.clock() + index * 1.3, cursor = index})
		end
		stats.localPartCount = #world:GetChildren()
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
			if candidate.Parent ~= Workspace or candidate:GetAttribute("KCPhase2RunId") ~= originalRun
				or candidate:GetAttribute("KCPhase2PreviewEnabled") ~= true or player:GetAttribute("KCPhase2Candidate") ~= candidate.Name then stop(); return end
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
			local laps = player:GetAttribute("KCPhase2CompletedLaps")
			if type(laps) == "number" and laps > completed then completed, lapSweepAt = laps, started; stats.lapSweeps += 1 end
			if started >= nextVisibilityAt then
				nextVisibilityAt = started + .2
				local ready, audio = pcall(feedback.Readiness)
				if not ready or (type(audio) == "table" and (audio.state == "stopped" or audio.state == "cancelled")) then
					readiness = {state = "cancelled", reason = if ready then audio.state else "feedback", loaded = 0, total = 8}
					stop()
					return
				end
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
					trace.nextAt, trace.source = started + 5.8, nil
					for offset = 1, #paths do
						trace.cursor = trace.cursor % #paths + 1
						local source = paths[trace.cursor]
						if source:IsDescendantOf(candidate) and (root.Position - source.Position).Magnitude < visibleRadius then trace.source = source; trace.began = started; stats.tracePulses += 1; break end
					end
				end
				local progress = (started - trace.began) / 1.6
				local source = trace.source
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
