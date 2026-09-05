--!strict

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MotionConfig = require(ReplicatedStorage.Config.AscentMotionConfig)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)

type ServiceContext = {
	Services: { [string]: any },
}

type VisualState = {
	part: BasePart,
	transparency: number,
	canCollide: boolean,
	canTouch: boolean,
	anchored: boolean,
	collisionGroup: string,
}

type MotionRecord = {
	part: BasePart,
	kind: string,
	authoredCFrame: CFrame,
	startCFrame: CFrame,
	endCFrame: CFrame,
	initialProgress: number,
	isFirstTravel: boolean,
	physicsMotion: boolean,
	bounceCount: number,
	arcHeight: number,
	visualSpin: boolean,
	physicsPathPoints: { Vector3 },
	duration: number,
	pauseDuration: number,
	pauseMin: number,
	pauseMax: number,
	warningDuration: number,
	cycleOffset: number,
	damage: number,
	activeTransparency: number,
	originalTransparency: number,
	originalCanCollide: boolean,
	originalCanTouch: boolean,
	originalAnchored: boolean,
	originalCollisionGroup: string,
	warning: BasePart?,
	warningTransparency: number?,
	phase: string,
	phaseStartedAt: number,
	nextPhaseAt: number,
	direction: number,
	previousCFrame: CFrame,
	visuals: { VisualState },
	random: Random,
	linearVelocity: LinearVelocity?,
	alignOrientation: AlignOrientation?,
	welds: { WeldConstraint },
	motionAttachment: Attachment?,
}

local CourseMotionService = {}

local attributes = MotionConfig.AttributeNames
local kinds = MotionConfig.MotionKinds
local defaults = MotionConfig.Defaults

local courseService: any = nil
local raceService: any = nil
local playerRaceService: any = nil
local respawnService: any = nil
local isInitialized = false
local isStarted = false
local boundCourse: Model? = nil
local records: { MotionRecord } = {}
local wasRaceActive = false
local contactTimes: { [number]: { [BasePart]: number } } = {}
local boundaryCollisionGroups: { [BasePart]: string } = {}

local MOVING_LOG_GROUP = "MovingLogs"
local COURSE_BOUNDARY_GROUP = "CourseBoundaries"

local function setCollisionGroup(part: BasePart, groupName: string)
	part.CollisionGroup = groupName
end

local function ensureMovingLogCollisionGroups()
	for _, groupName in ipairs({ MOVING_LOG_GROUP, COURSE_BOUNDARY_GROUP }) do
		if not PhysicsService:IsCollisionGroupRegistered(groupName) then
			PhysicsService:RegisterCollisionGroup(groupName)
		end
	end
	PhysicsService:CollisionGroupSetCollidable(MOVING_LOG_GROUP, COURSE_BOUNDARY_GROUP, false)
end

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function numberAttribute(part: BasePart, name: string, fallback: number): number
	local value = part:GetAttribute(name)
	return if typeof(value) == "number" then math.max(0, value) else fallback
end

local function isActiveRacer(player: Player): boolean
	return raceService ~= nil
		and raceService.IsRaceActive ~= nil
		and raceService.IsRaceActive() == true
		and playerRaceService ~= nil
		and playerRaceService.IsOfficialRacer ~= nil
		and playerRaceService.GetPlayerStatus ~= nil
		and playerRaceService.IsOfficialRacer(player) == true
		and playerRaceService.GetPlayerStatus(player) == RaceConstants.PlayerRaceStatus.Racing
end

local function setPhase(record: MotionRecord, phase: string, nextPhaseAt: number)
	record.phase = phase
	record.phaseStartedAt = now()
	record.nextPhaseAt = nextPhaseAt
	record.part:SetAttribute(attributes.MotionPhase, phase)
	record.part:SetAttribute(attributes.MotionNextPhaseAt, nextPhaseAt)
end

local function showWarning(record: MotionRecord, visible: boolean)
	local warning = record.warning
	if warning == nil or warning.Parent == nil then
		return
	end
	warning.Transparency = if visible then (record.warningTransparency or 0) else 1
end

local function moveRecord(record: MotionRecord, target: CFrame)
	local delta = target * record.part.CFrame:Inverse()
	record.part.CFrame = target
	for _, visual in ipairs(record.visuals) do
		if visual.part.Parent ~= nil then
			visual.part.CFrame = delta * visual.part.CFrame
		end
	end
end

