--!nonstrict
local archive=game.ServerStorage.EggRushChickenR05_20261026
local candidate=archive.Candidate_ChickenR05_C01
assert(candidate:GetAttribute("CandidateId")=="ER_P2_R05_C01")
local fixture=candidate:Clone();fixture.Name="R05_ArtClearanceFixture";fixture.Parent=workspace
local m=fixture.Obstacles.Mechanisms.GuardianPeck
local targets=m.Targets:GetChildren();table.sort(targets,function(a,b)return a.Name<b.Name end)
local actorParts={}
for _,p in m:GetDescendants() do if p:IsA("BasePart") then
 p.CanQuery=true
 if p:GetAttribute("ERLethal")~=true then table.insert(actorParts,p) end
end end
local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=actorParts;params.RespectCanCollide=false
local probe=Instance.new("Part");probe.Name="R05_StandingProbe";probe.Anchored=true;probe.CanCollide=false;probe.CanTouch=false;probe.Transparency=1;probe.Size=Vector3.new(3.3,5.5,4.2);probe.Parent=fixture
local source=archive.BuildSources_C01
local sampler=require(source.GuardianPeck).Sample
local controller=require(source.ChickenPeck).Bind(m,fixture,sampler)
local parts,landings={},{}
for _,route in {fixture.Routes.RevisionNormal,fixture.Routes.RevisionExpert} do
 for _,ref in route:GetChildren() do local p=ref.Value
  local parent=p:FindFirstAncestorWhichIsA("Model")
  if not parts[p] and (not parent or parent:GetAttribute("ERMechanism")==nil) then parts[p]=true;table.insert(landings,p) end
 end
end
local report={candidate=candidate:GetAttribute("CandidateId"),queries=0,unintendedStanding={},activeTargetStanding={},poses={},method="Actual nonlethal chicken art tested with fixed landing-oriented 3.3x5.5x4.2 standing boxes; intended peck target overlap counted separately; not a human camera or full continuous traversal"}
local times={};for i=0,23 do table.insert(times,i*5.75/24) end;table.insert(times,4.7)
local ok,failure=xpcall(function()
 for targetIndex=1,3 do for _,time in times do
  local elapsed=(targetIndex-1)*5.75+time
  controller.Advance(0,elapsed,function()end,false)
  local record={target=targetIndex,time=time,state=m:GetAttribute("ERState")}
  table.insert(report.poses,record)
  for _,p in landings do
   local top=p:GetAttribute("ERTop") or p.Position+p.CFrame.UpVector*p.Size.Y/2
   probe.CFrame=CFrame.new(top+Vector3.yAxis*2.95)*p.CFrame.Rotation
   report.queries+=1
   local active=(top-targets[targetIndex].Value.Position).Magnitude<2
   for _,hit in workspace:GetPartsInPart(probe,params) do
    local row={landing=p.Name,art=hit:GetFullName():sub(#fixture:GetFullName()+2),target=targetIndex,state=record.state,time=time}
    local list=if active then report.activeTargetStanding else report.unintendedStanding
    if #list<80 then table.insert(list,row)end
   end
  end
  task.wait()
 end end
end,debug.traceback)
controller.Stop();probe:Destroy();fixture:Destroy()
report.fixtureRemoved=fixture.Parent==nil;report.failure=if not ok then tostring(failure)else nil
return game.HttpService:JSONEncode(report)
