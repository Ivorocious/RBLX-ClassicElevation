--!strict
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local Audio = {}

type Voice = {sound: Sound, equalizer: EqualizerSoundEffect, began: number}
type Variation = {speed: number, gain: number}
type FailedClip = {family: string, kind: string, id: string}
type Readiness = {state: string, reason: string?, elapsed: number, timeout: number, loaded: number, total: number, failed: {FailedClip}, retryStarted: boolean, preloadComplete: boolean, error: string?}

function Audio.Start(folder: Folder, config: any)
	assert(RunService:IsClient(), "Key audio belongs to the local client")
	local active = true
	local started = os.clock()
	local readyTimeout = config.AudioReadyTimeout or 10
	assert(type(readyTimeout) == "number" and readyTimeout > 0 and readyTimeout <= 30, "Key audio readiness must resolve within 30 seconds")
	local readiness: Readiness = {state = "loading", elapsed = 0, timeout = readyTimeout, loaded = 0, total = 0, failed = {}, retryStarted = false, preloadComplete = false}
	local readinessConnection: RBXScriptConnection? = nil
	local preloadThread: thread? = nil
	local sources: {[string]: {[string]: Sound}} = {}
	local pools: {[string]: {Voice}} = {}
	local bodyGroups: {[string]: SoundGroup} = {}
	local sounds: {Sound} = {}
	local variations: {[BasePart]: Variation} = setmetatable({}, {__mode = "k"}) :: any
	local counts: {[string]: number} = {}
	local totals: {[string]: number} = {played = 0, unavailable = 0, steals = 0, downSteals = 0, upSteals = 0, nearbySteals = 0}
	local pitchVariation = math.clamp(config.AudioPitchVariation or .02, 0, .04)
	local gainVariation = math.clamp(config.AudioGainVariation or .025, 0, .06)
	local maxVoices = config.OwnPressVoices + config.OwnReleaseVoices + config.NearbyVoices
	local neutralVariation: Variation = {speed = 1, gain = 1}

	for family, info in config.Audio do
		local body = info.body
		if body then
			local group = Instance.new("SoundGroup")
			group.Name = family .. "_KeyBody"
			group.Volume = 1
			group.Parent = folder
			local reverb = Instance.new("ReverbSoundEffect")
			reverb.Name = "KeyBody"
			reverb.Priority = 10
			reverb.DecayTime = math.clamp(body.decay, .1, .18)
			reverb.WetLevel = math.clamp(body.wet, -40, -18)
			reverb.DryLevel = math.clamp(body.dry or -1, -3, 0)
			reverb.Density = math.clamp(body.density or .75, 0, 1)
			reverb.Diffusion = 1
			reverb.Parent = group
			bodyGroups[family] = group
		end
		local pair: {[string]: Sound} = {}
		for kind, id in {down = info.id, up = info.upId} do
			local sound = Instance.new("Sound")
			sound.Name = family .. "_" .. kind
			sound.SoundId = "rbxassetid://" .. id
			sound.Volume = 0
			sound.Parent = folder
			pair[kind] = sound
			table.insert(sounds, sound)
			readiness.total += 1
		end
		sources[family] = pair
	end

	for name, count in {down = config.OwnPressVoices, up = config.OwnReleaseVoices, nearby = config.NearbyVoices} do
		assert(count >= 1 and count <= 8 and count % 1 == 0, "Key audio pools must have 1 to 8 voices")
		local pool: {Voice} = {}
		for index = 1, count do
			local sound = Instance.new("Sound")
			sound.Name = name .. index
			sound.Parent = folder
			local equalizer = Instance.new("EqualizerSoundEffect")
			equalizer.Priority = 20
			equalizer.Parent = sound
			table.insert(pool, {sound = sound, equalizer = equalizer, began = 0})
			table.insert(sounds, sound)
		end
		pools[name] = pool
	end

	local function cancelPreload()
		local threadToCancel = preloadThread
		preloadThread = nil
		if threadToCancel and threadToCancel ~= coroutine.running() then
			pcall(task.cancel, threadToCancel)
		end
	end

	local function refreshReadiness()
		if not active or readiness.state ~= "loading" then return end
		readiness.elapsed = os.clock() - started
		local failed: {FailedClip} = {}
		for family, pair in sources do
			for kind, sound in pair do
				if not sound.IsLoaded or sound.TimeLength <= 0 then
					table.insert(failed, {family = family, kind = kind, id = sound.SoundId})
				end
			end
		end
		table.sort(failed, function(a, b) return a.family < b.family or (a.family == b.family and a.kind < b.kind) end)
		readiness.failed = failed
		readiness.loaded = readiness.total - #failed
		if not folder.Parent then
			readiness.state, readiness.reason = "stopped", "removed"
		elseif readiness.elapsed >= readyTimeout then
			readiness.state, readiness.reason = "degraded", "deadline"
		elseif #failed == 0 then
			readiness.preloadComplete = true
			readiness.state, readiness.reason = "ready", "loaded"
		elseif readiness.preloadComplete then
			readiness.state, readiness.reason = "degraded", "failed"
		end
		if readiness.state ~= "loading" then
			if readinessConnection then readinessConnection:Disconnect(); readinessConnection = nil end
			cancelPreload()
		end
	end

	local function readinessSnapshot(): Readiness
		refreshReadiness()
		local result = table.clone(readiness)
		result.failed = {}
		for _, clip in readiness.failed do table.insert(result.failed, table.clone(clip)) end
		return result
	end

	local function canPreload(): boolean
		refreshReadiness()
		return active and folder.Parent ~= nil and readiness.state == "loading"
	end

	readinessConnection = RunService.Heartbeat:Connect(refreshReadiness)
	preloadThread = task.defer(function()
		if not canPreload() then return end
		local function preload(list: {Instance}): boolean
			local ok, err = pcall(function() ContentProvider:PreloadAsync(list) end)
			if not active or not folder.Parent or readiness.state ~= "loading" then return false end
			if not ok then
				readiness.error = tostring(err)
				warn("[KeyboardCircuit Audio] " .. tostring(err))
			end
			return canPreload()
		end
		local list: {Instance} = {}
		for _, pair in sources do
			for _, sound in pair do table.insert(list, sound) end
		end
		if not preload(list) then return end
		local retry: {Instance} = {}
		for family, pair in sources do
			for kind, sound in pair do
				if not sound.IsLoaded or sound.TimeLength <= 0 then
					local info = config.Audio[family]
					sound.SoundId = "https://www.roblox.com/asset/?id=" .. (if kind == "up" then info.upId else info.id)
					table.insert(retry, sound)
				end
			end
		end
		if #retry > 0 then
			readiness.retryStarted = true
			if not preload(retry) then return end
		end
		readiness.preloadComplete = true
		refreshReadiness()
	end)

	local function variationFor(key: BasePart?): Variation
		if not key then return neutralVariation end
		local cached = variations[key]
		if cached then return cached end
		local name = (if key.Parent then key.Parent.Name else "") .. "/" .. key.Name
		local hash = 0
		for index = 1, #name do hash = (hash * 31 + string.byte(name, index)) % 65521 end
		local variation = {
			speed = 1 + ((hash % 5) / 2 - 1) * pitchVariation,
			gain = 1 - (math.floor(hash / 5) % 5) / 4 * gainVariation,
		}
		variations[key] = variation
		return variation
	end

	local function play(family: string, kind: string, volume: number, nearby: boolean?, key: BasePart?): boolean
		if not active or not folder.Parent then return false end
		local pair, info = sources[family], config.Audio[family]
		local source = if pair then pair[kind] else nil
		if not source or not source.IsLoaded then totals.unavailable += 1; return false end
		local poolName = if nearby then "nearby" else kind
		local pool = pools[poolName]
		if not pool then return false end
		local chosen = pool[1]
		for _, voice in pool do
			if not voice.sound.IsPlaying then chosen = voice; break end
			if voice.began < chosen.began then chosen = voice end
		end
		if chosen.sound.IsPlaying then
			chosen.sound:Stop()
			totals.steals += 1
			local metric = if nearby then "nearbySteals" else kind .. "Steals"
			totals[metric] += 1
		end
		local variation = variationFor(key)
		local speed = if kind == "up" then (info.upSpeed or info.speed or 1) else (info.speed or 1)
		chosen.began = os.clock()
		chosen.sound.SoundId = source.SoundId
		chosen.sound.Volume = volume * (if kind == "up" then info.upGain else info.gain) * variation.gain
		chosen.sound.PlaybackSpeed = speed * variation.speed
		chosen.sound.PlaybackRegionsEnabled = true
		chosen.sound.PlaybackRegion = if kind == "up" then info.upRegion else info.downRegion
		chosen.equalizer.LowGain = if kind == "up" then (info.upLow or info.low) else info.low
		chosen.equalizer.MidGain = if kind == "up" then (info.upMid or info.mid) else info.mid
		chosen.equalizer.HighGain = if kind == "up" then (info.upHigh or info.high) else info.high
		chosen.sound.SoundGroup = if kind == "down" and not nearby then bodyGroups[family] else nil
		chosen.sound:Play()
		totals.played += 1
		local countKey = family .. "_" .. kind
		counts[countKey] = (counts[countKey] or 0) + 1
		return true
	end

	return {
		Play = play,
		Readiness = readinessSnapshot,
		IsResolved = function(): boolean
			refreshReadiness()
			return readiness.state == "ready" or readiness.state == "degraded"
		end,
		AwaitReady = function(cancelled: (() -> boolean)?): Readiness
			while true do
				local result = readinessSnapshot()
				if result.state ~= "loading" then return result end
				if cancelled and cancelled() then
					result = readinessSnapshot()
					if result.state == "stopped" then return result end
					result.state, result.reason = "cancelled", "cancelled"
					return result
				end
				task.wait(math.min(.05, math.max(readyTimeout - result.elapsed, 0)))
			end
		end,
		Audition = function(family: string)
			if not play(family, "down", config.OwnVolume) then return end
			task.delay(config.AuditionReleaseDelay or .16, function()
				if active and folder.Parent then play(family, "up", config.ReleaseVolume) end
			end)
		end,
		Diagnostics = function()
			local result: any = {plays = table.clone(counts), totals = table.clone(totals), audio = {}, body = {}, maxVoices = maxVoices, readiness = readinessSnapshot()}
			for family, pair in sources do
				result.audio[family] = {}
				for kind, sound in pair do
					result.audio[family][kind] = {loaded = sound.IsLoaded, duration = sound.TimeLength, id = sound.SoundId}
				end
			end
			for family, group in bodyGroups do
				local reverb = group:FindFirstChild("KeyBody") :: ReverbSoundEffect
				result.body[family] = {decay = reverb.DecayTime, wet = reverb.WetLevel, dry = reverb.DryLevel, density = reverb.Density, diffusion = reverb.Diffusion}
			end
			return result
		end,
		Stop = function()
			if not active then return end
			refreshReadiness()
			active = false
			readiness.state, readiness.reason = "stopped", "stopped"
			if readinessConnection then readinessConnection:Disconnect(); readinessConnection = nil end
			cancelPreload()
			for _, sound in sounds do sound:Destroy() end
			for _, group in bodyGroups do group:Destroy() end
			table.clear(sounds)
			table.clear(sources)
			table.clear(pools)
			table.clear(bodyGroups)
			table.clear(variations)
		end,
	}
end

return Audio
