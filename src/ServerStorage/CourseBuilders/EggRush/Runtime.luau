--!nonstrict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Runtime = {}
local activeRoots = setmetatable({}, { __mode = "k" })
local BODY_NAMES = {
	Head = true, Torso = true, UpperTorso = true, LowerTorso = true,
	["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true,
	RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true,
	RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
}
local STATE_ATTRIBUTES = { "ERState", "EROpen", "ERBoarding", "ERExit" }

local function numberAttribute(instance, name, minimum, fallback)
	local value = instance:GetAttribute(name)
	if value == nil then value = fallback end
	assert(typeof(value) == "number" and value == value and math.abs(value) < math.huge
		and value >= minimum, instance.Name .. " needs finite " .. name .. " >= " .. minimum)
	return value
end

local function setChanged(instance, name, value)
	if instance:GetAttribute(name) ~= value then instance:SetAttribute(name, value) end
end

local function smooth(alpha)
	return alpha * alpha * (3 - 2 * alpha)
end

local function segmentsFor(kind, settings)
	local segments
	if kind == "ShellLip" then
		segments = {
			{ settings.closed, "Closed", 0, 0 }, { settings.warning, "Warning", 0, 0 },
			{ settings.move, "Opening", 0, 1 }, { settings.open, "Open", 1, 1 },
			{ settings.closingWarning, "ClosingWarning", 1, 1 }, { settings.move, "Closing", 1, 0 },
		}
	elseif kind == "Tray" then
		segments = {
			{ settings.board, "Boarding", 0, 0 }, { settings.warning, "DepartureWarning", 0, 0 },
			{ settings.move, "Travel", 0, 1 }, { settings.exit, "Exit", 1, 1 },
			{ settings.closingWarning, "ReturnWarning", 1, 1 }, { settings.move, "Returning", 1, 0 },
		}
	elseif kind == "EggRoller" then
		segments = {
			{ settings.rest, "Clear", 0, 0 }, { settings.warning, "Warning", 0, 0 },
			{ settings.move, "Rolling", 0, 1 },
		}
	elseif kind == "Tail" then
		segments = {
			{ settings.rest, "Rest", 0, 0 }, { settings.warning, "Warning", 0, 0 },
			{ settings.move, "Sweeping", 0, 1 }, { settings.open, "FarWait", 1, 1 },
			{ settings.closingWarning, "ReturnWarning", 1, 1 }, { settings.move, "Returning", 1, 0 },
		}
	else
		error("Unsupported Egg Rush mechanism " .. tostring(kind))
	end
	return segments
end

local function sampleSegments(segments, phase, elapsed)
	local cycle = 0
	for _, segment in segments do cycle += segment[1] end
	local time = (elapsed + phase) % cycle
	for _, segment in segments do
		if time < segment[1] then
			local alpha = time / segment[1]
			if segment[2] ~= "Rolling" then alpha = smooth(alpha) end
			return segment[3] + (segment[4] - segment[3]) * alpha, segment[2]
		end
		time -= segment[1]
	end
	return 0, segments[1][2]
end

-- Public pure sampler lets offline checks exercise every cycle boundary.
function Runtime.Sample(kind, settings, elapsed)
	return sampleSegments(segmentsFor(kind, settings), settings.phase or 0, elapsed)
end

local function settingsFor(model, kind)
	local settings = {
		phase = numberAttribute(model, "PhaseSeconds", 0, 0),
		warning = numberAttribute(model, "WarningSeconds", .8),
		move = numberAttribute(model, "MoveSeconds", .5),
	}
	if kind == "ShellLip" then
		settings.closed = numberAttribute(model, "ClosedSeconds", .1)
		settings.open = numberAttribute(model, "OpenSeconds", .5)
		settings.closingWarning = numberAttribute(model, "ClosingWarningSeconds", .8)
		settings.angle = math.rad(numberAttribute(model, "ClosedAngleDegrees", 1))
	elseif kind == "Tray" then
		settings.board = numberAttribute(model, "BoardSeconds", .5)
		settings.exit = numberAttribute(model, "ExitSeconds", .5)
		settings.closingWarning = numberAttribute(model, "ClosingWarningSeconds", .8)
	elseif kind == "EggRoller" then
		settings.rest = numberAttribute(model, "RestSeconds", .5)
		settings.turns = numberAttribute(model, "RollTurns", 0)
		assert(settings.turns <= 8, "Egg roll must be <= 8 turns per release")
	elseif kind == "Tail" then
		settings.rest = numberAttribute(model, "RestSeconds", .5)
		settings.open = numberAttribute(model, "FarWaitSeconds", .5)
		settings.closingWarning = numberAttribute(model, "ClosingWarningSeconds", .8)
		settings.angle = math.rad(numberAttribute(model, "SweepAngleDegrees", 1))
	end
	if settings.angle then assert(settings.angle <= math.pi, "Egg Rush hinge angle must be <= 180 degrees") end
	return settings
end

local function targetFrame(record, alpha)
	if record.kind == "Tray" or record.kind == "EggRoller" then
		local translation = record.start * CFrame.new(record.travel * alpha)
		return if record.kind == "EggRoller" then translation * CFrame.fromAxisAngle(record.axis, 2 * math.pi * record.settings.turns * alpha) else translation
	end
	local angle = record.settings.angle * (if record.kind == "ShellLip" then 1 - alpha else alpha)
	return record.start * CFrame.fromAxisAngle(record.axis, angle)
end

local function isWarning(state)
	return state == "Warning" or state == "ClosingWarning" or state == "DepartureWarning" or state == "ReturnWarning"
end

function Runtime.Start(course: Model, isEligible: (Player) -> boolean, recover)
	assert(RunService:IsServer(), "Egg Rush runtime must run on the server")
	assert(course:IsDescendantOf(Workspace) and course:GetAttribute("CourseId") == "egg_rush_circuit", "Active Egg Rush course required")
	assert(not activeRoots[course], "Egg Rush runtime already bound")
	local records, pecks, movingModels, staticHazards = {}, {}, {}, {}
	for _, model in course:GetDescendants() do
		local kind = model:GetAttribute("ERMechanism")
		if kind == nil then continue end
		assert(model:IsA("Model"), "ERMechanism belongs on a Model")
		if kind == "Peck" then
			table.insert(pecks, require(script.Parent.GuardianPeck).Bind(model,course))
			movingModels[model] = true
			continue
		end
		assert(kind == "ShellLip" or kind == "Tray" or kind == "EggRoller" or kind == "Tail", "Unknown ERMechanism")
		local parent = model.Parent
		while parent and parent ~= course do
			assert(parent:GetAttribute("ERMechanism") == nil, "Egg Rush mechanisms cannot nest")
			parent = parent.Parent
		end
		local settings = settingsFor(model, kind)
		local authoringFrame = model:GetPivot()
		local preview = model:GetAttribute("ERPreviewTransform")
		local pathFrame = if typeof(preview) == "CFrame" then authoringFrame * preview:Inverse() else authoringFrame
		local record = {
			model = model, kind = kind, settings = settings, start = pathFrame, restoreFrame = authoringFrame,
			segments = segmentsFor(kind, settings),
			parts = {}, contacts = {}, supports = {}, attributes = {}, radius = 0, state = nil,
		}
		for _, name in STATE_ATTRIBUTES do record.attributes[name] = { value = model:GetAttribute(name) } end
		if kind == "Tray" or kind == "EggRoller" then
			record.travel = model:GetAttribute("Travel")
			assert(typeof(record.travel) == "Vector3" and record.travel.Magnitude > 0
				and record.travel.Magnitude <= 200, model.Name .. " needs bounded local Travel")
			if kind == "Tray" then assert(math.abs(record.travel.Y) < .001, "Egg Rush tray must move sideways on level rails") end
		end
		if kind ~= "Tray" then
			record.axis = model:GetAttribute("RotationAxis")
			assert(typeof(record.axis) == "Vector3" and math.abs(record.axis.Magnitude - 1) < .001,
				model.Name .. " needs unit local RotationAxis")
		end
		local warning = model:FindFirstChild("Warning")
		if warning and warning:IsA("ObjectValue") then warning = warning.Value end
		assert(warning and warning:IsA("BasePart") and warning:IsDescendantOf(course) and warning.Transparency < 1,
			model.Name .. " needs visible Warning part or ObjectValue")
		assert(not warning:IsDescendantOf(model), "Warning must stay fixed outside the moving model; use an ObjectValue")
		record.warning, record.warningColor = warning, warning.Color
		record.sound = warning:FindFirstChild("WarningSound")
		if record.sound then
			assert(record.sound:IsA("Sound") and record.sound.SoundId ~= "" and not record.sound.IsPlaying,
				"WarningSound must be an idle configured Sound")
			record.soundLooped, record.soundTime = record.sound.Looped, record.sound.TimePosition
		end
		assert(kind ~= "EggRoller" or record.sound, "Rolling eggs need an audible warning")
		for _, part in model:GetDescendants() do
			if not part:IsA("BasePart") then continue end
			assert(part.Anchored, model.Name .. " must have anchored parts")
			table.insert(record.parts, {
				part = part, transparency = part.Transparency,
				linear = part.AssemblyLinearVelocity, angular = part.AssemblyAngularVelocity,
			})
			record.radius = math.max(record.radius, (part.Position - authoringFrame.Position).Magnitude + part.Size.Magnitude / 2)
			if part:GetAttribute("ERSupport") == true then
				assert(part.CanCollide and part.CanQuery and (kind == "ShellLip" or kind == "Tray"), "ERSupport must be a colliding shell/tray surface")
				table.insert(record.supports, part)
			end
			if (kind == "ShellLip" or kind == "Tray") and part.CanCollide then
				assert(part:GetAttribute("ERSupport") == true, "Every colliding moving shell/tray part needs ERSupport")
			end
			if part:GetAttribute("ERLethal") == true then
				assert(part.CanQuery and part.Transparency < 1 and not part.CanCollide
					and (kind == "EggRoller" or kind == "Tail"), "Moving lethal contact must be visible, queryable egg/tail geometry")
				table.insert(record.contacts, part)
			end
			if kind == "EggRoller" or kind == "Tail" then assert(not part.CanCollide, "Eggs/tail must not fling players") end
		end
		assert(#record.parts > 0 and record.radius <= 80, "Mechanism needs bounded physical geometry")
		if kind == "ShellLip" or kind == "Tray" then
			assert(#record.supports > 0, model.Name .. " needs ERSupport surface")
		else
			assert(#record.contacts > 0, model.Name .. " needs visible ERLethal contact")
		end
		table.insert(records, record)
		movingModels[model] = true
	end
	assert(#records > 0 or #pecks > 0, "Egg Rush course has no mechanisms")
	for _, part in course:GetDescendants() do
		if not part:IsA("BasePart") or part:GetAttribute("ERLethal") ~= true then continue end
		local parent, moving = part.Parent, false
		while parent and parent ~= course do
			if movingModels[parent] then moving = true; break end
			parent = parent.Parent
		end
		if not moving then
			assert(part.Transparency < 1 and part.CanQuery, "Static red contact must be visible and queryable")
			table.insert(staticHazards, part)
		end
	end
	local elapsed, stopped, holding = 0, false, false
	local stats = { frames = 0, pausedStalls = 0, contactQueries = 0, recoveryAttempts = 0, recoveries = 0, maximumSubsteps = 0 }
	local connection
	local controller = {}
	function controller.Diagnostics()
		local mechanisms = {}
		for _, record in records do
			table.insert(mechanisms, { name = record.model.Name, kind = record.kind, state = record.state,
				supportParts = #record.supports, lethalParts = #record.contacts })
		end
		for _, peck in pecks do
			table.insert(mechanisms, { name = peck.model.Name, kind = "Peck", state = peck.state,
				target = peck.target, supportParts = 0, lethalParts = #peck.contacts })
		end
		return { bound = not stopped, holding = holding, elapsed = elapsed, stats = table.clone(stats), mechanisms = mechanisms }
	end
	function controller.Hold()
		if stopped or holding then return end
		holding = true
		for _, record in records do
			for _, part in record.supports do
				part.AssemblyLinearVelocity, part.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
			end
			if record.sound then record.sound:Stop() end
		end
		for _, peck in pecks do peck.Hold() end
	end
	function controller.Resume()
		if stopped or not holding then return end
		holding = false
		for _, record in records do
			if record.sound and isWarning(record.state) then record.sound:Play() end
		end
		for _, peck in pecks do peck.Resume() end
	end
	function controller.Stop()
		if stopped then return end
		stopped = true
		if connection then connection:Disconnect() end
		for _, record in records do
			if record.model.Parent then
				record.model:PivotTo(record.restoreFrame)
				for name, saved in record.attributes do setChanged(record.model, name, saved.value) end
			end
			for _, saved in record.parts do
				local part = saved.part
				if part.Parent then
					part.Transparency = saved.transparency
					part.AssemblyLinearVelocity, part.AssemblyAngularVelocity = saved.linear, saved.angular
				end
			end
			if record.warning.Parent then record.warning.Color = record.warningColor end
			if record.sound and record.sound.Parent then
				record.sound:Stop()
				record.sound.Looped, record.sound.TimePosition = record.soundLooped, record.soundTime
			end
		end
		for _, peck in pecks do peck.Stop() end
		activeRoots[course] = nil
	end
	local function update(dt)
		if not course:IsDescendantOf(Workspace) then controller.Stop(); return end
		if holding then return end
		-- Freeze the shared mechanism clock after a stall instead of sweeping stale players.
		if dt <= 0 or dt > .25 then
			stats.pausedStalls += 1
			for _, record in records do
				for _, part in record.supports do
					part.AssemblyLinearVelocity, part.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
				end
			end
			return
		end
		local oldElapsed = elapsed
		elapsed += dt
		stats.frames += 1
		local owners, bodies, attempted = {}, {}, {}
		local now = Workspace:GetServerTimeNow()
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not isEligible(player) or not character or not humanoid or humanoid.Health <= 0
				or (character:GetAttribute("RecoveryUntil") or 0) > now then continue end
			for _, body in character:GetChildren() do
				if body:IsA("BasePart") and BODY_NAMES[body.Name] and body.Transparency < 1 and body.CanQuery then
					table.insert(bodies, body)
					owners[body] = player
				end
			end
		end
		local params = OverlapParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, bodies
		params.RespectCanCollide = false
		local function contact(part, reason)
			if #bodies == 0 or not part.Parent or part.Transparency >= 1 then return end
			stats.contactQueries += 1
			for _, body in Workspace:GetPartsInPart(part, params) do
				local player = owners[body]
				if player and not attempted[player] and player.Character == body.Parent and isEligible(player) then
					attempted[player] = true
					stats.recoveryAttempts += 1
					if recover(player, reason, false) then stats.recoveries += 1 end
				end
			end
		end
		for _, record in records do
			if not record.model:IsDescendantOf(course) then controller.Stop(); return end
			local before = record.model:GetPivot()
			local supportFrames = {}
			for _, part in record.supports do supportFrames[part] = part.CFrame end
			local speed = if record.travel then record.travel.Magnitude / record.settings.move
				else record.radius * record.settings.angle * 1.5 / record.settings.move
			if record.kind == "EggRoller" then speed += record.radius * 2 * math.pi * record.settings.turns / record.settings.move end
			local steps = if #record.contacts > 0 then math.max(1, math.ceil(speed * dt / .4), math.ceil(dt * 30)) else 1
			stats.maximumSubsteps = math.max(stats.maximumSubsteps, steps)
			local lastState
			for step = 1, steps do
				local alpha, state = sampleSegments(record.segments, record.settings.phase, oldElapsed + dt * step / steps)
				lastState = state
				record.model:PivotTo(targetFrame(record, alpha))
				if record.kind == "EggRoller" then
					for _, saved in record.parts do
						saved.part.Transparency = if state == "Rolling" then saved.transparency else 1
					end
				end
				if record.kind ~= "EggRoller" or state == "Rolling" then
					for _, part in record.contacts do contact(part, "EggRush:" .. record.model.Name) end
				end
			end
			local after = record.model:GetPivot()
			local axis, angle = (after.Rotation * before.Rotation:Inverse()):ToAxisAngle()
			for _, part in record.supports do
				part.AssemblyLinearVelocity = (part.Position - supportFrames[part].Position) / dt
				part.AssemblyAngularVelocity = axis * (angle / dt)
			end
			if lastState ~= record.state then
				record.state = lastState
				local warning = isWarning(lastState)
				local usable = lastState == "Open" or lastState == "Boarding" or lastState == "Exit"
				setChanged(record.model, "ERState", lastState)
				setChanged(record.model, "EROpen", lastState == "Open")
				setChanged(record.model, "ERBoarding", lastState == "Boarding")
				setChanged(record.model, "ERExit", lastState == "Exit")
				record.warning.Color = if warning then Color3.fromRGB(255, 194, 55)
					elseif usable then Color3.fromRGB(112, 211, 168) else record.warningColor
				if record.sound then
					if warning then record.sound.Looped = true; record.sound:Play() else record.sound:Stop() end
				end
			end
		end
		for _, peck in pecks do
			stats.maximumSubsteps = math.max(stats.maximumSubsteps,peck.Advance(oldElapsed,dt,contact,#bodies>0))
		end
		for _, part in staticHazards do contact(part, "EggRush:RedContact") end
	end
	activeRoots[course] = controller
	connection = RunService.Heartbeat:Connect(update)
	return controller
end

return Runtime
