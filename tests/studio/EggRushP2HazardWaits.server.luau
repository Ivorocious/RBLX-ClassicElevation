--!nonstrict
local RunService, Workspace, Players = game:GetService("RunService"), game:GetService("Workspace"), game:GetService("Players")
local Storage, Http = game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId==85558151074819,"Owned Studio server only")
assert(not Storage:FindFirstChild("EggRushP2HazardWaitsReport"),"Preserve the previous receipt")
local stored=Instance.new("StringValue"); stored.Name,stored.Parent="EggRushP2HazardWaitsReport",Storage
stored:SetAttribute("State","Ready")
local services={}
for _,name in {"CourseService","RaceService","PlayerRaceService","ResultsService","CheckpointService","EggRushService"} do
 services[name]=require(game.ServerScriptService.Services[name])
end
local BODY={Head=true,Torso=true,UpperTorso=true,LowerTorso=true,LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,
 RightUpperArm=true,RightLowerArm=true,RightHand=true,LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,RightUpperLeg=true,RightLowerLeg=true,RightFoot=true}
local function vector(v)return {v.X,v.Y,v.Z}end
local function pose(p)return {path=p:GetFullName(),size=vector(p.Size),frame={p.CFrame:GetComponents()},visible=p.Transparency<1,canQuery=p.CanQuery,canCollide=p.CanCollide,lethal=p:GetAttribute("ERLethal"),class=p.ClassName,fidelity=if p:IsA("MeshPart")then p.CollisionFidelity.Name else nil}end
local function snapshot(player)
 local r=assert(services.ResultsService.GetPlayerResult(player),"Missing official result")
 return {lap=r.currentLap,nextCheckpoint=r.nextCheckpointIndex,falls=r.falls or 0,splitCount=#(r.checkpointSplits or {}),lapTimes=table.clone(r.lapTimes or {}),latest=services.CheckpointService.GetLatestCheckpointIndex(player),status=r.status}
end
local function persist(report)
 local encoded,names=Http:JSONEncode(report),{}
 local folder=Instance.new("Folder");folder.Name,folder.Parent="Payload",stored
 local offset=1
 while offset<=#encoded do
  local last=math.min(offset+149999,#encoded)
  while last<#encoded do local b=string.byte(encoded,last+1);if b<128 or b>191 then break end;last-=1 end
  local chunk=Instance.new("StringValue");chunk.Name=string.format("Chunk_%03d",#names+1);chunk.Value=string.sub(encoded,offset,last);chunk.Parent=folder
  table.insert(names,chunk.Name);offset=last+1
 end
 stored.Value=Http:JSONEncode({format="EggRushP2HazardWaitsChunksV1",payloadFolder=folder.Name,chunks=names,jsonBytes=#encoded,ok=report.ok})
end
local used=false
local function run(command)
 assert(table.find({"All","Waits","Contacts"},command.stage),"Stage must be All, Waits or Contacts")
 local report={phase=2,stage=command.stage,ok=false,cases={},placements={},checkpointWrites=0,maximumWallSeconds=180,
  method="One real official fitted avatar, declared focused initial placements, real runtime and exact visible-mesh overlap queries; no CP, immunity, geometry or clock writes",
  limits="Seven representative holds omit egg centers/opposite edges; one rolling-egg and one stationary-tail contact are finite diagnostics, not universal arrivals, human, crowd or FPS proof"}
 local began,root,humanoid,character,player,originalOwner,originalAuto,holdConnection=os.clock(),nil,nil,nil,nil,nil,nil,nil
 local course,raceId,deadline=nil,nil,began+180
 local function clock()return services.EggRushService.GetDiagnostics().elapsed end
 local function guard()
  assert(os.clock()<deadline,"180-second total budget exhausted")
  assert(player.Character==character and humanoid.Health>0 and services.CourseService.GetActiveCourse()==course
   and services.RaceService.IsRaceActive() and services.RaceService.GetCurrentRaceId()==raceId
   and services.PlayerRaceService.IsOfficialRacer(player) and services.PlayerRaceService.GetPlayerStatus(player)=="Racing","Official actor/race changed")
 end
 local function untilTrue(predicate,seconds,message)
  local limit=math.min(deadline,os.clock()+seconds)
  repeat guard(); if predicate()then return end;RunService.Heartbeat:Wait() until os.clock()>=limit
  error(message)
 end
 local function noImmunity()
  untilTrue(function()return (character:GetAttribute("RecoveryUntil")or 0)<=Workspace:GetServerTimeNow()end,5,"Real recovery immunity did not expire")
 end
 local function place(frame,reason,case)
  table.insert(report.placements,{kind=reason,case=case,position=vector(frame.Position),frame={frame:GetComponents()},clock=clock(),seconds=os.clock()-began})
  character:PivotTo(frame);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
 end
 local ok,failure=xpcall(function()
  local tag=script:GetAttribute("OwnedStudioTestTag")
  local args=game:GetService("StudioTestService"):GetTestArgs()
  assert(typeof(tag)=="string" and #tag>0 and typeof(args)=="table" and args.tag==tag,"Exact owned StudioTestService tag required")
  course=assert(services.CourseService.GetActiveCourse())
  local expected=script:GetAttribute("ExpectedCandidate")or "ER_P2_R01_C02"
  assert(course:GetAttribute("EROwned")==true and course:GetAttribute("CourseId")=="egg_rush_circuit" and course:GetAttribute("CandidateId")==expected
   and course:GetAttribute("Phase")==2 and course:GetAttribute("FullBodyContacts")==true,"Wrong owned full-contact Phase2 candidate")
  raceId=services.RaceService.GetCurrentRaceId()
  local diagnostics=services.EggRushService.GetDiagnostics()
  assert(diagnostics.bound and diagnostics.raceId==raceId and raceId~="","Prepare current official race first")
  local id=script:GetAttribute("UserId")
  if id then player=Players:GetPlayerByUserId(id)else local list=Players:GetPlayers();assert(#list==1,"Select UserId explicitly with multiple actual Players");player=list[1]end
  character=assert(assert(player,"No selected actual Player").Character)
  root,humanoid=assert(character:FindFirstChild("HumanoidRootPart")),assert(character:FindFirstChildOfClass("Humanoid"))
  local fit=assert(character:FindFirstChild("CollisionPart"))
  assert(not root.Anchored and fit.CanCollide and humanoid.WalkSpeed==16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.01 and math.abs(Workspace.Gravity-196.2)<.01,"Expected unanchored fitted 16/7.2 profile")
  guard();originalOwner,originalAuto=root:GetNetworkOwner(),root:GetNetworkOwnershipAuto();root:SetNetworkOwner(nil)
  holdConnection=RunService.PreSimulation:Connect(function()if humanoid.Parent then humanoid:Move(Vector3.zero,false);humanoid.Jump=false end end)
  report.candidateId,report.raceId,report.userId,report.ownedStudioTestTag=expected,raceId,player.UserId,tag
  report.initialResult,report.actualFit,report.movement=snapshot(player),pose(fit),{walk=humanoid.WalkSpeed,jump=humanoid.JumpHeight,gravity=Workspace.Gravity}
  local bodies={}
  for _,p in character:GetChildren()do if p:IsA("BasePart")and BODY[p.Name]and p.Transparency<1 and p.CanQuery then table.insert(bodies,p)end end
  assert(#bodies>=15,"Expected actual visible R15 body parts")
  local mechanisms=course.Obstacles.Mechanisms
  local contacts={}
  report.hazardPeriods={}
  for _,name in {"EggBand1","EggBand2","GuardianTail"}do
   local m=assert(mechanisms:FindFirstChild(name));contacts[name]={}
   local period=m:GetAttribute("RestSeconds")+m:GetAttribute("WarningSeconds")+m:GetAttribute("MoveSeconds")
   if name=="GuardianTail"then period+=m:GetAttribute("FarWaitSeconds")+m:GetAttribute("ClosingWarningSeconds")+m:GetAttribute("MoveSeconds")end
   assert(math.abs(period-14.5)<.001,"Full-cycle checks require the actual 14.5-second shared period")
   report.hazardPeriods[name]=period
   for _,p in m:GetDescendants()do
    if p:IsA("BasePart")and p:GetAttribute("ERLethal")==true then
     assert(p:IsA("MeshPart")and p.CanQuery and p.CollisionFidelity==Enum.CollisionFidelity.PreciseConvexDecomposition,"Use actual queryable precise visible meshes, never rough boxes")
     table.insert(contacts[name],p)
    end
   end
   assert(#contacts[name]>0,"Missing actual lethal mesh")
  end
  report.hazardMeshes={}
  for name,parts in contacts do report.hazardMeshes[name]={};for _,p in parts do table.insert(report.hazardMeshes[name],pose(p))end end
  local tailAsset=assert(mechanisms.GuardianTail:FindFirstChild("GuardianSweepTail"),"Missing actual guardian sweep")
  report.actualTailAsset=tailAsset:GetFullName()
  local query=OverlapParams.new();query.FilterType=Enum.RaycastFilterType.Include;query.RespectCanCollide=false
  local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={course};ray.RespectCanCollide=true
  local function support()
   local hit=Workspace:Raycast(root.Position,Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.7),0),ray)
   return hit and hit.Instance
  end
  local function overlaps(parts)
   query.FilterDescendantsInstances=parts
   local found={}
   for _,body in bodies do
    for _,p in Workspace:GetPartsInPart(body,query)do
     if p.Transparency<1 and p.CanQuery then table.insert(found,{body=body.Name,part=p:GetFullName(),bodyFrame={body.CFrame:GetComponents()},partFrame={p.CFrame:GetComponents()}})end
    end
   end
   return found
  end
  local function waitCase(def)
   local case={name=def.name,kind="FullCycleWait",ok=false,states={},frames=0,overlapFrames=0,maximumDrift=0}
   table.insert(report.cases,case)
   local passed,message=xpcall(function()
    noImmunity();local before=snapshot(player)
    local pad=assert(course.Obstacles:FindFirstChild(def.pad,true));local x=def.side*(pad.Size.X/2-3)
    assert(pad.CanCollide and pad.Anchored and pad.Size.X>=6 and pad.Size.Z>=3,"Actual fixed wait support required")
    case.pad,case.lateralInset,case.localX=pose(pad),3,x
    local target=pad.CFrame* CFrame.new(x,pad.Size.Y/2+humanoid.HipHeight+root.Size.Y/2+.15,0)
    place(target,"InitialWaitPlacement",def.name)
    untilTrue(function()return support()==pad and humanoid.FloorMaterial~=Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y)<2 end,2,"Wait setup did not settle on the named support")
    local start,initial=clock(),root.Position
    case.startClock,case.initialPosition=start,vector(initial)
    repeat
     guard();RunService.Heartbeat:Wait();case.frames+=1
     local state=mechanisms[def.hazard]:GetAttribute("ERState");case.states[state]=true
     local hits=overlaps(contacts[def.hazard])
     if #hits>0 then case.overlapFrames+=1;case.firstOverlap=case.firstOverlap or hits end
     local actual=support();case.lastSupport=actual and actual:GetFullName();case.lastFloor=humanoid.FloorMaterial.Name
     case.maximumDrift=math.max(case.maximumDrift,Vector3.new(root.Position.X-initial.X,0,root.Position.Z-initial.Z).Magnitude)
     assert(#hits==0,"Visible hazard body overlap at the authored safe wait")
     assert(actual==pad and humanoid.FloorMaterial~=Enum.Material.Air,"Actual fixed wait support lost")
     assert(snapshot(player).falls==before.falls,"Actual recovery occurred at the safe wait")
    until clock()-start>=14.5
    case.endClock,case.runtimeSeconds,case.finalPosition,case.result=clock(),clock()-start,vector(root.Position),snapshot(player)
    assert(case.runtimeSeconds>=14.5,"Incomplete shared-clock cycle")
   end,debug.traceback)
   case.ok,case.failure=passed,if passed then nil else message
   case.lastPosition,case.lastClock=vector(root.Position),clock()
   local captured,state=pcall(snapshot,player);if captured then case.finalResult=state end
  end
  if command.stage~="Contacts"then
   for _,def in {
    {name="NormalEgg1LeftEdge",pad="S2_EggRollers_004",side=-1,hazard="EggBand1"},
    {name="NormalEgg2RightEdge",pad="S2_EggRollers_010",side=1,hazard="EggBand2"},
    {name="ExpertEgg1LeftEdge",pad="E2_ChuteCut_003",side=-1,hazard="EggBand1"},
    {name="ExpertEgg2RightEdge",pad="E2_ChuteCut_008",side=1,hazard="EggBand2"},
    {name="TailCenter",pad="Tail_SafeWait",side=0,hazard="GuardianTail"},
    {name="TailLeftEdge",pad="Tail_SafeWait",side=-1,hazard="GuardianTail"},
    {name="TailRightEdge",pad="Tail_SafeWait",side=1,hazard="GuardianTail"},
   }do waitCase(def)end
  end
  local function contactCase(name,modelName,stationary)
   local case={name=name,kind="DeliberateVisibleContact",ok=false,stationaryRequested=stationary}
   table.insert(report.cases,case)
   local passed,message=xpcall(function()
    noImmunity();local model=mechanisms[modelName];local chosen
    untilTrue(function()
     local state=model:GetAttribute("ERState")
     if stationary and state~="Rest"and state~="FarWait"then return false end
     if not stationary and state~="Rolling"then return false end
     local volume=0;chosen=nil
     for _,p in contacts[modelName]do if p.Transparency<1 and p.Size.X*p.Size.Y*p.Size.Z>volume then chosen=p;volume=p.Size.X*p.Size.Y*p.Size.Z end end
     return chosen~=nil
    end,16,"Natural visible contact state did not appear")
    local initialFrame=chosen.CFrame
    if stationary then
     local at=os.clock();repeat guard();RunService.Heartbeat:Wait()until os.clock()-at>=.12
     assert(model:GetAttribute("ERState")=="Rest"or model:GetAttribute("ERState")=="FarWait","Stationary contact state ended before setup")
     local delta=initialFrame:ToObjectSpace(chosen.CFrame);local _,angle=delta:ToAxisAngle()
     case.stationaryDisplacement,case.stationaryAngle=delta.Position.Magnitude,angle
     assert(delta.Position.Magnitude<.01 and math.abs(angle)<.01,"Tail was not actually stationary")
    end
    local before=snapshot(player);local respawn=assert(services.CheckpointService.GetCheckpointRespawnCFrame(player),"Missing existing earned recovery target")
    case.before,case.expectedRespawn,case.hazard,case.entryState,case.entryClock=before,{respawn:GetComponents()},pose(chosen),model:GetAttribute("ERState"),clock()
    local torso=assert(character:FindFirstChild("UpperTorso"));local relative=root.CFrame:ToObjectSpace(torso.CFrame)
    place(chosen.CFrame*relative:Inverse(),"DeliberateVisibleContactPlacement",name)
    case.initialExactOverlaps=overlaps(contacts[modelName])
    assert(#case.initialExactOverlaps>0,"Declared visible solid contact was not physically established")
    untilTrue(function()return snapshot(player).falls>before.falls end,3,"Visible contact did not trigger actual recovery")
    case.returnPosition,case.returnDistance,case.recoveryUntil=vector(root.Position),(root.Position-respawn.Position).Magnitude,character:GetAttribute("RecoveryUntil")
    case.after=snapshot(player)
    assert(case.after.falls==before.falls+1 and case.after.lap==before.lap and case.after.latest==before.latest
     and case.after.nextCheckpoint==before.nextCheckpoint and case.after.splitCount==before.splitCount and #case.after.lapTimes==#before.lapTimes,"Actual recovery changed earned progress or counted extra falls")
    assert(case.returnDistance<3,"Actual return did not match the existing earned checkpoint/start recovery frame")
    untilTrue(function()return support()~=nil and humanoid.FloorMaterial~=Enum.Material.Air end,3,"Actual recovered avatar did not regain physical support")
    case.returnSupport,case.returnFloor=support():GetFullName(),humanoid.FloorMaterial.Name
   end,debug.traceback)
   case.ok,case.failure=passed,if passed then nil else message
   case.lastPosition,case.lastClock=vector(root.Position),clock()
   local captured,state=pcall(snapshot,player);if captured then case.finalResult=state end
  end
  if command.stage~="Waits"then
   contactCase("VisibleRollingEggContact","EggBand1",false)
   contactCase("VisibleStationaryTailContact","GuardianTail",true)
  end
  report.ok=true;for _,case in report.cases do if not case.ok then report.ok=false end end
 end,debug.traceback)
 if holdConnection then holdConnection:Disconnect()end
 if root and root.Parent and originalAuto~=nil then
  humanoid:Move(Vector3.zero,false);humanoid.Jump=false
  local restored,message=pcall(function()if originalAuto then root:SetNetworkOwnershipAuto()else root:SetNetworkOwner(originalOwner)end end)
  report.ownershipRestored,report.restoreFailure=restored,if restored then nil else tostring(message)
  report.ok=report.ok and restored
 end
 report.ok=ok and report.ok;report.failure=if ok then nil else failure
 report.seconds,report.complete,report.cleanup=os.clock()-began,true,"Zero-movement connection disconnected, original network ownership restored when captured; no return placement or progress/clock writes"
 persist(report);stored:SetAttribute("State",if report.ok then "Complete"else"Failed")
end
stored:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end
 local decoded,command=pcall(function()return Http:JSONDecode(stored:GetAttribute("Command"))end)
 if not decoded or typeof(command)~="table"then stored:SetAttribute("CommandError","Expected JSON object");return end
 used=true;stored:SetAttribute("State","Running")
 task.spawn(function()local ok,message=xpcall(function()run(command)end,debug.traceback);if not ok then stored.Value=Http:JSONEncode({ok=false,failure=message});stored:SetAttribute("State","Failed")end end)
end)
