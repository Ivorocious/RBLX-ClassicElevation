--!nonstrict
local Test={}
local RunService,Players,Workspace=game:GetService("RunService"),game:GetService("Players"),game:GetService("Workspace")
local BODY_NAMES={Head=true,Torso=true,UpperTorso=true,LowerTorso=true,["Left Arm"]=true,["Right Arm"]=true,["Left Leg"]=true,["Right Leg"]=true,LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,RightUpperArm=true,RightLowerArm=true,RightHand=true,LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,RightUpperLeg=true,RightLowerLeg=true,RightFoot=true}
function Test.Run(expectedCandidate)
 assert(RunService:IsStudio()and RunService:IsServer()and game.PlaceId==85558151074819,"Owned Studio server required")
 local services={}
 for _,name in {"CourseService","RaceService","PlayerRaceService","ResultsService","EggRushService"}do services[name]=require(game.ServerScriptService.Services[name])end
 local player=assert(Players:GetPlayers()[1]);assert(#Players:GetPlayers()==1,"One isolated actual client required")
 local course,character=assert(services.CourseService.GetActiveCourse()),assert(player.Character)
 local root,humanoid=assert(character:FindFirstChild("HumanoidRootPart")),assert(character:FindFirstChildOfClass("Humanoid"))
 local collider=assert(character:FindFirstChild("CollisionPart"));local colliderSize=collider.Size
 local raceId,began=services.RaceService.GetCurrentRaceId(),os.clock()
 local owner,ownerAuto=root:GetNetworkOwner(),root:GetNetworkOwnershipAuto()
 local observer,observerFailure=nil,nil
 local report={candidate=expectedCandidate,userId=player.UserId,raceId=raceId,placements={},landings={},trace={},progressWrites=0,clockWrites=0,profileWrites=0,immunityWrites=0,method="One declared setup on actual S6_001, then supported Normal 001 to 002 to 003 to 004 through both Return sweeps; all contacts active",limits="Focused scripted native avatar; one setup is not ordinary entry, complete-route, human or crowd proof"}
 local function result()
  local value=assert(services.ResultsService.GetPlayerResult(player))
  return{lap=value.currentLap,nextCheckpoint=value.nextCheckpointIndex,falls=value.falls or 0,lapTimes=table.clone(value.lapTimes or{}),splits=#(value.checkpointSplits or{})}
 end
 local initial=result();local recoveryUntil=character:GetAttribute("RecoveryUntil")or 0
 report.runtimeBefore=services.EggRushService.GetDiagnostics()
 local function guard()
  assert(not observerFailure,observerFailure)
  assert(os.clock()-began<45 and player.Character==character and humanoid.Health>0,"Bounded original character changed")
  assert(services.CourseService.GetActiveCourse()==course and services.RaceService.GetCurrentRaceId()==raceId,"Actual course/race changed")
  assert(services.RaceService.IsRaceActive()and services.PlayerRaceService.IsOfficialRacer(player)and services.PlayerRaceService.GetPlayerStatus(player)=="Racing","Actual eligible Racing participant required")
  assert(not services.CourseService.IsInspectionMode()and not services.RaceService.IsInspectionUnlimitedTime(),"No inspection override or immunity")
  assert(not root.Anchored and humanoid.WalkSpeed==16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.01 and math.abs(Workspace.Gravity-196.2)<.01,"Accepted ordinary movement required")
  assert(collider.CanCollide and(collider.Size-colliderSize).Magnitude<.02 and services.EggRushService.GetDiagnostics().bound,"Fitted body/current runtime changed")
  assert(result().falls==initial.falls and(character:GetAttribute("RecoveryUntil")or 0)<=recoveryUntil+.01,"Actual recovery; focused attempt failed")
  return true
 end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={course};ray.RespectCanCollide=true
 local function support()
  local hit=Workspace:Raycast(root.Position,Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.7),0),ray)
  return hit and hit.Instance
 end
 local function snapshot()
  local rig={}
  for _,part in character:GetChildren()do
   if part:IsA("BasePart")and(BODY_NAMES[part.Name]or part==root or part==collider)then
    table.insert(rig,{name=part.Name,size={part.Size.X,part.Size.Y,part.Size.Z},frame={root.CFrame:ToObjectSpace(part.CFrame):GetComponents()},bodyContact=BODY_NAMES[part.Name]==true,visible=part.Transparency<1,canQuery=part.CanQuery,canCollide=part.CanCollide})
   end
  end
  return{seconds=os.clock()-began,root={root.CFrame:GetComponents()},hipHeight=humanoid.HipHeight,floor=tostring(humanoid.FloorMaterial),support=support()and support():GetFullName(),rig=rig,result=result()}
 end
 local ok,failure=xpcall(function()
  assert(course:GetAttribute("CourseId")=="egg_rush_circuit"and course:GetAttribute("CandidateId")==expectedCandidate and course:GetAttribute("FullBodyContacts")==true,"Expected actual gameplay candidate")
  assert(recoveryUntil<=Workspace:GetServerTimeNow(),"Wait for existing recovery immunity to expire before starting")
  guard();report.before=snapshot()
  local traversal=require(game.ServerStorage.CourseBuilders.EggRush.NativeTraversal)
  local all=traversal.Points(course,"Normal");local points={}
  for _,point in all do if table.find({"S6_ShellSpill_001","S6_ShellSpill_002","S6_ShellSpill_003","S6_ShellSpill_004"},point.part.Name)then table.insert(points,table.clone(point))end end
  assert(#points==4,"Current four-point Return sweep segment required")
  local sweepModels,redParts,owners={},{},{};report.sweepGeometry={}
  for _,name in {"ReturnFeatherSwing","ReturnFeederSweep"}do
   local model=course.Obstacles.Mechanisms[name];table.insert(sweepModels,model)
   local pivot=model:GetPivot()
   for _,part in model:GetDescendants()do
    if part:IsA("BasePart")and part:GetAttribute("ERLethal")==true then
     table.insert(redParts,part);owners[part]=model
     table.insert(report.sweepGeometry,{actor=name,path=part:GetFullName(),size={part.Size.X,part.Size.Y,part.Size.Z},frame={pivot:ToObjectSpace(part.CFrame):GetComponents()},canQuery=part.CanQuery})
    end
   end
  end
  local bodies={}
  for _,part in character:GetChildren()do if part:IsA("BasePart")and BODY_NAMES[part.Name]and part.Transparency<1 and part.CanQuery then table.insert(bodies,part)end end
  local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances=bodies;overlap.RespectCanCollide=false
  local lastSample=0
  observer=RunService.PostSimulation:Connect(function()
   local observed,message=xpcall(function()
    local contacts={}
    for _,red in redParts do
     local actor=owners[red]
     if red.Transparency<1 then
      for _,body in Workspace:GetPartsInPart(red,overlap)do table.insert(contacts,{actor=actor.Name,part=red.Name,body=body.Name})end
     end
    end
    if os.clock()-lastSample<.15 and #contacts==0 then return end
    lastSample=os.clock()
    local value=snapshot();value.sweepOverlaps=contacts;value.actors={};value.step=report.lastProgress and report.lastProgress.step
    for _,actor in sweepModels do table.insert(value.actors,{name=actor.Name,state=actor:GetAttribute("ERState"),clock=services.EggRushService.GetDiagnostics().elapsed,pivot={actor:GetPivot():GetComponents()}})end
    table.insert(report.trace,value)
    if #report.trace>80 then table.remove(report.trace,1)end
   end,debug.traceback)
   if not observed then observerFailure=tostring(message)end
  end)
  local from=points[1].part
  local ground=from.Position+from.CFrame.UpVector*from.Size.Y/2
  local at=ground+Vector3.yAxis*(humanoid.HipHeight+root.Size.Y/2+.15)
  root:SetNetworkOwner(nil)
  character:PivotTo(CFrame.new(at)*root.CFrame:ToObjectSpace(character:GetPivot()))
  root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
  table.insert(report.placements,{part=from:GetFullName(),rootTarget={at.X,at.Y,at.Z}})
  report.driver=traversal.Run(course,player,points,{placeAtStart=false,guard=guard,afterLanding=function(index,point,record)
   guard();table.insert(report.landings,{part=point.part.Name,record=record,body=snapshot()})
  end},function(index,total,step)report.lastProgress={index=index,total=total-1,step=step};script:SetAttribute("Progress",step)end)
  assert(report.driver.ok,report.driver.failure)
  guard();report.final=snapshot()
  assert(report.driver.jumps==3 and #report.landings==3 and #report.placements==1,"All three supported jumps and one declared setup required")
  assert(#report.driver.supportedWalks==1 and report.driver.supportedWalks[1].supportedThroughout,"One physically supported move to the north feather wait required")
  for _,name in {"ReturnFeatherSwing","ReturnFeederSweep"}do
   local found=false
   for _,receipt in report.driver.windowTrace do if receipt.model==name and receipt.entryClock then found=true end end
   assert(found,"Actual sweep admission receipt missing: "..name)
  end
  local heldThroughReturn=false
  for _,sample in report.trace do
   if sample.support==points[2].part:GetFullName()and sample.step=="S6_ShellSpill_002 -> S6_ShellSpill_003"then
    for _,actor in sample.actors do if actor.name=="ReturnFeatherSwing"and actor.state=="Returning"then heldThroughReturn=true end end
   end
   assert(#sample.sweepOverlaps==0,"Actual visible body overlap with a Return sweep")
  end
  report.heldThroughFeatherReturn=heldThroughReturn
  assert(heldThroughReturn,"Observe real supported waiting on002 while the feather returns before the feeder admission")
  local value=result()
  assert(value.lap==initial.lap and value.nextCheckpoint==initial.nextCheckpoint and value.splits==initial.splits and #value.lapTimes==#initial.lapTimes,"Focused check must retain actual existing progress")
  report.complete=true
 end,debug.traceback)
 if observer then observer:Disconnect()end
 humanoid:Move(Vector3.zero,false);humanoid.Jump=false
 if root.Parent then if ownerAuto then root:SetNetworkOwnershipAuto()else root:SetNetworkOwner(owner)end end
 report.ok,report.failure,report.seconds=ok and observerFailure==nil,if ok then observerFailure else tostring(failure),os.clock()-began
 report.runtimeAfter=services.EggRushService.GetDiagnostics()
 report.after=snapshot();report.cleanup="Observer/controller removed, movement stopped, original network ownership restored; no return placement"
 script:SetAttribute("State",if report.ok then"Complete"else"Failed")
 return report
end
return Test
