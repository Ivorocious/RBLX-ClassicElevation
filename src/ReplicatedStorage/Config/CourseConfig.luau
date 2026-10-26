--!strict

local CourseConfig = {}

CourseConfig.CourseLibraryName = "CourseLibrary"
CourseConfig.CourseArchiveName = "CourseArchive"
CourseConfig.ActiveCourseModelName = "RaceCourse"
CourseConfig.ManualEditingAttribute = "ManualEditing"
CourseConfig.ActiveCourseId = "city_run"
CourseConfig.SelectionMode = "Fixed"
CourseConfig.RuntimeActiveCourseAttribute = "RuntimeActiveCourse"
CourseConfig.SourceCourseIdAttribute = "SourceCourseId"
CourseConfig.CourseInfoName = "CourseInfo"
CourseConfig.TemplateCourseName = "CourseTemplate"
CourseConfig.RetiredCourseIds = {classic_circuit = true, classic_point_to_point = true, classic_ascent_point_to_point = true}

CourseConfig.RequiredChildNames = {
	CourseInfo = "CourseInfo",
	Start = "Start",
	Checkpoints = "Checkpoints",
	Finish = "Finish",
	Obstacles = "Obstacles",
	FallZones = "FallZones",
	FallZoneMain = "FallZone_Main",
	RouteMarkers = "RouteMarkers",
	Decoration = "Decoration",
	Bounds = "Bounds",
}

CourseConfig.CourseInfoAttributes = {
	CourseId = "CourseId",
	DisplayName = "DisplayName",
	RaceFormat = "RaceFormat",
	LapCount = "LapCount",
	Enabled = "Enabled",
	Difficulty = "Difficulty",
	TargetNewPlayerTime = "TargetNewPlayerTime",
	TargetPracticedTime = "TargetPracticedTime",
	CheckpointCount = "CheckpointCount",
}

CourseConfig.DefaultCourseInfo = {
	CourseId = "unavailable",
	DisplayName = "Course preparing",
	RaceFormat = "PointToPoint",
	LapCount = 1,
	Enabled = false,
	Difficulty = "Unknown",
	TargetNewPlayerTime = nil,
	TargetPracticedTime = nil,
	CheckpointCount = nil,
}

return CourseConfig
