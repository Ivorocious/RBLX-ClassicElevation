--!nonstrict
local RunService, Players, Workspace = game:GetService("RunService"), game:GetService("Players"), game:GetService("Workspace")
local Storage, Http, Physics = game:GetService("ServerStorage"), game:GetService("HttpService"), game:GetService("PhysicsService")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819, "Owned Studio server only")
local reportName=script:GetAttribute("ReportName") or "EggRushP2TrafficReport"
assert(typeof(reportName)=="string" and #reportName>0,"ReportName must be a nonempty string")
assert(not Storage:FindFirstChild(reportName), "Preserve the earlier traffic receipt")
local stored = Instance.new("StringValue"); stored.Name, stored.Parent = reportName, Storage
stored:SetAttribute("State", "Ready")
local services = {}
for _, name in {"CourseService", "RaceService", "PlayerRaceService", "ResultsService", "EggRushService"} do
 services[name] = require(game.ServerScriptService.Services[name])
end
local traversalName=script:GetAttribute("TraversalModule") or "NativeTraversal"
assert(typeof(traversalName)=="string" and #traversalName>0,"TraversalModule must name the owned test utility")
local traversalModule=assert(Storage.CourseBuilders.EggRush:FindFirstChild(traversalName),"Missing selected traversal module")
assert(traversalModule:IsA("ModuleScript"),"TraversalModule must select a ModuleScript")
local Traversal = require(traversalModule)
local used = false
local function vector(v) return {v.X, v.Y, v.Z} end
local function pose(p) return {path=p:GetFullName(), size=vector(p.Size), frame={p.CFrame:GetComponents()}, canCollide=p.CanCollide, group=p.CollisionGroup} end
local function result(player)
 local r = assert(services.ResultsService.GetPlayerResult(player), "Missing official result")
 return {lap=r.currentLap, nextCheckpoint=r.nextCheckpointIndex, falls=r.falls or 0, status=r.status,
  lapTimes=table.clone(r.lapTimes or {}), splitCount=#(r.checkpointSplits or {})}
end
local function persist(report)
 local encoded, names = Http:JSONEncode(report), {}
 local payload = Instance.new("Folder"); payload.Name = "Payload"; payload.Parent = stored
 local offset = 1
 while offset <= #encoded do
  local last = math.min(offset+149999, #encoded)
  while last < #encoded do local b=string.byte(encoded,last+1); if b<128 or b>191 then break end; last-=1 end
  local chunk=Instance.new("StringValue"); chunk.Name=string.format("Chunk_%03d",#names+1)
  chunk.Value=string.sub(encoded,offset,last); chunk.Parent=payload; table.insert(names,chunk.Name); offset=last+1
 end
 stored.Value=Http:JSONEncode({format="EggRushP2TrafficChunksV1", payloadFolder=payload.Name, chunks=names, jsonBytes=#encoded, ok=report.ok})
end
local function run(command)
 local stage=command.stage
 assert(table.find({"ShellClose","ShellLate","TraySplit","TrayLate"},stage), "Unknown traffic stage")
 local report={stage=stage,phase=2,ok=false,participants={},placements={},warnings={},checkpointWrites=0,traversalModule=traversalModule:GetFullName(),
  method="Two real official Players; declared initial positioning and ordinary per-actor lane steering on the unchanged shared clock",
  limits="Intentional lane-steering encounter evidence, not universal centerline/crowd proof; no continuous lap, human controls, arbitrary arrivals, 20-racer or FPS proof; sampled contacts are not exact recovery-cause proof"}
 local contexts, observer, cancelled, observerFailure = {}, nil, false, nil
 local began, course, raceId = os.clock(), nil, nil
 local deadline = began+80
 local function clock() return services.EggRushService.GetDiagnostics().elapsed end
 local function guard(i)
  local c=contexts[i]
  return not cancelled and not observerFailure and os.clock()<deadline and c.player.Character==c.character and c.humanoid.Health>0
   and services.CourseService.GetActiveCourse()==course and services.RaceService.IsRaceActive()
   and services.RaceService.GetCurrentRaceId()==raceId and services.PlayerRaceService.IsOfficialRacer(c.player)
   and services.PlayerRaceService.GetPlayerStatus(c.player)=="Racing" and result(c.player).falls==c.report.initialResult.falls
 end
 local function waitFor(i,predicate,message)
  repeat assert(guard(i),message); RunService.Heartbeat:Wait() until predicate()
 end
 local ok,failure=xpcall(function()
  local tag=script:GetAttribute("OwnedTestTag")
  assert(typeof(tag)=="string" and #tag>0 and Workspace:GetAttribute("ERP2OwnedTestTag")==tag, "Owned session tag mismatch")
  course=assert(services.CourseService.GetActiveCourse())
  local expectedCandidate=script:GetAttribute("ExpectedCandidate") or "ER_P2_R01_C03"
  assert(course:GetAttribute("EROwned")==true and course:GetAttribute("CourseId")=="egg_rush_circuit"
   and course:GetAttribute("CandidateId")==expectedCandidate and course:GetAttribute("Phase")==2 and course:GetAttribute("SampleRevision")==3
   and course:GetAttribute("FullBodyContacts")==true, "Expected owned Phase2 R03 full-contact course")
  raceId=services.RaceService.GetCurrentRaceId()
  local diagnostics=services.EggRushService.GetDiagnostics()
  assert(services.RaceService.IsRaceActive() and raceId~="" and diagnostics.bound and diagnostics.raceId==raceId and diagnostics.movementProfiles==2, "Prepare official two-racer race first")
  local players=Players:GetPlayers(); assert(#players==2,"Exactly two actual Players required")
  table.sort(players,function(a,b)return a.UserId<b.UserId end)
  report.raceId,report.candidateId,report.pacingRevision,report.ownedTestTag=raceId,course:GetAttribute("CandidateId"),course:GetAttribute("PacingRevision"),tag
  assert(math.abs(Workspace.Gravity-196.2)<.01,"Wrong gravity")
  local mechanisms=course.Obstacles.Mechanisms
  local function boardRemaining()
   local m=mechanisms.SidewaysTray
   local b,w,move,exit,cw=m:GetAttribute("BoardSeconds"),m:GetAttribute("WarningSeconds"),m:GetAttribute("MoveSeconds"),m:GetAttribute("ExitSeconds"),m:GetAttribute("ClosingWarningSeconds")
   local t=(clock()+(m:GetAttribute("PhaseSeconds") or 0))%(b+w+move+exit+cw+move)
   return if t<b+w then b+w-t else 0
  end
  local shellModels={}
  for _,m in mechanisms:GetChildren() do
   if m:GetAttribute("ERMechanism")=="ShellLip" then
    table.insert(shellModels,m); local count=0
    for _,p in m:GetDescendants() do if p:IsA("BasePart") and p:GetAttribute("ERSupport")==true then assert(p.CanCollide); count+=1 end end
    assert(count==8,"Keep all eight physical shell volumes")
   end
  end
  assert(#shellModels==9,"Keep all actual R03 shells")
  for i,player in players do
   local character=assert(player.Character); local root=assert(character:FindFirstChild("HumanoidRootPart"))
   local h=assert(character:FindFirstChildOfClass("Humanoid")); local fit=assert(character:FindFirstChild("CollisionPart"))
   assert(h.WalkSpeed==16 and not h.UseJumpPower and math.abs(h.JumpHeight-7.2)<.01 and fit.CanCollide and not root.Anchored,"Expected actual fitted 16/7.2 avatar")
   assert((character:GetAttribute("RecoveryUntil") or 0)<=Workspace:GetServerTimeNow(),"Wait for real recovery immunity to expire")
   local r={userId=player.UserId,role=if i==1 then "Leader" else "Follower",initialResult=result(player),body={},samples={},events={},motionSeconds={},holds={},overlapPairs={},overlapSamples=0}
   local c={player=player,character=character,root=root,humanoid=h,report=r,owner=root:GetNetworkOwner(),auto=root:GetNetworkOwnershipAuto(),done=false,bodies={}}
   contexts[i],report.participants[i]=c,r
   local side=if i==1 then -1 else 1
   r.aimPolicy={name="TrafficSeparateLanesV1",side=side,shellGlobalZ=side*2.4,trayGlobalX=side*2.4,fixedRightVector=side*2,footprintInset=.75}
   r.aimTargets,r.aimCalls={},0
   c.lastAim={}
   c.aim=function(part,_,defaultAim)
    local name=part.Name
    local offset=if name=="ShellContact" or name=="Shell_ForkWait" or name=="Shell_MiddleWait" or name=="Shell_ExitWait" then Vector3.new(0,0,side*2.4)
     elseif name=="TrayContact" or name=="Tray_BoardPocket" then Vector3.new(side*2.4,0,0) else part.CFrame.RightVector*(side*2)
    local requested=part.CFrame:PointToObjectSpace(defaultAim+offset)
    local x,z=math.max(0,part.Size.X/2-.75),math.max(0,part.Size.Z/2-.75)
    local localAim=Vector3.new(math.clamp(requested.X,-x,x),part.Size.Y/2,math.clamp(requested.Z,-z,z))
    local aim=part.CFrame:PointToWorldSpace(localAim)
    assert(math.abs(localAim.X)<part.Size.X/2 and math.abs(localAim.Z)<part.Size.Z/2,"Lane aim must stay strictly inside actual supported footprint")
    r.aimCalls+=1;c.lastAim[part]=aim
    local key=part:GetFullName();local target=r.aimTargets[key] or {firstAim=vector(aim),calls=0}
    target.calls+=1;target.lastAim,target.lastLocalAim,target.requestedOffset=vector(aim),vector(localAim),vector(offset)
    target.clamped=math.abs(requested.X-localAim.X)>.001 or math.abs(requested.Z-localAim.Z)>.001
    r.aimTargets[key]=target
    return aim
   end
   for _,p in character:GetChildren() do if p:IsA("BasePart") then table.insert(r.body,pose(p)) end end
   for _,name in {"Head","UpperTorso","LowerTorso","CollisionPart"} do table.insert(c.bodies,assert(character:FindFirstChild(name))) end
   local section=if stage:match("Shell") then "Shellworks" else if i==2 and stage=="TraySplit" then "IncubatorAlternate" else "Incubator"
   local all=Traversal.Points(course,"Normal",section)
   local startName=if stage=="ShellLate" and i==2 then "S3_ShellApproach_004" else if stage:match("Shell") then "Shell_ForkWait"
    else if stage=="TrayLate" then (if i==1 then "Tray_BoardPocket" else "") else "Shell_ExitWait"
   if stage=="TrayLate" and i==2 then
    for n,p in all do if p.part.Name=="Tray_BoardPocket" then startName=all[n-1].part.Name; break end end
   end
   local selected={}; local include=false
   for _,p in all do if p.part.Name==startName then include=true end; if include then table.insert(selected,p) end end
   assert(#selected>1,"Missing selected section start"); c.points=selected
   r.section,r.line,r.pace=section,"Normal",false
   local first=selected[1].part
   local offset=if (stage=="ShellClose" or stage=="TraySplit") then (if i==1 then -2 else 2) else 0
   local surface=first.CFrame:PointToWorldSpace(Vector3.new(offset,first.Size.Y/2,0))
   local target=surface+Vector3.new(0,h.HipHeight+root.Size.Y/2+.15,0)
   assert(first.Anchored and first.CanCollide,"Initial setup must use an actual fixed support")
   table.insert(report.placements,{userId=player.UserId,kind="InitialFocusedSetup",part=first:GetFullName(),position=vector(target),clock=clock()})
   root:SetNetworkOwner(nil); character:PivotTo(CFrame.new(target)); root.AssemblyLinearVelocity=Vector3.zero; root.AssemblyAngularVelocity=Vector3.zero
   local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Include; ray.FilterDescendantsInstances={course}; ray.RespectCanCollide=true; c.ray=ray
   local overlap=OverlapParams.new(); overlap.FilterType=Enum.RaycastFilterType.Include; overlap.RespectCanCollide=true; c.overlap=overlap
  end
  for i,c in contexts do
   local targets=table.clone(shellModels); table.insert(targets,contexts[3-i].character); c.overlap.FilterDescendantsInstances=targets
  end
  report.racerPairCollidable=Physics:CollisionGroupsAreCollidable(contexts[1].character.CollisionPart.CollisionGroup,contexts[2].character.CollisionPart.CollisionGroup)
  assert(report.racerPairCollidable,"Actual racer collision groups must interact for this physical traffic test")
  local lastAt,lastStates,lastSample=nil,{},0
  observer=RunService.Heartbeat:Connect(function()
   local sampled,message=xpcall(function()
    local at=os.clock(); if at-lastSample<.1 then return end; lastSample=at
    local elapsed=if lastAt then at-lastAt else 0; lastAt=at
    for _,m in mechanisms:GetChildren() do
     local state=m:GetAttribute("ERState")
     if state~=lastStates[m] then
      lastStates[m]=state
      if #report.warnings<200 then
       local ref=m:FindFirstChild("Warning"); local lamp=ref and ref.Value
       table.insert(report.warnings,{model=m.Name,state=state,clock=clock(),seconds=at-began,lamp=lamp and pose(lamp),color=lamp and {lamp.Color.R,lamp.Color.G,lamp.Color.B},transparency=lamp and lamp.Transparency})
      end
     end
    end
    for i,c in contexts do
     local r,root,h=c.report,c.root,c.humanoid
     local hit=Workspace:Raycast(root.Position,Vector3.new(0,-(h.HipHeight+root.Size.Y/2+.7),0),c.ray)
     local support=hit and hit.Instance
     local riding=support==mechanisms.SidewaysTray.TrayContact
     local recovering=(c.character:GetAttribute("RecoveryUntil") or 0)>Workspace:GetServerTimeNow() or result(c.player).falls>r.initialResult.falls
     local moved=support and c.previousSupport==support and c.previousFrame and c.previousPosition
      and (support.CFrame:PointToWorldSpace(c.previousFrame:PointToObjectSpace(c.previousPosition))-c.previousPosition).Magnitude>.002
     local kind=if recovering then "Recovery" else if riding then (if moved then "MovingRide" else "StationaryRide")
      else if h.FloorMaterial==Enum.Material.Air then "Airborne" else if c.previousPosition and (root.Position-c.previousPosition).Magnitude/math.max(elapsed,.001)<.25 then "StationaryFixed" else "OrdinaryMovement"
     r.motionSeconds[kind]=(r.motionSeconds[kind] or 0)+elapsed
     local stateKey=kind..":"..tostring(support)..":"..tostring(result(c.player).falls)
     if stateKey~=c.stateKey and #r.events<180 then
      c.stateKey=stateKey; table.insert(r.events,{seconds=at-began,clock=clock(),kind=kind,support=support and support:GetFullName(),position=vector(root.Position),result=result(c.player)})
     end
     if #r.samples<800 then table.insert(r.samples,{seconds=at-began,clock=clock(),position=vector(root.Position),support=support and support:GetFullName(),floor=h.FloorMaterial.Name,distanceToOther=(root.Position-contexts[3-i].root.Position).Magnitude}) end
     local pairs=0
     for _,body in c.bodies do
      c.overlap.CollisionGroup=body.CollisionGroup
      for _,p in Workspace:GetPartsInPart(body,c.overlap) do
       if p.CanCollide then
        pairs+=1; local key=body.Name.." -> "..p:GetFullName(); r.overlapPairs[key]=(r.overlapPairs[key] or 0)+1
        if #r.events<180 and not c.seen then c.seen={} end
        if c.seen and not c.seen[key] and #r.events<180 then c.seen[key]=true; table.insert(r.events,{seconds=at-began,contact={body=pose(body),part=pose(p)},position=vector(root.Position)}) end
       end
      end
     end
     if pairs>0 then r.overlapSamples+=1 end
     c.previousPosition,c.previousSupport,c.previousFrame=root.Position,support,support and support.CFrame
    end
   end,debug.traceback)
   if not sampled then observerFailure=message; cancelled=true end
  end)
  local leaderRelease,boardArrived=nil,{}
  local function hold(i,reason,predicate)
   local at=os.clock(); waitFor(i,predicate,reason); table.insert(contexts[i].report.holds,{reason=reason,seconds=os.clock()-at,endClock=clock()})
  end
  for i,c in contexts do
   c.running=true
   task.spawn(function()
    local ran,message=xpcall(function()
     c.report.driver=Traversal.Run(course,c.player,c.points,{placeAtStart=false,pace=false,aim=c.aim,guard=function()return guard(i)end,
      afterLanding=function(_,point,receipt)
       local r=c.report
       local aim=assert(c.lastAim[point.part],"Selected traversal utility did not use the test-only aim hook")
       local recorded=assert(receipt.landingAim,"Traversal receipt must record the exact applied lane aim")
       assert((Vector3.new(recorded[1],recorded[2],recorded[3])-aim).Magnitude<.02,"Traversal receipt did not retain the applied lane aim")
       receipt.trafficAimPolicy,receipt.trafficAim=r.aimPolicy,vector(aim)
       if point.part.Name=="Shell_ForkWait" or point.part.Name=="Tray_BoardPocket" or point.part.Name=="Shell_ExitWait" then
        local model=if point.part.Name=="Tray_BoardPocket" then mechanisms.SidewaysTray else mechanisms.ShellLip1
        table.insert(r.events,{kind="ActualArrival",part=point.part.Name,clock=clock(),seconds=os.clock()-began,state=model:GetAttribute("ERState"),boardingRemaining=if point.part.Name=="Tray_BoardPocket" then boardRemaining() else nil,position=vector(c.root.Position),support=receipt.support})
       end
       if point.part==mechanisms.ShellLip1.ShellContact then r.firstShellLandingClock=clock() end
       if point.part==mechanisms.SidewaysTray.TrayContact then r.boardedClock=clock() end
       if stage=="TraySplit" and point.part.Name=="Tray_BoardPocket" then
        boardArrived[i]=true
        hold(i,"Both actual board-pocket arrivals before early Boarding",function()return boardArrived[1] and boardArrived[2] and mechanisms.SidewaysTray:GetAttribute("ERState")=="Boarding" and boardRemaining()>3.7 end)
       end
      end},function(index,_,step)
      c.report.lastStep=step
      if index~=1 then return end
      if i==2 then
       if stage=="ShellLate" then hold(i,"Natural ClosingWarning release",function()return contexts[1].report.firstShellLandingClock and mechanisms.ShellLip1:GetAttribute("ERState")=="ClosingWarning"end)
       elseif stage=="TrayLate" then hold(i,"Late departure-warning release",function()
        return contexts[1].report.boardedClock and mechanisms.SidewaysTray:GetAttribute("ERState")=="DepartureWarning" and boardRemaining()<.9
       end)
       elseif stage=="ShellClose" then hold(i,"Close follower release",function()return leaderRelease and os.clock()-leaderRelease>=.45 end) end
      end
      c.report.releaseClock,c.report.releaseSeconds=clock(),os.clock()-began
      if i==1 then leaderRelease=os.clock() end
     end)
     c.report.driver.trafficAimPolicy,c.report.driver.aimCalls=c.report.aimPolicy,c.report.aimCalls
     assert(c.report.aimCalls>0,"Selected traversal has no working test-only aim hook")
     assert(c.report.driver.ok,c.report.driver.failure)
    end,debug.traceback)
    c.report.ok,c.report.failure=ran,if ran then nil else message
    local captured,final=pcall(result,c.player)
    c.report.finalResult,c.report.finalResultFailure=if captured then final else nil,if captured then nil else tostring(final)
    c.done=true; c.running=false
   end)
  end
  repeat RunService.Heartbeat:Wait() until (contexts[1].done and contexts[2].done) or os.clock()>=deadline or cancelled
  cancelled=true
  local cleanupDeadline=os.clock()+3
  repeat RunService.Heartbeat:Wait() until (contexts[1].done and contexts[2].done) or os.clock()>=cleanupDeadline
  report.allDriversStopped=contexts[1].done and contexts[2].done
  assert(report.allDriversStopped,"Driver did not stop cooperatively; end this owned test before another controller")
  assert(not observerFailure,observerFailure)
  for _,c in contexts do
   assert(c.report.ok,c.report.failure)
   assert(result(c.player).falls==c.report.initialResult.falls,"Actual recovery occurred during traffic")
  end
  if stage=="ShellLate" then
   for _,event in contexts[2].report.events do
    if event.kind=="ActualArrival" and event.part=="Shell_ForkWait" then report.lateClosingWarningArrival=event.state=="ClosingWarning" end
   end
   assert(report.lateClosingWarningArrival,"Actual follower ClosingWarning arrival was not established; preserve diagnostic")
  end
  if stage:match("Tray") then
   for _,c in contexts do
    local rides=c.report.driver.trayCarries
    assert(#rides==1 and rides[1].supportedThroughout and math.abs(rides[1].deckDistance-21)<.1,"Full supported ride missing")
   end
   local a,b=contexts[1].report.driver.trayCarries[1],contexts[2].report.driver.trayCarries[1]
   report.rideEndClockDifference=b.endClock-a.endClock
   report.sameRide=math.abs(report.rideEndClockDifference)<.2
   report.nextRide=report.rideEndClockDifference>14.2
   if stage=="TrayLate" then
    for _,event in contexts[2].report.events do
     if event.kind=="ActualArrival" and event.part=="Tray_BoardPocket" then report.lateBoardArrival=event.boardingRemaining<1.1 end
    end
    assert(report.lateBoardArrival,"Actual follower arrival missed the intended late window")
   end
   assert(if stage=="TraySplit" then report.sameRide else report.nextRide,"Requested same/next actual ride was not established")
  end
  report.ok=true
 end,debug.traceback)
 cancelled=true
 local stopDeadline=os.clock()+3
 while os.clock()<stopDeadline do
  local active=false; for _,c in contexts do if c.running then active=true end end
  if not active then break end
  RunService.Heartbeat:Wait()
 end
 if observer then observer:Disconnect() end
 for _,c in contexts do
  local r=c.report
  if c.root.Parent then
   if not c.running then
    c.humanoid:Move(Vector3.zero,false); c.humanoid.Jump=false
    local restored,message=pcall(function()if c.auto then c.root:SetNetworkOwnershipAuto()else c.root:SetNetworkOwner(c.owner)end end)
    r.ownershipRestored,r.restoreFailure=restored,if restored then nil else tostring(message)
   else r.ownershipRestored=false; r.restoreFailure="Driver still active; end owned session" end
  end
  local captured,final=pcall(result,c.player)
  r.finalResult,r.finalResultFailure=if captured then final else nil,if captured then nil else tostring(final)
  if r.driver then
   local carry,hop,settle=0,0,0
   for _,ride in r.driver.trayCarries do if ride.endClock then carry+=ride.endClock-ride.startClock end end
   for _,record in r.driver.records do hop+=record.seconds; settle+=record.settleSeconds end
   r.accounting={hopSecondsIncludingSettle=hop,settleSeconds=settle,admissionSeconds=r.driver.windowWaitSeconds-carry,fullRideSeconds=carry,
    residualSeconds=r.driver.seconds-hop-r.driver.windowWaitSeconds,meaning="Residual includes declared launch/barrier holds; sampled stationary/moving ride bins are separate observations, not added again"}
  end
 end
 report.ok=ok and report.ok; report.failure=if ok then nil else failure; report.observerFailure=observerFailure
 report.seconds,report.complete,report.cleanup=os.clock()-began,true,"Observer disconnected; stopped drivers restore original network ownership; no return placement, CP write or clock reset"
 persist(report); stored:SetAttribute("State",if report.ok then "Complete" else "Failed")
end
stored:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end
 local decoded,command=pcall(function()return Http:JSONDecode(stored:GetAttribute("Command"))end)
 if not decoded or typeof(command)~="table" then stored:SetAttribute("CommandError","Expected JSON object"); return end
 used=true; stored:SetAttribute("State","Running")
 task.spawn(function()
  local ok,message=xpcall(function()run(command)end,debug.traceback)
  if not ok then stored.Value=Http:JSONEncode({ok=false,failure=message}); stored:SetAttribute("State","Failed") end
 end)
end)
