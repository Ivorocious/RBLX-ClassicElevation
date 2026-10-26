--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

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
local inspectionMode = false
local studioCourseId: string? = nil
local discoveredCoursesById: { [string]: CourseRecord } = {}
local discoveredCourseOrder: { string } = {}
local activeCourseInfo: CourseInfo? = nil
local lastDiscoveryReport: string? = nil

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
	local archiveRoot = ServerStorage:FindFirstChild("Archive")
	if not archiveRoot then archiveRoot = Instance.new("Folder"); archiveRoot.Name = "Archive"; archiveRoot.Parent = ServerStorage end
	local archive = archiveRoot:FindFirstChild(CourseConfig.CourseArchiveName)

	if archive ~= nil and archive:IsA("Folder") then
		return archive
	end

	archive = Instance.new("Folder")
	archive.Name = CourseConfig.CourseArchiveName
	archive.Parent = archiveRoot

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

local function discoverFallZones(fallZonesFolder: Folder?): { BasePart }
	local fallZones: { BasePart } = {}

	if fallZonesFolder ~= nil then
		for _, descendant in ipairs(fallZonesFolder:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(fallZones, descendant)
			end
		end
	end

	return fallZones
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
	elseif #discoverFallZones(fallZonesFolder) == 0 then
		addWarning(warnings, "FallZones must contain at least one BasePart.")
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
	local duplicateCourseIds: { [string]: boolean } = {}
	local reportWarnings: { string } = {}

	-- The tournament rediscovers on every update, so repeat the log only when the result changes.
	local function report(summary: string)
		local signature = table.concat(reportWarnings, "\n") .. "\n" .. summary
		if signature == lastDiscoveryReport then
			return
		end
		lastDiscoveryReport = signature
		for _, warningMessage in ipairs(reportWarnings) do
			warn(warningMessage)
		end
		print(summary)
	end

	local library = getCourseLibrary()

	if library == nil then
		report("[CourseService] ServerStorage.CourseLibrary was not found; using Workspace.RaceCourse fallback.")
		return
	end

	for _, child in ipairs(library:GetChildren()) do
		if child:IsA("Model") then
			local info = readCourseInfo(child)
			if CourseConfig.RetiredCourseIds[info.courseId] then continue end
			if discoveredCoursesById[info.courseId] ~= nil or duplicateCourseIds[info.courseId] then
				duplicateCourseIds[info.courseId] = true
				discoveredCoursesById[info.courseId] = nil
				table.insert(reportWarnings, string.format("[CourseService] Duplicate course ID %s; all copies are excluded until reconciled.", info.courseId))
				continue
			end
			local warnings = validateCourseModel(child, true)

			discoveredCoursesById[info.courseId] = {
				model = child,
				info = info,
				validationWarnings = warnings,
			}

			for _, warningMessage in ipairs(warnings) do
				table.insert(reportWarnings, string.format("[CourseService] %s: %s", child.Name, warningMessage))
			end
		end
	end

	for courseId in pairs(discoveredCoursesById) do
		table.insert(discoveredCourseOrder, courseId)
	end
	table.sort(discoveredCourseOrder)
	report(string.format("[CourseService] Discovered %d course model(s).", #discoveredCourseOrder))
end

local function getFallbackActiveCourse(): Model?
	local activeCourse = Workspace:FindFirstChild(CourseConfig.ActiveCourseModelName)

	if activeCourse ~= nil and activeCourse:IsA("Model") and not CourseConfig.RetiredCourseIds[readCourseInfo(activeCourse).courseId] then
		return activeCourse
	end

	return nil
end

local function isPlayableCourseRecord(record: CourseRecord, allowStudioDevelopment: boolean?): boolean
	if CourseConfig.RetiredCourseIds[record.info.courseId] then return false end
	local studioDevelopment = allowStudioDevelopment == true and RunService:IsStudio()
		and record.info.courseId == "stud_garden_v2" and record.model:GetAttribute("SGV2Owned") == true
	if record.info.enabled ~= true and not studioDevelopment then
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

	local configuredRecord = discoveredCoursesById[studioCourseId or CourseConfig.ActiveCourseId]

	if configuredRecord ~= nil and isPlayableCourseRecord(configuredRecord, studioCourseId ~= nil) then
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
	print(string.format("[CourseService] Archived existing active course as %s.", activeCourse:GetFullName()))
end

local function spawnCourseRecord(record: CourseRecord, isCurrent: (() -> boolean)?): boolean
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

	if isCurrent and not isCurrent() then courseClone:Destroy();return false end
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

local function prepareCourseLibrary()
	local eggRush = Workspace:FindFirstChild("Course_EggRush")
	if RunService:IsRunning() and eggRush ~= nil then
		assert(eggRush:IsA("Model") and eggRush:GetAttribute("ManualEditing") == true
			and eggRush:GetAttribute("EROwned") == true, "Preserve the Egg Rush editing model")
		assert(readCourseInfo(eggRush).courseId == "egg_rush_circuit", "Unexpected Egg Rush identity")
		local warnings = validateCourseModel(eggRush, true)
		assert(#warnings == 0, "Egg Rush is incomplete: " .. table.concat(warnings, "; "))
		local library = ensureCourseLibrary()
		local previous = library:FindFirstChild(eggRush.Name)
		if previous ~= nil and previous ~= eggRush then
			previous.Name = getUniqueArchiveName("EggRush_BeforeEditing")
			previous.Parent = ensureCourseArchive()
		end
		eggRush.Parent = library
	end
	local studGarden = Workspace:FindFirstChild("Course_StudGarden")
	if RunService:IsStudio() and RunService:IsRunning() and studGarden ~= nil then
		assert(studGarden:IsA("Model") and studGarden:GetAttribute("ManualEditing") == true
			and studGarden:GetAttribute("SGV2Owned") == true, "Preserve the Stud Garden editing model")
		local warnings = validateCourseModel(studGarden, true)
		assert(#warnings == 0, "Stud Garden is incomplete: " .. table.concat(warnings, "; "))
		assert(readCourseInfo(studGarden).courseId == "stud_garden_v2", "Unexpected Stud Garden identity")
		local library = ensureCourseLibrary()
		assert(library:FindFirstChild(studGarden.Name) == nil, "Resolve the existing Stud Garden template before replacing it")
		studGarden.Parent = library
	end
	local shipwreck = Workspace:FindFirstChild("Course_ShipwreckCove")
	if shipwreck == nil then
		local library = getCourseLibrary()
		local storedShipwreck = library and library:FindFirstChild("Course_ShipwreckCove")
		if storedShipwreck and storedShipwreck:IsA("Folder") then
			shipwreck = storedShipwreck
		end
	end
	if RunService:IsRunning() and shipwreck then
		if shipwreck:IsA("Folder") and shipwreck:GetAttribute("EditablePiecesVersion") == 1 then
			shipwreck = require(ServerStorage.CourseBuilders.ShipwreckCove.Authoring).ToRuntime(shipwreck)
		end
		assert(shipwreck:IsA("Model") and shipwreck:GetAttribute("ManualEditing") == true, "Preserve Shipwreck editing model")
		local warnings = validateCourseModel(shipwreck, true)
		assert(#warnings == 0, "Shipwreck candidate is incomplete: " .. table.concat(warnings, "; "))
		local library = ensureCourseLibrary()
		local previous = library:FindFirstChild(shipwreck.Name)
		if previous and previous ~= shipwreck then
			previous.Name = getUniqueArchiveName("Shipwreck_BeforeEditing")
			previous.Parent = ensureCourseArchive()
		end
		shipwreck.Parent = library
	end
	local cityRun = Workspace:FindFirstChild("Course_CityRun")
	if RunService:IsRunning() and cityRun ~= nil then
		assert(cityRun:IsA("Model") and cityRun:GetAttribute("ManualEditing") == true,
			"The visible City Run must be marked ManualEditing before Play")
		local warnings = validateCourseModel(cityRun, true)
		assert(#warnings == 0, "City Run is incomplete: " .. table.concat(warnings, "; "))
		assert(readCourseInfo(cityRun).courseId == "city_run", "Unexpected City Run identity")
		local library = ensureCourseLibrary()
		local previous = library:FindFirstChild("Course_CityRun")
		if previous ~= nil then
			previous.Name = getUniqueArchiveName("CityRun_BeforeEditing")
			previous.Parent = ensureCourseArchive()
		end
		cityRun.Parent = library
	end
	local moonlit = Workspace:FindFirstChild("Course_MoonlitCitadel")
	if RunService:IsRunning() and moonlit ~= nil then
		assert(moonlit:IsA("Model") and moonlit:GetAttribute(CourseConfig.ManualEditingAttribute) == true,
			"The visible Moonlit Citadel must be marked ManualEditing before Play")
		local warnings = validateCourseModel(moonlit, true)
		assert(#warnings == 0, "Moonlit Citadel is incomplete: " .. table.concat(warnings, "; "))
		assert(readCourseInfo(moonlit).courseId == "moonlit_citadel", "Unexpected Moonlit Citadel identity")
		local library = ensureCourseLibrary()
		local previous = library:FindFirstChild(moonlit.Name)
		if previous ~= nil and previous ~= moonlit then
			previous.Name = getUniqueArchiveName("MoonlitCitadel_BeforeEditing")
			previous.Parent = ensureCourseArchive()
		end
		moonlit.Parent = library
	end
	discoverCourseLibrary()
end

local function ensureActiveCourse()
	prepareCourseLibrary()

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
	inspectionMode = false
	prepareCourseLibrary()
	if not inspectionMode then CourseService.UnloadActiveCourse() end
end

function CourseService.UnloadActiveCourse()
	if inspectionMode then return end
	local course = getFallbackActiveCourse()
	if course ~= nil then
		if course:GetAttribute(CourseConfig.RuntimeActiveCourseAttribute) == true then
			course:Destroy()
		else
			archiveExistingActiveCourse(course)
		end
	end
	activeCourseInfo = nil
end

function CourseService.CanSelectCourseForStudio(courseId: string): boolean
    if not RunService:IsStudio() then return false end
    local record = discoveredCoursesById[courseId]
    return record ~= nil and isPlayableCourseRecord(record, true)
end

function CourseService.SelectCourseForStudio(courseId: string): boolean
    if not CourseService.CanSelectCourseForStudio(courseId) then return false end
    studioCourseId = courseId
    return true
end

function CourseService.GetSelectedCourseId(): string
    return studioCourseId or CourseConfig.ActiveCourseId
end

function CourseService.DiscoverCourses()
	discoverCourseLibrary()
end

function CourseService.EnsureActiveCourse()
	if inspectionMode then return end
	ensureActiveCourse()
end

function CourseService.IsInspectionMode(): boolean
	return inspectionMode
end

function CourseService.GetDiscoveredCourseIds(): { string }
	local courseIds = {}

	for index, courseId in ipairs(discoveredCourseOrder) do
		courseIds[index] = courseId
	end

	return courseIds
end

function CourseService.GetEligibleCourses(): {CourseInfo}
	discoverCourseLibrary()
	local result = {}
	for _, id in discoveredCourseOrder do
		local record = discoveredCoursesById[id]
		if record.model.Parent == getCourseLibrary() and isPlayableCourseRecord(record) then
			record.info = readCourseInfo(record.model)
			if record.info.enabled then table.insert(result,table.clone(record.info)) end
		end
	end
	return result
end

function CourseService.LoadTournamentCourse(courseId: string,isCurrent: (() -> boolean)?): boolean
	if inspectionMode then return false end
	prepareCourseLibrary()
	local record = discoveredCoursesById[courseId]
	if not record or not isPlayableCourseRecord(record) then return false end
	return spawnCourseRecord(record,isCurrent) and CourseService.GetActiveCourseId() == courseId
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

function CourseService.GetFallZones(): { BasePart }
	return discoverFallZones(CourseService.GetFallZonesFolder())
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
