--!nonstrict
assert(game:GetService("RunService"):IsStudio() and game.PlaceId == 85558151074819)
assert(game:GetService("StudioTestService"):GetTestArgs().tag == "EggRush_P2_Baseline")
local template = game.ServerStorage.CourseLibrary:WaitForChild("Course_EggRush")
assert(template:GetAttribute("CandidateId") == "ER_P1_R01" and template:GetAttribute("PacingRevision") == "T01")
-- This deliberate inspection selection cannot establish the normal entry path.
template.CourseInfo:SetAttribute("Enabled", true)
require(game.ServerScriptService.Services.CourseService).DiscoverCourses()
require(game.ServerStorage.CourseBuilders.EggRush.RestartR01.Checks).Start()
