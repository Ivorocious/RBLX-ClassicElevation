--!nonstrict
local S,H,RS=game.ServerStorage,game.HttpService,game:GetService("RunService")
assert(RS:IsStudio() and RS:IsServer() and game.PlaceId==85558151074819)
assert(game:GetService("StudioTestService"):GetTestArgs().tag==script:GetAttribute("OwnedTestTag"))
local C=require(game.ServerScriptService.Services.CourseService)
local R=require(game.ServerScriptService.Services.RaceService)
local P=require(game.ServerScriptService.Services.PlayerRaceService)
local Results=require(game.ServerScriptService.Services.ResultsService)
local T=require(S.CourseBuilders.EggRush[script:GetAttribute("TraversalModule")or"NativeTraversal"])
local report=Instance.new("StringValue");report.Name=script:GetAttribute("ReportName")or"ERP2OrdinaryMarginsReport"
assert(not S:FindFirstChild(report.Name));report.Parent=S;report:SetAttribute("State","Ready")
local used=false
report:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end;used=true;report:SetAttribute("State","Running")
 task.spawn(function()
  local out={cases={},placements=0,checkpointWrites=0,method="One real fitted actor on each declared ordinary lane; isolated from the other player",limits="Finite focused jumps, not simultaneous passing, normal entry or full-race pacing"}
  local player,root,h,originalAuto,originalOwner
  local ok,err=xpcall(function()
   local course=assert(C.GetActiveCourse());local expected=script:GetAttribute("ExpectedCandidate")or"ER_P2_R01_C04"
   assert(course:GetAttribute("CandidateId")==expected);out.candidateId=expected
   player=assert(game.Players:GetPlayerByUserId(-1));root=player.Character.HumanoidRootPart;h=player.Character.Humanoid
   originalAuto,originalOwner=root:GetNetworkOwnershipAuto(),root:GetNetworkOwner()
   local race=R.GetCurrentRaceId();local deadline=os.clock()+75
   local function guard()return os.clock()<deadline and C.GetActiveCourse()==course and R.GetCurrentRaceId()==race and R.IsRaceActive()and P.IsOfficialRacer(player)and h.Health>0 end
   local o=course.Obstacles
   local paths={
    {name="ExitClimb",points={o.Tray_ReceivePocket,o.S4_ExitClimb.S4_ExitClimb_001,o.S4_ExitClimb.S4_ExitClimb_002,o.S4_ExitClimb.S4_ExitClimb_003,o.S4_ExitClimb.S4_ExitClimb_004,o.CP3_Pocket}},
    {name="RookeryTurn",points={o.S5_Rookery.S5_Rookery_002,o.S5_Rookery.S5_Rookery_003,o.S5_Rookery.S5_Rookery_004,o.S5_Rookery.S5_Rookery_005}}}
   for _,path in paths do for _,side in {-1,1}do
    while(player.Character:GetAttribute("RecoveryUntil")or 0)>workspace:GetServerTimeNow()do assert(guard());RS.Heartbeat:Wait()end
    local before=Results.GetPlayerResult(player).falls or 0
    local points={};for _,part in path.points do table.insert(points,{part=part})end
    local calls=0;local aims={}
    local function aim(part,nextPart,default)
     calls+=1;local v=part.CFrame:PointToObjectSpace(default+part.CFrame.RightVector*2*side)
     local chosen=part.CFrame:PointToWorldSpace(Vector3.new(math.clamp(v.X,-part.Size.X/2+.75,part.Size.X/2-.75),part.Size.Y/2,math.clamp(v.Z,-part.Size.Z/2+.75,part.Size.Z/2-.75)))
     aims[part.Name]={chosen.X,chosen.Y,chosen.Z};return chosen
    end
    out.placements+=1
    local driver=T.Run(course,player,points,{placeAtStart=true,pace=true,aim=aim,guard=function()return guard()and(Results.GetPlayerResult(player).falls or 0)==before end})
    table.insert(out.cases,{path=path.name,side=side,driver=driver,aims=aims,aimCalls=calls,falls=(Results.GetPlayerResult(player).falls or 0)-before})
    report.Value=H:JSONEncode(out)
   end end
   out.allPassed=true;for _,case in out.cases do out.allPassed=out.allPassed and case.driver.ok and case.falls==0 and case.aimCalls>0 end
  end,debug.traceback)
  if root and root.Parent then h:Move(Vector3.zero,false);h.Jump=false;if originalAuto then root:SetNetworkOwnershipAuto()else root:SetNetworkOwner(originalOwner)end end
  out.ok,out.failure=ok,if ok then nil else err;report.Value=H:JSONEncode(out);report:SetAttribute("State",if ok then"Complete"else"Failed")
 end)
end)

