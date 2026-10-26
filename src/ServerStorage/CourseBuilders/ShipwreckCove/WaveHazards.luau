--!strict
-- Layout.surges uses CourseOrigin-local center/floor and one bounds part per visual zone.
-- Each Decoration zone contains reusable SurgeWater, SurgeFoam, and SurgeWave BaseParts.
local Config = require(game.ReplicatedStorage.Config.ShipwreckConfig)
local Geometry = require(game.ReplicatedStorage.Shared.ShipwreckHazards)
local WaveHazards = {}

local function vector(point)
	return Vector3.new(point[1], point[2], point[3])
end

local function findPart(parent, name)
	local candidate = parent and parent:FindFirstChild(name)
	return if candidate and candidate:IsA("BasePart") then candidate else nil
end

local function activeTransparency(part, fallback)
	local value = part:GetAttribute("ActiveTransparency")
	return if type(value) == "number" then math.clamp(value, 0, 1) else fallback
end

local function playSound(parent, name, soundId, volume)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Volume = volume
	sound.RollOffMinDistance = 8
	sound.RollOffMaxDistance = 90
	sound.Parent = parent
	return sound
end

local function setAttributeIfChanged(part, name, value)
	if part:GetAttribute(name) ~= value then
		part:SetAttribute(name, value)
	end
end

