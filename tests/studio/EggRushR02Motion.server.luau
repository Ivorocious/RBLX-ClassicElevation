--!nonstrict
local RunService=game:GetService("RunService")
local Storage,Workspace,Http=game.ServerStorage,workspace,game.HttpService
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId==85558151074819)
local report=Instance.new("StringValue")
report.Name,report.Parent="EggRushR02MotionReport",Storage
report:SetAttribute("State","Running")
local result={candidate=script:GetAttribute("ExpectedCandidate")or "ER_P2_R02_C06",seconds=script:GetAttribute("Seconds")or 30,
 samples=0,mechanisms={},safeOverlaps={},shellWaitOverlaps={},shellHitCountsByWait={},lethalHitCountsByWait={},
 method="Actual runtime on one cloned course, no eligible players; fixed standing-body boxes at waits; bounded shared-cycle sample",
 limits="No avatar movement, human Expert completion, tray rider, race progress, multiplayer or FPS proof"}
local fixture,probe,controller
local saved={}
local ok,failure=xpcall(function()
 local library=Storage:WaitForChild("CourseLibrary",15)
 local template=library:WaitForChild("Course_EggRush",15)
 assert(template and template:GetAttribute("CandidateId")==result.candidate)
 fixture=template:Clone()
 fixture.Name,fixture.Parent="ER_R02MotionFixture",Workspace
 local moving,contacts,shells={},{},{}
 for _,m in ipairs(fixture.Obstacles.Mechanisms:GetChildren()) do
  moving[m.Name]=m
  result.mechanisms[m.Name]={kind=m:GetAttribute("ERMechanism"),states={},rollingEntries={}}
  saved[m]={frame=m:GetPivot(),parts={}}
  for _,p in ipairs(m:GetDescendants()) do
   if p:IsA("BasePart") then
    saved[m].parts[p]={frame=p.CFrame,transparency=p.Transparency}
    if p:GetAttribute("ERLethal")==true then table.insert(contacts,p) end
    if m:GetAttribute("ERMechanism")=="ShellLip" and p.CanCollide then table.insert(shells,p) end
   end
  end
 end
 for _,p in ipairs(fixture.Obstacles.ThemedHazards:GetDescendants()) do
  if p:IsA("BasePart") and p:GetAttribute("ERLethal")==true then table.insert(contacts,p) end
 end
 probe=Instance.new("Part")
 probe.Name,probe.Size="ER_R02StandingProbe",Vector3.new(3.3,5.5,4.2)
 probe.Anchored,probe.CanCollide,probe.CanTouch,probe.CanQuery,probe.Transparency=true,false,false,true,1
 probe.Parent=fixture
 local params=OverlapParams.new()
 params.FilterType,params.FilterDescendantsInstances=Enum.RaycastFilterType.Include,contacts
 local shellParams=OverlapParams.new()
 shellParams.FilterType,shellParams.FilterDescendantsInstances=Enum.RaycastFilterType.Include,shells
 local waits={}
 for _,name in ipairs({"CP1_Pocket","CP2_Pocket","CP3_Pocket","CP4_Pocket","Shell_ForkWait","Shell_MiddleWait","Shell_ExitWait",
  "Tray_BoardPocket","Tray_ReceivePocket","TrayB_BoardPocket","TrayB_ReceivePocket","Tail_SafeWait",
  "S2_EggRollers_003","S2_EggRollers_005","S2_EggRollers_008","S2_EggRollers_010",
  "E2_ChuteCut_003","E2_ChuteCut_005","E2_ChuteCut_007","E2_ChuteCut_009"}) do
  local wait=assert(fixture.Obstacles:FindFirstChild(name,true),name)
  table.insert(waits,wait)
 end
 local Runtime=require(Storage.CourseBuilders.EggRush.Runtime)
 controller=Runtime.Start(fixture,function()return false end,function()error("No player should be recovered")end)
 local deadline=os.clock()+45
 repeat
  task.wait(.1)
  local d=controller.Diagnostics()
  result.samples+=1
  for _,state in ipairs(d.mechanisms) do
   local row=result.mechanisms[state.name]
   row.states[state.state]=(row.states[state.state] or 0)+1
   if state.state=="Rolling" and row.lastState~="Rolling" then table.insert(row.rollingEntries,d.elapsed) end
   row.lastState=state.state
  end
  for _,p in ipairs(waits) do
   local top=p.Position+p.CFrame.UpVector*p.Size.Y/2
   probe.CFrame=CFrame.new(top+Vector3.new(0,2.75,0))*p.CFrame.Rotation
   for _,hit in ipairs(Workspace:GetPartsInPart(probe,params)) do
    if hit.Transparency<1 then
     result.lethalHitCountsByWait[p.Name]=(result.lethalHitCountsByWait[p.Name]or 0)+1
     if #result.safeOverlaps<30 then table.insert(result.safeOverlaps,{wait=p.Name,hit=hit:GetFullName(),clock=d.elapsed}) end
    end
   end
   if p.Name:find("Shell_",1,true)==1 then
    for _,hit in ipairs(Workspace:GetPartsInPart(probe,shellParams)) do
     result.shellHitCountsByWait[p.Name]=(result.shellHitCountsByWait[p.Name]or 0)+1
     if #result.shellWaitOverlaps<30 then table.insert(result.shellWaitOverlaps,{wait=p.Name,hit=hit:GetFullName(),clock=d.elapsed}) end
    end
   end
  end
 until controller.Diagnostics().elapsed>=result.seconds or os.clock()>=deadline
 result.diagnostics=controller.Diagnostics()
 assert(result.diagnostics.elapsed>=result.seconds,"Shared motion clock did not cover two full cycles")
 controller.Stop()
 result.maximumPositionError,result.maximumBasisError,result.maximumTransparencyError=0,0,0
 for m,baseline in pairs(saved) do
  result.maximumPositionError=math.max(result.maximumPositionError,(m:GetPivot().Position-baseline.frame.Position).Magnitude)
  for p,s in pairs(baseline.parts) do
   result.maximumPositionError=math.max(result.maximumPositionError,(p.Position-s.frame.Position).Magnitude)
   result.maximumBasisError=math.max(result.maximumBasisError,(p.CFrame.RightVector-s.frame.RightVector).Magnitude+(p.CFrame.UpVector-s.frame.UpVector).Magnitude)
   result.maximumTransparencyError=math.max(result.maximumTransparencyError,math.abs(p.Transparency-s.transparency))
  end
 end
 assert(result.maximumPositionError<.002 and result.maximumBasisError<.0001 and result.maximumTransparencyError==0,"Runtime authoring-pose restoration differs")
 assert(#result.safeOverlaps==0,"A designated safe standing box intersects visible lethal geometry")
 assert(#result.shellWaitOverlaps==0,"A shell wait standing box intersects moving shell solids")
 result.complete=true
end,debug.traceback)
if controller then controller.Stop() end
if probe then probe:Destroy() end
if fixture then fixture:Destroy() end
result.fixtureRemoved=not Workspace:FindFirstChild("ER_R02MotionFixture")
result.ok,result.failure=ok,if ok then nil else failure
report.Value=Http:JSONEncode(result)
report:SetAttribute("State",if ok then "Complete" else "Failed")
