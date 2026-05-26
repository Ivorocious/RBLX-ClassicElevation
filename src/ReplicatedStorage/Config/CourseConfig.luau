--!strict

local CourseConfig = {}

CourseConfig.CourseLibraryName = "CourseLibrary"
CourseConfig.ActiveCourseModelName = "RaceCourse"
CourseConfig.CourseInfoName = "CourseInfo"
CourseConfig.TemplateCourseName = "CourseTemplate"

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
	CourseId = "MVP_PointToPoint_01",
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