function WaveHazards.Create(course, definitions)
	local obstacleBounds = course.Obstacles:FindFirstChild("ShipwreckHazards")
	local zones = {}
	local sounds = {}

	for _, data in definitions or {} do
		local decoration = course.Decoration:FindFirstChild(data.name)
		local bounds = findPart(obstacleBounds, data.name .. "Bounds")
		local water = findPart(decoration, "SurgeWater")
		local foam = findPart(decoration, "SurgeFoam")
		local wave = findPart(decoration, "SurgeWave")
		if not decoration or not bounds or not water or not foam or not wave then
			warn("Disabled Shipwreck surge " .. data.name .. ": a required visible or bounds part is missing")
			continue
		end
		local localRotations = {
			water = bounds.CFrame:ToObjectSpace(water.CFrame).Rotation,
			foam = bounds.CFrame:ToObjectSpace(foam.CFrame).Rotation,
			wave = bounds.CFrame:ToObjectSpace(wave.CFrame).Rotation,
		}
		local zone = {
			data = data,
			bounds = bounds,
			water = water,
			foam = foam,
			wave = wave,
			width = bounds.Size.X,
			depth = bounds.Size.Z,
			halfDepth = bounds.Size.Z * 0.5,
			floorOffset = data.floor - data.center[2],
			waterBottomOffset = Config.TideWaterBottom - data.center[2],
			localRotations = localRotations,
			activeTransparencies = {
				water = activeTransparency(water, Config.TideWaterActiveTransparency or 0),
				foam = activeTransparency(foam, Config.TideFoamActiveTransparency or 0),
				wave = activeTransparency(wave, Config.TideWaveActiveTransparency or 0),
			},
			originals = {
				water = {CFrame = water.CFrame, Size = water.Size, Transparency = water.Transparency},
				foam = {CFrame = foam.CFrame, Size = foam.Size, Transparency = foam.Transparency},
				wave = {CFrame = wave.CFrame, Size = wave.Size, Transparency = wave.Transparency},
			},
			originalAttributes = {
				Phase = bounds:GetAttribute("Phase"),
				WaveNumber = bounds:GetAttribute("WaveNumber"),
				WavePhase = bounds:GetAttribute("WavePhase"),
			},
			lastPhase = "",
			lastVisibleWaveCFrame = nil,
			disabled = false,
		}
		zone.warningSound = playSound(foam, "TideWarning", Config.Audio.TideWarning, 0.45)
		zone.surgeSound = playSound(foam, "TideSurge", Config.Audio.TideSurge, 0.5)
		table.insert(sounds, zone.warningSound)
		table.insert(sounds, zone.surgeSound)
		table.insert(zones, zone)
	end

	local controller = {}
	local function restoreVisuals(zone)
		for name, part in {water = zone.water, foam = zone.foam, wave = zone.wave} do
			local original = zone.originals[name]
			if part.Parent then
				part.CFrame = original.CFrame
				part.Size = original.Size
				part.Transparency = original.Transparency
			end
		end
	end
	local function hideVisuals(zone)
		restoreVisuals(zone)
		for _, part in {zone.water, zone.foam, zone.wave} do
			if part.Parent then
				part.Transparency = 1
			end
		end
	end

	local function setPhase(zone, phase)
		local waveNumber = if phase == "Surge" then 1 else 0
		setAttributeIfChanged(zone.bounds, "Phase", phase)
		setAttributeIfChanged(zone.bounds, "WaveNumber", waveNumber)
		setAttributeIfChanged(zone.bounds, "WavePhase", phase)
	end

	function controller.Step(t, dt, active, updateVisuals, contact)
		for _, zone in zones do
			if not zone.bounds.Parent or not zone.water.Parent or not zone.foam.Parent or not zone.wave.Parent then
				if not zone.disabled then
					warn("Disabled Shipwreck surge " .. zone.data.name .. ": a required part was removed")
					zone.disabled = true
				end
				for _, part in {zone.water, zone.foam, zone.wave} do
					if part.Parent then part.Transparency = 1 end
				end
				zone.warningSound:Stop()
				zone.surgeSound:Stop()
				continue
			end
			local data = zone.data
			local cycleTime = (t - (data.phase or 0)) % Config.TideCycle
			local phase, amount = Geometry.TidePhase(t - (data.phase or 0), Config)
			local surgeStart = Config.TideDry + Config.TideWarning
			local surgeProgress = math.clamp((cycleTime - surgeStart) / Config.TideActive, 0, 1)
			local drainProgress = if phase == "Drain" then 1 - amount else 0
			local frontZ = zone.halfDepth
			local waterHeight = 0
			local waterDepth = 0
			local showWave = false
			local showFoam = false

			if phase == "Warning" then
				-- Keep the audible warning while the visual surge remains hidden.
			elseif phase == "Surge" then
				frontZ = zone.halfDepth - zone.depth * surgeProgress
				waterHeight = Config.TideWaterHeight
				waterDepth = math.clamp(zone.halfDepth - frontZ, 0, zone.depth)
				showWave = surgeProgress < 1
				showFoam = showWave
			elseif phase == "Drain" then
				frontZ = -zone.halfDepth + zone.depth * drainProgress
				waterHeight = Config.TideWaterHeight * (1 - drainProgress)
				waterDepth = math.clamp(zone.halfDepth - frontZ, 0, zone.depth)
				showFoam = waterDepth > 0.1
			end

			if phase ~= zone.lastPhase and active then
				if phase == "Warning" then
					zone.warningSound:Play()
				elseif phase == "Surge" then
					zone.surgeSound:Play()
				end
			end
			zone.lastPhase = phase
			setPhase(zone, phase)

			if updateVisuals then
				if phase == "Dry" then
					hideVisuals(zone)
				else
					local waterHeightVisible = math.max(0.05, waterHeight)
					local waterDepthVisible = math.max(0.05, waterDepth)
					local waterCenterZ = frontZ + waterDepthVisible * 0.5
					zone.water.Size = Vector3.new(zone.width, waterHeightVisible, waterDepthVisible)
					zone.water.CFrame = zone.bounds.CFrame
						* CFrame.new(0, zone.waterBottomOffset + waterHeightVisible * 0.5, waterCenterZ)
						* zone.localRotations.water
					zone.water.Transparency = if waterDepth > 0 then zone.activeTransparencies.water else 1

					local foamOriginal = zone.originals.foam
					local crestHeight = Config.TideCrestHeight
					local crestDepth = math.min(Config.TideCrestDepth, zone.depth)
					zone.foam.Size = Vector3.new(zone.width, foamOriginal.Size.Y, foamOriginal.Size.Z)
					zone.foam.CFrame = zone.bounds.CFrame
						* CFrame.new(0, zone.floorOffset + crestHeight - foamOriginal.Size.Y * 0.5, frontZ)
						* zone.localRotations.foam
					zone.foam.Transparency = if showFoam then zone.activeTransparencies.foam else 1

					zone.wave.Size = Vector3.new(zone.width, crestHeight, crestDepth)
					zone.wave.CFrame = zone.bounds.CFrame
						* CFrame.new(0, zone.floorOffset + crestHeight * 0.5, frontZ)
						* zone.localRotations.wave
					zone.wave.Transparency = if showWave then zone.activeTransparencies.wave else 1
				end
			end

			if active and dt <= 0.5 and (phase == "Surge" or phase == "Drain") then
				if zone.water.Transparency < 1 then
					contact(zone.water.CFrame, zone.water.Size, "H02 Tide surge")
				end
				if phase == "Surge" and showWave and zone.wave.Transparency < 1 then
					local previousCFrame = zone.lastVisibleWaveCFrame or zone.wave.CFrame
					contact(zone.wave.CFrame, zone.wave.Size, "H02 Tide surge", previousCFrame)
				end
			end
			if active and phase == "Surge" and zone.wave.Transparency < 1 then
				zone.lastVisibleWaveCFrame = zone.wave.CFrame
			else
				zone.lastVisibleWaveCFrame = nil
			end
		end
	end

	function controller.Reset()
		for _, zone in zones do
			hideVisuals(zone)
			zone.warningSound:Stop()
			zone.surgeSound:Stop()
			zone.lastPhase = ""
			zone.lastVisibleWaveCFrame = nil
			if zone.bounds.Parent then setPhase(zone, "Dry") end
		end
	end
	function controller.Stop()
		for _, zone in zones do
			restoreVisuals(zone)
			for name, value in zone.originalAttributes do
				if zone.bounds.Parent then zone.bounds:SetAttribute(name, value) end
			end
		end
		for _, sound in sounds do
			sound:Destroy()
		end
	end
	return controller
end

return WaveHazards
