-- Studio-only real-time wave traversal probe; it never drives the hazard clock manually.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
assert(RunService:IsStudio(), "Studio only")

local layout = require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local Config = require(game.ReplicatedStorage.Config.ShipwreckConfig)
local installed = assert(game.ServerStorage.CourseLibrary:FindFirstChild("Course_ShipwreckCove"), "Missing installed course")
assert(installed:GetAttribute("ShipwreckBuild") == layout.build, "layout and installed build differ")

local player = assert(game.Players:GetPlayers()[1], "An R15 Studio player is required")
local character = assert(player.Character, "Player has no character")
local humanoid = assert(character:FindFirstChildOfClass("Humanoid"), "Missing humanoid")
local root = assert(character:FindFirstChild("HumanoidRootPart"), "Missing HumanoidRootPart")
assert(humanoid.RigType == Enum.HumanoidRigType.R15, "Probe requires R15")

local oldPivot = character:GetPivot()
local oldRootAnchored = root.Anchored
local oldLinearVelocity = root.AssemblyLinearVelocity
local oldAngularVelocity = root.AssemblyAngularVelocity
local oldOwner = root:GetNetworkOwner()
local oldRecoveryUntil = character:GetAttribute("RecoveryUntil")
local oldWalkSpeed = humanoid.WalkSpeed
local oldJumpHeight = humanoid.JumpHeight
local oldJumpPower = humanoid.JumpPower
local oldUseJumpPower = humanoid.UseJumpPower
local oldAutoRotate = humanoid.AutoRotate
local oldPlatformStand = humanoid.PlatformStand
local oldSit = humanoid.Sit
local oldEvaluateStateMachine = humanoid.EvaluateStateMachine

local fixture, controller, heartbeatConnection
local runtimeError
local epoch = os.clock()
local initialPhaseOffset = script:GetAttribute("InitialPhaseOffset")
if typeof(initialPhaseOffset) ~= "number" then initialPhaseOffset = epoch % Config.TideCycle end
assert(initialPhaseOffset >= 0 and initialPhaseOffset < Config.TideCycle, "InitialPhaseOffset must be within one tide cycle")

local currentLeg
local recoveries = {}
local crossings = {}
local phaseSeen = {}
local waveMetrics = {}
local maxStep = 0

local function runtimeTime()
	return os.clock() - epoch + initialPhaseOffset
end

local function floorTop(part, localX, localZ)
	return part.CFrame:PointToWorldSpace(Vector3.new(localX, part.Size.Y * 0.5, localZ))
end

local function flat(point)
	return Vector3.new(point.X, 0, point.Z)
end

local function waitFor(predicate, timeout)
	local deadline = os.clock() + timeout
	repeat
		RunService.Heartbeat:Wait()
		if predicate() then return true end
	until os.clock() >= deadline
	return predicate()
end

