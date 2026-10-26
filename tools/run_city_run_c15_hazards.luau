local function makeService()
--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local HazardConfig = (function()
--!strict

local HazardConfig = {}

HazardConfig.AttributeNames = {
	HazardType = "HazardType",
	FallDistance = "FallDistance",
	CycleOffset = "CycleOffset",
	HazardPhase = "HazardPhase",
	NextPhaseAt = "NextPhaseAt",
}

HazardConfig.HazardTypes = {
	Kill = "Kill",
	FallingRock = "FallingRock",
	Crumble = "Crumble",
}

HazardConfig.Phases = {
	Idle = "Idle",
	Solid = "Solid",
	Warning = "Warning",
	Falling = "Falling",
	Cooldown = "Cooldown",
	Resetting = "Resetting",
	Gone = "Gone",
}

HazardConfig.OverlapScanInterval = 0.1

HazardConfig.FallingRock = {
	DefaultFallDistance = 40,
	WarningDuration = 1.3,
	FallDuration = 0.7,
	CooldownDuration = 2.5,
	ResetDuration = 0.1,
	WarningColor = Color3.fromRGB(239, 65, 55),
	WarningMaterial = Enum.Material.Neon,
	WarningTransparency = 0.2,
}

HazardConfig.Crumble = {
	WarningDuration = 1.25,
	GoneDuration = 2,
	WarningColor = Color3.fromRGB(255, 170, 54),
	WarningMaterial = Enum.Material.Neon,
	GoneTransparency = 1,
}

return HazardConfig

end)()
local RaceConstants = (function()
--!strict

local RaceTypes = {} -- Type-only module; no runtime values.

type RaceState = RaceTypes.RaceState
type PlayerRaceStatus = RaceTypes.PlayerRaceStatus
type RaceFormat = RaceTypes.RaceFormat

local RaceConstants = {}

RaceConstants.RaceState = {
	WaitingForPlayers = "WaitingForPlayers" :: RaceState,
	Intermission = "Intermission" :: RaceState,
	Countdown = "Countdown" :: RaceState,
	Racing = "Racing" :: RaceState,
	RaceEnding = "RaceEnding" :: RaceState,
	Results = "Results" :: RaceState,
	Resetting = "Resetting" :: RaceState,
}

RaceConstants.PlayerRaceStatus = {
	Lobby = "Lobby" :: PlayerRaceStatus,
	Queued = "Queued" :: PlayerRaceStatus,
	Racing = "Racing" :: PlayerRaceStatus,
	Finished = "Finished" :: PlayerRaceStatus,
	Spectating = "Spectating" :: PlayerRaceStatus,
	LateRacing = "LateRacing" :: PlayerRaceStatus,
	GhostRacing = "GhostRacing" :: PlayerRaceStatus,
	DNF = "DNF" :: PlayerRaceStatus,
}

RaceConstants.RaceFormat = {
	PointToPoint = "PointToPoint" :: RaceFormat,
	LapBased = "LapBased" :: RaceFormat,
}

RaceConstants.RemoteNames = {
	RaceStateChanged = "RaceStateChanged",
	PlayerRaceStatusChanged = "PlayerRaceStatusChanged",
	RaceTimerUpdated = "RaceTimerUpdated",
	RaceResultsUpdated = "RaceResultsUpdated",
	PersonalRaceSummary = "PersonalRaceSummary",
	RequestSpectate = "RequestSpectate",
	RequestRaceLate = "RequestRaceLate",
	RequestGhostRace = "RequestGhostRace",
	RequestDevRaceState = "RequestDevRaceState",
}

RaceConstants.CollisionGroups = {
	Default = "Default",
	RaceCharacter = "RaceCharacter",
	GhostCharacter = "GhostCharacter",
	Racers = "Racers",
	GhostRacers = "GhostRacers",
}

RaceConstants.DefaultDurations = {
	Intermission = 20,
	Countdown = 5,
	Race = 180,
	RaceEnding = 5,
	Results = 12,
	Resetting = 3,
}

return RaceConstants

end)()
local ManualObstacleMotion = (function()
--!strict

local Workspace = game:GetService("Workspace")
local Motion = {}
local axes = { X = Vector3.xAxis, Y = Vector3.yAxis, Z = Vector3.zAxis }

local function number(part: BasePart, name: string, default: number, low: number, high: number): number
	local value = part:GetAttribute(name)
	return if typeof(value) == "number" and value == value then math.clamp(value, low, high) else default
end

function Motion.Create(course: Model)
	local records = {}
	local elapsed = 0
	local fastest = 0
	for _, part in course:GetDescendants() do
		if not part:IsA("BasePart") or part:GetAttribute("HazardType") ~= "Kill" then continue end
		local kind = part:GetAttribute("KitMotion")
		if kind ~= "Spin" and kind ~= "Swing" and kind ~= "Slide" then continue end
		assert(part.Anchored, "Moving kit traps must be anchored: " .. part:GetFullName())
		local period = number(part, "MotionPeriod", 6, 2, 120)
		local distance = number(part, "MotionDistance", 6, 0, 100)
		local angle = math.rad(number(part, "MotionAngle", 60, 0, 170))
		local axisName = part:GetAttribute("MotionAxis")
		local axis = axes[if typeof(axisName) == "string" then axisName else "Y"] or Vector3.yAxis
		local rate = math.pi * 2 / period
		local speed = rate * (if kind == "Slide" then distance else part.Size.Magnitude/2 * (if kind == "Swing" then angle else 1))
		fastest = math.max(fastest, speed)
		table.insert(records, { part = part, start = part.CFrame, kind = kind, axis = axis,
			rate = rate, distance = distance, angle = angle, speed = speed,
			phase = math.rad(number(part, "MotionPhase", 0, 0, 360)) })
	end
	if #records == 0 then return nil end
	local controller = {}
	local function pose(record, time: number): CFrame
		local phase = time * record.rate + record.phase
		if record.kind == "Slide" then
			return record.start * CFrame.new(record.axis * math.sin(phase) * record.distance)
		end
		local angle = if record.kind == "Spin" then phase else math.sin(phase) * record.angle
		return record.start * CFrame.fromAxisAngle(record.axis, angle)
	end
	function controller.Reset()
		elapsed = 0
		for _, record in records do
			if record.part.Parent then record.part.CFrame = record.start end
		end
	end
	function controller.Step(deltaTime: number, overlap: OverlapParams?, onHit)
		-- Slow the timeline on a stall instead of skipping across a racer.
		local advance = math.min(deltaTime, .1, 8 / math.max(fastest, 1))
		for _, record in records do
			if not record.part.Parent then continue end
			if overlap then
				local steps = math.max(1, math.ceil(record.speed * advance / .5))
				for step = 0, steps do
					local cf = pose(record, elapsed + advance * step / steps)
					record.part.CFrame = cf
					for _, hit in Workspace:GetPartsInPart(record.part, overlap) do onHit(hit) end
				end
			end
			record.part.CFrame = pose(record, elapsed + advance)
		end
		elapsed += advance
	end
	return controller
end

return Motion

end)()

