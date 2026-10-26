--!nonstrict
local Test = {}
local RunService, Players, Workspace, LogService = game:GetService("RunService"), game:GetService("Players"), game:GetService("Workspace"), game:GetService("LogService")
local BODY_NAMES = {Head=true,Torso=true,UpperTorso=true,LowerTorso=true,["Left Arm"]=true,["Right Arm"]=true,["Left Leg"]=true,["Right Leg"]=true,LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,RightUpperArm=true,RightLowerArm=true,RightHand=true,LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,RightUpperLeg=true,RightLowerLeg=true,RightFoot=true}
local PART_NAMES = {"CP4_Pocket", "S6_ShellSpill_001", "S6_ShellSpill_002", "S6_ShellSpill_003", "S6_ShellSpill_004"}
local SWEEP_NAMES = {"ReturnFeatherSwing", "ReturnFeederSweep"}
local INCOMING_STEP = "S6_ShellSpill_001 -> S6_ShellSpill_002"
local function vector(v) return {v.X,v.Y,v.Z} end
local function frame(cf) return {cf:GetComponents()} end
local function bottom(part)
 local cf,size=part.CFrame,part.Size
 local half=(math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z)/2
 return cf.Position.Y-half
end

function Test.Run(expectedCandidate)
 expectedCandidate=expectedCandidate or "ER_P3_W06_C03"
 assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId==85558151074819,"Owned Studio server required")
 local services={}
 for _,name in {"CourseService","RaceService","PlayerRaceService","ResultsService","EggRushService"} do
  services[name]=require(game.ServerScriptService.Services[name])
 end
 local player=assert(Players:GetPlayers()[1],"Actual racer missing")
 assert(#Players:GetPlayers()==1,"One isolated actual client required")
 local course,character=assert(services.CourseService.GetActiveCourse()),assert(player.Character)
 local root,humanoid=assert(character:FindFirstChild("HumanoidRootPart")),assert(character:FindFirstChildOfClass("Humanoid"))
 local collider=assert(character:FindFirstChild("CollisionPart"));local colliderSize=collider.Size
 local raceId,began=services.RaceService.GetCurrentRaceId(),os.clock()
 local originalOwner,originalAuto=root:GetNetworkOwner(),root:GetNetworkOwnershipAuto()
 local observer,observerFailure,lastSample,lastKey=nil,nil,-math.huge,nil
 local parts,models,redParts,redOwners,bodies,feet={}, {}, {}, {}, {}, {}
 local fallConnections={}
 local report={
  candidateExpected=expectedCandidate,userId=player.UserId,raceId=raceId,placements={},landings={},trace={},fallTouches={},recoveryMessages={},
  progressWrites=0,clockWrites=0,profileWrites=0,immunityWrites=0,geometryWrites=0,
  sampling={otherPeriodSeconds=.12,physicsFramesChecked=0,incomingFramesChecked=0,incomingFramesSaved=0,overlapFrames=0,maxPhysicsDelta=0},
  method="One declared setup on CP4, then the unchanged Normal driver through 001, 002, 003 and 004 with live contacts and timing",
  limits="One scripted racer and one focused placement; not ordinary entry, a full lap, human, crowd, device or performance proof. Instantaneous overlap samples do not replace runtime substep contact checks. Scenery overlap queries cover queryable HatcheryWorld parts only.",
 }
 local function result()
  local value=assert(services.ResultsService.GetPlayerResult(player))
  return {lap=value.currentLap,nextCheckpoint=value.nextCheckpointIndex,falls=value.falls or 0,
   lapTimes=table.clone(value.lapTimes or {}),splits=#(value.checkpointSplits or {}),status=services.PlayerRaceService.GetPlayerStatus(player)}
 end
 local initial=result();local initialRecovery=character:GetAttribute("RecoveryUntil") or 0
 local runtimeBefore=services.EggRushService.GetDiagnostics()
 report.initialResult,report.initialRecoveryUntil,report.runtimeBefore=initial,initialRecovery,runtimeBefore
 local function guard()
  assert(not observerFailure,observerFailure)
  assert(os.clock()-began<45 and player.Character==character and root.Parent and humanoid.Parent and humanoid.Health>0,"Bounded original character changed")
  assert(services.CourseService.GetActiveCourse()==course and services.RaceService.GetCurrentRaceId()==raceId,"Course or race changed")
  assert(services.RaceService.IsRaceActive() and services.PlayerRaceService.IsOfficialRacer(player) and services.PlayerRaceService.GetPlayerStatus(player)=="Racing","Actual eligible Racing participant required")
  assert(not services.CourseService.IsInspectionMode() and not services.RaceService.IsInspectionUnlimitedTime(),"No inspection override or immunity")
  assert(not root.Anchored and humanoid.WalkSpeed==16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.01 and math.abs(Workspace.Gravity-196.2)<.01,"Ordinary movement required")
  local runtime=services.EggRushService.GetDiagnostics()
  assert(collider.Parent==character and collider.CanCollide and (collider.Size-colliderSize).Magnitude<.02 and runtime.bound and not runtime.holding and runtime.raceId==raceId,"Fitted body or live runtime changed")
  local current=result()
  assert(current.lap==initial.lap and current.nextCheckpoint==initial.nextCheckpoint and current.splits==initial.splits and #current.lapTimes==#initial.lapTimes,"Focused attempt changed progression")
  assert(current.falls==initial.falls and (character:GetAttribute("RecoveryUntil") or 0)<=initialRecovery+.01,"Actual recovery; stop the focused attempt")
  return true
 end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={course};ray.RespectCanCollide=true
 local hazardOverlap=OverlapParams.new();hazardOverlap.FilterType=Enum.RaycastFilterType.Include;hazardOverlap.RespectCanCollide=false
 local sceneryOverlap=OverlapParams.new();sceneryOverlap.FilterType=Enum.RaycastFilterType.Include;sceneryOverlap.RespectCanCollide=false
 local function standing()
  local hit=Workspace:Raycast(root.Position,Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.7),0),ray)
  return hit and hit.Instance,hit
 end
 local function hazardContacts()
  local contacts={}
  for _,red in redParts do
   if red.Transparency<1 then
    for _,body in Workspace:GetPartsInPart(red,hazardOverlap) do table.insert(contacts,{actor=redOwners[red],part=red.Name,body=body.Name}) end
   end
  end
  return contacts
 end
 local function sceneryContacts()
  local contacts={}
  local queryParts=table.clone(bodies);table.insert(queryParts,collider)
  for _,body in queryParts do
   for _,part in Workspace:GetPartsInPart(body,sceneryOverlap) do
    table.insert(contacts,{body=body.Name,path=part:GetFullName(),canCollide=part.CanCollide,canQuery=part.CanQuery,transparency=part.Transparency})
   end
  end
  return contacts
 end
 local function snapshot(reason,dt,contacts,diagnostics)
  local support,hit=standing();local actors={};local clock=diagnostics.elapsed
  for _,actor in models do
   local settings=actor.settings
   local cycle=settings.rest+settings.warning+2*settings.move+settings.open+settings.closingWarning
   local at=(clock+settings.phase)%cycle;local farAt=settings.rest+settings.warning+settings.move
   local remaining=if at>=farAt and at<farAt+settings.open+settings.closingWarning then farAt+settings.open+settings.closingWarning-at else 0
   local alpha,predicted=actor.sample("Tail",settings,clock)
   table.insert(actors,{name=actor.model.Name,state=actor.model:GetAttribute("ERState"),predictedState=predicted,alpha=alpha,cycleAt=at,farWindowRemaining=remaining,pivot=frame(actor.model:GetPivot())})
  end
  local localPositions={}
  for _,part in parts do localPositions[part.Name]=vector(part.CFrame:PointToObjectSpace(root.Position)) end
  local rig={}
  for _,body in bodies do table.insert(rig,{name=body.Name,frame=frame(root.CFrame:ToObjectSpace(body.CFrame))}) end
  local footFrames={}
  for _,foot in feet do table.insert(footFrames,{name=foot.Name,position=vector(foot.Position),bottom=bottom(foot)}) end
  return {reason=reason,seconds=os.clock()-began,dt=dt,serverTime=Workspace:GetServerTimeNow(),clock=clock,step=report.lastProgress and report.lastProgress.step,
   root=frame(root.CFrame),velocity=vector(root.AssemblyLinearVelocity),moveDirection=vector(humanoid.MoveDirection),jump=humanoid.Jump,
   state=humanoid:GetState().Name,floor=humanoid.FloorMaterial.Name,support=support and support:GetFullName(),supportPosition=hit and vector(hit.Position),
   localPositions=localPositions,collider=frame(root.CFrame:ToObjectSpace(collider.CFrame)),feet=footFrames,rig=rig,
   actors=actors,sweepOverlaps=contacts,sceneryOverlaps=sceneryContacts(),result=result(),recoveryUntil=character:GetAttribute("RecoveryUntil") or 0,
   runtimeRecoveryAttempts=diagnostics.stats and diagnostics.stats.recoveryAttempts,runtimeRecoveries=diagnostics.stats and diagnostics.stats.recoveries}
 end
 local ok,failure=xpcall(function()
  assert(course:GetAttribute("CourseId")=="egg_rush_circuit" and course:GetAttribute("CandidateId")==expectedCandidate and course:GetAttribute("Phase")==3 and course:GetAttribute("FullBodyContacts")==true,"Expected actual full-body Phase3 candidate")
  local world=assert(course.Decoration:FindFirstChild("HatcheryWorld"),"Current hatchery world missing")
  local worldParts=0
  for _,item in world:GetDescendants() do if item:IsA("BasePart") then worldParts+=1 end end
  report.identity={candidate=course:GetAttribute("CandidateId"),worldBuild=world:GetAttribute("ERPhase3Build"),worldParts=worldParts,fullBodyContacts=course:GetAttribute("FullBodyContacts")}
  assert(initial.nextCheckpoint~=4,"Starting on CP4 would award the next checkpoint; use a different race state")
  assert(initialRecovery<=Workspace:GetServerTimeNow(),"Wait for existing recovery immunity to expire")
  assert(runtimeBefore.bound and runtimeBefore.elapsed and runtimeBefore.stats,"Bound live mechanism clock and recovery counters required")
  guard()
  local beforeSupport=standing()
  report.beforeSetup={root=frame(root.CFrame),support=beforeSupport and beforeSupport:GetFullName(),floor=humanoid.FloorMaterial.Name}
  local traversal=require(game.ServerStorage.CourseBuilders.EggRush.NativeTraversal)
  local all=traversal.Points(course,"Normal");local points={}
  for _,point in all do if table.find(PART_NAMES,point.part.Name) then table.insert(points,table.clone(point));table.insert(parts,point.part) end end
  assert(#points==5,"Five current incoming Return route references required")
  report.route={}
  for index,point in points do
   assert(point.part.Name==PART_NAMES[index],"Incoming Return route order changed")
   table.insert(report.route,{name=point.part.Name,path=point.part:GetFullName(),frame=frame(point.part.CFrame),size=vector(point.part.Size),canCollide=point.part.CanCollide,canQuery=point.part.CanQuery})
  end
  local sample=require(game.ServerStorage.CourseBuilders.EggRush.Runtime).Sample
  report.sweeps={}
  for _,name in SWEEP_NAMES do
   local model=assert(course.Obstacles.Mechanisms:FindFirstChild(name),"Current Return sweep missing")
   assert(model:GetAttribute("ERMechanism")=="Tail","Expected live Return sweep")
   local settings={rest=model:GetAttribute("RestSeconds"),warning=model:GetAttribute("WarningSeconds"),move=model:GetAttribute("MoveSeconds"),open=model:GetAttribute("FarWaitSeconds"),closingWarning=model:GetAttribute("ClosingWarningSeconds"),phase=model:GetAttribute("PhaseSeconds") or 0}
   table.insert(models,{model=model,settings=settings,sample=sample})
   local record={name=name,settings=settings,lethalParts={}}
   for _,part in model:GetDescendants() do
    if part:IsA("BasePart") and part:GetAttribute("ERLethal")==true then
     table.insert(redParts,part);redOwners[part]=name
     table.insert(record.lethalParts,{path=part:GetFullName(),size=vector(part.Size),frame=frame(model:GetPivot():ToObjectSpace(part.CFrame)),canQuery=part.CanQuery,transparency=part.Transparency})
    end
   end
   assert(#record.lethalParts>0,"Return sweep has no live contact parts")
   table.insert(report.sweeps,record)
  end
  report.rigDefinition={collider={size=vector(collider.Size),canCollide=collider.CanCollide,canQuery=collider.CanQuery},bodies={}}
  for _,part in character:GetChildren() do
   if part:IsA("BasePart") and BODY_NAMES[part.Name] and part.Transparency<1 and part.CanQuery then
    table.insert(bodies,part)
    table.insert(report.rigDefinition.bodies,{name=part.Name,size=vector(part.Size),canQuery=part.CanQuery,canCollide=part.CanCollide})
    if part.Name=="LeftFoot" or part.Name=="RightFoot" or part.Name=="Left Leg" or part.Name=="Right Leg" then table.insert(feet,part) end
   end
  end
  assert(#bodies>0 and #feet>0,"Visible queryable real body and feet required")
  hazardOverlap.FilterDescendantsInstances=bodies
  sceneryOverlap.FilterDescendantsInstances={world}
  for _,zone in services.CourseService.GetFallZones() do
   if zone:IsA("BasePart") then
    table.insert(fallConnections,zone.Touched:Connect(function(body)
     if body:IsDescendantOf(character) then
      table.insert(report.fallTouches,{seconds=os.clock()-began,zone=zone:GetFullName(),body=body.Name,root=vector(root.Position),result=result(),recoveryUntil=character:GetAttribute("RecoveryUntil") or 0})
     end
    end))
   end
  end
  local prefix="[RespawnService] Respawned "..player.Name.." after "
  local logConnection=LogService.MessageOut:Connect(function(message)
   if string.find(message,prefix,1,true) then table.insert(report.recoveryMessages,{seconds=os.clock()-began,message=message}) end
  end)
  table.insert(fallConnections,logConnection)
  local first=points[1].part;local ground=first.Position+first.CFrame.UpVector*first.Size.Y/2
  local at=ground+Vector3.yAxis*(humanoid.HipHeight+root.Size.Y/2+.15)
  root:SetNetworkOwner(nil)
  character:PivotTo(CFrame.new(at)*root.CFrame:ToObjectSpace(character:GetPivot()))
  root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
  table.insert(report.placements,{part=first:GetFullName(),rootTarget=vector(at),reason="Declared focused setup at CP4"})
  local setupDeadline=os.clock()+3;local stableSince
  repeat
   RunService.Heartbeat:Wait();guard()
   if standing()==first and humanoid.FloorMaterial~=Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y)<2 then stableSince=stableSince or os.clock() else stableSince=nil end
  until (stableSince and os.clock()-stableSince>=.12) or os.clock()>setupDeadline
  assert(stableSince and os.clock()-stableSince>=.12,"Declared CP4 setup never settled with support")
  report.setup=snapshot("supported setup",nil,hazardContacts(),services.EggRushService.GetDiagnostics())
  assert(#report.setup.sweepOverlaps==0,"Visible body overlapped a Return sweep at setup")
  observer=RunService.PostSimulation:Connect(function(dt)
   local observed,message=xpcall(function()
    report.sampling.physicsFramesChecked+=1;report.sampling.maxPhysicsDelta=math.max(report.sampling.maxPhysicsDelta,dt)
    local contacts=hazardContacts()
    if #contacts>0 then report.sampling.overlapFrames+=1 end
    local diagnostics=services.EggRushService.GetDiagnostics()
    assert(diagnostics.bound and diagnostics.elapsed and diagnostics.stats,"Live mechanism observation stopped")
    local current=result();local recovery=character:GetAttribute("RecoveryUntil") or 0;local support=standing()
    local step=report.lastProgress and report.lastProgress.step
    local key=table.concat({step or "setup",support and support:GetFullName() or "air",models[1].model:GetAttribute("ERState") or "?",models[2].model:GetAttribute("ERState") or "?",tostring(current.falls),tostring(recovery)},"|")
    local changed=key~=lastKey;local incoming=step==INCOMING_STEP
    if incoming then report.sampling.incomingFramesChecked+=1 end
    if incoming or os.clock()-lastSample>=.12 or changed or #contacts>0 then
     lastKey=key;lastSample=os.clock()
     table.insert(report.trace,snapshot(if #contacts>0 then "overlap" elseif incoming then "incoming frame" elseif changed then "transition" else "sample",dt,contacts,diagnostics))
     if incoming then report.sampling.incomingFramesSaved+=1 end
    end
   end,debug.traceback)
   if not observed then observerFailure=tostring(message) end
  end)
  report.driver=traversal.Run(course,player,points,{placeAtStart=false,guard=guard,afterLanding=function(_,point,record)
   guard();table.insert(report.landings,{part=point.part.Name,record=record,body=snapshot("landing",nil,hazardContacts(),services.EggRushService.GetDiagnostics())})
   assert(#report.landings[#report.landings].body.sweepOverlaps==0,"Visible body overlapped a Return sweep at landing")
  end},function(index,total,step) report.lastProgress={index=index,total=total-1,step=step} end)
  assert(report.driver.ok,report.driver.failure)
  guard()
  assert(report.driver.jumps==4 and #report.landings==4 and #report.placements==1,"Four jumps and one declared CP4 setup required")
  for index,landing in report.landings do assert(landing.part==PART_NAMES[index+1],"Unexpected supported landing order") end
  assert(#report.driver.supportedWalks==1 and report.driver.supportedWalks[1].supportedThroughout,"Supported 002 north hold walk required")
  for _,name in SWEEP_NAMES do
   local found=false
   for _,receipt in report.driver.windowTrace do if receipt.model==name and receipt.entryClock then found=true end end
   assert(found,"Missing actual sweep admission: "..name)
  end
  local heldThroughReturn=false
  for _,observation in report.trace do
   if observation.support==points[3].part:GetFullName() and observation.step=="S6_ShellSpill_002 -> S6_ShellSpill_003" then
    for _,actor in observation.actors do if actor.name=="ReturnFeatherSwing" and actor.state=="Returning" then heldThroughReturn=true end end
   end
  end
  report.heldThroughFeatherReturn=heldThroughReturn
  assert(heldThroughReturn,"No supported observation on 002 while the feather returned")
  assert(report.sampling.incomingFramesChecked>0 and report.sampling.incomingFramesSaved==report.sampling.incomingFramesChecked,"Missing incoming physics frames")
  assert(report.sampling.overlapFrames==0 and #hazardContacts()==0,"Visible body overlapped a Return sweep")
  local final=result()
  assert(final.lap==initial.lap and final.nextCheckpoint==initial.nextCheckpoint and final.splits==initial.splits and #final.lapTimes==#initial.lapTimes,"Focused attempt changed actual progression")
  for index,lapTime in initial.lapTimes do assert(final.lapTimes[index]==lapTime,"Existing lap time changed") end
  local stats=services.EggRushService.GetDiagnostics().stats
  assert(stats.recoveryAttempts==runtimeBefore.stats.recoveryAttempts and stats.recoveries==runtimeBefore.stats.recoveries,"Runtime recorded a hazard recovery attempt")
  report.complete=true
 end,debug.traceback)
 if observer then observer:Disconnect() end
 for _,connection in fallConnections do connection:Disconnect() end
 humanoid:Move(Vector3.zero,false);humanoid.Jump=false
 if root.Parent then if originalAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(originalOwner) end end
 report.ok=ok and observerFailure==nil
 report.failure=if ok then observerFailure else tostring(failure)
 report.seconds=os.clock()-began
 report.runtimeAfter=services.EggRushService.GetDiagnostics()
 local gotFinal,final=pcall(result)
 if gotFinal then report.finalResult=final else report.finalResultFailure=tostring(final) end
 report.finalRecoveryUntil=character:GetAttribute("RecoveryUntil") or 0
 if #models==2 and report.runtimeAfter.bound and report.runtimeAfter.elapsed and report.runtimeAfter.stats then
  local captured,observation=pcall(function() return snapshot("final",nil,hazardContacts(),report.runtimeAfter) end)
  if captured then report.finalObservation=observation end
 end
 if gotFinal and report.runtimeAfter.stats and runtimeBefore.stats then
  report.recoveryDelta={attempts=report.runtimeAfter.stats.recoveryAttempts-runtimeBefore.stats.recoveryAttempts,recoveries=report.runtimeAfter.stats.recoveries-runtimeBefore.stats.recoveries,falls=report.finalResult.falls-initial.falls}
 end
 report.cleanup="Observation and server movement stopped; original ownership restored; no return placement"
 return report
end

return Test