local function setRecordVisible(record: MotionRecord, visible: boolean)
	record.part.Transparency = if visible then record.activeTransparency else 1
	record.part.CanCollide = visible and record.originalCanCollide
	record.part.CanTouch = visible and record.originalCanTouch
	for _, visual in ipairs(record.visuals) do
		if visual.part.Parent ~= nil then
			visual.part.Transparency = if visible then numberAttribute(visual.part, "ActiveTransparency", visual.transparency) else 1
			visual.part.CanCollide = visible and visual.canCollide
			visual.part.CanTouch = visible and visual.canTouch
		end
	end
end

local function nextPause(record: MotionRecord): number
	if record.kind ~= kinds.Snowball and record.kind ~= kinds.RollingBoulder then
		return record.pauseDuration
	end
	if record.pauseMax <= record.pauseMin then
		return record.pauseMin
	end
	return record.random:NextNumber(record.pauseMin, record.pauseMax)
end

local function booleanAttribute(part: BasePart, name: string, fallback: boolean): boolean
	local value = part:GetAttribute(name)
	return if typeof(value) == "boolean" then value else fallback
end

local function setMovingLogPhysics(record: MotionRecord, enabled: boolean)
	if record.linearVelocity == nil or record.alignOrientation == nil then
		return
	end
	record.linearVelocity.Enabled = enabled
	record.alignOrientation.Enabled = enabled
	if enabled then
		setCollisionGroup(record.part, MOVING_LOG_GROUP)
		for _, visual in ipairs(record.visuals) do
			setCollisionGroup(visual.part, MOVING_LOG_GROUP)
			visual.part.Anchored = false
		end
		record.part.Anchored = false
		record.part.AssemblyLinearVelocity = record.linearVelocity.VectorVelocity
		record.part.AssemblyAngularVelocity = Vector3.zero
		pcall(function()
			record.part:SetNetworkOwner(nil)
		end)
	else
		record.part.AssemblyLinearVelocity = Vector3.zero
		record.part.AssemblyAngularVelocity = Vector3.zero
		record.part.Anchored = true
		for _, visual in ipairs(record.visuals) do
			visual.part.Anchored = true
		end
	end
end

local function buildExclusions(record: MotionRecord): { Instance }
	local excluded: { Instance } = { record.part }
	if record.warning ~= nil then
		table.insert(excluded, record.warning)
	end
	for _, visual in ipairs(record.visuals) do
		table.insert(excluded, visual.part)
	end
	return excluded
end

local function resetRecord(record: MotionRecord, clearDiagnostics: boolean)
	if record.part.Parent ~= nil then
		setMovingLogPhysics(record, false)
		moveRecord(record, record.authoredCFrame)
		record.part.Transparency = record.originalTransparency
		record.part.CanCollide = record.originalCanCollide
		record.part.CanTouch = record.originalCanTouch
		record.part.Anchored = record.originalAnchored
		setCollisionGroup(record.part, record.originalCollisionGroup)
		for _, visual in ipairs(record.visuals) do
			if visual.part.Parent ~= nil then
				visual.part.Transparency = visual.transparency
				visual.part.CanCollide = visual.canCollide
				visual.part.CanTouch = visual.canTouch
				visual.part.Anchored = visual.anchored
				setCollisionGroup(visual.part, visual.collisionGroup)
			end
		end
		record.previousCFrame = record.startCFrame
		if clearDiagnostics then
			record.part:SetAttribute(attributes.MotionPhase, nil)
			record.part:SetAttribute(attributes.MotionNextPhaseAt, nil)
		else
			setPhase(record, "Idle", 0)
		end
	end
	showWarning(record, false)
end

local function destroyMovingLogPhysics(record: MotionRecord)
	for _, weld in ipairs(record.welds) do
		weld:Destroy()
	end
	if record.linearVelocity ~= nil then
		record.linearVelocity:Destroy()
	end
	if record.alignOrientation ~= nil then
		record.alignOrientation:Destroy()
	end
	if record.motionAttachment ~= nil then
		record.motionAttachment:Destroy()
	end
end

local function restoreRecords(clearDiagnostics: boolean)
	for _, record in ipairs(records) do
		resetRecord(record, clearDiagnostics)
	end
end