local setupOk, setupError = pcall(function()
	assert(not workspace:FindFirstChild("__ShipwreckLiveWaves28"), "Owned wave fixture already exists")
	fixture = installed:Clone()
	fixture.Name = "__ShipwreckLiveWaves28"
	fixture:PivotTo(fixture:GetPivot() + Vector3.new(600, 0, 0))
	fixture.Parent = workspace
	local surfaces = fixture.Obstacles.WalkingSurfaces
	local east = assert(surfaces:FindFirstChild("SurgeEastRefuge"), "Missing east refuge")
	local middle = assert(surfaces:FindFirstChild("SurgeMiddleRefuge"), "Missing middle refuge")
	local west = assert(surfaces:FindFirstChild("SurgeWestRefuge"), "Missing west refuge")
	local passage1 = assert(surfaces:FindFirstChild("Surge1Passage"), "Missing Surge1 passage")
	local passage2 = assert(surfaces:FindFirstChild("Surge2Passage"), "Missing Surge2 passage")
	local origin = fixture.Bounds.CourseOrigin.CFrame
	local oldBounds, oldBoundsSize = character:GetBoundingBox()
	local feetOffset = root.Position.Y - (oldBounds.Position.Y - oldBoundsSize.Y * 0.5)

	root.Anchored = false
	pcall(function() root:SetNetworkOwner(nil) end)
	humanoid.WalkSpeed = 16
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = 7.2
	humanoid.EvaluateStateMachine = true
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid.AutoRotate = true
	character:SetAttribute("RecoveryUntil", 0)
	local startTarget = floorTop(east, 0, 0) + Vector3.new(0, feetOffset + 0.12, 0)
	character:PivotTo(character:GetPivot() + (startTarget - root.Position))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	humanoid:ChangeState(Enum.HumanoidStateType.Running)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { surfaces }
	rayParams.RespectCanCollide = true
	local function standingOn()
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -4.5, 0), rayParams)
		return hit and hit.Instance or nil
	end
	local function groundedOn(surface)
		return humanoid.FloorMaterial ~= Enum.Material.Air and standingOn() == surface
	end
	local function moveTo(surface, localX, localZ, timeout, jump)
		local floorPoint = floorTop(surface, localX, localZ)
		local target = floorPoint + Vector3.new(0, feetOffset, 0)
		humanoid:MoveTo(target)
		if jump then
			humanoid.Jump = true
			local tookOff = waitFor(function() return humanoid.FloorMaterial == Enum.Material.Air end, 0.6)
			humanoid.Jump = false
			assert(tookOff, "Humanoid did not jump toward " .. surface.Name)
		end
		local arrived = waitFor(function()
			return groundedOn(surface) and (flat(root.Position - target)).Magnitude < 1.6
		end, timeout)
		humanoid:MoveTo(root.Position)
		assert(arrived, "Humanoid missed " .. surface.Name .. " near " .. tostring(target))
	end

	local waveData = {}
	local boundsByName = {}
	for _, data in layout.surges do
		local bounds = assert(fixture.Obstacles.ShipwreckHazards:FindFirstChild(data.name .. "Bounds"),
			"Missing bounds for " .. data.name)
		boundsByName[data.name] = bounds
		phaseSeen[data.name] = {}
		waveMetrics[data.name] = {
			height = 0,
			depth = 0,
			top = 0,
			maxFrontMismatch = 0,
			maxPoolBehind = 0,
			completedSweeps = {},
			currentSweep = nil,
		}
		table.insert(waveData, data)
	end
	controller = require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(fixture,
		function(candidate, reason)
			if candidate == player then
				table.insert(recoveries, {reason = reason, time = runtimeTime(), leg = currentLeg and currentLeg.zone or "waiting"})
			end
		end,
		function(candidate) return candidate == player end)
	for _, descendant in fixture:GetDescendants() do
		if descendant:IsA("Sound") then descendant.Volume = 0 end
	end

	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		if runtimeError or not controller then return end
		maxStep = math.max(maxStep, dt)
		local now = runtimeTime()
		local ok, err = pcall(controller.Step, now, dt, true)
		if not ok then runtimeError = tostring(err); return end
		for _, data in waveData do
			local zone = fixture.Decoration[data.name]
			local bounds = boundsByName[data.name]
			local phase = bounds:GetAttribute("Phase")
			local metrics = waveMetrics[data.name]
			if phase then phaseSeen[data.name][phase] = true end
			if currentLeg and currentLeg.zone == data.name and phase ~= "Dry" then
				currentLeg.stayedDry = false
			end
			if zone.SurgeWave.Transparency < 1 then
				metrics.height = math.max(metrics.height, zone.SurgeWave.Size.Y)
				metrics.depth = math.max(metrics.depth, zone.SurgeWave.Size.Z)
				local waterLocal = origin:PointToObjectSpace(zone.SurgeWater.Position)
				metrics.top = math.max(metrics.top, waterLocal.Y + zone.SurgeWater.Size.Y * 0.5)
				local front = bounds.CFrame:PointToObjectSpace(zone.SurgeWave.Position).Z
				local waterLocalZ = bounds.CFrame:PointToObjectSpace(zone.SurgeWater.Position).Z
				local waterFront = waterLocalZ - zone.SurgeWater.Size.Z * 0.5
				local waterBack = waterLocalZ + zone.SurgeWater.Size.Z * 0.5
				metrics.maxFrontMismatch = math.max(metrics.maxFrontMismatch, math.abs(front - waterFront))
				metrics.maxPoolBehind = math.max(metrics.maxPoolBehind,
					waterBack - front - zone.SurgeWave.Size.Z * 0.5)
				if phase == "Surge" then
					if not metrics.currentSweep then
						metrics.currentSweep = {startZ = front, endZ = front}
					else
						metrics.currentSweep.endZ = front
					end
				end
			end
			if phase ~= "Surge" and metrics.currentSweep then
				if #metrics.completedSweeps < 2 then
					table.insert(metrics.completedSweeps, metrics.currentSweep)
				end
				metrics.currentSweep = nil
			end
		end
	end)
	assert(waitFor(function() return groundedOn(east) end, 2), "Could not ground on east refuge")

	local function waitForDryWindow(data, minimumSeconds)
		local bounds = boundsByName[data.name]
		local deadline = os.clock() + Config.TideCycle * 2 + 2
		while os.clock() < deadline do
			local now = runtimeTime()
			local phaseTime = (now - (data.phase or 0)) % Config.TideCycle
			local remainingDry = Config.TideDry - phaseTime
			if bounds:GetAttribute("Phase") == "Dry" and remainingDry >= minimumSeconds then
				return now
			end
			RunService.Heartbeat:Wait()
		end
		return nil
	end

	local function cross(data, fromSurface, toSurface, passage, direction)
		local startTime = waitForDryWindow(data, 5)
		assert(startTime, "No safe dry window for " .. data.name)
		assert(groundedOn(fromSurface), "Not standing on " .. fromSurface.Name)
		local beforeRecoveries = #recoveries
		local leg = {
			zone = data.name,
			from = fromSurface.Name,
			to = toSurface.Name,
			startTime = startTime,
			phaseAtEntry = boundsByName[data.name]:GetAttribute("Phase"),
			stayedDry = true,
		}
		currentLeg = leg
		moveTo(passage, 0, 0, 5, false)
		moveTo(passage, direction * 7.2, 0, 3, false)
		moveTo(toSurface, -direction * 11.4, 0, 3, true)
		moveTo(toSurface, 0, 0, 3, false)
		leg.endTime = runtimeTime()
		leg.phaseAtExit = boundsByName[data.name]:GetAttribute("Phase")
		leg.recoveries = #recoveries - beforeRecoveries
		leg.passed = leg.stayedDry and leg.recoveries == 0 and leg.phaseAtExit == "Dry"
		currentLeg = nil
		table.insert(crossings, leg)
		assert(leg.passed, data.name .. " left its dry window or contacted the racer during traversal")
	end

	local routes = {
		{layout.surges[1], east, middle, passage1, -1},
		{layout.surges[2], middle, west, passage2, -1},
		{layout.surges[2], west, middle, passage2, 1},
		{layout.surges[1], middle, east, passage1, 1},
	}
	for index, route in routes do
		cross(table.unpack(route))
		script:SetAttribute("Progress", index)
	end

	assert(not runtimeError, runtimeError or "Runtime failed")
	for _, data in waveData do
		local seen = phaseSeen[data.name]
		local metrics = waveMetrics[data.name]
		for _, phase in {"Dry", "Warning", "Surge", "Drain"} do
			assert(seen[phase], data.name .. " never displayed " .. phase)
		end
		assert(metrics.height >= Config.TideCrestHeight - 0.1,
			data.name .. " did not display the configured crest height")
		assert(metrics.depth >= Config.TideCrestDepth - 0.1,
			data.name .. " did not display the configured crest depth")
		assert(metrics.top <= Config.TideWaterBottom + Config.TideWaterHeight + 0.1,
			data.name .. " pool exceeded its configured water top")
		assert(metrics.maxFrontMismatch < 0.3, data.name .. " pool front did not align with the visible crest")
		assert(metrics.maxPoolBehind > 1, data.name .. " did not show a pool behind its crest")
		assert(#metrics.completedSweeps > 0, data.name .. " did not complete a visible sweep")
		for _, sweep in metrics.completedSweeps do
			assert(sweep.startZ > sweep.endZ, data.name .. " crest did not travel from +Z toward -Z")
		end
		metrics.currentSweep = nil
	end
	assert(#recoveries == 0, "Unexpected runtime recovery during wave traversal")
end)

local result = {
	build = layout.build,
	passed = setupOk,
	error = if setupOk then nil else tostring(setupError),
	initialPhaseOffset = initialPhaseOffset,
	tideCycle = Config.TideCycle,
	crestHeight = Config.TideCrestHeight,
	crestDepth = Config.TideCrestDepth,
	maxHeartbeatStep = maxStep,
	crossings = crossings,
	phasesSeen = phaseSeen,
	waveMetrics = waveMetrics,
	recoveries = recoveries,
	method = "Four real-time Humanoid.MoveTo/jump crossings using one Runtime controller and Heartbeat dt; initial phase offset is recorded, no controlled-time Step or reset.",
}

if heartbeatConnection then heartbeatConnection:Disconnect() end
if controller then pcall(function() controller.Stop() end) end
if fixture then fixture:Destroy() end
humanoid:MoveTo(root.Position)
humanoid.Jump = false
character:PivotTo(oldPivot)
root.AssemblyLinearVelocity = oldLinearVelocity
root.AssemblyAngularVelocity = oldAngularVelocity
root.Anchored = oldRootAnchored
humanoid.WalkSpeed = oldWalkSpeed
humanoid.JumpHeight = oldJumpHeight
humanoid.JumpPower = oldJumpPower
humanoid.UseJumpPower = oldUseJumpPower
humanoid.AutoRotate = oldAutoRotate
humanoid.PlatformStand = oldPlatformStand
humanoid.Sit = oldSit
humanoid.EvaluateStateMachine = oldEvaluateStateMachine
character:SetAttribute("RecoveryUntil", oldRecoveryUntil)
if not oldRootAnchored then
	pcall(function()
		if oldOwner and oldOwner.Parent then root:SetNetworkOwner(oldOwner) else root:SetNetworkOwnershipAuto() end
	end)
end
script:SetAttribute("Result", HttpService:JSONEncode(result))
