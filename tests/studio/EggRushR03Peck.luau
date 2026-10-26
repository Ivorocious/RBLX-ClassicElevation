--!nonstrict
local Test={}
function Test.Run()
 assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsRunning())
 local course=game.ServerStorage.CourseLibrary.Course_EggRush:Clone()
 assert(course:GetAttribute("CandidateId")=="ER_P2_R03_C04")
 course.Name="R03_PeckContactFixture";course:PivotTo(course:GetPivot()+Vector3.new(0,0,2000));course.Parent=workspace
 local m=course.Obstacles.Mechanisms.GuardianPeck
 local frames,colors={},{}
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then frames[p]=p.CFrame end end
 local bodies,bodyIndex={},{}
 local targets=m.Targets:GetChildren();table.sort(targets,function(a,b)return a.Name<b.Name end)
 for index,ref in targets do
  colors[ref.Value]=ref.Value.Color
  local p=Instance.new("Part");p.Name="StandingTarget"..index;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.Transparency=1;p.Size=Vector3.new(3.3,5.5,4.2)
  p.CFrame=CFrame.new(ref.Value.Position+Vector3.yAxis*2.75);p.Parent=course
  table.insert(bodies,p);bodyIndex[p]=index
 end
 local query=OverlapParams.new();query.FilterType=Enum.RaycastFilterType.Include;query.FilterDescendantsInstances=bodies
 local peck=require(game.ServerStorage.CourseBuilders.EggRush.GuardianPeck)
 local controller=peck.Bind(m,course)
 local report={candidate=course:GetAttribute("CandidateId"),samples=0,hitCounts={0,0,0},wrongTargetHits=0,nonStrikeCallbacks=0,maximumTipError=0,maximumJointGap=0,maximumRestoreError=0,markerRestored=true,method="Native visible beak GetPartsInPart against three fixed standing-body boxes; deterministic authored cycle sampling, not a raced avatar"}
 local settings={rest=2.2,warning=1.8,strike=.55,impact=.3,recover=.9,phase=0}
 local ok,failure=xpcall(function()
  for sample=1,519 do
   local elapsed=sample/30
   local state=peck.Sample(settings,elapsed,3)
   local previous=peck.Sample(settings,(sample-1)/30,3)
   controller.Advance((sample-1)/30,1/30,function(p)
    if not state.lethal and not previous.lethal then report.nonStrikeCallbacks+=1 end
    for _,body in workspace:GetPartsInPart(p,query) do
     local index=bodyIndex[body];report.hitCounts[index]+=1
     if index~=state.target then report.wrongTargetHits+=1 end
    end
   end,true)
   if state.state=="Impact" then
    local tip=m.Head:GetPivot():PointToWorldSpace(m.Head:GetAttribute("BeakTip"))
    local plate=targets[state.target].Value
    report.maximumTipError=math.max(report.maximumTipError,(tip-(plate.Position+Vector3.yAxis*(plate.Size.Y/2+.25))).Magnitude)
   end
   local lower,upper=m.NeckLower,m.NeckUpper
   local a=lower.Position+lower.CFrame.UpVector*12
   local b=upper.Position-upper.CFrame.UpVector*12
   report.maximumJointGap=math.max(report.maximumJointGap,(a-b).Magnitude)
   report.samples+=1
   if sample%30==0 then task.wait() end
  end
  controller.Hold();controller.Resume()
 end,debug.traceback)
 controller.Stop()
 for p,cf in frames do report.maximumRestoreError=math.max(report.maximumRestoreError,(p.Position-cf.Position).Magnitude) end
 for p,color in colors do if p.Color~=color then report.markerRestored=false end end
 course:Destroy();report.fixtureRemoved=course.Parent==nil
 report.failure=if not ok then tostring(failure) else nil
 report.ok=ok and report.hitCounts[1]>0 and report.hitCounts[2]>0 and report.hitCounts[3]>0 and report.wrongTargetHits==0 and report.nonStrikeCallbacks==0 and report.maximumTipError<.001 and report.maximumJointGap<.001 and report.maximumRestoreError<.001 and report.markerRestored
 return report
end
return Test
