-- Studio-only runtime cargo probe: an actual server-owned R15 traverses the dock route.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
assert(RunService:IsStudio(), "Studio only")

local layout = require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
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

local fixture, controller, heartbeatConnection, inputConnection
local runtimeError
local currentHold
local direction = Vector3.zero
local jump = false
local epoch = os.clock()
local maxHeartbeatStep = 0
local contacts = {}
local contactsBySource = {}
local cargoRows = {}
local result = {
	build = layout.build,
	passed = false,
	method = "Real-time Runtime.Create plus server-owned R15 physics along the dock route; each RedCargo sweep gets one full-period standing contact window.",
}

local function runtimeTime()
	return os.clock() - epoch
end

local function top(part)
	return part.Position + part.CFrame.UpVector * part.Size.Y * 0.5
end

local function flat(point)
	return Vector3.new(point.X, 0, point.Z)
end

local function edge(part, direction)
	return math.min(
		part.Size.X * 0.5 / math.max(0.0001, math.abs(direction:Dot(part.CFrame.RightVector))),
		part.Size.Z * 0.5 / math.max(0.0001, math.abs(direction:Dot(part.CFrame.LookVector)))
	)
end

local function floorHeight(part, position)
	local normal = part.CFrame.UpVector
	local center = top(part)
	return Vector3.new(position.X,
		center.Y - (normal.X * (position.X - center.X) + normal.Z * (position.Z - center.Z)) / normal.Y,
		position.Z)
end

local function pointRecord(point)
	return {math.round(point.X * 100) / 100, math.round(point.Y * 100) / 100, math.round(point.Z * 100) / 100}
end

local function finiteRange(minimum, maximum)
	if minimum == math.huge or maximum == -math.huge then return nil end
	return {minimum, maximum}
end

local function waitFor(predicate, timeout)
	local deadline = os.clock() + timeout
	repeat
		RunService.Heartbeat:Wait()
		if predicate() then return true end
	until os.clock() >= deadline
	return predicate()
end

