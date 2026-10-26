assert(game:GetService("RunService"):IsStudio())
local template=game.ServerStorage.CourseLibrary:WaitForChild("Course_EggRush")
assert(template:GetAttribute("CandidateId")=="ER_P1_R01" and template:GetAttribute("Phase")==1)
-- Enable only the owned test-server copy; the authoring template stays disabled.
template.CourseInfo:SetAttribute("Enabled",true)
require(game.ServerScriptService.Services.CourseService).DiscoverCourses()
require(game.ServerStorage.CourseBuilders.EggRush.RestartR01.Checks).Start()
