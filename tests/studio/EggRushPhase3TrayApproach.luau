--!nonstrict
local Test = {}
local RunService, Players, Workspace = game:GetService("RunService"), game:GetService("Players"), game:GetService("Workspace")

local function vector(value)
 return {value.X, value.Y, value.Z}
end

function Test.Run(expectedCandidate)
 expectedCandidate = expectedCandidate or "ER_P3_W06_C03"
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
 local observer, observerFailure, deck, tray = nil, nil, nil, nil
 local report = {
  candidate=expectedCandidate, userId=player.UserId, raceId=raceId, placements={}, landings={}, trace={},
  progressWrites=0, clockWrites=0, profileWrites=0, immunityWrites=0, geometryWrites=0,
  sampling={physicsFramesChecked=0, maxPhysicsDelta=0},
  method="One declared placement on S4_IncubatorApproach_003; current Normal driver walks and jumps through the board pocket, first tray, full carry and receiving pocket",
  limits="One scripted racer and one focused setup, not ordinary entry, a full lap, human, crowd, device or performance proof",
 }
 local function result()
  local value = assert(services.ResultsService.GetPlayerResult(player))
  return {lap=value.currentLap, nextCheckpoint=value.nextCheckpointIndex, falls=value.falls or 0,
   lapTimes=table.clone(value.lapTimes or {}), splits=#(value.checkpointSplits or {}), status=services.PlayerRaceService.GetPlayerStatus(player)}
 end
 local initial = result()
 local initialRecovery = character:GetAttribute("RecoveryUntil") or 0
 local runtimeBefore = services.EggRushService.GetDiagnostics()
 report.initialResult, report.initialRecoveryUntil, report.runtimeBefore = initial, initialRecovery, runtimeBefore
 local function guard()
  assert(not observerFailure, observerFailure)
  assert(os.clock()-began < 45 and player.Character == character and root.Parent and humanoid.Parent and humanoid.Health > 0, "Bounded original character changed")
  assert(services.CourseService.GetActiveCourse() == course and services.RaceService.GetCurrentRaceId() == raceId, "Course or race changed")
  assert(services.RaceService.IsRaceActive() and services.PlayerRaceService.IsOfficialRacer(player) and services.PlayerRaceService.GetPlayerStatus(player) == "Racing", "Actual eligible Racing participant required")
  assert(not services.CourseService.IsInspectionMode() and not services.RaceService.IsInspectionUnlimitedTime(), "No inspection override or immunity")
  assert(not root.Anchored and humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2)<.01 and math.abs(Workspace.Gravity-196.2)<.01, "Ordinary movement required")
  local runtime = services.EggRushService.GetDiagnostics()
  assert(collider.Parent == character and collider.CanCollide and (collider.Size-colliderSize).Magnitude<.02 and runtime.bound and not runtime.holding and runtime.raceId==raceId, "Fitted body or live runtime changed")
  assert(result().falls == initial.falls and (character:GetAttribute("RecoveryUntil") or 0) <= initialRecovery+.01, "Actual recovery; stop the focused attempt")
  return true
 end
 local ray = RaycastParams.new(); ray.FilterType=Enum.RaycastFilterType.Include; ray.FilterDescendantsInstances={course}; ray.RespectCanCollide=true
 local function standing()
  local hit = Workspace:Raycast(root.Position, Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.7),0), ray)
  return hit and hit.Instance
 end
 local function snapshot()
  local support = standing()
  return {seconds=os.clock()-began, step=report.lastProgress and report.lastProgress.step,
   trayState=tray:GetAttribute("ERState"), root=vector(root.Position), deck=vector(deck.Position),
   deckLocal=vector(deck.CFrame:PointToObjectSpace(root.Position)), rootVelocity=vector(root.AssemblyLinearVelocity),
   deckVelocity=vector(deck.AssemblyLinearVelocity), relativeVelocity=vector(deck.CFrame:VectorToObjectSpace(root.AssemblyLinearVelocity-deck.AssemblyLinearVelocity)),
   moveDirection=vector(humanoid.MoveDirection), floor=humanoid.FloorMaterial.Name, support=support and support:GetFullName()}
 end
 local ok, failure = xpcall(function()
  assert(course:GetAttribute("CourseId")=="egg_rush_circuit" and course:GetAttribute("CandidateId")==expectedCandidate and course:GetAttribute("FullBodyContacts")==true, "Expected actual full-body Phase3 candidate")
  assert(initialRecovery<=Workspace:GetServerTimeNow(), "Wait for existing recovery immunity to expire")
  assert(runtimeBefore.bound and runtimeBefore.elapsed and runtimeBefore.stats, "Bound live mechanism clock and recovery counters required")
  guard()
  tray = assert(course.Obstacles.Mechanisms:FindFirstChild("SidewaysTray"))
  deck = assert(tray:FindFirstChild("TrayContact"))
  assert(tray:GetAttribute("ERMechanism")=="Tray" and deck.CanCollide and deck.CanQuery and math.abs(tray:GetAttribute("Travel").Magnitude-16)<.01, "Actual first-tray support required")
  local traversal = require(game.ServerStorage.CourseBuilders.EggRush.NativeTraversal)
  local all, points, collecting = traversal.Points(course,"Normal"), {}, false
  for _, point in all do
   if point.part.Name=="S4_IncubatorApproach_003" then collecting=true end
   if collecting then table.insert(points,table.clone(point)) end
   if collecting and point.part.Name=="Tray_ReceivePocket" then break end
  end
  assert(#points==4 and points[2].part.Name=="Tray_BoardPocket" and points[3].part==deck and points[4].part.Name=="Tray_ReceivePocket", "Expected current first-tray route")
  assert(points[3].waitKind=="Tray" and points[4].waitKind=="SideExit", "Expected current tray waits")
  report.route={}
  for _, point in points do table.insert(report.route,{part=point.part:GetFullName(), waitKind=point.waitKind}) end
  report.traySettings={board=tray:GetAttribute("BoardSeconds"), warning=tray:GetAttribute("WarningSeconds"),
   move=tray:GetAttribute("MoveSeconds"), exit=tray:GetAttribute("ExitSeconds"), phase=tray:GetAttribute("PhaseSeconds"), travel=vector(tray:GetAttribute("Travel"))}
  local first=points[1].part
  local target=traversal.PointAim(first,points[2].part,false)+Vector3.yAxis*(humanoid.HipHeight+root.Size.Y/2+.15)
  root:SetNetworkOwner(nil)
  character:PivotTo(CFrame.new(target)*root.CFrame:ToObjectSpace(character:GetPivot()))
  root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
  table.insert(report.placements,{part=first:GetFullName(),rootTarget=vector(target),reason="Declared focused setup before the real board approach"})
  local setupDeadline=os.clock()+3; local stableSince
  repeat
   RunService.Heartbeat:Wait();guard()
   if standing()==first and humanoid.FloorMaterial~=Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y)<2 then stableSince=stableSince or os.clock() else stableSince=nil end
  until (stableSince and os.clock()-stableSince>=.12) or os.clock()>setupDeadline
  assert(stableSince and os.clock()-stableSince>=.12,"Declared setup never settled on the actual approach")
  report.setup=snapshot()
  observer=RunService.PostSimulation:Connect(function(dt)
   local observed,message=xpcall(function()
    report.sampling.physicsFramesChecked+=1;report.sampling.maxPhysicsDelta=math.max(report.sampling.maxPhysicsDelta,dt)
    table.insert(report.trace,snapshot())
   end,debug.traceback)
   if not observed then observerFailure=tostring(message) end
  end)
  report.driver=traversal.Run(course,player,points,{placeAtStart=false,guard=guard,afterLanding=function(_,point,record)
   guard();table.insert(report.landings,{part=point.part.Name,record=record,observation=snapshot()})
  end},function(index,total,step) report.lastProgress={index=index,total=total-1,step=step} end)
  assert(report.driver.ok,report.driver.failure)
  guard()
  assert(report.driver.jumps==3 and #report.landings==3 and #report.placements==1, "Actual approach, carry and receiving landing required")
  assert(#report.driver.trayCarries==1 and report.driver.trayCarries[1].supportedThroughout, "Unchanged full first-tray carry required")
  local final=result()
  assert(final.lap==initial.lap and final.nextCheckpoint==initial.nextCheckpoint and final.splits==initial.splits and #final.lapTimes==#initial.lapTimes, "Focused attempt changed actual progression")
  for index,lapTime in initial.lapTimes do assert(final.lapTimes[index]==lapTime,"Existing lap time changed") end
  local stats=services.EggRushService.GetDiagnostics().stats
  assert(stats.recoveryAttempts==runtimeBefore.stats.recoveryAttempts and stats.recoveries==runtimeBefore.stats.recoveries, "Runtime recorded a hazard recovery attempt")
  report.complete=true
 end,debug.traceback)
 if observer then observer:Disconnect() end
 humanoid:Move(Vector3.zero,false); humanoid.Jump=false
 if root.Parent then if originalAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(originalOwner) end end
 report.ok=ok and observerFailure==nil
 report.failure=if ok then observerFailure else tostring(failure)
 report.seconds=os.clock()-began
 report.runtimeAfter=services.EggRushService.GetDiagnostics()
 report.finalResult=result()
 report.finalRecoveryUntil=character:GetAttribute("RecoveryUntil") or 0
 if deck and tray then
  local captured,observation=pcall(snapshot)
  if captured then report.finalObservation=observation end
 end
 if report.runtimeAfter.stats and runtimeBefore.stats then
  report.recoveryDelta={attempts=report.runtimeAfter.stats.recoveryAttempts-runtimeBefore.stats.recoveryAttempts,
   recoveries=report.runtimeAfter.stats.recoveries-runtimeBefore.stats.recoveries,falls=report.finalResult.falls-initial.falls}
 end
 report.cleanup="Observation and server movement stopped; original ownership restored; no return placement"
 return report
end

return Test
