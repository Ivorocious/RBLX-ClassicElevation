--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local CheckpointConfig = require(ReplicatedStorage.Config.CheckpointConfig)
local CourseConfig = require(ReplicatedStorage.Config.CourseConfig)
local RaceConstants = require(ReplicatedStorage.Shared.RaceConstants)
local RaceTypes = require(ReplicatedStorage.Shared.RaceTypes)

type CourseInfo = RaceTypes.CourseInfo
type RaceFormat = RaceTypes.RaceFormat

type ServiceContext = {
	Services: { [string]: any },
}

type CourseRecord = {
	model: Model,
	info: CourseInfo,
	validationWarnings: { string },
}

type OrderedCheckpoint = {
	index: number,
	name: string,
	part: BasePart,
}

local CourseService = {}

local isInitialized = false
local isStarted = false
local discoveredCoursesById: { [string]: CourseRecord } = {}
local discoveredCourseOrder: { string } = {}
local activeCourseInfo: CourseInfo? = nil

local function getCourseLibrary(): Folder?
	local library = ServerStorage:FindFirstChild(CourseConfig.CourseLibraryName)

	if library ~= nil and library:IsA("Folder") then
		return library
	end

	return nil
end

local function getCourseInfoInstance(courseModel: Model): Instance?
	return courseModel:FindFirstChild(CourseConfig.RequiredChildNames.CourseInfo)
end

local function getStringAttribute(instance: Instance?, attributeName: string, fallback: string): string
	if instance == nil then
		return fallback
	end

	local value = instance:GetAttribute(attributeName)

	if typeof(value) == "string" and value ~= "" then
		return value
	end

	return fallback
end

local function getBooleanAttribute(instance: Instance?, attributeName: string, fallback: boolean): boolean
	if instance == nil then
		return fallback
	end

	local value = instance:GetAttribute(attributeName)

	if typeof(value) == "boolean" then
		return value
	end

	return fallback
end

local function getNumberAttribute(instance: Instance?, attributeName: string, fallback: number?): number?
	if instance == nil then
		return fallback
	end

	local value = instance:GetAttribute(attributeName)

	if typeof(value) == "number" then
		return value
	end

	return fallback
end

local function normalizeRaceFormat(value: string): RaceFormat
	if value == RaceConstants.RaceFormat.LapBased then
		return RaceConstants.RaceFormat.LapBased
	end

	return RaceConstants.RaceFormat.PointToPoint
end

local function readCourseInfo(courseModel: Model): CourseInfo
	local attributes = CourseConfig.CourseInfoAttributes
	local defaults = CourseConfig.DefaultCourseInfo
	local courseInfoInstance = getCourseInfoInstance(courseModel)
	local lapCount = math.max(1, getNumberAttribute(courseInfoInstance, attributes.LapCount, defaults.LapCount) or 1)

	return {
		courseId = getStringAttribute(courseInfoInstance, attributes.CourseId, defaults.CourseId),
		displayName = getStringAttribute(courseInfoInstance, attributes.DisplayName, defaults.DisplayName),
		raceFormat = normalizeRaceFormat(getStringAttribute(courseInfoInstance, attributes.RaceFormat, defaults.RaceFormat)),
		lapCount = lapCount,
		enabled = getBooleanAttribute(courseInfoInstance, attributes.Enabled, defaults.Enabled),
		difficulty = getStringAttribute(courseInfoInstance, attributes.Difficulty, defaults.Difficulty),
		targetNewPlayerTime = getNumberAttribute(courseInfoInstance, attributes.TargetNewPlayerTime, defaults.TargetNewPlayerTime),
		targetPracticedTime = getNumberAttribute(
			courseInfoInstance,
			attributes.TargetPracticedTime,
			defaults.TargetPracticedTime
		),
		checkpointCount = getNumberAttribute(courseInfoInstance, attributes.CheckpointCount, defaults.CheckpointCount),
	}
end

local function getBasePart(parent: Instance?, childName: string): BasePart?
	if parent == nil then
		return nil
	end

	local child = parent:FindFirstChild(childName)

	if child ~= nil and child:IsA("BasePart") then
		return child
	end

	return nil
end

local function getFolder(parent: Instance?, childName: string): Folder?
	if parent == nil then
		return nil
	end

	local child = parent:FindFirstChild(childName)

	if child ~= nil and child:IsA("Folder") then
		return child
	end

	return nil
end

local function parseCheckpointIndex(checkpointName: string): number?
	local prefix = CheckpointConfig.CheckpointNamePrefix
	local padding = CheckpointConfig.CheckpointNumberPadding
	local digits = string.match(checkpointName, "^" .. prefix .. "_(%d+)$")

	if digits == nil or #digits ~= padding then
		return nil
	end

	return tonumber(digits)
