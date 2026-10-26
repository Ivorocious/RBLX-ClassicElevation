--!nonstrict
local RunService,Workspace,Players=game:GetService("RunService"),game:GetService("Workspace"),game:GetService("Players")
local Storage,Http,Physics=game:GetService("ServerStorage"),game:GetService("HttpService"),game:GetService("PhysicsService")
assert(RunService:IsStudio()and RunService:IsServer()and game.PlaceId==85558151074819,"Owned Studio server only")
local reportName=script:GetAttribute("ReportName")or"EggRushP2PackReport"
assert(typeof(reportName)=="string"and #reportName>0 and not Storage:FindFirstChild(reportName),"Preserve earlier report; choose a unique ReportName")
local stored=Instance.new("StringValue");stored.Name,stored.Parent=reportName,Storage;stored:SetAttribute("State","Ready")
local services={}
for _,name in {"CourseService","RaceService","PlayerRaceService","ResultsService","EggRushService"}do services[name]=require(game.ServerScriptService.Services[name])end
local traversalName=script:GetAttribute("TraversalModule")or"NativeTraversal"
assert(typeof(traversalName)=="string"and #traversalName>0,"TraversalModule must name the owned test utility")
local traversalModule=assert(Storage.CourseBuilders.EggRush:FindFirstChild(traversalName),"Missing selected traversal utility")
assert(traversalModule:IsA("ModuleScript"),"Select an actual traversal ModuleScript")
local Traversal=require(traversalModule)
local function vector(v)return {v.X,v.Y,v.Z}end
local function pose(p)return {path=p:GetFullName(),size=vector(p.Size),frame={p.CFrame:GetComponents()},canCollide=p.CanCollide,group=p.CollisionGroup}end
local function result(player)
 local r=assert(services.ResultsService.GetPlayerResult(player),"Missing actual official result")
 return {lap=r.currentLap,nextCheckpoint=r.nextCheckpointIndex,falls=r.falls or 0,status=r.status,splitCount=#(r.checkpointSplits or {}),lapTimes=table.clone(r.lapTimes or {})}
end
local function persist(report)
 local encoded,names=Http:JSONEncode(report),{}
 local folder=Instance.new("Folder");folder.Name,folder.Parent="Payload",stored
 local offset=1
 while offset<=#encoded do
  local last=math.min(offset+149999,#encoded)
  while last<#encoded do local b=string.byte(encoded,last+1);if b<128 or b>191 then break end;last-=1 end
  local p=Instance.new("StringValue");p.Name=string.format("Chunk_%03d",#names+1);p.Value=string.sub(encoded,offset,last);p.Parent=folder;table.insert(names,p.Name);offset=last+1
 end
 stored.Value=Http:JSONEncode({format="EggRushP2PackChunksV1",payloadFolder=folder.Name,chunks=names,jsonBytes=#encoded,ok=report.ok})
end
local function run(command)
 local stage=command.stage;assert(stage=="Start"or stage=="ShellPack","Choose Start or ShellPack")
 local report={stage=stage,phase=2,ok=false,participants={},placements={},pairCollision={},contacts={},samples=0,checkpointWrites=0,maximumControllerSeconds=77,maximumCleanupDeadlineSeconds=80,traversalModule=traversalModule:GetFullName(),
  limits="Eight actual official Players with intentional ordinary lanes and distinct terminal grid aims; no 20-player, human-control, device/FPS or universal-arrival proof. A physical controller failure is not a width verdict."}
 local began,contexts,observer,cancelled,observerFailure=os.clock(),{},nil,false,nil
 local deadline=began+77
 local course,raceId
 local function clock()return services.EggRushService.GetDiagnostics().elapsed end
 local function guard(i)
  local c=contexts[i]
  return not cancelled and not observerFailure and os.clock()<deadline and c.player.Character==c.character and c.humanoid.Health>0
   and services.CourseService.GetActiveCourse()==course and services.RaceService.IsRaceActive()and services.RaceService.GetCurrentRaceId()==raceId
   and services.PlayerRaceService.IsOfficialRacer(c.player)and services.PlayerRaceService.GetPlayerStatus(c.player)=="Racing"
   and result(c.player).falls==c.report.initialResult.falls
 end
 local function waitFor(i,predicate)
  repeat assert(guard(i),"Actor/race changed, real fall, observer error or bounded deadline");RunService.Heartbeat:Wait()until predicate()
 end
 local ok,failure=xpcall(function()
  local tag=script:GetAttribute("OwnedStudioTestTag");local args=game:GetService("StudioTestService"):GetTestArgs()
  assert(typeof(tag)=="string"and #tag>0 and typeof(args)=="table"and args.tag==tag,"Exact owned Studio test tag required")
  course=assert(services.CourseService.GetActiveCourse())
  assert(course:GetAttribute("CandidateId")== (script:GetAttribute("ExpectedCandidate")or"ER_P2_R01_C03")
   and course:GetAttribute("CourseId")=="egg_rush_circuit"and course:GetAttribute("EROwned")==true and course:GetAttribute("Phase")==2
   and course:GetAttribute("SampleRevision")==3 and course:GetAttribute("FullBodyContacts")==true,"Wrong owned full-contact Phase2 course")
  raceId=services.RaceService.GetCurrentRaceId();local diagnostics=services.EggRushService.GetDiagnostics()
  assert(services.RaceService.IsRaceActive()and raceId~=""and diagnostics.bound and diagnostics.raceId==raceId and diagnostics.movementProfiles==8,"Prepare eight actual bound official racers")
  assert(math.abs(Workspace.Gravity-196.2)<.01,"Wrong gravity")
  local players=Players:GetPlayers();assert(#players==8,"Exactly eight actual Players required; no virtual racers")
  table.sort(players,function(a,b)return a.UserId<b.UserId end)
  report.candidateId,report.raceId,report.ownedStudioTestTag,report.pacingRevision=course:GetAttribute("CandidateId"),raceId,tag,course:GetAttribute("PacingRevision")
  local shells={}
  for _,m in course.Obstacles.Mechanisms:GetChildren()do
   if m:GetAttribute("ERMechanism")=="ShellLip"then
    table.insert(shells,m);local count=0
    for _,p in m:GetDescendants()do if p:IsA("BasePart")and p:GetAttribute("ERSupport")==true then assert(p.CanCollide);count+=1 end end
    assert(count==8,"Keep all eight physical shell volumes")
   end
  end
  assert(#shells==9,"Missing actual R03 shells")
  for i,player in players do
   local character=assert(player.Character);local root=assert(character:FindFirstChild("HumanoidRootPart"));local h=assert(character:FindFirstChildOfClass("Humanoid"))
   local fit=assert(character:FindFirstChild("CollisionPart"))
   assert(not root.Anchored and fit.CanCollide and h.WalkSpeed==16 and not h.UseJumpPower and math.abs(h.JumpHeight-7.2)<.01,"Actual fitted 16/7.2 profile required")
   assert((character:GetAttribute("RecoveryUntil")or 0)<=Workspace:GetServerTimeNow(),"Wait until actual recovery immunity expires")
   local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={course};ray.RespectCanCollide=true
   local r={userId=player.UserId,wave=if i<=4 then 1 else 2,initialResult=result(player),fit=pose(fit),body={},events={},samples={},overlapPairs={},overlapSamples=0}
   local c={player=player,character=character,root=root,humanoid=h,report=r,owner=root:GetNetworkOwner(),auto=root:GetNetworkOwnershipAuto(),ray=ray,bodies={}}
   contexts[i],report.participants[i]=c,r
   assert(guard(i),"All eight must be actual current official racing actors")
   for _,p in character:GetChildren()do if p:IsA("BasePart")then table.insert(r.body,pose(p))end end
   for _,name in {"Head","UpperTorso","LowerTorso","CollisionPart"}do table.insert(c.bodies,assert(character:FindFirstChild(name)))end
   local function support()
    local hit=Workspace:Raycast(root.Position,Vector3.new(0,-(h.HipHeight+root.Size.Y/2+.7),0),ray);return hit and hit.Instance
   end
   c.support=support
   local actual=support()
   r.delivered={position=vector(root.Position),support=actual and actual:GetFullName(),floor=h.FloorMaterial.Name,clock=clock()}
   if stage=="Start"then
    assert(actual==course.Start and h.FloorMaterial~=Enum.Material.Air,"Actual delivered Start support required; no corrective placement")
    assert(r.initialResult.nextCheckpoint==1,"Start stage requires the actual lap's unearned CP1")
    r.line=if i%2==1 then "Normal"else"Expert"
    c.points={}
    for _,p in Traversal.Points(course,r.line)do table.insert(c.points,p);if p.part==course.Obstacles.CP1_Pocket then break end end
    assert(c.points[#c.points].part==course.Obstacles.CP1_Pocket,"Start stage must include the first fork and actual CP1 merge")
   else
    r.line="Normal"
    local all=Traversal.Points(course,"Normal","Shellworks")
    local startName=if i<=4 then "Shell_ForkWait"else string.format("S3_ShellApproach_%03d",9-i)
    c.points={};local include=false
    for _,p in all do if p.part.Name==startName then include=true end;if include then table.insert(c.points,p)end end
    local incubator=Traversal.Points(course,"Normal","Incubator")
    for n=2,#incubator do
     local p=incubator[n];table.insert(c.points,p);if p.part==course.Obstacles.Tray_BoardPocket then break end
    end
    assert(c.points[#c.points].part==course.Obstacles.Tray_BoardPocket,"Shell pack must clear Exit and stop before the tray ride")
    assert(#c.points>1,"Missing actual focused start")
    local first=c.points[1].part;local x=if i<=4 then (i-2.5)*5 else 0
    assert(first.Anchored and first.CanCollide and math.abs(x)<=first.Size.X/2-3,"Declared root must fit actual fixed support footprint")
    local target=first.CFrame*CFrame.new(x,first.Size.Y/2+h.HipHeight+root.Size.Y/2+.15,0)
    table.insert(report.placements,{userId=player.UserId,kind="InitialFocusedShellSetup",part=first:GetFullName(),frame={target:GetComponents()},localX=x,clock=clock()})
    root:SetNetworkOwner(nil);character:PivotTo(target);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
   end
   local side=if i%2==1 then -1 else 1
   local column=(i-1)%4
   local gridX=if stage=="Start"then -6+column*4 else -7.2+column*4.8
   local gridZ=(if i<=4 then -1 else 1)*(if stage=="Start"then 2.4 else 2)
   c.terminal=c.points[#c.points].part
   assert(math.abs(gridX)<=c.terminal.Size.X/2-.75 and math.abs(gridZ)<=c.terminal.Size.Z/2-.75,"Eight distinct terminal grid targets must fit without clamping together")
   r.aimPolicy={name="PackOrdinaryLanesV2",side=side,ordinaryRight=side*1.8,shellGlobalZ=side*2.4,terminal=c.terminal:GetFullName(),terminalLocalX=gridX,terminalLocalZ=gridZ,footprintInset=.75}
   r.aimCalls,r.aimTargets=0,{};c.lastAim={}
   c.aim=function(part,_,defaultAim)
    local requested
    if part==c.terminal then requested=Vector3.new(gridX,part.Size.Y/2,gridZ)
    else
     local name=part.Name
     local offset=if name=="ShellContact"or name=="Shell_ForkWait"or name=="Shell_MiddleWait"or name=="Shell_ExitWait"then Vector3.new(0,0,side*2.4)else part.CFrame.RightVector*(side*1.8)
     requested=part.CFrame:PointToObjectSpace(defaultAim+offset)
    end
    local x,z=math.max(0,part.Size.X/2-.75),math.max(0,part.Size.Z/2-.75)
    local localAim=Vector3.new(math.clamp(requested.X,-x,x),part.Size.Y/2,math.clamp(requested.Z,-z,z))
    assert(math.abs(localAim.X)<part.Size.X/2 and math.abs(localAim.Z)<part.Size.Z/2,"Lane/grid aim must remain inside the actual support")
    local aim=part.CFrame:PointToWorldSpace(localAim);r.aimCalls+=1;c.lastAim[part]=aim
    local key=part:GetFullName();local entry=r.aimTargets[key]or{firstAim=vector(aim),calls=0}
    entry.calls+=1;entry.lastAim,entry.localAim=vector(aim),vector(localAim)
    entry.clamped=math.abs(requested.X-localAim.X)>.001 or math.abs(requested.Z-localAim.Z)>.001;r.aimTargets[key]=entry
    return aim
   end
   local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.RespectCanCollide=true;c.overlap=overlap
  end
  for i,c in contexts do
   local include=table.clone(shells)
   for j,other in contexts do if i~=j then table.insert(include,other.character)end end
   c.overlap.FilterDescendantsInstances=include
   for j=i+1,8 do
    local other=contexts[j];local enabled=Physics:CollisionGroupsAreCollidable(c.character.CollisionPart.CollisionGroup,other.character.CollisionPart.CollisionGroup)
    table.insert(report.pairCollision,{a=i,b=j,enabled=enabled,initialDistance=(c.root.Position-other.root.Position).Magnitude})
    assert(enabled,"Preserve actual racer/racer collision for the pack test")
   end
  end
  local lastSample=0
  observer=RunService.Heartbeat:Connect(function()
   local observed,message=xpcall(function()
    local at=os.clock();if at-lastSample<.15 then return end;lastSample=at;report.samples+=1
    for i,c in contexts do
     local actual=c.support();local r=c.report;local minimum=math.huge;local closest
     for j,other in contexts do if i~=j then local distance=(c.root.Position-other.root.Position).Magnitude;if distance<minimum then minimum,closest=distance,j end end end
     r.minimumOtherDistance=math.min(r.minimumOtherDistance or math.huge,minimum)
     if #r.samples<520 then table.insert(r.samples,{seconds=at-began,clock=clock(),position=vector(c.root.Position),support=actual and actual:GetFullName(),floor=c.humanoid.FloorMaterial.Name,nearest=closest,distance=minimum,falls=result(c.player).falls,step=r.lastStep})end
     local hits=0
     for _,body in c.bodies do
      c.overlap.CollisionGroup=body.CollisionGroup
      for _,p in Workspace:GetPartsInPart(body,c.overlap)do
       if p.CanCollide then
        hits+=1;local key=body.Name.." -> "..p:GetFullName();r.overlapPairs[key]=(r.overlapPairs[key]or 0)+1
        c.seen=c.seen or{}
        if not c.seen[key]and #report.contacts<96 then
         c.seen[key]=true;table.insert(report.contacts,{actor=i,seconds=at-began,body=pose(body),part=pose(p),position=vector(c.root.Position)})
        end
       end
      end
     end
     if hits>0 then r.overlapSamples+=1 end
    end
   end,debug.traceback)
   if not observed then observerFailure=message;cancelled=true end
  end)
  local releaseAt=os.clock()
  local function firstWaveEntered()
   for i=1,4 do if not contexts[i].report.firstShellLandingClock then return false end end
   return true
  end
  local secondWaveRelease
  for i,c in contexts do
   c.running=true
   task.spawn(function()
    local passed,message=xpcall(function()
     c.report.driver=Traversal.Run(course,c.player,c.points,{placeAtStart=false,pace=false,aim=c.aim,guard=function()return guard(i)end,
      afterLanding=function(_,point,receipt)
       local aim=assert(c.lastAim[point.part],"Selected traversal did not use the optional test aim hook")
       local exact=assert(receipt.landingAim,"Traversal must record the exact applied aim")
       assert((Vector3.new(exact[1],exact[2],exact[3])-aim).Magnitude<.02,"Hop receipt does not match the applied lane/grid aim")
       receipt.packAimPolicy,receipt.packAim=c.report.aimPolicy,vector(aim)
       if point.part==course.Obstacles.Mechanisms.ShellLip1.ShellContact then c.report.firstShellLandingClock=clock()end
       if #c.report.events<24 then table.insert(c.report.events,{kind="SupportedLanding",part=point.part.Name,support=receipt.support,clock=clock(),seconds=os.clock()-began,position=vector(c.root.Position)})end
       if point.part==c.terminal then
        if stage=="Start"then
         local limit=os.clock()+.75
         waitFor(i,function()return result(c.player).nextCheckpoint==2 or os.clock()>=limit end)
         local actual=result(c.player)
         assert(actual.nextCheckpoint==2 and actual.lap==c.report.initialResult.lap and actual.splitCount==c.report.initialResult.splitCount+1,"Actual CP1 checkpoint progress missing at the supported merge")
         c.report.cp1ProgressObserved=true
        end
        c.report.terminalOfficial=result(c.player)
       end
      end},function(index,_,step)
      c.report.lastStep=step
      if index~=1 then return end
      if stage=="Start"then waitFor(i,function()return os.clock()-releaseAt>=(i-1)*.5 end)
      elseif i<=4 then waitFor(i,function()return os.clock()-releaseAt>=(i-1)*.8 end)
      else
       waitFor(i,firstWaveEntered)
       if not secondWaveRelease then secondWaveRelease=os.clock()end
       waitFor(i,function()return os.clock()-secondWaveRelease>=(i-5)*.55 end)
      end
      c.report.actualReleaseSeconds,c.report.actualReleaseClock=os.clock()-began,clock()
     end)
     c.report.driver.packAimPolicy,c.report.driver.aimCalls=c.report.aimPolicy,c.report.aimCalls
     assert(c.report.aimCalls>0,"Selected traversal utility has no working aim hook")
     assert(c.report.driver.ok,c.report.driver.failure)
    end,debug.traceback)
    c.report.ok,c.report.failure=passed,if passed then nil else message
    c.done,c.running=true,false
    if not passed then
     report.firstControllerFailure=report.firstControllerFailure or {actor=i,seconds=os.clock()-began,message=message}
     cancelled=true
    end
   end)
  end
  local function allStopped()for _,c in contexts do if c.running then return false end end;return true end
  repeat RunService.Heartbeat:Wait()until allStopped()or cancelled or os.clock()>=deadline
  cancelled=true
  local stopAt=math.min(began+80,os.clock()+3)
  while not allStopped()and os.clock()<stopAt do RunService.Heartbeat:Wait()end
  report.allDriversStopped=allStopped();assert(report.allDriversStopped,"End owned session before any other controller; driver did not stop")
  assert(not observerFailure,observerFailure)
  for _,c in contexts do
   assert(c.report.ok,c.report.failure)
   assert(result(c.player).falls==c.report.initialResult.falls,"Real recovery occurred during pack test")
   local actual=c.support();local wanted=c.points[#c.points].part
   local position=wanted.CFrame:PointToObjectSpace(c.root.Position)
   assert(actual and actual:IsDescendantOf(course)and c.humanoid.FloorMaterial~=Enum.Material.Air
    and math.abs(position.X)<=wanted.Size.X/2 and math.abs(position.Z)<=wanted.Size.Z/2,"Final supported join footprint was lost while later racers arrived")
  end
  report.ok=true
 end,debug.traceback)
 cancelled=true
 local stopAt=math.min(began+80,os.clock()+3)
 while os.clock()<stopAt do
  local active=false;for _,c in contexts do if c.running then active=true end end
  if not active then break end;RunService.Heartbeat:Wait()
 end
 if observer then observer:Disconnect()end
 for _,c in contexts do
  if c.root.Parent and not c.running then
   c.humanoid:Move(Vector3.zero,false);c.humanoid.Jump=false
   local restored,message=pcall(function()if c.auto then c.root:SetNetworkOwnershipAuto()else c.root:SetNetworkOwner(c.owner)end end)
   c.report.ownershipRestored,c.report.restoreFailure=restored,if restored then nil else tostring(message)
  else c.report.ownershipRestored=false;c.report.restoreFailure="Actor removed or driver still running; end owned session"end
  local captured,final=pcall(result,c.player);c.report.finalResult=if captured then final else nil
  if not captured then c.report.finalResultFailure=tostring(final)end
  report.ok=report.ok and c.report.ownershipRestored
 end
 report.ok=ok and report.ok;report.failure=if ok then nil else failure;report.observerFailure=observerFailure
 report.seconds,report.complete,report.cleanup=os.clock()-began,true,"Observer disconnected; stopped actors restore original ownership; no CP, profile, clock or collision writes and no final return placements"
 persist(report);stored:SetAttribute("State",if report.ok then "Complete"else"Failed")
end
local used=false
stored:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end
 local decoded,command=pcall(function()return Http:JSONDecode(stored:GetAttribute("Command"))end)
 if not decoded or typeof(command)~="table"then stored:SetAttribute("CommandError","Expected JSON object");return end
 used=true;stored:SetAttribute("State","Running")
 task.spawn(function()local ok,message=xpcall(function()run(command)end,debug.traceback);if not ok then stored.Value=Http:JSONEncode({ok=false,failure=message});stored:SetAttribute("State","Failed")end end)
end)
