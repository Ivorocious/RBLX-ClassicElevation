--!nonstrict
local Test = {}
local RunService, Players, Workspace = game:GetService("RunService"), game:GetService("Players"), game:GetService("Workspace")
local BODY_NAMES = {Head=true,Torso=true,UpperTorso=true,LowerTorso=true,["Left Arm"]=true,["Right Arm"]=true,["Left Leg"]=true,["Right Leg"]=true,LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,RightUpperArm=true,RightLowerArm=true,RightHand=true,LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,RightUpperLeg=true,RightLowerLeg=true,RightFoot=true}
local PART_NAMES = {"S6_ShellSpill_001", "S6_ShellSpill_002", "S6_ShellSpill_003", "S6_ShellSpill_004"}
local SWEEP_NAMES = {"ReturnFeatherSwing", "ReturnFeederSweep"}
local function vector(v) return {v.X, v.Y, v.Z} end
local function frame(cf) return {cf:GetComponents()} end

function Test.Run(expectedCandidate)
 expectedCandidate = expectedCandidate or "ER_P3_W06_C02"
 assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819, "Owned Studio server required")
 local services = {}
 for _, name in {"CourseService", "RaceService", "PlayerRaceService", "ResultsService", "EggRushService"} do
  services[name] = require(game.ServerScriptService.Services[name])
 end
 local player = assert(Players:GetPlayers()[1], "Actual racer missing")
 assert(#Players:GetPlayers() == 1, "One isolated actual client required")
 local course, character = assert(services.CourseService.GetActiveCourse()), assert(player.Character)
 local root, humanoid = assert(character:FindFirstChild("HumanoidRootPart")), assert(character:FindFirstChildOfClass("Humanoid"))
 local collider = assert(character:FindFirstChild("CollisionPart")); local colliderSize = collider.Size
 local raceId, began = services.RaceService.GetCurrentRaceId(), os.clock()
 local originalOwner, originalAuto = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto()
 local observer, observerFailure, lastSample, lastKey = nil, nil, -math.huge, nil
 local parts, models, redParts, redOwners, bodies = {}, {}, {}, {}, {}
 local report = {
  candidateExpected=expectedCandidate, userId=player.UserId, raceId=raceId, placements={}, landings={}, trace={},
  progressWrites=0, clockWrites=0, profileWrites=0, immunityWrites=0, geometryWrites=0,
  sampling={periodSeconds=.12, physicsFramesChecked=0, overlapFrames=0, maxPhysicsDelta=0},
  method="One declared placement on S6_001 followed by the current Normal driver through 002, 003 and 004 with live contacts and unchanged timing",
  limits="One scripted racer and one setup; not ordinary entry, a full lap, human, crowd, device or performance proof. Instantaneous overlap samples do not replace runtime substep contact checks.",
 }
 local function result()
  local value = assert(services.ResultsService.GetPlayerResult(player))
  return {lap=value.currentLap, nextCheckpoint=value.nextCheckpointIndex, falls=value.falls or 0,
   lapTimes=table.clone(value.lapTimes or {}), splits=#(value.checkpointSplits or {}), status=services.PlayerRaceService.GetPlayerStatus(player)}
 end
 local initial = result()
 local initialRecovery = character:GetAttribute("RecoveryUntil") or 0
 local runtimeBefore = services.EggRushService.GetDiagnostics()
 report.initialResult, report.initialRecoveryUntil = initial, initialRecovery
 report.runtimeBefore = runtimeBefore
 local function guard()
  assert(not observerFailure, observerFailure)
  assert(os.clock()-began < 45 and player.Character == character and root.Parent and humanoid.Parent and humanoid.Health > 0, "Bounded original character changed")
  assert(services.CourseService.GetActiveCourse() == course and services.RaceService.GetCurrentRaceId() == raceId, "Course or race changed")
  assert(services.RaceService.IsRaceActive() and services.PlayerRaceService.IsOfficialRacer(player) and services.PlayerRaceService.GetPlayerStatus(player) == "Racing", "Actual eligible Racing participant required")
  assert(not services.CourseService.IsInspectionMode() and not services.RaceService.IsInspectionUnlimitedTime(), "No inspection override or immunity")
  assert(not root.Anchored and humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.01 and math.abs(Workspace.Gravity-196.2)<.01, "Ordinary movement required")
  local runtime=services.EggRushService.GetDiagnostics()
  assert(collider.Parent == character and collider.CanCollide and (collider.Size-colliderSize).Magnitude<.02 and runtime.bound and not runtime.holding and runtime.raceId==raceId, "Fitted body or live runtime changed")
  assert(result().falls == initial.falls and (character:GetAttribute("RecoveryUntil") or 0) <= initialRecovery+.01, "Actual recovery; stop the focused attempt")
  return true
 end
 local ray = RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Include; ray.FilterDescendantsInstances={course}; ray.RespectCanCollide=true
 local overlap = OverlapParams.new(); overlap.FilterType=Enum.RaycastFilterType.Include; overlap.RespectCanCollide=false
 local function standing()
  local hit=Workspace:Raycast(root.Position,Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.7),0),ray)
  return hit and hit.Instance, hit
 end
 local function rig()
  local value={}
  for _, body in bodies do
   table.insert(value,{name=body.Name, frame=frame(root.CFrame:ToObjectSpace(body.CFrame)), size=vector(body.Size), visible=body.Transparency<1, canQuery=body.CanQuery})
  end
  return value
 end
 local function contactsNow()
  local contacts={}
  for _, red in redParts do
   if red.Transparency<1 then
    for _, body in Workspace:GetPartsInPart(red,overlap) do table.insert(contacts,{actor=redOwners[red],part=red.Name,body=body.Name}) end
   end
  end
  return contacts
 end
 local function snapshot(reason, contacts, diagnostics)
  local support, hit = standing()
  local actors={}
  local clock=diagnostics.elapsed
  for _, actor in models do
   local settings=actor.settings
   local cycle=settings.rest+settings.warning+2*settings.move+settings.open+settings.closingWarning
   local at=(clock+settings.phase)%cycle
   local farAt=settings.rest+settings.warning+settings.move
   local remaining=if at>=farAt and at<farAt+settings.open+settings.closingWarning then farAt+settings.open+settings.closingWarning-at else 0
   local alpha, predicted=actor.sample("Tail",settings,clock)
   table.insert(actors,{name=actor.model.Name,state=actor.model:GetAttribute("ERState"),predictedState=predicted,alpha=alpha,cycleAt=at,farWindowRemaining=remaining,pivot=frame(actor.model:GetPivot())})
  end
  local localPositions={}
  for _, part in parts do localPositions[part.Name]=vector(part.CFrame:PointToObjectSpace(root.Position)) end
  return {reason=reason,seconds=os.clock()-began,serverTime=Workspace:GetServerTimeNow(),clock=clock,step=report.lastProgress and report.lastProgress.step,
   root=frame(root.CFrame),velocity=vector(root.AssemblyLinearVelocity),moveDirection=vector(humanoid.MoveDirection),jump=humanoid.Jump,
   state=humanoid:GetState().Name,floor=humanoid.FloorMaterial.Name,support=support and support:GetFullName(),
   supportPosition=hit and vector(hit.Position),localPositions=localPositions,collider=frame(root.CFrame:ToObjectSpace(collider.CFrame)),rig=rig(),
   actors=actors,sweepOverlaps=contacts,result=result(),recoveryUntil=character:GetAttribute("RecoveryUntil") or 0,
   runtimeRecoveryAttempts=diagnostics.stats and diagnostics.stats.recoveryAttempts,runtimeRecoveries=diagnostics.stats and diagnostics.stats.recoveries}
 end
 local ok, failure=xpcall(function()
  assert(course:GetAttribute("CourseId")=="egg_rush_circuit" and course:GetAttribute("CandidateId")==expectedCandidate and course:GetAttribute("Phase")==3 and course:GetAttribute("FullBodyContacts")==true, "Expected actual full-body Phase3 candidate")
  local world=assert(course.Decoration:FindFirstChild("HatcheryWorld"), "Current hatchery world missing")
  local worldParts=0
  for _, item in world:GetDescendants() do if item:IsA("BasePart") then worldParts+=1 end end
  report.identity={candidate=course:GetAttribute("CandidateId"),worldBuild=world:GetAttribute("ERPhase3Build"),worldParts=worldParts,fullBodyContacts=course:GetAttribute("FullBodyContacts")}
  assert(worldParts==907, "Current C02 world must have 907 parts")
  assert(initialRecovery<=Workspace:GetServerTimeNow(), "Wait for existing recovery immunity to expire")
  assert(runtimeBefore.bound and runtimeBefore.elapsed and runtimeBefore.stats, "Bound live mechanism clock and recovery counters required")
  guard()
  local beforeSupport=standing()
  report.beforeSetup={root=frame(root.CFrame),support=beforeSupport and beforeSupport:GetFullName(),floor=humanoid.FloorMaterial.Name}
  local traversal=require(game.ServerStorage.CourseBuilders.EggRush.NativeTraversal)
  local all=traversal.Points(course,"Normal"); local points={}
  for _, point in all do if table.find(PART_NAMES,point.part.Name) then table.insert(points,table.clone(point));table.insert(parts,point.part) end end
  assert(#points==4, "Four current Return route references required")
  report.route={}
  for index, point in points do
   assert(point.part.Name==PART_NAMES[index], "Return route order changed")
   table.insert(report.route,{name=point.part.Name,path=point.part:GetFullName(),frame=frame(point.part.CFrame),size=vector(point.part.Size),canCollide=point.part.CanCollide,canQuery=point.part.CanQuery})
  end
  local sample=require(game.ServerStorage.CourseBuilders.EggRush.Runtime).Sample
  report.sweeps={}
  for _, name in SWEEP_NAMES do
   local model=assert(course.Obstacles.Mechanisms:FindFirstChild(name), "Current Return sweep missing")
   assert(model:GetAttribute("ERMechanism")=="Tail", "Expected live Return sweep")
   local settings={rest=model:GetAttribute("RestSeconds"),warning=model:GetAttribute("WarningSeconds"),move=model:GetAttribute("MoveSeconds"),open=model:GetAttribute("FarWaitSeconds"),closingWarning=model:GetAttribute("ClosingWarningSeconds"),phase=model:GetAttribute("PhaseSeconds") or 0}
   local actor={model=model,settings=settings,sample=sample};table.insert(models,actor)
   local record={name=name,settings=settings,lethalParts={}}
   for _, part in model:GetDescendants() do
    if part:IsA("BasePart") and part:GetAttribute("ERLethal")==true then
     table.insert(redParts,part);redOwners[part]=name
     table.insert(record.lethalParts,{path=part:GetFullName(),size=vector(part.Size),frame=frame(model:GetPivot():ToObjectSpace(part.CFrame)),canQuery=part.CanQuery,transparency=part.Transparency})
    end
   end
   assert(#record.lethalParts>0, "Return sweep has no live contact parts")
   table.insert(report.sweeps,record)
  end
  for _, part in character:GetChildren() do
   if part:IsA("BasePart") and BODY_NAMES[part.Name] and part.Transparency<1 and part.CanQuery then table.insert(bodies,part) end
  end
  assert(#bodies>0, "Visible queryable real body missing")
  overlap.FilterDescendantsInstances=bodies
  observer=RunService.PostSimulation:Connect(function(dt)
   local observed, message=xpcall(function()
    report.sampling.physicsFramesChecked+=1;report.sampling.maxPhysicsDelta=math.max(report.sampling.maxPhysicsDelta,dt)
    local contacts=contactsNow()
    if #contacts>0 then report.sampling.overlapFrames+=1 end
    local diagnostics=services.EggRushService.GetDiagnostics()
    assert(diagnostics.bound and diagnostics.elapsed and diagnostics.stats,"Live mechanism observation stopped")
    local current=result();local recovery=character:GetAttribute("RecoveryUntil") or 0
    local support=standing()
    local key=table.concat({report.lastProgress and report.lastProgress.step or "setup",support and support:GetFullName() or "air",models[1].model:GetAttribute("ERState") or "?",models[2].model:GetAttribute("ERState") or "?",tostring(current.falls),tostring(recovery)},"|")
    local changed=key~=lastKey
    if os.clock()-lastSample>=.12 or changed or #contacts>0 then
     lastKey=key;lastSample=os.clock()
     table.insert(report.trace,snapshot(if #contacts>0 then "overlap" elseif changed then "transition" else "sample",contacts,diagnostics))
    end
   end,debug.traceback)
   if not observed then observerFailure=tostring(message) end
  end)
  local first=points[1].part
  local ground=first.Position+first.CFrame.UpVector*first.Size.Y/2
  local at=ground+Vector3.yAxis*(humanoid.HipHeight+root.Size.Y/2+.15)
  root:SetNetworkOwner(nil)
  character:PivotTo(CFrame.new(at)*root.CFrame:ToObjectSpace(character:GetPivot()))
  root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
  table.insert(report.placements,{part=first:GetFullName(),rootTarget=vector(at),reason="Declared focused setup"})
  local setupDeadline=os.clock()+3;local stableSince
  repeat
   RunService.Heartbeat:Wait();guard()
   local support=standing()
   if support==first and humanoid.FloorMaterial~=Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y)<2 then stableSince=stableSince or os.clock() else stableSince=nil end
  until (stableSince and os.clock()-stableSince>=.12) or os.clock()>setupDeadline
  assert(stableSince and os.clock()-stableSince>=.12,"Declared setup never settled with support on 001")
  report.setup=snapshot("supported setup",contactsNow(),services.EggRushService.GetDiagnostics())
  assert(#report.setup.sweepOverlaps==0,"Visible body overlapped a Return sweep at setup")
  report.driver=traversal.Run(course,player,points,{placeAtStart=false,guard=guard,afterLanding=function(_,point,record)
   guard();table.insert(report.landings,{part=point.part.Name,record=record,body=snapshot("landing",contactsNow(),services.EggRushService.GetDiagnostics())})
   assert(#report.landings[#report.landings].body.sweepOverlaps==0,"Visible body overlapped a Return sweep at landing")
  end},function(index,total,step) report.lastProgress={index=index,total=total-1,step=step} end)
  assert(report.driver.ok, report.driver.failure)
  guard()
  assert(report.driver.jumps==3 and #report.landings==3 and #report.placements==1,"All three jumps and one declared setup required")
  for index, landing in report.landings do assert(landing.part==PART_NAMES[index+1],"Unexpected supported landing order") end
  assert(#report.driver.supportedWalks==1 and report.driver.supportedWalks[1].supportedThroughout,"Supported 002 north hold walk required")
  for _, name in SWEEP_NAMES do
   local found=false
   for _, receipt in report.driver.windowTrace do if receipt.model==name and receipt.entryClock then found=true end end
   assert(found,"Missing actual sweep admission: "..name)
  end
  local heldThroughReturn=false
  for _, observation in report.trace do
   if observation.support==points[2].part:GetFullName() and observation.step=="S6_ShellSpill_002 -> S6_ShellSpill_003" then
    for _, actor in observation.actors do if actor.name=="ReturnFeatherSwing" and actor.state=="Returning" then heldThroughReturn=true end end
   end
  end
  report.heldThroughFeatherReturn=heldThroughReturn
  assert(heldThroughReturn,"No supported observation on 002 while the feather returned")
  assert(report.sampling.overlapFrames==0,"Visible body overlapped a Return sweep in a physics sample")
  assert(#contactsNow()==0,"Visible body overlapped a Return sweep at completion")
  local final=result()
  assert(final.lap==initial.lap and final.nextCheckpoint==initial.nextCheckpoint and final.splits==initial.splits and #final.lapTimes==#initial.lapTimes,"Focused attempt changed actual progression")
  for index, lapTime in initial.lapTimes do assert(final.lapTimes[index]==lapTime,"Existing lap time changed") end
  local stats=services.EggRushService.GetDiagnostics().stats
  assert(stats.recoveryAttempts==runtimeBefore.stats.recoveryAttempts and stats.recoveries==runtimeBefore.stats.recoveries,"Runtime recorded a hazard recovery attempt")
  report.complete=true
 end,debug.traceback)
 if observer then observer:Disconnect() end
 humanoid:Move(Vector3.zero,false);humanoid.Jump=false
 if root.Parent then if originalAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(originalOwner) end end
 report.ok=ok and observerFailure==nil
 report.failure=if ok then observerFailure else tostring(failure)
 report.seconds=os.clock()-began
 report.runtimeAfter=services.EggRushService.GetDiagnostics()
 report.finalResult=result()
 report.finalRecoveryUntil=character:GetAttribute("RecoveryUntil") or 0
 if #models==2 and report.runtimeAfter.bound and report.runtimeAfter.elapsed and report.runtimeAfter.stats then
  local captured, observation=pcall(function() return snapshot("final",contactsNow(),report.runtimeAfter) end)
  if captured then report.finalObservation=observation end
 end
 if report.runtimeAfter.stats and runtimeBefore.stats then
  report.recoveryDelta={attempts=report.runtimeAfter.stats.recoveryAttempts-runtimeBefore.stats.recoveryAttempts,recoveries=report.runtimeAfter.stats.recoveries-runtimeBefore.stats.recoveries,falls=report.finalResult.falls-initial.falls}
 end
 report.cleanup="Observation and server movement stopped; original ownership restored; no return placement"
 return report
end
return Test
