--!strict
local RunService, Players, Http = game:GetService("RunService"), game:GetService("Players"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client fixture required")
local player = Players.LocalPlayer
local candidate = assert(workspace:FindFirstChild("KeyboardCircuit_P2_I07_Final05"))
assert(candidate:GetAttribute("CourseId") == "keyboard-circuit-phase2" and candidate:GetAttribute("Phase2Only") and candidate:GetAttribute("PrototypeOnly") and candidate:GetAttribute("PrototypeRevision") == "KC_P2_I07_05", "Exact compact prototype required")
local setupProbe = assert(shared.KCP2I07TraversalProbe, "Install work-i07/Setup first")
local Factory = assert(shared.KCP2I07EfficientTraversal, "Install work-i07/Driver first")
assert(Factory.Revision == "KC_P2_I07_DRIVER_05", "Current departure-footprint driver required")
local Timing = assert(shared.KCP2I07Timing, "Install work-i07/Timing first")
assert(not shared.KCP2ContinuousLap or not shared.KCP2ContinuousLap.active, "Original lap fixture is active")
assert(not shared.KCP2I07Race or not shared.KCP2I07Race.active, "Efficient race fixture is active")
assert(not shared.KCP2I06Pacing or not shared.KCP2I06Pacing.active, "Efficient lap fixture is active")
local options = shared.KCP2I07RaceOptions or {}
local routeChoice = options.routeChoice or "normal"
local arrivalDelay = options.arrivalDelaySeconds or 0
assert(routeChoice == "normal" or routeChoice == "expert" or routeChoice == "x02", "Choose normal, expert or x02")
local requestedLaps = options.laps or 3
assert(requestedLaps == 1 or requestedLaps == 3, "Choose one measurement lap or three complete race laps")
assert(type(arrivalDelay) == "number" and arrivalDelay >= 0 and arrivalDelay <= 14, "Arrival delay must be 0–14 seconds")
local pairedX02 = options.pairedX02 == true
assert(routeChoice ~= "x02" or pairedX02, "Expert comparison requires the common paired departure")
local Layout, Motion = require(candidate.SourceSnapshot.Layout), require(candidate.SourceSnapshot.Motion)
local character = assert(player.Character)
local root = assert(character:FindFirstChild("HumanoidRootPart")) :: BasePart
local humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
local started, runId = os.clock(), candidate:GetAttribute("KCPhase2RunId")
local initialRecoveries = player:GetAttribute("KCPhase2Recoveries")
local units, unitDistrict = {}, {}
for _, district in Layout.Districts do for _, id in district.sequences do unitDistrict[id] = district.id end end
for _, item in candidate.Districts:GetDescendants() do
	if item:IsA("Model") then
		local id = item:GetAttribute("SequenceId") or item:GetAttribute("MechanismId")
		if id then assert(not units[id], "Duplicate sequence " .. id); units[id] = item end
	end
end
for _, item in candidate.CheckpointBays:GetChildren() do units[item.Name] = item end
local r: any = {
	active = true, passed = false, candidate = candidate.Name, iteration = candidate:GetAttribute("ConstructionIteration"),
	revision = candidate:GetAttribute("KCPhase2Revision"), prototypeRevision = candidate:GetAttribute("PrototypeRevision"), layoutRevision = Layout.Revision, runId = runId, userId = player.UserId,
	secondsLimit = if requestedLaps == 3 then 600 else 300, requestedLaps = requestedLaps, routeChoice = routeChoice, pairedX02 = pairedX02, arrivalDelaySeconds = arrivalDelay,
	setupCalls = 0, joins = {}, sequences = {}, checkpoints = {}, gates = {}, recoveries = {}, stateChanges = {}, operations = {}, laps = {}, branchComparisons = {},
	fixtureRevision = Factory.Revision,
	districts = {}, sampledPathStuds = 0, diagnosticReads = 0,
	movement = {walkSpeed = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight, useJumpPower = humanoid.UseJumpPower, gravity = workspace.Gravity},
	boundary = "One F00 setup, then ordinary continuous movement. All normal features remain required in normal mode. Complete requested lap count with supported automated paths and actual carrying; no human typicality or crowd/device proof.",
}
shared.KCP2I07Race = r
local driver, worker, monitor
local activeDistrict, currentOperation, lapNumber = "Setup", nil, 0
local seenGates, seenRecoveries = {}, {}
local previousPosition, previousAt, lastDiagnostic, lastState = nil, os.clock(), -math.huge, ""
local function vector(value: Vector3) return {value.X, value.Y, value.Z} end
local function horizontal(value: Vector3) return Vector3.new(value.X, 0, value.Z) end
local function state()
	return {finished = player:GetAttribute("KCPhase2Finished"), at = workspace:GetServerTimeNow(), elapsed = os.clock() - started, runtimeElapsed = candidate:GetAttribute("KCElapsed"),
		root = vector(root.Position), speed = horizontal(root.AssemblyLinearVelocity).Magnitude, floor = humanoid.FloorMaterial.Name,
		nextGate = player:GetAttribute("KCPhase2NextGate"), lap = player:GetAttribute("KCPhase2Lap"), completedLaps = player:GetAttribute("KCPhase2CompletedLaps"),
		recoveries = player:GetAttribute("KCPhase2Recoveries"), participant = player:GetAttribute("KCPhase2Candidate")}
end
local function diagnostics()
	local encoded = candidate:GetAttribute("KCPhase2ServerDiagnostics")
	if type(encoded) ~= "string" then return end
	local ok, data = pcall(Http.JSONDecode, Http, encoded)
	if not ok or type(data) ~= "table" then return end
	r.diagnosticReads += 1
	r.serverState = data.participants and data.participants[tostring(player.UserId)]
	for _, row in data.gates or {} do
		if row.userId == player.UserId and r.continuousServerStartedAt and row.at >= r.continuousServerStartedAt then
			local key = tostring(row.at) .. ":" .. tostring(row.gate)
			if not seenGates[key] then seenGates[key] = true; table.insert(r.gates, row) end
		end
	end
	for _, row in data.recoveries or {} do
		if row.userId == player.UserId and r.continuousServerStartedAt and row.at >= r.continuousServerStartedAt then
			local key = tostring(row.at) .. ":" .. tostring(row.reason)
			if not seenRecoveries[key] then seenRecoveries[key] = true; table.insert(r.recoveries, row) end
		end
	end
end
local function closeOperation(interrupted: boolean?)
	if not currentOperation then return end
	local operation = currentOperation
	operation.elapsed, operation.after, operation.interrupted = os.clock() - operation.beganClock, state(), interrupted == true
	operation.lastRecord = if driver then #driver.Records() else 0
	operation.takeoffSettleSeconds = 0
	if driver then
		for index = operation.firstRecord, operation.lastRecord do
			local record = driver.Records()[index]
			if record.controlHold then operation.takeoffSettleSeconds += record.elapsed or 0 end
		end
	end
	local district = r.districts[operation.district]
	if not district then district = {seconds = 0, sampledPathStuds = 0, categories = {}}; r.districts[operation.district] = district end
	district.seconds += operation.elapsed
	district.takeoffSettleSeconds = (district.takeoffSettleSeconds or 0) + operation.takeoffSettleSeconds
	district.sampledPathStuds += operation.sampledPathStuds
	district.categories[operation.kind] = (district.categories[operation.kind] or 0) + operation.elapsed
	currentOperation = nil
end
local function finish(passed: boolean, failure: string?, cancelWorker: boolean?)
	if not r.active then return end
	r.active, r.passed, r.error = false, passed, failure
	if monitor then monitor:Disconnect() end
	local clean, cleanup = pcall(if driver then driver.Stop else setupProbe.Stop)
	r.cleanup = if clean then cleanup or {unbound = true} else {error = tostring(cleanup)}
	if not clean or type(cleanup) == "table" and (cleanup.unbound == false or cleanup.avatarCleared == false) then r.passed, r.error = false, r.error or "Fixture cleanup failed" end
	local accounted, accountingError = pcall(closeOperation, true)
	if not accounted then r.accountingError = tostring(accountingError) end
	diagnostics()
	r.finalState, r.elapsed, r.records = state(), os.clock() - started, if driver then driver.Records() else {}
	r.airLandingHoldSeconds = 0
	for _, record in r.records do r.airLandingHoldSeconds += record.airLandingHoldSeconds or 0 end
	if r.continuousBeganAt then r.continuousSeconds = os.clock() - r.continuousBeganAt end
	r.accountedContinuousSeconds, r.waitSeconds, r.moveSeconds, r.carrySeconds, r.fixtureHoldSeconds = 0, 0, 0, 0, 0
	r.takeoffSettleSeconds = 0
	for _, operation in r.operations do
		if operation.continuous then
			r.accountedContinuousSeconds += operation.elapsed
			r.takeoffSettleSeconds += operation.takeoffSettleSeconds or 0
			if operation.kind == "move" then r.moveSeconds += operation.elapsed
			elseif operation.kind == "carrying" then r.carrySeconds += operation.elapsed
			elseif operation.kind == "fixtureHold" then r.fixtureHoldSeconds += operation.elapsed
			else r.waitSeconds += operation.elapsed end
		end
	end
	r.unassignedContinuousSeconds = (r.continuousSeconds or 0) - r.accountedContinuousSeconds
	if cancelWorker and worker then task.cancel(worker) end
end
local function guard()
	assert(r.active and os.clock() - started < r.secondsLimit, "Fixture stopped or bounded race deadline")
	assert(candidate.Parent and candidate:GetAttribute("KCPhase2RunId") == runId and candidate:GetAttribute("KCPhase2Stopped") ~= true, "Session changed")
	assert(player.Character == character and root.Parent == character and humanoid.Health > 0 and not root.Anchored, "Character replaced, unavailable or anchored")
	assert(player:GetAttribute("KCPhase2Candidate") == candidate.Name and player:GetAttribute("KCPhase2Recoveries") == initialRecoveries, "Authoritative recovery or participant change")
	assert(math.abs(humanoid.WalkSpeed - 16) < .001 and math.abs(humanoid.JumpHeight - 7.2) < .001 and not humanoid.UseJumpPower and math.abs(workspace.Gravity - 196.2) < .001, "Ordinary movement baseline changed")
end
local function measure(kind: string, label: string, callback)
	guard()
	assert(not currentOperation, "Nested timing operation")
	currentOperation = {kind = kind, label = label, district = activeDistrict, beganClock = os.clock(), before = state(), sampledPathStuds = 0,
		continuous = r.continuousBeganAt ~= nil, lap = lapNumber, firstRecord = if driver then #driver.Records() + 1 else 0}
	table.insert(r.operations, currentOperation)
	local result = callback(currentOperation)
	guard()
	closeOperation(false)
	return result
end
local function contact(bank: Instance): BasePart
	local part = assert(bank:FindFirstChild("BankContact") or bank:FindFirstChild("KeyContact"), "Missing traversal contact " .. bank.Name)
	assert(part:IsA("BasePart")); return part
end
local function endpoint(id: string, departing: boolean): BasePart
	local unit = assert(units[id], "Missing route unit " .. id)
	if unit:FindFirstChild("BankContact") then return contact(unit) end
	return contact(assert(unit:FindFirstChild(if departing then "ExitBank" else "EntryBank") or unit:FindFirstChild(if departing then "Exit" else "Entry")))
end
local function move(label: string, target: Vector3, jumping: boolean, support: BasePart, settings)
	measure("move", label, function() assert(driver.Move(label, target, jumping, support, settings), label) end)
end
local function cross(label: string, from: BasePart, to: BasePart, prepared: Vector3?, arrivalTarget: Vector3?)
	measure("move", label, function() assert(driver.Cross(label, from, to, prepared, arrivalTarget), label) end)
end
local function prepare(label: string, from: BasePart, to: BasePart, toPosition: Vector3?): Vector3
	return measure("move", label .. " prepare", function() return driver.Prepare(label, from, to, toPosition) end)
end
local function waitFor(kind: string, label: string, predicate, seconds: number, observation)
	measure(kind, label, function(operation)
		driver.Hold()
		operation.samples = {}
		if kind == "carrying" then operation.rideUnitId, operation.ridePhaseSeconds = r.currentSequence.id, {} end
		local began, sampled = os.clock(), -math.huge
		while os.clock() - began < seconds do
			guard()
			if predicate() then operation.passed = true; return end
			if observation and os.clock() - sampled >= .2 then
				sampled = os.clock(); table.insert(operation.samples, {t = sampled - began, value = observation()})
			end
			task.wait(.02)
		end
		error("Window timeout: " .. label)
	end)
end
local function tuning(unit: Model)
	local values = Motion.Tuning(unit:GetAttribute("MechanismKind"))
	for key in values do local value = unit:GetAttribute("Timing_" .. key); if value ~= nil then values[key] = value end end
	return values
end
local function window(label: string, unit: Model, index: number, required: number, predicate, kind: string?)
	local values, mechanismKind = tuning(unit), unit:GetAttribute("MechanismKind")
	required += .1
	local function remaining() return Timing.Remaining(mechanismKind, candidate:GetAttribute("KCElapsed") or 0, index, values) end
	waitFor(kind or "hazardAdmission", label, function() return predicate() and remaining() >= required end, 18,
		function() return {state = unit:GetAttribute("CycleState"), runtimeElapsed = candidate:GetAttribute("KCElapsed"), remaining = remaining(), required = required, authoritativeOpen = predicate()} end)
	local operation = r.operations[#r.operations]
	operation.acceptedRemaining, operation.requiredRemaining, operation.acceptedAt = remaining(), required, state()
end
local followingGate = {CP1 = "CP2", CP2 = "CP3", CP3 = "F01", F01 = "F00", F00 = "CP1"}
local function checkpoint(id: string)
	local bay, result = endpoint(id, false), {id = id, lap = lapNumber, before = state()}
	table.insert(r.checkpoints, result)
	local function accepted()
        local finalReturn = id == "F00" and lapNumber == 3
        local expectedNext = if finalReturn then "" else followingGate[id]
        local completed = if id == "F00" then lapNumber else lapNumber - 1
        local expectedLap = if id == "F00" and not finalReturn then lapNumber + 1 else lapNumber
        return player:GetAttribute("KCPhase2NextGate") == expectedNext and player:GetAttribute("KCPhase2CompletedLaps") == completed and player:GetAttribute("KCPhase2Lap") == expectedLap and player:GetAttribute("KCPhase2Finished") == finalReturn
    end
	if not accepted() then
		assert(player:GetAttribute("KCPhase2NextGate") == id, "Unexpected gate at " .. id)
		if bay.CFrame:PointToObjectSpace(root.Position).X > -1 then
			result.reverseCorrection = true
			move(id .. " required upstream gate approach", bay.CFrame:PointToWorldSpace(Vector3.new(-6, 0, 0)), false, bay)
		end
		move(id .. " forward gate crossing", bay.CFrame:PointToWorldSpace(Vector3.new(6, 0, 0)), false, bay)
	end
	waitFor("gateConfirmation", id .. " authoritative acceptance", accepted, 2)
	result.passed, result.after = true, state()
end
local function join(from: string, to: string)
	local links = {}
	for _, bank in candidate.RouteLinks:GetChildren() do
		if bank:GetAttribute("FromSequence") == from and bank:GetAttribute("ToSequence") == to then table.insert(links, bank) end
	end
	table.sort(links, function(a, b) return tonumber(a.Name:match("_(%d+)$")) < tonumber(b.Name:match("_(%d+)$")) end)
	local result: any = {from = from, to = to, lap = lapNumber, connectors = #links, began = os.clock(), before = state()}
	table.insert(r.joins, result)
	local previous = endpoint(from, true)
	for index, bank in links do local target = contact(bank); cross(from .. "→" .. to .. " connector" .. index, previous, target); previous = target end
	local arrival = endpoint(to, false)
	local target = if followingGate[to] then arrival.CFrame:PointToWorldSpace(Vector3.new(-6, 0, 0)) else nil
	cross(from .. "→" .. to .. " arrival", previous, arrival, nil, target)
	result.passed, result.after, result.elapsed = true, state(), os.clock() - result.began
end
local function modelNamed(unit: Model, name: string): Model
	for _, item in unit:GetDescendants() do if item:IsA("Model") and item.Name == name then return item end end
	error("Missing traversal Model " .. name)
end
local function staticSequence(id: string, unit: Model)
	local points = unit.TraversalPoints:GetChildren()
	table.sort(points, function(a, b) return a:GetAttribute("Ordinal") < b:GetAttribute("Ordinal") end)
	local previous = endpoint(id, false)
	for index = 2, #points do
		local point = points[index]
		if id == "O04" and point.Name == "EnterTurn" then
			local stem = contact(modelNamed(unit, "EnterStem"))
			move("O04 Enter hairpin turn", stem.Position - stem.CFrame.LookVector * 5.25, false, stem)
		else
			local target = contact(modelNamed(unit, point.Name))
			if point:GetAttribute("JumpFromPrevious") then cross(id .. " " .. point.Name, previous, target) else move(id .. " " .. point.Name, target.Position, false, target) end
			previous = target
		end
	end
end
local function mechanism(id: string, unit: Model)
	local entry, exit = endpoint(id, false), endpoint(id, true)
	if id == "H02" then
		cross("H02 first seesaw", entry, contact(unit.Spacebar1)); cross("H02 second seesaw", contact(unit.Spacebar1), contact(unit.Spacebar2)); cross("H02 exit", contact(unit.Spacebar2), exit)
	elseif id == "H03" then
		local values, lane, soonest = tuning(unit), 1, math.huge
		for candidateLane = 1, 2 do
			local candidateFirst = contact(unit["Lane" .. candidateLane .. "Row1"])
			local approach = horizontal(candidateFirst.Position - entry.Position).Unit
			local preparation = horizontal(Factory.Edge(entry, approach, 1.25) - root.Position).Magnitude / 16 + .1
			local elapsed = (candidate:GetAttribute("KCElapsed") or 0) + preparation
			local phase = (elapsed - (candidateLane - 1) * values.LaneOffset) % values.Period
			local expectedWait = if phase < values.Open - values.CrossingAllowance - .1 then 0 else values.Period - phase
			if expectedWait < soonest then lane, soonest = candidateLane, expectedWait end
		end
		r.currentSequence.selectedLane = lane
		local firstBank = unit["Lane" .. lane .. "Row1"]
		local first = contact(firstBank)
		local direction = prepare("H03 first row", entry, first)
		window("H03 lane" .. lane .. " admission", unit, lane, values.CrossingAllowance, function() return firstBank:GetAttribute("AdmissionOpen") == true end)
		cross("H03 row1", entry, first, direction)
		local previous = first
		for row = 2, 3 do local target = contact(unit["Lane" .. lane .. "Row" .. row]); cross("H03 row" .. row, previous, target); previous = target end
		cross("H03 exit", previous, exit)
	elseif id == "H04" then
		local crossing, frame = contact(unit.CrossingBank), unit:GetAttribute("EncounterFrame")
		local direction = prepare("H04 entry", entry, crossing)
		window("H04 first zone clearance", unit, 1, 1.5, function() return unit.Drop1:GetAttribute("CycleState") == "Clear" end)
		cross("H04 entry to crossing", entry, crossing, direction)
		-- Keep stopping and turning body room between the falling-key contact volumes.
		local waitSettings = {precision = true, tolerance = .15, stopRadius = .1, holdOnArrival = true}
		move("H04 first inter-zone wait position", frame:PointToWorldSpace(Vector3.new(-5.25, -.575, 0)), false, crossing, waitSettings)
		waitFor("hazardAdmission", "H04 first wait-position standstill", function() return horizontal(root.AssemblyLinearVelocity).Magnitude < .5 end, .8)
		window("H04 middle zone clearance", unit, 2, 1.3, function() return unit.Drop2:GetAttribute("CycleState") == "Clear" end)
		move("H04 second inter-zone wait position", frame:PointToWorldSpace(Vector3.new(5.25, -.575, 0)), false, crossing, waitSettings)
		waitFor("hazardAdmission", "H04 second wait-position standstill", function() return horizontal(root.AssemblyLinearVelocity).Magnitude < .5 end, .8)
		window("H04 final zone clearance", unit, 3, 2, function() return unit.Drop3:GetAttribute("CycleState") == "Clear" end)
		cross("H04 exit", crossing, exit)
	elseif id == "H05" or id == "H06" then
		local ride = contact(unit.RideableBank)
		local direction = prepare(id .. " board", entry, ride)
		if id == "H06" then window("H06 boardable departure", unit, 1, 1.2, function() return unit:GetAttribute("BoardingWindow") == true end, "boardingAdmission")
		else waitFor("boardingAdmission", "H05 boardable lift", function() return unit:GetAttribute("BoardingWindow") == true end, 18) end
		cross(id .. " board", entry, ride, direction)
		driver.Hold()
		local boarded = root.Position
		waitFor("carrying", id .. " physical carrying", function() return unit:GetAttribute("ExitWindow") == true end, 12,
			function() return {root = vector(root.Position), relative = vector(ride.CFrame:PointToObjectSpace(root.Position)), slider = unit.Slider.CurrentPosition, cycle = unit:GetAttribute("CycleState")} end)
		local gain, distance = root.Position.Y - boarded.Y, (root.Position - boarded).Magnitude
		assert(if id == "H05" then gain > 5 else distance > 12, id .. " actual carrying required")
		table.insert(r.currentSequence.rides, {verticalGain = gain, carriedDistance = distance})
		cross(id .. " exit", ride, exit)
	elseif id == "H07" then
		local crossing = contact(unit.CrossingBank)
		local direction = prepare("H07 entry", entry, crossing)
		window("H07 safe rest approach", unit, 1, 2.2, function() return unit.SweepArm:GetAttribute("CycleState") == "Rest" end)
		cross("H07 approach", entry, crossing, direction)
		move("H07 supported corridor takeoff", crossing.Position, false, crossing, {tolerance = .25})
		move("H07 low-arm corridor jump", unit:GetAttribute("EncounterFrame"):PointToWorldSpace(Vector3.new(8, .425, 0)), true, crossing, {seconds = 4, tolerance = .4})
		cross("H07 exit", crossing, exit)
	elseif id == "H08" then
		local previous = entry
		for index = 1, 4 do
			local target = contact(unit["PassageBank" .. index])
			local direction = prepare("H08 passage" .. index, previous, target)
			if index > 1 then local panel = unit["DominoPanel" .. (index - 1)]; window("H08 passage" .. index .. " admission", unit, index - 1, 1.2, function() return panel:GetAttribute("AdmissionOpen") == true end) end
			cross("H08 passage" .. index, previous, target, direction); previous = target
		end
		cross("H08 exit", previous, exit)
	elseif id == "H01" then
		local middle, first, second = contact(unit.PermanentCtrlRefuge), contact(unit.ShiftBridge1), contact(unit.ShiftBridge2)
		local frame = unit:GetAttribute("EncounterFrame")
		local direction = prepare("H01 first Shift", entry, first, frame:PointToWorldSpace(Vector3.new(-13, 0, 0)))
		window("H01 first admission", unit, 1, tuning(unit).CrossingAllowance, function() return unit.ShiftBridge1:GetAttribute("AdmissionOpen") == true end)
		cross("H01 first Shift", entry, first, direction); cross("H01 Ctrl refuge", first, middle)
		direction = prepare("H01 second Shift", middle, second, frame:PointToWorldSpace(Vector3.new(13, 0, 0)))
		window("H01 second admission", unit, 2, tuning(unit).CrossingAllowance, function() return unit.ShiftBridge2:GetAttribute("AdmissionOpen") == true end)
		cross("H01 second Shift", middle, second, direction); cross("H01 exit", second, exit)
	else error("Unexpected mechanism " .. id) end
end
local function startBranchComparison()
	if not pairedX02 then return end
	local bank = endpoint("H07", true)
	move("X02 paired common departure", bank.Position, false, bank, {tolerance = .25})
	waitFor("fixtureHold", "X02 paired standstill", function() return horizontal(root.AssemblyLinearVelocity).Magnitude < .5 end, 2)
	r.branchComparison = {route = routeChoice, lap = lapNumber, beganClock = os.clock(), before = state()}
	table.insert(r.branchComparisons, r.branchComparison)
end
local function expertBranch(expertId: string, fromId: string, checkpointId: string)
    local expert
    for _, item in candidate.ExpertRoutes:GetChildren() do if item:GetAttribute("ExpertId") == expertId then assert(not expert); expert = item end end
    assert(expert and expert:GetAttribute("BranchAfter") == fromId and expert:GetAttribute("MergeBefore") == checkpointId, "Actual expert branch contract required")
    local caps = {}
    for _, marker in expert.TraversalPoints:GetChildren() do table.insert(caps, {ordinal = marker:GetAttribute("Ordinal"), contact = contact(expert["PrecisionLanding" .. marker.Name])}) end
    table.sort(caps, function(a, b) return a.ordinal < b.ordinal end)
    assert(#caps == Layout.BranchGeometry[expertId].landings, "Every expert precision landing is required")
    local result: any = {id = expertId, lap = lapNumber, before = state(), began = os.clock(), landings = #caps, rides = {}}
    table.insert(r.sequences, result)
    local previous = endpoint(fromId, true)
    for _, cap in caps do cross(expertId .. " cap" .. cap.ordinal, previous, cap.contact); previous = cap.contact end
    local bay = endpoint(checkpointId, false)
    cross(expertId .. " " .. checkpointId .. " merge", previous, bay, nil, assert(expert:GetAttribute("PrecisionMergePosition")))
    move(expertId .. " supported upstream merge approach", bay.CFrame:PointToWorldSpace(Vector3.new(-6, 0, 0)), false, bay)
    result.passed, result.after, result.elapsed = true, state(), os.clock() - result.began
    checkpoint(checkpointId)
end

r.serverStartedAt = workspace:GetServerTimeNow()
monitor = RunService.Heartbeat:Connect(function()
	if not r.active then return end
	local ok, failure = pcall(guard)
	if not ok then finish(false, tostring(failure), true); return end
	if r.cancelRequested then finish(false, "Fixture cancelled", true); return end
	local now = os.clock()
	if r.continuousBeganAt then
		if previousPosition then
			local delta = horizontal(root.Position - previousPosition).Magnitude
			if currentOperation and currentOperation.kind == "carrying" then
				local phase = units[currentOperation.rideUnitId]:GetAttribute("CycleState") or "Unknown"
				currentOperation.ridePhaseSeconds[phase] = (currentOperation.ridePhaseSeconds[phase] or 0) + now - previousAt
			end
			if now - previousAt <= .5 and (root.Position - previousPosition).Magnitude > math.max(12, (now - previousAt) * 80) then finish(false, "Unexpected position discontinuity", true); return end
			r.sampledPathStuds += delta
			if currentOperation then currentOperation.sampledPathStuds += delta end
		end
		previousPosition, previousAt = root.Position, now
	end
	local signature = tostring(player:GetAttribute("KCPhase2NextGate")) .. ":" .. tostring(player:GetAttribute("KCPhase2CompletedLaps")) .. ":" .. tostring(player:GetAttribute("KCPhase2Recoveries"))
	if signature ~= lastState then lastState = signature; table.insert(r.stateChanges, state()); diagnostics() end
	if now - lastDiagnostic >= .5 then lastDiagnostic = now; diagnostics() end
end)
worker = task.spawn(function()
	local ok, failure = xpcall(function()
		assert(player:GetAttribute("KCPhase2NextGate") == "CP1" and player:GetAttribute("KCPhase2CompletedLaps") == 0 and player:GetAttribute("KCPhase2Lap") == 1 and type(initialRecoveries) == "number", "Prepare a fresh active participant; fixture never calls Begin/Restart")
		assert(#Layout.Main == 21 and #Layout.Sequences == 16 and Layout.Main[1] == "F00", "Current route contract required")
		guard()
		r.setupCalls += 1; r.setup = setupProbe.Place(endpoint("F00", false))
		assert(r.setup.attempts == 1, "Repeated setup must not become a pacing pass")
		setupProbe.Stop()
		driver = Factory.New(candidate, player, guard)
		if arrivalDelay > 0 then
			local delayBegan = os.clock()
			waitFor("arrivalOffset", "F00 controlled arrival offset", function() return os.clock() - delayBegan >= arrivalDelay end, arrivalDelay + 1)
		end
		r.startState, r.continuousBeganAt, r.continuousServerStartedAt = state(), os.clock(), workspace:GetServerTimeNow()
		previousPosition, previousAt = root.Position, os.clock()
        for requestedLap = 1, requestedLaps do
            lapNumber = requestedLap
            r.branchComparison = nil
            local lap: any = {number = lapNumber, beganClock = os.clock(), before = state(), firstOperation = #r.operations + 1,
                firstJoin = #r.joins + 1, firstSequence = #r.sequences + 1, firstCheckpoint = #r.checkpoints + 1}
            table.insert(r.laps, lap)
            local index = 1
            while index <= #Layout.Main do
                local id, after = Layout.Main[index], Layout.Main[index % #Layout.Main + 1]
                activeDistrict = if id == "F01" then "Return" else unitDistrict[after] or unitDistrict[id] or "Return"
                local chosenBranch
                if routeChoice == "expert" then for _, branch in Layout.Branches do if branch.from == id then chosenBranch = branch; break end end end
                if chosenBranch then
                    expertBranch(chosenBranch.id, chosenBranch.from, chosenBranch.before)
                    index = assert(table.find(Layout.Main, chosenBranch.before))
                else
                    join(id, after)
                    if followingGate[after] then checkpoint(after)
                    else
                        local result: any = {id = after, lap = lapNumber, before = state(), began = os.clock(), rides = {}}
                        table.insert(r.sequences, result); r.currentSequence = result
                        local unit = assert(units[after])
                        if unit:GetAttribute("MechanismId") then mechanism(after, unit) else staticSequence(after, unit) end
                        result.passed, result.after, result.elapsed = true, state(), os.clock() - result.began
                    end
                    index += 1
                end
                if r.branchComparison and not r.branchComparison.elapsed and player:GetAttribute("KCPhase2NextGate") == "F01" then
                    r.branchComparison.elapsed, r.branchComparison.after = os.clock() - r.branchComparison.beganClock, state()
                end
            end
            waitFor("gateConfirmation", "lap " .. lapNumber .. " authoritative gate receipt", function() diagnostics(); return #r.gates >= lapNumber * 5 end, 2)
            local expectedJoins = if routeChoice == "expert" then 5 else 21
            local expectedSequences = if routeChoice == "expert" then 8 else 16
            assert(#r.joins - lap.firstJoin + 1 == expectedJoins and #r.sequences - lap.firstSequence + 1 == expectedSequences and #r.checkpoints - lap.firstCheckpoint + 1 == 5, "Incomplete lap traversal")
            local completed = {}
            for sequenceIndex = lap.firstSequence, #r.sequences do
                local sequence = r.sequences[sequenceIndex]
                assert(sequence.passed and not completed[sequence.id], "Duplicate or failed sequence"); completed[sequence.id] = true
            end
            for _, id in Layout.Sequences do
                local intentionalBranch = false
                if routeChoice == "expert" then for _, branch in Layout.Branches do if table.find(branch.skips,id) then intentionalBranch = true end end end
                assert(completed[id] or intentionalBranch, "Missing retained sequence " .. id)
            end
            if routeChoice == "expert" then for _, branch in Layout.Branches do assert(completed[branch.id], "Missing precision branch " .. branch.id) end end
            for gateIndex, gate in {"CP1", "CP2", "CP3", "F01", "F00"} do assert(r.gates[(lapNumber - 1) * 5 + gateIndex].gate == gate, "Authoritative gate order mismatch") end
            lap.passed, lap.after, lap.elapsed, lap.lastOperation = true, state(), os.clock() - lap.beganClock, #r.operations
            lap.districts, lap.takeoffSettleSeconds = {}, 0
            for operationIndex = lap.firstOperation, lap.lastOperation do
                local operation = r.operations[operationIndex]
                local portion = lap.districts[operation.district]
                if not portion then portion = {seconds = 0, sampledPathStuds = 0, categories = {}}; lap.districts[operation.district] = portion end
                portion.seconds += operation.elapsed; portion.sampledPathStuds += operation.sampledPathStuds
                portion.takeoffSettleSeconds = (portion.takeoffSettleSeconds or 0) + (operation.takeoffSettleSeconds or 0)
                lap.takeoffSettleSeconds += operation.takeoffSettleSeconds or 0
                portion.categories[operation.kind] = (portion.categories[operation.kind] or 0) + operation.elapsed
            end
        end
        assert(#r.gates == requestedLaps * 5 and player:GetAttribute("KCPhase2CompletedLaps") == requestedLaps, "Incomplete authoritative race")
        assert(if requestedLaps == 3 then player:GetAttribute("KCPhase2Finished") == true and player:GetAttribute("KCPhase2NextGate") == "" and player:GetAttribute("KCPhase2Lap") == 3 else player:GetAttribute("KCPhase2Finished") ~= true and player:GetAttribute("KCPhase2NextGate") == "CP1" and player:GetAttribute("KCPhase2Lap") == 2, "Wrong terminal progression state")
        r.automatedSecondsBeforeCleanup = os.clock() - r.continuousBeganAt
        r.targetSeconds = if routeChoice == "expert" then {40 * requestedLaps, 60 * requestedLaps} else if routeChoice == "normal" then {80 * requestedLaps, 120 * requestedLaps} else nil
        r.withinPlanningTarget = if r.targetSeconds then r.automatedSecondsBeforeCleanup >= r.targetSeconds[1] and r.automatedSecondsBeforeCleanup <= r.targetSeconds[2] else nil
        r.proof = if requestedLaps == 3 then "Three continuous automated laps with fifteen ordered natural server gates" else "One continuous automated measurement lap; no three-lap completion claim"

		guard()
	end, debug.traceback)
	finish(ok, if ok then nil else tostring(failure), false)
end)
return {started = true, report = "shared.KCP2I07Race", secondsLimit = r.secondsLimit, requestedLaps = requestedLaps, routeChoice = routeChoice, arrivalDelaySeconds = arrivalDelay, boundary = r.boundary}
