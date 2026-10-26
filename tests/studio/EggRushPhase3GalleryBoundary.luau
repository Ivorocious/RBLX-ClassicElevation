--!nonstrict
local Test={}
local RunService,Players,Workspace=game:GetService("RunService"),game:GetService("Players"),game:GetService("Workspace")
local BODY_NAMES={Head=true,Torso=true,UpperTorso=true,LowerTorso=true,["Left Arm"]=true,["Right Arm"]=true,["Left Leg"]=true,["Right Leg"]=true,LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,RightUpperArm=true,RightLowerArm=true,RightHand=true,LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,RightUpperLeg=true,RightLowerLeg=true,RightFoot=true}
local function vector(v)return{v.X,v.Y,v.Z}end
local function half(frame,size)
 return Vector3.new(math.abs(frame.RightVector.X)*size.X+math.abs(frame.UpVector.X)*size.Y+math.abs(frame.LookVector.X)*size.Z,math.abs(frame.RightVector.Y)*size.X+math.abs(frame.UpVector.Y)*size.Y+math.abs(frame.LookVector.Y)*size.Z,math.abs(frame.RightVector.Z)*size.X+math.abs(frame.UpVector.Z)*size.Y+math.abs(frame.LookVector.Z)*size.Z)/2
end
function Test.Run(expectedCandidate)
 assert(RunService:IsStudio()and RunService:IsServer()and game.PlaceId==85558151074819,"Owned Studio server required")
 local services={}
 for _,name in {"CourseService","RaceService","PlayerRaceService","CheckpointService","ResultsService","EggRushService"}do services[name]=require(game.ServerScriptService.Services[name])end
 local player=assert(Players:GetPlayers()[1]);assert(#Players:GetPlayers()==1,"One isolated actual client required")
 local course,character=assert(services.CourseService.GetActiveCourse()),assert(player.Character)
 local root,humanoid=assert(character:FindFirstChild("HumanoidRootPart")),assert(character:FindFirstChildOfClass("Humanoid"))
 local collider=assert(character:FindFirstChild("CollisionPart"));local colliderSize=collider.Size
 local owner,ownerAuto=root:GetNetworkOwner(),root:GetNetworkOwnershipAuto()
 local raceId,began=services.RaceService.GetCurrentRaceId(),os.clock()
 local movement,jump,launched=Vector3.zero,false,false
 local controller,observer,fallConnection,observerFailure=nil,nil,nil,nil
 local report={candidate=expectedCandidate,userId=player.UserId,raceId=raceId,placements={},trace={},wallSamples={},fallTouches={},floorOverlaps={},gallerySupports={},progressWrites=0,clockWrites=0,profileWrites=0,geometryWrites=0,immunityWrites=0,stage="WaitingOnStart",method="One declared S6_004 setup after a real far-pose wait, ordinary +Z jump from S6_004 center before its existing grate toward the corrected visible gallery boundary, then actual fall recovery",limits="One scripted gallery side-fall; not a whole route, arbitrary arrival, human camera or multiplayer proof"}
 local function result()
  local value=assert(services.ResultsService.GetPlayerResult(player))
  return{lap=value.currentLap,nextCheckpoint=value.nextCheckpointIndex,falls=value.falls or 0,lapTimes=table.clone(value.lapTimes or{}),splits=#(value.checkpointSplits or{}),latest=services.CheckpointService.GetLatestCheckpointIndex(player)}
 end
 local initial=result();local initialRecovery=character:GetAttribute("RecoveryUntil")or 0
 local initialRuntime=services.EggRushService.GetDiagnostics()
 report.runtimeBefore=initialRuntime;report.grateContacts={}
 local function guard()
  assert(not observerFailure,observerFailure)
  assert(os.clock()-began<45 and player.Character==character and humanoid.Health>0,"Bounded original character changed")
  assert(services.CourseService.GetActiveCourse()==course and services.RaceService.GetCurrentRaceId()==raceId,"Actual course/race changed")
  assert(services.RaceService.IsRaceActive()and services.PlayerRaceService.IsOfficialRacer(player)and services.PlayerRaceService.GetPlayerStatus(player)=="Racing","Actual eligible Racing participant required")
  assert(not services.CourseService.IsInspectionMode()and not services.RaceService.IsInspectionUnlimitedTime(),"No inspection override or immunity")
  assert(not root.Anchored and humanoid.WalkSpeed==16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.01 and math.abs(Workspace.Gravity-196.2)<.01,"Accepted ordinary movement required")
  assert(collider.CanCollide and(collider.Size-colliderSize).Magnitude<.02 and services.EggRushService.GetDiagnostics().bound,"Fitted body/current runtime changed")
  assert(result().falls<=initial.falls+1,"More than one actual recovery")
  return true
 end
 local function waitFor(predicate,seconds,message)
  local deadline=os.clock()+seconds
  repeat guard();if predicate()then return end;RunService.Heartbeat:Wait()until os.clock()>deadline
  error(message)
 end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={course};ray.RespectCanCollide=true
 local function support()
  local hit=Workspace:Raycast(root.Position,Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.7),0),ray)
  return hit and hit.Instance
 end
 local function snapshot()
  local rig={}
  for _,part in character:GetChildren()do if part:IsA("BasePart")and(BODY_NAMES[part.Name]or part==root or part==collider)then
   table.insert(rig,{name=part.Name,size=vector(part.Size),frame={root.CFrame:ToObjectSpace(part.CFrame):GetComponents()},bodyContact=BODY_NAMES[part.Name]==true,visible=part.Transparency<1,canQuery=part.CanQuery,canCollide=part.CanCollide})
  end end
  return{seconds=os.clock()-began,root={root.CFrame:GetComponents()},velocity=vector(root.AssemblyLinearVelocity),floor=tostring(humanoid.FloorMaterial),humanoidState=humanoid:GetState().Name,jumpRequested=humanoid.Jump,support=support()and support():GetFullName(),rig=rig,result=result(),stage=report.stage}
 end
 local ok,failure=xpcall(function()
  assert(course:GetAttribute("CourseId")=="egg_rush_circuit"and course:GetAttribute("CandidateId")==expectedCandidate and course:GetAttribute("FullBodyContacts")==true,"Expected corrected world candidate")
  assert(initialRecovery<=Workspace:GetServerTimeNow(),"Existing immunity must expire before this check")
  assert(support()==course.Start and humanoid.FloorMaterial~=Enum.Material.Air,"Begin physically supported on actual Start")
  assert(initialRuntime.bound and initialRuntime.stats,"Actual runtime diagnostics required")
  local pivot=course:GetPivot();local direction=pivot:VectorToWorldSpace(Vector3.zAxis)
  local world=assert(course.Decoration:FindFirstChild("HatcheryWorld"))
  local count=0;for _,part in world:GetDescendants()do if part:IsA("BasePart")then count+=1 end end
  report.worldParts=count
  assert(count==(script:GetAttribute("ExpectedWorldParts")or 982),"Expected inspected982-part set-back world")
  local gallery=assert(world.Nursery:FindFirstChild("FinishIntakeGallery"))
  local walls,floors={},{}
  local floorSet={}
  local function floor(part)
   assert(part and part:IsA("BasePart"),"Corrected visible floor/foundation part missing")
   if not floorSet[part]then floorSet[part]=true;table.insert(floors,part)end
  end
  local wallNames={RearWall=true,FrontLeftWall=true,FrontRightWall=true,FrontLintel=true,DoorRecessBack=true,DoorArch=true,DoorSpandrels=true}
  report.noncollidingTrim={}
  for _,part in gallery:GetChildren()do if part:IsA("BasePart")then
   local role=part:GetAttribute("ERWorldRole")
   if role=="BelowFallBoundaryFloor"or part.Name=="FloorUnderside"then
    assert(part.CanCollide and part.CanQuery,"Corrected gallery floor must match its actual solid role")
    floor(part)
   elseif role=="VisibleSolidBoundary"or wallNames[part.Name]or part.Name:match("^DoorJamb")or part.Name:match("^SidePier")or part.Name:match("^RecessedWindow")or part.Name:match("^WindowHead")then
    assert(part.CanCollide and part.CanQuery,"Visible gallery wall must be a real physical/queryable boundary: "..part.Name)
    table.insert(walls,part)
   elseif part.Name:match("^WindowSill")or part.Name=="Ceiling"or part.Name=="RoofDeck"or part.Name=="Cornice"then
    assert(not part.CanCollide,"Gallery trim must not create a catch ledge: "..part.Name)
    table.insert(report.noncollidingTrim,part.Name)
   end
  end end
  report.solidGalleryParts=#walls+1
  assert(report.solidGalleryParts==18 and world:GetAttribute("SolidGalleryBoundaryParts")==18,"Expected actual18-part gallery boundary including its lowered floor")
  floor(world.Nursery:FindFirstChild("GalleryFoundation_Collar"));floor(world.Nursery:FindFirstChild("GalleryFoundation_Stem"))
  assert(#walls>0 and #floors>=3,"Actual gallery wall/floor evidence required")
  local fall=assert(course.FallZones:FindFirstChild("FallZone_Main"))
  local fallTop=fall.Position.Y+half(fall.CFrame,fall.Size).Y
  report.fallTop=fallTop;report.geometry={}
  for _,part in floors do
   local top=part.Position.Y+half(part.CFrame,part.Size).Y
   assert(top<fallTop-1,"Every exposed gallery floor/collar/stem top must match the actual below-fall margin")
   table.insert(report.geometry,{path=part:GetFullName(),frame={part.CFrame:GetComponents()},size=vector(part.Size),role=part:GetAttribute("ERWorldRole"),top=top,collide=part.CanCollide,query=part.CanQuery})
  end
  local pad=assert(course.Obstacles.S6_ShellSpill:FindFirstChild("S6_ShellSpill_004"))
  local padLocal=pivot:PointToObjectSpace(pad.Position)
  local front=math.huge
  for _,part in walls do
   local frame=pivot:ToObjectSpace(part.CFrame);local extent=half(frame,part.Size)
   if math.abs(frame.Position.X-padLocal.X)<=extent.X+.1 then front=math.min(front,frame.Position.Z-extent.Z)end
   table.insert(report.geometry,{path=part:GetFullName(),frame={part.CFrame:GetComponents()},size=vector(part.Size),role=part:GetAttribute("ERWorldRole"),collide=part.CanCollide,query=part.CanQuery})
  end
  assert(front<math.huge and front>padLocal.Z,"Actual front plane on this gallery approach required")
  report.frontPlaneLocalZ=front
  local padFrame=pivot:ToObjectSpace(pad.CFrame)
  report.launchPadForwardEdgeLocalZ=padFrame.Position.Z+half(padFrame,pad.Size).Z
  report.galleryEdgeClearance=front-report.launchPadForwardEdgeLocalZ
  assert(report.galleryEdgeClearance>0,"Gallery must remain beyond the actual takeoff pad edge")
  local bodies={};for _,part in character:GetChildren()do if part:IsA("BasePart")and BODY_NAMES[part.Name]and part.Transparency<1 and part.CanQuery then table.insert(bodies,part)end end
  assert(#bodies>0,"Actual queryable visible body required")
  local bodyQuery=OverlapParams.new();bodyQuery.FilterType=Enum.RaycastFilterType.Include;bodyQuery.FilterDescendantsInstances=bodies;bodyQuery.RespectCanCollide=false
  local wallQuery=OverlapParams.new();wallQuery.FilterType=Enum.RaycastFilterType.Include;wallQuery.FilterDescendantsInstances=walls;wallQuery.RespectCanCollide=true
  local grate={}
  for _,part in course.Obstacles.ThemedHazards.ReturnHotGrate:GetDescendants()do if part:IsA("BasePart")and part:GetAttribute("ERLethal")==true then table.insert(grate,part)end end
  local lastTrace=0
  observer=RunService.PostSimulation:Connect(function()
   local observed,message=xpcall(function()
    local value=result()
    if value.falls>initial.falls then
     movement=Vector3.zero;jump=false
     if not report.firstRecovery then report.firstRecovery=snapshot();report.stage="Recovered"end
     return
    end
    if report.stage~="Driving"and report.stage~="Falling"then return end
    for _,part in grate do for _,body in Workspace:GetPartsInPart(part,bodyQuery)do
     table.insert(report.grateContacts,{part=part:GetFullName(),body=body.Name,seconds=os.clock()-began,root=vector(root.Position)})
    end end
    local localCollider=pivot:ToObjectSpace(collider.CFrame)
    local leading=localCollider.Position.Z+half(localCollider,collider.Size).Z
    local bodyLeading=-math.huge
    for _,body in bodies do
     local frame=pivot:ToObjectSpace(body.CFrame)
     bodyLeading=math.max(bodyLeading,frame.Position.Z+half(frame,body.Size).Z)
    end
    report.maximumLeadingLocalZ=math.max(report.maximumLeadingLocalZ or leading,leading)
    report.maximumVisibleBodyLeadingLocalZ=math.max(report.maximumVisibleBodyLeadingLocalZ or bodyLeading,bodyLeading)
    report.minimumWallGap=math.min(report.minimumWallGap or(front-leading),front-leading)
    report.minimumVisibleBodyWallGap=math.min(report.minimumVisibleBodyWallGap or(front-bodyLeading),front-bodyLeading)
    if not report.nearestWallSample or leading>report.nearestWallSample.leadingLocalZ then
     report.nearestWallSample={seconds=os.clock()-began,leadingLocalZ=leading,visibleBodyLeadingLocalZ=bodyLeading,gap=front-leading,root=vector(root.Position)}
    end
    assert(leading<=front+.3,"Collider entered the gallery front plane before actual recovery")
    local touched=Workspace:GetPartBoundsInBox(collider.CFrame,collider.Size+Vector3.one*.12,wallQuery)
    if #touched>0 then
     local names={};for _,part in touched do table.insert(names,part:GetFullName())end
     local sample={seconds=os.clock()-began,parts=names,leadingLocalZ=leading,gap=front-leading,velocityAlong=root.AssemblyLinearVelocity:Dot(direction),root=vector(root.Position)}
     table.insert(report.wallSamples,sample)
     assert(leading<=front+.3,"Collider passed through the visible front boundary")
     if math.abs(sample.velocityAlong)<1.5 then report.physicalStop=sample end
    end
    local standing=support()
    if standing and standing:IsDescendantOf(world)and humanoid.FloorMaterial~=Enum.Material.Air then
     table.insert(report.gallerySupports,{part=standing:GetFullName(),seconds=os.clock()-began});error("Actual support on new gallery scenery")
    end
    for _,part in floors do for _,body in Workspace:GetPartsInPart(part,bodyQuery)do
     table.insert(report.floorOverlaps,{part=part:GetFullName(),body=body.Name,seconds=os.clock()-began});error("Visible body reached the lowered floor/collar/stem before actual recovery")
    end end
    if os.clock()-lastTrace>=.05 or #touched>0 then
     lastTrace=os.clock();local sample=snapshot();sample.leadingLocalZ=leading;sample.visibleBodyLeadingLocalZ=bodyLeading;sample.wallGap=front-leading;table.insert(report.trace,sample)
     if #report.trace>48 then table.remove(report.trace,1)end
    end
   end,debug.traceback)
   if not observed then observerFailure=tostring(message);movement=Vector3.zero;jump=false end
  end)
  fallConnection=fall.Touched:Connect(function(part)
   if part:IsDescendantOf(character)then table.insert(report.fallTouches,{body=part.Name,seconds=os.clock()-began,source=fall:GetFullName()})end
  end)
  local feeder=course.Obstacles.Mechanisms.ReturnFeederSweep
  local function remaining()
   local rest,warning,move,far,closing=feeder:GetAttribute("RestSeconds"),feeder:GetAttribute("WarningSeconds"),feeder:GetAttribute("MoveSeconds"),feeder:GetAttribute("FarWaitSeconds"),feeder:GetAttribute("ClosingWarningSeconds")
   local clock=services.EggRushService.GetDiagnostics().elapsed
   local t=(clock+(feeder:GetAttribute("PhaseSeconds")or 0))%(rest+warning+move+far+closing+move)
   local at=rest+warning+move
   return if t>=at and t<at+far+closing then at+far+closing-t else 0
  end
  waitFor(function()assert(support()==course.Start,"Lost Start support while waiting");return feeder:GetAttribute("ERState")=="FarWait"and remaining()>=1.5 end,18,"Actual far parked pose did not offer1.5seconds including ReturnWarning")
  report.safeWindow={clock=services.EggRushService.GetDiagnostics().elapsed,state=feeder:GetAttribute("ERState"),remaining=remaining(),policy="Actual FarWait state plus unchanged ReturnWarning at the same far pose"}
  local expected=assert(services.CheckpointService.GetCheckpointRespawnCFrame(player))
  report.expectedRecovery={expected:GetComponents()}
  root:SetNetworkOwner(nil)
  local ground=pad.Position+pad.CFrame.UpVector*pad.Size.Y/2
  local at=ground+Vector3.yAxis*(humanoid.HipHeight+root.Size.Y/2+.15)
  character:PivotTo(CFrame.lookAt(at,at+direction)*root.CFrame:ToObjectSpace(character:GetPivot()))
  root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
  table.insert(report.placements,{part=pad:GetFullName(),rootTarget=vector(at),facing=vector(direction)})
  report.stage="Settling"
  local settled=os.clock()+.18
  waitFor(function()return os.clock()>=settled and humanoid.FloorMaterial~=Enum.Material.Air and support()==pad end,2,"Declared setup did not settle on actual S6_004")
  report.setup=snapshot();report.stage="Driving"
  movement=direction
  report.jumpStateEnabled=humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
  assert(report.jumpStateEnabled,"Ordinary Jumping state must already be enabled")
  controller=RunService.PreSimulation:Connect(function()
   if result().falls>initial.falls then movement=Vector3.zero;jump=false end
   humanoid:Move(movement,false)
   if not launched and movement.Magnitude>0 then
    launched=true;jump=true;humanoid.Jump=true
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    report.takeoff=snapshot()
   end
   humanoid.Jump=jump
  end)
  waitFor(function()
   assert(result().falls==initial.falls,"Actual recovery occurred before the requested jump became airborne")
   return launched and humanoid.FloorMaterial==Enum.Material.Air
  end,.65,"Ordinary center jump did not leave S6_004")
  report.airborne=snapshot()
  jump=false;report.stage="Falling"
  waitFor(function()return result().falls==initial.falls+1 end,6,"Actual fall service did not recover the gallery side-fall")
  movement=Vector3.zero;jump=false
  report.firstRecovery=report.firstRecovery or snapshot();report.stage="Recovered"
  assert(report.nearestWallSample,"Actual pre-recovery clearance samples required")
  if #report.wallSamples>0 then
   assert(report.physicalStop and report.maximumLeadingLocalZ<=front+.3,"Observed wall contact must still produce a physical stop before the front plane")
   report.boundaryResult="Actual wall contact stopped the collider before the front plane"
  else
   assert(report.minimumWallGap>.06 and report.minimumVisibleBodyWallGap>.06,"Uncontacted gallery must remain beyond both collider and visible body through the fall")
   report.boundaryResult="Set-back gallery was not reached before actual fall recovery"
  end
  assert(#report.gallerySupports==0 and #report.floorOverlaps==0,"No scenery landing or pre-recovery lowered-floor overlap allowed")
  assert(#report.fallTouches>0,"Actual FallZone_Main touch evidence required")
  local runtimeAfter=services.EggRushService.GetDiagnostics()
  assert(runtimeAfter.stats.recoveries==initialRuntime.stats.recoveries,"A moving/red hazard recovered this attempt instead of the fall plane")
  assert((root.Position-expected.Position).Magnitude<2,"Actual recovery did not arrive at the retained checkpoint frame")
  waitFor(function()return humanoid.FloorMaterial~=Enum.Material.Air end,2,"Actual recovery did not settle")
  local untilAt=os.clock()+2.25
  waitFor(function()assert(result().falls==initial.falls+1,"Repeated recovery after the side-fall");return os.clock()>=untilAt end,3,"Post-recovery observation did not finish")
  local final=result()
  assert(final.lap==initial.lap and final.nextCheckpoint==initial.nextCheckpoint and final.latest==initial.latest and final.splits==initial.splits and #final.lapTimes==#initial.lapTimes,"Gallery side-fall changed legitimate lap/checkpoint progress")
  for index,time in initial.lapTimes do assert(final.lapTimes[index]==time,"Completed lap time changed")end
  assert(#report.placements==1 and final.falls==initial.falls+1,"Exactly one declared setup and one actual recovery required")
  report.complete=true
 end,debug.traceback)
 if controller then controller:Disconnect()end
 if observer then observer:Disconnect()end
 if fallConnection then fallConnection:Disconnect()end
 humanoid:Move(Vector3.zero,false);humanoid.Jump=false
 if root.Parent then if ownerAuto then root:SetNetworkOwnershipAuto()else root:SetNetworkOwner(owner)end end
 report.ok,report.failure,report.seconds=ok and observerFailure==nil,if ok then observerFailure else tostring(failure),os.clock()-began
 report.runtimeAfter=services.EggRushService.GetDiagnostics()
 report.after=snapshot();report.cleanup="Controller, observer and fall-touch listener disconnected; movement stopped and original ownership restored; no return placement"
 script:SetAttribute("State",if report.ok then"Complete"else"Failed")
 return report
end
return Test
