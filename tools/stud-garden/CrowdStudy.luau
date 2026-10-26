--!strict

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local HttpService = game:GetService("HttpService")
local Config = require(game.ReplicatedStorage.Config.StudGardenConfig)
local Layout = require(game.ServerStorage.CourseBuilders.StudGarden.Layout)
local CourseService = require(game.ServerScriptService.Services.CourseService)

local Study = {}
local PLACE_ID = 85558151074819
local activeFolder: Folder? = nil
local CASES = {"Start20", "H01_Clear", "H02_Clear", "K1_Merge", "K2_Merge",
	"R1_Returns", "R2_Returns", "R3_Returns", "R4_Returns"}

local function guard()
	assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning(),
		"CrowdStudy requires a running Studio server")
	assert(game.PlaceId == PLACE_ID, "CrowdStudy place mismatch")
end

function Study.Cases(): {string}
	return table.clone(CASES)
end

function Study.Cleanup(): boolean
	guard()
	if activeFolder == nil then return false end
	activeFolder:Destroy()
	activeFolder = nil
	return true
end

local function flat(value: Vector3): Vector3
	return Vector3.new(value.X, 0, value.Z)
end

local function lateral(direction: Vector3): Vector3
	local forward = if flat(direction).Magnitude > 0.01 then flat(direction).Unit else Vector3.zAxis
	return Vector3.new(-forward.Z, 0, forward.X)
end

local function boundary(record: any, anchor: Vector3, direction: Vector3, inset: number): number
	local relative = anchor - record.position
	local distance = math.huge
	for _, axis in {"X", "Z"} do
		if math.abs(direction[axis]) > 1e-5 then
			local margin = record.size[axis] / 2 - inset - relative[axis] * math.sign(direction[axis])
			distance = math.min(distance, margin / math.abs(direction[axis]))
		end
	end
	return math.max(0, distance)
end