type ServiceContext = {
	Services: { [string]: any },
}

type PartVisual = {
	part: BasePart,
	transparency: number,
	color: Color3,
	material: Enum.Material,
}

type WarningVisual = {
	part: BasePart,
	color: Color3,
	material: Enum.Material,
	transparency: number,
}

type FallingRockRecord = {
	part: BasePart,
	warning: WarningVisual?,
	startCFrame: CFrame,
	landingCFrame: CFrame,
	originalTransparency: number,
	phase: string,
	nextPhaseAt: number,
	tween: Tween?,
}

type CrumbleRecord = {
	part: BasePart,
	visuals: { PartVisual },
	originalColor: Color3,
	originalMaterial: Enum.Material,
	originalCanCollide: boolean,
	originalCanTouch: boolean,
	phase: string,
	nextPhaseAt: number,
	warningDuration: number,
	goneDuration: number,
}

local CourseHazardService = {}

local isInitialized = false
local isStarted = false
local raceService: any = nil
local courseService: any = nil
local playerRaceService: any = nil
local respawnService: any = nil

local killParts: { BasePart } = {}
local fallingRocks: { FallingRockRecord } = {}
local crumbles: { CrumbleRecord } = {}
local touchConnections: { RBXScriptConnection } = {}
local overlapAccumulator = 0
local wasRaceActive = false
local manualMotion: any = nil

