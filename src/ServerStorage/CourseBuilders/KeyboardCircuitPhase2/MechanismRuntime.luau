--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Motion = require(script.Parent.Motion)
local Mechanisms = require(script.Parent.Mechanisms)
local Runtime = {}
local controllers = setmetatable({}, {__mode = "k"})

local function changed(instance: Instance, key: string, value)
	if instance:GetAttribute(key) ~= value then instance:SetAttribute(key, value) end
end

local function visibleWarning(plate: BasePart, warning: boolean, admission: boolean?, message: string?)
	local color = if warning then Color3.fromRGB(255, 215, 38) else if admission then Color3.fromRGB(156, 222, 191) else Color3.fromRGB(157, 126, 40)
	if plate.Color ~= color then plate.Color = color end
	local legend = plate:FindFirstChild("Legend")
	local label = if legend then legend:FindFirstChildOfClass("TextLabel") else nil
	if label and message and label.Text ~= message then label.Text = message end
	changed(plate, "WarningActive", warning)
	changed(plate, "AdmissionOpen", admission == true)
end

local function readTuning(unit: Model, kind: string)
	local tuning = Motion.Tuning(kind)
	for key in tuning do
		local value = unit:GetAttribute("Timing_" .. key)
		if value ~= nil then tuning[key] = value end
	end
	for key, value in tuning do assert(type(value) == "number" and value >= 0, unit.Name .. " invalid timing " .. key) end
	if tuning.Period then assert(tuning.Period > 0, "Mechanism period must be positive") end
	return tuning
end

local function collect(candidate: Model)
	local units, ids = {}, {}
	for _,unit in candidate:GetDescendants() do
		if not unit:IsA("Model") or not unit:GetAttribute("MechanismKind") then continue end
		local kind = unit:GetAttribute("MechanismKind") :: string
		local id = unit:GetAttribute("MechanismId")
		assert(id and not ids[id], "Mechanism IDs must be present and unique")
		ids[id] = true
		local record = {unit = unit, kind = kind, tuning = readTuning(unit, kind), actors = {}, lamps = {}, frames = {}, state = "Waiting", at = 0}
		for _,item in unit:GetDescendants() do
			if item:IsA("Model") and item:GetAttribute("KCMover") then
				local actor = {model = item, index = item:GetAttribute("MotionIndex"), rest = item:GetPivot(), shapes = {}, supports = {}, collidable = {}, radius = 0}
				for _,part in item:GetDescendants() do
					if not part:IsA("BasePart") then continue end
					actor.collidable[part] = part.CanCollide
					if part:GetAttribute("Role") == "Lethal" then table.insert(actor.shapes, part) end
					if part:GetAttribute("KCSupport") then table.insert(actor.supports, part) end
					if part:GetAttribute("Role") == "Lethal" then actor.radius = math.max(actor.radius, (part.CFrame.Position - actor.rest.Position).Magnitude + part.Size.Magnitude / 2) end
				end
				local pivotLocal = item:GetAttribute("MotionPivotLocal")
				if pivotLocal then actor.pivot = Mechanisms.GetFrame(unit) * pivotLocal; actor.localPose = actor.pivot:ToObjectSpace(actor.rest) end
				local ray = RaycastParams.new()
				ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, actor.supports, true
				actor.ray = ray
				table.insert(record.actors, actor)
			elseif item:IsA("BasePart") and item:GetAttribute("KCWarning") and not item:GetAttribute("KCActorWarning") then
				table.insert(record.lamps, item)
			elseif item:IsA("Frame") and item.Name == "DropWarning" then
				local key = item.Parent.Parent
				table.insert(record.frames, {frame = item, index = key:GetAttribute("DropWarningIndex")})
			end
		end
		table.sort(record.actors, function(a, b) return a.index < b.index end)
		table.insert(units, record)
	end
	return units
end

