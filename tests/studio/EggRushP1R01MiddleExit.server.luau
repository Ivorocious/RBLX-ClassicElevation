assert(game:GetService("RunService"):IsStudio())
local storage=game.ServerStorage
local courseService=require(game.ServerScriptService.Services.CourseService)
local checkpointService=require(game.ServerScriptService.Services.CheckpointService)
local course=assert(courseService.GetActiveCourse())
assert(course:GetAttribute("CandidateId")=="ER_P1_R01" and course:GetAttribute("SampleRevision")==2)
local player=game.Players:GetPlayers()[1]
assert(checkpointService.SetInspectionCheckpointForStudio(player,2))
local all=require(storage.CourseBuilders.EggRush.RestartR01.Sample).Points(course,"Normal")
local points={}
for i=9,#all do table.insert(points,all[i])end
assert(points[1].part.Name=="Shell_MiddleWait" and points[#points].part.Name=="Shell_ExitWait")
local result=Instance.new("StringValue");result.Name="R01MiddleExit";result.Parent=storage
local report=require(storage.CourseBuilders.EggRush.NativeTraversal).Run(course,player,points,{placeAtStart=true})
report.setup="One initial placement at MiddleWait; ordinary movement across the revised final pair and exit"
report.sampleRevision=2
result.Value=game.HttpService:JSONEncode(report)