local attributes = HazardConfig.AttributeNames
local phases = HazardConfig.Phases
local hazardTypes = HazardConfig.HazardTypes

local function getServerTime(): number
	return Workspace:GetServerTimeNow()
end

local function isRaceActive(): boolean
	return raceService ~= nil
		and raceService.IsRaceActive ~= nil
		and raceService.IsRaceActive() == true
end

local function isActiveOfficialRacer(player: Player): boolean
	if not isRaceActive() or playerRaceService == nil then
		return false
	end

	if playerRaceService.IsOfficialRacer == nil or playerRaceService.GetPlayerStatus == nil then
		return false
	end

	return playerRaceService.IsOfficialRacer(player) == true
		and playerRaceService.GetPlayerStatus(player) == RaceConstants.PlayerRaceStatus.Racing
end

local function getPlayerFromPart(part: BasePart): Player?
	local character = part:FindFirstAncestorWhichIsA("Model")

	-- Cosmetic accessories and the invisible root must not extend a lethal contact.
	if character == nil or part.Parent ~= character or part.Name == "HumanoidRootPart" or part.Transparency >= 1 then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function recoverPlayerFromPart(part: BasePart)
	local player = getPlayerFromPart(part)

	if player == nil or respawnService == nil or respawnService.RecoverPlayer == nil then
		return
	end

	respawnService.RecoverPlayer(player, "CourseHazard")
end

local function setPhase(instance: BasePart, phase: string, nextPhaseAt: number)
	instance:SetAttribute(attributes.HazardPhase, phase)
	instance:SetAttribute(attributes.NextPhaseAt, nextPhaseAt)
end

local function setWarningVisible(warning: WarningVisual?, visible: boolean)
	if warning == nil or warning.part.Parent == nil then
		return
	end

	if visible then
		warning.part.Color = HazardConfig.FallingRock.WarningColor
		warning.part.Material = HazardConfig.FallingRock.WarningMaterial
		warning.part.Transparency = HazardConfig.FallingRock.WarningTransparency
	else
		warning.part.Transparency = 1
	end
end

local function cancelRockTween(record: FallingRockRecord)
	if record.tween ~= nil then
		record.tween:Cancel()
		record.tween = nil
	end
end

local function resetFallingRock(record: FallingRockRecord, restoreWarning: boolean)
	cancelRockTween(record)

	if record.part.Parent ~= nil then
		record.part.CFrame = record.startCFrame
		record.part.Transparency = record.originalTransparency
		record.phase = phases.Idle
		record.nextPhaseAt = 0
		setPhase(record.part, phases.Idle, 0)
	end

	if restoreWarning and record.warning ~= nil and record.warning.part.Parent ~= nil then
		record.warning.part.Color = record.warning.color
		record.warning.part.Material = record.warning.material
		record.warning.part.Transparency = record.warning.transparency
	else
		setWarningVisible(record.warning, false)
	end
end

local function restoreCrumble(record: CrumbleRecord, clearPhaseAttributes: boolean)
	if record.part.Parent ~= nil then
		record.part.Color = record.originalColor
		record.part.Material = record.originalMaterial
		record.part.CanCollide = record.originalCanCollide
		record.part.CanTouch = record.originalCanTouch
		record.phase = phases.Solid
		record.nextPhaseAt = 0

		if clearPhaseAttributes then
			record.part:SetAttribute(attributes.HazardPhase, nil)
			record.part:SetAttribute(attributes.NextPhaseAt, nil)
		else
			setPhase(record.part, phases.Solid, 0)
		end
	end

	for _, visual in ipairs(record.visuals) do
		if visual.part.Parent ~= nil then
			visual.part.Transparency = visual.transparency
			visual.part.Color = visual.color
			visual.part.Material = visual.material
		end
	end
end

local function restoreBoundHazards()
	if manualMotion then manualMotion.Reset() end
	for _, record in ipairs(fallingRocks) do
		resetFallingRock(record, true)

		if record.part.Parent ~= nil then
			record.part:SetAttribute(attributes.HazardPhase, nil)
			record.part:SetAttribute(attributes.NextPhaseAt, nil)
		end
	end

	for _, record in ipairs(crumbles) do
		restoreCrumble(record, true)
	end
end