local function canAffect(record: MotionRecord, player: Player, timestamp: number): boolean
	if not isActiveRacer(player) then
		return false
	end
	local playerTimes = contactTimes[player.UserId]
	if playerTimes == nil then
		playerTimes = {}
		contactTimes[player.UserId] = playerTimes
	end
	local lastTime = playerTimes[record.part]
	if lastTime ~= nil and timestamp - lastTime < MotionConfig.ContactCooldown then
		return false
	end
	playerTimes[record.part] = timestamp
	return true
end

local function affectPlayer(record: MotionRecord, player: Player, timestamp: number)
	if not canAffect(record, player, timestamp) then
		return
	end
	local character = player.Character
	local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid == nil or humanoid.Health <= 0 then
		return
	end
	local recoveryUntil = if character ~= nil then character:GetAttribute("RecoveryUntil") else nil
	if typeof(recoveryUntil) == "number" and timestamp < recoveryUntil then
		return
	end
	if record.kind == kinds.Snowball and humanoid.Health > record.damage then
		humanoid:TakeDamage(record.damage)
	elseif respawnService ~= nil and respawnService.RecoverPlayer ~= nil then
		respawnService.RecoverPlayer(player, record.kind)
	end
end

local function playerFromHit(instance: Instance): Player?
	local character = instance:FindFirstAncestorWhichIsA("Model")
	return if character ~= nil then Players:GetPlayerFromCharacter(character) else nil
end

local function activeRacerCharacters(): { Instance }
	local characters: { Instance } = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if #characters >= MotionConfig.MaxRacersChecked then
			break
		end
		if isActiveRacer(player) and player.Character ~= nil then
			table.insert(characters, player.Character)
		end
	end
	return characters
end

local function rollingHazardHit(record: MotionRecord, target: CFrame): Player?
	local characters = activeRacerCharacters()
	if #characters == 0 then
		return nil
	end
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = characters
	for _, hit in ipairs(Workspace:GetPartBoundsInBox(record.part.CFrame, record.part.Size, overlapParams)) do
		local player = playerFromHit(hit)
		if player ~= nil then
			return player
		end
	end
	local displacement = target.Position - record.previousCFrame.Position
	if displacement.Magnitude < 0.001 then
		return nil
	end
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = characters
	local result: RaycastResult?
	if record.kind == kinds.RollingLog then
		result = Workspace:Blockcast(record.previousCFrame, record.part.Size, displacement, raycastParams)
	else
		local radius = math.max(
			0.5,
			math.min(record.part.Size.X, record.part.Size.Y, record.part.Size.Z)
				* MotionConfig.ProjectileRadiusScale
		)
		result = Workspace:Spherecast(record.previousCFrame.Position, radius, displacement, raycastParams)
	end
	return if result ~= nil then playerFromHit(result.Instance) else nil
end

local function currentOverlap(record: MotionRecord): (Player?, boolean)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = buildExclusions(record)
	-- Exact geometry prevents a mountain wedge bounding box from swallowing snowballs.
	local hits = if record.kind == kinds.Snowball then Workspace:GetPartsInPart(record.part, params) else Workspace:GetPartBoundsInBox(record.part.CFrame, record.part.Size, params)
	table.sort(hits, function(left, right)
		return (left.Position - record.part.Position).Magnitude < (right.Position - record.part.Position).Magnitude
	end)
	local touchedCover = false
	for _, hit in ipairs(hits) do
		local player = playerFromHit(hit)
		if player ~= nil then
			return player, false
		end
		if hit.CanCollide then
			touchedCover = true
			if record.kind == kinds.Snowball then
				return nil, true
			end
		end
	end
	return nil, touchedCover
end

local function sweep(record: MotionRecord, fromPosition: Vector3, toPosition: Vector3): (Player?, boolean)
	local displacement = toPosition - fromPosition
	if displacement.Magnitude < 0.001 then
		return nil, false
	end
	local excluded = buildExclusions(record)
	local radius = math.max(0.5, math.min(record.part.Size.X, record.part.Size.Y, record.part.Size.Z) * MotionConfig.ProjectileRadiusScale)
	for _ = 1, 12 do
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = excluded
		params.IgnoreWater = true
		local result = Workspace:Spherecast(fromPosition, radius, displacement, params)
		if result == nil then
			return nil, false
		end
		local player = playerFromHit(result.Instance)
		if player ~= nil then
			return player, false
		end
		if result.Instance:IsA("BasePart") and result.Instance.CanCollide then
			if record.kind == kinds.Snowball then
				return nil, true
			end
			table.insert(excluded, result.Instance)
			continue
		end
		table.insert(excluded, result.Instance)
	end
	return nil, false
