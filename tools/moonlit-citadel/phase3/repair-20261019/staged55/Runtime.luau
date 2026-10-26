--!nonstrict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Config = require(ReplicatedStorage.Config.MoonlitCitadelCourseConfig)

local Coverage = require(script.Parent.Coverage)
local Runtime = {}
local activeRoots = setmetatable({}, { __mode = "k" })
local BODY_NAMES = {
	Head = true, UpperTorso = true, LowerTorso = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
	RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
	RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
	Torso = true, ["Left Arm"] = true, ["Right Arm"] = true,
	["Left Leg"] = true, ["Right Leg"] = true,
}
local CAR_SOUND = "rbxassetid://78959704238630"
local LANTERN_SOUND = "rbxassetid://89163507250478"

local function numberAttribute(instance, name, fallback)
	local value = instance:GetAttribute(name)
	assert(value == nil or (typeof(value) == "number" and value == value and math.abs(value) < math.huge), name .. " must be finite")
	return if value == nil then fallback else value
end

local function characterParts(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then return nil end
	return character, humanoid, root
end

local function carProgress(elapsed, record)
	local t = math.max(0, elapsed - record.offset) % record.cycle
	local travelTime = (record.cycle - 2 * record.dwell) / 2
	if t < record.dwell then return 0, "LowDwell", record.dwell - t + math.max(0, record.offset - elapsed) end
	if t < record.dwell + travelTime then return (t - record.dwell) / travelTime, "Rising", record.dwell + travelTime - t end
	if t < record.dwell * 2 + travelTime then return 1, "HighDwell", record.dwell * 2 + travelTime - t end
	return 1 - (t - record.dwell * 2 - travelTime) / travelTime, "Descending", record.cycle - t
end

local function setAttributeChanged(instance, name, value)
	if instance:GetAttribute(name) ~= value then instance:SetAttribute(name, value) end
end

local function validateAnchored(model, primaryName)
	assert(model:IsA("Model") and model.PrimaryPart and model.PrimaryPart.Name == primaryName, model.Name .. " needs " .. primaryName .. " PrimaryPart")
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then assert(part.Anchored, model.Name .. " must be anchored") end
	end
	return model.PrimaryPart
end

local function bodyParts(character)
	local parts = {}
	for _, part in character:GetChildren() do
		if part:IsA("BasePart") and BODY_NAMES[part.Name] then table.insert(parts, part) end
	end
	return parts
end

local function carryBounds(racer)
	-- The physical body and root define clearance; accessory handles never enlarge it.
	local minimum, maximum = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	local function include(part)
		for _, x in { -1, 1 } do
			for _, y in { -1, 1 } do
				for _, z in { -1, 1 } do
					local point = racer.root.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2))
					minimum = Vector3.new(math.min(minimum.X, point.X), math.min(minimum.Y, point.Y), math.min(minimum.Z, point.Z))
					maximum = Vector3.new(math.max(maximum.X, point.X), math.max(maximum.Y, point.Y), math.max(maximum.Z, point.Z))
				end
			end
		end
	end
	include(racer.root)
	for _, part in racer.body do if part.CanCollide then include(part) end end
	local size = maximum - minimum
	return racer.root.CFrame * CFrame.new((minimum + maximum) / 2), Vector3.new(math.max(.05, size.X - .04), math.max(.05, size.Y - .04), math.max(.05, size.Z - .04))
end

local function possibleBodyContact(center, radius, racers)
	for _, racer in racers do
		if racer.visibleRadius >= 0 then
			local difference = racer.root.Position - center
			local combinedRadius = radius + racer.visibleRadius + .02
			if difference:Dot(difference) <= combinedRadius * combinedRadius then return true end
		end
	end
	return false
end

local function insideDeckCircle(position, deckPosition, radius)
	local x, z = position.X - deckPosition.X, position.Z - deckPosition.Z
	return x * x + z * z <= (radius + .001) * (radius + .001)
end

