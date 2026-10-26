--!nonstrict
local RS,Storage,Http=game:GetService("RunService"),game:GetService("ServerStorage"),game:GetService("HttpService")
assert(RS:IsStudio() and RS:IsServer() and game.PlaceId==85558151074819)
assert(game:GetService("StudioTestService"):GetTestArgs().tag==script:GetAttribute("OwnedTestTag"))
local C=require(game.ServerScriptService.Services.CourseService)
local R=require(game.ServerScriptService.Services.RaceService)
local P=require(game.ServerScriptService.Services.PlayerRaceService)
local Results=require(game.ServerScriptService.Services.ResultsService)
local T=require(Storage.CourseBuilders.EggRush[script:GetAttribute("TraversalModule")or"NativeTraversal"])
local value=Instance.new("StringValue");value.Name=script:GetAttribute("ReportName")or"ERP2ReturnMarginsReport";assert(not Storage:FindFirstChild(value.Name));value.Parent=Storage
value:SetAttribute("State","Ready")
local used=false
value:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end;used=true
 task.spawn(function()
  value:SetAttribute("State","Running")
  local report={cases={},placements=0,checkpointWrites=0,method="Actual ordinary jumps and explicitly jump-disabled walking after declared focused placements",limits="Finite return margin checks; not full-course pacing or universal corner reachability"}
  local player,root,human,char,auto,owner,control
  local ok,failure=xpcall(function()
   local course=assert(C.GetActiveCourse());assert(course:GetAttribute("CandidateId")=="ER_P2_R01_C04")
   player=assert(game.Players:GetPlayerByUserId(script:GetAttribute("UserId")or-1));char=assert(player.Character);root,human=char.HumanoidRootPart,char.Humanoid
   auto,owner=root:GetNetworkOwnershipAuto(),root:GetNetworkOwner()
   local race=R.GetCurrentRaceId();local finishAt=os.clock()+100
   local function guard()
    assert(os.clock()<finishAt and player.Character==char and human.Health>0 and C.GetActiveCourse()==course
     and R.GetCurrentRaceId()==race and R.IsRaceActive() and P.IsOfficialRacer(player),"Return test context changed")
   end
   local function waitFor(predicate,seconds,message)
    local deadline=os.clock()+seconds
    repeat guard();RS.Heartbeat:Wait()until predicate()or os.clock()>deadline
    assert(predicate(),message)
   end
   local function ready()
    waitFor(function()return (char:GetAttribute("RecoveryUntil")or 0)<=workspace:GetServerTimeNow()end,6,"Recovery immunity did not expire")
   end
   assert(human.WalkSpeed==16 and not human.UseJumpPower and math.abs(human.JumpHeight-7.2)<.01)
   local o=course.Obstacles;local g=o.S6_ShellSpill
   local starts={{o.CP4_Pocket,g.S6_ShellSpill_001,g.S6_ShellSpill_002,g.S6_ShellSpill_003},
    {g.S6_ShellSpill_005,g.S6_ShellSpill_006,g.S6_ShellSpill_007,g.S6_ShellSpill_008}}
   for _,pace in {false,true}do for index,list in starts do
    ready();local before=Results.GetPlayerResult(player).falls or 0;local points={};for _,p in list do table.insert(points,{part=p})end
    report.placements+=1
    local run=T.Run(course,player,points,{placeAtStart=true,pace=pace,guard=function()guard();assert((Results.GetPlayerResult(player).falls or 0)==before,"Actual recovery during return jump");return true end})
    table.insert(report.cases,{kind="JumpPrefix",prefix=index,pace=pace,run=run,falls=(Results.GetPlayerResult(player).falls or 0)-before})
    value.Value=Http:JSONEncode(report)
   end end
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={course};params.RespectCanCollide=true
   local function support()local hit=workspace:Raycast(root.Position,Vector3.new(0,-(human.HipHeight+root.Size.Y/2+.7),0),params);return hit and hit.Instance end
   for _,pair in {{g.S6_ShellSpill_002,g.S6_ShellSpill_003},{g.S6_ShellSpill_007,g.S6_ShellSpill_008}}do
    ready();root:SetNetworkOwner(nil);human:Move(Vector3.zero,false);human.Jump=false
    local pos=pair[1].Position+Vector3.new(0,pair[1].Size.Y/2+human.HipHeight+root.Size.Y/2+.15,0)
    report.placements+=1;char:PivotTo(CFrame.lookAt(pos,Vector3.new(pair[2].Position.X,pos.Y,pair[2].Position.Z)));root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
    waitFor(function()return support()==pair[1] and human.FloorMaterial~=Enum.Material.Air end,2,"Walking setup did not settle")
    local before=Results.GetPlayerResult(player).falls or 0
    local direction=(pair[2].Position-root.Position)*Vector3.new(1,0,1);direction=direction.Unit
    local reached=false;local positiveVelocity=0;local began=os.clock()
    control=RS.PreSimulation:Connect(function()human:Move(direction,false);human.Jump=false end)
    repeat guard();RS.Heartbeat:Wait();positiveVelocity=math.max(positiveVelocity,root.AssemblyLinearVelocity.Y)
     reached=support()==pair[2] and human.FloorMaterial~=Enum.Material.Air
    until reached or (Results.GetPlayerResult(player).falls or 0)>before or os.clock()-began>2.5
    control:Disconnect();control=nil;human:Move(Vector3.zero,false);human.Jump=false
    table.insert(report.cases,{kind="NoJump",from=pair[1].Name,to=pair[2].Name,reached=reached,maximumUpwardVelocity=positiveVelocity,falls=(Results.GetPlayerResult(player).falls or 0)-before,seconds=os.clock()-began})
    value.Value=Http:JSONEncode(report)
   end
   ready();local before=Results.GetPlayerResult(player).falls or 0;report.placements+=1
   local skip=T.Run(course,player,{{part=g.S6_ShellSpill_007},{part=course.Start}},{placeAtStart=true,pace=false,guard=function()guard();assert((Results.GetPlayerResult(player).falls or 0)==before,"Actual recovery on finish-merge temptation");return true end})
   table.insert(report.cases,{kind="FinishMergeTemptation",run=skip,falls=(Results.GetPlayerResult(player).falls or 0)-before,
    design="This diagonal can skip only the final ordinary merge cap; both lines have already passed every red hop and required encounter. Ordered checkpoint/forward-finish rules still apply."})
   report.marginChecksPassed=true
   for _,case in report.cases do if case.kind=="JumpPrefix"then report.marginChecksPassed=report.marginChecksPassed and case.run.ok and case.falls==0 elseif case.kind=="NoJump"then report.marginChecksPassed=report.marginChecksPassed and not case.reached and case.maximumUpwardVelocity<5 end end
  end,debug.traceback)
  if control then control:Disconnect()end
  if root and root.Parent then human:Move(Vector3.zero,false);human.Jump=false;if auto then root:SetNetworkOwnershipAuto()else root:SetNetworkOwner(owner)end end
  report.ok,report.failure=ok and report.marginChecksPassed==true,if ok then nil else failure
  value.Value=Http:JSONEncode(report);value:SetAttribute("State",if report.ok then "Complete"else"Failed")
 end)
end)