local runOk, runError = pcall(function()
	assert(not workspace:FindFirstChild("__ShipwreckCargo28Fixture"), "Owned cargo fixture already exists")
	fixture = installed:Clone()
	fixture.Name = "__ShipwreckCargo28Fixture"
	fixture:PivotTo(fixture:GetPivot() + Vector3.new(600, 0, 0))
	fixture.Parent = workspace
	local origin = fixture.Bounds.CourseOrigin.CFrame
	local surfaces = fixture.Obstacles.WalkingSurfaces
	local route = assert(layout.testRoutes.dock, "Missing authored dock route")
	local authored = {}
	for _, link in layout.links do authored[link[1] .. ">" .. link[2]] = true end
	for index = 1, #route - 1 do
		assert(authored[route[index] .. ">" .. route[index + 1]],
			"Missing authored link " .. route[index] .. " -> " .. route[index + 1])
		assert(surfaces:FindFirstChild(route[index]) and surfaces:FindFirstChild(route[index + 1]),
			"Dock route surface missing")
	end

	local targetNames = {
		S01_01 = "RedCargo1_0",
		S01_03 = "RedCargo3_3",
		S01_04 = "RedCargo4_0",
	}
	local targetData = {}
	for _, data in layout.hazards do
		targetData[data.name] = data
	end
	for surfaceName, cargoName in targetNames do
		local data = assert(targetData[cargoName], "Missing cargo source " .. cargoName)
		local visual = assert(fixture.Decoration.Obstacles:FindFirstChild(cargoName), "Missing cargo visual " .. cargoName)
		cargoRows[cargoName] = {
			data = data,
			visual = visual,
			waitingSurface = surfaceName,
			minimumX = math.huge,
			maximumX = -math.huge,
			hold = nil,
		}
	end
	local cargoCount = 0
	for _ in cargoRows do cargoCount += 1 end
	assert(cargoCount == 3, "Expected all three RedCargo sweeps")

	root.Anchored = false
	pcall(function() root:SetNetworkOwner(nil) end)
	humanoid.WalkSpeed = 16
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = 7.2
	humanoid.EvaluateStateMachine = true
	humanoid.AutoRotate = true
	humanoid.PlatformStand = false
	humanoid.Sit = false
	character:SetAttribute("RecoveryUntil", 0)
	local initialBounds, initialSize = character:GetBoundingBox()
	local feetOffset = root.Position.Y - (initialBounds.Position.Y - initialSize.Y * 0.5)
	local start = assert(surfaces:FindFirstChild(route[1]), "Missing dock start")
	local startPosition = top(start) + Vector3.new(0, feetOffset + 0.12, 0)
	character:PivotTo(character:GetPivot() + (startPosition - root.Position))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	humanoid:ChangeState(Enum.HumanoidStateType.Running)

	controller = require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(fixture,
		function(candidate, reason)
			if candidate == player then
				local time = runtimeTime()
				local hit = contactsBySource[reason]
				if hit then
					hit.count += 1
					hit.lastTime = time
				else
					hit = {source = reason, count = 1, firstTime = time, lastTime = time}
					contactsBySource[reason] = hit
					table.insert(contacts, hit)
				end
				if currentHold and currentHold.cargo == reason then currentHold.hit = true end
			end
		end,
		function(candidate) return candidate == player end)
	for _, descendant in fixture:GetDescendants() do
		if descendant:IsA("Sound") then descendant.Volume = 0 end
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = {surfaces}
	rayParams.RespectCanCollide = true
	local function standingOn()
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -4.3, 0), rayParams)
		return hit and hit.Instance or nil
	end
	local function groundedOn(part)
		return humanoid.FloorMaterial ~= Enum.Material.Air and standingOn() == part
	end
	inputConnection = RunService.PreSimulation:Connect(function()
		humanoid:Move(direction, false)
		humanoid.Jump = jump
	end)
	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		if runtimeError or not controller then return end
		maxHeartbeatStep = math.max(maxHeartbeatStep, dt)
		local ok, err = pcall(controller.Step, runtimeTime(), dt, true)
		if not ok then runtimeError = tostring(err); return end
		for name, row in cargoRows do
			local x = origin:PointToObjectSpace(row.visual.Position).X
			row.minimumX = math.min(row.minimumX, x)
			row.maximumX = math.max(row.maximumX, x)
			if currentHold and currentHold.cargo == name then
				currentHold.minimumX = math.min(currentHold.minimumX, x)
				currentHold.maximumX = math.max(currentHold.maximumX, x)
			end
		end
	end)
	assert(waitFor(function() return groundedOn(start) end, 2), "Could not ground on dock start")
	local function holdCargoRow(surfaceName, cargoName)
		local row = cargoRows[cargoName]
		local data = row.data
		local hold = {cargo = cargoName, surface = surfaceName, startedAt = runtimeTime(), hit = false,
			minimumX = math.huge, maximumX = -math.huge}
		currentHold = hold
		direction = Vector3.zero
		jump = false
		local deadline = os.clock() + (data.period or 3.8) + 0.3
		while os.clock() < deadline do
			assert(groundedOn(surfaces[surfaceName]), "Left cargo test surface " .. surfaceName)
			RunService.Heartbeat:Wait()
		end
		direction = Vector3.zero
		local expectedMin = data.p[1] - data.amplitude
		local expectedMax = data.p[1] + data.amplitude
		hold.finishedAt = runtimeTime()
		hold.expectedX = {expectedMin, expectedMax}
		hold.actualX = finiteRange(hold.minimumX, hold.maximumX)
		hold.passed = hold.hit and hold.minimumX <= expectedMin + 0.75 and hold.maximumX >= expectedMax - 0.75
		row.hold = hold
		currentHold = nil
	end

	local record = {name = "dockFullRow", links = {}, rows = {}, start = pointRecord(root.Position)}
	result.route = record
	for index = 1, #route - 1 do
		local from = surfaces[route[index]]
		local to = surfaces[route[index + 1]]
		assert(groundedOn(from), "Not grounded on " .. from.Name)
		local ta, tb = top(from), top(to)
		local delta = flat(tb - ta)
		local d = delta.Unit
		local launchDistance = math.min(math.max(0, edge(from, d) - 0.65), math.max(0, delta.Magnitude - edge(to, d) - 2))
		local takeoff = floorHeight(from, ta + d * launchDistance)
		local stage = floorHeight(from, ta + d * math.max(0, launchDistance - 2.35))
		local gap = delta.Magnitude - edge(from, d) - edge(to, d)
		local needsJump = gap > 0.2 or tb.Y - ta.Y > 0.6
		local link = {from = from.Name, to = to.Name, gap = math.round(gap * 100) / 100,
			jumpRequired = needsJump, startPosition = pointRecord(root.Position)}

		local walkDeadline = os.clock() + 3.5
		while (flat(stage - root.Position)).Magnitude > 1.1 do
			assert(groundedOn(from), "Left " .. from.Name .. " before its launch point")
			assert(os.clock() < walkDeadline, "Could not reach the launch point on " .. from.Name)
			direction = flat(stage - root.Position).Unit
			RunService.Heartbeat:Wait()
		end
		direction = Vector3.zero
		assert(waitFor(function() return groundedOn(from) end, 0.2), "Not grounded at launch on " .. from.Name)

		direction = d
		local launchReached = waitFor(function()
			return (flat(root.Position - takeoff)):Dot(d) >= -0.6 or not groundedOn(from)
		end, 1)
		if not needsJump and groundedOn(to) then
			link.passed = true
		else
			assert(launchReached and groundedOn(from), "Left " .. from.Name .. " before grounded takeoff")
			if needsJump then
				jump = true
				assert(waitFor(function() return humanoid.FloorMaterial == Enum.Material.Air end, 0.4),
					"Jump did not launch from " .. from.Name)
				jump = false
			end
			local reached = waitFor(function()
				if groundedOn(to) then return true end
				if (flat(root.Position - tb)):Dot(d) > -0.85 then direction = Vector3.zero end
				return false
			end, 2.25)
			direction = Vector3.zero
			assert(reached, "Missed " .. to.Name .. "; current floor=" .. tostring(standingOn()))
			link.landingPosition = pointRecord(root.Position)
			link.landingSurface = to.Name
			link.passed = true
		end
		table.insert(record.links, link)
		local cargoName = targetNames[to.Name]
		if cargoName then
			direction = Vector3.zero
			local row = cargoRows[cargoName]
			local holdRecord = {surface = to.Name, cargo = cargoName}
			table.insert(record.rows, holdRecord)
			holdCargoRow(to.Name, cargoName)
			holdRecord.startedAt = row.hold.startedAt
			holdRecord.finishedAt = row.hold.finishedAt
			holdRecord.expectedX = row.hold.expectedX
			holdRecord.actualX = row.hold.actualX
			holdRecord.hit = row.hold.hit
			holdRecord.passed = row.hold.passed
		end
		script:SetAttribute("Progress", index)
	end

	assert(not runtimeError, runtimeError or "Runtime failed")
	assert(#record.links == #route - 1, "Dock route was incomplete")
	local failures = {}
	for _, name in {"RedCargo1_0", "RedCargo3_3", "RedCargo4_0"} do
		local row = cargoRows[name]
		assert(row.hold, "Route did not reach " .. row.waitingSurface)
		if not row.hold.passed then table.insert(failures, name) end
	end
	record.passed = #failures == 0
	record.contacts = contacts
	record.elapsed = runtimeTime()
	result.route = record
	result.passed = record.passed
	assert(record.passed, "Full-row runtime evidence missing for " .. table.concat(failures, ", "))
end)

if inputConnection then inputConnection:Disconnect() end
direction = Vector3.zero
jump = false
if controller then pcall(function() controller.Stop() end) end
if heartbeatConnection then heartbeatConnection:Disconnect() end
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
if not runOk then result.error = tostring(runError) end
result.maxHeartbeatStep = maxHeartbeatStep
result.contacts = contacts
result.redCargo = {}
for name, row in cargoRows do
	local hit = contactsBySource[name]
	result.redCargo[name] = {
		surface = row.waitingSurface,
		contacts = if hit then hit.count else 0,
		actualX = finiteRange(row.minimumX, row.maximumX),
		expectedX = {row.data.p[1] - row.data.amplitude, row.data.p[1] + row.data.amplitude},
		hold = row.hold,
	}
end
script:SetAttribute("Result", HttpService:JSONEncode(result))
