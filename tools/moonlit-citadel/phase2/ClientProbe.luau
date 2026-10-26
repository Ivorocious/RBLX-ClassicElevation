--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local Probe = {}
local activeHandle
local lastReport
local FINISH_SETTLE_SECONDS = 0.5
local finishBodyNames = {Head = true, UpperTorso = true, LowerTorso = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true}

local function finishDecision(checks, age)
	if not checks.directed or age > FINISH_SETTLE_SECONDS then return "Failed" end
	if checks.ordered and checks.bodyContact and checks.anchored then return "Ready" end
	return if age <= FINISH_SETTLE_SECONDS then "Wait" else "Failed"
end

local function finishBroadcastMatches(payload, userId, raceId)
	return type(payload) == "table" and raceId ~= "" and payload.raceId == raceId
		and payload.userId == userId and payload.status == "Finished"
end

local function serverFinishContactValid(contact, expected)
	if type(contact) ~= "table" then return false, {present = false} end
	local at = contact.at
	local checks = {present = true, source = contact.source == "actual-server-Finish.Touched",
		course = contact.coursePath == expected.coursePath and contact.courseId == expected.courseId and contact.candidate == expected.candidate,
		race = expected.raceId ~= "" and contact.raceId == expected.raceId, player = contact.userId == expected.userId,
		body = finishBodyNames[contact.partName] == true and contact.partPath == expected.characterPath .. "." .. tostring(contact.partName),
		officialCheckpoint = contact.official == true and contact.checkpoint == 4,
		status = contact.status == "Racing" or contact.status == "Finished",
		fresh = type(at) == "number" and at == at and at >= expected.startedAt
			and at <= expected.observedAt + 0.05 and at <= expected.now + 0.05 and expected.now - at <= 1.5}
	for _, passed in checks do if not passed then return false, checks end end
	return true, checks
end

local function characters()
	local result = {}
	for _, player in Players:GetPlayers() do if player.Character then table.insert(result, player.Character) end end
	return result
end

local function xyz(value) return {value.X, value.Y, value.Z} end
local function resolve(course, path)
	local item = course
	for name in string.gmatch(path, "[^/]+") do item = assert(item:FindFirstChild(name), "Missing route path " .. path) end
	return item
end
local function surface(course, path)
	local item = resolve(course, path)
	if not item:IsA("BasePart") then item = item:FindFirstChild("Contact", true) end
	assert(item and item:IsA("BasePart") and item.CanCollide, "Expected actual collidable support " .. path)
	return item
end
local function top(part, offset)
	return part.CFrame:PointToWorldSpace(Vector3.new(0, part.Size.Y / 2, 0) + (offset or Vector3.zero))
end

