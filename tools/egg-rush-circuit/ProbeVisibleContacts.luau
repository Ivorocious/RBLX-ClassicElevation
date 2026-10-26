local course=assert(workspace:FindFirstChild("Course_EggRush"))
assert(game.PlaceId==85558151074819 and not game.RunService:IsRunning()and course:GetAttribute("EROwned"))
local mechanisms=course.Obstacles.Mechanisms
local probe=Instance.new("Part");probe.Name="__EggRushVisibleContactProbe"
probe.Size=Vector3.one*.12;probe.Anchored=true;probe.Transparency=1
probe.CanCollide=false;probe.CanTouch=false;probe.CanQuery=true;probe.Parent=workspace
local report={candidate=course:GetAttribute("CandidateId"),ok=true,cases={},
 limits="Small static surface/corner probes in Edit; the shaft-interior sample is observational. Moving-avatar tests decide contact behavior; this is not a solid-interior, pixel-perfect collision or human gameplay claim"}
local ok,failure=xpcall(function()
 local function sample(model,name,point,expected)
  local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include
  params.FilterDescendantsInstances={model};params.RespectCanCollide=false
  probe.CFrame=model:GetPivot()*CFrame.new(point)
  local hits={}
  for _,p in ipairs(workspace:GetPartsInPart(probe,params))do
   if p:GetAttribute("ERLethal")==true and p.Transparency<1 then table.insert(hits,p.Name)end
  end
  local passed=expected==nil or(#hits>0)==expected
  report.ok=report.ok and passed
  table.insert(report.cases,{name=name,point={point.X,point.Y,point.Z},expected=expected,observational=expected==nil,hits=hits,ok=passed})
 end
 for i=1,2 do
  local m=mechanisms["EggBand"..i]
  sample(m,"Egg"..i.."Body",Vector3.zero,true)
  sample(m,"Egg"..i.."Cap",Vector3.new(0,3.6,0),true)
  sample(m,"Egg"..i.."EmptyCapCorner",Vector3.new(3.2,3.6,3.2),false)
  sample(m,"Egg"..i.."Outside",Vector3.new(4.2,0,4.2),false)
 end
 local t=mechanisms.GuardianTail
 sample(t,"TailShaftInterior",Vector3.new(10,1,0),nil)
 sample(t,"TailShaftTop",Vector3.new(10,2.18,0),true)
 sample(t,"TailShaftBottom",Vector3.new(10,-1.48,0),true)
 sample(t,"TailCentralTip",Vector3.new(28,1,0),true)
 sample(t,"TailEmptyNorthCorner",Vector3.new(28,1,-3.8),false)
 sample(t,"TailEmptySouthCorner",Vector3.new(27,1,3.5),false)
end,debug.traceback)
probe:Destroy()
if not ok then report.ok=false;report.failure=failure end
return game.HttpService:JSONEncode(report)
