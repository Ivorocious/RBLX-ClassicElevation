--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Storage = game:GetService("ServerStorage")
local Http = game:GetService("HttpService")
local Physics = game:GetService("PhysicsService")
local Logs = game:GetService("LogService")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819, "Owned Studio server only")
local Course = require(game.ServerScriptService.Services.CourseService)
local Race = require(game.ServerScriptService.Services.RaceService)
local Official = require(game.ServerScriptService.Services.PlayerRaceService)
local Results = require(game.ServerScriptService.Services.ResultsService)
local Runtime = require(game.ServerScriptService.Services.EggRushService)
local traversalModule = Storage.CourseBuilders.EggRush:FindFirstChild(script:GetAttribute("TraversalModule") or "NativeTraversal")
assert(traversalModule and traversalModule:IsA("ModuleScript"))
local Traversal = require(traversalModule)
local name = script:GetAttribute("ReportName") or "ERP2ConcurrentExitReport"
assert(typeof(name) == "string" and not Storage:FindFirstChild(name), "Preserve existing reports")
local stored = Instance.new("StringValue")
stored.Name, stored.Parent = name, Storage
stored:SetAttribute("State", "Ready")
local used = false
local function vector(v) return {v.X, v.Y, v.Z} end
local function pose(p)
 return {frame={p.CFrame:GetComponents()}, size=vector(p.Size), canCollide=p.CanCollide, canQuery=p.CanQuery, group=p.CollisionGroup}
