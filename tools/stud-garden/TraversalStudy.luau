--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local Study = {}
local activeController: any = nil
local PROGRESS_ATTRIBUTES = {"CheckpointIndex", "LatestCheckpointIndex", "NextCheckpointIndex", "RaceStatus",
	"PlayerRaceStatus", "RaceState", "CurrentRaceId", "RaceId", "CourseId", "CurrentCourseId"}

local function vector(value: any): Vector3
	if typeof(value) == "Vector3" then return value end
	assert(type(value) == "table" and #value == 3, "Expected a three-number vector")
	for _, component in value do
		assert(type(component) == "number" and component == component and math.abs(component) < 1e7, "Invalid vector component")
	end
	return Vector3.new(value[1], value[2], value[3])
end

local function flat(value: Vector3): Vector3
	return Vector3.new(value.X, 0, value.Z)
end

local function packed(value: Vector3): {number}
	return {value.X, value.Y, value.Z}
end

local function boundary(size: Vector3, direction: Vector3, inset: number): number
	local x = if math.abs(direction.X) > 1e-5 then (size.X / 2 - inset) / math.abs(direction.X) else math.huge
	local z = if math.abs(direction.Z) > 1e-5 then (size.Z / 2 - inset) / math.abs(direction.Z) else math.huge
	return math.min(x, z)
end

-- Takeoffs and entries follow the center-to-center ray, including diagonal expert offsets.
function Study.PlanEdge(source: any, target: any): any
	local a, b = vector(source.position), vector(target.position)
	local aSize, bSize = vector(source.size), vector(target.size)
	local delta = flat(b - a)
	assert(delta.Magnitude > 0.1, "Consecutive waypoints have the same horizontal position")
	assert(math.min(aSize.X, aSize.Z, bSize.X, bSize.Z) >= 4, "Unsupported movement footprint")
	local direction = delta.Unit
	local expert = math.min(aSize.X, aSize.Z, bSize.X, bSize.Z) < 8
	local takeoffInset, landingInset = if expert then 0.2 else 0.5, if expert then 0.35 else 0.6
	local exit = a + direction * boundary(aSize, direction, 0)
	local entry = b - direction * boundary(bSize, direction, 0)
	local gap = math.max(0, (entry - exit):Dot(direction))
	local rise = b.Y - a.Y
	return {direction = direction, takeoff = a + direction * boundary(aSize, direction, takeoffInset),
		landing = b - direction * boundary(bSize, direction, landingInset), gap = gap, rise = rise,
		jump = gap > 0.75 or rise > 0.6, expert = expert}
end

function Study.SelectWaypoints(raw: any, options: any?): {any}
	local settings = options or {}
	local route = if type(raw) == "string" then HttpService:JSONDecode(raw) else raw
	assert(type(route) == "table", "Route JSON must contain an array")
	if route.waypoints then route = route.waypoints end
	assert(#route >= 2 and #route <= 500, "Expected 2–500 ordered route waypoints")
	local first, last = 1, #route
	if settings.sequenceId then
		local startIndex, endIndex
		for index, point in route do
			if point.sequenceId == settings.sequenceId then startIndex = startIndex or index; endIndex = index end
		end
		assert(startIndex and endIndex, "Sequence is absent from supplied route")
		first, last = math.max(1, startIndex - 1), endIndex
	end
	if settings.fromId then
		local found
		for index, point in route do if point.id == settings.fromId then found = index; break end end
		assert(found, "fromId is absent from route")
		first = found
	end
	if settings.toId then
		local found
		for index, point in route do if point.id == settings.toId then found = index; break end end
		assert(found, "toId is absent from route")
		last = found
	end
	assert(first < last, "Selected segment needs a supported starting point and a destination")
	local result, identities = {}, {}
	for index = first, last do
		local point = route[index]
		assert(type(point.id) == "string" and type(point.sequenceId) == "string" and not identities[point.id], "Invalid/duplicate waypoint identity")
		identities[point.id] = true
		local size = vector(point.size)
		assert(size.X > 0 and size.Y > 0 and size.Z > 0, "Invalid waypoint size")
		table.insert(result, {id = point.id, sequenceId = point.sequenceId, kind = point.kind,
			position = vector(point.position), size = size, sourceIndex = index})
	end
	return result
end

function Study.Stop(reason: string?): boolean
	if not activeController then return false end
	activeController.Stop(reason)
	return true
end

function Study.GetActive(): any
	return activeController
end

function Study.Start(course: Model, routeJson: any, options: any?): any
	assert(RunService:IsStudio() and RunService:IsClient() and RunService:IsRunning(), "TraversalStudy requires a running Studio client")
	assert(Workspace:GetAttribute("StudGardenTestEnabled") == true, "Explicit Stud Garden test flag required")
	assert(activeController == nil, "Stop the existing movement study first")
	assert(course:IsA("Model") and course:IsDescendantOf(Workspace) and course:GetAttribute("CourseId") == "stud_garden", "Active Stud Garden course required")
	local settings = options or {}
	if settings.expectedBuildId then assert(course:GetAttribute("StudGardenBuild") == settings.expectedBuildId, "Course build mismatch") end
	if settings.expectedLayoutRevision then assert(course:GetAttribute("LayoutRevision") == settings.expectedLayoutRevision, "Layout revision mismatch") end
	local points = Study.SelectWaypoints(routeJson, settings)
	local player = Players.LocalPlayer
	assert(player and player.Character, "Local player character is missing")
	local character = player.Character :: Model
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
	assert(humanoid and root and root:IsA("BasePart"), "Normal local humanoid/root required")
	assert(humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight - 7.2) < 0.001, "Expected inherited WalkSpeed16 / JumpHeight7.2")
	assert(not root.Anchored and humanoid.Health > 0, "Character is not movable")
	local bounds = course:FindFirstChild("Bounds")
	local originMarker = bounds and bounds:FindFirstChild("CourseOrigin")
	local origin = if settings.origin then CFrame.new(vector(settings.origin))
		elseif originMarker and originMarker:IsA("BasePart") then originMarker.CFrame
		else CFrame.new(vector(course:GetAttribute("CourseOrigin")))
	assert(origin.UpVector:Dot(Vector3.yAxis) > 0.999, "Course origin must be upright")
	local nativeById: any = {}
	for _, part in course:GetDescendants() do
		if part:IsA("BasePart") and part.CanCollide and part:GetAttribute("CoreFloor") == true and part:GetAttribute("WalkSurface") == true then
			local id = part:GetAttribute("PointId")
			if part:GetAttribute("HazardId") then
				local suffix = ({DryBefore = "Before", Walkway = "Crossing", DryAfter = "After"})[part.Parent.Name]
				if suffix then id = part:GetAttribute("HazardId") .. "_" .. suffix end
			end
			if type(id) == "string" then
				assert(not nativeById[id], "Duplicate native floor identity " .. id)
				nativeById[id] = part
			end
		end
	end
	for _, point in points do
		local floor = nativeById[point.id]
		assert(floor, "Native movement floor missing: " .. point.id)
		local nativeTop = origin:PointToObjectSpace(floor.Position + floor.CFrame.UpVector * floor.Size.Y / 2)
		assert((nativeTop - point.position).Magnitude < 0.05 and (floor.Size - point.size).Magnitude < 0.05, "Route/native footprint mismatch: " .. point.id)
		assert(floor.CFrame.UpVector:Dot(Vector3.yAxis) > 0.999 and math.abs(floor.CFrame.RightVector:Dot(origin.RightVector)) > 0.999, "Rotated waypoint is unsupported: " .. point.id)
		point.floor = floor
	end
	local hazards: any = {}
	local suppliedHazards = settings.hazards or {}
	if type(suppliedHazards) == "string" then suppliedHazards = HttpService:JSONDecode(suppliedHazards) end
	for key, data in suppliedHazards do
		local id = data.id or key
		local volume = data.volume
		assert(type(id) == "string" and volume and type(data.clearSeconds) == "number", "Hazard metadata needs id, volume and clearSeconds")
		hazards[id] = {position = vector(volume.position), size = vector(volume.size), clearSeconds = data.clearSeconds}
	end
	local runtime = course:FindFirstChild("StudGardenRuntime")
	for _, point in points do
		if point.kind == "hazard" then
			local metadata = hazards[point.sequenceId]
			assert(metadata and runtime, "Supply exact hazard volume metadata and an active native runtime")
			local part = runtime:FindFirstChild(if point.sequenceId == "H01" then "H01_WaterSweep" else "H02_HarvestFruit")
			assert(part and type(part:GetAttribute("Phase")) == "string", "Native hazard phase missing")
			metadata.part = part
		end
	end
	local params = RaycastParams.new()
	params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {course}
	params.RespectCanCollide = true
	local function support(): RaycastResult?
		return Workspace:Raycast(root.Position, -Vector3.yAxis * (humanoid.HipHeight + root.Size.Y / 2 + 4), params)
	end
	local initialSupport = support()
	assert(humanoid.FloorMaterial ~= Enum.Material.Air and initialSupport and initialSupport.Instance == points[1].floor, "Stand on the selected first waypoint before starting")
	local standingOffset = root.Position.Y - initialSupport.Position.Y
	assert(standingOffset >= 1 and standingOffset <= 6, "Unexpected humanoid standing height")
	local playerModule = player.PlayerScripts:FindFirstChild("PlayerModule")
	assert(playerModule and playerModule:IsA("ModuleScript"), "PlayerModule is missing")
	local controls: any = require(playerModule):GetControls()
	local controlsWereEnabled = if type(controls.controlsEnabled) == "boolean" then controls.controlsEnabled else controls.enabled
	assert(type(controlsWereEnabled) == "boolean", "Cannot read prior PlayerModule control state safely")
	local tests = player.PlayerScripts:FindFirstChild("StudGardenTraversalStudies")
	if not tests then tests = Instance.new("Folder"); tests.Name = "StudGardenTraversalStudies"; tests.Parent = player.PlayerScripts end
	local folder = Instance.new("Folder")
	folder.Name = "Proxy_" .. HttpService:GenerateGUID(false)
	folder.Parent = tests
	local resultValue = Instance.new("StringValue")
	resultValue.Name, resultValue.Parent = "ResultJSON", folder
	local started = os.clock()
	local report: any = {evidence = "Studio client scripted normal-movement proxy; not human input or multiplayer proof",
		status = "Starting", buildId = course:GetAttribute("StudGardenBuild"), layoutRevision = course:GetAttribute("LayoutRevision"),
		route = settings.routeName or "supplied", sequenceId = settings.sequenceId, firstId = points[1].id, lastId = points[#points].id,
		plannedPoints = #points, reached = {}, jumps = {}, hazardWaits = {}, progressEvents = {}, elapsedSeconds = 0,
		movementSeconds = 0, commandedMoveSeconds = 0, hazardWaitSeconds = 0, controlsRestored = false,
		initialControlsEnabled = controlsWereEnabled, movement = {walkSpeed = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight, gravity = Workspace.Gravity}}
	local controller: any = {Folder = folder}
	local stopped, cleaned, moved = false, false, false
	local lastPosition, recoveryBaseline = root.Position, character:GetAttribute("RecoveryUntil") or 0
	local lastProgress = ""
	local publishAt = 0
	local activeHazard: any = nil
	local inHazardWait = false
	local finishLockObserved = false
	local destroyConnection: RBXScriptConnection? = nil
	local maxSeconds = settings.maxSeconds or (if settings.sequenceId or settings.fromId or settings.toId then 60 else 480)
	assert(type(maxSeconds) == "number" and maxSeconds > 0 and maxSeconds <= 600, "Study time bound must be 1–600 seconds")
	local function progress()
		local values: any = {}
		for _, name in PROGRESS_ATTRIBUTES do
			local value = player:GetAttribute(name)
			if value ~= nil then values[name] = value end
		end
		local encoded = HttpService:JSONEncode(values)
		if encoded ~= lastProgress then
			lastProgress = encoded
			table.insert(report.progressEvents, {elapsedSeconds = os.clock() - started, attributes = values})
		end
		report.latestProgress = values
		report.checkpointProgressAvailable = values.CheckpointIndex ~= nil or values.LatestCheckpointIndex ~= nil or values.NextCheckpointIndex ~= nil
		report.raceStatusAvailable = values.RaceStatus ~= nil or values.PlayerRaceStatus ~= nil or values.RaceState ~= nil
		report.progressAvailable = report.checkpointProgressAvailable or report.raceStatusAvailable
	end
	local function publish(force: boolean?)
		if not force and os.clock() < publishAt then return end
		publishAt = os.clock() + 0.25
		report.elapsedSeconds = os.clock() - started
		report.position = packed(origin:PointToObjectSpace(root.Position))
		progress()
		if folder.Parent then
			folder:SetAttribute("Status", report.status)
			folder:SetAttribute("CurrentPoint", report.currentPoint)
			folder:SetAttribute("ReachedCount", #report.reached)
			folder:SetAttribute("JumpCount", #report.jumps)
			folder:SetAttribute("ElapsedSeconds", report.elapsedSeconds)
			folder:SetAttribute("MovementSeconds", report.movementSeconds)
			folder:SetAttribute("HazardWaitSeconds", report.hazardWaitSeconds)
			folder:SetAttribute("ControlsRestored", report.controlsRestored)
			folder:SetAttribute("ProgressAvailable", report.progressAvailable)
			resultValue.Value = HttpService:JSONEncode(report)
		end
	end
	local function restore()
		if cleaned then return end
		cleaned = true
		local moveOk, moveError = pcall(function() humanoid:Move(Vector3.zero, false); humanoid.Jump = false end)
		local controlsOk, controlsError = pcall(function()
			if controlsWereEnabled then controls:Enable() else controls:Disable() end
		end)
		report.controlsRestored = controlsOk
		if not moveOk then report.stopMovementError = tostring(moveError) end
		if not controlsOk then report.restoreError = tostring(controlsError) end
		if destroyConnection then destroyConnection:Disconnect(); destroyConnection = nil end
		if activeController == controller then activeController = nil end
	end
	function controller.Stop(reason: string?)
		if cleaned then return end
		stopped = true
		report.status, report.reason = "Stopped", reason or "Stopped by owner"
		restore()
		publish(true)
	end
	function controller.GetReport(): any
		return HttpService:JSONDecode(resultValue.Value)
	end
	function controller.GetStatus(): string
		return report.status
	end
	local function command(direction: Vector3)
		assert(not stopped, report.reason or "Study stopped")
		moved = direction.Magnitude > 0.01
		humanoid:Move(direction, false)
	end
	local function supportedFinishLock(): boolean
		if not root.Anchored then return false end
		local finish = course:FindFirstChild("Finish")
		local hit = support()
		if not finish or not finish:IsA("BasePart") or not hit or hit.Instance ~= points[#points].floor then return false end
		local relative = finish.CFrame:PointToObjectSpace(root.Position)
		return math.abs(relative.X) <= finish.Size.X / 2 + 2 and math.abs(relative.Y) <= finish.Size.Y / 2 + 2
			and math.abs(relative.Z) <= finish.Size.Z / 2 + 3
	end
	local function frame(allowFinish: boolean?): number
		local dt = RunService.Heartbeat:Wait()
		assert(not stopped, report.reason or "Study stopped")
		assert(dt <= 0.5, "Frame stall exceeded 0.5 seconds")
		assert(os.clock() - started < maxSeconds, "Study duration limit reached")
		assert(player.Character == character and character.Parent and humanoid.Health > 0, "Character replaced or died")
		if allowFinish and supportedFinishLock() then finishLockObserved = true end
		assert((not root.Anchored or finishLockObserved) and course:IsDescendantOf(Workspace) and folder.Parent, "Character/course/test folder became unavailable")
		assert((character:GetAttribute("RecoveryUntil") or 0) <= recoveryBaseline, "Unexpected server recovery")
		local displacement = root.Position - lastPosition
		assert(displacement.Magnitude <= math.max(6, 16 * dt + 3), "Unexpected position discontinuity")
		if flat(displacement).Magnitude > 0.015 then report.movementSeconds += dt end
		if moved then report.commandedMoveSeconds += dt end
		if inHazardWait then report.hazardWaitSeconds += dt end
		lastPosition = root.Position
		if not allowFinish then
			assert(humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight - 7.2) < 0.001, "Movement settings changed during study")
		end
		assert(math.abs(Workspace.Gravity - report.movement.gravity) < 0.001, "Gravity changed during study")
		if activeHazard then assert(activeHazard.part:GetAttribute("Phase") == "Clear", "Hazard Clear window closed during crossing") end
		publish()
		return dt
	end
	local function groundedOn(point: any): boolean
		local hit = support()
		return humanoid.FloorMaterial ~= Enum.Material.Air and hit ~= nil and hit.Instance == point.floor
			and math.abs(root.Position.Y - hit.Position.Y - standingOffset) < 0.8
	end
	local function walkTo(point: any, localTarget: Vector3, tolerance: number, final: boolean?)
		local target = origin:PointToWorldSpace(localTarget)
		local best, progressedAt = math.huge, os.clock()
		while true do
			if final and finishLockObserved then command(Vector3.zero); return end
			local delta = flat(target - root.Position)
			if delta.Magnitude <= tolerance and groundedOn(point) then command(Vector3.zero); return end
			assert(groundedOn(point), "Lost expected supported walkway: " .. point.id)
			if delta.Magnitude < best - 0.1 then best, progressedAt = delta.Magnitude, os.clock() end
			assert(os.clock() - progressedAt < 6, "Supported walk stalled: " .. point.id)
			command(if delta.Magnitude > tolerance then delta.Unit else Vector3.zero)
			frame(final)
		end
	end
	local function reach(point: any, initial: boolean?)
		report.currentPoint = point.id
		table.insert(report.reached, {id = point.id, elapsedSeconds = os.clock() - started, initialSupport = initial == true,
			position = packed(origin:PointToObjectSpace(root.Position))})
		publish(true)
	end
	local function outsideVolume(metadata: any): boolean
		local localPosition = origin:PointToObjectSpace(root.Position)
		local delta = localPosition - metadata.position
		return math.abs(delta.X) > metadata.size.X / 2 + 1.5 or math.abs(delta.Z) > metadata.size.Z / 2 + 1.5
	end
	local function waitForHazard(point: any)
		local metadata = hazards[point.sequenceId]
		assert(metadata and groundedOn(point) and outsideVolume(metadata), "Hazard wait must be supported outside the full swept volume")
		local crossing, after
		for _, candidate in points do
			if candidate.id == point.sequenceId .. "_Crossing" then crossing = candidate end
			if candidate.id == point.sequenceId .. "_After" then after = candidate end
		end
		assert(crossing and after, "Hazard segment must include its crossing and dry after-refuge")
		local estimate = (flat(crossing.position - point.position).Magnitude + flat(after.position - crossing.position).Magnitude) / 16 + 0.7
		assert(metadata.clearSeconds >= estimate, "Declared Clear duration is too short for conservative crossing")
		report.status = "WaitingForClear"
		command(Vector3.zero)
		local began, phase = os.clock(), metadata.part:GetAttribute("Phase")
		local sawNonClear = phase ~= "Clear"
		inHazardWait = true
		while true do
			assert(groundedOn(point) and outsideVolume(metadata), "Left safe refuge while waiting")
			phase = metadata.part:GetAttribute("Phase")
			assert(phase == "Clear" or phase == "Warning" or phase == "Active", "Unknown hazard phase")
			if phase ~= "Clear" then sawNonClear = true end
			if phase == "Clear" and sawNonClear then break end
			assert(os.clock() - began < 18, "No fresh Clear transition within 18 seconds; check active race/runtime")
			frame()
		end
		inHazardWait = false
		table.insert(report.hazardWaits, {id = point.sequenceId, seconds = os.clock() - began, policy = "fresh Clear transition", estimatedCrossingSeconds = estimate})
		activeHazard = metadata
		report.status = "Moving"
		publish(true)
	end
	local function moveEdge(source: any, target: any)
		local plan = Study.PlanEdge(source, target)
		report.currentPoint = target.id
		local final = target.id == "F0"
		if not plan.jump then
			local worldTarget = origin:PointToWorldSpace(target.position)
			local best, progressedAt = math.huge, os.clock()
			while not (groundedOn(target) and flat(worldTarget - root.Position).Magnitude <= 0.8) do
				if final and finishLockObserved then break end
				assert(groundedOn(source) or groundedOn(target), "Unsupported walking connection " .. source.id .. "→" .. target.id)
				local delta = flat(worldTarget - root.Position)
				if delta.Magnitude < best - 0.1 then best, progressedAt = delta.Magnitude, os.clock() end
				assert(os.clock() - progressedAt < 6, "Walking connection stalled")
				command(if delta.Magnitude > 0.8 then delta.Unit else Vector3.zero)
				frame(final)
			end
		else
			walkTo(source, plan.takeoff, 0.2)
			assert(groundedOn(source), "Jump takeoff has no native support")
			local jumpRecord: any = {fromId = source.id, toId = target.id, elapsedSeconds = os.clock() - started,
				gap = plan.gap, rise = plan.rise, takeoffPosition = packed(origin:PointToObjectSpace(root.Position)), landed = false}
			table.insert(report.jumps, jumpRecord)
			local began, airborne = os.clock(), false
			local worldLanding = origin:PointToWorldSpace(plan.landing)
			humanoid.Jump = true
			while true do
				local hit = support()
				local inAir = humanoid.FloorMaterial == Enum.Material.Air
				if inAir then airborne = true; humanoid.Jump = false end
				if airborne and groundedOn(target) then jumpRecord.landed = true; jumpRecord.flightSeconds = os.clock() - began; break end
				assert(os.clock() - began < 2.5, "Jump failed to land on expected floor " .. target.id)
				assert(airborne or os.clock() - began < 0.45, "Requested jump did not become airborne")
				if airborne and not inAir and hit then error("Landed on unexpected surface before " .. target.id) end
				assert(root.Position.Y - standingOffset >= origin.Position.Y + math.min(source.position.Y, target.position.Y) - 2, "Fell below intended jump")
				local delta = flat(worldLanding - root.Position)
				command(if delta.Magnitude > 0.18 then delta.Unit else Vector3.zero)
				frame(final)
			end
			humanoid.Jump = false
			walkTo(target, target.position, 0.8, final)
		end
		command(Vector3.zero)
		reach(target)
		if activeHazard and target.id == target.sequenceId .. "_After" then activeHazard = nil end
	end
	progress()
	publish(true)
	activeController = controller
	local ok, disableError = pcall(function() controls:Disable() end)
	if not ok then restore(); error(disableError) end
	if typeof(script) == "Instance" then destroyConnection = script.Destroying:Connect(function() controller.Stop("Helper script was removed") end) end
	task.spawn(function()
		local ran, failure = xpcall(function()
			report.status = "Moving"
			walkTo(points[1], points[1].position, 0.8)
			reach(points[1], true)
			for index = 2, #points do
				local source, target = points[index - 1], points[index]
				if source.kind == "hazard" and source.id == source.sequenceId .. "_Before" then waitForHazard(source) end
				assert(target.kind ~= "hazard" or target.id == target.sequenceId .. "_Before" or activeHazard,
					"Hazard crossing requires its dry before-refuge and fresh Clear wait")
				moveEdge(source, target)
			end
			if finishLockObserved then
				report.status = "StoppedAtFinishTrigger"
				report.finishLockObserved = true
				report.completionBasis = "Native finish support/trigger proximity and server anchoring observed; confirm actual Finished status in the existing server snapshot"
			else
				report.status = if points[#points].id == "F0" then "CompletedProxyRoute" else "CompletedSegment"
			end
		end, function(message) return debug.traceback(tostring(message), 2) end)
		if not ran and not stopped then report.status, report.reason = "Failed", failure end
		restore()
		publish(true)
	end)
	return controller
end

return Study
