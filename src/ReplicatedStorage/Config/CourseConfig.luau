--!strict

local CourseConfig = {}

CourseConfig.CourseLibraryName = "CourseLibrary"
CourseConfig.CourseArchiveName = "CourseArchive"
CourseConfig.ActiveCourseModelName = "RaceCourse"
CourseConfig.ActiveCourseId = "classic_point_to_point"
CourseConfig.SelectionMode = "Fixed"
CourseConfig.RuntimeActiveCourseAttribute = "RuntimeActiveCourse"
CourseConfig.SourceCourseIdAttribute = "SourceCourseId"
CourseConfig.CourseInfoName = "CourseInfo"
CourseConfig.TemplateCourseName = "CourseTemplate"
CourseConfig.ClassicPointToPointCourseName = "Course_ClassicPointToPoint"
CourseConfig.ClassicCircuitCourseName = "Course_ClassicCircuit"
CourseConfig.ClassicCircuitCourseId = "classic_circuit"

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
	CourseId = "classic_point_to_point",
	DisplayName = "Classic Point-to-Point",
	RaceFormat = "PointToPoint",
	LapCount = 1,
	Enabled = true,
	Difficulty = "MVP",
	TargetNewPlayerTime = 180,
	TargetPracticedTime = 90,
	CheckpointCount = nil,
}

return CourseConfig