end
local function officialResult(player)
 local r = assert(Results.GetPlayerResult(player), "Missing real racer result")
 return {falls=r.falls or 0, lap=r.currentLap, nextCheckpoint=r.nextCheckpointIndex, status=r.status, splits=#(r.checkpointSplits or {})}
end
local function persist(report)
 local json, names = Http:JSONEncode(report), {}
 local payload = Instance.new("Folder")
 payload.Name, payload.Parent = "Payload", stored
 local first = 1
 while first <= #json do
  local last = math.min(first+119999, #json)
  while last < #json do local b=string.byte(json,last+1); if b<128 or b>191 then break end; last-=1 end
  local chunk = Instance.new("StringValue")
  chunk.Name, chunk.Value, chunk.Parent = string.format("Chunk_%03d", #names+1), string.sub(json,first,last), payload
  table.insert(names,chunk.Name); first=last+1
 end
 stored.Value = Http:JSONEncode({format="ERP2ConcurrentExitV1", chunks=names, payloadFolder="Payload", jsonBytes=#json, ok=report.ok})
end
local function boxOverlap(a,b)
 local aa,bb={a.CFrame.RightVector,a.CFrame.UpVector,a.CFrame.LookVector},{b.CFrame.RightVector,b.CFrame.UpVector,b.CFrame.LookVector}
 local axes={aa[1],aa[2],aa[3],bb[1],bb[2],bb[3]}
 for _,x in aa do for _,y in bb do local n=x:Cross(y); if n.Magnitude>.00001 then table.insert(axes,n.Unit) end end end
 local ah,bh={a.Size.X/2,a.Size.Y/2,a.Size.Z/2},{b.Size.X/2,b.Size.Y/2,b.Size.Z/2}
 local delta,minimum=b.Position-a.Position,math.huge
 for _,axis in axes do
  local extent=0
  for i=1,3 do extent+=math.abs(axis:Dot(aa[i]))*ah[i]+math.abs(axis:Dot(bb[i]))*bh[i] end
  local overlap=extent-math.abs(delta:Dot(axis))
  if overlap<0 then return false,overlap end
  minimum=math.min(minimum,overlap)
 end
 return true,minimum
end
local function run(command)
 assert(typeof(command.pace)=="boolean", "Explicit pace=false reproduces Native11; pace=true is a separate control")
 local out={ok=false,cases={},placements={},checkpointWrites=0,profileWrites=0,clockWrites=0,pace=command.pace,
  method="One real official racer and one cloned actual fitted R15 Humanoid; colliding server-owned bodies start on Receive, swap lanes, and use the actual traversal module",
  limits={"Clone is a nonplayer physical fixture: no official enrollment, production carry, progression or recovery claim",
   "Receive placement deliberately excludes boarding/carry; retain the earlier two-real-player supported rides separately",
   "Clone has copied body/joints/collider and no copied character scripts or playing animation tracks; this is not a second client or human",
   "Stop both traversals on the first failure; a recovered rider must not steer back through the other rider's path",
   "Finite two-body exit evidence only; no supported-entry, full-race, twenty-racer, device or FPS claim"}}
 local began,deadline=os.clock(),os.clock()+50
 local player,real,clone,root,originalAuto,originalOwner,observer,logConnection,holder
 local contexts,activeCase,recent={},nil,{}
 local cancelled,caseReleased=false,false
 local function clock() return Runtime.GetDiagnostics().elapsed end
 local function fail(kind,detail)
  if activeCase and not activeCase.firstFailure then
   activeCase.firstFailure={kind=kind,detail=detail,seconds=os.clock()-began,clock=clock(),recentFrames=table.clone(recent)}
  end
  cancelled=true
 end
 local ok,errorMessage=xpcall(function()
  local tag=script:GetAttribute("OwnedTestTag")
  assert(typeof(tag)=="string" and #tag>0 and Workspace:GetAttribute("ERP2OwnedTestTag")==tag, "Owned Solo Play tag required")
  local players=Players:GetPlayers(); assert(#players==1, "Exactly one real Player; do not launch another client")
  player=players[1]; real=assert(player.Character); root=assert(real:FindFirstChild("HumanoidRootPart"))
  local h=assert(real:FindFirstChildOfClass("Humanoid")); local fit=assert(real:FindFirstChild("CollisionPart"))
  assert(h.RigType==Enum.HumanoidRigType.R15 and fit:IsA("Part") and fit.Shape==Enum.PartType.Block and fit.CanCollide)
  assert(h.WalkSpeed==16 and not h.UseJumpPower and math.abs(h.JumpHeight-7.2)<.01 and math.abs(Workspace.Gravity-196.2)<.01)
  assert((real:GetAttribute("RecoveryUntil") or 0)<=Workspace:GetServerTimeNow(), "Real recovery must expire before setup")
  local course=assert(Course.GetActiveCourse()); local expected=script:GetAttribute("ExpectedCandidate") or "ER_P2_R01_C05"
  assert(course:GetAttribute("CandidateId")==expected and course:GetAttribute("FullBodyContacts")==true and course:GetAttribute("EROwned")==true)
  local raceId=Race.GetCurrentRaceId(); local diag=Runtime.GetDiagnostics()
  assert(Race.IsRaceActive() and Official.IsOfficialRacer(player) and Official.GetPlayerStatus(player)=="Racing")
  assert(diag.bound and diag.raceId==raceId and diag.movementProfiles==1, "Use the existing one-player official race")
  originalAuto,originalOwner=root:GetNetworkOwnershipAuto(),root:GetNetworkOwner()
  out.candidateId,out.raceId,out.traversalModule,out.ownedTestTag=expected,raceId,traversalModule:GetFullName(),tag
  out.realBefore=officialResult(player)
  local archivable=real.Archivable; real.Archivable=true
  local cloned,copy=pcall(function() return real:Clone() end)
  real.Archivable=archivable; assert(cloned and copy, tostring(copy)); clone=copy
  clone.Name="_"..name.."_R15Fixture"
  assert(not Workspace:FindFirstChild(clone.Name), "Keep another fixture untouched")
  for _,child in clone:GetDescendants() do if child:IsA("LuaSourceContainer") then child:Destroy() end end
  clone:SetAttribute("ERP2PhysicalFixture",true); clone.Parent=Workspace
  local nh=assert(clone:FindFirstChildOfClass("Humanoid")); local nr=assert(clone:FindFirstChild("HumanoidRootPart")); local nf=assert(clone:FindFirstChild("CollisionPart"))
  assert(nh.RigType==Enum.HumanoidRigType.R15 and (nf.Size-fit.Size).Magnitude<.001 and nh.WalkSpeed==16 and not nh.UseJumpPower and math.abs(nh.JumpHeight-7.2)<.01)
  assert(nf:IsA("Part") and nf.Shape==Enum.PartType.Block and nf.CanCollide and nf.CollisionGroup==fit.CollisionGroup)
  assert(Physics:CollisionGroupsAreCollidable(fit.CollisionGroup,nf.CollisionGroup), "Physical racer collisions must remain enabled")
  out.fixtureBody,out.realBody=pose(nf),pose(fit)
  local o=course.Obstacles; local parts={o.Tray_ReceivePocket,o.S4_ExitClimb.S4_ExitClimb_001,o.S4_ExitClimb.S4_ExitClimb_002,o.S4_ExitClimb.S4_ExitClimb_003,o.S4_ExitClimb.S4_ExitClimb_004,o.CP3_Pocket}
  out.route={}; local points={}
  for _,part in parts do table.insert(points,{part=part}); table.insert(out.route,{name=part.Name,pose=pose(part)}) end
  local ray=RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Include; ray.FilterDescendantsInstances={course}; ray.RespectCanCollide=true
  local function support(c)
   local hit=Workspace:Raycast(c.root.Position,Vector3.new(0,-(c.humanoid.HipHeight+c.root.Size.Y/2+.7),0),ray)
   return hit and hit.Instance
  end
  local baseFalls=out.realBefore.falls
  local function alive()
   return not cancelled and os.clock()<deadline and #Players:GetPlayers()==1 and player.Character==real and h.Health>0 and nh.Health>0
    and Course.GetActiveCourse()==course and Race.GetCurrentRaceId()==raceId and Race.IsRaceActive()
    and Official.GetPlayerStatus(player)=="Racing" and officialResult(player).falls==baseFalls
    and (real:GetAttribute("RecoveryUntil") or 0)<=Workspace:GetServerTimeNow()
  end
  contexts={{actor=player,character=real,root=root,humanoid=h,fit=fit,kind="RealPlayer"},
   {actor={Character=clone},character=clone,root=nr,humanoid=nh,fit=nf,kind="NonplayerPhysicalClone"}}
  local hazards,zones={},{}
  for _,part in course:GetDescendants() do
   if part:IsA("BasePart") and part:GetAttribute("ERLethal")==true then table.insert(hazards,part) end
  end
  for _,part in course.FallZones:GetDescendants() do if part:IsA("BasePart") then table.insert(zones,part) end end
  local npcParams=OverlapParams.new(); npcParams.FilterType=Enum.RaycastFilterType.Include; npcParams.FilterDescendantsInstances={clone}; npcParams.RespectCanCollide=false
  local physical=OverlapParams.new(); physical.FilterType=Enum.RaycastFilterType.Include; physical.RespectCanCollide=true
  local nextFrame=0
  observer=RunService.Heartbeat:Connect(function()
   if not activeCase or cancelled then return end
   local observed,detail=xpcall(function()
    local row={seconds=os.clock()-began,clock=clock(),actors={}}
    for _,c in contexts do
     local standing=support(c)
     local frame={kind=c.kind,step=c.step,position=vector(c.root.Position),velocity=vector(c.root.AssemblyLinearVelocity),rootFrame={c.root.CFrame:GetComponents()},
      collider=pose(c.fit),floor=c.humanoid.FloorMaterial.Name,state=c.humanoid:GetState().Name,health=c.humanoid.Health,support=standing and standing.Name}
     table.insert(row.actors,frame)
     if c.lastFloor~=c.humanoid.FloorMaterial.Name then
      table.insert(c.record.transitions,{seconds=row.seconds,clock=row.clock,frame=frame})
      c.lastFloor=c.humanoid.FloorMaterial.Name
     end
     if c.humanoid.Health<=0 then fail("ActualHumanoidDeath",c.kind) end
     if caseReleased and c.root.Position.Y<parts[1]:GetAttribute("ERTop").Y-3 then fail("BelowEveryExitLanding",frame) end
    end
    if (nf.Size-fit.Size).Magnitude>.03 then fail("CloneColliderShapeDrift",{real=pose(fit),clone=pose(nf)}) end
    physical.CollisionGroup=fit.CollisionGroup; physical.FilterDescendantsInstances={clone}
    local hits=Workspace:GetPartsInPart(fit,physical)
    local overlap,depth=boxOverlap(fit,nf)
    activeCase.observerFrames+=1
    if #hits>0 then activeCase.nativePairOverlapFrames+=1 end
    if overlap and depth>.01 then activeCase.boxPairOverlapFrames+=1 end
    activeCase.maximumBoxOverlap=math.max(activeCase.maximumBoxOverlap,if overlap then depth else 0)
    row.pair={nativeHits=#hits,boxOverlap=overlap,boxOverlapDepth=depth}
    if (#hits>0 or (overlap and depth>.01)) and #activeCase.contactEvents<24 then table.insert(activeCase.contactEvents,row) end
    if os.clock()>=nextFrame then
     nextFrame=os.clock()+1/30; table.insert(recent,row); if #recent>80 then table.remove(recent,1) end
    end
    for _,part in hazards do
     if part.Parent and part.Transparency<1 and part.CanQuery and (part.Position-nr.Position).Magnitude<part.Size.Magnitude/2+10 then
      for _,body in Workspace:GetPartsInPart(part,npcParams) do
       if body.Parent==clone and body.Name~="HumanoidRootPart" and body.Transparency<1 and body.CanQuery then
        fail("CloneVisibleHazardOverlap_NoOfficialRecovery",{hazard=part:GetFullName(),body=body.Name}); break
       end
      end
     end
    end
    for _,zone in zones do
     if zone.Parent and #Workspace:GetPartsInPart(zone,npcParams)>0 then fail("CloneActualFallZoneOverlap_NoOfficialRecovery",zone:GetFullName()) end
    end
    if not alive() then fail("RealRecoveryOrRaceContextChanged",officialResult(player)) end
   end,debug.traceback)
   if not observed then fail("ObserverError",detail) end
  end)
  logConnection=Logs.MessageOut:Connect(function(message)
   if activeCase and string.find(message,"[RespawnService] Respawned "..player.Name.." after ",1,true) then
    table.insert(activeCase.productionRecoveryLog,{message=message,seconds=os.clock()-began,clock=clock()})
    fail("ProductionRealPlayerRecovery",message)
   end
  end)
  for caseIndex,realSide in {-1,1} do
   assert(alive(), "Stop after first case failure")
   activeCase={id=caseIndex,realSide=realSide,pace=command.pace,actors={},contactEvents={},productionRecoveryLog={},observerFrames=0,
    nativePairOverlapFrames=0,boxPairOverlapFrames=0,maximumBoxOverlap=0,ok=false}
   table.insert(out.cases,activeCase); recent={}; caseReleased=false
   for i,c in contexts do
    c.side=if i==1 then realSide else -realSide; c.done=false; c.running=false; c.lastFloor=nil; c.step="ReceiveSetup"
    c.record={kind=c.kind,side=c.side,transitions={},aims={},hops={},done=false}; table.insert(activeCase.actors,c.record)
    local first=parts[1]; local target=first.CFrame:PointToWorldSpace(Vector3.new(c.side*2,first.Size.Y/2,0))+Vector3.new(0,c.humanoid.HipHeight+c.root.Size.Y/2+.15,0)
    c.root:SetNetworkOwner(nil); c.character:PivotTo(CFrame.lookAt(target,target+first.CFrame.LookVector))
    c.root.AssemblyLinearVelocity=Vector3.zero; c.root.AssemblyAngularVelocity=Vector3.zero
    table.insert(out.placements,{case=caseIndex,kind=c.kind,side=c.side,part=first:GetFullName(),position=vector(target),clock=clock()})
   end
   holder=RunService.PreSimulation:Connect(function()for _,c in contexts do c.humanoid:Move(Vector3.zero,false); c.humanoid.Jump=false end end)
   local settled,settleUntil=0,os.clock()+3
   repeat
    assert(alive() and os.clock()<settleUntil,"Initial physical support did not settle")
    RunService.Heartbeat:Wait()
    local stable=true
    for _,c in contexts do stable=stable and support(c)==parts[1] and c.humanoid.FloorMaterial~=Enum.Material.Air and math.abs(c.root.AssemblyLinearVelocity.Y)<2 end
    settled=if stable then settled+1 else 0
   until settled>=2
   holder:Disconnect(); holder=nil; caseReleased=true
   for _,c in contexts do
    local context=c; context.running=true
    task.spawn(function()
     local ran,driver=xpcall(function()
      return Traversal.Run(course,context.actor,points,{placeAtStart=false,pace=command.pace,guard=alive,
       aim=function(part,_,defaultAim)
        assert(alive(),"Stopped concurrent exit after first failure")
        local requested=part.CFrame:PointToObjectSpace(defaultAim+part.CFrame.RightVector*(context.side*2))
        local target=part.CFrame:PointToWorldSpace(Vector3.new(math.clamp(requested.X,-part.Size.X/2+.75,part.Size.X/2-.75),part.Size.Y/2,
         math.clamp(requested.Z,-part.Size.Z/2+.75,part.Size.Z/2-.75)))
        context.record.aims[part.Name]=vector(target); return target
       end,
       afterLanding=function(_,point,receipt)
        table.insert(context.record.hops,{to=point.part.Name,receipt=receipt,root=pose(context.root),collider=pose(context.fit),velocity=vector(context.root.AssemblyLinearVelocity)})
       end},function(_,_,step)context.step=step end)
     end,debug.traceback)
     context.record.driver=if ran then driver else nil; context.record.failure=if ran then driver.failure else driver
     context.record.ok=ran and driver.ok; context.done=true; context.running=false; context.record.done=true
     if context.root.Parent then context.root:SetNetworkOwner(nil) end
     if not context.record.ok then fail("TraversalFailure",{kind=context.kind,failure=context.record.failure}) end
    end)
   end
   repeat RunService.Heartbeat:Wait() until cancelled or (contexts[1].done and contexts[2].done) or os.clock()>=deadline
   if os.clock()>=deadline then fail("FiniteDeadline",50) end
   local stopUntil=os.clock()+3
   repeat RunService.Heartbeat:Wait() until (contexts[1].done and contexts[2].done) or os.clock()>=stopUntil
   assert(contexts[1].done and contexts[2].done,"End this owned Play: a traversal did not stop cooperatively")
   activeCase.realAfter=officialResult(player)
   activeCase.ok=not cancelled and contexts[1].record.ok and contexts[2].record.ok and activeCase.realAfter.falls==baseFalls
   activeCase.lastFrames=table.clone(recent)
   if not activeCase.ok then
    if root.Position.Y<parts[1]:GetAttribute("ERTop").Y-3 and officialResult(player).falls==baseFalls then
     local observeUntil=os.clock()+2
     repeat RunService.Heartbeat:Wait() until officialResult(player).falls>baseFalls or os.clock()>=observeUntil
     activeCase.afterAbortProductionResult=officialResult(player)
    end
    break
   end
  end
  out.allRequestedCasesCompleted=#out.cases==2 and out.cases[1].ok and out.cases[2].ok
  out.ok=out.allRequestedCasesCompleted
 end,debug.traceback)
 cancelled=true
 if holder then holder:Disconnect() end
 local stopUntil=os.clock()+3
 repeat
  local active=false; for _,c in contexts do active=active or c.running end
  if not active then break end
  RunService.Heartbeat:Wait()
 until os.clock()>=stopUntil
 if observer then observer:Disconnect() end
 if logConnection then logConnection:Disconnect() end
 out.allDriversStopped=true
 for _,c in contexts do
  out.allDriversStopped=out.allDriversStopped and not c.running
  if c.humanoid.Parent then c.humanoid:Move(Vector3.zero,false); c.humanoid.Jump=false end
 end
 if clone then clone:Destroy(); out.cloneDestroyed=true end
 if root and root.Parent and originalAuto~=nil then
  local restored,message=pcall(function()if originalAuto then root:SetNetworkOwnershipAuto()else root:SetNetworkOwner(originalOwner)end end)
  out.realOwnershipRestored,out.ownershipRestoreError=restored,if restored then nil else tostring(message)
 end
 if player then local got,r=pcall(officialResult,player); if got then out.realAfter=r end end
 out.ok=ok and out.ok and out.allDriversStopped
 out.failure=if ok then nil else errorMessage
 out.seconds=os.clock()-began
 out.cleanup="Observer/holder/log disconnected, temporary nonplayer rig destroyed, real ownership restored; no final placement or progression/clock write"
 persist(out); stored:SetAttribute("State",if out.ok then "Complete" else "Failed")
end
stored:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end
 local decoded,command=pcall(Http.JSONDecode,Http,stored:GetAttribute("Command"))
 if not decoded or typeof(command)~="table" or typeof(command.pace)~="boolean" then stored:SetAttribute("CommandError","Use {pace=false}; optional separate run uses true"); return end
 used=true; stored:SetAttribute("State","Running")
 task.spawn(function()
  local ok,message=xpcall(function()run(command)end,debug.traceback)
  if not ok then stored.Value=Http:JSONEncode({ok=false,failure=message}); stored:SetAttribute("State","Failed") end
 end)
end)