local function disconnectTouchConnections()
	for _, connection in ipairs(touchConnections) do
		connection:Disconnect()
	end

	table.clear(touchConnections)
end

local function beginRockWarning(record: FallingRockRecord, now: number)
	if record.part.Parent == nil then
		return
	end

	cancelRockTween(record)
	record.part.CFrame = record.startCFrame
	record.part.Transparency = 0
	setWarningVisible(record.warning, true)
	record.phase = phases.Warning
	record.nextPhaseAt = now + HazardConfig.FallingRock.WarningDuration
	setPhase(record.part, record.phase, record.nextPhaseAt)
end

local function beginRockFall(record: FallingRockRecord, now: number)
	if record.part.Parent == nil then
		return
	end

	record.phase = phases.Falling
	record.nextPhaseAt = now + HazardConfig.FallingRock.FallDuration
	setPhase(record.part, record.phase, record.nextPhaseAt)

	record.tween = TweenService:Create(
		record.part,
		TweenInfo.new(HazardConfig.FallingRock.FallDuration, Enum.EasingStyle.Linear),
		{ CFrame = record.landingCFrame }
	)
	record.tween:Play()
end

local function beginRockCooldown(record: FallingRockRecord, now: number)
	cancelRockTween(record)

	if record.part.Parent == nil then
		return
	end

	record.part.CFrame = record.landingCFrame
	setWarningVisible(record.warning, false)
	record.phase = phases.Cooldown
	record.nextPhaseAt = now + HazardConfig.FallingRock.CooldownDuration
	setPhase(record.part, record.phase, record.nextPhaseAt)
end

local function beginRockReset(record: FallingRockRecord, now: number)
	cancelRockTween(record)

	if record.part.Parent == nil then
		return
	end

	record.part.Transparency = 1
	record.part.CFrame = record.startCFrame
	record.phase = phases.Resetting
	record.nextPhaseAt = now + HazardConfig.FallingRock.ResetDuration
	setPhase(record.part, record.phase, record.nextPhaseAt)
end

local function updateFallingRocks(now: number)
	for _, record in ipairs(fallingRocks) do
		if now < record.nextPhaseAt then
			continue
		end

		if record.phase == phases.Idle or record.phase == phases.Resetting then
			beginRockWarning(record, now)
		elseif record.phase == phases.Warning then
			beginRockFall(record, now)
		elseif record.phase == phases.Falling then
			beginRockCooldown(record, now)
		elseif record.phase == phases.Cooldown then
			beginRockReset(record, now)
		end
	end
end

local function beginCrumbleWarning(record: CrumbleRecord)
	if record.phase ~= phases.Solid or record.part.Parent == nil then
		return
	end

	for _, visual in ipairs(record.visuals) do
		visual.part.Color = HazardConfig.Crumble.WarningColor
	end
	record.part.Color = HazardConfig.Crumble.WarningColor
	record.part.Material = HazardConfig.Crumble.WarningMaterial
	record.phase = phases.Warning
	record.nextPhaseAt = getServerTime() + record.warningDuration
	setPhase(record.part, record.phase, record.nextPhaseAt)
end

local function updateCrumbles(now: number)
	for _, record in ipairs(crumbles) do
		if record.nextPhaseAt == 0 or now < record.nextPhaseAt then
			continue
		end

		if record.phase == phases.Warning then
			record.part.CanCollide = false
			record.part.CanTouch = false

			for _, visual in ipairs(record.visuals) do
				if visual.part.Parent ~= nil then
					visual.part.Transparency = HazardConfig.Crumble.GoneTransparency
				end
			end

			record.phase = phases.Gone
			record.nextPhaseAt = now + record.goneDuration
			setPhase(record.part, record.phase, record.nextPhaseAt)
		elseif record.phase == phases.Gone then
			restoreCrumble(record, false)
		end
	end
end

local function buildOverlapFilter(): { Instance }
	local characters: { Instance } = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if isActiveOfficialRacer(player) and player.Character ~= nil then
			table.insert(characters, player.Character)
		end
	end

	return characters
end

local function scanPartForRacers(hazardPart: BasePart, overlapParams: OverlapParams)
	if hazardPart.Parent == nil or not hazardPart.CanQuery then
		return
	end

	for _, overlappingPart in ipairs(Workspace:GetPartsInPart(hazardPart, overlapParams)) do
		recoverPlayerFromPart(overlappingPart)
	end
