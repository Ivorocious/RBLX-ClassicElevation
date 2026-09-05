--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MotionConfig = require(ReplicatedStorage.Config.AscentMotionConfig)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)

type ServiceContext = {
	Services: { [string]: any },
}

type MotionRecord = {
	part: BasePart,
	kind: string,
	startCFrame: CFrame,
	endCFrame: CFrame,
	duration: number,
	pauseDuration: number,
	warningDuration: number,
	cycleOffset: number,
	damage: number,
	activeTransparency: number,
	originalTransparency: number,
	originalCanCollide: boolean,
	originalCanTouch: boolean,
	warning: BasePart?,
	warningTransparency: number?,
	phase: string,
	phaseStartedAt: number,
	nextPhaseAt: number,
	direction: number,
	previousCFrame: CFrame,
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

local function movePart(part: BasePart, target: CFrame)
	local delta = target * part.CFrame:Inverse()
	part.CFrame = target
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("BasePart") then child.CFrame = delta * child.CFrame end
	end
end

local function resetRecord(record: MotionRecord, clearDiagnostics: boolean)
	if record.part.Parent ~= nil then
		movePart(record.part, record.startCFrame)
		record.part.Transparency = record.originalTransparency
		record.part.CanCollide = record.originalCanCollide
		record.part.CanTouch = record.originalCanTouch
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

local function currentOverlap(record: MotionRecord): (Player?, boolean)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = if record.warning ~= nil then { record.part, record.warning } else { record.part }
	local hits = Workspace:GetPartBoundsInBox(record.part.CFrame, record.part.Size, params)
	table.sort(hits, function(left, right)
		return (left.Position - record.part.Position).Magnitude < (right.Position - record.part.Position).Magnitude
	end)
	for _, hit in ipairs(hits) do
		local player = playerFromHit(hit)
		if player ~= nil then
			return player, false
		end
		if hit.CanCollide then
			return nil, true
		end
	end
	return nil, false
end

local function sweep(record: MotionRecord, fromPosition: Vector3, toPosition: Vector3): (Player?, boolean)
	local displacement = toPosition - fromPosition
	if displacement.Magnitude < 0.001 then
		return nil, false
	end
	local excluded: { Instance } = { record.part }
	if record.warning ~= nil then
		table.insert(excluded, record.warning)
	end
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
			return nil, true
		end
		table.insert(excluded, result.Instance)
	end
	return nil, false
end

local function carryGroundedRacers(record: MotionRecord, delta: CFrame)
	if delta.Position.Magnitude < 0.0001 then
		return
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if not isActiveRacer(player) then
			continue
		end
		local character = player.Character
		local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
		if humanoid == nil or root == nil or not root:IsA("BasePart") or humanoid.FloorMaterial == Enum.Material.Air then
			continue
		end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { record.part }
		local distance = humanoid.HipHeight + root.Size.Y * 0.5 + MotionConfig.GroundProbeExtraDistance
		local hit = Workspace:Raycast(root.Position, Vector3.new(0, -distance, 0), params)
		if hit ~= nil then
			character:PivotTo(delta * character:GetPivot())
		end
	end
end

local function beginCycle(record: MotionRecord, timestamp: number)
	record.direction = 1
	movePart(record.part, record.startCFrame)
	record.previousCFrame = record.startCFrame
	if record.kind == kinds.MovingLog then
		setPhase(record, "MovingOut", timestamp + record.duration)
	else
		record.part.Transparency = 1
		record.part.CanCollide = false
		record.part.CanTouch = false
		showWarning(record, true)
		setPhase(record, "Warning", timestamp + record.warningDuration)
	end
end

local function startRace(timestamp: number)
	table.clear(contactTimes)
	for _, record in ipairs(records) do
		resetRecord(record, false)
		setPhase(record, "Idle", timestamp + record.cycleOffset)
	end
end

local function updateMovingLog(record: MotionRecord, timestamp: number)
	if record.phase == "Idle" and timestamp >= record.nextPhaseAt then
		beginCycle(record, timestamp)
	elseif (record.phase == "MovingOut" or record.phase == "MovingBack") then
		local alpha = math.clamp((timestamp - record.phaseStartedAt) / math.max(record.duration, 0.01), 0, 1)
		local eased = (1 - math.cos(alpha * math.pi)) * 0.5
		local from = if record.direction == 1 then record.startCFrame else record.endCFrame
		local destination = if record.direction == 1 then record.endCFrame else record.startCFrame
		local previous = record.part.CFrame
		movePart(record.part, from:Lerp(destination, eased))
		carryGroundedRacers(record, record.part.CFrame * previous:Inverse())
		if timestamp >= record.nextPhaseAt then
			movePart(record.part, destination)
			setPhase(record, "Paused", timestamp + record.pauseDuration)
		end
	elseif record.phase == "Paused" and timestamp >= record.nextPhaseAt then
		record.direction *= -1
		setPhase(record, if record.direction == 1 then "MovingOut" else "MovingBack", timestamp + record.duration)
	end
end

local function beginTravel(record: MotionRecord, timestamp: number)
	showWarning(record, false)
	record.part.Transparency = record.activeTransparency
	record.part.CanCollide = record.originalCanCollide
	record.part.CanTouch = record.originalCanTouch
	record.previousCFrame = record.startCFrame
	movePart(record.part, record.startCFrame)
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
		local target = from:Lerp(destination, alpha)
		if record.kind == kinds.Avalanche then
			target *= CFrame.Angles(MotionConfig.AvalancheRotationSpeed * (timestamp - record.phaseStartedAt), 0, 0)
		end
		local hitPlayer, hitCover = currentOverlap(record)
		if hitPlayer == nil and not hitCover then
			hitPlayer, hitCover = sweep(record, record.previousCFrame.Position, target.Position)
		end
		movePart(record.part, target)
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
			record.part.Transparency = 1
			record.part.CanCollide = false
			record.part.CanTouch = false
			setPhase(record, "Cooldown", timestamp + record.pauseDuration)
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
	table.clear(records)
	table.clear(contactTimes)
	boundCourse = course
	wasRaceActive = false
	if course == nil then
		return
	end
	for _, descendant in ipairs(course:GetDescendants()) do
		if not descendant:IsA("BasePart") then
			continue
		end
		local kind = descendant:GetAttribute(attributes.MotionKind)
		local motionEnd = descendant:GetAttribute(attributes.MotionEnd)
		if typeof(kind) ~= "string" or typeof(motionEnd) ~= "CFrame" then
			continue
		end
		if kind ~= kinds.MovingLog and kind ~= kinds.LavaSpurt and kind ~= kinds.Snowball and kind ~= kinds.Avalanche then
			continue
		end
		if not descendant.Anchored then
			warn(string.format("[CourseMotionService] Ignored unanchored motion part %s.", descendant:GetFullName()))
			continue
		end
		local sibling = if descendant.Parent ~= nil then descendant.Parent:FindFirstChild("Warning") else nil
		local warning = if sibling ~= nil and sibling:IsA("BasePart") then sibling else nil
		local record: MotionRecord = {
			part = descendant,
			kind = kind,
			startCFrame = descendant.CFrame,
			endCFrame = motionEnd,
			duration = numberAttribute(descendant, attributes.MotionDuration, defaults.MotionDuration),
			pauseDuration = numberAttribute(descendant, attributes.PauseDuration, defaults.PauseDuration),
			warningDuration = numberAttribute(descendant, attributes.WarningDuration, defaults.WarningDuration),
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
			warning = warning,
			warningTransparency = if warning ~= nil then warning.Transparency else nil,
			phase = "Idle",
			phaseStartedAt = 0,
			nextPhaseAt = 0,
			direction = 1,
			previousCFrame = descendant.CFrame,
		}
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
