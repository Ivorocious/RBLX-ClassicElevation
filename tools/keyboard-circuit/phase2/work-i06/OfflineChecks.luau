local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local CFrame, Vector3, Enum = roblox.CFrame, roblox.Vector3, roblox.Enum
local directory = "tools/keyboard-circuit/phase2/work-i06/"
for _, name in {"PacingTiming.client.luau", "EfficientTraversal.client.luau", "EfficientContinuousLap.client.luau", "EfficientRace.client.luau"} do luau.load(fs.readFile(directory .. name), {debugName = name}) end
local timingShared = {}
luau.load(fs.readFile(directory .. "PacingTiming.client.luau"), {environment = {shared = timingShared}})()
local Timing = timingShared.KCP2I06Timing
local Motion = luau.load(fs.readFile("tools/keyboard-circuit/phase2/staged/Motion.luau"))()
local checks = 0
for _, kind in {"Foundry", "Domino", "Shift", "Sweep", "Shuttle", "Fallaway"} do
	local config = Motion.Tuning(kind)
	for index = 1, (if kind == "Fallaway" or kind == "Sweep" or kind == "Shuttle" then 1 else 3) do
		for tick = 0, 4000 do
			local elapsed = tick / 100
			local remaining = Timing.Remaining(kind, elapsed, index, config)
			assert(remaining >= 0 and remaining <= config.Period)
			if remaining > .001 then
				local result = if kind == "Sweep" or kind == "Shuttle" then Motion[kind](elapsed, config) else if kind == "Fallaway" then Motion.Fallaway(elapsed, 1, 1, config) else Motion[kind](elapsed, index, config)
				assert(if kind == "Sweep" then result.state == "Rest" else if kind == "Shuttle" then result.state == "Boarding" else if kind == "Foundry" then result.state == "Clear" else if kind == "Domino" then result.state == "ClearPassage" else result.open)
			end
			checks += 1
		end
	end
end
assert(math.abs(Timing.Remaining("Domino", 4, 1, Motion.Defaults.Domino) - 2.2) < .0001)
assert(Timing.Remaining("Domino", 6.3, 1, Motion.Defaults.Domino) == 0)
assert(Timing.Remaining("Shuttle", 2.2, 1, Motion.Defaults.Shuttle) < 1.2)
assert(Timing.Remaining("Shuttle", .5, 1, Motion.Defaults.Shuttle) >= 1.2)

