--!nonstrict
local Test = {}
local RunService, Players, Workspace = game:GetService("RunService"), game:GetService("Players"), game:GetService("Workspace")

local BODY_NAMES = {
 Head=true, Torso=true, UpperTorso=true, LowerTorso=true,
 ["Left Arm"]=true, ["Right Arm"]=true, ["Left Leg"]=true, ["Right Leg"]=true,
 LeftUpperArm=true, LeftLowerArm=true, LeftHand=true, RightUpperArm=true, RightLowerArm=true, RightHand=true,
 LeftUpperLeg=true, LeftLowerLeg=true, LeftFoot=true, RightUpperLeg=true, RightLowerLeg=true, RightFoot=true,
}
local FOOT_NAMES = {LeftFoot=true, RightFoot=true, ["Left Leg"]=true, ["Right Leg"]=true}

local function vector(value)
 return {value.X, value.Y, value.Z}
end

local function half(frame, size)
 return Vector3.new(
  math.abs(frame.RightVector.X)*size.X + math.abs(frame.UpVector.X)*size.Y + math.abs(frame.LookVector.X)*size.Z,
  math.abs(frame.RightVector.Y)*size.X + math.abs(frame.UpVector.Y)*size.Y + math.abs(frame.LookVector.Y)*size.Z,
  math.abs(frame.RightVector.Z)*size.X + math.abs(frame.UpVector.Z)*size.Y + math.abs(frame.LookVector.Z)*size.Z
 )/2
end

