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

local function ensureCourseLibrary(): Folder
	local library = getCourseLibrary()

	if library ~= nil then
		return library
	end

	library = Instance.new("Folder")
	library.Name = CourseConfig.CourseLibraryName
	library.Parent = ServerStorage

	return library
end

local function ensureCourseArchive(): Folder
	local archive = ServerStorage:FindFirstChild(CourseConfig.CourseArchiveName)

	if archive ~= nil and archive:IsA("Folder") then
		return archive
	end

	archive = Instance.new("Folder")
	archive.Name = CourseConfig.CourseArchiveName
	archive.Parent = ServerStorage

	return archive
end

local function getCourseInfoInstance(courseModel: Model): Instance?
	return courseModel:FindFirstChild(CourseConfig.RequiredChildNames.CourseInfo)
end

local function ensureFolder(parent: Instance, folderName: string): Folder
	local existingFolder = parent:FindFirstChild(folderName)

	if existingFolder ~= nil and existingFolder:IsA("Folder") then
		return existingFolder
	end

	local folder = Instance.new("Folder")
	folder.Name = folderName
	folder.Parent = parent

	return folder
end

local function ensureCourseInfoInstance(courseModel: Model): Instance
	return ensureFolder(courseModel, CourseConfig.RequiredChildNames.CourseInfo)
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

local function countOrderedCheckpoints(courseModel: Model): number
	local checkpointsFolder = getFolder(courseModel, CourseConfig.RequiredChildNames.Checkpoints)

	return #discoverOrderedCheckpoints(checkpointsFolder)
end

local function writeCourseInfoAttributes(courseModel: Model, courseInfo: CourseInfo)
	local attributes = CourseConfig.CourseInfoAttributes
	local courseInfoInstance = ensureCourseInfoInstance(courseModel)

	courseInfoInstance:SetAttribute(attributes.CourseId, courseInfo.courseId)
	courseInfoInstance:SetAttribute(attributes.DisplayName, courseInfo.displayName)
	courseInfoInstance:SetAttribute(attributes.RaceFormat, courseInfo.raceFormat)
	courseInfoInstance:SetAttribute(attributes.LapCount, courseInfo.lapCount)
	courseInfoInstance:SetAttribute(attributes.Enabled, courseInfo.enabled)
	courseInfoInstance:SetAttribute(attributes.Difficulty, courseInfo.difficulty)
	courseInfoInstance:SetAttribute(attributes.TargetNewPlayerTime, courseInfo.targetNewPlayerTime)
	courseInfoInstance:SetAttribute(attributes.TargetPracticedTime, courseInfo.targetPracticedTime)
	courseInfoInstance:SetAttribute(attributes.CheckpointCount, courseInfo.checkpointCount)
end

local function getClassicPointToPointCourseInfo(courseModel: Model): CourseInfo
	local defaults = CourseConfig.DefaultCourseInfo

	return {
		courseId = CourseConfig.ActiveCourseId,
		displayName = "Classic Point-to-Point",
		raceFormat = RaceConstants.RaceFormat.PointToPoint,
		lapCount = 1,
		enabled = true,
		difficulty = defaults.Difficulty,
		targetNewPlayerTime = defaults.TargetNewPlayerTime,
		targetPracticedTime = defaults.TargetPracticedTime,
		checkpointCount = countOrderedCheckpoints(courseModel),
	}
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

local function ensureClassicPointToPointCourseFromFallback()
	local library = ensureCourseLibrary()
	local existingCourse = library:FindFirstChild(CourseConfig.ClassicPointToPointCourseName)

	if existingCourse ~= nil then
		if existingCourse:IsA("Model") then
			ensureFolder(existingCourse, CourseConfig.RequiredChildNames.Obstacles)
			ensureFolder(existingCourse, CourseConfig.RequiredChildNames.RouteMarkers)
			ensureFolder(existingCourse, CourseConfig.RequiredChildNames.Decoration)
			ensureFolder(existingCourse, CourseConfig.RequiredChildNames.Bounds)
			writeCourseInfoAttributes(existingCourse, getClassicPointToPointCourseInfo(existingCourse))
		else
			warn(
				string.format(
					"[CourseService] %s exists but is not a Model.",
					CourseConfig.ClassicPointToPointCourseName
				)
			)
		end

		return
	end

	local fallbackCourse = getFallbackActiveCourse()

	if fallbackCourse == nil then
		return
	end

	local courseClone = fallbackCourse:Clone()
	courseClone.Name = CourseConfig.ClassicPointToPointCourseName
	courseClone:SetAttribute(CourseConfig.RuntimeActiveCourseAttribute, nil)
	courseClone:SetAttribute(CourseConfig.SourceCourseIdAttribute, nil)

	ensureFolder(courseClone, CourseConfig.RequiredChildNames.Obstacles)
	ensureFolder(courseClone, CourseConfig.RequiredChildNames.RouteMarkers)
	ensureFolder(courseClone, CourseConfig.RequiredChildNames.Decoration)
	ensureFolder(courseClone, CourseConfig.RequiredChildNames.Bounds)
	writeCourseInfoAttributes(courseClone, getClassicPointToPointCourseInfo(courseClone))

	courseClone.Parent = library
	print("[CourseService] Created Course_ClassicPointToPoint from Workspace.RaceCourse fallback.")