local trajectoryResults = {}
local function trajectory(label, size, separation, rise, rotation, launchCase)
	local now, bound, moveCommand, unbound = 0, nil, Vector3.zero, 0
	local contacts = {}
	local base = CFrame.new(100, 300, -200) * CFrame.Angles(0, rotation or 0, 0)
	local from = {Name = "From", Size = Vector3.new(size, .25, size), CFrame = base}
	local to = {Name = "To", Size = Vector3.new(size, .25, size), CFrame = base * CFrame.new(separation, rise, 0)}
	for _, part in {from, to} do
		part.Position, part.AssemblyCenterOfMass = part.CFrame.Position, part.CFrame.Position
		part.AssemblyLinearVelocity, part.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		part.GetFullName = function() return label .. "." .. part.Name end
		table.insert(contacts, part)
	end
	local height = 3.18
	local character = {}
	local root = {Position = from.Position + Vector3.new(0, .125 + height, 0), Parent = character, AssemblyLinearVelocity = Vector3.zero}
	local humanoid = {FloorMaterial = Enum.Material.SmoothPlastic, Health = 100, Jump = false}
	humanoid.Move = function(_, value) assert(value.Magnitude <= 1.0001); moveCommand = value end
	character.FindFirstChild = function(_, name) return if name == "HumanoidRootPart" then root else nil end
	character.FindFirstChildOfClass = function(_, name) return if name == "Humanoid" then humanoid else nil end
	local player = {Character = character}
	local workspace = {GetServerTimeNow = function() return now end}
	local function contactBelow(position)
		local selected, top = nil, -math.huge
		for _, part in contacts do
			local point = part.CFrame:PointToObjectSpace(position)
			local candidateTop = part.Position.Y + .125
			if math.abs(point.X) <= part.Size.X / 2 and math.abs(point.Z) <= part.Size.Z / 2 and candidateTop <= position.Y and candidateTop > top then selected, top = part, candidateTop end
		end
		return selected, top
	end
	workspace.Raycast = function(_, position)
		local selected, top = contactBelow(position)
		return if selected and position.Y - top <= 7 then {Instance = selected} else nil
	end
	local verticalVelocity, driftStage, driftSteeringResumed = 0, 0, false
	local function step()
		local dt = 1 / 120
		now += dt
		assert(now < 20, "Mock trajectory stalled")
		if bound then bound(dt) end
		if humanoid.Jump and humanoid.FloorMaterial ~= Enum.Material.Air then verticalVelocity = math.sqrt(2 * 196.2 * 7.2); humanoid.FloorMaterial = Enum.Material.Air end
		local wasAirborne = humanoid.FloorMaterial == Enum.Material.Air
		local horizontalVelocity = moveCommand * 16
		local position = root.Position + horizontalVelocity * dt
		if humanoid.FloorMaterial == Enum.Material.Air then
			verticalVelocity -= 196.2 * dt
			position += Vector3.new(0, verticalVelocity * dt, 0)
		end
		local selected, top = contactBelow(position)
		if selected and verticalVelocity <= 0 and position.Y <= top + height then
			position = Vector3.new(position.X, top + height, position.Z)
			verticalVelocity, humanoid.FloorMaterial = 0, Enum.Material.SmoothPlastic
		elseif not selected or position.Y > top + height + .001 then humanoid.FloorMaterial = Enum.Material.Air end
		if launchCase == "LandingDrift" and selected == to then
			if driftStage == 0 and wasAirborne and humanoid.FloorMaterial ~= Enum.Material.Air then
				position = to.Position + Vector3.new(0, .125 + height, 0) - base.RightVector * .24
				verticalVelocity, driftStage = 6.3, 1
			elseif driftStage == 1 then
				position = to.Position + Vector3.new(0, .125 + height, 0) + base.RightVector * .373
				verticalVelocity, driftStage = .075, 2
			elseif driftStage == 2 then
				verticalVelocity = 0
				if moveCommand.Magnitude > 0 then driftSteeringResumed, driftStage = true, 3 end
			end
		end
		root.Position, root.AssemblyLinearVelocity = position, horizontalVelocity + Vector3.new(0, verticalVelocity, 0)
	end
	local runService = {
		IsStudio = function() return true end, IsClient = function() return true end,
		BindToRenderStep = function(_, _, _, callback) bound = callback end,
		UnbindFromRenderStep = function() bound = nil; unbound += 1 end,
		RenderStepped = {Wait = step},
	}
	local shared = {}
	local environment = {game = {GetService = function() return runService end}, workspace = workspace, shared = shared,
		Vector3 = Vector3, Enum = Enum, RaycastParams = {new = function() return {} end}, os = {clock = function() return now end}}
	luau.load(fs.readFile(directory .. "EfficientTraversal.client.luau"), {environment = environment})()
	local driver = shared.KCP2I06EfficientTraversal.New({}, player, function() assert(player.Character == character) end)
	local direction = base.RightVector
	local readinessRecord
	if launchCase and launchCase ~= "LandingDrift" then
		local edge = shared.KCP2I06EfficientTraversal.Edge(from, direction, .9)
		root.Position = edge + Vector3.new(0, .125 + height, 0) + direction * (if launchCase == "OvershotEdge" then .28 else -.1)
		root.AssemblyLinearVelocity = direction * (if launchCase == "OpposedVelocity" then -16 else if launchCase == "LateralVelocity" then 0 else 16)
		if launchCase == "LateralVelocity" then root.AssemblyLinearVelocity = base.LookVector * 8 end
		if launchCase == "PositiveVerticalVelocity" or launchCase == "MovingSupport" then
			root.AssemblyLinearVelocity = Vector3.new(0, 6.587, 0)
			if launchCase == "MovingSupport" then from.AssemblyLinearVelocity = root.AssemblyLinearVelocity
			else assert(not pcall(driver.Cross, label .. " premature launch", from, to, direction), "Still-rising support must not qualify for a new launch") end
			local ready
			ready, readinessRecord = driver.Move(label .. " grounded arrival", root.Position, false, from, {seconds = 1, tolerance = .4, holdOnArrival = true})
			assert(ready and math.abs(readinessRecord.finishSupportNormalSpeed) <= 2)
			assert(if launchCase == "MovingSupport" then readinessRecord.groundReadinessWaitSeconds == 0 else readinessRecord.groundReadinessWaitSeconds > 0)
			assert(not humanoid.Jump, "Ground readiness must not issue a jump")
			root.AssemblyLinearVelocity, from.AssemblyLinearVelocity = Vector3.zero, Vector3.zero
		end
	end
	assert(driver.Cross(label, from, to, if launchCase and launchCase ~= "OvershotEdge" and launchCase ~= "LandingDrift" then direction else nil), label .. " failed mock support transition")
	local record = driver.Records()[#driver.Records()]
	assert(record.arrived and record.airborne and record.finishSupport == label .. ".To")
	assert(driver.Support(to))
	if launchCase and launchCase ~= "PositiveVerticalVelocity" and launchCase ~= "MovingSupport" and launchCase ~= "LandingDrift" then
		assert(record.launch.settleSeconds > 0 and record.launch.after.speed <= .5)
		assert(driver.Records()[#driver.Records() - 1].controlHold == true)
		assert(record.launch.pendingEdgeReversal == (launchCase == "OvershotEdge"))
	else assert(record.launch.settleSeconds == 0) end
	local localFinish = to.CFrame:PointToObjectSpace(root.Position)
	if size <= 3 then assert(math.abs(localFinish.X) < .25) end
	if launchCase == "LandingDrift" then
		assert(driftSteeringResumed, "Stable support outside tolerance must release the readiness latch")
		assert(record.groundReadinessWaitSeconds > 0 and record.groundReadinessWaitSeconds < record.elapsed)
	end
	driver.Stop(); driver.Stop()
	assert(unbound == 1 and moveCommand.Magnitude == 0)
	table.insert(trajectoryResults, {case = label, seconds = now, localFinish = {localFinish.X, localFinish.Y, localFinish.Z}, airLandingHoldSeconds = record.airLandingHoldSeconds, support = record.finishSupport,
		settleSeconds = record.launch.settleSeconds, pendingEdgeReversal = record.launch.pendingEdgeReversal,
		groundReadinessSeconds = if readinessRecord then readinessRecord.groundReadinessWaitSeconds else record.groundReadinessWaitSeconds,
		driftSteeringResumed = driftSteeringResumed})
end
trajectory("BroadBank", 12.8, 18, 1, .63)
trajectory("NarrowDominoBank", 5, 10, 0, -1.3)
trajectory("ExpertPrecision", 2.4, 6.2, 0, .31)
trajectory("OpposedLaunchVelocity", 12.8, 16, 0, .63, "OpposedVelocity")
trajectory("SidewaysLaunchVelocity", 12.8, 16, 0, .63, "LateralVelocity")
trajectory("JustOvershotTakeoff", 12.8, 16, 0, .63, "OvershotEdge")
trajectory("StillRisingGroundedArrival", 12.8, 16, 0, .63, "PositiveVerticalVelocity")
trajectory("ReadyMovingSupport", 12.8, 16, 0, .63, "MovingSupport")
trajectory("PrecisionLandingDrift", 2.4, 6.2, 0, .31, "LandingDrift")

local runner = fs.readFile(directory .. "EfficientContinuousLap.client.luau")
local driver = fs.readFile(directory .. "EfficientTraversal.client.luau")
assert(select(2, runner:gsub("setupProbe%.Place%(endpoint%(\"F00\", false%)%)", "")) == 1)
assert(not runner:find("PivotTo", 1, true) and not driver:find("PivotTo", 1, true))
assert(not runner:find("CFrame =", 1, true) and not driver:find("CFrame =", 1, true))
assert(not runner:find("WalkSpeed =", 1, true) and not driver:find("WalkSpeed =", 1, true))
assert(not runner:find("JumpHeight =", 1, true) and not driver:find("JumpHeight =", 1, true))
local race = fs.readFile(directory .. "EfficientRace.client.luau")
assert(select(2, race:gsub("setupProbe%.Place%(endpoint%(\"F00\", false%)%)", "")) == 1)
assert(not race:find("PivotTo", 1, true) and not race:find("CFrame =", 1, true))
local Progression = luau.load(fs.readFile("tools/keyboard-circuit/phase2/staged/Progression.luau"))()
local progress = Progression.New(0)
assert(Progression.Begin(progress, .1).accepted)
local gatesChecked = 0
for lap = 1, 3 do
	for _, gate in {"CP1", "CP2", "CP3", "F01", "F00"} do
		gatesChecked += 1
		assert(Progression.Pass(progress, gate, gatesChecked + .1).accepted)
		local finalReturn = gate == "F00" and lap == 3
		local expectedNext = if finalReturn then "" else ({CP1 = "CP2", CP2 = "CP3", CP3 = "F01", F01 = "F00", F00 = "CP1"})[gate]
		assert(progress.nextGate == expectedNext and progress.completedLaps == (if gate == "F00" then lap else lap - 1))
		assert(progress.lap == (if gate == "F00" and not finalReturn then lap + 1 else lap) and progress.finished == finalReturn)
	end
end
local receipt = {compiled = 4, windowSamples = checks, naturalGateContractChecks = gatesChecked, mockTrajectories = trajectoryResults,
	contract = "One F00 setup call; no geometry/movement-setting writes; actual gates/recoveries required by runner",
	boundary = "Pure timing and mocked controller tests only. Mock support physics does not prove Roblox contacts, pacing, hazard safety or native traversal."}
fs.writeFile(directory .. "Offline-checks.json", serde.encode("json", receipt, true) .. "\n")
print(serde.encode("json", receipt))
