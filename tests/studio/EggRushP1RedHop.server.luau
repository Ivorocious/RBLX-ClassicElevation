--!nonstrict
local RunService, Players = game:GetService("RunService"), game:GetService("Players")
local Workspace, ServerStorage, Http = game:GetService("Workspace"), game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer(), "Native Studio server diagnostic only")
assert(not ServerStorage:FindFirstChild("R04RedHopReport"), "Preserve the existing red-hop receipt")
local stored = Instance.new("StringValue")
stored.Name, stored.Parent = "R04RedHopReport", ServerStorage
stored:SetAttribute("State", "Ready")
local allInsets = script:GetAttribute("AllInsets") == true
local sourceNeedle = "inset=.55,requested=false"
local sourceReplacement = 'inset=(if from.part.Name=="S3_ShellApproach_002" then (script:GetAttribute("ProbeTakeoffInset") or .55) else .55),requested=false'
local services = {}
for _, name in {"CourseService", "RaceService", "PlayerRaceService", "ResultsService", "CheckpointService", "EggRushService"} do
 services[name] = require(game.ServerScriptService.Services[name])
end
local BODY_NAMES = {
 Head=true,Torso=true,UpperTorso=true,LowerTorso=true,["Left Arm"]=true,["Right Arm"]=true,["Left Leg"]=true,["Right Leg"]=true,
 LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,RightUpperArm=true,RightLowerArm=true,RightHand=true,
 LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,RightUpperLeg=true,RightLowerLeg=true,RightFoot=true,
}
local function vector(value) return {value.X,value.Y,value.Z} end
local function pose(part) return {name=part.Name,path=part:GetFullName(),cframe={part.CFrame:GetComponents()},size=vector(part.Size),
 canCollide=part.CanCollide,canQuery=part.CanQuery,transparency=part.Transparency} end
local function edgeDistance(part,position,direction)
 local p,d=part.CFrame:PointToObjectSpace(position),part.CFrame:VectorToObjectSpace(direction)
 local distance=math.huge
 for _,axis in {"X","Z"} do
  if math.abs(d[axis])>.0001 then distance=math.min(distance,(math.sign(d[axis])*part.Size[axis]/2-p[axis])/d[axis]) end
 end
 return distance