end

local function scanLethalOverlaps()
	local characters = buildOverlapFilter()

	if #characters == 0 then
		return
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = characters

	for _, killPart in ipairs(killParts) do
		scanPartForRacers(killPart, overlapParams)
	end

	for _, record in ipairs(fallingRocks) do
		if record.phase == phases.Falling then
			scanPartForRacers(record.part, overlapParams)
		end
	end
end

local function resetForInactiveRace()
	if manualMotion then manualMotion.Reset() end
	for _, record in ipairs(fallingRocks) do
		resetFallingRock(record, false)
	end

	for _, record in ipairs(crumbles) do
		restoreCrumble(record, false)
	end
end

local function startRaceHazards(now: number)
	for _, record in ipairs(fallingRocks) do
		resetFallingRock(record, false)
		local offset = record.part:GetAttribute(attributes.CycleOffset)
		local cycleOffset = if typeof(offset) == "number" then math.max(0, offset) else 0
		record.nextPhaseAt = now + cycleOffset
		setPhase(record.part, phases.Idle, record.nextPhaseAt)
	end
end

local function updateHazards(deltaTime: number)
	local active = isRaceActive()

	if not active then
		if wasRaceActive then
			resetForInactiveRace()
		end

		wasRaceActive = false
		overlapAccumulator = 0
		return
	end

	local now = getServerTime()

	if not wasRaceActive then
		startRaceHazards(now)
	end

	wasRaceActive = true
	if manualMotion then
		local characters = buildOverlapFilter()
		local overlap = nil
		if #characters > 0 then
			overlap = OverlapParams.new()
			overlap.FilterType = Enum.RaycastFilterType.Include
			overlap.FilterDescendantsInstances = characters
		end
		manualMotion.Step(deltaTime, overlap, recoverPlayerFromPart)
	end
	updateFallingRocks(now)
	updateCrumbles(now)
	overlapAccumulator += deltaTime

	if overlapAccumulator >= HazardConfig.OverlapScanInterval then
		overlapAccumulator = 0
		scanLethalOverlaps()
	end
end

local function makeWarningVisual(part: BasePart): WarningVisual?
	local parent = part.Parent
	local warning = if parent ~= nil then parent:FindFirstChild("Warning") else nil

	if warning == nil or not warning:IsA("BasePart") then
		warn(
			string.format(
				"[CourseHazardService] Falling rock %s has no BasePart sibling named Warning.",
				part:GetFullName()
			)
		)
		return nil
	end

	return {
		part = warning,
		color = warning.Color,
		material = warning.Material,
		transparency = warning.Transparency,
	}
end

local function bindKillPart(part: BasePart)
	table.insert(killParts, part)
	table.insert(touchConnections, part.Touched:Connect(function(touchedPart)
		if getPlayerFromPart(touchedPart) == nil then return end
		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Include
		overlap.FilterDescendantsInstances = { touchedPart }
		-- Touched can arrive at the physics contact margin; confirm the actual shapes overlap.
		if #Workspace:GetPartsInPart(part, overlap) > 0 then recoverPlayerFromPart(touchedPart) end
	end))
end

local function bindFallingRock(part: BasePart)
	if not part.Anchored then
		warn(
			string.format("[CourseHazardService] Ignored unanchored falling rock %s.", part:GetFullName())
		)
		return
	end

	if not part.CanQuery then
		warn(
			string.format(
				"[CourseHazardService] Falling rock %s cannot run overlap checks while CanQuery is false.",
				part:GetFullName()
			)
		)
	end

	local fallDistanceAttribute = part:GetAttribute(attributes.FallDistance)
	local fallDistance = if typeof(fallDistanceAttribute) == "number"
		then math.max(0, fallDistanceAttribute)
		else HazardConfig.FallingRock.DefaultFallDistance
	local record: FallingRockRecord = {
		part = part,
		warning = makeWarningVisual(part),
		startCFrame = part.CFrame,
		landingCFrame = part.CFrame + Vector3.new(0, -fallDistance, 0),
		originalTransparency = part.Transparency,
		phase = phases.Idle,
		nextPhaseAt = 0,
		tween = nil,
	}

	table.insert(fallingRocks, record)
	resetFallingRock(record, false)
	table.insert(touchConnections, part.Touched:Connect(function(touchedPart)
		if record.phase == phases.Falling then
			recoverPlayerFromPart(touchedPart)
		end
	end))
