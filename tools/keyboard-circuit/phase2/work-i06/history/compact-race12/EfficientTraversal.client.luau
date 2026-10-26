--!strict
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client fixture required")
local Factory = {}
local binding = "KCP2I06EfficientTraversal"
local function vector(value: Vector3) return {value.X, value.Y, value.Z} end
local function horizontal(value: Vector3) return Vector3.new(value.X, 0, value.Z) end

function Factory.Edge(part: BasePart, direction: Vector3, margin: number): Vector3
	local localDirection = part.CFrame:VectorToObjectSpace(direction)
	local x = if math.abs(localDirection.X) > .001 then (part.Size.X / 2 - margin) / math.abs(localDirection.X) else math.huge
	local z = if math.abs(localDirection.Z) > .001 then (part.Size.Z / 2 - margin) / math.abs(localDirection.Z) else math.huge
	assert(math.min(x, z) >= 0, "Landing is narrower than the requested inset")
	return part.Position + direction * math.min(x, z)
end

function Factory.New(candidate: Model, player: Player, guard: () -> ())
	local character = assert(player.Character)
	local root = assert(character:FindFirstChild("HumanoidRootPart")) :: BasePart
	local humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
	local ray = RaycastParams.new()
	ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {candidate}, true
	local records, current, preparedTakeoff = {}, nil, nil
	local stopped = false
	local driver = {}
	local function ground()
		return workspace:Raycast(root.Position, Vector3.new(0, -7, 0), ray)
	end
	local function supported(part: BasePart): boolean
		local hit = ground()
		return humanoid.FloorMaterial ~= Enum.Material.Air and hit ~= nil and hit.Instance == part
	end
	local function supportNormalSpeed(part: BasePart): number
		local surfaceVelocity = part.AssemblyLinearVelocity + part.AssemblyAngularVelocity:Cross(root.Position - part.AssemblyCenterOfMass)
		return (root.AssemblyLinearVelocity - surfaceVelocity):Dot(part.CFrame.UpVector)
	end
	local function inside(part: BasePart, inset: number): boolean
		local point = part.CFrame:PointToObjectSpace(root.Position)
		return math.abs(point.X) <= part.Size.X / 2 - inset and math.abs(point.Z) <= part.Size.Z / 2 - inset
	end
	local function updateGroundWait(entry)
		if entry.groundReadinessUpdatedClock then
			local now = os.clock()
			entry.groundReadinessWaitSeconds += now - entry.groundReadinessUpdatedClock
			entry.groundReadinessUpdatedClock = now
		end
	end
	local function commandFrame(dt: number)
		if stopped or not current or player.Character ~= character then return end
		local command = current
		local target = if type(command.target) == "function" then command.target() else command.target
		local delta = horizontal(target - root.Position)
		local scale = if command.waitingForGround or delta.Magnitude <= command.stopRadius then 0 else if command.precision then math.min(1, delta.Magnitude / .8) else 1
		humanoid:Move(if scale > 0 then delta.Unit * scale else Vector3.zero, false)
		if command.jump and not command.jumped then
			humanoid.Jump = true
			if humanoid.FloorMaterial == Enum.Material.Air and root.AssemblyLinearVelocity.Y > 1 then command.jumped = true end
		else humanoid.Jump = false end
		if command.entry then
			local entry = command.entry
			entry.commandedMoveSeconds += if scale > 0 then dt else 0
			entry.airLandingHoldSeconds += if scale == 0 and humanoid.FloorMaterial == Enum.Material.Air then dt else 0
			if command.previousPosition then entry.sampledPathStuds += horizontal(root.Position - command.previousPosition).Magnitude end
			command.previousPosition = root.Position
		end
	end
	RunService:BindToRenderStep(binding, Enum.RenderPriority.Character.Value + 10, commandFrame)
	function driver.Hold()
		if current and current.entry and not current.entry.elapsed then
			local entry, hit = current.entry, ground()
			entry.elapsed, entry.finish, entry.finishSupport, entry.arrived, entry.interrupted = os.clock() - entry.beganClock, vector(root.Position), hit and hit.Instance:GetFullName(), false, true
			entry.finishVelocity = vector(root.AssemblyLinearVelocity)
			updateGroundWait(entry)
			entry.groundReadinessUpdatedClock = nil
		end
		current = nil
		humanoid.Jump = false
		humanoid:Move(Vector3.zero, false)
	end
	function driver.Support(part: BasePart): boolean return supported(part) end
	function driver.Move(label: string, target, jumping: boolean, expected: BasePart, options)
		guard()
		assert(not stopped, "Efficient driver stopped")
		local settings = options or {}
		local first = ground()
		local began = os.clock()
		local entry: any = {label = label, jump = jumping, beganClock = began, target = vector(if type(target) == "function" then target() else target),
			expectedSupport = expected:GetFullName(), start = vector(root.Position), startSupport = first and first.Instance:GetFullName(),
			startVelocity = vector(root.AssemblyLinearVelocity),
			at = workspace:GetServerTimeNow(), samples = {}, commandedMoveSeconds = 0, airLandingHoldSeconds = 0, sampledPathStuds = 0,
			flowLanding = settings.flowLanding == true, precision = settings.precision == true, launch = settings.launch, groundReadinessWaitSeconds = 0}
		table.insert(records, entry)
		current = {target = target, jump = jumping, jumped = false, precision = settings.precision == true,
			stopRadius = settings.stopRadius or .25, entry = entry, previousPosition = root.Position}
		commandFrame(0)
		local airborne, arrived, sampled, readinessBegan, readyFrames = false, false, -math.huge, nil, 0
		while os.clock() - began < (settings.seconds or 6) do
			guard()
			local hit = ground()
			local point = if type(target) == "function" then target() else target
			local distance = horizontal(point - root.Position).Magnitude
			if humanoid.FloorMaterial == Enum.Material.Air then airborne = true end
			local landed = supported(expected) and (not jumping or airborne)
			local atGoal = landed and (if settings.flowLanding then inside(expected, settings.landingInset or .2) else distance < (settings.tolerance or .4))
			local normalSpeed = supportNormalSpeed(expected)
			local supportReady = landed and math.abs(normalSpeed) <= 2
			readyFrames = if supportReady then readyFrames + 1 else 0
			if current.waitingForGround and readyFrames >= 2 then
				updateGroundWait(entry)
				entry.groundReadinessUpdatedClock = nil
				current.waitingForGround = false
				commandFrame(0)
			end
			if atGoal and supportReady and (not readinessBegan or readyFrames >= 2) then arrived = true; break end
			if atGoal and math.abs(normalSpeed) > 2 then
				readinessBegan = readinessBegan or os.clock()
				entry.groundReadinessBeganClock = readinessBegan
				if not current.waitingForGround then entry.groundReadinessUpdatedClock = os.clock() end
				current.waitingForGround = true
				commandFrame(0)
			end
			updateGroundWait(entry)
			if os.clock() - sampled >= .08 then
				sampled = os.clock()
				table.insert(entry.samples, {t = sampled - began, p = vector(root.Position), velocity = vector(root.AssemblyLinearVelocity), supportNormalSpeed = normalSpeed, floor = humanoid.FloorMaterial.Name, support = hit and hit.Instance:GetFullName()})
			end
			RunService.RenderStepped:Wait()
		end
		local last = ground()
		entry.finish, entry.finishSupport, entry.arrived, entry.elapsed, entry.airborne = vector(root.Position), last and last.Instance:GetFullName(), arrived, os.clock() - began, airborne
		entry.finishVelocity = vector(root.AssemblyLinearVelocity)
		entry.finishSupportNormalSpeed = supportNormalSpeed(expected)
		updateGroundWait(entry)
		entry.groundReadinessUpdatedClock = nil
		if not arrived or settings.holdOnArrival then driver.Hold() end
		return arrived, entry
	end
	function driver.Prepare(label: string, from: BasePart, to: BasePart, toPosition: Vector3?)
		local delta = horizontal((toPosition or to.Position) - from.Position)
		assert(delta.Magnitude > .001, "Distinct transfer contacts required")
		local direction = delta.Unit
		local edge = Factory.Edge(from, direction, .9)
		local arrived, entry = driver.Move(label .. " takeoff", edge, false, from,
			{seconds = 6, tolerance = .4, precision = true, stopRadius = .1, holdOnArrival = true})
		assert(arrived, label .. " takeoff")
		entry.edgeOvershootStuds = horizontal(root.Position - edge):Dot(direction)
		preparedTakeoff = {from = from, at = os.clock(), overshoot = entry.edgeOvershootStuds}
		return direction
	end
	local function launchVelocity(direction: Vector3)
		local velocity = horizontal(root.AssemblyLinearVelocity)
		local forward = velocity:Dot(direction)
		return {velocity = vector(velocity), speed = velocity.Magnitude, forwardSpeed = forward, lateralSpeed = (velocity - direction * forward).Magnitude}
	end
	local function settleTakeoff(label: string, from: BasePart, direction: Vector3, pendingEdgeReversal: boolean)
		local before = launchVelocity(direction)
		if before.forwardSpeed >= -.5 and before.lateralSpeed <= 2 and not pendingEdgeReversal then return before, 0 end
		driver.Hold()
		local began, first = os.clock(), ground()
		local entry: any = {label = label .. " takeoff settle", jump = false, controlHold = true, beganClock = began,
			at = workspace:GetServerTimeNow(), expectedSupport = from:GetFullName(), target = vector(root.Position), start = vector(root.Position),
			startSupport = first and first.Instance:GetFullName(), startVelocity = vector(root.AssemblyLinearVelocity), launchBefore = before, pendingEdgeReversal = pendingEdgeReversal,
			samples = {}, commandedMoveSeconds = 0, airLandingHoldSeconds = 0, sampledPathStuds = 0}
		table.insert(records, entry)
		current = {target = function() return root.Position end, jump = false, jumped = false, precision = true,
			stopRadius = .1, entry = entry, previousPosition = root.Position}
		commandFrame(0)
		local sampled, frames = -math.huge, 0
		while os.clock() - began < .8 do
			guard()
			assert(supported(from), label .. " takeoff settle lost departure support")
			if horizontal(root.AssemblyLinearVelocity).Magnitude <= .5 and (not pendingEdgeReversal or frames > 0) then break end
			if os.clock() - sampled >= .04 then
				sampled = os.clock()
				table.insert(entry.samples, {t = sampled - began, p = vector(root.Position), velocity = vector(root.AssemblyLinearVelocity), floor = humanoid.FloorMaterial.Name, support = from:GetFullName()})
			end
			RunService.RenderStepped:Wait()
			frames += 1
		end
		local last = ground()
		entry.finish, entry.finishVelocity, entry.finishSupport = vector(root.Position), vector(root.AssemblyLinearVelocity), last and last.Instance:GetFullName()
		entry.elapsed, entry.arrived = os.clock() - began, supported(from) and horizontal(root.AssemblyLinearVelocity).Magnitude <= .5
		driver.Hold()
		assert(entry.arrived, label .. " takeoff velocity did not settle")
		return before, entry.elapsed
	end
	function driver.Cross(label: string, from: BasePart, to: BasePart, preparedDirection: Vector3?, arrivalTarget: Vector3?)
		local direction = preparedDirection or driver.Prepare(label, from, to)
		assert(supported(from), label .. " departure support")
		assert(math.abs(supportNormalSpeed(from)) <= 2, label .. " departure still rising or falling relative to support")
		local precision = math.min(to.Size.X, to.Size.Z) <= 3
		local target = if arrivalTarget then arrivalTarget else function() return if precision then to.Position else Factory.Edge(to, direction, .8) end
		local aim = horizontal((if type(target) == "function" then target() else target) - root.Position)
		assert(aim.Magnitude > .001, label .. " distinct jump target")
		-- A just-overshot edge can leave a reversing input queued for the next frame.
		local pendingEdgeReversal = preparedTakeoff ~= nil and preparedTakeoff.from == from and os.clock() - preparedTakeoff.at < .25 and preparedTakeoff.overshoot > .05
		local before, settleSeconds = settleTakeoff(label, from, aim.Unit, pendingEdgeReversal)
		preparedTakeoff = nil
		local atLaunch = launchVelocity(aim.Unit)
		atLaunch.supportNormalSpeed = supportNormalSpeed(from)
		assert(supported(from) and math.abs(atLaunch.supportNormalSpeed) <= 2, label .. " settled departure support")
		local arrived, entry = driver.Move(label .. " jump", target, true, to,
			{seconds = 4, flowLanding = not precision, precision = precision, tolerance = .25, stopRadius = if precision then .1 else .25,
				launch = {direction = vector(aim.Unit), before = before, after = atLaunch, settleSeconds = settleSeconds, pendingEdgeReversal = pendingEdgeReversal}})
		return arrived, entry
	end
	function driver.Records() return records end
	function driver.Stop()
		if stopped then return end
		stopped = true
		local unbound, unbindError = pcall(RunService.UnbindFromRenderStep, RunService, binding)
		local cleared, clearError = pcall(driver.Hold)
		return {unbound = unbound, avatarCleared = cleared, unbindError = if unbound then nil else tostring(unbindError), avatarError = if cleared then nil else tostring(clearError)}
	end
	return driver
end

shared.KCP2I06EfficientTraversal = Factory
return {installed = true, factory = "shared.KCP2I06EfficientTraversal", boundary = "Ordinary Humanoid movement only; validated support and airborne transitions; no character positioning or movement tuning."}
