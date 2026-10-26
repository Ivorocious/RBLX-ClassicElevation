-- Studio-only focused probe for wave-boundary movement and the live coconut grove.
-- Run once in Studio after confirming C05 is installed; it moves one real R15 avatar.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

assert(RunService:IsStudio(), "Studio only")
assert(#Players:GetPlayers() == 1, "Probe requires exactly one Studio player")

local Layout = require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local Config = require(game.ReplicatedStorage.Config.ShipwreckConfig)
local installed = assert(game.ServerStorage.CourseLibrary:FindFirstChild("Course_ShipwreckCove"),
	"Missing installed Shipwreck Cove course")
assert(installed:GetAttribute("ShipwreckBuild") == Layout.build, "Installed course differs from Layout")

local player = Players:GetPlayers()[1]
local character = assert(player.Character, "Player has no character")
local humanoid = assert(character:FindFirstChildOfClass("Humanoid"), "Missing Humanoid")
local root = assert(character:FindFirstChild("HumanoidRootPart"), "Missing HumanoidRootPart")
assert(humanoid.RigType == Enum.HumanoidRigType.R15, "Probe requires an actual R15")

local fixtureName = "__SC29GameplayProbe"
assert(not Workspace:FindFirstChild(fixtureName), "Owned probe fixture already exists")

local original = {
	pivot = character:GetPivot(),
	anchored = root.Anchored,
	linearVelocity = root.AssemblyLinearVelocity,
	angularVelocity = root.AssemblyAngularVelocity,
	networkOwner = root:GetNetworkOwner(),
	recoveryUntil = character:GetAttribute("RecoveryUntil"),
	walkSpeed = humanoid.WalkSpeed,
	jumpHeight = humanoid.JumpHeight,
	jumpPower = humanoid.JumpPower,
	useJumpPower = humanoid.UseJumpPower,
	autoRotate = humanoid.AutoRotate,
	platformStand = humanoid.PlatformStand,
	sit = humanoid.Sit,
	evaluateStateMachine = humanoid.EvaluateStateMachine,
}

local fixture: Model? = nil
local controller: any = nil
local heartbeatConnection: RBXScriptConnection? = nil
local runtimeError: string? = nil
local stage = "setup"
local runtimeEpoch = os.clock()
local recoveryAnchor: BasePart? = nil
local recoveryCount = 0
local hits = {}
local recoveries = {}
local waveTrial = { status = "not-started", steps = {} }
local groveTrial = { status = "not-started", steps = {}, coconutEvents = {} }
local coconutDataByName = {}
local coconutParts = {}
local coconutPreviousState = {}
local activeCoconutEvents = {}
local currentRuntimeTime = 0
local groveHitStart = 0
local groveRecoveryStart = 0

local oldBounds, oldBoundsSize = character:GetBoundingBox()
local feetOffset = root.Position.Y - (oldBounds.Position.Y - oldBoundsSize.Y * 0.5)

local function runtimeTime(): number
	return os.clock() - runtimeEpoch
end

local function floorTop(part: BasePart, localX: number?, localZ: number?): Vector3
	return part.CFrame:PointToWorldSpace(Vector3.new(localX or 0, part.Size.Y * 0.5, localZ or 0))
end

local function flat(point: Vector3): Vector3
	return Vector3.new(point.X, 0, point.Z)
end

local function pointRecord(point: Vector3): { number }
	return {
		math.round(point.X * 100) / 100,
		math.round(point.Y * 100) / 100,
		math.round(point.Z * 100) / 100,
	}
end

local function waitFor(predicate: () -> boolean, timeout: number): boolean
	local deadline = os.clock() + timeout
	repeat
		RunService.Heartbeat:Wait()
		if predicate() then
			return true
		end
	until os.clock() >= deadline
	return predicate()
end

local function setStage(value: string)
	stage = value
	script:SetAttribute("Stage", value)
end

local function placeOnSurface(surface: BasePart, localX: number?, localZ: number?)
	local goal = floorTop(surface, localX, localZ) + Vector3.new(0, feetOffset, 0)
	character:PivotTo(character:GetPivot() + (goal - root.Position))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	humanoid:MoveTo(goal)
	humanoid.Jump = false
end

local function standingOn(surfaces: Instance): BasePart?
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { surfaces }
	rayParams.RespectCanCollide = true
	local result = Workspace:Raycast(root.Position, Vector3.new(0, -5.5, 0), rayParams)
	return result and result.Instance or nil
end

local function moveToSurface(surface: BasePart, localX: number?, localZ: number?, jump: boolean,
	timeout: number): (boolean, string?)
	local recoveryBefore = recoveryCount
	local goal = floorTop(surface, localX, localZ) + Vector3.new(0, feetOffset, 0)
	local startPosition = root.Position
	humanoid:MoveTo(goal)
	if jump then
		humanoid.Jump = true
		local tookOff = waitFor(function()
			return recoveryCount > recoveryBefore or humanoid.FloorMaterial == Enum.Material.Air
		end, 0.6)
		humanoid.Jump = false
		if recoveryCount > recoveryBefore then
			return false, "recovered-during-takeoff"
		end
		if not tookOff then
			return false, "jump-did-not-take-off"
		end
	end
	local arrived = waitFor(function()
		if recoveryCount > recoveryBefore then
			return true
		end
		return standingOn(fixture :: Model) == surface
			and (flat(root.Position - goal)).Magnitude < 1.8
	end, timeout)
	humanoid:MoveTo(root.Position)
	if recoveryCount > recoveryBefore then
		return false, "recovered-during-move"
	end
	if not arrived then
		return false, "move-timeout"
	end
	return true, nil
end

local function recordMove(record: { [string]: any }, label: string, surface: BasePart,
	localX: number?, localZ: number?, jump: boolean, timeout: number): boolean
	local phases = {}
	if fixture then
		for _, name in { "Surge1", "Surge2" } do
			local bounds = fixture.Obstacles.ShipwreckHazards:FindFirstChild(name .. "Bounds")
			phases[name] = bounds and bounds:GetAttribute("Phase") or nil
		end
	end
	local started = runtimeTime()
	local startPosition = pointRecord(root.Position)
	local ok, reason = moveToSurface(surface, localX, localZ, jump, timeout)
	local landing = standingOn(fixture :: Model)
	table.insert(record.steps, {
		name = label,
		time = math.round(started * 1000) / 1000,
		phases = phases,
		start = startPosition,
		finish = pointRecord(root.Position),
		landedOn = landing and landing.Name or nil,
		passed = ok,
		error = reason,
	})
	return ok
end

local function remainingDry(zoneData: { [string]: any }): number
	local phaseTime = (runtimeTime() - (zoneData.phase or 0)) % Config.TideCycle
	return Config.TideDry - phaseTime
end

local function waitForDryWindow(zoneData: { [string]: any }, minimumSeconds: number, timeout: number): boolean
	return waitFor(function()
		local bounds = fixture and fixture.Obstacles.ShipwreckHazards:FindFirstChild(zoneData.name .. "Bounds")
		return bounds ~= nil and bounds:GetAttribute("Phase") == "Dry"
			and remainingDry(zoneData) >= minimumSeconds
	end, timeout)
end

local function recoverInFixture(candidate: Player, reason: string)
	if candidate ~= player then
		return
	end
	recoveryCount += 1
	local recoveryFrom = root.Position
	local anchor = recoveryAnchor
	table.insert(hits, {
		stage = stage,
		reason = reason,
		time = math.round(currentRuntimeTime * 1000) / 1000,
		position = pointRecord(recoveryFrom),
	})
	character:SetAttribute("RecoveryUntil", Workspace:GetServerTimeNow() + 1)
	if anchor and anchor.Parent then
		placeOnSurface(anchor)
	end
	table.insert(recoveries, {
		stage = stage,
		reason = reason,
		anchor = anchor and anchor.Name or nil,
		from = pointRecord(recoveryFrom),
		to = pointRecord(root.Position),
		time = math.round(currentRuntimeTime * 1000) / 1000,
		mode = "probe-local fixture recovery; not RespawnService",
	})
	local coconutEvent = activeCoconutEvents[reason]
	if coconutEvent then
		coconutEvent.hit = true
		coconutEvent.hitTime = math.round(currentRuntimeTime * 1000) / 1000
	end
end

local function sampleCoconuts(now: number)
	if not fixture then
		return
	end
	for name, part in coconutParts do
		if not part.Parent then
			continue
		end
		local state = part:GetAttribute("State") or "Reset"
		local previous = coconutPreviousState[name] or "Reset"
		local data = coconutDataByName[name]
		local activeEvent = activeCoconutEvents[name]
		if state == "Warning" and previous ~= "Warning" then
			local marker = fixture.Decoration.Falling:FindFirstChild(name .. "Warning")
			activeEvent = {
				name = name,
				stageAtWarning = stage,
				warningTime = math.round(now * 1000) / 1000,
				warningPosition = pointRecord(marker and marker.Position or part.Position),
				distanceAtWarning = math.round((flat(root.Position - (marker and marker.Position or part.Position))).Magnitude * 100) / 100,
				minimumDistance = math.huge,
				states = { "Warning" },
				hit = false,
			}
			activeCoconutEvents[name] = activeEvent
		elseif activeEvent and state ~= previous then
			table.insert(activeEvent.states, state)
		end
		if activeEvent and (state == "Warning" or state == "Falling" or state == "Hold") then
			local marker = fixture.Decoration.Falling:FindFirstChild(name .. "Warning")
			local hazardPosition = if state == "Warning" and marker then marker.Position else part.Position
			activeEvent.minimumDistance = math.min(activeEvent.minimumDistance,
				(flat(root.Position - hazardPosition)).Magnitude)
		end
		if activeEvent and state == "Reset" and previous ~= "Reset" then
			activeEvent.minimumDistance = if activeEvent.minimumDistance == math.huge then nil
				else math.round(activeEvent.minimumDistance * 100) / 100
			activeEvent.radius = data and data.radius or nil
			activeEvent.outcome = if activeEvent.hit then "hit-and-recovered" else "no-runtime-hit"
			table.insert(groveTrial.coconutEvents, activeEvent)
			activeCoconutEvents[name] = nil
		end
		coconutPreviousState[name] = state
	end
end

local ok, errorText = pcall(function()
	fixture = installed:Clone()
	fixture.Name = fixtureName
	fixture:PivotTo(fixture:GetPivot() + Vector3.new(3000, 0, 0))
	fixture.Parent = Workspace
	local surfaces = fixture.Obstacles.WalkingSurfaces
	local east = assert(surfaces:FindFirstChild("SurgeEastRefuge"), "Missing east refuge")
	local middle = assert(surfaces:FindFirstChild("SurgeMiddleRefuge"), "Missing middle refuge")
	local west = assert(surfaces:FindFirstChild("SurgeWestRefuge"), "Missing west refuge")
	local passage1 = assert(surfaces:FindFirstChild("Surge1Passage"), "Missing Surge1 passage")
	local shoreEntry = assert(surfaces:FindFirstChild("ShoreEntry28"), "Missing shore entry")
	local shoreSurfaces = {}
	for _, name in { "S04_Shore_02", "S04_Shore_03", "S04_Shore_04", "S04_Shore_05", "S04_Shore_06" } do
		local surface = assert(surfaces:FindFirstChild(name), "Missing grove route surface " .. name)
		table.insert(shoreSurfaces, surface)
	end
	local surge1 = assert(Layout.surges[1], "Missing first surge definition")
	local surge2 = assert(Layout.surges[2], "Missing second surge definition")
	assert(surge1.name == "Surge1" and surge2.name == "Surge2", "Unexpected surge order")
	local wave1Bounds = assert(fixture.Obstacles.ShipwreckHazards:FindFirstChild("Surge1Bounds"), "Missing Surge1 bounds")
	local wave1Visuals = fixture.Decoration.Surge1
	for _, data in Layout.falling do
		if data.kind == "coconut" then
			local part = fixture.Decoration.Falling:FindFirstChild(data.name)
			assert(part and part:IsA("BasePart"), "Missing coconut visual " .. data.name)
			coconutDataByName[data.name] = data
			coconutParts[data.name] = part
		end
	end
	assert(next(coconutParts) ~= nil, "No coconut visuals were found")

	root.Anchored = false
	pcall(function()
		root:SetNetworkOwner(nil)
	end)
	humanoid.WalkSpeed = 16
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = 7.2
	humanoid.EvaluateStateMachine = true
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid.AutoRotate = true
	character:SetAttribute("RecoveryUntil", 0)

	placeOnSurface(east)
	character:SetAttribute("RecoveryUntil", 0)
	humanoid:ChangeState(Enum.HumanoidStateType.Running)
	recoveryAnchor = east
	controller = require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(fixture,
		recoverInFixture,
		function(candidate)
			return candidate == player
		end)
	local warningSound = assert(wave1Visuals.SurgeFoam:FindFirstChild("TideWarning"), "Missing runtime warning sound")
	controller.Reset()
	controller.Step(0, 0, false)
	runtimeEpoch = os.clock()
	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		if not controller or not fixture or runtimeError then
			return
		end
		currentRuntimeTime = runtimeTime()
		local stepOk, stepError = pcall(controller.Step, currentRuntimeTime, dt, true)
		if not stepOk then
			runtimeError = tostring(stepError)
			groveTrial.error = runtimeError
			waveTrial.error = runtimeError
			return
		end
		sampleCoconuts(currentRuntimeTime)
	end)
	script:SetAttribute("Build", Layout.build)
	script:SetAttribute("Candidate", "SC29_CANDIDATE_05 (parent-confirmed installed candidate)")

	-- Begin one crossing at the first real-time warning transition. A hit uses
	-- only a fixture-local checkpoint callback, so it cannot affect the live race.
	setStage("wave-warning-boundary")
	placeOnSurface(east)
	recoveryAnchor = east
	local warningReached = waitFor(function()
		return wave1Bounds:GetAttribute("Phase") == "Warning"
	end, Config.TideCycle + 1)
	if not warningReached then
		waveTrial.status = "warning-timeout"
	else
		local currentTime = runtimeTime()
		local water = wave1Visuals.SurgeWater
		local foam = wave1Visuals.SurgeFoam
		local wave = wave1Visuals.SurgeWave
		waveTrial.status = "attempting-from-warning"
		waveTrial.entryTime = math.round(currentTime * 1000) / 1000
		waveTrial.phaseAtEntry = wave1Bounds:GetAttribute("Phase")
		waveTrial.warningAudio = {
			isPlaying = warningSound.IsPlaying,
			volume = warningSound.Volume,
			soundId = warningSound.SoundId,
			playbackLoudness = warningSound.PlaybackLoudness,
			distanceToPlayer = math.round((warningSound.Parent.Position - root.Position).Magnitude * 100) / 100,
		}
		waveTrial.warningVisualsHidden = water.Transparency >= 0.99 and foam.Transparency >= 0.99
			and wave.Transparency >= 0.99
		local recoveryBefore = recoveryCount
		local started = runtimeTime()
		local sequence = {
			{ "warning-passage", passage1, 0, 0, false, 4 },
			{ "warning-passage-edge", passage1, -7.2, 0, false, 2.5 },
			{ "warning-wave-landing", middle, 11.4, 0, true, 3 },
			{ "warning-middle-refuge", middle, 0, 0, false, 2.5 },
		}
		local passed = true
		for _, step in sequence do
			local surface = step[2]
			if not recordMove(waveTrial, step[1], surface, step[3], step[4], step[5], step[6]) then
				passed = false
				break
			end
		end
		waveTrial.duration = math.round((runtimeTime() - started) * 1000) / 1000
		waveTrial.phaseAtExit = wave1Bounds:GetAttribute("Phase")
		waveTrial.newHits = #hits - (recoveryBefore)
		waveTrial.status = if recoveryCount > recoveryBefore then "hit-and-fixture-recovered"
			elseif passed then "crossed-without-runtime-hit" else "movement-did-not-finish"
	end
	waveTrial.totalHits = #hits
	waveTrial.recoveries = #recoveries

	-- Reset placement between focused segments, then walk the shore route on the
	-- same live controller and clock. The grove segment itself uses real physics.
	setStage("grove-approach")
	placeOnSurface(west)
	character:SetAttribute("RecoveryUntil", 0)
	recoveryAnchor = west
	groveHitStart = #hits
	groveRecoveryStart = #recoveries
	local dryWindow = waitForDryWindow(surge2, 4.2, Config.TideCycle * 2 + 2)
	if not dryWindow then
		groveTrial.status = "shore-entry-dry-window-timeout"
	else
	local approachStarted = runtimeTime()
	local exitedWave = recordMove(groveTrial, "west-refuge-to-shore-entry", shoreEntry, nil, nil, true, 3.5)
	if exitedWave then
		setStage("grove")
			local enteredBeach = recordMove(groveTrial, "shore-entry-to-beach", shoreSurfaces[1], nil, nil, true, 3.5)
			local walkedAll = enteredBeach
			if walkedAll then
				for index = 2, #shoreSurfaces do
					local target = shoreSurfaces[index]
					if not recordMove(groveTrial, "grove-" .. target.Name, target, nil, nil, true, 3.5) then
						walkedAll = false
						break
					end
				end
			end
			groveTrial.duration = math.round((runtimeTime() - approachStarted) * 1000) / 1000
		local groveHits = #hits - groveHitStart
		local lastGroveHit = if groveHits > 0 then hits[#hits] else nil
		local hitCoconut = lastGroveHit ~= nil and coconutDataByName[lastGroveHit.reason] ~= nil
		groveTrial.status = if hitCoconut then "coconut-hit-and-fixture-recovered"
			elseif groveHits > 0 then "other-hazard-hit-and-fixture-recovered"
			elseif walkedAll then "completed-without-runtime-hit"
			else "movement-did-not-finish"
	else
		groveTrial.status = if #hits > groveHitStart then "hit-before-grove-and-fixture-recovered"
			else "shore-entry-movement-did-not-finish"
	end
	end
	groveTrial.hits = #hits - groveHitStart
	groveTrial.recoveries = #recoveries - groveRecoveryStart

	-- Close any warning/fall cycle still active when the bounded walk ends.
	for name, activeEvent in activeCoconutEvents do
		activeEvent.minimumDistance = if activeEvent.minimumDistance == math.huge then nil
			else math.round(activeEvent.minimumDistance * 100) / 100
		activeEvent.radius = coconutDataByName[name] and coconutDataByName[name].radius or nil
		activeEvent.hit = activeEvent.hit or false
		activeEvent.outcome = if activeEvent.hit then "hit-and-recovered" else "still-active-at-end"
		table.insert(groveTrial.coconutEvents, activeEvent)
	end
	local groveWarnings = 0
	local groveNearWarnings = 0
	local groveNearDuringEvents = 0
	local groveCoconutHits = 0
	for _, event in groveTrial.coconutEvents do
		if event.stageAtWarning == "grove" then
			groveWarnings += 1
			if event.radius and event.distanceAtWarning <= event.radius then
				groveNearWarnings += 1
			end
			if event.radius and event.minimumDistance and event.minimumDistance <= event.radius + 2 then
				groveNearDuringEvents += 1
			end
			if event.hit then
				groveCoconutHits += 1
			end
		end
	end
	groveTrial.randomCoconutEvents = groveWarnings
	groveTrial.warningsStartingWithinRadius = groveNearWarnings
	groveTrial.eventsPassingWithinRadiusPlusTwoStuds = groveNearDuringEvents
	groveTrial.coconutHits = groveCoconutHits
	end)

if heartbeatConnection then
	heartbeatConnection:Disconnect()
end
if controller then
	pcall(function()
		controller.Stop()
	end)
end
if fixture then
	fixture:Destroy()
end
if character.Parent and player.Character == character then
	character:PivotTo(original.pivot)
	root.AssemblyLinearVelocity = original.linearVelocity
	root.AssemblyAngularVelocity = original.angularVelocity
	root.Anchored = original.anchored
	humanoid.WalkSpeed = original.walkSpeed
	humanoid.JumpHeight = original.jumpHeight
	humanoid.JumpPower = original.jumpPower
	humanoid.UseJumpPower = original.useJumpPower
	humanoid.AutoRotate = original.autoRotate
	humanoid.PlatformStand = original.platformStand
	humanoid.Sit = original.sit
	humanoid.EvaluateStateMachine = original.evaluateStateMachine
	character:SetAttribute("RecoveryUntil", original.recoveryUntil)
	if not original.anchored then
		pcall(function()
			if original.networkOwner and original.networkOwner.Parent then
				root:SetNetworkOwner(original.networkOwner)
			else
				root:SetNetworkOwnershipAuto()
			end
		end)
	end
end

script:SetAttribute("Result", HttpService:JSONEncode({
	build = Layout.build,
	candidate = "SC29_CANDIDATE_05 (parent-confirmed installed candidate)",
	passed = ok and runtimeError == nil,
	error = if not ok then tostring(errorText) else runtimeError,
	method = "One actual server-owned Studio R15 on an owned clone. Real-time Runtime.Step; no wave clock stepping. Explicit fixture-local recovery anchor; not the live RespawnService. Two focused segments with a fixture reposition between them; no full-race claim.",
	walkSpeed = 16,
	jumpHeight = 7.2,
	waveBoundary = waveTrial,
	grove = groveTrial,
	hits = hits,
	recoveries = recoveries,
	completedCoconutEvents = #groveTrial.coconutEvents,
}))