end
local function top(part) return part.Position+part.CFrame.UpVector*part.Size.Y/2 end
local publication=0
local function publish(report)
 local encoded=Http:JSONEncode(report)
 publication+=1
 local folder=Instance.new("Folder");folder.Name=string.format("Payload_%03d",publication)
 local names,offset={},1
 while offset<=#encoded do
  local last=math.min(offset+149999,#encoded)
  while last<#encoded do local byte=string.byte(encoded,last+1);if byte<128 or byte>191 then break end;last-=1 end
  local chunk=Instance.new("StringValue");chunk.Name=string.format("Chunk_%03d",#names+1)
  chunk.Value=string.sub(encoded,offset,last);chunk.Parent=folder;table.insert(names,chunk.Name);offset=last+1
 end
 folder.Parent=stored
 stored.Value=Http:JSONEncode({format="R04RedHopChunksV1",payloadFolder=folder.Name,chunks=names,jsonBytes=#encoded,
  ok=report.ok,complete=report.complete,attempts=#report.cases,ownerApproval=false})
end
local function run()
 local report={candidateId="ER_P1_R01",phase=1,ownerApproval=false,cases={},placements={},checkpointWrites=0,totalSecondsLimit=65,
  method="Actual CP2 -> Approach001 ->002 ->003 prefix using existing conservative NativeTraversal; full-rate PreSimulation/PostSimulation contact sampling",
  limits={"Two .55 baseline attempts by default; AllInsets selects two attempts each at .55/1.2/1.6, not statistical reliability proof",
   "Edge-rule crossing is passively inferred with the exact driver formula; first Jump=true, ascent and Air receipts are actual observed states",
   "Queries match Runtime BODY_NAMES/visible/CanQuery filters with RespectCanCollide=false; sampled overlap plus recovery does not expose the private recovery reason",
   "Repeated CP2 placements are listed setup; no continuous lap, owner acceptance or human-control claim"}}
 local course,player,character,root,humanoid,originalOwner,originalAuto,ownershipSaved
 local connections,current,observerFailure={},nil,nil
 local started=os.clock()
 local function falls() return assert(services.ResultsService.GetPlayerResult(player)).falls or 0 end
 local function guard()
  assert(not observerFailure,observerFailure)
  assert(os.clock()-started<65,"Red-hop diagnostic exceeded 65 seconds")
  assert(player.Character==character and root.Parent and humanoid.Health>0,"Character changed or died; stop further attempts")
  assert(services.CourseService.GetActiveCourse()==course and services.RaceService.IsRaceActive()
   and services.RaceService.GetCurrentRaceId()==report.raceId,"Race or course changed")
  assert(services.PlayerRaceService.IsOfficialRacer(player) and services.PlayerRaceService.GetPlayerStatus(player)=="Racing","Official racer no longer Racing")
  assert(not root.Anchored and humanoid.WalkSpeed==16 and not humanoid.UseJumpPower
   and math.abs(humanoid.JumpHeight-7.2)<.01 and math.abs(Workspace.Gravity-196.2)<.01,"Actual movement profile changed")
 end
 local ok,failure=xpcall(function()
  course=assert(services.CourseService.GetActiveCourse())
  assert(course:GetAttribute("CandidateId")=="ER_P1_R01" and course:GetAttribute("Phase")==1 and course:GetAttribute("SampleRevision")==3,"Expected actual Phase 1 revision3")
  player=assert(Players:GetPlayers()[1]);character=assert(player.Character)
  root,humanoid=character.HumanoidRootPart,assert(character:FindFirstChildOfClass("Humanoid"))
  report.raceId,report.userId=services.RaceService.GetCurrentRaceId(),player.UserId
  guard();assert(services.EggRushService.GetDiagnostics().bound==true,"Prepare the actual bound inspection race first")
  local approach=course.Obstacles.S3_ShellApproach
  local cp2,a,b,c=course.Obstacles.CP2_Pocket,approach.S3_ShellApproach_001,approach.S3_ShellApproach_002,approach.S3_ShellApproach_003
  local hazard=assert(course.Obstacles.Shellworks_RedHop)
  assert(hazard:GetAttribute("ERLethal")==true and hazard.Transparency<1 and hazard.CanQuery and not hazard.CanCollide
   and hazard:GetAttribute("ERPadName")==b.Name and hazard:GetAttribute("ERNextPadName")==c.Name,"Expected unchanged visible red hop")
  report.geometry={hazard=pose(hazard),departure=pose(b),target=pose(c)}
  report.initialProgress={checkpoint=services.CheckpointService.GetLatestCheckpointIndex(player),resultLap=services.ResultsService.GetPlayerResult(player).currentLap,
   nextCheckpoint=services.ResultsService.GetPlayerResult(player).nextCheckpointIndex}
  local canonical=ServerStorage.CourseBuilders.EggRush.NativeTraversal
  local prototype=script:FindFirstChild("ProbeTemplate")
  if allInsets then
   assert(prototype and prototype:IsA("ModuleScript") and prototype:GetAttribute("ProbeSourceVerified")==true,"Install the externally verified one-token ProbeTemplate before enabling AllInsets")
   assert(prototype:GetAttribute("ReplacementCount")==1 and prototype:GetAttribute("OriginalSourceBytes")==20666
    and prototype:GetAttribute("OriginalSourceSha256")=="EB58E98349FCACE21FC2FE3792E73D7A892BF4F13EB514A81F90569AC1611691","Unexpected probe source contract")
   report.probeSourceContract={verification="Installer attestation; native server Source access is protected",canonicalPath=canonical:GetFullName(),
    originalBytes=prototype:GetAttribute("OriginalSourceBytes"),originalSha256=prototype:GetAttribute("OriginalSourceSha256"),
    patchedBytes=prototype:GetAttribute("PatchedSourceBytes"),patchedSha256=prototype:GetAttribute("PatchedSourceSha256"),replacementCount=1,
    needle=sourceNeedle,replacement=sourceReplacement,canonicalSourceUnchanged=prototype:GetAttribute("CanonicalSourceUnchanged")}
   assert(report.probeSourceContract.canonicalSourceUnchanged==true and report.probeSourceContract.patchedBytes and report.probeSourceContract.patchedSha256,"Missing verified clone source receipt")
  else report.probeSourceContract={method="Unmodified actual canonical NativeTraversal at default .55 inset"} end
  local drivers=Instance.new("Folder");drivers.Name,drivers.Parent="PreservedDriverClones",stored
  local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.RespectCanCollide=false
  local function bodies()
   local values={}
   for _,part in character:GetChildren() do
    if part:IsA("BasePart") and BODY_NAMES[part.Name] and part.Transparency<1 and part.CanQuery then table.insert(values,part) end
   end
   return values
  end
  local function full(sample,parts)
   local value={sample=sample,root=pose(root),bodies={}}
   for _,part in parts do table.insert(value.bodies,pose(part)) end
   return value
  end
  local rayParams=RaycastParams.new();rayParams.FilterType=Enum.RaycastFilterType.Include;rayParams.FilterDescendantsInstances={course};rayParams.RespectCanCollide=true
  local function sample(phase)
   if not current then return end
   guard()
   local receipt=current.receipt
   local hit=Workspace:Raycast(root.Position,Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.7),0),rayParams)
   local parts=bodies();params.FilterDescendantsInstances=parts
   local hits={}
   if #parts>0 then for _,part in Workspace:GetPartsInPart(hazard,params) do table.insert(hits,part.Name) end end
   local onTargetStep=current.step==b.Name.." -> "..c.Name
   local edge=onTargetStep and edgeDistance(b,root.Position,current.direction) or nil
   local value={phase=phase,seconds=os.clock()-current.began,step=current.step,rootPosition=vector(root.Position),velocity=vector(root.AssemblyLinearVelocity),
    floor=humanoid.FloorMaterial.Name,state=humanoid:GetState().Name,jump=humanoid.Jump,edgeDistance=edge,overlapBodies=hits,
    falls=falls()-current.before,support=hit and hit.Instance:GetFullName(),recoveryUntil=character:GetAttribute("RecoveryUntil")}
   if #receipt.trace<512 then table.insert(receipt.trace,value) else receipt.traceTruncated=true end
   if onTargetStep then
    local detail=full(value,parts)
    if value.falls==0 then
     if not receipt.firstEdgeRuleCrossing and phase=="PreSimulation" and edge<=current.inset then receipt.firstEdgeRuleCrossing=detail end
     if not receipt.firstJumpTrue and humanoid.Jump then receipt.firstJumpTrue=detail end
     if not receipt.firstAscent and root.AssemblyLinearVelocity.Y>.1 then receipt.firstAscent=detail end
     if not receipt.firstAir and humanoid.FloorMaterial==Enum.Material.Air then receipt.firstAir=detail end
     if #hits>0 and not receipt.firstRedOverlap then receipt.firstRedOverlap=detail end
     table.insert(current.ring,detail);if #current.ring>12 then table.remove(current.ring,1) end
    end
   end
   if value.falls>0 and not receipt.recovery then receipt.recovery=full(value,parts);receipt.framesBeforeRecovery=table.clone(current.ring) end
  end
  for _,phase in {"PreSimulation","PostSimulation"} do
   table.insert(connections,RunService[phase]:Connect(function()
    local sampled,message=xpcall(function()sample(phase)end,debug.traceback)
    if not sampled then observerFailure=message end
   end))
  end
  originalOwner,originalAuto=root:GetNetworkOwner(),root:GetNetworkOwnershipAuto();ownershipSaved=true
  local settings=if allInsets then {.55,1.2,1.6,.55,1.2,1.6} else {.55,.55}
  local lastRecoveryAt
  for index,inset in settings do
   current=nil
   local waitDeadline=os.clock()+3
   repeat
    guard()
    if (character:GetAttribute("RecoveryUntil") or 0)<=Workspace:GetServerTimeNow() and (not lastRecoveryAt or os.clock()-lastRecoveryAt>=1.65) then break end
    RunService.Heartbeat:Wait()
   until os.clock()>=waitDeadline
   assert((character:GetAttribute("RecoveryUntil") or 0)<=Workspace:GetServerTimeNow() and (not lastRecoveryAt or os.clock()-lastRecoveryAt>=1.65),"Existing recovery cooldown did not expire")
   local module=if allInsets then prototype:Clone() else canonical:Clone()
   module.Name=string.format("Attempt_%02d_Inset_%03d",index,math.floor(inset*100+.5))
   module:SetAttribute("ProbeTakeoffInset",inset);module.Parent=drivers
   local receipt={attempt=index,inset=inset,trace={},driver=module:GetFullName(),defaultOtherDepartureInset=.55}
   table.insert(report.cases,receipt)
   local position=top(cp2)+Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+.15,0)
   table.insert(report.placements,{kind="InitialAttemptPlacement",attempt=index,part=cp2:GetFullName(),position=vector(position),controller="NativeTraversal placeAtStart=true"})
   current={receipt=receipt,inset=inset,before=falls(),began=os.clock(),ring={}}
   stored:SetAttribute("State","Running");stored:SetAttribute("Attempt",index)
   receipt.result=require(module).Run(course,player,{{part=cp2},{part=a},{part=b},{part=c}},
    {placeAtStart=true,pace=false,guard=function()
     guard();assert(falls()==current.before,"Actual recovery occurred during focused prefix");return true
    end},function(_,_,step)
     current.step=step
     if step==b.Name.." -> "..c.Name then
      local delta=top(c)-root.Position;current.direction=Vector3.new(delta.X,0,delta.Z).Unit
      receipt.targetStepStart=full({seconds=os.clock()-current.began,step=step},bodies())
     end
     stored:SetAttribute("Progress",step)
    end)
   receipt.actualFalls=falls()-current.before
   if receipt.actualFalls>0 then lastRecoveryAt=os.clock() end
   receipt.lastFrames=table.clone(current.ring)
   receipt.outcome=if receipt.actualFalls>0 then (if receipt.firstRedOverlap then "RecoveryAfterObservedTargetRedOverlap" else "RecoveryWithoutCapturedTargetRedOverlap")
    elseif receipt.result.ok then "PrefixAndTargetHopCompleted" else "DriverFailureWithoutRecovery"
   current=nil
   guard();publish(report)
  end
  report.complete=true
 end,debug.traceback)
 current=nil
 for _,connection in connections do connection:Disconnect() end
 if root and root.Parent and humanoid and humanoid.Parent then
  humanoid:Move(Vector3.zero,false);humanoid.Jump=false
  if player.Character==character and humanoid.Health>0 and services.CourseService.GetActiveCourse()==course then
   local cp2=course.Obstacles.CP2_Pocket
   local position=top(cp2)+Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+.15,0)
   table.insert(report.placements,{kind="PostTestCleanupPlacement",position=vector(position),purpose="After all attempts and observer/controller disconnection; not traversal"})
   character:PivotTo(CFrame.new(position));root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
  end
  if ownershipSaved then
   local restored,message=pcall(function()if originalAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(originalOwner) end end)
   report.ownershipRestored,report.ownershipRestoreFailure=restored,if restored then nil else tostring(message)
  end
 end
 report.ok,report.failure=ok,if ok then nil else failure
 report.observerFailure,report.seconds=observerFailure,os.clock()-started
 report.interpretation="ok means the bounded diagnostic ran; inspect each case outcome, actual falls and contact frames. It is not a red-hop clearance verdict."
 publish(report);stored:SetAttribute("State",if ok then "Complete" else "Failed")
end
stored.Value=Http:JSONEncode({state="Ready",allInsets=allInsets,attempts=if allInsets then 6 else 2,ownerApproval=false,command={action="Run"},
 setup="Prepare an active official R01 revision3 race first. Baseline uses untouched driver clones; AllInsets requires externally verified ProbeTemplate."})
local used=false
stored:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end
 local parsed,command=pcall(function()return Http:JSONDecode(stored:GetAttribute("Command"))end)
 if not parsed or typeof(command)~="table" or command.action~="Run" then return end
 used=true;task.spawn(run)
end)
