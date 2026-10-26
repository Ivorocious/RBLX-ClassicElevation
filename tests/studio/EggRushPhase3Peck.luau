--!nonstrict
local Test={}
local RunService,Players,Workspace=game:GetService("RunService"),game:GetService("Players"),game:GetService("Workspace")
function Test.Run(expectedCandidate)
 assert(RunService:IsStudio()and RunService:IsServer()and game.PlaceId==85558151074819,"Owned Studio server required")
 local services={}
 for _,name in {"CourseService","RaceService","PlayerRaceService","CheckpointService","ResultsService","EggRushService"}do services[name]=require(game.ServerScriptService.Services[name])end
 local player=assert(Players:GetPlayers()[1]);assert(#Players:GetPlayers()==1,"One isolated actual client required")
 local course,character=assert(services.CourseService.GetActiveCourse()),assert(player.Character)
 local root,humanoid=assert(character:FindFirstChild("HumanoidRootPart")),assert(character:FindFirstChildOfClass("Humanoid"))
 local raceId,began=services.RaceService.GetCurrentRaceId(),os.clock()
 local owner,ownerAuto=root:GetNetworkOwner(),root:GetNetworkOwnershipAuto()
 local connection,movement=nil,Vector3.zero
 local report={candidate=expectedCandidate,placements={},cases={},progressWrites=0,clockWrites=0,immunityWrites=0,profileWrites=0,method="Declared setup placements, actual ordered checkpoint contacts and walked lap gate, warned ordinary jump escape, deliberate live beak hit and actual checkpoint recovery",limits="Focused real eligible avatar; setup placements are not complete-route or human game-feel proof"}
 local function result()
  local value=assert(services.ResultsService.GetPlayerResult(player))
  return{lap=value.currentLap,nextCheckpoint=value.nextCheckpointIndex,lapTimes=table.clone(value.lapTimes or{}),splits=#(value.checkpointSplits or{}),falls=value.falls or 0,latest=services.CheckpointService.GetLatestCheckpointIndex(player)}
 end
 local function guard()
  assert(os.clock()-began<100 and player.Character==character and humanoid.Health>0,"Bounded original character changed")
  assert(services.CourseService.GetActiveCourse()==course and services.RaceService.GetCurrentRaceId()==raceId,"Actual course/race changed")
  assert(services.RaceService.IsRaceActive()and services.PlayerRaceService.IsOfficialRacer(player)and services.PlayerRaceService.GetPlayerStatus(player)=="Racing","Actual eligible Racing participant required")
  assert(not services.CourseService.IsInspectionMode()and not services.RaceService.IsInspectionUnlimitedTime(),"No inspection override or immunity")
  assert(not root.Anchored and humanoid.WalkSpeed==16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.01,"Ordinary movement required")
  assert(services.EggRushService.GetDiagnostics().bound,"Actual runtime must remain bound")
  return true
 end
 local function waitFor(predicate,seconds,message)
  local deadline=os.clock()+seconds
  repeat guard();if predicate()then return end;RunService.Heartbeat:Wait()until os.clock()>deadline
  error(message)
 end
 local function check(name,value,details)
  table.insert(report.cases,{name=name,ok=value,details=details});assert(value,name)
 end
 local function top(part)return part.Position+part.CFrame.UpVector*part.Size.Y/2 end
 local function setup(name,ground)
  movement=Vector3.zero;humanoid:Move(Vector3.zero,false);humanoid.Jump=false
  local at=ground+Vector3.yAxis*(humanoid.HipHeight+root.Size.Y/2+.15)
  character:PivotTo(CFrame.new(at)*root.CFrame:ToObjectSpace(character:GetPivot()))
  root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
  table.insert(report.placements,{name=name,position={at.X,at.Y,at.Z}})
  waitFor(function()return humanoid.FloorMaterial~=Enum.Material.Air end,2,"Declared setup did not settle")
 end
 local function walkTo(ground)
  waitFor(function()
   local flat=(ground-root.Position)*Vector3.new(1,0,1)
   if flat.Magnitude<.35 then movement=Vector3.zero;return humanoid.FloorMaterial~=Enum.Material.Air end
   movement=flat.Unit;return false
  end,3,"Actual gate walk did not reach endpoint")
 end
 local function checkpoint(index)
  setup("Ordered actual CP"..index,top(course.Obstacles["CP"..index.."_Pocket"]))
  waitFor(function()return result().latest==index end,2,"Actual checkpoint contact missing")
 end
 local ok,failure=xpcall(function()
  assert(course:GetAttribute("CourseId")=="egg_rush_circuit"and course:GetAttribute("CandidateId")==expectedCandidate and course:GetAttribute("FullBodyContacts")==true,"Expected accepted gameplay candidate")
  guard()
  local fresh=result();assert(fresh.lap==1 and fresh.nextCheckpoint==1 and fresh.splits==0 and #fresh.lapTimes==0,"Fresh race required; no direct progress setup")
  root:SetNetworkOwner(nil)
  connection=RunService.PreSimulation:Connect(function()humanoid:Move(movement,false);humanoid.Jump=false end)
  for index=1,4 do checkpoint(index)end
  local function gateGround(z)
   local at=course.Finish.CFrame:PointToWorldSpace(Vector3.new(0,0,z));return Vector3.new(at.X,top(course.Start).Y,at.Z)
  end
  setup("Declared forward gate approach",gateGround(3));walkTo(gateGround(-3))
  waitFor(function()return result().lap==2 and #result().lapTimes==1 end,2,"Actual forward gate did not award completed lap1")
  for index=1,3 do checkpoint(index)end
  waitFor(function()return(character:GetAttribute("RecoveryUntil")or 0)<=Workspace:GetServerTimeNow()end,3,"Existing immunity must expire")
  local baseline=result();report.before=baseline
  check("Actual completed lap and CP3 established",baseline.lap==2 and baseline.nextCheckpoint==4 and baseline.latest==3 and baseline.splits==7 and #baseline.lapTimes==1,baseline)
  local traversal=require(game.ServerStorage.CourseBuilders.EggRush.NativeTraversal)
  local points=traversal.Points(course,"Normal")
  local target,nextPoint
  for index,point in points do if point.peck and point.peck.target==1 then target,nextPoint=point,points[index+1];break end end
  assert(target and nextPoint,"Current Normal target1 and actual next landing required")
  local chicken=target.peck.model
  local function state(name)return chicken:GetAttribute("ERPeckTarget")==1 and chicken:GetAttribute("ERState")==name end
  waitFor(function()return state("Rest")end,20,"Target1 Rest not observed")
  setup("Warned escape target1",top(target.part))
  waitFor(function()return state("Warning")end,4,"Actual target1 warning not observed")
  report.escapeWarning={clock=services.EggRushService.GetDiagnostics().elapsed,state=chicken:GetAttribute("ERState"),target=chicken:GetAttribute("ERPeckTarget"),plateColor={chicken.Targets["01"].Value.Color.R,chicken.Targets["01"].Value.Color.G,chicken.Targets["01"].Value.Color.B}}
  connection:Disconnect();connection=nil
  report.escape=traversal.Run(course,player,{{part=target.part},{part=nextPoint.part}},{placeAtStart=false,guard=guard})
  assert(report.escape.ok,report.escape.failure)
  root:SetNetworkOwner(nil)
  connection=RunService.PreSimulation:Connect(function()humanoid:Move(movement,false);humanoid.Jump=false end)
  waitFor(function()return state("Recovering")end,5,"Actual strike/recovery not observed after escape")
  check("Warned ordinary jump escapes without recovery",result().falls==baseline.falls,{result=result(),jump=report.escape.records[1]})
  waitFor(function()return state("Rest")end,20,"Next target1 Rest not observed")
  setup("Intentional beak hit target1",top(target.part))
  local runtimeBefore=services.EggRushService.GetDiagnostics()
  local observedWarning,observedStrike=false,false
  waitFor(function()
   observedWarning=observedWarning or state("Warning")
   observedStrike=observedStrike or(state("Pecking")or state("Impact"))
   return result().falls==baseline.falls+1
  end,6,"Live beak did not recover the eligible standing player")
  local after=result();local runtimeAfter=services.EggRushService.GetDiagnostics()
  check("Live warned beak causes exactly one actual recovery",observedWarning and observedStrike and after.falls==baseline.falls+1 and runtimeAfter.stats.recoveries==runtimeBefore.stats.recoveries+1,{before=runtimeBefore,after=runtimeAfter,result=after})
  check("Hit keeps completed lap, current lap and latest checkpoint",after.lap==baseline.lap and after.nextCheckpoint==baseline.nextCheckpoint and after.latest==3 and after.splits==baseline.splits and after.lapTimes[1]==baseline.lapTimes[1],after)
  local expected=assert(services.CheckpointService.GetCheckpointRespawnCFrame(player))
  check("Actual recovery arrives at CP3 frame",(root.Position-expected.Position).Magnitude<2,{distance=(root.Position-expected.Position).Magnitude,recoveryUntil=character:GetAttribute("RecoveryUntil")})
  waitFor(function()return humanoid.FloorMaterial~=Enum.Material.Air end,2,"Actual recovery did not settle")
  local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={course};ray.RespectCanCollide=true
  local support=Workspace:Raycast(root.Position,Vector3.new(0,-9,0),ray)
  check("Recovery is physically supported on CP3",support and support.Instance==course.Obstacles.CP3_Pocket,{support=support and support.Instance:GetFullName()})
  local untilAt=os.clock()+3.5
  waitFor(function()assert(result().falls==baseline.falls+1,"Immediate repeated recovery at CP3");return os.clock()>=untilAt end,4,"Post-immunity observation did not complete")
  check("No repeated recovery after immunity expires",(character:GetAttribute("RecoveryUntil")or 0)<Workspace:GetServerTimeNow()and result().falls==baseline.falls+1,result())
  report.complete=true
 end,debug.traceback)
 if connection then connection:Disconnect()end
 humanoid:Move(Vector3.zero,false);humanoid.Jump=false
 if root.Parent then if ownerAuto then root:SetNetworkOwnershipAuto()else root:SetNetworkOwner(owner)end end
 report.ok,report.failure,report.seconds,report.final=ok,if ok then nil else tostring(failure),os.clock()-began,result()
 report.cleanup="Movement stopped and original ownership restored; no return placement"
 script:SetAttribute("State",if ok then"Complete"else"Failed")
 return report
end
return Test
