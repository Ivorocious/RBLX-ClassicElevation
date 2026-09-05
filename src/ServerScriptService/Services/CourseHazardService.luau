--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local HazardConfig = require(ReplicatedStorage.Config.HazardConfig)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)

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
}

local CourseHazardService = {}

local isInitialized = false
local isStarted = false
local raceService: any = nil
local courseService: any = nil
local playerRaceService: any = nil

local killParts: { BasePart } = {}
local fallingRocks: { FallingRockRecord } = {}
local crumbles: { CrumbleRecord } = {}
local touchConnections: { RBXScriptConnection } = {}
local overlapAccumulator = 0
local wasRaceActive = false

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

	if character == nil then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

local function killPlayerFromPart(part: BasePart)
	local player = getPlayerFromPart(part)

	if player == nil or not isActiveOfficialRacer(player) then
		return
	end

	local character = player.Character
	local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil

	if humanoid ~= nil and humanoid.Health > 0 then
		humanoid.Health = 0
	end
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
	record.nextPhaseAt = getServerTime() + HazardConfig.Crumble.WarningDuration
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
			record.nextPhaseAt = now + HazardConfig.Crumble.GoneDuration
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
		killPlayerFromPart(overlappingPart)
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
	table.insert(touchConnections, part.Touched:Connect(killPlayerFromPart))
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
			killPlayerFromPart(touchedPart)
		end
	end))
end

local function bindCrumble(part: BasePart)
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

	isInitialized = true
end

function CourseHazardService.BindActiveCourse()
	disconnectTouchConnections()
	restoreBoundHazards()
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
		warn("[CourseHazardService] Active course is unavailable.")
		return
	end

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
