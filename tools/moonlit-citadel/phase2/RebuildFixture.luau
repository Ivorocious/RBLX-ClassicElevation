--!nonstrict
assert(game:GetService('RunService'):IsStudio() and not game:GetService('RunService'):IsRunning())
assert(game.PlaceId == 0 and game.GameId == 0, 'Owned unpublished fixture only')
local storage = game:GetService('ServerStorage')
local config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local recovery = assert(storage:FindFirstChild('MoonlitPhase2FixtureRecovery'))
local builders = storage.CourseBuilders
local snapshot = builders.MoonlitCitadelCourse:Clone()
snapshot.Name = config.CandidateId .. '_BuilderSnapshot'
assert(not builders:FindFirstChild(snapshot.Name), 'Keep earlier builder snapshots')
snapshot.Parent = builders
local course = require(snapshot.RouteBuilder).Build()
local warnings = require(game.ServerScriptService.Services.CourseService).ValidateCourseModel(course, true)
assert(#warnings == 0, table.concat(warnings, '; '))
local previous = storage.CourseLibrary:FindFirstChild(config.CourseName)
if previous then
    previous.Name = (previous:GetAttribute('CandidateId') or 'Previous') .. '_Course'
    assert(not recovery:FindFirstChild(previous.Name), 'Preserve earlier native candidate')
    previous.Parent = recovery
end
course.Parent = storage.CourseLibrary
return {candidate=course:GetAttribute('CandidateId'), descendants=#course:GetDescendants(), warnings=warnings}