end

local function discoverOrderedCheckpoints(checkpointsFolder: Folder?): { OrderedCheckpoint }
	local discoveredCheckpoints = {}

	if checkpointsFolder == nil then
		return discoveredCheckpoints
	end

	for _, child in ipairs(checkpointsFolder:GetChildren()) do
		if child:IsA("BasePart") then
			local checkpointIndex = parseCheckpointIndex(child.Name)

			if checkpointIndex ~= nil then
				table.insert(discoveredCheckpoints, {
					index = checkpointIndex,
					name = child.Name,
					part = child,
				})
			end
		end
	end

	table.sort(discoveredCheckpoints, function(left, right)
		return left.index < right.index
	end)

	return discoveredCheckpoints
end

local function addWarning(warnings: { string }, message: string)
	table.insert(warnings, message)
end

local function validateCheckpointNames(checkpointsFolder: Folder?, warnings: { string })
	if checkpointsFolder == nil then
		return
	end

	local validCheckpointCount = 0

	for _, child in ipairs(checkpointsFolder:GetChildren()) do
		if child:IsA("BasePart") and parseCheckpointIndex(child.Name) ~= nil then
			validCheckpointCount += 1
		end
	end

	if validCheckpointCount == 0 then
		addWarning(warnings, "Checkpoints must contain at least one BasePart named Checkpoint_###.")
	end
end

local function validateCourseModel(courseModel: Model, requireAuthoringFolders: boolean): { string }
	local childNames = CourseConfig.RequiredChildNames
	local warnings = {}

	if requireAuthoringFolders and courseModel:FindFirstChild(childNames.CourseInfo) == nil then
		addWarning(warnings, "CourseInfo is missing.")
	end

	if getBasePart(courseModel, childNames.Start) == nil then
		addWarning(warnings, "Start must be a BasePart.")
	end

	local checkpointsFolder = getFolder(courseModel, childNames.Checkpoints)

	if checkpointsFolder == nil then
		addWarning(warnings, "Checkpoints must be a Folder.")
	else
		validateCheckpointNames(checkpointsFolder, warnings)
	end

	if getBasePart(courseModel, childNames.Finish) == nil then
		addWarning(warnings, "Finish must be a BasePart.")
	end

	if requireAuthoringFolders and getFolder(courseModel, childNames.Obstacles) == nil then
		addWarning(warnings, "Obstacles must be a Folder.")
	end

	local fallZonesFolder = getFolder(courseModel, childNames.FallZones)

	if fallZonesFolder == nil then
		addWarning(warnings, "FallZones must be a Folder.")
	elseif getBasePart(fallZonesFolder, childNames.FallZoneMain) == nil then
		addWarning(warnings, "FallZones.FallZone_Main must be a BasePart.")
	end

	if requireAuthoringFolders and getFolder(courseModel, childNames.RouteMarkers) == nil then
		addWarning(warnings, "RouteMarkers must be a Folder.")
	end

	if requireAuthoringFolders and getFolder(courseModel, childNames.Decoration) == nil then
		addWarning(warnings, "Decoration must be a Folder.")
	end

	if requireAuthoringFolders and getFolder(courseModel, childNames.Bounds) == nil then
		addWarning(warnings, "Bounds must be a Folder.")
	end

	return warnings
end