end

local function cachePhysicsPath(record: MotionRecord)
	local points: { Vector3 } = { record.startCFrame.Position }
	local excluded = buildExclusions(record)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character ~= nil then
			table.insert(excluded, player.Character)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	params.IgnoreWater = true
	params.RespectCanCollide = true
	local castHeight = math.max(30, record.arcHeight * 3)
	local radius = math.min(record.part.Size.X, record.part.Size.Y, record.part.Size.Z) * 0.5
	for bounceIndex = 1, record.bounceCount do
		local intendedProgress = bounceIndex / (record.bounceCount + 1)
		local bouncePoint: Vector3? = nil
		for _, progressOffset in ipairs({ 0, -0.03, 0.03, -0.06, 0.06 }) do
			local progress = math.clamp(intendedProgress + progressOffset, 0, 1)
			local linearPoint = record.startCFrame.Position:Lerp(record.endCFrame.Position, progress)
			local result = Workspace:Raycast(
				linearPoint + Vector3.new(0, castHeight, 0),
				Vector3.new(0, -castHeight * 2, 0),
				params
			)
			if result ~= nil and result.Instance.CanCollide then
				bouncePoint = Vector3.new(linearPoint.X, result.Position.Y + radius, linearPoint.Z)
				break
			end
		end
		if bouncePoint ~= nil then
			table.insert(points, bouncePoint)
		end
	end
	table.insert(points, record.endCFrame.Position)
	record.physicsPathPoints = points
end