end

local function isPlayableCourseRecord(record: CourseRecord): boolean
	if record.info.enabled ~= true then
		return false
	end

	local warnings = validateCourseModel(record.model, false)

	for _, warningMessage in ipairs(warnings) do
		warn(string.format("[CourseService] %s cannot be selected: %s", record.model.Name, warningMessage))
	end

	return #warnings == 0
end

local function selectActiveCourseRecord(): CourseRecord?
	if CourseConfig.SelectionMode ~= "Fixed" then
		warn(string.format("[CourseService] Unsupported selection mode %s; using Fixed.", tostring(CourseConfig.SelectionMode)))
	end

	local configuredRecord = discoveredCoursesById[CourseConfig.ActiveCourseId]

	if configuredRecord ~= nil and isPlayableCourseRecord(configuredRecord) then
		return configuredRecord
	end

	if configuredRecord == nil then
		warn(string.format("[CourseService] Configured course id %s was not found.", CourseConfig.ActiveCourseId))
	else
		warn(string.format("[CourseService] Configured course id %s is not playable.", CourseConfig.ActiveCourseId))
	end

	for _, courseId in ipairs(discoveredCourseOrder) do
		local record = discoveredCoursesById[courseId]

		if record ~= nil and isPlayableCourseRecord(record) then
			warn(string.format("[CourseService] Falling back to enabled course %s.", courseId))
			return record
		end
	end

	return nil
end

local function getUniqueArchiveName(baseName: string): string
	local archive = ensureCourseArchive()
	local archiveName = baseName
	local index = 1

	while archive:FindFirstChild(archiveName) ~= nil do
		index += 1
		archiveName = string.format("%s_%03d", baseName, index)
	end

	return archiveName
end

local function archiveExistingActiveCourse(activeCourse: Model)
	local archive = ensureCourseArchive()
	local archivedName = getUniqueArchiveName(activeCourse.Name .. "_Legacy")

	activeCourse.Name = archivedName
	activeCourse.Parent = archive
	print(string.format("[CourseService] Archived existing active course as ServerStorage.CourseArchive.%s.", archivedName))
end

local function spawnCourseRecord(record: CourseRecord): boolean
	local courseClone = record.model:Clone()
	courseClone.Name = CourseConfig.ActiveCourseModelName
	courseClone:SetAttribute(CourseConfig.RuntimeActiveCourseAttribute, true)
	courseClone:SetAttribute(CourseConfig.SourceCourseIdAttribute, record.info.courseId)

	local warnings = validateCourseModel(courseClone, false)

	if #warnings > 0 then
		for _, warningMessage in ipairs(warnings) do
			warn(string.format("[CourseService] Could not spawn %s: %s", record.model.Name, warningMessage))
		end

		courseClone:Destroy()
		return false
	end

	local existingActiveCourse = getFallbackActiveCourse()

	if existingActiveCourse ~= nil then
		if existingActiveCourse:GetAttribute(CourseConfig.RuntimeActiveCourseAttribute) == true then
			existingActiveCourse:Destroy()
		else
			archiveExistingActiveCourse(existingActiveCourse)
		end
	end

	courseClone.Parent = Workspace
	activeCourseInfo = readCourseInfo(courseClone)

	print(
		string.format(
			"[CourseService] Spawned active course %s from %s.",
			activeCourseInfo.displayName,
			record.model.Name
		)
	)

	return true
end

local function ensureActiveCourse()
	ensureClassicPointToPointCourseFromFallback()
	discoverCourseLibrary()

	local selectedRecord = selectActiveCourseRecord()

	if selectedRecord ~= nil and spawnCourseRecord(selectedRecord) then
		return
	end

	local fallbackCourse = getFallbackActiveCourse()

	if fallbackCourse == nil then
		warn("[CourseService] No active course could be spawned and no Workspace.RaceCourse fallback exists.")
		return
	end

	local warnings = validateCourseModel(fallbackCourse, false)

	for _, warningMessage in ipairs(warnings) do
		warn(string.format("[CourseService] Active fallback %s: %s", fallbackCourse.Name, warningMessage))
	end

	activeCourseInfo = readCourseInfo(fallbackCourse)
	print(string.format("[CourseService] Using active course fallback: %s.", activeCourseInfo.displayName))
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
	ensureActiveCourse()
end

function CourseService.DiscoverCourses()
	discoverCourseLibrary()
end

function CourseService.EnsureActiveCourse()
	ensureActiveCourse()
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