local function discoverCourseLibrary()
	discoveredCoursesById = {}
	discoveredCourseOrder = {}

	local library = getCourseLibrary()

	if library == nil then
		print("[CourseService] ServerStorage.CourseLibrary was not found; using Workspace.RaceCourse fallback.")
		return
	end

	for _, child in ipairs(library:GetChildren()) do
		if child:IsA("Model") then
			local info = readCourseInfo(child)
			local warnings = validateCourseModel(child, true)

			discoveredCoursesById[info.courseId] = {
				model = child,
				info = info,
				validationWarnings = warnings,
			}
			table.insert(discoveredCourseOrder, info.courseId)

			for _, warningMessage in ipairs(warnings) do
				warn(string.format("[CourseService] %s: %s", child.Name, warningMessage))
			end
		end
	end

	table.sort(discoveredCourseOrder)
	print(string.format("[CourseService] Discovered %d course model(s).", #discoveredCourseOrder))
end

local function getFallbackActiveCourse(): Model?
	local activeCourse = Workspace:FindFirstChild(CourseConfig.ActiveCourseModelName)

	if activeCourse ~= nil and activeCourse:IsA("Model") then
		return activeCourse
	end

	return nil
end

local function getActiveCourseInfo(): CourseInfo
	local activeCourse = getFallbackActiveCourse()

	if activeCourse ~= nil then
		activeCourseInfo = readCourseInfo(activeCourse)
	elseif activeCourseInfo == nil then
		activeCourseInfo = {
			courseId = CourseConfig.DefaultCourseInfo.CourseId,
			displayName = CourseConfig.DefaultCourseInfo.DisplayName,
			raceFormat = normalizeRaceFormat(CourseConfig.DefaultCourseInfo.RaceFormat),
			lapCount = CourseConfig.DefaultCourseInfo.LapCount,
			enabled = CourseConfig.DefaultCourseInfo.Enabled,
			difficulty = CourseConfig.DefaultCourseInfo.Difficulty,
			targetNewPlayerTime = CourseConfig.DefaultCourseInfo.TargetNewPlayerTime,
			targetPracticedTime = CourseConfig.DefaultCourseInfo.TargetPracticedTime,
			checkpointCount = CourseConfig.DefaultCourseInfo.CheckpointCount,
		}
	end

	return activeCourseInfo :: CourseInfo
end

function CourseService.Init(_context: ServiceContext?)
	if isInitialized then
		return
	end

	isInitialized = true
end

function CourseService.Start(_context: ServiceContext?)
	if not isInitialized then
		warn("[CourseService] Start called before Init.")
		return
	end

	if isStarted then
		return
	end

	isStarted = true
	discoverCourseLibrary()

	local activeCourse = getFallbackActiveCourse()

	if activeCourse == nil then
		warn("[CourseService] Workspace.RaceCourse fallback was not found.")
		return
	end

	local warnings = validateCourseModel(activeCourse, false)

	for _, warningMessage in ipairs(warnings) do
		warn(string.format("[CourseService] Active fallback %s: %s", activeCourse.Name, warningMessage))
	end

	activeCourseInfo = readCourseInfo(activeCourse)
	print(string.format("[CourseService] Active course fallback: %s.", activeCourseInfo.displayName))
end

function CourseService.DiscoverCourses()
	discoverCourseLibrary()
end

function CourseService.GetDiscoveredCourseIds(): { string }
	local courseIds = {}

	for index, courseId in ipairs(discoveredCourseOrder) do
		courseIds[index] = courseId
	end

	return courseIds
end

function CourseService.GetCourseInfo(courseId: string): CourseInfo?
	local record = discoveredCoursesById[courseId]

	if record == nil then
		return nil
	end

	return record.info
end

function CourseService.GetActiveCourse(): Model?
	return getFallbackActiveCourse()
end

function CourseService.GetActiveCourseModel(): Model?
	return CourseService.GetActiveCourse()
end

function CourseService.GetActiveCourseInfo(): CourseInfo
	return getActiveCourseInfo()
end

function CourseService.GetActiveCourseId(): string
	return CourseService.GetActiveCourseInfo().courseId
end

function CourseService.GetActiveCourseDisplayName(): string
	return CourseService.GetActiveCourseInfo().displayName
end

function CourseService.GetStartPart(): BasePart?
	return getBasePart(CourseService.GetActiveCourse(), CourseConfig.RequiredChildNames.Start)
end

function CourseService.GetFinishPart(): BasePart?
	return getBasePart(CourseService.GetActiveCourse(), CourseConfig.RequiredChildNames.Finish)
end

function CourseService.GetCheckpointsFolder(): Folder?
	return getFolder(CourseService.GetActiveCourse(), CourseConfig.RequiredChildNames.Checkpoints)
end

function CourseService.GetOrderedCheckpoints(): { OrderedCheckpoint }
	return discoverOrderedCheckpoints(CourseService.GetCheckpointsFolder())
end

function CourseService.GetFallZonesFolder(): Folder?
	return getFolder(CourseService.GetActiveCourse(), CourseConfig.RequiredChildNames.FallZones)
end

function CourseService.GetFallZoneMain(): BasePart?
	local fallZonesFolder = CourseService.GetFallZonesFolder()

	return getBasePart(fallZonesFolder, CourseConfig.RequiredChildNames.FallZoneMain)
end

function CourseService.GetMainFallZone(): BasePart?
	return CourseService.GetFallZoneMain()
end

function CourseService.GetRaceFormat(): RaceFormat
	return CourseService.GetActiveCourseInfo().raceFormat
end

function CourseService.GetLapCount(): number
	return CourseService.GetActiveCourseInfo().lapCount
end

function CourseService.ValidateCourseModel(courseModel: Model, requireAuthoringFolders: boolean?): { string }
	return validateCourseModel(courseModel, requireAuthoringFolders == true)
end

return CourseService
