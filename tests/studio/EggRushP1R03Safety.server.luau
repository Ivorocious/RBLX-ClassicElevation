--!nonstrict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local Http = game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer(), "Native Studio server safety checks only")
assert(not ServerStorage:FindFirstChild("R01SafetyReport"), "A safety command runner already exists")
local stored = Instance.new("StringValue")
stored.Name, stored.Value, stored.Parent = "R01SafetyReport", "{}", ServerStorage
local services = {}
for _, name in {"CourseService", "RaceService", "PlayerRaceService", "CheckpointService", "ResultsService", "EggRushService"} do
 services[name] = require(game.ServerScriptService.Services[name])
end
local busy, sequence = false, 0
local function vector(p) return {p.X, p.Y, p.Z} end

local function run(command)
 local report = {action = command.action, candidateId = "ER_P1_R01", sampleRevision = 3, setups = {}, cases = {}, ownerApproval = false,
  limits = "Scoped real-avatar Studio evidence. Setup placements and checkpoint writes are listed. No crowded, human-listening, physical-device, FPS, universal-route or owner-acceptance proof."}
 local course, player, character, root, humanoid, raceId
 local control, movement, pulse = nil, Vector3.zero, false
 local originalOwner, originalAuto, ownershipSaved
 local startWall = os.clock()
 local bodyParts = {}
 local function bodyFlags()
  local flags = {}
  for _, part in bodyParts do flags[part.Name] = part.CanCollide end
  return flags
 end
 local function guard()
  assert(player.Character == character and root.Parent and humanoid.Health > 0, "ContextChanged: character changed or died")
  assert(services.CourseService.GetActiveCourse() == course and services.RaceService.IsRaceActive()
   and services.RaceService.GetCurrentRaceId() == raceId, "ContextChanged: race changed")
 end
 local cleanupToCP2 = command.action == "NoJump" or command.action == "Late"
 local ok, failure = xpcall(function()
  assert(command.action == "Edges" or command.action == "NoJump" or command.action == "Late", "Unknown safety action")
  course = assert(services.CourseService.GetActiveCourse(), "No active course")
  assert(course:GetAttribute("CandidateId") == "ER_P1_R01" and course:GetAttribute("Phase") == 1
   and course:GetAttribute("SampleRevision") == 3, "Expected active R01 revision 3")
  player = assert(Players:GetPlayers()[1], "No first inspector")
  character = assert(player.Character)
  root, humanoid = character.HumanoidRootPart, assert(character:FindFirstChildOfClass("Humanoid"))
  raceId = services.RaceService.GetCurrentRaceId()
  guard()
  assert(services.PlayerRaceService.IsOfficialRacer(player) and services.PlayerRaceService.GetPlayerStatus(player) == "Racing", "Prepare an official inspector")
  assert(not root.Anchored and humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower
   and math.abs(humanoid.JumpHeight - 7.2) < .01, "Wrong actual movement profile")
  assert(services.EggRushService.GetDiagnostics().bound == true, "Actual runtime is not bound")
  for _, name in {"Head", "Torso", "UpperTorso", "LowerTorso"} do
   local part = character:FindFirstChild(name)
   if part and part:IsA("BasePart") then table.insert(bodyParts, part) end
  end
  report.bodyCollisionAtStart = bodyFlags()
  report.raceId, report.userId = raceId, player.UserId
  report.movement = {walk = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight, useJumpPower = humanoid.UseJumpPower,
   maxSlopeAngle = humanoid.MaxSlopeAngle, gravity = Workspace.Gravity}
  originalOwner, originalAuto = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto()
  ownershipSaved = true
  root:SetNetworkOwner(nil)
  local params = RaycastParams.new()
  params.FilterType, params.FilterDescendantsInstances, params.RespectCanCollide = Enum.RaycastFilterType.Include, {course}, true
  local overlapParams = OverlapParams.new()
  overlapParams.FilterType, overlapParams.FilterDescendantsInstances, overlapParams.RespectCanCollide = Enum.RaycastFilterType.Include, {course}, true
  overlapParams.MaxParts = 32
  local legOffset = humanoid.HipHeight + root.Size.Y / 2
  local footNames = {LeftFoot = true, RightFoot = true, ["Left Leg"] = true, ["Right Leg"] = true}
  for _, foot in character:GetChildren() do
   if not foot:IsA("BasePart") or not footNames[foot.Name] then continue end
   local cf, size = foot.CFrame, foot.Size
   local extent = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
   legOffset = math.max(legOffset, root.Position.Y - foot.Position.Y + extent)
  end
  assert(legOffset >= 1 and legOffset <= 8, "No bounded leg length")
  report.legOffset = legOffset
  local function standing()
   local rootHit = Workspace:Raycast(root.Position, Vector3.new(0, -(legOffset + .7), 0), params)
   if rootHit and math.abs(root.Position.Y - rootHit.Position.Y - legOffset) <= .85 then return rootHit, "Root" end
   for _, foot in character:GetChildren() do
    if not foot:IsA("BasePart") or not footNames[foot.Name] then continue end
    local cf, size = foot.CFrame, foot.Size
    local extent = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
    local hit = Workspace:Raycast(foot.Position, Vector3.new(0, -(extent + .7), 0), params)
    if hit then return hit, foot.Name end
   end
   return nil, nil
  end
  local function overlaps()
   local hits = {}
   for _, body in bodyParts do
    for _, part in Workspace:GetPartsInPart(body, overlapParams) do
     if part.CanCollide then table.insert(hits, body.Name .. " -> " .. part:GetFullName()) end
    end
   end
   return hits
  end
  local function snapshot()
   local hit, ray = standing()
   return {position = vector(root.Position), velocity = vector(root.AssemblyLinearVelocity), floor = humanoid.FloorMaterial.Name,
    humanoidState = humanoid:GetState().Name, support = hit and hit.Instance:GetFullName(), ray = ray,
    supportPosition = hit and vector(hit.Position), supportNormal = hit and vector(hit.Normal)}
  end
  local function falls() return assert(services.ResultsService.GetPlayerResult(player)).falls or 0 end
  local function clock() return assert(services.EggRushService.GetDiagnostics().elapsed, "Runtime clock unbound") end
  local function partOfPad(hit, pad)
   return hit and (hit.Instance == pad or (hit.Instance.Parent == pad.Parent and hit.Instance.Name:match("^" .. pad.Name .. "_Shoulder")))
  end
  local approach
  local function edgeDistance(part, direction)
   local cf, size = part.CFrame, part.Size
   local ex = (math.abs(cf.RightVector.X) * size.X + math.abs(cf.UpVector.X) * size.Y + math.abs(cf.LookVector.X) * size.Z) / 2
   local ez = (math.abs(cf.RightVector.Z) * size.X + math.abs(cf.UpVector.Z) * size.Y + math.abs(cf.LookVector.Z) * size.Z) / 2
   local distance = math.huge
   if math.abs(direction.X) > .0001 then distance = math.min(distance, (cf.Position.X + math.sign(direction.X) * ex - root.Position.X) / direction.X) end
   if math.abs(direction.Z) > .0001 then distance = math.min(distance, (cf.Position.Z + math.sign(direction.Z) * ez - root.Position.Z) / direction.Z) end
   return distance
  end
  control = RunService.PreSimulation:Connect(function()
   if not humanoid.Parent or not root.Parent then return end
   if approach and not approach.requested then
    local hit = standing()
    if partOfPad(hit, approach.pad) and edgeDistance(hit.Instance, approach.direction) <= .55 then
     approach.requested, approach.presses, approach.launch = true, 1, snapshot()
     pulse = true
    end
   end
   humanoid:Move(movement, false)
   humanoid.Jump = pulse
   pulse = false
  end)
  local function place(pad, localOffset, look, purpose)
   movement, pulse, approach = Vector3.zero, false, nil
   humanoid:Move(Vector3.zero, false)
   humanoid.Jump = false
   local top = pad.CFrame * Vector3.new(localOffset.X, pad.Size.Y / 2, localOffset.Z)
   local target = top + Vector3.new(0, legOffset + .15, 0)
   table.insert(report.setups, {kind = "InitialActionPlacement", purpose = purpose, surface = pad:GetFullName(), position = vector(target)})
   character:PivotTo(CFrame.lookAt(target, Vector3.new(look.X, target.Y, look.Z)))
   root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
  end
  local function settle(pad)
   local began, stableSince = os.clock(), nil
   repeat
    RunService.Heartbeat:Wait()
    guard()
    if partOfPad(standing(), pad) and humanoid.FloorMaterial ~= Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y) < .1 then stableSince = stableSince or os.clock() else stableSince = nil end
    if stableSince and os.clock() - stableSince >= .25 then return true, os.clock() - began end
   until os.clock() - began >= 2
   return false, os.clock() - began
  end
  local function pause(seconds)
   local began = os.clock()
   repeat RunService.Heartbeat:Wait(); guard() until os.clock() - began >= seconds
  end

  if command.action == "Edges" then
   report.scope = "Four actual wait-edge positions, each inset1.25 from the authored main contact edge; no collision or body-profile writes"
   local o, m = course.Obstacles, course.Obstacles.Mechanisms
   local cases = {
    {name = "ForkFront", pad = o.Shell_ForkWait, edge = -1, model = m.ShellLip1},
    {name = "MiddleFront", pad = o.Shell_MiddleWait, edge = -1, model = m.ShellLip3},
    {name = "MiddleBack", pad = o.Shell_MiddleWait, edge = 1, model = m.ShellLip2},
    {name = "ExitNearCrown", pad = o.Shell_ExitWait, edge = 1, model = m.CrownLip5},
   }
   for _, config in cases do
    guard()
    assert(os.clock() - startWall < 88, "Edge action exceeded bounded total time")
    local pad, model = config.pad, config.model
    local cycle = model:GetAttribute("ClosedSeconds") + model:GetAttribute("WarningSeconds") + 2 * model:GetAttribute("MoveSeconds")
     + model:GetAttribute("OpenSeconds") + model:GetAttribute("ClosingWarningSeconds")
    assert(cycle > 0 and cycle <= 18, "Unexpected wait cycle length")
    local case = {name = config.name, part = pad:GetFullName(), neighbor = model.Name, inset = 1.25, durationRequired = cycle + .05,
     states = {}, trace = {}, bodyOverlaps = {}, maximumHorizontalDrift = 0, maximumVerticalDrift = 0, supportLostSamples = 0}
    table.insert(report.cases, case)
    stored:SetAttribute("Case", config.name)
    stored:SetAttribute("Progress", "SettlingEdge")
    local offsetZ = config.edge * math.max(0, pad.Size.Z / 2 - 1.25)
    place(pad, Vector3.new(0, 0, offsetZ), model:GetPivot().Position, config.name .. " edge setup")
    local settled, settleSeconds = settle(pad)
    case.settled, case.settleSeconds = settled, settleSeconds
    if not settled then
     case.outcome, case.initial = "InconclusiveEdgeSetupDidNotSettle", snapshot()
     for _, hit in overlaps() do case.bodyOverlaps[hit] = true end
     continue
    end
    local initial, before, began, beganClock, lastTrace = root.Position, falls(), os.clock(), clock(), -math.huge
    case.baseline = snapshot()
    case.checkpointAtStart = services.CheckpointService.GetLatestCheckpointIndex(player)
    stored:SetAttribute("Progress", "ObservingFullActualCycle")
    repeat
     RunService.Heartbeat:Wait()
     guard()
     local elapsed = clock() - beganClock
     local bodyHits = overlaps()
     for _, hit in bodyHits do case.bodyOverlaps[hit] = true end
     case.states[assert(model:GetAttribute("ERState"))] = true
     local delta = root.Position - initial
     case.maximumHorizontalDrift = math.max(case.maximumHorizontalDrift, Vector3.new(delta.X, 0, delta.Z).Magnitude)
     case.maximumVerticalDrift = math.max(case.maximumVerticalDrift, math.abs(delta.Y))
     if not partOfPad(standing(), pad) or humanoid.FloorMaterial == Enum.Material.Air then case.supportLostSamples += 1 end
     case.recoveries = falls() - before
     if elapsed - lastTrace >= .5 then
      local sample = snapshot()
      sample.seconds, sample.neighborState, sample.bodyOverlapCount = elapsed, model:GetAttribute("ERState"), #bodyHits
      table.insert(case.trace, sample)
      lastTrace = elapsed
     end
     case.elapsed = elapsed
     assert(os.clock() - began < cycle + 5 and os.clock() - startWall < 89, "Wait runtime clock stalled or edge action budget exhausted")
    until case.elapsed >= cycle + .05
    case.final, case.queriedOverlapObserved = snapshot(), next(case.bodyOverlaps) ~= nil
    case.allSixStates = true
    for _, name in {"Closed", "Warning", "Opening", "Open", "ClosingWarning", "Closing"} do if not case.states[name] then case.allSixStates = false end end
    case.remainedSupported = case.supportLostSamples == 0 and case.recoveries == 0
    case.driftWithinPointOne = case.maximumHorizontalDrift <= .1 and case.maximumVerticalDrift <= .1
    case.ok = case.remainedSupported and case.driftWithinPointOne and not case.queriedOverlapObserved and case.allSixStates
    case.outcome = if case.ok then "ListedEdgeStayedSupportedWithoutQueriedOverlap" else "ListedEdgeHasRecordedSafetyFinding"
   end
   report.complete = #report.cases == 4
   report.ok = report.complete
   for _, case in report.cases do if not case.ok then report.ok = false end end

  elseif command.action == "NoJump" then
   report.scope = "One ordinary walking attempt across the actual CP2-to-first-fragment gap; jumping remains false"
   assert(services.CheckpointService.SetInspectionCheckpointForStudio(player, 2), "CP2 inspection setup failed")
   table.insert(report.setups, {kind = "InspectionCheckpointWrite", checkpoint = 2})
   local pad = course.Obstacles.CP2_Pocket
   local target = assert(course.Routes.S3_ShellApproach:FindFirstChild("001")).Value
   place(pad, Vector3.zero, target.Position, "NoJump CP2 setup")
   local settled = settle(pad)
   assert(settled, "NoJump CP2 setup did not settle")
   pause(1.65)
   local before, baseline = falls(), root.Position
   report.before, report.trace = snapshot(), {}
   report.jumpInput = false
   local began, stableSince, lastTrace = os.clock(), nil, -math.huge
   local recovered, lostAndDropped, reached, jumpObserved = false, false, false, false
   repeat
    guard()
    local flat = (target.Position - root.Position) * Vector3.new(1, 0, 1)
    movement = if flat.Magnitude > .35 then flat.Unit else Vector3.zero
    RunService.Heartbeat:Wait()
    guard()
    local actual = standing()
    if partOfPad(actual, target) and humanoid.FloorMaterial ~= Enum.Material.Air then stableSince = stableSince or os.clock() else stableSince = nil end
    jumpObserved = jumpObserved or humanoid:GetState() == Enum.HumanoidStateType.Jumping
     or (humanoid.FloorMaterial == Enum.Material.Air and root.AssemblyLinearVelocity.Y > 3)
    recovered = falls() > before
    reached = stableSince and os.clock() - stableSince >= .15
    lostAndDropped = (not actual or humanoid.FloorMaterial == Enum.Material.Air) and baseline.Y - root.Position.Y > 3
    if os.clock() - began - lastTrace >= .15 then
     local sample = snapshot()
     sample.seconds = os.clock() - began
     table.insert(report.trace, sample)
     lastTrace = sample.seconds
    end
    if recovered or reached or lostAndDropped then break end
   until os.clock() - began >= 3
   movement = Vector3.zero
   report.seconds, report.after, report.actualFalls = os.clock() - began, snapshot(), falls() - before
   report.unrequestedJumpObserved = jumpObserved
   report.didWalkAcross = reached == true and not jumpObserved and not recovered
   report.outcome = if report.didWalkAcross then "WalkedAcrossActualGap" elseif recovered then "ActualRecoveryObserved"
    elseif lostAndDropped then "LostSupportAndDroppedMoreThanThreeStuds" elseif jumpObserved then "UnrequestedJumpObserved"
    else "NoCrossingEstablishedWithinThreeSeconds"
   report.complete = recovered or reached == true or lostAndDropped or jumpObserved
   report.ok = report.complete and not report.didWalkAcross and not jumpObserved

  elseif command.action == "Late" then
   report.scope = "One first-Crown entry started near the natural end of ClosingWarning, with three seconds of observation"
   assert(services.CheckpointService.SetInspectionCheckpointForStudio(player, 2), "Late CP2 inspection setup failed")
   table.insert(report.setups, {kind = "InspectionCheckpointWrite", checkpoint = 2})
   local pad, model = course.Obstacles.Shell_ForkWait, course.Obstacles.Mechanisms.CrownLip1
   place(pad, Vector3.zero, model:GetPivot().Position, "Late-entry fork setup")
   assert(settle(pad), "Late fork setup did not settle")
   local c, w, m, o, cw = model:GetAttribute("ClosedSeconds"), model:GetAttribute("WarningSeconds"), model:GetAttribute("MoveSeconds"), model:GetAttribute("OpenSeconds"), model:GetAttribute("ClosingWarningSeconds")
   local cycle, closingStart = c + w + 2 * m + o + cw, c + w + m + o
   local waitDeadline = os.clock() + 16
   local admitted = false
   repeat
    RunService.Heartbeat:Wait()
    guard()
    local phase = (clock() + (model:GetAttribute("PhaseSeconds") or 0)) % cycle
    admitted = model:GetAttribute("ERState") == "ClosingWarning" and phase >= closingStart + cw - .2 and phase < closingStart + cw
    if admitted then report.entryClock, report.entryPhase = clock(), phase; break end
   until os.clock() >= waitDeadline
   if not admitted then
    report.complete, report.ok, report.outcome = false, false, "InconclusiveNoNaturalLateWindowWithinBudget"
   else
    local target, before = model.ShellContact, falls()
    local began, lastTrace = os.clock(), -math.huge
    local baseline = root.Position
    report.trace, report.bodyOverlaps = {}, {}
    report.entryState = model:GetAttribute("ERState")
    local aim = target.Position + target.CFrame.UpVector * target.Size.Y / 2
    local flat = (aim - root.Position) * Vector3.new(1, 0, 1)
    approach = {pad = pad, direction = flat.Unit, presses = 0, requested = false}
    local attempt = approach
    local reached, stableSince = false, nil
    repeat
     guard()
     aim = target.Position + target.CFrame.UpVector * target.Size.Y / 2
     flat = (aim - root.Position) * Vector3.new(1, 0, 1)
     movement = if flat.Magnitude > .35 then flat.Unit else Vector3.zero
     if not attempt.requested and flat.Magnitude > .001 then attempt.direction = flat.Unit end
     RunService.Heartbeat:Wait()
     guard()
     local hit = standing()
     if hit and hit.Instance:IsDescendantOf(model) and humanoid.FloorMaterial ~= Enum.Material.Air then stableSince = stableSince or os.clock() else stableSince = nil end
     reached = reached or (stableSince and os.clock() - stableSince >= .15)
     for _, bodyHit in overlaps() do report.bodyOverlaps[bodyHit] = true end
     if os.clock() - began - lastTrace >= .15 then
      local sample = snapshot()
      sample.seconds, sample.state = os.clock() - began, model:GetAttribute("ERState")
      table.insert(report.trace, sample)
      lastTrace = sample.seconds
     end
     if falls() > before then break end
    until os.clock() - began >= 3
    movement, approach = Vector3.zero, nil
    report.seconds, report.jumpPresses, report.launch = os.clock() - began, attempt.presses, attempt.launch
    report.final, report.actualFalls, report.reachedMovingCrown = snapshot(), falls() - before, reached == true
    report.queriedBodyOverlapObserved = next(report.bodyOverlaps) ~= nil
    report.lostHeight = baseline.Y - root.Position.Y
    report.outcome = if report.actualFalls > 0 then "ActualRecoveryObserved" elseif report.reachedMovingCrown then "ActualCrownSupportObservedDuringLateAttempt"
     elseif report.queriedBodyOverlapObserved then "BodyOverlapObservedDuringLateAttempt" else "NoCrownEntryEstablishedWithinObservation"
    report.complete = true
    report.ok = not report.queriedBodyOverlapObserved
    report.interpretation = "A diagnostic outcome; blocked entry or a fall can be valid late behavior. This is not a required successful crossing."
   end
  end
 end, debug.traceback)

 if control then control:Disconnect() end
 movement, pulse = Vector3.zero, false
 if humanoid and humanoid.Parent then humanoid:Move(Vector3.zero, false); humanoid.Jump = false end
 if cleanupToCP2 and character and root and root.Parent and humanoid and humanoid.Health > 0 and player.Character == character and course and course.Parent then
  local returned, returnFailure = pcall(function()
   local pocket = course.Obstacles.CP2_Pocket
   local target = pocket.Position + Vector3.new(0, pocket.Size.Y / 2 + humanoid.HipHeight + root.Size.Y / 2 + .15, 0)
   table.insert(report.setups, {kind = "PostActionCleanupPlacement", surface = pocket:GetFullName(), position = vector(target),
    purpose = "Authorized CP2 return after movement disconnect; not part of the attempt"})
   character:PivotTo(CFrame.new(target))
   root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
  end)
  report.cleanup = {returnedToCP2 = returned, failure = if returned then nil else tostring(returnFailure)}
 end
 if ownershipSaved and root and root.Parent then
  local restored, restoreFailure = pcall(function()
   if originalAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(originalOwner) end
  end)
  report.ownershipRestored = restored
  if not restored then report.ownershipFailure = tostring(restoreFailure) end
 end
 report.bodyCollisionAtEnd, report.wallSeconds = bodyFlags(), os.clock() - startWall
 report.executed, report.failure = ok, if ok then nil else tostring(failure)
 if not ok then report.complete, report.ok = false, false end
 return report
end

stored:GetAttributeChangedSignal("Command"):Connect(function()
 if busy then return end
 busy = true
 stored:SetAttribute("State", "Running")
 task.spawn(function()
  local decoded, command = pcall(Http.JSONDecode, Http, stored:GetAttribute("Command"))
  local report
  if decoded then report = run(command) else report = {executed = false, complete = false, ok = false, failure = tostring(command)} end
  local encoded = Http:JSONEncode(report)
  sequence += 1
  local receipt = Instance.new("StringValue")
  receipt.Name, receipt.Value, receipt.Parent = string.format("Receipt_%02d", sequence), encoded, stored
  stored.Value = encoded
  stored:SetAttribute("State", if report.ok and report.complete then "Complete" elseif report.complete then "Finding" else "Inconclusive")
  busy = false
 end)
end)
stored:SetAttribute("State", "Ready")
