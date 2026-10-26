local course=assert(workspace:FindFirstChild("Course_EggRush"),"Missing authored Egg Rush")
assert(game.PlaceId==85558151074819 and game.CreatorId==86069177,"Wrong experience")
assert(not game:GetService("RunService"):IsRunning(),"Inspect the authored Edit candidate")
assert(course:GetAttribute("EROwned")==true and course:GetAttribute("CourseId")=="egg_rush_circuit")
local report={candidate=course:GetAttribute("CandidateId"),phase=course:GetAttribute("Phase"),
 enabled=course.CourseInfo:GetAttribute("Enabled"),descendants=#course:GetDescendants(),
 visibleParts=0,meshParts=0,collidableParts=0,lethal={},references=0,artUnits=0,errors={}}
local function check(value,message)if not value then table.insert(report.errors,message)end end
check(course.Decoration:FindFirstChild("WorldFinished")~=nil,"Missing finished surroundings")
check(course.Decoration:FindFirstChild("ShellworksFinished")~=nil,"Missing finished Shellworks")
check(#course.Checkpoints:GetChildren()==4,"Expected exactly four checkpoints")
check(course.CourseInfo:GetAttribute("LapCount")==3,"Expected three laps")
for _,object in ipairs(course:GetDescendants())do
 if object:IsA("ObjectValue")then
  report.references+=1
  check(object.Value and object.Value:IsDescendantOf(course),"External or missing reference: "..object:GetFullName())
 end
 if object:GetAttribute("ERArt")==true then
  report.artUnits+=1
  for _,part in ipairs(object:GetDescendants())do
   if part:IsA("BasePart")then
    check(not part.CanCollide and not part.CanTouch,"Art changes physical blocking: "..part:GetFullName())
   end
  end
 end
 if not object:IsA("BasePart")then continue end
 if object:IsA("MeshPart")then report.meshParts+=1 end
 if object.Transparency<1 then report.visibleParts+=1 end
 if object.CanCollide then report.collidableParts+=1 end
 if object:GetAttribute("ERLethal")==true then
  table.insert(report.lethal,{path=object:GetFullName(),visible=object.Transparency<1,query=object.CanQuery,
   collision=object.CanCollide,size={object.Size.X,object.Size.Y,object.Size.Z},
   fidelity=object:IsA("MeshPart")and tostring(object.CollisionFidelity)or nil})
  check(object.Transparency<1 and object.CanQuery and not object.CanCollide,"Invalid visible contact: "..object:GetFullName())
 end
 if object.Name=="RoughEgg"or object.Name=="RoughTail"then
  check(object.Transparency==1 and not object.CanQuery and object:GetAttribute("ERLethal")==nil,"Rough contact still active")
 end
end
report.checkpoints={}
for _,p in ipairs(course.Checkpoints:GetChildren())do
 local cf=p:GetAttribute("RespawnCFrame")
 table.insert(report.checkpoints,{name=p.Name,respawn=typeof(cf)=="CFrame"and{cf.X,cf.Y,cf.Z}or nil})
 check(typeof(cf)=="CFrame","Missing recovery frame: "..p.Name)
end
local service=require(game.ServerScriptService.Services.CourseService)
report.courseErrors=service.ValidateCourseModel(course,true)
check(#report.courseErrors==0,"CourseService validation failed")
report.ok=#report.errors==0
return game.HttpService:JSONEncode(report)