local function physicsMotionTarget(record: MotionRecord, alpha: number): CFrame
	local segmentCount = math.max(1, #record.physicsPathPoints - 1)
	local scaledProgress = math.min(alpha * segmentCount, segmentCount - 0.000001)
	local segmentIndex = math.floor(scaledProgress)
	local segmentAlpha = scaledProgress - segmentIndex
	if alpha >= 1 then
		segmentIndex = segmentCount - 1
		segmentAlpha = 1
	end
	local startPoint = record.physicsPathPoints[segmentIndex + 1] or record.startCFrame.Position
	local endPoint = record.physicsPathPoints[segmentIndex + 2] or record.endCFrame.Position
	local position = startPoint:Lerp(endPoint, segmentAlpha)
	local bounceScale = math.max(0.35, 1 - segmentIndex * 0.2)
	position += Vector3.new(0, 4 * record.arcHeight * bounceScale * segmentAlpha * (1 - segmentAlpha), 0)
	local baseRotation = record.startCFrame:Lerp(record.endCFrame, alpha).Rotation
	return CFrame.new(position) * baseRotation
end

local function beginCycle(record: MotionRecord, timestamp: number)
	record.direction = 1
	if record.kind == kinds.MovingLog then
		local progress = if record.isFirstTravel then record.initialProgress else 0
		local startingCFrame = record.startCFrame:Lerp(record.endCFrame, progress)
		record.isFirstTravel = false
		moveRecord(record, startingCFrame)
		record.previousCFrame = startingCFrame
		setRecordVisible(record, true)
		setMovingLogPhysics(record, true)
		setPhase(record, "Travelling", timestamp + (1 - progress) * record.duration)
		record.phaseStartedAt = timestamp - progress * record.duration
	else
		moveRecord(record, record.startCFrame)
		record.previousCFrame = record.startCFrame
		setRecordVisible(record, false)
		showWarning(record, true)
		setPhase(record, "Warning", timestamp + record.warningDuration)
	end
end

local function startRace(timestamp: number)
	table.clear(contactTimes)
	for _, record in ipairs(records) do
		resetRecord(record, false)
		if record.kind == kinds.MovingLog then
			record.isFirstTravel = true
			setRecordVisible(record, false)
		end
		setPhase(record, "Idle", timestamp + record.cycleOffset)
	end
end

local function updateMovingLog(record: MotionRecord, timestamp: number)
	if record.phase == "Idle" and timestamp >= record.nextPhaseAt then
		beginCycle(record, timestamp)
	elseif record.phase == "Travelling" then
		if timestamp >= record.nextPhaseAt then
			setMovingLogPhysics(record, false)
			setRecordVisible(record, false)
			moveRecord(record, record.startCFrame)
			setPhase(record, "Cooldown", timestamp + record.pauseDuration)
		end
	elseif record.phase == "Cooldown" and timestamp >= record.nextPhaseAt then
		beginCycle(record, timestamp)
	end
end

local function beginTravel(record: MotionRecord, timestamp: number)
	showWarning(record, false)
	if record.physicsMotion then
		cachePhysicsPath(record)
	end
	setRecordVisible(record, true)
	record.previousCFrame = record.startCFrame
	moveRecord(record, record.startCFrame)
	setPhase(record, "Travelling", timestamp + record.duration)
end

local function affectLavaOverlaps(record: MotionRecord, timestamp: number)
	local characters: { Instance } = {}
	local racerCount = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if racerCount >= MotionConfig.MaxRacersChecked then
			break
		end
		if isActiveRacer(player) and player.Character ~= nil then
			table.insert(characters, player.Character)
			racerCount += 1
		end
	end
	if #characters == 0 then
		return
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = characters
	local affected: { [Player]: boolean } = {}
	for _, hit in ipairs(Workspace:GetPartsInPart(record.part, params)) do
		local player = playerFromHit(hit)
		if player ~= nil and not affected[player] then
			affected[player] = true
			affectPlayer(record, player, timestamp)
		end
	end
end

local function updateHazard(record: MotionRecord, timestamp: number)
	if record.phase == "Idle" and timestamp >= record.nextPhaseAt then
		beginCycle(record, timestamp)
	elseif record.phase == "Warning" and timestamp >= record.nextPhaseAt then
		beginTravel(record, timestamp)
	elseif record.phase == "Travelling" then
		local alpha = math.clamp((timestamp - record.phaseStartedAt) / math.max(record.duration, 0.01), 0, 1)
		local from = if record.direction == 1 then record.startCFrame else record.endCFrame
		local destination = if record.direction == 1 then record.endCFrame else record.startCFrame
		local target = if record.physicsMotion then physicsMotionTarget(record, alpha) else from:Lerp(destination, alpha)
		local isRolling = record.kind == kinds.RollingLog or record.kind == kinds.RollingBoulder
		if record.visualSpin or record.kind == kinds.Avalanche or isRolling then
			local spinSpeed = if isRolling then MotionConfig.RollingRotationSpeed else MotionConfig.AvalancheRotationSpeed
			target *= CFrame.Angles(spinSpeed * (timestamp - record.phaseStartedAt), 0, 0)
		end
		local hitPlayer: Player? = nil
		local hitCover = false
		if isRolling then
			hitPlayer = rollingHazardHit(record, target)
		else
			hitPlayer, hitCover = currentOverlap(record)
			if hitPlayer == nil and (not hitCover or record.kind ~= kinds.Snowball) then
				hitPlayer, hitCover = sweep(record, record.previousCFrame.Position, target.Position)
			end
		end
		moveRecord(record, target)
		record.previousCFrame = target
		if hitPlayer ~= nil and record.kind ~= kinds.LavaSpurt then
			affectPlayer(record, hitPlayer, timestamp)
		end
		if record.kind == kinds.LavaSpurt then
			affectLavaOverlaps(record, timestamp)
		end
		if (hitCover or hitPlayer ~= nil) and record.kind == kinds.Snowball then
			alpha = 1
		end
		if (alpha >= 1 or timestamp >= record.nextPhaseAt) and record.kind == kinds.LavaSpurt and record.direction == 1 then
			record.direction = -1
			record.previousCFrame = record.endCFrame
			setPhase(record, "LavaPause", timestamp + record.pauseDuration)
		elseif alpha >= 1 or timestamp >= record.nextPhaseAt then
			setRecordVisible(record, false)
			moveRecord(record, record.startCFrame)
			setPhase(record, "Cooldown", timestamp + nextPause(record))
		end
	elseif record.phase == "LavaPause" and timestamp >= record.nextPhaseAt then
		setPhase(record, "Travelling", timestamp + record.duration)
	elseif record.phase == "LavaPause" then
		affectLavaOverlaps(record, timestamp)
	elseif record.phase == "Cooldown" and timestamp >= record.nextPhaseAt then
		beginCycle(record, timestamp)
	end
end

local function bindCourse(course: Model?)
	restoreRecords(true)
	for _, record in ipairs(records) do
		destroyMovingLogPhysics(record)
	end
	for boundary, collisionGroup in pairs(boundaryCollisionGroups) do
		if boundary.Parent ~= nil then
			setCollisionGroup(boundary, collisionGroup)
		end
	end
	table.clear(records)
	table.clear(contactTimes)
	table.clear(boundaryCollisionGroups)
	boundCourse = course
	wasRaceActive = false
	if course == nil then
		return
	end
	ensureMovingLogCollisionGroups()
	for _, descendant in ipairs(course:GetDescendants()) do
		if descendant:IsA("BasePart")
			and (descendant:GetAttribute("CourseBoundary") == true or descendant:GetAttribute("EnvironmentSolid") == true)
		then
			boundaryCollisionGroups[descendant] = descendant.CollisionGroup
			setCollisionGroup(descendant, COURSE_BOUNDARY_GROUP)
		end
	end
	for _, descendant in ipairs(course:GetDescendants()) do
		if not descendant:IsA("BasePart") then
			continue
		end
		local kind = descendant:GetAttribute(attributes.MotionKind)
		local motionStart = descendant:GetAttribute(attributes.MotionStart)
		local motionEnd = descendant:GetAttribute(attributes.MotionEnd)
		if typeof(kind) ~= "string" or typeof(motionEnd) ~= "CFrame" then
			continue
		end
		if kind ~= kinds.MovingLog
			and kind ~= kinds.LavaSpurt
			and kind ~= kinds.Snowball
			and kind ~= kinds.Avalanche
			and kind ~= kinds.RollingLog
			and kind ~= kinds.RollingBoulder
		then
			continue
		end
		if not descendant.Anchored then
			warn(string.format("[CourseMotionService] Ignored unanchored motion part %s.", descendant:GetFullName()))
			continue
		end
		local sibling = if descendant.Parent ~= nil then descendant.Parent:FindFirstChild("Warning") else nil
		local warning = if sibling ~= nil and sibling:IsA("BasePart") then sibling else nil
		local visuals: { VisualState } = {}
		for _, child in ipairs(descendant:GetDescendants()) do
			if child:IsA("BasePart") and child ~= warning then
				table.insert(visuals, {
					part = child,
					transparency = child.Transparency,
					canCollide = child.CanCollide,
					canTouch = child.CanTouch,
					anchored = child.Anchored,
					collisionGroup = child.CollisionGroup,
				})
			end
		end
		local defaultPause = if kind == kinds.MovingLog then defaults.MovingLogPauseDuration else defaults.PauseDuration
		local defaultPauseMin = if kind == kinds.RollingBoulder
			then defaults.RollingBoulderPauseMin
			elseif kind == kinds.Snowball then defaults.SnowballPauseMin
			else defaultPause
		local defaultPauseMax = if kind == kinds.RollingBoulder
			then defaults.RollingBoulderPauseMax
			elseif kind == kinds.Snowball then defaults.SnowballPauseMax
			else defaultPause
		local pauseMin = numberAttribute(descendant, attributes.PauseMin, defaultPauseMin)
		local pauseMax = numberAttribute(descendant, attributes.PauseMax, defaultPauseMax)
		if pauseMax < pauseMin then
			pauseMin, pauseMax = pauseMax, pauseMin
		end
		local warningDuration = numberAttribute(descendant, attributes.WarningDuration, defaults.WarningDuration)
		if kind == kinds.RollingBoulder then
			warningDuration = math.max(warningDuration, MotionConfig.RollingBoulderMinWarningDuration)
		end
		local seed = 0
		for index = 1, #descendant:GetFullName() do
			seed = (seed * 31 + string.byte(descendant:GetFullName(), index)) % 2147483647
		end
		local record: MotionRecord = {
			part = descendant,
			kind = kind,
			authoredCFrame = descendant.CFrame,
			startCFrame = if typeof(motionStart) == "CFrame" then motionStart else descendant.CFrame,
			endCFrame = motionEnd,
			initialProgress = math.clamp(
				numberAttribute(descendant, attributes.InitialProgress, 0),
				0,
				1
			),
			isFirstTravel = true,
			physicsMotion = booleanAttribute(descendant, "PhysicsMotion", false),
			bounceCount = math.clamp(math.floor(numberAttribute(descendant, "BounceCount", 0)), 0, 2),
			arcHeight = math.clamp(numberAttribute(descendant, "ArcHeight", 10), 0, 30),
			visualSpin = booleanAttribute(descendant, "VisualSpin", false),
			physicsPathPoints = {},
			duration = numberAttribute(descendant, attributes.MotionDuration, defaults.MotionDuration),
			pauseDuration = numberAttribute(descendant, attributes.PauseDuration, defaultPause),
			pauseMin = pauseMin,
			pauseMax = pauseMax,
			warningDuration = warningDuration,
			cycleOffset = numberAttribute(descendant, attributes.CycleOffset, 0),
			damage = numberAttribute(descendant, attributes.Damage, defaults.SnowballDamage),
			activeTransparency = math.clamp(
				numberAttribute(descendant, attributes.ActiveTransparency, 0),
				0,
				1
			),
			originalTransparency = descendant.Transparency,
			originalCanCollide = descendant.CanCollide,
			originalCanTouch = descendant.CanTouch,
			originalAnchored = descendant.Anchored,
			originalCollisionGroup = descendant.CollisionGroup,
			warning = warning,
			warningTransparency = if warning ~= nil then warning.Transparency else nil,
			phase = "Idle",
			phaseStartedAt = 0,
			nextPhaseAt = 0,
			direction = 1,
			previousCFrame = descendant.CFrame,
			visuals = visuals,
			random = Random.new(seed),
			linearVelocity = nil,
			alignOrientation = nil,
			welds = {},
			motionAttachment = nil,
		}
		if kind == kinds.MovingLog then
			setCollisionGroup(descendant, MOVING_LOG_GROUP)
			for _, visual in ipairs(record.visuals) do
				setCollisionGroup(visual.part, MOVING_LOG_GROUP)
			end
			local attachment = Instance.new("Attachment")
			attachment.Name = "MotionAttachment"
			attachment.Parent = descendant
			local linearVelocity = Instance.new("LinearVelocity")
			linearVelocity.Name = "MotionLinearVelocity"
			linearVelocity.Attachment0 = attachment
			linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
			linearVelocity.ForceLimitsEnabled = false
			linearVelocity.VectorVelocity = (record.endCFrame.Position - record.startCFrame.Position)
				/ math.max(record.duration, 0.01)
			linearVelocity.Enabled = false
			linearVelocity.Parent = descendant
			local alignOrientation = Instance.new("AlignOrientation")
			alignOrientation.Name = "MotionAlignOrientation"
			alignOrientation.Attachment0 = attachment
			alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
			alignOrientation.CFrame = record.startCFrame.Rotation
			alignOrientation.RigidityEnabled = true
			alignOrientation.Enabled = false
			alignOrientation.Parent = descendant
			record.linearVelocity = linearVelocity
			record.alignOrientation = alignOrientation
			record.motionAttachment = attachment
			for _, visual in ipairs(record.visuals) do
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = descendant
				weld.Part1 = visual.part
				weld.Parent = descendant
				table.insert(record.welds, weld)
			end
		end
		table.insert(records, record)
		resetRecord(record, false)
	end
end

local function heartbeat(deltaTime: number)
	local activeCourse = if courseService ~= nil and courseService.GetActiveCourse ~= nil then courseService.GetActiveCourse() else nil
	if activeCourse ~= boundCourse then
		bindCourse(activeCourse)
	end
	local active = raceService ~= nil and raceService.IsRaceActive ~= nil and raceService.IsRaceActive() == true
	if not active then
		if wasRaceActive then
			restoreRecords(false)
		end
		wasRaceActive = false
		return
	end
	local timestamp = now()
	if not wasRaceActive then
		startRace(timestamp)
	end
	wasRaceActive = true
	for _, record in ipairs(records) do
		if record.kind == kinds.MovingLog then
			updateMovingLog(record, timestamp)
		else
			updateHazard(record, timestamp)
		end
	end
end

function CourseMotionService.Init(context: ServiceContext?)
	if isInitialized then
		return
	end
	if context ~= nil then
		courseService = context.Services.CourseService
		raceService = context.Services.RaceService
		playerRaceService = context.Services.PlayerRaceService
		respawnService = context.Services.RespawnService
	end
	isInitialized = true
end

function CourseMotionService.BindActiveCourse()
	local course = if courseService ~= nil and courseService.GetActiveCourse ~= nil then courseService.GetActiveCourse() else nil
	bindCourse(course)
end

function CourseMotionService.Start(_context: ServiceContext?)
	if not isInitialized or isStarted then
		return
	end
	isStarted = true
	CourseMotionService.BindActiveCourse()
	RunService.Heartbeat:Connect(heartbeat)
end

return CourseMotionService