local function plan(caseId: string, layout: any): any
	local actors = {}
	local function add(source: any, path: {any}, side: number, back: number, group: string, lane: number?)
		local forward = flat(path[1].position - source.position).Unit
		table.insert(actors, {source = source, path = path, offset = lateral(forward) * side - forward * back,
			lane = lane or side, group = group})
	end
	local function finish(description: any, columns: number, sideSpacing: number, rowSpacing: number, bias: number): any
		local rows = math.ceil(#actors / columns)
		for index, actor in actors do
			local last = actor.path[#actor.path]
			local previous = actor.path[#actor.path - 1] or actor.source
			local forward = last.forward or flat(last.position - previous.position).Unit
			local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
			actor.endPosition = last.position + lateral(forward) * ((column - (columns - 1) / 2) * sideSpacing)
				+ forward * (bias + ((rows - 1) / 2 - row) * rowSpacing)
		end
		return description
	end
	local function first(id: string, count: number): {any}
		local result = {}
		for index = 1, math.min(count, #layout.sequenceById[id].points) do
			table.insert(result, layout.sequenceById[id].points[index])
		end
		return result
	end
	if caseId == "Start20" then
		local path = {}
		for _, id in {"A1", "A2"} do
			for _, point in layout.sequenceById[id].points do table.insert(path, point) end
		end
		for row = 0, 3 do
			for column = 0, 4 do add(layout.nodeById.R0, path, (column - 2) * 4, (row - 1.5) * 4.5, "start") end
		end
		return finish({actors = actors, goal = "All A1/A2 landings and separate supported end slots", maximumDuration = 32}, 5, 4, 3, 0)
	end
	local hazardId = string.match(caseId, "^(H0[12])_Clear$")
	if hazardId ~= nil then
		local hazard = layout.sequenceById[hazardId]
		for row = 0, 1 do
			for column = 0, 2 do
				add(hazard.safeBefore, {hazard.crossing, hazard.safeAfter}, (column - 1) * 4.5, row * 4.5, "crossing")
			end
		end
		return finish({actors = actors, hazardId = hazardId, goal = "Clear the crossing into separate dry after-refuge slots",
			maximumDuration = 6.2}, 3, 4.5, 4, 4)
	end
	local mergeId = string.match(caseId, "^(K[12])_Merge$")
	if mergeId ~= nil then
		local fork = layout.forks[if mergeId == "K1" then 1 else 2]
		local main = layout.sequenceById[fork.main[#fork.main]].points
		local expert = layout.sequenceById[fork.expert[#fork.expert]].points
		local path = {layout.nodeById[mergeId]}
		for _, point in first(if mergeId == "K1" then "B3" else "D3", 2) do table.insert(path, point) end
		for _, side in {-2.5, 2.5} do add(main[#main], path, side, 0, "main") end
		add(expert[#expert], path, 0, 0, "expert", -2.5)
		local followerPath = {expert[#expert]}
		for _, point in path do table.insert(followerPath, point) end
		add(expert[#expert - 1], followerPath, 0, 0, "expert", 2.5)
		return finish({actors = actors, mergeId = mergeId, goal = "Single-file expert and main arrivals clear two exit landings",
			maximumDuration = 12}, 2, 5, 3, 0)
	end
	local checkpointId = string.match(caseId, "^(R[1-4])_Returns$")
	if checkpointId ~= nil then
		local index = tonumber(string.sub(checkpointId, 2)) :: number
		local checkpoint = layout.nodeById[checkpointId]
		local previousIds = {"A3", "B3", "C4", "D3"}
		local followingIds = {"B1", "C1", "D1", "E1"}
		local previous = layout.sequenceById[previousIds[index]].points
		local pocket = {id = checkpointId .. "_Pocket", position = checkpoint.spawnPosition, size = checkpoint.spawnSize}
		local path = {checkpoint}
		for _, point in first(followingIds[index], 2) do table.insert(path, point) end
		for row = 0, 1 do
			for _, side in {-2.1, 2.1} do
				add(pocket, path, side, (row - 0.5) * 4.2, "return")
				add(previous[#previous], path, side, (row - 0.5) * 4.2, "incoming")
			end
		end
		return finish({actors = actors, checkpointId = checkpointId, goal = "Pocket returns and incoming rivals clear two onward landings",
			maximumDuration = 12}, 4, 3.5, 4, 0)
	end
	error("Unknown CrowdStudy case: " .. caseId)
end

local function courseOrigin(course: Model): CFrame
	local bounds = course:FindFirstChild("Bounds")
	local marker = if bounds ~= nil then bounds:FindFirstChild("CourseOrigin") else nil
	return if marker ~= nil and marker:IsA("BasePart") then marker.CFrame else CFrame.new(Config.Origin)
end

local function targetPosition(actor: any, index: number): Vector3
	local point = actor.path[index]
	if index == #actor.path then return actor.endPosition end
	if math.min(point.size.X, point.size.Z) < 8 then return point.position end
	local previous = if index == 1 then actor.source else actor.path[index - 1]
	local direction = point.forward or flat(point.position - previous.position).Unit
	local side = lateral(direction)
	local allowance = boundary(point, point.position, side, 2)
	return point.position + side * math.clamp(actor.lane, -allowance, allowance)
end

-- Use the passing traversal study's insets, measured against each actual floor along the actor's lane.
local function edgePlan(actor: any, index: number): any
	local source = if index == 1 then actor.source else actor.path[index - 1]
	local target = actor.path[index]
	local a = if index == 1 then source.position + actor.offset else targetPosition(actor, index - 1)
	local b = targetPosition(actor, index)
	local direction = flat(b - a).Unit
	local expert = math.min(source.size.X, source.size.Z, target.size.X, target.size.Z) < 8
	local takeoffInset, landingInset = if expert then 0.2 else 0.5, if expert then 0.35 else 0.6
	local exit = a + direction * boundary(source, a, direction, 0)
	local entry = b - direction * boundary(target, b, -direction, 0)
	local gap, rise = math.max(0, (entry - exit):Dot(direction)), b.Y - a.Y
	return {source = source, target = target, targetPosition = b, direction = direction, expert = expert,
		takeoff = a + direction * boundary(source, a, direction, takeoffInset),
		landing = b - direction * boundary(target, b, -direction, landingInset), gap = gap, rise = rise,
		jump = gap > 0.75 or rise > 0.6, arrivalTolerance = if index == #actor.path then 0.6 else 0.8}
end

local function edgeCommand(motion: any, edge: any, position: Vector3, onSource: boolean, onTarget: boolean,
	inAir: boolean, now: number): (Vector3?, boolean, boolean)
	if motion.phase == "approach" then
		if onTarget then motion.phase = "center"
		elseif not onSource then return nil, false, false
		elseif flat(edge.takeoff - position).Magnitude > 0.2 then return edge.takeoff, false, false
		else
			motion.phase, motion.began, motion.airborne = "flight", now, false
			return edge.landing, true, true
		end
	end
	if motion.phase == "flight" then
		if inAir then motion.airborne = true end
		if motion.airborne and onTarget then motion.phase = "center"
		elseif now - motion.began >= 2.5 or (not motion.airborne and now - motion.began >= 0.45) then
			motion.phase = "blocked"
			motion.issue = if motion.airborne then "flight_deadline" else "takeoff_not_airborne"
			return nil, false, false
		else return edge.landing, not motion.airborne, false end
	end
	if motion.phase == "walk" or motion.phase == "center" then
		if onTarget and flat(edge.targetPosition - position).Magnitude <= edge.arrivalTolerance then
			motion.phase = "arrived"
			return nil, false, false
		end
		if onTarget or (motion.phase == "walk" and onSource) then return edge.targetPosition, false, false end
	end
	return nil, false, false
end

local function verifyFloors(course: Model, origin: CFrame, actors: {any}): {[any]: BasePart}
	local surfaces: {BasePart} = {}
	for _, item in course:GetDescendants() do
		if item:IsA("BasePart") and item.CanCollide and item:GetAttribute("WalkSurface") == true
			and item:GetAttribute("CoreFloor") == true then
			table.insert(surfaces, item)
		end
	end
	local checked: {[any]: BasePart} = {}
	local function verify(record: any)
		if checked[record] then return end
		local expected = origin:PointToWorldSpace(record.position)
		for _, part in surfaces do
			local top = part.CFrame:PointToWorldSpace(Vector3.new(0, part.Size.Y / 2, 0))
			if (top - expected).Magnitude < 0.05 and (part.Size - record.size).Magnitude < 0.05 then
				assert(part.CFrame.UpVector:Dot(Vector3.yAxis) > 0.999
					and math.abs(part.CFrame.RightVector:Dot(origin.RightVector)) > 0.999, "Rotated study floor unsupported")
				checked[record] = part
				return
			end
		end
		error("Live walk surface does not match study source: " .. tostring(record.id or record.position))
	end
	for _, actor in actors do
		verify(actor.source)
		for _, point in actor.path do verify(point) end
	end
	return checked
end

local function durationLimits(caseId: string, maximumDuration: number, requested: number?): (number, number)
	return math.clamp(requested or maximumDuration, 1, maximumDuration), if caseId == "Start20" then 35 else 20
end

local function matchesActiveCourse(course: any, activeCourse: any, activeCourseId: string, revision: string): boolean
	return course ~= nil and course == activeCourse and activeCourseId == Config.CourseId
		and course:GetAttribute("RuntimeActiveCourse") == true
		and course:GetAttribute("SourceCourseId") == Config.CourseId
		and course:GetAttribute("CourseId") == Config.CourseId
		and course:GetAttribute("StudGardenBuild") == Config.BuildId
		and course:GetAttribute("LayoutRevision") == revision
end

local function nativeSupport(actor: any, hit: RaycastResult?, expectedFloor: BasePart): boolean
	return actor.humanoid.FloorMaterial ~= Enum.Material.Air and hit ~= nil and hit.Instance == expectedFloor
		and math.abs(actor.root.Position.Y - hit.Position.Y - actor.lift) < 0.8
end

function Study.Run(caseId: string, options: any?): any
	local started = os.clock()
	guard()
	assert(activeFolder == nil, "Clean up the current crowd study before another invocation")
	options = options or {}
	local course = options.Course or CourseService.GetActiveCourse()
	assert(course ~= nil and course:IsA("Model") and course:IsDescendantOf(workspace), "Live course required")
	local layout = Layout.Get()
	assert(matchesActiveCourse(course, CourseService.GetActiveCourse(), CourseService.GetActiveCourseId(), layout.revision),
		"CrowdStudy requires the active Stud Garden source/build/layout")
	local player = options.TemplatePlayer or Players:GetPlayers()[1]
	assert(player ~= nil and player.Parent == Players, "A current player must supply the avatar")
	local template = player.Character
	local templateHumanoid = if template ~= nil then template:FindFirstChildOfClass("Humanoid") else nil
	local templateRoot = if template ~= nil then template:FindFirstChild("HumanoidRootPart") else nil
	assert(template ~= nil and templateHumanoid ~= nil and templateHumanoid.Health > 0
		and templateRoot ~= nil and templateRoot:IsA("BasePart"), "Live healthy character required")
	assert(math.abs(templateHumanoid.WalkSpeed - Config.WalkSpeed) < 0.01 and not templateHumanoid.UseJumpPower
		and math.abs(templateHumanoid.JumpHeight - Config.JumpHeight) < 0.01, "Template must use normal Stud Garden movement")
	assert(templateRoot.CollisionGroup == "RaceCharacter", "Template must already use the normal RaceCharacter group")
	assert(PhysicsService:CollisionGroupsAreCollidable("RaceCharacter", "RaceCharacter")
		and PhysicsService:CollisionGroupsAreCollidable("RaceCharacter", "Default"), "Normal racer collision policy required")
	local description = plan(caseId, layout)
	local duration, invocationLimit = durationLimits(caseId, description.maximumDuration, options.Duration)
	local origin = courseOrigin(course)
	assert(origin.UpVector:Dot(Vector3.yAxis) > 0.999, "Upright course origin required")
	local floors = verifyFloors(course, origin, description.actors)
	local supportParams = RaycastParams.new()
	supportParams.FilterType, supportParams.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {course}
	supportParams.RespectCanCollide = true
	local function support(actor: any): RaycastResult?
		return workspace:Raycast(actor.root.Position,
			-Vector3.yAxis * (actor.humanoid.HipHeight + actor.root.Size.Y / 2 + 4), supportParams)
	end
	local function supported(actor: any, hit: RaycastResult?, record: any): boolean
		return nativeSupport(actor, hit, floors[record])
	end
	local hazardModel: Instance? = nil
	if description.hazardId ~= nil then
		local art = course:FindFirstChild("Art")
		local hazards = if art ~= nil then art:FindFirstChild("HazardVisuals") else nil
		hazardModel = if hazards ~= nil then hazards:FindFirstChild(description.hazardId) else nil
		assert(hazardModel ~= nil and hazardModel:GetAttribute("HazardPhase") == "Clear", "Start hazard study during a live Clear phase")
	end
	local deadline = started + duration
	local report: any = {caseId = caseId, courseName = course.Name, sourceCourseId = course:GetAttribute("SourceCourseId"),
		buildId = Config.BuildId, layoutRevision = layout.revision, controllerRevision = "SG_CROWD_02",
		goal = description.goal, requestedDuration = duration, invocationLimit = invocationLimit, fixtureCount = #description.actors,
		walkSpeed = templateHumanoid.WalkSpeed, jumpHeight = templateHumanoid.JumpHeight,
		rigType = templateHumanoid.RigType.Name, collisionGroup = "RaceCharacter", actors = {}, timeline = {},
		evidence = "Single Studio server physical avatar-clone study using normal Humanoid movement.",
		limits = "NPC clones are not official racers. No human timing, 20 networked clients, authoritative hazard recovery, checkpoint progress or device performance proof."}
	local folder = Instance.new("Folder")
	folder.Name = "StudGardenCrowdStudy_" .. HttpService:GenerateGUID(false)
	folder:SetAttribute("StudGardenCrowdStudy", true)
	folder:SetAttribute("BuildId", Config.BuildId)
	folder.Parent = workspace
	activeFolder = folder
	local cleanupWatchdog = task.delay(math.max(0, started + invocationLimit - os.clock()), function()
		if activeFolder == folder then
			report.endedBy = "invocation_deadline"
			folder:Destroy()
			activeFolder = nil
		end
	end)
	local actors: {any} = {}
	local cloneReferences: {Model} = {}
	local function hazardPhase(): string?
		return if hazardModel ~= nil then hazardModel:GetAttribute("HazardPhase") else nil
	end
	local ok, failure = xpcall(function()
		for index, proposed in description.actors do
			assert(os.clock() < deadline, "Setup exhausted the bounded study duration")
			local previousArchivable = template.Archivable
			template.Archivable = true
			local cloned, rig = pcall(function() return template:Clone() end)
			template.Archivable = previousArchivable
			assert(cloned and rig ~= nil, "Could not clone template character")
			table.insert(cloneReferences, rig)
			rig.Name = string.format("Fixture_%02d_%s", index, proposed.group)
			for _, descendant in rig:GetDescendants() do
				if descendant:IsA("LuaSourceContainer") then descendant:Destroy()
				elseif descendant:IsA("BasePart") then
					assert(descendant.CollisionGroup == "RaceCharacter", "Clone contains an unexpected collision group")
					descendant.Anchored = false
				end
			end
			local humanoid = rig:FindFirstChildOfClass("Humanoid")
			local root = rig:FindFirstChild("HumanoidRootPart")
			assert(humanoid ~= nil and root ~= nil and root:IsA("BasePart"), "Clone body is incomplete")
			rig.PrimaryPart = root
			local lift = humanoid.HipHeight + root.Size.Y / 2 + (if humanoid.RigType == Enum.HumanoidRigType.R6 then 2 else 0)
			local startPosition = origin:PointToWorldSpace(proposed.source.position + proposed.offset + Vector3.new(0, lift + 0.15, 0))
			local forward = origin:VectorToWorldSpace(flat(proposed.path[1].position - proposed.source.position).Unit)
			rig:PivotTo(CFrame.lookAt(startPosition, startPosition + forward))
			rig.Parent = folder
			root:SetNetworkOwner(nil)
			root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
			humanoid.PlatformStand, humanoid.Sit, humanoid.AutoRotate = false, false, true
			humanoid.Jump = false
			local actor = table.clone(proposed)
			actor.rig, actor.humanoid, actor.root, actor.lift = rig, humanoid, root, lift
			actor.index, actor.currentFloor, actor.state = 1, proposed.source, "moving"
			actor.edge = edgePlan(actor, 1)
			actor.motion = {phase = if actor.edge.jump then "approach" else "walk"}
			actor.progressAt, actor.progressPosition = started, root.Position
			actor.record = {id = rig.Name, group = proposed.group, completedWaypoints = 0,
				maximumStallSeconds = 0, jumpsRequested = 0, airborneTransitions = 0, jumps = {},
				initialPosition = {root.Position.X, root.Position.Y, root.Position.Z},
				endSlot = {proposed.endPosition.X, proposed.endPosition.Y, proposed.endPosition.Z}}
			table.insert(actors, actor)
		end
		task.wait(0.35)
		for _, actor in actors do
			local hit = support(actor)
			if hit ~= nil and hit.Instance == floors[actor.source] and actor.humanoid.FloorMaterial ~= Enum.Material.Air then
				local measured = actor.root.Position.Y - hit.Position.Y
				if measured >= 1 and measured <= 6 and math.abs(measured - actor.lift) < 0.8 then actor.lift = measured end
			end
			actor.record.initialSupportVerified = supported(actor, hit, actor.source)
		end
		local nextSample = os.clock()
		local lastFrame = nextSample
		while os.clock() < deadline do
			local now = os.clock()
			local frameSeconds = math.clamp(now - lastFrame, 1 / 120, 0.1)
			lastFrame = now
			if activeFolder ~= folder or folder.Parent == nil then
				report.endedBy = "cleanup_requested"
				break
			end
			if not matchesActiveCourse(course, CourseService.GetActiveCourse(), CourseService.GetActiveCourseId(), layout.revision) then
				report.endedBy = "course_changed"
				break
			end
			if hazardModel ~= nil and hazardPhase() ~= "Clear" then
				report.endedBy = "clear_window_ended"
				break
			end
			local moving = 0
			for _, actor in actors do
				if actor.state == "fell" then continue end
				local humanoid, root = actor.humanoid, actor.root
				local position = origin:PointToObjectSpace(root.Position)
				local edge = actor.edge
				local hit = support(actor)
				local onSource, onTarget = supported(actor, hit, edge.source), supported(actor, hit, edge.target)
				if humanoid.Health <= 0 or position.Y < math.min(actor.currentFloor.position.Y, edge.target.position.Y) + actor.lift - 2.5 then
					actor.state = "fell"
					actor.record.fallAt = now - started
					humanoid.Jump = false
					humanoid:Move(Vector3.zero, false)
					continue
				end
				if actor.state == "completed" then
					humanoid.Jump = false
					if onTarget and flat(edge.targetPosition - position).Magnitude <= 0.8 then
						humanoid:Move(Vector3.zero, false)
						continue
					end
					actor.state, actor.motion = "moving", {phase = "center"}
					actor.record.leftEndSlotAt = now - started
				end
				local previousPhase, wasAirborne = actor.motion.phase, actor.motion.airborne
				local moveTarget, jump, requested = edgeCommand(actor.motion, edge, position, onSource, onTarget,
					humanoid.FloorMaterial == Enum.Material.Air, now)
				humanoid.Jump = jump
				if requested then
					actor.record.jumpsRequested += 1
					actor.currentJump = {fromId = edge.source.id, toId = edge.target.id, seconds = now - started,
						gap = edge.gap, rise = edge.rise, supportedTakeoff = onSource,
						takeoff = {position.X, position.Y - actor.lift, position.Z}, landed = false}
					table.insert(actor.record.jumps, actor.currentJump)
				end
				if actor.motion.airborne and not wasAirborne then actor.record.airborneTransitions += 1 end
				if previousPhase == "flight" and (actor.motion.phase == "center" or actor.motion.phase == "arrived") then
					actor.currentJump.landed, actor.currentJump.flightSeconds = true, now - actor.motion.began
				end
				if actor.motion.issue ~= nil then actor.record.controlIssue = actor.motion.issue end
				if actor.motion.phase == "arrived" then
					actor.record.completedWaypoints = actor.index
					actor.record.lastReachedPointId = actor.path[actor.index].id
					actor.currentFloor = actor.path[actor.index]
					if description.mergeId ~= nil and actor.currentFloor.id == description.mergeId then actor.record.mergeArrivalAt = now - started end
					if description.checkpointId ~= nil and actor.currentFloor.id == description.checkpointId then actor.record.checkpointArrivalAt = now - started end
					actor.progressAt, actor.progressPosition = now, root.Position
					humanoid:Move(Vector3.zero, false)
					if actor.index == #actor.path then
						actor.state = "completed"
						actor.record.completedAt = now - started
						actor.record.endSupportVerified = onTarget
						continue
					end
					actor.index += 1
					actor.edge = edgePlan(actor, actor.index)
					actor.motion = {phase = if actor.edge.jump then "approach" else "walk"}
					moving += 1
					continue
				end
				if flat(root.Position - actor.progressPosition).Magnitude >= 1.5 then
					actor.progressAt, actor.progressPosition = now, root.Position
				end
				actor.record.maximumStallSeconds = math.max(actor.record.maximumStallSeconds, now - actor.progressAt)
				local difference = if moveTarget ~= nil then flat(moveTarget - position) else Vector3.zero
				local stoppingDistance = if actor.motion.phase == "flight" then 0.18 else 0.05
				local move = if difference.Magnitude > stoppingDistance then difference.Unit
					* math.min(1, difference.Magnitude / (Config.WalkSpeed * frameSeconds)) else Vector3.zero
				humanoid:Move(origin:VectorToWorldSpace(move), false)
				moving += 1
			end
			if now >= nextSample then
				table.insert(report.timeline, {seconds = now - started, moving = moving, hazardPhase = hazardPhase()})
				nextSample = now + 1
			end
			if moving == 0 then report.endedBy = "all_actors_finished_or_fell"; break end
			RunService.Heartbeat:Wait()
		end
	end, debug.traceback)
	report.elapsed = os.clock() - started
	report.completed, report.fell, report.stalled, report.unfinished = 0, 0, 0, 0
	local firstArrival, lastArrival = math.huge, -math.huge
	for _, actor in actors do
		pcall(function() actor.humanoid.Jump = false; actor.humanoid:Move(Vector3.zero, false) end)
		actor.record.state = actor.state
		actor.record.motionPhase = actor.motion.phase
		actor.record.targetPointId = if actor.state ~= "completed" then actor.path[actor.index].id else nil
		actor.record.lastPosition = {actor.root.Position.X, actor.root.Position.Y, actor.root.Position.Z}
		if actor.state == "completed" then report.completed += 1
		elseif actor.state == "fell" then report.fell += 1
		else report.unfinished += 1 end
		if actor.record.maximumStallSeconds >= 2 then report.stalled += 1 end
		if actor.record.mergeArrivalAt ~= nil then
			firstArrival = math.min(firstArrival, actor.record.mergeArrivalAt)
			lastArrival = math.max(lastArrival, actor.record.mergeArrivalAt)
		end
		table.insert(report.actors, actor.record)
	end
	if firstArrival < math.huge then
		report.mergeArrivalSpreadSeconds = lastArrival - firstArrival
		local arrivals = 0
		for _, actor in actors do if actor.record.mergeArrivalAt ~= nil then arrivals += 1 end end
		report.mergeArrivals = arrivals
		report.simultaneousArrivalObserved = arrivals == #actors and lastArrival - firstArrival <= 1
	end
	if caseId == "Start20" then
		report.completedA1, report.enteredA2 = 0, 0
		for _, actor in actors do
			if actor.record.completedWaypoints >= #layout.sequenceById.A1.points then report.completedA1 += 1 end
			if actor.record.completedWaypoints > #layout.sequenceById.A1.points then report.enteredA2 += 1 end
		end
	end
	if description.hazardId ~= nil and report.completed == #description.actors then
		local allClearAt = 0
		for _, actor in actors do allClearAt = math.max(allClearAt, actor.record.completedAt) end
		report.allClearAt = allClearAt
	end
	report.status = if ok then "recorded" else "error"
	report.error = if not ok then tostring(failure) else nil
	report.endedBy = report.endedBy or "duration_limit"
	report.createdFixtures = #cloneReferences
	report.controlledFixtures = #actors
	if activeFolder == folder then Study.Cleanup() else folder:Destroy() end
	pcall(task.cancel, cleanupWatchdog)
	for _, rig in cloneReferences do if rig.Parent == nil then rig:Destroy() end end
	report.cleanupComplete = activeFolder ~= folder and folder.Parent == nil
	report.elapsedIncludingCleanup = os.clock() - started
	return report
end

return Study
