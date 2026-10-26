--!strict

local Check = {}

-- Run in Studio Edit mode with a fresh CourseService module and no visible course.
-- Uses the configured active course, so it follows CourseConfig.ActiveCourseId.
function Check.Run(courseService: any)
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	assert(not game:GetService("RunService"):IsRunning(), "Stop Play before this check")
	assert(workspace:FindFirstChild("RaceCourse") == nil, "Preserve the preview in ServerStorage first")
	local courseId = require(game:GetService("ReplicatedStorage").Config.CourseConfig).ActiveCourseId
	local library = game:GetService("ServerStorage").CourseLibrary
	local authored: Model? = nil
	for _, child in library:GetChildren() do
		local info = child:FindFirstChild("CourseInfo")
		if child:IsA("Model") and info and info:GetAttribute("CourseId") == courseId then authored = child end
	end
	assert(authored, "The configured course must be in CourseLibrary")
	local originalCount = #authored:GetDescendants()
	courseService.Init()
	courseService.Start()
	assert(workspace:FindFirstChild("RaceCourse") == nil, "Startup must leave the lobby without a map")
	assert(courseService.GetCourseInfo(courseId) ~= nil, "Course must remain discoverable")
	courseService.EnsureActiveCourse()
	local active = courseService.GetActiveCourse()
	assert(active and active ~= authored, "Selection must load a runtime clone")
	assert(active:GetAttribute("SourceCourseId") == courseId, "Wrong selected course")
	local checkpointCount = #courseService.GetOrderedCheckpoints()
	assert(checkpointCount > 0, "Checkpoint discovery failed")
	courseService.UnloadActiveCourse()
	courseService.UnloadActiveCourse()
	assert(workspace:FindFirstChild("RaceCourse") == nil, "Unload must restore the lobby-only state")
	assert(authored.Parent == library and #authored:GetDescendants() == originalCount, "Authored course changed")
	return string.format("PASS: %s lobby startup, discovery, selected clone, %d checkpoints, repeated unload, authored preservation", courseId, checkpointCount)
end

return Check
