--!strict

local Check = {}

-- Run in Studio Edit mode with a fresh CourseService module and no visible course.
function Check.Run(courseService: any)
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	assert(not game:GetService("RunService"):IsRunning(), "Stop Play before this check")
	assert(workspace:FindFirstChild("RaceCourse") == nil, "Preserve the preview in ServerStorage first")
	local library = game:GetService("ServerStorage").CourseLibrary
	local authored = library.Course_ClassicAscentPointToPoint
	local originalCount = #authored:GetDescendants()
	courseService.Init()
	courseService.Start()
	assert(workspace:FindFirstChild("RaceCourse") == nil, "Startup must leave the lobby without a map")
	assert(courseService.GetCourseInfo("classic_ascent_point_to_point") ~= nil, "Course must remain discoverable")
	courseService.EnsureActiveCourse()
	local active = courseService.GetActiveCourse()
	assert(active and active ~= authored, "Selection must load a runtime clone")
	assert(active:GetAttribute("SourceCourseId") == "classic_ascent_point_to_point", "Wrong selected course")
	assert(#courseService.GetOrderedCheckpoints() == 19, "Checkpoint discovery failed")
	courseService.UnloadActiveCourse()
	courseService.UnloadActiveCourse()
	assert(workspace:FindFirstChild("RaceCourse") == nil, "Unload must restore the lobby-only state")
	assert(authored.Parent == library and #authored:GetDescendants() == originalCount, "Authored course changed")
	return "PASS: lobby startup, discovery, selected clone, 19 checkpoints, repeated unload, authored preservation"
end

return Check
