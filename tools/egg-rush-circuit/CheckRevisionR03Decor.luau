--!nonstrict
local a=game.ServerStorage.EggRushRevisionR03_20261026
local candidate=a:FindFirstChild("Candidate_R03_C04") or workspace.Course_EggRush
assert(candidate:GetAttribute("CandidateId")=="ER_P2_R03_C04")
local fixture=candidate:Clone();fixture.Name="R03_DecorCorridorCheck"
local solids={fixture.Decoration.RevisionR02,fixture.Decoration.RevisionR03,fixture.Obstacles.Mechanisms.GuardianPeck}
for _,container in solids do for _,p in container:GetDescendants() do if p:IsA("BasePart") then p.CanQuery=p.Transparency<.95 end end end
fixture.Parent=workspace
local probe=Instance.new("Part");probe.Name="R03_DecorProbe";probe.Anchored=true;probe.CanCollide=false;probe.CanTouch=false;probe.Transparency=1;probe.Size=Vector3.new(3.3,5.5,4.2);probe.Parent=workspace
local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=solids;params.RespectCanCollide=false
local report={candidate=candidate:GetAttribute("CandidateId"),standing={},jumpArcs={},queries=0,method="Actual visible native decoration with oriented 3.3x5.5x4.2 body boxes at static landings and four samples on illustrative jump arcs; excludes timed traversal and human camera"}
local seen={}
local function top(p)return p:GetAttribute("ERTop") or p.Position+p.CFrame.UpVector*p.Size.Y/2 end
local function inspect(at,direction,kind,name)
 probe.CFrame=CFrame.lookAt(at+Vector3.yAxis*2.95,at+Vector3.yAxis*2.95+direction)
 report.queries+=1
 for _,p in workspace:GetPartsInPart(probe,params) do if p.Transparency<.95 and not p.Name:match("PeckTarget") then
  local key=kind..name..p:GetFullName()
  if not seen[key] then seen[key]=true;table.insert(report[kind],{route=name,decor=p:GetFullName():sub(#fixture:GetFullName()+2),at={at.X,at.Y,at.Z}}) end
 end end
end
local ok,failure=xpcall(function()
 for _,routeName in {"RevisionNormal","RevisionExpert"} do
  local refs=fixture.Routes[routeName]:GetChildren();table.sort(refs,function(x,y)return x.Name<y.Name end)
  for index,ref in refs do
   local p=ref.Value
   local moving=p:FindFirstAncestorWhichIsA("Model")
   if not moving or moving:GetAttribute("ERMechanism")==nil then
    local prev=refs[math.max(1,index-1)].Value
    local delta=(top(p)-top(prev))*Vector3.new(1,0,1);if delta.Magnitude<.01 then delta=Vector3.zAxis end
    inspect(top(p),delta.Unit,"standing",routeName..":"..p.Name)
    if index>1 and not refs[index-1]:GetAttribute("WaitKind") and not ref:GetAttribute("WaitKind") then
     for step=1,4 do
      local t=step/5
      inspect(top(prev):Lerp(top(p),t)+Vector3.yAxis*(7.2*math.sin(math.pi*t)),delta.Unit,"jumpArcs",prev.Name.."->"..p.Name)
     end
    end
   end
  end
 end
end,debug.traceback)
probe:Destroy();fixture:Destroy();report.fixtureRemoved=true
report.failure=if not ok then tostring(failure) else nil
return game.HttpService:JSONEncode(report)