function Probe.Start(course, nodes, options)
	assert(RunService:IsStudio() and RunService:IsClient(), "Studio client only")
	assert(not activeHandle, "Stop the current probe before starting another")
	options = options or {}
	local crownLaneOffset = options.crownLaneOffset or 0
	local liftLaneOffset = options.liftLaneOffset or 0
	assert(typeof(liftLaneOffset) == "number" and liftLaneOffset == liftLaneOffset
		and math.abs(liftLaneOffset) <= 3, "Use a lift standing lane within3studs")
	assert(typeof(crownLaneOffset) == "number" and crownLaneOffset == crownLaneOffset
		and math.abs(crownLaneOffset) <= 2.5, "Crown lane offset must be finite and within2.5studs")
	assert(typeof(course) == "Instance" and course:IsDescendantOf(workspace), "Use the actual active shared course")
	assert(course:GetAttribute("CandidateId") == Config.CandidateId, "Wrong candidate")
	assert(type(nodes) == "table" and #nodes > 0, "Supply Layout.GetRoute nodes copied to this client")
	local player = Players.LocalPlayer
	local character = assert(player.Character, "No character")
	local humanoid = assert(character:FindFirstChildOfClass("Humanoid"), "No humanoid")
	local body = assert(character:FindFirstChild("HumanoidRootPart"), "No root part")
	local startClock = os.clock()
	local trace = {candidate = Config.CandidateId, choices = options.choices, bays = options.bays,
		source = "Ordinary Humanoid movement in shared race", directedClockOnly = true, complete = false,
		state = "Starting", steps = {}, contacts = {}, movementGoals = {}, catchReturns = {}, crownLaneOffset = crownLaneOffset, liftLaneOffset = liftLaneOffset,
		startedAt = workspace:GetServerTimeNow(),
		requirements = {lanternBands = {}, rides = {}, checkpoints = {}},
		profile = {rig = humanoid.RigType.Name, walkSpeed = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight,
			useJumpPower = humanoid.UseJumpPower, maxSlopeAngle = humanoid.MaxSlopeAngle, gravity = workspace.Gravity}}
	lastReport = trace
	local cancelled, goal, connections = nil, nil, {}
	local jumpRequest = false
	local initial, currentNode, terminalReached, finishPendingAt, latestRaceStatus, latestProgress = nil, nil, false, nil, nil, nil
	local nextRecordedCheckpoint = 1
	local usedCatchRoutes = {}
	local finishTrigger = assert(course:FindFirstChild("Finish"), "Actual shared Finish trigger missing")
	assert(finishTrigger:IsA("BasePart"), "Shared Finish must be a BasePart")
	local renderName = "MoonlitPhase2Probe_" .. tostring(player.UserId)
	local handle = {}
	local function progress()
		local encoded = player:GetAttribute("MCPhase2Progress")
		assert(type(encoded) == "string", "Install ServerProbe observer before actual shared staging")
		local ok, current = pcall(HttpService.JSONDecode, HttpService, encoded)
		assert(ok and current.source == "shared-services", "Invalid shared progress observer")
		assert(workspace:GetServerTimeNow() - current.observedAt <= 1.5, "Shared observer is stale")
		return current
	end
	local function terminalEligible()
		if not currentNode then return false end
		local crown = currentNode.path:match("^Obstacles/CrownApproach/") ~= nil
		local final = currentNode.finish == true and currentNode.path == "Obstacles/Crown/CrownTerrace/Contact"
		local required = trace.requirements
		return (crown or final) and nextRecordedCheckpoint == 5
			and required.lanternBands[1] and required.lanternBands[2] and required.lanternBands[3]
			and required.rides.Lower ~= nil and required.rides.Upper ~= nil
	end
	local function insideFinish()
		local point = finishTrigger.CFrame:PointToObjectSpace(body.Position)
		return math.abs(point.X) <= finishTrigger.Size.X / 2 + body.Size.X / 2 + 1
			and math.abs(point.Y) <= finishTrigger.Size.Y / 2 + body.Size.Y / 2 + 1
			and math.abs(point.Z) <= finishTrigger.Size.Z / 2 + body.Size.Z / 2 + 1
	end
	local function orderedFinal(current)
		if current.status ~= "Finished" or not current.finished or current.checkpoint ~= 4
			or current.falls ~= 0 or current.requiredLaps ~= 1 or #current.splits ~= 4 then return false end
		for index, split in current.splits do if split.checkpoint ~= index or split.lap ~= 1 then return false end end
		return true
	end
	local function finishSnapshot(current)
		local parts, geometry = {}, {}
		for _, part in character:GetChildren() do
			if part:IsA("BasePart") and finishBodyNames[part.Name] then
				if part.CanQuery and part.Transparency < 1 then table.insert(parts, part) end
				local minimum, maximum = Vector3.one * math.huge, Vector3.one * -math.huge
				for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
					local point = finishTrigger.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2))
					minimum, maximum = minimum:Min(point), maximum:Max(point)
				end end end
				table.insert(geometry, {name = part.Name, position = xyz(part.Position), size = xyz(part.Size),
					triggerLocalMin = xyz(minimum), triggerLocalMax = xyz(maximum), canQuery = part.CanQuery, transparency = part.Transparency})
			end
		end
		local params = OverlapParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, parts
		local contacts = {}
		for _, part in workspace:GetPartsInPart(finishTrigger, params) do table.insert(contacts, part.Name) end
		local serverContact, serverContactChecks = serverFinishContactValid(current and current.finishContact, {
			coursePath = course:GetFullName(), courseId = Config.CourseId, candidate = Config.CandidateId,
			raceId = current and current.raceId or "", userId = player.UserId, characterPath = character:GetFullName(),
			startedAt = trace.startedAt, observedAt = current and current.observedAt or 0, now = workspace:GetServerTimeNow()})
		local checks = {directed = terminalEligible() == true, ordered = current ~= nil and orderedFinal(current) == true,
			bodyContact = #contacts > 0 or serverContact, anchored = body.Anchored}
		return {checks = checks, elapsed = os.clock() - startClock, serverTime = workspace:GetServerTimeNow(),
			pendingSeconds = finishPendingAt and os.clock() - finishPendingAt or 0,
			node = currentNode and currentNode.name, nodePath = currentNode and currentNode.path, waiting = trace.waiting,
			shared = current, broadcast = latestRaceStatus, rootPosition = xyz(body.Position), rootSize = xyz(body.Size),
			rootTriggerLocal = xyz(finishTrigger.CFrame:PointToObjectSpace(body.Position)), rootHeuristicInside = insideFinish(),
			velocity = xyz(body.AssemblyLinearVelocity), humanoidState = humanoid:GetState().Name, floor = humanoid.FloorMaterial.Name,
			trigger = finishTrigger:GetFullName(), triggerPosition = xyz(finishTrigger.Position), triggerSize = xyz(finishTrigger.Size),
			bodyContacts = contacts, clientBodyContact = #contacts > 0, serverBodyContact = serverContact,
			serverFinishContact = current and current.finishContact, serverFinishContactChecks = serverContactChecks,
			contactProofSource = if serverContact then "actual-server-Finish.Touched" elseif #contacts > 0 then "actual-client-GetPartsInPart" else nil,
			bodyGeometry = geometry, nextRecordedCheckpoint = nextRecordedCheckpoint,
			requirements = trace.requirements, characterUnchanged = player.Character == character,
			characterSerialUnchanged = not initial or (current and current.characterSerial == initial.characterSerial),
			recoveryUnchanged = not initial or character:GetAttribute("RecoveryUntil") == initial.recoveryUntil}
	end
	local function guard()
		assert(not cancelled, cancelled or "Cancelled")
		assert(os.clock() - startClock <= (options.watchdogSeconds or 600), "Probe watchdog expired")
		assert(player.Character == character and humanoid.Health > 0, "Character replaced or died")
		assert(humanoid.RigType == Enum.HumanoidRigType.R15, "Clean course proof requires the selected supported R15 avatar")
		assert(course:IsDescendantOf(workspace) and course:GetAttribute("CandidateId") == Config.CandidateId, "Course exited or changed")
		local current = progress()
		latestProgress = current
		assert(current.candidate == Config.CandidateId and current.courseId == Config.CourseId, "Shared course selection changed")
		assert(current.coursePath == course:GetFullName(), "Probe model is not the actual active course")
		assert(current.official and current.staged, "Player did not enter as an official staged racer")
		assert(current.raceId ~= "" and (not initial or current.raceId == initial.raceId), "Shared race ID changed")
		local eligible = terminalEligible()
		local broadcastFinish = eligible and finishBroadcastMatches(latestRaceStatus, player.UserId, current.raceId)
		local finishSignal = current.finished or current.status == "Finished" or broadcastFinish
		local finishEvidence
		if finishSignal or finishPendingAt or (eligible and body.Anchored) then
			finishEvidence = finishSnapshot(current)
		end
		if finishSignal or (finishEvidence and eligible and body.Anchored and finishEvidence.checks.bodyContact) then
			if not finishPendingAt then
				finishPendingAt = os.clock()
				trace.terminalGuard = {first = finishEvidence, settleSeconds = FINISH_SETTLE_SECONDS, samples = 0}
				trace.finishEntry = {node = currentNode and currentNode.name, path = currentNode and currentNode.path, elapsed = os.clock() - startClock,
					position = xyz(body.Position), trigger = finishTrigger:GetFullName(), bridgeStatus = current.status}
			end
			goal = nil
			jumpRequest = false
			humanoid.Jump = false
			humanoid:Move(Vector3.zero, false)
		end
		if finishPendingAt and not terminalReached then
			-- Shared result, body contact and movement lock can replicate in different orders.
			trace.terminalGuard.samples += 1
			trace.terminalGuard.latest = finishEvidence
			local decision = finishDecision(finishEvidence.checks, os.clock() - finishPendingAt)
			trace.terminalGuard.decision = decision
			if decision == "Failed" then trace.failureSnapshot = finishEvidence; error("Early, unordered or misplaced shared finish after bounded settling") end
			terminalReached = decision == "Ready"
		end
		local pending = finishPendingAt ~= nil and not terminalReached
		assert(current.raceState == "Racing" or terminalReached or pending, "Shared race stopped")
		assert(current.status == "Racing" or terminalReached or (pending and current.status == "Finished"), "Player race status changed")
		if latestRaceStatus and initial and latestRaceStatus.raceId == initial.raceId then
			assert(latestRaceStatus.status == "Racing" or (eligible and latestRaceStatus.status == "Finished"), "Server broadcast changed player status")
		end
		if initial then
			assert(current.falls == initial.falls, "Unrequested shared fall recovery")
			assert(current.characterSerial == initial.characterSerial, "Server observed character replacement")
			assert(character:GetAttribute("RecoveryUntil") == initial.recoveryUntil, "Recovery interrupted the route")
		end
		assert(math.abs(workspace.Gravity - 196.2) < 0.001, "Wrong gravity profile")
		if not terminalReached and not pending then
			assert(humanoid.WalkSpeed == 16 and humanoid.UseJumpPower == false and math.abs(humanoid.JumpHeight - 7.2) < 0.001,
				"Expected ordinary speed16 / jump-height7.2")
			assert(humanoid.MaxSlopeAngle == 45, "Wrong slope profile")
		end
		return current
	end
	local function contact()
		if humanoid.FloorMaterial == Enum.Material.Air then return nil end
		local params = RaycastParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, characters()
		params.RespectCanCollide = true
		local leg = character:FindFirstChild("Left Leg")
		local r6Height = if humanoid.RigType == Enum.HumanoidRigType.R6 and leg then leg.Size.Y else 0
		local hit = workspace:Raycast(body.Position,
			Vector3.new(0, -(humanoid.HipHeight + r6Height + body.Size.Y / 2 + 1.1), 0), params)
		if hit and hit.Normal.Y >= math.cos(math.rad(45.5)) then return hit.Instance, hit.Position end
		return nil
	end
	local function groundedOn(expected)
		local hit, point = contact()
		if hit == expected then return true end
		if expected.Name == "Deck" or not hit or not hit:IsDescendantOf(course) then return false end
		local role = hit:GetAttribute("Role")
		if not hit:GetAttribute("MCWalkable") and role ~= "WalkableSurface" and role ~= "Walkable" and role ~= "SafeRefuge" and role ~= "Contact" then return false end
		local localPoint = expected.CFrame:PointToObjectSpace(point)
		return math.abs(localPoint.X) <= expected.Size.X / 2 + 0.4 and math.abs(localPoint.Z) <= expected.Size.Z / 2 + 0.4
			and math.abs(localPoint.Y - expected.Size.Y / 2) <= 0.65
	end
	local function record(name, expected, extra)
		local hit, point = contact()
		local current = progress()
		table.insert(trace.steps, {name = name, section = trace.section, elapsed = os.clock() - startClock,
			position = xyz(body.Position), velocity = xyz(body.AssemblyLinearVelocity), state = humanoid:GetState().Name,
			ground = humanoid.FloorMaterial.Name, support = hit and hit:GetFullName(), supportPoint = point and xyz(point),
			expected = expected and expected:GetFullName(), actualExpectedSupport = expected and groundedOn(expected),
			checkpoint = current.checkpoint, falls = current.falls, status = current.status, extra = extra})
	end
	local function await(name, test, seconds)
		trace.waiting = name
		local deadline = os.clock() + seconds
		repeat
			guard()
			if terminalReached then trace.waiting = nil; return end
			if finishPendingAt then task.wait(0.025); continue end
			if test() then trace.waiting = nil; return end
			task.wait(0.025)
		until os.clock() >= deadline
		error("Timed out " .. name .. " at " .. tostring(trace.section))
	end
	local function pause(seconds, expected, name)
		local untilClock = os.clock() + seconds
		await(name, function()
			assert(groundedOn(expected), "Lost real support while waiting " .. name)
			return os.clock() >= untilClock
		end, seconds + 1)
		if terminalReached then return end
		record(name, expected)
	end
	local function horizontalDistance(target)
		return Vector3.new(body.Position.X - target.X, 0, body.Position.Z - target.Z).Magnitude
	end
	local function move(expected, offset, name, kind, seconds, drop)
		guard()
		if terminalReached then return end
		local actualOffset = offset or Vector3.zero
		local appliedCrownOffset = if currentNode and currentNode.path:match("^Obstacles/CrownApproach/") then crownLaneOffset else 0
		actualOffset += Vector3.new(appliedCrownOffset, 0, 0)
		table.insert(trace.movementGoals, {name = name, nodePath = currentNode and currentNode.path,
			supportPath = expected:GetFullName(), localOffset = xyz(actualOffset), crownLaneOffset = appliedCrownOffset,
			goal = xyz(top(expected, actualOffset)), elapsed = os.clock() - startClock})
		if kind == "Jump" then
			assert(contact(), "Jump has no real takeoff support")
			record(name .. "Takeoff")
		end
		goal = function() return top(expected, actualOffset) end
		if kind == "Jump" then jumpRequest = true; humanoid.Jump = true end
		if kind == "Jump" then
			await(name .. "ActualTakeoff", function()
				return humanoid.FloorMaterial == Enum.Material.Air and body.AssemblyLinearVelocity.Y > 1
			end, 0.6)
			jumpRequest = false
			humanoid.Jump = false
			if terminalReached then return end
		elseif drop then
			await(name .. "ActualDrop", function()
				return humanoid.FloorMaterial == Enum.Material.Air and body.AssemblyLinearVelocity.Y < -1
			end, seconds or 6)
			if terminalReached then return end
			record(name .. "AirborneDrop", expected)
		end
		await(name .. "Reach", function() return horizontalDistance(goal()) <= (options.goalTolerance or 1.05) end, seconds or 8)
		if terminalReached then return end
		goal = nil
		jumpRequest = false
		humanoid.Jump = false
		humanoid:Move(Vector3.zero, false)
		await(name .. "ActualLanding", function() return groundedOn(expected) end, 2)
		if terminalReached then return end
		record(name .. (if kind == "Jump" then "Landing" else ""), expected)
	end
	local function lanternGate(node)
		if not node.lanternBand then return end
		local lantern = resolve(course, node.lanternPath or ("Obstacles/SwingLanterns/SwingBand" .. node.lanternBand))
		local visible = assert(lantern:FindFirstChild("CageAndCore", true), "Missing actual visible cage/core group")
		assert(visible:IsA("Model") and visible:FindFirstChildWhichIsA("BasePart", true), "No actual visible cage parts")
		local landing = surface(course, node.path)
		local target = top(landing, node.offset)
		local previousDistance
		local clearance = node.lanternClearance or 7.5
		await("Visible lantern " .. node.lanternBand .. " clear", function()
			local from = Vector3.new(body.Position.X, 0, body.Position.Z)
			local to = Vector3.new(target.X, 0, target.Z)
			local frame = visible:GetBoundingBox()
			local point = Vector3.new(frame.Position.X, 0, frame.Position.Z)
			local line = to - from
			local alpha = if line.Magnitude > 0.01 then math.clamp((point - from):Dot(line) / line:Dot(line), 0, 1) else 0
			local distance = (point - (from + line * alpha)).Magnitude
			if previousDistance == nil then previousDistance = distance; return false end
			local away = distance > previousDistance
			previousDistance = distance
			return distance >= clearance and away
		end, node.lanternTimeout or 20)
		local frame = visible:GetBoundingBox()
		record("LanternBand" .. node.lanternBand .. "Window", nil, {cage = visible:GetFullName(), position = xyz(frame.Position)})
		trace.requirements.lanternBands[node.lanternBand] = true
	end
	local function ride(node)
		local deck = surface(course, node.path)
		assert(deck.Name == "Deck", "Ride must target actual dynamic deck")
		local waitPart = surface(course, node.waitPath or node.boardPath)
		if node.waitOffset then move(waitPart, node.waitOffset, node.name .. "Wait", "Walk", 8) end
		await(node.name .. "BoardingSupport", function() return groundedOn(waitPart) end, 2)
		if node.waitSeconds or options.liftArrivalDelay then pause(node.waitSeconds or options.liftArrivalDelay, waitPart, node.name .. "ArrivalDelay") end
		local lastHeight = top(deck).Y
		await(node.name .. "RealBoardingWindow", function()
			assert(groundedOn(waitPart), "Boarding wait lost actual floor support")
			local height = top(deck).Y
			local delta = height - lastHeight
			lastHeight = height
			local direction = node.direction or "Up"
			local movingCorrectly = direction == "Any" or (direction == "Up" and delta >= -0.02) or (direction == "Down" and delta <= 0.02)
			return math.abs(height - assert(node.boardHeight)) <= (node.boardHeightTolerance or 0.65) and movingCorrectly
		end, node.cycleTimeout or 40)
		local lane = Vector3.new(liftLaneOffset, 0, 0)
		move(deck, (node.board or Vector3.zero) + lane, node.name .. "Board", "Jump", node.boardTimeout or 3)
		local rideStart = os.clock()
		local lastSample = 0
		await(node.name .. "RealExitHeight", function()
			assert(contact() == deck, "Lost actual dynamic deck support in " .. node.name)
			if os.clock() - lastSample >= 0.2 then
				lastSample = os.clock()
				table.insert(trace.contacts, {ride = node.name, elapsed = os.clock() - startClock,
					position = xyz(body.Position), deckTop = top(deck).Y, exactDeck = true})
			end
			return if node.exitDirection == "Down" then top(deck).Y <= node.exitHeight + 0.4 else top(deck).Y >= node.exitHeight - 0.4
		end, node.cycleTimeout or 40)
		record(node.name .. "RideExit", deck, {rideSeconds = os.clock() - rideStart})
		if node.exitTakeoff then move(deck, node.exitTakeoff + lane, node.name .. "ExitTakeoff", "Walk", 3) end
		move(surface(course, node.exitPath), node.exitOffset, node.name .. "Exit", node.exitKind or "Jump", 4)
		local stage = assert(node.path:match("/MovingCars/(%a+)_Bay%d/Deck$"), "Unknown lift stage")
		assert(stage == "Lower" or stage == "Upper", "Unknown required lift stage")
		trace.requirements.rides[stage] = {deck = deck:GetFullName(), elapsed = os.clock() - startClock,
			rideSeconds = os.clock() - rideStart}
	end
	local function follow(list)
		for _, node in list do
			trace.section = node.name
			currentNode = node
			guard()
			if terminalReached then return end
			lanternGate(node)
			if node.kind == "Ride" then ride(node)
			else
				assert(node.kind == "Walk" or node.kind == "Jump", "Unknown route action " .. tostring(node.kind))
				move(surface(course, node.path), node.offset, node.name, node.kind, node.timeout, node.drop)
			end
			if terminalReached then return end
			if node.waitSeconds and node.kind ~= "Ride" then pause(node.waitSeconds, surface(course, node.path), node.name .. "Wait") end
			if node.checkpoint then
				await("Official CP" .. node.checkpoint, function() return progress().checkpoint == node.checkpoint end, 3)
				record("OfficialCP" .. node.checkpoint, surface(course, node.path))
				if not trace.requirements.checkpoints[node.checkpoint] then
					assert(node.checkpoint == nextRecordedCheckpoint, "Directed checkpoint evidence is out of order")
					trace.requirements.checkpoints[node.checkpoint] = true
					nextRecordedCheckpoint += 1
				end
			end
			local extraRoute = options.catchRoutes and options.catchRoutes[node.name]
			if extraRoute and not usedCatchRoutes[node.name] then
				usedCatchRoutes[node.name] = true
				follow(extraRoute)
				table.insert(trace.catchReturns, {rejoin = node.name, elapsed = os.clock() - startClock, falls = progress().falls})
			end
			if terminalReached then return end
		end
	end
	local function cleanup()
		goal = nil
		jumpRequest = false
		RunService:UnbindFromRenderStep(renderName)
		for _, connection in connections do connection:Disconnect() end
		if humanoid.Parent then humanoid.Jump = false; humanoid:Move(Vector3.zero, false) end
		activeHandle = nil
	end
	function handle.Stop(reason)
		cancelled = reason or "User stopped probe"
		jumpRequest = false
		if humanoid.Parent then humanoid.Jump = false end
	end
	function handle.Debug() return trace end
	activeHandle = handle
	table.insert(connections, player.CharacterAdded:Connect(function()
		cancelled = "Character replaced"
		jumpRequest = false
		if humanoid.Parent then humanoid.Jump = false end
	end))
	local statusRemote = assert(game.ReplicatedStorage.Remotes:FindFirstChild("PlayerRaceStatusChanged"), "Shared status broadcast absent")
	table.insert(connections, statusRemote.OnClientEvent:Connect(function(payload)
		if type(payload) == "table" and payload.userId == player.UserId then latestRaceStatus = payload end
	end))
	RunService:BindToRenderStep(renderName, Enum.RenderPriority.Input.Value + 1, function()
		if cancelled or player.Character ~= character or humanoid.Health <= 0 then
			jumpRequest = false
			if humanoid.Parent then humanoid.Jump = false end
			return
		end
		humanoid.Jump = jumpRequest
		if not goal then return end
		local target = goal()
		trace.goal = xyz(target)
		local delta = Vector3.new(target.X - body.Position.X, 0, target.Z - body.Position.Z)
		humanoid:Move(if delta.Magnitude > 0.6 then delta.Unit else Vector3.zero, false)
	end)
	task.spawn(function()
		local ok, reason = xpcall(function()
			initial = guard()
			initial.recoveryUntil = character:GetAttribute("RecoveryUntil")
			assert(initial.checkpoint == 0 and initial.falls == 0 and not initial.finished, "Use a fresh actual shared start")
			trace.raceId = initial.raceId
			trace.initial = initial
			trace.state = "Running"
			local startSupport = surface(course, nodes[1].path)
			await("Initial actual staging floor", function() return groundedOn(startSupport) end, 4)
			follow(nodes)
			await("Actual official finish", function()
				local current = progress()
				return current.finished and current.status == "Finished" and current.checkpoint == 4
			end, 4)
			local final = guard()
			assert(terminalReached and terminalEligible(), "Terminal finish requirements were not met")
			assert(final.falls == 0 and #final.splits == 4 and final.requiredLaps == 1, "Wrong final result")
			for index, split in final.splits do assert(split.checkpoint == index and split.lap == 1, "Official split order failed") end
			record("ActualSharedFinishTrigger", nil, {anchored = body.Anchored, profileRestoredAfterFinish = humanoid.MaxSlopeAngle ~= 45})
			trace.final, trace.complete, trace.state = final, true, "Complete"
		end, debug.traceback)
		trace.elapsed = os.clock() - startClock
		if not ok then
			trace.failure = tostring(reason); trace.state = "Failed"
			if not trace.failureSnapshot then
				local captured, snapshot = pcall(finishSnapshot, latestProgress)
				trace.failureSnapshot = if captured then snapshot else {snapshotError = tostring(snapshot)}
			end
		end
		cleanup()
	end)
	return handle
end

function Probe.Observe(course, options)
	assert(RunService:IsStudio() and RunService:IsClient(), "Studio client observer only")
	assert(not activeHandle, "Stop the current probe before observing")
	options = options or {}
	assert(course:GetAttribute("CandidateId") == Config.CandidateId, "Wrong observed candidate")
	local player = Players.LocalPlayer
	local originalCharacter = player.Character
	local report = {candidate = Config.CandidateId, evidenceKind = "Actual client observation; no directed route claim",
		samples = {}, completeRoute = false, state = "Observing", characterReplacements = 0}
	lastReport = report
	local started, lastCharacter, initial, connection = os.clock(), originalCharacter, nil, nil
	local handle = {}
	activeHandle = handle
	local active = true
	local function stop(reason)
		if not active then return end
		active = false
		connection:Disconnect()
		if activeHandle == handle then activeHandle = nil end
		report.elapsed = os.clock() - started
		report.failure = reason
		report.state = if reason then "Failed" else "Observed"
		if not reason then
			if options.expectedFallDelta ~= nil and (not report.final or report.final.falls - initial.falls ~= options.expectedFallDelta) then
				report.failure, report.state = "Unexpected shared fall delta", "Failed"
			end
			if options.expectedCharacterReplacements ~= nil and report.characterReplacements ~= options.expectedCharacterReplacements then
				report.failure, report.state = "Unexpected character replacement count", "Failed"
			end
		end
	end
	connection = RunService.Heartbeat:Connect(function()
		if not active then return end
		local ok, reason = pcall(function()
			local encoded = player:GetAttribute("MCPhase2Progress")
			assert(type(encoded) == "string", "Shared server observer absent")
			local state = HttpService:JSONDecode(encoded)
			assert(state.source == "shared-services" and workspace:GetServerTimeNow() - state.observedAt <= 1.5, "Observer stale")
			assert(state.candidate == Config.CandidateId and state.courseId == Config.CourseId, "Observed course exited")
			assert(state.coursePath == course:GetFullName(), "Observed model is not active shared course")
			if initial then assert(state.raceId == initial.raceId, "Observed race restarted") else initial = state; report.initial = state end
			assert(state.official and state.status == "Racing" and state.raceState == "Racing", "Observation requires actual official active race")
			local character = assert(player.Character, "No current character")
			if character ~= lastCharacter then lastCharacter = character; report.characterReplacements += 1 end
			local body = assert(character:FindFirstChild("HumanoidRootPart"), "Current root absent")
			local humanoid = assert(character:FindFirstChildOfClass("Humanoid"), "Current humanoid absent")
			local params = RaycastParams.new()
			params.FilterType, params.FilterDescendantsInstances, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, characters(), true
			local leg = character:FindFirstChild("Left Leg")
			local r6 = if humanoid.RigType == Enum.HumanoidRigType.R6 and leg then leg.Size.Y else 0
			local hit = if humanoid.FloorMaterial ~= Enum.Material.Air then workspace:Raycast(body.Position,
				Vector3.new(0, -(humanoid.HipHeight + r6 + body.Size.Y / 2 + 1.1), 0), params) else nil
			local expected = options.expectedSupportPath and surface(course, options.expectedSupportPath)
			if options.requireSupport then assert(hit and hit.Instance == expected, "Lost expected actual waiting/deck support") end
			if options.expectedCheckpoint ~= nil then assert(state.checkpoint == options.expectedCheckpoint, "Unexpected checkpoint change") end
			report.final = state
			if not report.lastSample or os.clock() - report.lastSample >= (options.sampleInterval or 0.1) then
				report.lastSample = os.clock()
				table.insert(report.samples, {elapsed = os.clock() - started, position = xyz(body.Position), velocity = xyz(body.AssemblyLinearVelocity),
					support = hit and hit.Instance:GetFullName(), state = state, alive = humanoid.Health > 0,
					anchored = body.Anchored, actualExpectedSupport = expected and hit and hit.Instance == expected})
			end
			if os.clock() - started >= (options.durationSeconds or 40) then stop() end
		end)
		if not ok then stop(tostring(reason)) end
	end)
	function handle.Stop(reason) stop(reason) end
	function handle.Debug() return report end
	return handle
end

function Probe.Current() return lastReport end
function Probe.Debug() return lastReport end
function Probe.Stop(reason)
	if activeHandle then activeHandle.Stop(reason) end
	return lastReport
end

return Probe
