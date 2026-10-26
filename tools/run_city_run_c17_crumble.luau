--!strict
-- Run as a temporary normal Server Script in a Studio Play server.
-- Exact source snapshots are inserted below by this repository writer; no source ModuleScript is required.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
assert(RunService:IsServer() and RunService:IsRunning(), "Run in a Studio Play server")
local player = assert(Players:GetPlayers()[1], "One Studio test player is required")
local character = player.Character or player.CharacterAdded:Wait()

local function hazardConfigSourceFactory(game, require, script)--!strict

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
	ShakeDistance = 0.12,
	ShakeFrequency = 18,
	FallDistance = 18,
	FallDuration = 0.55,
}

return HazardConfig
end

local function courseHazardSourceFactory(game, require, script)--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local HazardConfig = require(ReplicatedStorage.Config.HazardConfig)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local ManualObstacleMotion = require(game.ServerStorage.CourseBuilders.ManualObstacleMotion)

type ServiceContext = {
	Services: { [string]: any },
}

type PartVisual = {
	part: BasePart,
	transparency: number,
	color: Color3,
	material: Enum.Material,
	cframe: CFrame,
	anchored: boolean,
	canCollide: boolean,
	canTouch: boolean,
	tween: Tween?,
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
	phase: string,
	nextPhaseAt: number,
	warningDuration: number,
	goneDuration: number,
	fallDuration: number,
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
local heartbeatConnection: RBXScriptConnection? = nil

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
	for _, visual in ipairs(record.visuals) do
		if visual.part.Parent ~= nil then
			if visual.tween ~= nil then
				visual.tween:Cancel()
				visual.tween = nil
			end

			visual.part.Transparency = visual.transparency
			visual.part.Color = visual.color
			visual.part.Material = visual.material
			visual.part.CFrame = visual.cframe
			visual.part.Anchored = visual.anchored
			visual.part.CanCollide = visual.canCollide
			visual.part.CanTouch = visual.canTouch
		end
	end

	if record.part.Parent ~= nil then
		record.phase = phases.Solid
		record.nextPhaseAt = 0

		if clearPhaseAttributes then
			record.part:SetAttribute(attributes.HazardPhase, nil)
			record.part:SetAttribute(attributes.NextPhaseAt, nil)
		else
			setPhase(record.part, phases.Solid, 0)
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
		if visual.part.Parent ~= nil then
			visual.part.Anchored = true
		end
	end

	record.phase = phases.Warning
	record.nextPhaseAt = getServerTime() + record.warningDuration
	setPhase(record.part, record.phase, record.nextPhaseAt)
end

local function updateCrumbleWarningShake(record: CrumbleRecord, now: number)
	local remaining = record.nextPhaseAt - now
	local elapsed = record.warningDuration - math.max(0, remaining)
	local distance = HazardConfig.Crumble.ShakeDistance
	local frequency = HazardConfig.Crumble.ShakeFrequency
	local offset = CFrame.new(
		math.sin(elapsed * frequency) * distance,
		math.cos(elapsed * frequency * 1.3) * distance * 0.35,
		math.sin(elapsed * frequency * 0.7) * distance * 0.45
	)

	for _, visual in ipairs(record.visuals) do
		if visual.part.Parent ~= nil then
			visual.part.CFrame = visual.cframe * offset
		end
	end
end

local function beginCrumbleFall(record: CrumbleRecord, now: number)
	if record.part.Parent == nil then
		return
	end

	local fallOffset = Vector3.new(0, -HazardConfig.Crumble.FallDistance, 0)
	local tweenInfo = TweenInfo.new(record.fallDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	for _, visual in ipairs(record.visuals) do
		if visual.part.Parent ~= nil then
			visual.part.CFrame = visual.cframe
			visual.part.Anchored = true
			visual.part.CanCollide = false
			visual.part.CanTouch = false

			if record.fallDuration > 0 then
				visual.tween = TweenService:Create(visual.part, tweenInfo, { CFrame = visual.cframe + fallOffset })
				visual.tween:Play()
			else
				visual.part.CFrame = visual.cframe + fallOffset
			end
		end
	end

	record.phase = phases.Falling
	record.nextPhaseAt = now + record.fallDuration
	setPhase(record.part, record.phase, record.nextPhaseAt)
end

local function updateCrumbles(now: number)
	for _, record in ipairs(crumbles) do
		if record.phase == phases.Warning then
			updateCrumbleWarningShake(record, now)
		end

		if record.nextPhaseAt == 0 or now < record.nextPhaseAt then
			continue
		end

		if record.phase == phases.Warning then
			beginCrumbleFall(record, now)
		elseif record.phase == phases.Falling then
			for _, visual in ipairs(record.visuals) do
				if visual.tween ~= nil then
					visual.tween:Cancel()
					visual.tween = nil
				end
			end

			record.phase = phases.Gone
			record.nextPhaseAt = now + math.max(0, record.goneDuration - record.fallDuration)
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
			cframe = part.CFrame,
			anchored = part.Anchored,
			canCollide = part.CanCollide,
			canTouch = part.CanTouch,
			tween = nil,
		},
	}

	for _, descendant in ipairs(part:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(visuals, {
				part = descendant,
				transparency = descendant.Transparency,
				color = descendant.Color,
				material = descendant.Material,
				cframe = descendant.CFrame,
				anchored = descendant.Anchored,
				canCollide = descendant.CanCollide,
				canTouch = descendant.CanTouch,
				tween = nil,
			})
		end
	end

	local record: CrumbleRecord = {
		part = part,
		visuals = visuals,
		phase = phases.Solid,
		nextPhaseAt = 0,
		warningDuration = warningDuration,
		goneDuration = goneDuration,
		fallDuration = math.min(goneDuration, HazardConfig.Crumble.FallDuration),
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
	heartbeatConnection = RunService.Heartbeat:Connect(updateHazards)
end

function CourseHazardService.Stop()
	if heartbeatConnection ~= nil then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end

	disconnectTouchConnections()
	restoreBoundHazards()
	manualMotion = nil
	table.clear(killParts)
	table.clear(fallingRocks)
	table.clear(crumbles)
	wasRaceActive = false
	overlapAccumulator = 0
	isStarted = false
end
return CourseHazardService
end

local HazardConfig = hazardConfigSourceFactory(game, require, script)
local RaceConstants = { PlayerRaceStatus = { Racing = "Racing" } }
local ManualObstacleMotion = {
	Create = function(_course)
		return {
			Reset = function() end,
			Step = function(_deltaTime, _overlapParams, _recover) end,
		}
	end,
}
local function harnessRequire(moduleScript)
	if moduleScript == ReplicatedStorage.Config.HazardConfig then return HazardConfig end
	if moduleScript == ReplicatedStorage.Shared.RaceConstants then return RaceConstants end
	if moduleScript == ServerStorage.CourseBuilders.ManualObstacleMotion then return ManualObstacleMotion end
	error("Unexpected source dependency: " .. moduleScript:GetFullName())
end
local CourseHazardService = courseHazardSourceFactory(game, harnessRequire, script)
local activeRace = true
local currentCourse = nil
local records = {}

local function waitUntil(predicate, timeout, message)
	local deadline = os.clock() + timeout
	repeat task.wait(0.03) until predicate() or os.clock() >= deadline
	assert(predicate(), message)
end

local fixture = Instance.new("Model")
fixture.Name = "__C17CrumbleFixture"
local obstacles = Instance.new("Folder")
obstacles.Name = "Obstacles"
obstacles.Parent = fixture
local collider = Instance.new("Part")
collider.Name = "CrumbleCollider"
collider.Size = Vector3.new(8, 1, 8)
collider.Anchored, collider.CanCollide, collider.CanTouch, collider.CanQuery = true, true, true, true
collider.Color, collider.Material, collider.CFrame = Color3.fromRGB(85, 125, 185), Enum.Material.Slate, CFrame.new(0, 1000, 0)
collider:SetAttribute(HazardConfig.AttributeNames.HazardType, HazardConfig.HazardTypes.Crumble)
collider:SetAttribute("CrumbleDelay", 0.35)
collider:SetAttribute("CrumbleResetTime", 1.1)
collider.Parent = obstacles
local skin = Instance.new("Part")
skin.Name = "AttachedVisualSkin"
skin.Size = Vector3.new(5, 0.25, 5)
skin.Anchored, skin.CanCollide, skin.CanTouch, skin.CanQuery = true, true, true, false
skin.Color, skin.Material, skin.CFrame = Color3.fromRGB(38, 184, 136), Enum.Material.WoodPlanks, collider.CFrame * CFrame.new(0, 0.625, 0)
skin.Parent = collider
assert(skin:IsDescendantOf(collider), "Skin must be a collider descendant")
local colliderCFrame, skinCFrame = collider.CFrame, skin.CFrame
local colliderColor, skinColor = collider.Color, skin.Color

local function assertAuthored(clearPhase)
	assert(collider.CFrame == colliderCFrame and skin.CFrame == skinCFrame, "Transforms were not restored")
	assert(collider.Color == colliderColor and skin.Color == skinColor, "Colors were not restored")
	assert(collider.CanCollide and skin.CanCollide and collider.CanTouch and skin.CanTouch, "Collision or touch was not restored")
	if clearPhase then assert(collider:GetAttribute(HazardConfig.AttributeNames.HazardPhase) == nil, "Stop did not clear phase") end
end

local function makeProbe()
	local probe = Instance.new("Part")
	probe.Name, probe.Size, probe.Transparency = "__C17CrumbleProbe", Vector3.new(1, 1, 1), 0.99
	probe.CanCollide, probe.CanTouch, probe.CanQuery, probe.Massless = false, true, false, true
	probe.CFrame, probe.Parent = collider.CFrame + Vector3.new(0, 4, 0), character
	probe:SetNetworkOwner(nil)
	return probe
end

local ok, failure = xpcall(function()
	fixture.Parent, currentCourse = Workspace, fixture
	CourseHazardService.Init({ Services = {
		RaceService = { IsRaceActive = function() return activeRace end },
		CourseService = { GetActiveCourse = function() return currentCourse end },
		PlayerRaceService = {
			IsOfficialRacer = function(candidate) return candidate == player end,
			GetPlayerStatus = function(candidate) return if candidate == player then "Racing" else "Lobby" end,
		},
		RespawnService = { RecoverPlayer = function() end },
	} })
	CourseHazardService.Start()

	local probe = makeProbe()
	waitUntil(function() return collider:GetAttribute(HazardConfig.AttributeNames.HazardPhase) == HazardConfig.Phases.Warning end, 3, "Real collider touch did not start Warning")
	local warningCFrame = collider.CFrame
	task.wait(0.1)
	assert((collider.Position - warningCFrame.Position).Magnitude > 0.01, "Collider did not shake")
	assert((skin.Position - skinCFrame.Position).Magnitude > 0.01, "Child skin did not shake")
	assert(collider.Color == colliderColor and skin.Color == skinColor, "Warning changed colors")
	assert(collider.CanCollide and skin.CanCollide, "Warning disabled collision early")
	probe:Destroy()

	waitUntil(function() return collider:GetAttribute(HazardConfig.AttributeNames.HazardPhase) == HazardConfig.Phases.Falling end, 2, "Crumble did not begin Falling")
	assert(collider.Anchored and skin.Anchored, "Falling pieces were not anchored")
	assert(not collider.CanCollide and not skin.CanCollide and not collider.CanTouch and not skin.CanTouch, "Falling pieces kept collision or touch")
	waitUntil(function() return collider.Position.Y < colliderCFrame.Position.Y - HazardConfig.Crumble.FallDistance * 0.5 end, 2, "Collider did not visibly fall")
	assert((skin.Position - skinCFrame.Position - (collider.Position - colliderCFrame.Position)).Magnitude < 0.01, "Child skin offset changed while falling")
	table.insert(records, { name = "RealColliderSkinShakeAndFall", passed = true })

	activeRace = false
	waitUntil(function() return collider:GetAttribute(HazardConfig.AttributeNames.HazardPhase) == HazardConfig.Phases.Solid end, 2, "Inactive-race cleanup did not restore")
	assertAuthored(false)
	table.insert(records, { name = "InactiveRaceRestore", passed = true })

	activeRace = true
	local secondProbe = makeProbe()
	waitUntil(function() return collider:GetAttribute(HazardConfig.AttributeNames.HazardPhase) == HazardConfig.Phases.Warning end, 3, "Second collider touch did not start Warning")
	secondProbe:Destroy()
	waitUntil(function() return collider:GetAttribute(HazardConfig.AttributeNames.HazardPhase) == HazardConfig.Phases.Falling end, 2, "Second crumble cycle did not begin Falling")
	CourseHazardService.Stop()
	assertAuthored(true)
	table.insert(records, { name = "StopRestore", passed = true })
end, debug.traceback)

pcall(function() CourseHazardService.Stop() end)
fixture:Destroy()
local result=HttpService:JSONEncode({
	passed = ok,
	records = records,
	failure = if ok then nil else failure,
	method = "Exact inline HazardConfig and CourseHazardService source runs through sourceFactory with only dependency stubs; real collider and child skin are exercised in a Studio server",
	limitation = "Requires Studio Play with one test player; it does not prove full-course timing or multiplayer behavior",
})
local out=Instance.new("StringValue");out.Name="C17CrumbleResult";out.Value=result;out.Parent=ServerStorage
return result