end

local function bindCrumble(part: BasePart)
	local crumbleDelayAttribute = part:GetAttribute("CrumbleDelay")
	local crumbleResetTimeAttribute = part:GetAttribute("CrumbleResetTime")
	local warningDuration = if typeof(crumbleDelayAttribute) == "number"
		then math.max(0, crumbleDelayAttribute)
		else HazardConfig.Crumble.WarningDuration
	local goneDuration = if typeof(crumbleResetTimeAttribute) == "number"
		then math.max(0, crumbleResetTimeAttribute)
		else HazardConfig.Crumble.GoneDuration
	local visuals: { PartVisual } = {
		{
			part = part,
			transparency = part.Transparency,
			color = part.Color,
			material = part.Material,
		},
	}

	for _, descendant in ipairs(part:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(visuals, {
				part = descendant,
				transparency = descendant.Transparency,
				color = descendant.Color,
				material = descendant.Material,
			})
		end
	end

	local record: CrumbleRecord = {
		part = part,
		visuals = visuals,
		originalColor = part.Color,
		originalMaterial = part.Material,
		originalCanCollide = part.CanCollide,
		originalCanTouch = part.CanTouch,
		phase = phases.Solid,
		nextPhaseAt = 0,
		warningDuration = warningDuration,
		goneDuration = goneDuration,
	}

	table.insert(crumbles, record)
	restoreCrumble(record, false)
	table.insert(touchConnections, part.Touched:Connect(function(touchedPart)
		local player = getPlayerFromPart(touchedPart)

		if player ~= nil and isActiveOfficialRacer(player) then
			beginCrumbleWarning(record)
		end
	end))
end

function CourseHazardService.Init(context: ServiceContext?)
	if isInitialized then
		return
	end

	if context ~= nil then
		raceService = context.Services.RaceService
		courseService = context.Services.CourseService
		playerRaceService = context.Services.PlayerRaceService
		respawnService = context.Services.RespawnService
	end

	if raceService == nil then
		warn("[CourseHazardService] RaceService dependency is missing.")
	end

	if courseService == nil then
		warn("[CourseHazardService] CourseService dependency is missing.")
	end

	if playerRaceService == nil then
		warn("[CourseHazardService] PlayerRaceService dependency is missing.")
	end

	if respawnService == nil then
		warn("[CourseHazardService] RespawnService dependency is missing.")
	end

	isInitialized = true
end

function CourseHazardService.BindActiveCourse()
	disconnectTouchConnections()
	restoreBoundHazards()
	manualMotion = nil
	table.clear(killParts)
	table.clear(fallingRocks)
	table.clear(crumbles)
	wasRaceActive = false
	overlapAccumulator = 0

	if courseService == nil or courseService.GetActiveCourse == nil then
		warn("[CourseHazardService] Active course dependency is unavailable.")
		return
	end

	local course = courseService.GetActiveCourse()

	if course == nil then
		return
	end
	manualMotion = ManualObstacleMotion.Create(course)

	for _, descendant in ipairs(course:GetDescendants()) do
		if not descendant:IsA("BasePart") then
			continue
		end

		local hazardType = descendant:GetAttribute(attributes.HazardType)

		if hazardType == hazardTypes.Kill then
			bindKillPart(descendant)
		elseif hazardType == hazardTypes.FallingRock then
			bindFallingRock(descendant)
		elseif hazardType == hazardTypes.Crumble then
			bindCrumble(descendant)
		end
	end

	print(
		string.format(
			"[CourseHazardService] Bound %d kill part(s), %d falling rock(s), and %d crumble part(s).",
			#killParts,
			#fallingRocks,
			#crumbles
		)
	)
end

function CourseHazardService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[CourseHazardService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true
	CourseHazardService.BindActiveCourse()
	RunService.Heartbeat:Connect(updateHazards)
end

return CourseHazardService

end

local function run()
 local player=game.Players:GetPlayers()[1];local char=player.Character;local root=char.HumanoidRootPart;local hum=char.Humanoid
 local saved,anchored=char:GetPivot(),root.Anchored
 local fixture=Instance.new("Model");fixture.Name="__C15HazardFixture"
 game.ServerStorage.CourseLibrary.Course_CityRun.Obstacles.C15Routes:Clone().Parent=fixture
 fixture:PivotTo(fixture:GetPivot()+Vector3.new(5000,0,0));fixture.Parent=workspace
 local current=fixture;local hits=0;local records={}
 local service=makeService()
 service.Init({Services={
 RaceService={IsRaceActive=function() return true end},
 PlayerRaceService={IsOfficialRacer=function(p) return p==player end,GetPlayerStatus=function() return "Racing" end},
 CourseService={GetActiveCourse=function() return current end},
 RespawnService={RecoverPlayer=function() hits+=1;char:PivotTo(saved);return true end}
 }})
 local function waitFor(fn,seconds,label)
 local deadline=os.clock()+seconds;repeat task.wait(.03) until fn() or os.clock()>deadline;assert(fn(),label) end
 local ok,err=xpcall(function()
  local rotor,swing,hurdle,tile
  local tiles=0
  for _,p in fixture:GetDescendants() do if p:IsA("BasePart") then
   if p:GetAttribute("KitMotion")=="Spin" and not rotor then rotor=p end
   if p:GetAttribute("KitMotion")=="Swing" and not swing then swing=p end
   if p.Name:find("CrossingHurdle",1,true) and p:GetAttribute("HazardType")=="Kill" then hurdle=p end
   if p:GetAttribute("HazardType")=="Crumble" then tiles+=1;if p.Parent.Name=="C15_Crumble_00_0" then tile=p end end
  end end
  assert(tiles==52 and tile and rotor and swing and hurdle)
  local rs,ss=rotor.CFrame,swing.CFrame
  service.Start();task.wait(.25)
  assert((rotor.CFrame.LookVector-rs.LookVector).Magnitude>.01 and (swing.CFrame.LookVector-ss.LookVector).Magnitude>.01,"New motion did not run")
  table.insert(records,{name="RotorAndSwingMotion",passed=true})
  for label,p in {Rotor=rotor,Swing=swing,ApproachHurdle=hurdle} do
   local before=hits;root.Anchored=true;char:PivotTo(p.CFrame)
   waitFor(function() return hits>before end,2,label.." contact did not recover")
   table.insert(records,{name=label.."Contact",passed=true})
  end
  root.Anchored=false;root:SetNetworkOwner(nil);char:PivotTo(CFrame.new(tile.Position+Vector3.new(0,.5+hum.HipHeight+root.Size.Y/2+.1,0)));root.AssemblyLinearVelocity=Vector3.zero
  waitFor(function() return tile:GetAttribute("HazardPhase")=="Warning" end,2,"Crumble did not warn")
  waitFor(function() return tile:GetAttribute("HazardPhase")=="Gone" end,2,"Crumble did not disappear")
  assert(not tile.CanCollide);local visuals=0
  for _,p in tile:GetDescendants() do if p:IsA("BasePart") then visuals+=1;assert(p.Transparency==1,"Crumble skin did not fade") end end
  assert(visuals>0);root.Anchored=true;char:PivotTo(saved)
  waitFor(function() return tile:GetAttribute("HazardPhase")=="Solid" end,4,"Crumble did not reset")
  assert(tile.CanCollide)
  table.insert(records,{name="CrumbleWarningGoneVisualsReset",passed=true,tiles=tiles,visuals=visuals})
 end,debug.traceback)
 current=nil;service.BindActiveCourse();char:PivotTo(saved);root.Anchored=anchored;root.AssemblyLinearVelocity=Vector3.zero
 if not anchored then root:SetNetworkOwnershipAuto() end;fixture:Destroy()
 return {passed=ok,records=records,failure=err,method="Current server hazard source inlined with current config, actual player contacts in isolated fixture; mock race eligibility and recovery callback"}
end
local r=Instance.new("StringValue");r.Name="C15HazardResult";r.Parent=game.ServerStorage;r.Value="Running"
task.spawn(function() local ok,result=pcall(run);r.Value=game:GetService("HttpService"):JSONEncode({ok=ok,result=result}) end)
return "Started focused C15 service contact and crumble check"

