--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Tuning = require(ReplicatedStorage.Config.CityRunTuning)
local Audio = require(ReplicatedStorage.Config.CityRunAudio)
local Conveyors = require(script.Parent.Conveyors)
local Runtime = {}

local function vec(p): Vector3
	return Vector3.new(p[1], p[2], p[3])
end

local function visible(record, show: boolean)
	if record.visible == show then return end
	record.visible = show
	for _, item in record.model:GetDescendants() do
		if item:IsA("BasePart") then item.Transparency = if show then 0 else 1 end
	end
end

local function soundPlaying(sound: Sound, playing: boolean)
	if playing and not sound.IsPlaying and sound.SoundId ~= "" then sound:Play()
	elseif not playing and sound.IsPlaying then sound:Stop() end
end

function Runtime.Create(model: Model, recoverPlayer, isRacer)
	local conveyors = Conveyors.Create(model)
 local moving = model.Obstacles.Moving
	local origin = model:GetPivot()
	local cars = {}
	for i = 0, 2 do
		local car = moving:FindFirstChild("Car" .. i)
		assert(car and car:IsA("Model"), "Missing City Run car " .. i)
		local boundsCFrame, boundsSize = car:GetBoundingBox()
        cars[i + 1] = { model = car, visible = true, previous = nil, spawnedAt = nil,
            collisionSize = boundsSize, collisionOffset = car:GetPivot():PointToObjectSpace(boundsCFrame.Position) }
		visible(cars[i + 1], false)
	end
	local train = { model = Instance.new("Model"), visible = true, previous = nil }
	train.model.Name, train.model.WorldPivot, train.model.Parent = "TrainAssembly", moving.ActiveTrain2:GetPivot(), moving
	for i = 0, 4 do
		local coach = moving:FindFirstChild("ActiveTrain" .. i)
		assert(coach and coach:IsA("Model"), "Missing active train coach")
		coach.Parent = train.model
	end
	visible(train, false)
	local ballRecords = {}
	for _, definition in Tuning.hazards.balls do
		local ball, cable = moving:FindFirstChild(definition.name), moving:FindFirstChild(definition.name .. "Cable")
		assert(ball and cable, "Missing suspended hazard")
		table.insert(ballRecords, { model = ball, cable = cable, definition = definition, previousAngle = nil })
	end
	local barrier = moving.TrainBarrier
	local exitBarrier = moving.TrainBarrierExit
	local barrierClosed, exitBarrierClosed = barrier:GetPivot(), exitBarrier:GetPivot()
	local gate = model.Obstacles.TrainEntryGate
	local gantry = model.Decoration:FindFirstChild("SignalGantry")
	local redLights = {}
	if gantry then
		for _, item in gantry:GetDescendants() do
			if item:IsA("BasePart") and string.find(item.Name, "__Red__", 1, true) then table.insert(redLights, item) end
		end
	end
	local crossingEquipment = model.Decoration:FindFirstChild("C11Depot")
	local lamps = crossingEquipment and crossingEquipment:FindFirstChild("Depot_CrossingEquipment")
	if lamps then
		for _, item in lamps:GetDescendants() do
			if item:IsA("BasePart") and string.find(item.Name, "__Red__", 1, true) then table.insert(redLights, item) end
		end
	end
	local sounds = {}
	for name, id in Audio do
		local emitter = model.Obstacles.Audio:FindFirstChild(name)
		if not emitter and (name == "TrainRumble" or name == "TrainHorn") then
			emitter = model.Obstacles.Audio.CrossingBell:Clone()
			emitter.Name, emitter.Parent = name, model.Obstacles.Audio
		end
		if not emitter and name == "TrafficTires" then
            emitter = model.Obstacles.Audio.TrafficEngine:Clone()
            emitter.Name, emitter.Parent = name, model.Obstacles.Audio
        end
        local sound = emitter and emitter:FindFirstChildOfClass("Sound")
		assert(sound, "Missing audio emitter")
		sound.SoundId = id
		sounds[name] = sound
        if name == "TrafficEngine" or name == "TrafficTires" then
            sound.Looped = true
            sound.Volume = if name == "TrafficEngine" then .9 else .42
            sound.RollOffMinDistance = 12
            sound.RollOffMaxDistance = 135
        end
		if name == "TrainRumble" or name == "TrainHorn" then
			sound.Volume = if name == "TrainHorn" then 1.4 else 1.1
			sound.RollOffMinDistance = if name == "TrainHorn" then 90 else 24
			sound.RollOffMaxDistance = if name == "TrainHorn" then 650 else 240
			sound.Looped = name == "TrainRumble"
		end
	end
	local nextSpawn, spawnIndex = 0, 0
	local lastGround = {}
	local characterOverlap = OverlapParams.new()
	characterOverlap.FilterType = Enum.RaycastFilterType.Include
	local groundRay = RaycastParams.new()
	groundRay.FilterType = Enum.RaycastFilterType.Include
	groundRay.FilterDescendantsInstances = {
		model.Obstacles.WalkingSurfaces,
		model.Obstacles:FindFirstChild("C14Routes"),
		model.Obstacles:FindFirstChild("C15Routes"),
	}
	groundRay.RespectCanCollide = true
	local lastTime = 0
	local hornCycle = -1
	local controller = {}

	local function recoverFromPart(item: BasePart, label: string)
		local character = item:FindFirstAncestorWhichIsA("Model")
		if not character or item.Parent ~= character or item.Name == "HumanoidRootPart" or item.Transparency >= 1 then return end
		local player = character and Players:GetPlayerFromCharacter(character)
		if not player or not isRacer(player) then return end
		if (character:GetAttribute("RecoveryUntil") or 0) > Workspace:GetServerTimeNow() then return end
		if recoverPlayer(player, label) then lastGround[player] = nil end
	end

	local function sweepBox(a: Vector3?, b: Vector3, size: Vector3, overlap: OverlapParams, label: string)
		local start = a or b
		local midpoint = (start + b) / 2
		local sweptSize = size + Vector3.new(math.abs(b.X-start.X), math.abs(b.Y-start.Y), math.abs(b.Z-start.Z))
		for _, item in Workspace:GetPartBoundsInBox(origin * CFrame.new(midpoint), sweptSize, overlap) do
			recoverFromPart(item, label)
		end
	end

	local function sphereContacts(center: Vector3, radius: number, overlap: OverlapParams)
		local world = origin:PointToWorldSpace(center)
		for _, item in Workspace:GetPartBoundsInRadius(world, radius, overlap) do
			local p = item.CFrame:PointToObjectSpace(world)
			local h = item.Size / 2
			local closest = Vector3.new(math.clamp(p.X,-h.X,h.X), math.clamp(p.Y,-h.Y,h.Y), math.clamp(p.Z,-h.Z,h.Z))
			if (p-closest).Magnitude <= radius then recoverFromPart(item, "CityRunWreckingBall") end
		end
	end

	function controller.Step(elapsed: number, damageEnabled: boolean)
  conveyors.Step(elapsed)
		assert(elapsed >= lastTime, "City Run timeline must move forward")
		lastTime = elapsed
		local characters: {Model} = {}
		local racers: {[Player]: boolean} = {}
		local players: {Player} = {}
		local overlap: OverlapParams? = nil
		if damageEnabled then
			players = Players:GetPlayers()
			for _, player in players do
				local racer = isRacer(player)
				local character = player.Character
				racers[player] = racer
				if racer and character then table.insert(characters, character) end
			end
			if #characters > 0 then
				characterOverlap.FilterDescendantsInstances = characters
				overlap = characterOverlap
			end
		end
		local traffic = Tuning.hazards.cars
		while nextSpawn <= elapsed do
			local record = cars[spawnIndex % #cars + 1]
			record.spawnedAt, record.previous = nextSpawn, nil
			nextSpawn += traffic.intervals[spawnIndex % #traffic.intervals + 1]
			spawnIndex += 1
		end
		local nearestCar, nearestDistance = nil, math.huge
		for _, record in cars do
			local age = if record.spawnedAt then elapsed - record.spawnedAt else -1
			local active = age >= 0 and age <= (traffic.endX-traffic.startX)/traffic.speed
			visible(record, active)
			if active then
				local position = Vector3.new(traffic.startX+age*traffic.speed, traffic.crossing[2]+3, traffic.crossing[3])
				record.model:PivotTo(origin * CFrame.new(position))
				if overlap then sweepBox(record.previous, position+record.collisionOffset, record.collisionSize, overlap, "CityRunTraffic") end
				record.previous = position+record.collisionOffset
				local distance = math.abs(position.X-traffic.crossing[1])
				if distance < nearestDistance then nearestCar, nearestDistance = position, distance end
			else record.previous = nil end
		end
		if nearestCar then
            sounds.TrafficEngine.Parent.CFrame = origin * CFrame.new(nearestCar)
            sounds.TrafficTires.Parent.CFrame = origin * CFrame.new(nearestCar)
			local playbackSpeed = if nearestCar.X < traffic.crossing[1] then 1.06 else .92
			if sounds.TrafficEngine.PlaybackSpeed ~= playbackSpeed then sounds.TrafficEngine.PlaybackSpeed = playbackSpeed end
        end
		soundPlaying(sounds.TrafficEngine, nearestDistance < 120)
        soundPlaying(sounds.TrafficTires, nearestDistance < 100)

		for _, record in ballRecords do
			local d = record.definition
			local angle = math.sin(elapsed * math.pi * 2 / d.period + d.phase) * d.amplitude
			local pivot = origin * CFrame.new(vec(d.pivot))
			local arm = pivot * CFrame.Angles(angle, 0, 0)
			record.model:PivotTo(arm * CFrame.new(0, -d.length, 0))
			record.cable:PivotTo(arm)
			if overlap then
				local previous = record.previousAngle or angle
				local steps = math.max(1, math.ceil(math.abs(angle-previous)*d.length/.75))
				for i = 1, steps do
					local a = previous+(angle-previous)*i/steps
					local center = vec(d.pivot)+Vector3.new(0,-d.length*math.cos(a),-d.length*math.sin(a))
					sphereContacts(center, d.radius, overlap)
				end
			end
			record.previousAngle = angle
		end
		soundPlaying(sounds.SwingAir, true)

		local rail = Tuning.hazards.train
		local duration = (rail.endX-rail.startX)/rail.speed
		local cycle = math.floor(elapsed / (rail.openTime+duration))
		local phase = elapsed % (rail.openTime+duration) - rail.openTime
		local active = phase >= 0
		visible(train, active)
		local x = rail.startX+math.max(0,phase)*rail.speed
		local cleared = x-rail.size[1]/2 > rail.crossing[1]+6
		if gate.CanCollide then gate.CanCollide = false end
		local lowering = if active and not cleared then math.clamp((phase-(rail.warningTime-.4))/.4,0,1) else 0
		local barrierCFrame = barrierClosed * CFrame.Angles(0, 0, math.rad(82)*(1-lowering))
		local exitBarrierCFrame = exitBarrierClosed * CFrame.Angles(0, 0, -math.rad(82)*(1-lowering))
		if barrier:GetPivot() ~= barrierCFrame then barrier:PivotTo(barrierCFrame) end
		if exitBarrier:GetPivot() ~= exitBarrierCFrame then exitBarrier:PivotTo(exitBarrierCFrame) end
		local warning = active and not cleared
		local trainPhase = if not warning then "Open" elseif phase < rail.warningTime then "EarlyWarning" elseif x+rail.size[1]/2 < rail.crossing[1]-6 then "Clearance" else "Passing"
		if model:GetAttribute("TrainPhase") ~= trainPhase then model:SetAttribute("TrainPhase", trainPhase) end
		local lampTransparency = if warning and math.floor(elapsed*4)%2==0 then 0 else .7
		for _, lamp in redLights do
			if lamp.Transparency ~= lampTransparency then lamp.Transparency = lampTransparency end
		end
		soundPlaying(sounds.CrossingBell, warning)
		if warning and hornCycle ~= cycle then
			hornCycle = cycle
			sounds.TrainHorn.TimePosition = 0
			sounds.TrainHorn:Play()
		end
		local noseX = x + rail.size[1]/2
		local tailX = x - rail.size[1]/2
		local nearestX = math.clamp(rail.crossing[1], tailX, noseX)
		sounds.TrainRumble.Parent.CFrame = origin * CFrame.new(nearestX, rail.bodyCenterY, -12)
		sounds.TrainHorn.Parent.CFrame = origin * CFrame.new(noseX, rail.bodyCenterY+3, -12)
		soundPlaying(sounds.TrainRumble, active)
		if not active then soundPlaying(sounds.TrainHorn, false) end
		if active then
			train.model:PivotTo(origin * CFrame.new(x,89,-12))
			local position = Vector3.new(x,rail.bodyCenterY,-12)
			if overlap then sweepBox(train.previous, position, vec(rail.size), overlap, "CityRunTrain") end
			train.previous = position
		else train.previous = nil end

		if overlap then
			for _, player in players do
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if not root or not racers[player] then lastGround[player] = nil; continue end
				local ground = Workspace:Raycast(root.Position, Vector3.new(0,-6,0), groundRay)
				if ground then lastGround[player] = ground.Position.Y
				elseif lastGround[player] and root.Position.Y < lastGround[player]-12 then
					if recoverPlayer(player,"CityRunFall") then lastGround[player] = nil end
				end
			end
		end
	end

	function controller.Stop()
  conveyors.Stop()
		for _, sound in sounds do soundPlaying(sound, false) end
	end

	return controller
end

return Runtime