function Runtime.Start(candidate: Model, eligible: (Player) -> boolean, recover: (Player, string) -> boolean, options)
	assert(RunService:IsServer(), "Keyboard Circuit mechanisms must run on the server")
	assert(candidate:GetAttribute("Phase2Only") == true, "Isolated Phase 2 candidate required")
	local existing = controllers[candidate]
	if existing then return existing end
	local units = collect(candidate)
	assert(#units == 8, "Phase 2 requires exactly eight mechanism units")
	local clock = Motion.NewClock(Workspace:GetServerTimeNow())
	local settings = table.clone(Motion.Defaults)
	for key, value in options or {} do settings[key] = value end
	local stationaryQueries = 0
	for _,record in units do for _,actor in record.actors do stationaryQueries += #actor.shapes end end
	assert(settings.MaxQueriesPerFrame >= stationaryQueries and settings.MaxSweepSteps >= 1, "Query budget must allow every stationary lethal shape")
	local params = OverlapParams.new()
	params.FilterType, params.RespectCanCollide = Enum.RaycastFilterType.Include, false
	local characters, characterPlayers, playerRows, retryAt = {}, {}, {}, {}
	local active, connection, failed = true, nil, nil
	local counters = {frames = 0, bodyQueries = 0, peakQueries = 0, pivots = 0, contacts = 0, supportRays = 0, pausedBudgets = 0, stalledContactFrames = 0, errors = 0}
	local frameQueries = 0
	local function gather()
		table.clear(characters); table.clear(characterPlayers); table.clear(playerRows)
		for _,player in Players:GetPlayers() do
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
			if eligible(player) and character and root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 then
				table.insert(characters, character)
				characterPlayers[character] = player
				table.insert(playerRows, {player = player, character = character, root = root, humanoid = humanoid})
			end
		end
		params.FilterDescendantsInstances = characters
	end
	local function retry(player: Player, reason: string, force: boolean?): boolean
		if not force and (retryAt[player] or -math.huge) > clock.elapsed then return false end
		retryAt[player] = clock.elapsed + settings.ContactRetry
		if recover(player, reason) then counters.contacts += 1; return true end
		return false
	end
	local function checkShapes(actor, reason: string)
		if #characters == 0 then return end
		for _,shape in actor.shapes do
			frameQueries += 1; counters.bodyQueries += 1
			for _,body in Workspace:GetPartsInPart(shape, params) do
				if body:FindFirstAncestorWhichIsA("Accessory") then continue end
				local ancestor: Instance? = body.Parent
				while ancestor and not characterPlayers[ancestor] do ancestor = ancestor.Parent end
				local player = if ancestor then characterPlayers[ancestor] else nil
				if player then retry(player, reason) end
			end
		end
	end
	local function supported(row, actor): boolean
		if row.humanoid.FloorMaterial == Enum.Material.Air then return false end
		counters.supportRays += 1
		return Workspace:Raycast(row.root.CFrame.Position, Vector3.new(0, -settings.SupportRayLength, 0), actor.ray) ~= nil
	end
	local function recoverSupport(actor, reason: string)
		for _,row in playerRows do if supported(row, actor) then retry(row.player, reason, true) end end
	end
	local function movable(actor, enabled: boolean)
		for part in actor.collidable do
			part.Anchored = not enabled
			if not enabled then part.AssemblyLinearVelocity, part.AssemblyAngularVelocity = Vector3.zero, Vector3.zero end
		end
		if enabled then (actor.model.PrimaryPart :: BasePart):SetNetworkOwner(nil) end
	end
	local function resetUnits(recoverRiders: boolean)
		if recoverRiders then gather() end
		for _,record in units do
			for _,constraint in record.unit:GetChildren() do
				if constraint:IsA("PrismaticConstraint") or constraint:IsA("HingeConstraint") then constraint.Enabled = false end
			end
			for _,actor in record.actors do
				if recoverRiders and #actor.supports > 0 then recoverSupport(actor, "MechanismReset") end
				if actor.model:GetAttribute("KCPhysicalMover") then movable(actor, false) end
				actor.model:PivotTo(actor.rest)
				for part, collidable in actor.collidable do part.CanCollide = collidable end
				changed(actor.model, "CycleState", "Stopped")
				changed(actor.model, "OpenWindow", false)
				changed(actor.model, "AdmissionOpen", false)
			end
			for _,constraint in record.unit:GetChildren() do
				if constraint:IsA("PrismaticConstraint") then constraint.TargetPosition = 0 end
				if constraint:IsA("HingeConstraint") then constraint.TargetAngle = 0 end
			end
			for _,lamp in record.lamps do visibleWarning(lamp, false, false) end
			for _,entry in record.frames do entry.frame.BackgroundTransparency = 1 end
			record.state, record.at = "Waiting", 0
			changed(record.unit, "CycleState", "Stopped")
			changed(record.unit, "BoardingWindow", false)
			changed(record.unit, "ExitWindow", false)
		end
		changed(candidate, "KCElapsed", 0)
	end
	resetUnits(false)
	for _,record in units do
		for _,actor in record.actors do if actor.model:GetAttribute("KCPhysicalMover") then movable(actor, true) end end
		for _,constraint in record.unit:GetChildren() do if constraint:IsA("PrismaticConstraint") or constraint:IsA("HingeConstraint") then constraint.Enabled = true end end
	end
	local function stateFor(record, actor, now: number)
		local kind, tuning = record.kind, record.tuning
		if kind == "Fallaway" then return Motion.Fallaway(now, actor.model:GetAttribute("LaneIndex"), actor.model:GetAttribute("RowIndex"), tuning) end
		if kind == "Foundry" then return Motion.Foundry(now, actor.index, tuning) end
		if kind == "Sweep" then return Motion.Sweep(now, tuning) end
		if kind == "Domino" then return Motion.Domino(now, actor.index, tuning) end
		if kind == "Shift" then return Motion.Shift(now, actor.index, tuning) end
		return nil
	end
	local function destinationFor(record, actor, state)
		local frame, kind, tuning = Mechanisms.GetFrame(record.unit), record.kind, record.tuning
		if kind == "Fallaway" then
			local shake = if state.warning then math.sin(clock.elapsed * 35) * .045 else 0
			return actor.rest + frame:VectorToWorldSpace(Vector3.new(shake, -tuning.DropDistance * state.alpha, 0))
		end
		if kind == "Foundry" then return actor.rest + frame:VectorToWorldSpace(Vector3.new(0, -tuning.DropDistance * state.alpha, 0)) end
		if kind == "Sweep" then return actor.pivot * CFrame.Angles(0, math.rad(tuning.Angle) * state.alpha, 0) * actor.localPose end
		if kind == "Domino" then return actor.pivot * CFrame.Angles(0, 0, -math.rad(tuning.Angle) * state.alpha) * actor.localPose end
		if kind == "Shift" then return actor.rest + frame:VectorToWorldSpace(Vector3.new(0, 0, actor.model:GetAttribute("RetractDirection") * tuning.Travel * state.alpha)) end
		return actor.rest
	end
	local function updateLamps(record, states)
		for _,lamp in record.lamps do
			local index = lamp:GetAttribute("MotionIndex") or lamp:GetAttribute("LaneIndex") or 1
			local state = states[index]
			if state then
				local message = if record.kind == "Fallaway" or record.kind == "Shift" then (if state.admission then "GO" else "WAIT") else if record.kind == "Domino" then (if state.state == "ResetWarning" or state.state == "Reset" then "↑" else "↓") else nil
				visibleWarning(lamp, state.warning, state.admission, message)
			end
		end
		for _,entry in record.frames do
			local state = states[entry.index]
			local transparency = if state and state.warning then .45 else 1
			if entry.frame.BackgroundTransparency ~= transparency then entry.frame.BackgroundTransparency = transparency end
		end
	end
	local function physical(record, now: number)
		local tuning, unit = record.tuning, record.unit
		if record.kind == "Seesaws" then
			for _,actor in record.actors do
				local hinge = unit["Hinge" .. actor.index]
				hinge.TargetAngle = math.sin((now + (actor.index - 1) * tuning.Offset) * math.pi * 2 / tuning.Period) * tuning.MaxAngle
				changed(actor.model, "CycleState", "Rocking")
			end
			changed(unit, "CycleState", "Rocking")
		elseif record.kind == "Lift" then
			local slider, actor = unit.Slider, record.actors[1]
			if record.state == "Waiting" then
				for _,row in playerRows do if supported(row, actor) then record.state, record.at = "Boarding", now; break end end
			elseif record.state == "Boarding" and now - record.at >= tuning.BoardDwell then record.state, record.at = "Rising", now
			elseif record.state == "Rising" and math.abs(slider.CurrentPosition - tuning.Travel) <= tuning.ArrivalTolerance then record.state, record.at = "HighDwell", now
			elseif record.state == "HighDwell" and now - record.at >= tuning.HighDwell then record.state, record.at = "Returning", now
			elseif record.state == "Returning" and math.abs(slider.CurrentPosition) <= tuning.ArrivalTolerance then record.state, record.at = "Waiting", now end
			slider.Speed = tuning.Speed
			slider.TargetPosition = if record.state == "Rising" or record.state == "HighDwell" then tuning.Travel else 0
			local boarding = record.state == "Waiting" or record.state == "Boarding"
			changed(unit, "CycleState", record.state)
			changed(unit, "BoardingWindow", boarding and math.abs(slider.CurrentPosition) <= tuning.ArrivalTolerance)
			changed(unit, "ExitWindow", record.state == "HighDwell" and math.abs(slider.CurrentPosition - tuning.Travel) <= tuning.ArrivalTolerance)
			for _,lamp in record.lamps do visibleWarning(lamp, record.state == "Boarding", boarding) end
		elseif record.kind == "Shuttle" then
			local slider = unit.Slider
			local state = Motion.Shuttle(now, tuning)
			slider.Speed = tuning.Speed
			slider.TargetPosition = if state.state == "Outbound" or state.state == "Exit" then tuning.Travel else 0
			local boarding = state.state == "Boarding" and math.abs(slider.CurrentPosition) <= tuning.ArrivalTolerance
			local exit = state.state == "Exit" and math.abs(slider.CurrentPosition - tuning.Travel) <= tuning.ArrivalTolerance
			changed(unit, "CycleState", state.state)
			changed(unit, "BoardingWindow", boarding)
			changed(unit, "ExitWindow", exit)
			for _,lamp in record.lamps do visibleWarning(lamp, state.warning, if lamp.Name == "BoardingWarning" then boarding else exit, if (lamp.Name == "BoardingWarning" and boarding) or (lamp.Name == "ExitWarning" and exit) then "GO" else "WAIT") end
		end
	end
	local function heartbeat()
		local before, now, advanced = Motion.StepClock(clock, Workspace:GetServerTimeNow(), settings.MaxClockStep)
		gather()
		frameQueries = 0
		local function stationaryContacts()
			for _,record in units do for _,actor in record.actors do checkShapes(actor, record.unit:GetAttribute("MechanismId") .. "Contact") end end
			counters.peakQueries = math.max(counters.peakQueries, frameQueries)
			counters.stalledContactFrames += 1
		end
		if not advanced then stationaryContacts(); return end
		local plans, queries = {}, 0
		for _,record in units do
			local states = {}
			for _,actor in record.actors do
				local state = stateFor(record, actor, now)
				if not state then continue end
				local destination, previous = destinationFor(record, actor, state), actor.model:GetPivot()
				local steps = if #actor.shapes > 0 then Motion.SweepSteps(previous, destination, actor.radius, settings.SweepSpacing) else 1
				if steps > settings.MaxSweepSteps then clock.elapsed = before; counters.pausedBudgets += 1; stationaryContacts(); return end
				queries += if #characters > 0 then #actor.shapes * (if previous == destination then 1 else steps + 1) else 0
				table.insert(plans, {record = record, actor = actor, state = state, previous = previous, destination = destination, steps = steps})
				if record.kind == "Fallaway" then
					if actor.model:GetAttribute("RowIndex") == 1 then states[actor.model:GetAttribute("LaneIndex")] = state end
				else states[actor.index] = state end
			end
			record.nextStates = states
		end
		-- A budget failure holds every scripted actor and warning at the previous checked phase.
		if queries > settings.MaxQueriesPerFrame then clock.elapsed = before; counters.pausedBudgets += 1; stationaryContacts(); return end
		for _,plan in plans do
			local actor, state, record = plan.actor, plan.state, plan.record
			if record.kind == "Fallaway" or record.kind == "Shift" then
				for part, collidable in actor.collidable do part.CanCollide = collidable and state.open end
			end
			if plan.previous == plan.destination then checkShapes(actor, record.unit:GetAttribute("MechanismId") .. "Contact")
			elseif #actor.shapes == 0 then actor.model:PivotTo(plan.destination); counters.pivots += 1
			else
				for step = 0, plan.steps do
					actor.model:PivotTo(plan.previous:Lerp(plan.destination, step / plan.steps))
					counters.pivots += 1
					checkShapes(actor, record.unit:GetAttribute("MechanismId") .. "Contact")
				end
			end
			changed(actor.model, "CycleState", state.state)
			changed(actor.model, "OpenWindow", state.open)
			changed(actor.model, "AdmissionOpen", state.admission)
			if record.kind == "Fallaway" then
				local lamp = actor.model:FindFirstChild("RowWarning")
				if lamp then visibleWarning(lamp, state.warning, state.admission) end
			end
		end
		for _,record in units do
			physical(record, now)
			updateLamps(record, record.nextStates)
			if record.nextStates[1] then changed(record.unit, "CycleState", record.nextStates[1].state) end
		end
		counters.frames += 1
		counters.peakQueries = math.max(counters.peakQueries, frameQueries)
		changed(candidate, "KCElapsed", now)
	end
	local controller = {}
	function controller.Diagnostics()
		local result = table.clone(counters)
		result.active, result.elapsed, result.pausedStalls, result.failure = active, clock.elapsed, clock.pausedStalls, failed
		result.units, result.maxQueriesPerFrame, result.maxSweepSteps = #units, settings.MaxQueriesPerFrame, settings.MaxSweepSteps
		result.heartbeatConnections = if active then 1 else 0
		return result
	end
	function controller.Stop()
		if not active then return end
		active = false
		if connection then connection:Disconnect() end
		resetUnits(true)
		table.clear(retryAt)
		controllers[candidate] = nil
	end
	function controller.Reset()
		controller.Stop()
		return Runtime.Start(candidate, eligible, recover, options)
	end
	connection = RunService.Heartbeat:Connect(function()
		local success, failure = xpcall(heartbeat, debug.traceback)
		if not success then
			failed = tostring(failure); counters.errors += 1
			controller.Stop()
			warn("Keyboard Circuit mechanism runtime stopped safely: " .. failed)
		end
	end)
	controllers[candidate] = controller
	return controller
end

return Runtime