function Runtime.Start(course: Model, isEligible, recover)
	assert(RunService:IsServer(), "Moonlit runtime is server only")
	assert(course:IsDescendantOf(Workspace) and course:GetAttribute("CourseId") == "moonlit_citadel" and course:GetAttribute("MoonlitCourse") == true, "Active Moonlit course required")
	assert(not activeRoots[course], "Moonlit runtime already bound")
	local cars, lanterns, hazards, sounds, connections = {}, {}, {}, {}, {}
	local hazardBounds = {}
	local profiles, originalAttributes = {}, {}
	local elapsed, stopped, redAccumulator = 0, false, 0
	local stats = {
		frames = 0, cpuSeconds = 0, cpuMaxMs = 0, supportChecks = 0, groundedRiders = 0,
		carryProbes = 0, blockedCarries = 0, carriedSteps = 0, hazardProbes = 0,
		hazardHits = 0, recoveries = 0, recoveryRejected = 0, maxLanternSweepSteps = 0,
		characterFiltersBuilt = 0, maximumExcludedCharacters = 0,
		bodyRadiusBuilds = 0, skippedRedBroad = 0, skippedLanternBroad = 0,
		skippedSupportChecks = 0,
	}
	local lastBlocker = nil
	local supportedR15, unsupportedRigs = 0, {}
	local controller = {}
	local function rememberAttributes(instance, names)
		local originals = {}
		for _, name in names do originals[name] = { value = instance:GetAttribute(name) } end
		originalAttributes[instance] = originals
	end
	for _, instance in course:GetDescendants() do
		if instance:IsA("Folder") and instance.Name == "MovingCars" then
			for _, model in instance:GetChildren() do
				if not model:IsA("Model") then continue end
				local deck = validateAnchored(model, "Deck")
				local travel = model:GetAttribute("Travel")
				assert(typeof(travel) == "Vector3" and travel.X == 0 and travel.Z == 0 and travel.Y > 0, model.Name .. " needs vertical Travel")
				assert(deck.CanCollide and deck.CanQuery and deck.CFrame.UpVector:Dot(Vector3.yAxis) > .999, model.Name .. " needs a level colliding Deck")
				local cycle, dwell = numberAttribute(model, "CycleSeconds", 14), numberAttribute(model, "DwellSeconds", 2)
				assert(dwell >= 0 and cycle > 2 * dwell, "Lift cycle needs travel time")
				local reference = model:FindFirstChild("Counterweight")
				local weight = reference and reference:IsA("ObjectValue") and reference.Value
				assert(weight and weight:IsA("Model") and weight.PrimaryPart and weight:IsDescendantOf(course) and not weight:IsDescendantOf(model), model.Name .. " needs a separate outside counterweight")
				validateAnchored(weight, weight.PrimaryPart.Name)
				local contacts = {}
				for _, part in model:GetDescendants() do
					if part:IsA("BasePart") and part.CanCollide then table.insert(contacts, { part = part, velocity = part.AssemblyLinearVelocity }) end
				end
				rememberAttributes(model, { "MoonlitPhase", "MoonlitBoarding", "MoonlitPassengers", "MoonlitNextPhaseAt" })
				table.insert(cars, {
					model = model, deck = deck, contacts = contacts, start = model:GetPivot(), travel = travel,
					cycle = cycle, dwell = dwell, offset = math.max(0, numberAttribute(model, "PhaseSeconds", 0)),
					weight = weight, weightStart = weight:GetPivot(), passengers = 0, phase = "LowDwell",
					horizontalSupportRadius = math.sqrt(deck.Size.X * deck.Size.X + deck.Size.Z * deck.Size.Z) / 2,
					supportGuardLevel = deck.CFrame.UpVector.X == 0 and deck.CFrame.UpVector.Z == 0 and deck.CFrame.UpVector.Y > 0,
				})
			end
		elseif instance:IsA("Folder") and instance.Name == "SwingLanterns" then
			for _, model in instance:GetChildren() do
				if not model:IsA("Model") then continue end
				local cage = validateAnchored(model, "CageContact")
				local pivot, rest = model:GetAttribute("PivotPosition"), model:GetAttribute("RestCFrame")
				local visible = model:FindFirstChild("CageAndCore", true)
				assert(typeof(pivot) == "Vector3" and typeof(rest) == "CFrame" and cage.CanQuery and visible, "Lantern needs pivot, rest and cage/core")
				local visibleParts = {}
				for _, part in visible:GetDescendants() do
					if part:IsA("BasePart") and part.Transparency < 1 then
						assert(part.CanQuery, "Visible lantern cage/core must be queryable")
						table.insert(visibleParts, part)
					end
				end
				assert(#visibleParts > 0, "Lantern needs visible contact geometry")
				local contactRadius, sweepRadius = 0, 0
				local start = model:GetPivot()
				for _, part in visibleParts do
					local halfDiagonal = part.Size.Magnitude / 2
					contactRadius = math.max(contactRadius, (part.Position - cage.Position).Magnitude + halfDiagonal)
					local restPosition = rest:PointToWorldSpace(start:PointToObjectSpace(part.Position))
					sweepRadius = math.max(sweepRadius, (restPosition - pivot).Magnitude + halfDiagonal)
				end
				for _, part in model:GetDescendants() do if part:IsA("BasePart") then assert(not part.CanCollide, "Lantern must not fling racers") end end
				local cycle = numberAttribute(model, "CycleSeconds", 6)
				local axis = model:GetAttribute("SwingAxis") or Vector3.zAxis
				assert(cycle > 0 and typeof(axis) == "Vector3" and math.abs(axis.Magnitude - 1) < .01, "Invalid lantern cycle or axis")
				table.insert(lanterns, {
					model = model, cage = cage, visibleParts = visibleParts, start = model:GetPivot(), rest = rest,
					pivot = pivot, axis = axis.Unit, angle = math.rad(numberAttribute(model, "SwingAngleDegrees", 32)),
					cycle = cycle, offset = math.max(0, numberAttribute(model, "PhaseSeconds", 0)),
					contactRadius = contactRadius, sweepRadius = sweepRadius,
				})
			end
		elseif instance:IsA("BasePart") and instance:GetAttribute("MoonlitHazard") == true then
			assert(instance.CanQuery and instance.Transparency < 1, "Moonlit red contacts must be visible and queryable")
			table.insert(hazards, instance)
			hazardBounds[instance] = { center = instance.Position, radius = instance.Size.Magnitude / 2 }
		end
	end
	assert(#cars == 4 and #lanterns == 3, "Moonlit course needs four cars and three lanterns")

	local function restoreProfile(humanoid, saved)
		if humanoid.Parent ~= nil then
			humanoid.WalkSpeed, humanoid.UseJumpPower = saved.WalkSpeed, saved.UseJumpPower
			humanoid.JumpHeight, humanoid.JumpPower, humanoid.MaxSlopeAngle = saved.JumpHeight, saved.JumpPower, saved.MaxSlopeAngle
		end
	end
	local function syncProfile(racers)
		local current = {}
		supportedR15, unsupportedRigs = 0, {}
		for _, racer in racers do
			local humanoid = racer.humanoid
			if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
				table.insert(unsupportedRigs, racer.player.UserId)
				continue
			end
			current[humanoid] = true
			supportedR15 += 1
			if not profiles[humanoid] then
				profiles[humanoid] = { WalkSpeed = humanoid.WalkSpeed, UseJumpPower = humanoid.UseJumpPower, JumpHeight = humanoid.JumpHeight, JumpPower = humanoid.JumpPower, MaxSlopeAngle = humanoid.MaxSlopeAngle }
				local movement = Config.Movement
				humanoid.WalkSpeed, humanoid.UseJumpPower = movement.WalkSpeed, movement.UseJumpPower
				humanoid.JumpHeight, humanoid.MaxSlopeAngle = movement.JumpHeight, movement.MaxSlopeAngle
			end
		end
		for humanoid, saved in profiles do
			if not current[humanoid] then restoreProfile(humanoid, saved); profiles[humanoid] = nil end
		end
	end
	local function requestRecovery(player, reason, force, attempted)
		if not isEligible(player) or (attempted and attempted[player]) then return false end
		if attempted then attempted[player] = true end
		local accepted = recover(player, reason, force == true)
		if accepted then stats.recoveries += 1 else stats.recoveryRejected += 1 end
		return accepted
	end
	local function cue(parent, id, volume, speed)
		if Config.SoundEnabled == false then return nil end
		local sound = Instance.new("Sound")
		sound.Name, sound.SoundId, sound.Volume, sound.PlaybackSpeed = "MoonlitCourseCue", id, volume, speed
		sound.Looped, sound.RollOffMaxDistance, sound.RollOffMinDistance = true, 50, 6
		sound.Parent = parent
		table.insert(sounds, sound)
		return sound
	end
	local function scanHazard(part, params, owners, attempted, reason)
		stats.hazardProbes += 1
		for _, hit in Workspace:GetPartsInPart(part, params) do
			local player = owners[hit]
			if player and not attempted[player] then
				stats.hazardHits += 1
				requestRecovery(player, reason, false, attempted)
			end
		end
	end
	for _, hazard in hazards do
		table.insert(connections, hazard.Touched:Connect(function(hit)
			if stopped or not BODY_NAMES[hit.Name] or hit.Transparency >= 1 or not hit.CanQuery or not hit.Parent or not hit.Parent:IsA("Model") then return end
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player or not isEligible(player) then return end
			local params = OverlapParams.new()
			params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, { hit }
			stats.hazardProbes += 1
			if #Workspace:GetPartsInPart(hazard, params) > 0 then
				stats.hazardHits += 1
				requestRecovery(player, "MoonlitRedContact", false)
			end
		end))
	end
	for _, record in cars do record.sound = cue(record.deck, CAR_SOUND, .10, .65) end
	for _, record in lanterns do record.sound = cue(record.cage, LANTERN_SOUND, .12, .75) end

	local function restoreTransforms()
		for _, record in cars do
			if record.model.Parent then record.model:PivotTo(record.start) end
			if record.weight.Parent then record.weight:PivotTo(record.weightStart) end
			for _, contact in record.contacts do
				if contact.part.Parent and contact.part.AssemblyLinearVelocity ~= contact.velocity then contact.part.AssemblyLinearVelocity = contact.velocity end
			end
			record.phase, record.passengers = "LowDwell", 0
		end
		for _, record in lanterns do if record.model.Parent then record.model:PivotTo(record.start) end end
		for _, sound in sounds do sound:Stop() end
		for instance, originals in originalAttributes do
			if instance.Parent then for name, saved in originals do setAttributeChanged(instance, name, saved.value) end end
		end
	end
	function controller.Reset()
		assert(not stopped, "Moonlit runtime stopped")
		-- Shared recovery moves occupants out before the lift transforms reset.
		for _, player in Players:GetPlayers() do
			if isEligible(player) and not requestRecovery(player, "MoonlitRuntimeReset", false) then return false end
		end
		elapsed, redAccumulator = 0, 0
		restoreTransforms()
		return true
	end
	function controller.Stop()
		if stopped then return end
		stopped = true
		for _, connection in connections do connection:Disconnect() end
		restoreTransforms()
		for humanoid, saved in profiles do restoreProfile(humanoid, saved) end
		table.clear(profiles)
		for _, sound in sounds do sound:Destroy() end
		activeRoots[course] = nil
	end
	function controller.Diagnostics()
		local measured = table.clone(stats)
		measured.averageHeartbeatMs = if measured.frames > 0 then measured.cpuSeconds * 1000 / measured.frames else 0
		local report = {
			bound = not stopped, elapsed = elapsed, candidateId = course:GetAttribute("CandidateId"),
			stats = measured, lastBlocker = lastBlocker and table.clone(lastBlocker),
			supportedR15 = supportedR15, unsupportedRigUserIds = table.clone(unsupportedRigs),
			gravity = Workspace.Gravity, expectedGravity = Config.Gravity, gravityMatches = math.abs(Workspace.Gravity - Config.Gravity) < .01,
			cars = {}, lanterns = {}, sounds = {},
		}
		for _, record in cars do table.insert(report.cars, { name = record.model.Name, phase = record.phase, passengers = record.passengers, cycle = record.cycle, dwell = record.dwell, deckY = record.deck.Position.Y }) end
		for _, record in lanterns do
			local angle = math.sin(math.max(0, elapsed - record.offset) * 2 * math.pi / record.cycle) * record.angle
			table.insert(report.lanterns, { name = record.model.Name, visibleContactParts = #record.visibleParts, angleDegrees = math.deg(angle) })
		end
		for _, sound in sounds do table.insert(report.sounds, { id = sound.SoundId, loaded = sound.IsLoaded, playing = sound.IsPlaying }) end
		return report
	end
	activeRoots[course] = controller
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		if not course:IsDescendantOf(Workspace) then controller.Stop(); return end
		local startedAt = os.clock()
		elapsed += dt
		stats.frames += 1
		local racers, characters, visibleBodies, owners, attempted = {}, {}, {}, {}, {}
		for _, player in Players:GetPlayers() do
			-- Rebuild once per frame so replacements and spectators are excluded too.
			if player.Character then table.insert(characters, player.Character) end
			if isEligible(player) then
				local character, humanoid, root = characterParts(player)
				if character then
					local body = bodyParts(character)
					local racer = { player = player, character = character, humanoid = humanoid, root = root, body = body, visibleRadius = -1 }
					table.insert(racers, racer)
					for _, part in body do
						if part.Transparency < 1 and part.CanQuery then
							table.insert(visibleBodies, part)
							owners[part] = player
							racer.visibleRadius = math.max(racer.visibleRadius, (part.Position - root.Position).Magnitude + part.Size.Magnitude / 2)
						end
					end
					stats.bodyRadiusBuilds += 1
				end
			end
		end
		stats.characterFiltersBuilt += 1
		stats.maximumExcludedCharacters = math.max(stats.maximumExcludedCharacters, #characters)
		syncProfile(racers)
		Coverage.CheckSkyFall(course, racers, requestRecovery, attempted)
		local supportParams = RaycastParams.new()
		supportParams.FilterType, supportParams.FilterDescendantsInstances, supportParams.RespectCanCollide = Enum.RaycastFilterType.Exclude, characters, true
		local supports = {}
		for _, racer in racers do
			local humanoid, root = racer.humanoid, racer.root
			local state = humanoid:GetState()
			if root.Anchored or humanoid.Jump or humanoid.FloorMaterial == Enum.Material.Air or state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then continue end
			local nearDeck = false
			for _, record in cars do
				if not record.supportGuardLevel or insideDeckCircle(root.Position, record.deck.Position, record.horizontalSupportRadius) then nearDeck = true; break end
			end
			if not nearDeck then stats.skippedSupportChecks += 1; continue end
			stats.supportChecks += 1
			local hit = Workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + 1), 0), supportParams)
			if hit and hit.Normal:Dot(Vector3.yAxis) >= .95 then supports[racer] = hit.Instance end
		end
		for _, record in cars do
			local alpha, phase, remaining = carProgress(elapsed, record)
			local current = record.model:GetPivot()
			local target = record.start + record.travel * alpha
			local displacement = target.Position - current.Position
			local exclusions = table.clone(characters)
			table.insert(exclusions, record.model)
			table.insert(exclusions, record.weight)
			local cast = RaycastParams.new()
			cast.FilterType, cast.FilterDescendantsInstances, cast.RespectCanCollide = Enum.RaycastFilterType.Exclude, exclusions, true
			local overlap = OverlapParams.new()
			overlap.FilterType, overlap.FilterDescendantsInstances, overlap.RespectCanCollide = Enum.RaycastFilterType.Exclude, exclusions, true
			local passengerCount = 0
			for _, racer in racers do
				if attempted[racer.player] or supports[racer] ~= record.deck then continue end
				local point = record.deck.CFrame:PointToObjectSpace(racer.root.Position)
				if math.abs(point.X) > record.deck.Size.X / 2 or math.abs(point.Z) > record.deck.Size.Z / 2 then continue end
				stats.groundedRiders += 1
				local blocker, reason = nil, nil
				if displacement.Magnitude > .001 then
					local bodyFrame, bodySize = carryBounds(racer)
					cast.CollisionGroup, overlap.CollisionGroup = racer.root.CollisionGroup, racer.root.CollisionGroup
					stats.carryProbes += 1
					local result = Workspace:Blockcast(bodyFrame, bodySize, displacement, cast)
					if result then blocker, reason = result.Instance, "BodySweep" end
					if not blocker then
						stats.carryProbes += 1
						for _, part in Workspace:GetPartBoundsInBox(bodyFrame + displacement, bodySize, overlap) do
							if part.CanCollide then blocker, reason = part, "BodyDestination"; break end
						end
					end
				end
				if blocker then
					stats.blockedCarries += 1
					lastBlocker = { userId = racer.player.UserId, car = record.model.Name, part = blocker:GetFullName(), reason = reason, elapsed = elapsed, excludedCharacters = #characters }
					lastBlocker.recoveryAccepted = requestRecovery(racer.player, "MoonlitBlockedCarCarry", true, attempted)
				else
					passengerCount += 1
					if displacement.Magnitude > .001 then stats.carriedSteps += 1 end
				end
			end
			if displacement.Magnitude > .00001 then
				record.model:PivotTo(target)
				record.weight:PivotTo(record.weightStart - record.travel * alpha)
			end
			local velocity = if dt > 0 then displacement / dt else Vector3.zero
			for _, contact in record.contacts do
				if (contact.part.AssemblyLinearVelocity - velocity).Magnitude > .0001 then contact.part.AssemblyLinearVelocity = velocity end
			end
			record.phase, record.passengers = phase, passengerCount
			if record.model:GetAttribute("MoonlitPhase") ~= phase then
				setAttributeChanged(record.model, "MoonlitPhase", phase)
				setAttributeChanged(record.model, "MoonlitBoarding", phase == "LowDwell" or phase == "HighDwell")
				setAttributeChanged(record.model, "MoonlitNextPhaseAt", Workspace:GetServerTimeNow() + remaining)
			end
			setAttributeChanged(record.model, "MoonlitPassengers", passengerCount)
			if record.sound then
				local moving = phase == "Rising" or phase == "Descending"
				if moving and not record.sound.IsPlaying then record.sound:Play() elseif not moving and record.sound.IsPlaying then record.sound:Stop() end
			end
		end
		local params = OverlapParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, visibleBodies
		for _, record in lanterns do
			local nearSweep = possibleBodyContact(record.pivot, record.sweepRadius, racers)
			-- After a long stall one full period covers every authored swing position.
			local sweepDuration = math.min(dt, record.cycle)
			local steps = if nearSweep then math.max(1, math.ceil(sweepDuration * 2 * math.pi / record.cycle * math.abs(record.angle) * record.sweepRadius / .5)) else 1
			stats.maxLanternSweepSteps = math.max(stats.maxLanternSweepSteps, steps)
			for step = 1, steps do
				local t = math.max(0, elapsed - sweepDuration + sweepDuration * step / steps - record.offset)
				local angle = math.sin(t * 2 * math.pi / record.cycle) * record.angle
				local target = CFrame.new(record.pivot) * CFrame.fromAxisAngle(record.axis, angle) * CFrame.new(-record.pivot) * record.rest
				if record.model:GetPivot() ~= target then record.model:PivotTo(target) end
				if nearSweep and possibleBodyContact(record.cage.Position, record.contactRadius, racers) then
					stats.hazardProbes += 1
					-- The cube contains every visible part at any cage rotation.
					if #Workspace:GetPartBoundsInBox(CFrame.new(record.cage.Position), Vector3.one * (record.contactRadius * 2 + .04), params) > 0 then
						for _, part in record.visibleParts do scanHazard(part, params, owners, attempted, "MoonlitLanternCage") end
					end
				else
					stats.skippedLanternBroad += 1
				end
			end
			if record.sound and not record.sound.IsPlaying then record.sound:Play() end
		end
		redAccumulator += dt
		if redAccumulator >= .08 then
			redAccumulator = 0
			for _, hazard in hazards do
				local bounds = hazardBounds[hazard]
				if possibleBodyContact(bounds.center, bounds.radius, racers) then
					scanHazard(hazard, params, owners, attempted, "MoonlitRedContact")
				else
					stats.skippedRedBroad += 1
				end
			end
		end
		local duration = os.clock() - startedAt
		stats.cpuSeconds += duration
		stats.cpuMaxMs = math.max(stats.cpuMaxMs, duration * 1000)
	end))
	return controller
end

return Runtime