function Test.Run(expectedCandidate, comparison)
 local began = os.clock()
 local report = {
  candidate=expectedCandidate, comparison=comparison, stage="Preparation", placements={}, trace={},
  fallTouches={}, roofOverlaps={}, roofPlaneCrossings={}, scenerySupports={}, groundedAfterDeparture={}, progressWrites=0, clockWrites=0,
  profileWrites=0, geometryWrites=0, immunityWrites=0,
  method="One declared supported placement at the first tray center, actual outward carry, then an ordinary westward walking drop",
  limits="One scripted real racer and one drop; not a human visual judgment, full route, crowd, device or performance proof",
 }
 local services, player, course, character, root, humanoid, collider
 local tray, deck, roof, fall, owner, ownerAuto, initial, runtimeBefore, expectedRecovery
 local controller, observer, fallConnection, observerFailure
 local movement = Vector3.zero
 local result, snapshot

 local ok, failure = xpcall(function()
  assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId==85558151074819, "Owned Studio server required")
  assert(comparison=="before" or comparison=="after", "Comparison must be before or after")
  assert(type(expectedCandidate)=="string" and #expectedCandidate>0, "Expected candidate ID required")
  services = {}
  for _, name in {"CourseService", "RaceService", "PlayerRaceService", "CheckpointService", "ResultsService", "EggRushService"} do
   services[name] = require(game.ServerScriptService.Services[name])
  end
  assert(#Players:GetPlayers()==1, "One isolated actual client required")
  player = Players:GetPlayers()[1]
  course, character = assert(services.CourseService.GetActiveCourse()), assert(player.Character)
  root, humanoid = assert(character:FindFirstChild("HumanoidRootPart")), assert(character:FindFirstChildOfClass("Humanoid"))
  collider = assert(character:FindFirstChild("CollisionPart"))
  owner, ownerAuto = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto()
  local colliderSize = collider.Size
  local raceId = services.RaceService.GetCurrentRaceId()
  report.userId, report.raceId = player.UserId, raceId

  result = function()
   local value = assert(services.ResultsService.GetPlayerResult(player))
   return {
    lap=value.currentLap, nextCheckpoint=value.nextCheckpointIndex, falls=value.falls or 0,
    lapTimes=table.clone(value.lapTimes or {}), splits=#(value.checkpointSplits or {}),
    latest=services.CheckpointService.GetLatestCheckpointIndex(player), status=services.PlayerRaceService.GetPlayerStatus(player),
   }
  end
  initial = result()
  report.before = initial
  runtimeBefore = services.EggRushService.GetDiagnostics()
  report.runtimeBefore = runtimeBefore

  local function guard()
   script:SetAttribute("Progress", report.stage)
   assert(not observerFailure, observerFailure)
   assert(os.clock()-began<45 and player.Character==character and humanoid.Health>0, "Bounded original character changed")
   assert(services.CourseService.GetActiveCourse()==course and services.RaceService.GetCurrentRaceId()==raceId, "Actual course or race changed")
   assert(services.RaceService.IsRaceActive() and services.PlayerRaceService.IsOfficialRacer(player) and result().status=="Racing", "Actual eligible Racing participant required")
   assert(not services.CourseService.IsInspectionMode() and not services.RaceService.IsInspectionUnlimitedTime(), "No inspection override")
   assert(not root.Anchored and humanoid.WalkSpeed==16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.01 and math.abs(Workspace.Gravity-196.2)<.01, "Ordinary accepted movement required")
   assert(collider.CanCollide and (collider.Size-colliderSize).Magnitude<.02 and services.EggRushService.GetDiagnostics().bound, "Current fitted body and runtime required")
   local falls = result().falls
   assert(falls<=initial.falls+1, "More than one actual recovery")
   if report.stage~="WalkingWest" and report.stage~="Falling" and report.stage~="Recovered" then
    assert(falls==initial.falls, "Actual recovery occurred before the requested drop")
   end
  end
  local function waitFor(predicate, seconds, message)
   local deadline = os.clock()+seconds
   repeat
    guard()
    if predicate() then return end
    RunService.Heartbeat:Wait()
   until os.clock()>deadline
   error(message)
  end

  assert(course:GetAttribute("CourseId")=="egg_rush_circuit" and course:GetAttribute("CandidateId")==expectedCandidate and course:GetAttribute("FullBodyContacts")==true, "Expected Egg Rush candidate required")
  assert(runtimeBefore.bound and runtimeBefore.stats and type(runtimeBefore.elapsed)=="number", "Bound live hazard diagnostics required")
  assert((character:GetAttribute("RecoveryUntil") or 0)<=Workspace:GetServerTimeNow(), "Existing recovery immunity must have expired")
  local ray = RaycastParams.new()
  ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {course}, true
  local function support()
   local hit = Workspace:Raycast(root.Position, Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.7),0), ray)
   return hit and hit.Instance
  end
  guard()
  assert(support()==course.Start and humanoid.FloorMaterial~=Enum.Material.Air, "Begin physically supported on the delivered Start")

  tray = assert(course.Obstacles.Mechanisms:FindFirstChild("SidewaysTray"))
  deck = assert(tray:FindFirstChild("TrayContact"))
  assert(tray:GetAttribute("ERMechanism")=="Tray" and deck:IsA("BasePart") and deck.CanCollide and deck.CanQuery, "Actual first-tray support required")
  local travel = tray:GetAttribute("Travel")
  assert(typeof(travel)=="Vector3" and math.abs(travel.Magnitude-16)<.01, "The first tray must retain its authored 16-stud carry")
  local world = assert(course.Decoration:FindFirstChild("HatcheryWorld"))
  local buildings = {}
  for _, object in world:GetDescendants() do
   if object.Name=="TankEastService" and object:IsA("Model") then table.insert(buildings, object) end
  end
  assert(#buildings==1, "Exactly one TankEastService model required")
  roof = assert(buildings[1]:FindFirstChild("RoofDeck", true))
  assert(roof:IsA("BasePart") and roof.CFrame.UpVector:Dot(Vector3.yAxis)>.99, "Horizontal TankEastService roof required")
  fall = assert(course.FallZones:FindFirstChild("FallZone_Main"))
  assert(fall:IsA("BasePart") and fall.CanTouch, "Actual touch-enabled fall zone required")
  expectedRecovery = assert(services.CheckpointService.GetCheckpointRespawnCFrame(player))
  local pivot = course:GetPivot()
  local west = pivot:VectorToWorldSpace(-Vector3.xAxis)
  west = Vector3.new(west.X,0,west.Z).Unit
  assert(deck.CFrame.RightVector:Dot(-west)>.99, "Tray west edge must match the course west direction")

  local feet, bodies = {}, {}
  for _, part in character:GetChildren() do
   if part:IsA("BasePart") and BODY_NAMES[part.Name] and part.Transparency<1 and part.CanQuery then
    table.insert(bodies, part)
    if FOOT_NAMES[part.Name] then table.insert(feet, part) end
   end
  end
  assert(#feet==2 and #bodies>0, "Two visible queryable feet and the actual racer body are required")
  local bodyQuery = OverlapParams.new()
  bodyQuery.FilterType, bodyQuery.FilterDescendantsInstances, bodyQuery.RespectCanCollide = Enum.RaycastFilterType.Include, bodies, false
  local roofTop = roof.Position.Y + half(roof.CFrame,roof.Size).Y
  local fallTop = fall.Position.Y + half(fall.CFrame,fall.Size).Y
  report.geometry = {
   coursePivot={pivot:GetComponents()}, roof={path=roof:GetFullName(), frame={roof.CFrame:GetComponents()}, size=vector(roof.Size), top=roofTop, collide=roof.CanCollide, query=roof.CanQuery, transparency=roof.Transparency},
   fall={path=fall:GetFullName(), frame={fall.CFrame:GetComponents()}, size=vector(fall.Size), top=fallTop, touch=fall.CanTouch},
   tray={path=tray:GetFullName(), deck=deck:GetFullName(), size=vector(deck.Size), travel=vector(travel)},
   expectedRecovery={expectedRecovery:GetComponents()}, west=vector(west),
  }

  snapshot = function()
   local footBottom, footOverRoof = math.huge, false
   local footFrames = {}
   for _, foot in feet do
    local relative = roof.CFrame:ToObjectSpace(foot.CFrame)
    local extent = half(relative,foot.Size)
    local projected = math.abs(relative.Position.X)<=roof.Size.X/2+extent.X and math.abs(relative.Position.Z)<=roof.Size.Z/2+extent.Z
    local bottom = foot.Position.Y-half(foot.CFrame,foot.Size).Y
    footBottom = math.min(footBottom,bottom)
    footOverRoof = footOverRoof or projected
    table.insert(footFrames,{name=foot.Name, bottom=bottom, projectedOverRoof=projected, position=vector(foot.Position)})
   end
   local relativeRoot = roof.CFrame:PointToObjectSpace(root.Position)
   local solid = support()
   return {
    seconds=os.clock()-began, stage=report.stage, root=vector(root.Position), rootY=root.Position.Y,
    feetBottom=footBottom, feet=footFrames, colliderBottom=collider.Position.Y-half(collider.CFrame,collider.Size).Y,
    roofTop=roofTop, rootOverRoof=math.abs(relativeRoot.X)<=roof.Size.X/2 and math.abs(relativeRoot.Z)<=roof.Size.Z/2,
    footOverRoof=footOverRoof, velocity=vector(root.AssemblyLinearVelocity), floor=tostring(humanoid.FloorMaterial),
    airborne=humanoid.FloorMaterial==Enum.Material.Air, humanoidState=humanoid:GetState().Name,
    support=solid and solid:GetFullName(), trayState=tray:GetAttribute("ERState"), result=result(),
   }
  end
  local previous, lastTrace = nil, 0
  observer = RunService.PostSimulation:Connect(function()
   local observed, message = xpcall(function()
    if report.stage~="WalkingWest" and report.stage~="Falling" then return end
    if result().falls>initial.falls then
     movement=Vector3.zero
     if not report.firstRecovery then report.firstRecovery=snapshot() end
     return
    end
    local sample = snapshot()
    if sample.airborne and support()~=deck then
     report.airborneObserved=true
    elseif report.airborneObserved and not sample.airborne then
     table.insert(report.groundedAfterDeparture,sample)
    end
    if previous then
     for index, foot in sample.feet do
      local prior=previous.feet[index]
      if prior.name==foot.name and prior.bottom>roofTop and foot.bottom<=roofTop then
       table.insert(report.roofPlaneCrossings,{foot=foot.name, before=previous, after=sample,
        projectedOverRoof=prior.projectedOverRoof or foot.projectedOverRoof})
      end
     end
    end
    if sample.support and not sample.airborne then
     local solid = support()
     if solid and solid:IsDescendantOf(world) then table.insert(report.scenerySupports, sample) end
    end
    for _, part in Workspace:GetPartsInPart(roof,bodyQuery) do
     table.insert(report.roofOverlaps,{seconds=sample.seconds, body=part.Name, root=sample.root, airborne=sample.airborne, support=sample.support})
    end
    if os.clock()-lastTrace>=.04 then
     lastTrace=os.clock()
     table.insert(report.trace,sample)
    end
    report.minimumFeetBeforeRecovery=math.min(report.minimumFeetBeforeRecovery or sample.feetBottom,sample.feetBottom)
    report.lastFallingSample=sample
    previous=sample
   end,debug.traceback)
   if not observed then observerFailure=tostring(message);movement=Vector3.zero end
  end)
  fallConnection = fall.Touched:Connect(function(part)
   if part:IsDescendantOf(character) then
    table.insert(report.fallTouches,{body=part.Name, seconds=os.clock()-began, source=fall:GetFullName()})
   end
  end)

  local board = assert(tray:GetAttribute("BoardSeconds"))
  local warning = assert(tray:GetAttribute("WarningSeconds"))
  local move = assert(tray:GetAttribute("MoveSeconds"))
  local exit = assert(tray:GetAttribute("ExitSeconds"))
  local closing = assert(tray:GetAttribute("ClosingWarningSeconds"))
  local phase = tray:GetAttribute("PhaseSeconds") or 0
  local function boardingRemaining()
   local elapsed = assert(services.EggRushService.GetDiagnostics().elapsed)
   local time = (elapsed+phase)%(board+warning+move+exit+closing+move)
   return if tray:GetAttribute("ERState")=="Boarding" and time<board then board-time else 0
  end
  report.stage="WaitingForBoarding"
  waitFor(function()
   assert(support()==course.Start and humanoid.FloorMaterial~=Enum.Material.Air, "Lost delivered Start support while waiting")
   return boardingRemaining()>=1.5
  end,16,"Actual early boarding window did not occur")
  report.boarding={clock=services.EggRushService.GetDiagnostics().elapsed, remaining=boardingRemaining(), state=tray:GetAttribute("ERState")}
  root:SetNetworkOwner(nil)
  local ground = deck.Position + deck.CFrame.UpVector*deck.Size.Y/2
  local target = ground + Vector3.yAxis*(humanoid.HipHeight+root.Size.Y/2+.15)
  character:PivotTo(CFrame.lookAt(target,target+west)*root.CFrame:ToObjectSpace(character:GetPivot()))
  root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
  table.insert(report.placements,{part=deck:GetFullName(), rootTarget=vector(target), facing=vector(west), trayState=tray:GetAttribute("ERState")})
  report.stage="SettlingOnTray"
  local settleUntil=os.clock()+.18
  waitFor(function()return os.clock()>=settleUntil and support()==deck and humanoid.FloorMaterial~=Enum.Material.Air end,2,"Declared setup did not settle on the actual tray")
  assert(tray:GetAttribute("ERState")=="Boarding" or tray:GetAttribute("ERState")=="DepartureWarning", "Missed the start of the outward carry")
  report.setup=snapshot()
  controller=RunService.PreSimulation:Connect(function()
   if result().falls>initial.falls then movement=Vector3.zero end
   humanoid:Move(movement,false)
   humanoid.Jump=false
  end)

  report.stage="OutwardCarry"
  local initialDeck, initialRoot, initialRelative = deck.CFrame, root.Position, deck.CFrame:PointToObjectSpace(root.Position)
  local carry={samples=0,travelSamples=0,maximumLocalDrift=0,expectedDistance=travel.Magnitude,startClock=services.EggRushService.GetDiagnostics().elapsed}
  report.carry=carry
  waitFor(function()
   local currentSupport, state = support(), tray:GetAttribute("ERState")
   carry.samples+=1
   if state=="Travel" then carry.travelSamples+=1 end
   carry.lastState, carry.lastSupport = state, currentSupport and currentSupport:GetFullName()
   local delta=deck.CFrame:PointToObjectSpace(root.Position)-initialRelative
   carry.maximumLocalDrift=math.max(carry.maximumLocalDrift,Vector3.new(delta.X,0,delta.Z).Magnitude)
   assert(currentSupport==deck and humanoid.FloorMaterial~=Enum.Material.Air, "Lost physical tray support during outward carry")
   return state=="Exit"
  end,10,"First tray did not reach its actual outward endpoint")
  carry.deckDistance=(deck.Position-initialDeck.Position).Magnitude
  carry.rootDistance=(root.Position-initialRoot).Magnitude
  carry.endClock=services.EggRushService.GetDiagnostics().elapsed
  carry.supportedThroughout=true
  assert(carry.travelSamples>0 and math.abs(carry.deckDistance-carry.expectedDistance)<.1 and math.abs(carry.rootDistance-carry.expectedDistance)<1 and carry.maximumLocalDrift<1.5, "Actual full supported outward carry required")

  report.stage="WalkingWest"
  report.dropStart=snapshot()
  report.targetDeckLocalX=-(deck.Size.X/2+1.5)
  movement=west
  waitFor(function()
   assert(result().falls==initial.falls, "Recovered before the walking drop left the tray")
   return deck.CFrame:PointToObjectSpace(root.Position).X<=report.targetDeckLocalX
  end,1.5,"Westward walk did not reach the declared drop line")
  movement=Vector3.zero
  waitFor(function()return humanoid.FloorMaterial==Enum.Material.Air and support()~=deck end,.8,"Westward walking drop did not leave the tray")
  report.airborne=snapshot()
  report.stage="Falling"
  waitFor(function()return result().falls==initial.falls+1 end,6,"Actual fall recovery did not occur")
  movement=Vector3.zero
  report.firstRecovery=report.firstRecovery or snapshot()
  report.stage="Recovered"
  waitFor(function()return #report.fallTouches>0 end,1,"Actual fall-zone touch was not observed")
  assert((character:GetPivot().Position-expectedRecovery.Position).Magnitude<2, "Actual recovery did not arrive at the retained checkpoint frame")
  waitFor(function()return humanoid.FloorMaterial~=Enum.Material.Air and support()~=nil end,2,"Actual recovery did not settle on solid support")
  report.recovered=snapshot()
  local observeUntil=os.clock()+1.4
  waitFor(function()return os.clock()>=observeUntil end,2,"Post-recovery observation did not finish")

  local final, runtimeAfter = result(), services.EggRushService.GetDiagnostics()
  report.final, report.runtimeAfter = final, runtimeAfter
  report.hazardRecoveryAttempts = runtimeAfter.stats.recoveryAttempts-runtimeBefore.stats.recoveryAttempts
  report.hazardRecoveries = runtimeAfter.stats.recoveries-runtimeBefore.stats.recoveries
  report.visibleRoofPlaneCrossedWhileAirborne=false
  for _, crossing in report.roofPlaneCrossings do
   if roof.Transparency<1 and crossing.projectedOverRoof and crossing.before.airborne and crossing.after.airborne then
    report.visibleRoofPlaneCrossedWhileAirborne=true
   end
  end
  assert(#report.placements==1 and final.falls==initial.falls+1, "Exactly one declared setup and one actual recovery required")
  assert(#report.trace>=5 and report.minimumFeetBeforeRecovery and report.minimumFeetBeforeRecovery<report.dropStart.feetBottom-10, "A sampled airborne descent must precede recovery")
  assert(report.hazardRecoveryAttempts==0 and report.hazardRecoveries==0, "A live hazard attempted or caused recovery during this check")
  assert(final.lap==initial.lap and final.nextCheckpoint==initial.nextCheckpoint and final.latest==initial.latest and final.splits==initial.splits and #final.lapTimes==#initial.lapTimes, "The fall changed legitimate race progress")
  for index, time in initial.lapTimes do assert(final.lapTimes[index]==time, "A completed lap time changed") end
  assert(#report.scenerySupports==0, "Actual scenery support interrupted the fall")
  assert(report.airborneObserved and #report.groundedAfterDeparture==0, "The avatar did not remain airborne after leaving the tray")
  if comparison=="before" then
   assert(report.visibleRoofPlaneCrossedWhileAirborne, "The specified visible roof-plane fall was not reproduced")
  else
   assert(not report.visibleRoofPlaneCrossedWhileAirborne, "The same drop still crossed the visible roof plane before recovery")
  end
  report.complete=true
 end,debug.traceback)

 local cleanupErrors={}
 local function cleanup(action)
  local cleaned, message=pcall(action)
  if not cleaned then table.insert(cleanupErrors,tostring(message)) end
 end
 if controller then cleanup(function()controller:Disconnect()end) end
 if observer then cleanup(function()observer:Disconnect()end) end
 if fallConnection then cleanup(function()fallConnection:Disconnect()end) end
 if humanoid and humanoid.Parent then cleanup(function()humanoid:Move(Vector3.zero,false);humanoid.Jump=false end) end
 if root and root.Parent and ownerAuto~=nil then cleanup(function()
  if ownerAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(owner) end
 end) end
 report.ok, report.failure, report.seconds = ok and observerFailure==nil, if ok then observerFailure else tostring(failure), os.clock()-began
 if services and services.EggRushService then
  local got, value=pcall(services.EggRushService.GetDiagnostics)
  if got then
   report.runtimeAtExit=value
   if runtimeBefore and runtimeBefore.stats and value.stats then
    report.hazardRecoveryAttempts=value.stats.recoveryAttempts-runtimeBefore.stats.recoveryAttempts
    report.hazardRecoveries=value.stats.recoveries-runtimeBefore.stats.recoveries
   end
  end
 end
 if roof and report.visibleRoofPlaneCrossedWhileAirborne==nil then
  report.visibleRoofPlaneCrossedWhileAirborne=false
  for _, crossing in report.roofPlaneCrossings do
   if roof.Transparency<1 and crossing.projectedOverRoof and crossing.before.airborne and crossing.after.airborne then
    report.visibleRoofPlaneCrossedWhileAirborne=true
   end
  end
 end
 if result then
  local got, value=pcall(result)
  if got then report.resultAtExit=value end
 end
 report.cleanup={description="Test connections disconnected, movement stopped and original network ownership restored; no return placement",errors=cleanupErrors}
 if #cleanupErrors>0 then
  report.ok=false
  report.failure=(report.failure or "").."; cleanup failed: "..table.concat(cleanupErrors,"; ")
 end
 pcall(function()script:SetAttribute("State",if report.ok then "Complete" else "Failed")end)
 return report
end

return Test
