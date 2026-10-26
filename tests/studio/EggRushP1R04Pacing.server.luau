--!nonstrict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
assert(RunService:IsStudio() and RunService:IsServer(), "Native Studio server test only")
assert(not ServerStorage:FindFirstChild("R04PacingReport"), "Use a fresh Play session for this single pacing attempt")
local stored = Instance.new("StringValue")
stored.Name, stored.Parent = "R04PacingReport", ServerStorage
stored:SetAttribute("State", "Ready")
local expectedRevision = script:GetAttribute("ExpectedSampleRevision") or 3
assert(expectedRevision == 3 or expectedRevision == 4, "Select the installed Phase 1 geometry revision explicitly")
local line = script:GetAttribute("Line") or "Expert"
assert(line == "Normal" or line == "Expert", "Line must be Normal or Expert")
local pace = script:GetAttribute("Pace")
if pace == nil then pace = line == "Expert" end
assert(typeof(pace) == "boolean", "Pace must be a boolean")
local shellNames = if line == "Expert" then {"CrownLip1", "CrownLip2", "CrownLip3", "CrownLip4", "CrownLip5"}
 else {"ShellLip1", "ShellLip2", "ShellLip3", "ShellLip4"}
local services = {}
for _, name in {"CourseService", "RaceService", "PlayerRaceService", "CheckpointService", "OnboardingService", "EggRushService", "ResultsService"} do
 services[name] = require(game.ServerScriptService.Services[name])
end
local traversalModule = ServerStorage.CourseBuilders.EggRush.NativeTraversal
local overrideContract
local override = script:FindFirstChild("TraversalOverride")
if override then
 assert(line == "Normal" and override:IsA("ModuleScript"), "TraversalOverride is restricted to the Normal diagnostic")
 assert(override:GetAttribute("ProbeSourceVerified") == true and override:GetAttribute("ReplacementCount") == 1
  and override:GetAttribute("OriginalSourceBytes") == 20666
  and override:GetAttribute("OriginalSourceSha256") == "EB58E98349FCACE21FC2FE3792E73D7A892BF4F13EB514A81F90569AC1611691"
  and override:GetAttribute("PatchedSourceBytes") == 20770
  and override:GetAttribute("PatchedSourceSha256") == "3DF8A7F47DF5D7093E58694DE732E3E6FFB1CC64962404D723C7CA7D8556AB3B"
  and override:GetAttribute("CanonicalSourceUnchanged") == true, "TraversalOverride source contract does not match the verified scoped clone")
 local inset = override:GetAttribute("ProbeTakeoffInset")
 assert(inset == 1.2 or inset == 1.6, "TraversalOverride inset must be 1.2 or 1.6")
 overrideContract = {path = override:GetFullName(), verification = "Installer source comparison; native Script Source access is protected",
  probeSourceVerified = true, replacementCount = 1, originalSourceBytes = 20666,
  originalSourceSha256 = override:GetAttribute("OriginalSourceSha256"), patchedSourceBytes = 20770,
  patchedSourceSha256 = override:GetAttribute("PatchedSourceSha256"), canonicalSourceUnchanged = true,
  probeTakeoffInset = inset, scopedDeparture = "S3_ShellApproach_002", otherDepartureInset = .55}
 traversalModule = override
end
local traversal = require(traversalModule)
local ForwardGate = require(game.ReplicatedStorage.Shared.ForwardGate)
local used = false
local function vector(value) return {value.X, value.Y, value.Z} end
local function pose(part) return {path = part:GetFullName(), cframe = {part.CFrame:GetComponents()}, size = vector(part.Size)} end
local reportSequence = 0
local function storeReport(payload)
 local encoded = Http:JSONEncode(payload)
 reportSequence += 1
 local folder = Instance.new("Folder")
 folder.Name = string.format("Payload_%03d", reportSequence)
 local names, offset = {}, 1
 while offset <= #encoded do
  local last = math.min(offset + 149999, #encoded)
  while last < #encoded do
   local nextByte = string.byte(encoded, last + 1)
   if nextByte < 128 or nextByte > 191 then break end
   last -= 1
  end
  local chunk = Instance.new("StringValue")
  chunk.Name = string.format("Chunk_%03d", #names + 1)
  chunk.Value = string.sub(encoded, offset, last)
  chunk.Parent = folder
  table.insert(names, chunk.Name)
  offset = last + 1
 end
 folder.Parent = stored
 stored.Value = Http:JSONEncode({format = "R04PacingReportChunksV1", payloadFolder = folder.Name, chunks = names,
  jsonBytes = #encoded, line = payload.line, ok = payload.ok, complete = payload.complete,
  officialFinishSeconds = payload.officialFinishSeconds, ownerApproval = false})
end
local function waitFor(predicate, seconds, message, guard)
 local limit = os.clock() + seconds
 repeat
  if guard then guard() end
  if predicate() then return end
  RunService.Heartbeat:Wait()
 until os.clock() >= limit
 error(message)
end
local function resultSnapshot(player)
 local value = assert(services.ResultsService.GetPlayerResult(player), "Missing official result")
 local splits, laps = {}, {}
 for _, split in value.checkpointSplits or {} do
  table.insert(splits, {checkpointIndex = split.checkpointIndex, lap = split.lap, elapsedTime = split.elapsedTime})
 end
 for index, seconds in value.lapTimes or {} do laps[index] = seconds end
 return {status = value.status, currentLap = value.currentLap, requiredLaps = value.requiredLaps,
  nextCheckpointIndex = value.nextCheckpointIndex, falls = value.falls or 0,
  lapTimes = laps, checkpointSplits = splits, finishTime = value.finishTime, placement = value.placement}
end
local function splitExists(result, lap, checkpoint)
 for _, split in result.checkpointSplits do
  if split.lap == lap and split.checkpointIndex == checkpoint then return true end
 end
 return false
end
local function freshPrepare(report)
 local player = assert(Players:GetPlayers()[1], "Join the native test client first")
 local deadline = os.clock() + 65
 for _, racer in Players:GetPlayers() do
  if racer:GetAttribute("OnboardingReady") ~= true then
   local success, message = services.OnboardingService.SetStudioPreset(racer, "Returning racer")
   assert(success, message)
   waitFor(function() return racer:GetAttribute("OnboardingReady") == true end,
    math.max(.1, math.min(25, deadline - os.clock())), "Returning racer preset did not arrive")
  end
 end
 assert(services.CourseService.SelectCourseForStudio("egg_rush_circuit"), "Deliberately install the disabled Phase 1 template first")
 services.RaceService.SetInspectionUnlimitedTime(true)
 local previous = services.RaceService.GetCurrentRaceId()
 assert(services.RaceService.ApplyStudioAction("RestartRace"), "Could not start a fresh inspection race")
 waitFor(function()
  return services.RaceService.IsRaceActive() and services.RaceService.GetCurrentRaceId() ~= previous
   and services.CourseService.GetActiveCourseId() == "egg_rush_circuit"
 end, math.max(.1, math.min(35, deadline - os.clock())), "Fresh inspection race did not become active")
 local course = assert(services.CourseService.GetActiveCourse())
 assert(course:GetAttribute("CandidateId") == "ER_P1_R01" and course:GetAttribute("Phase") == 1
  and course:GetAttribute("EROwned") == true and course:GetAttribute("SampleRevision") == expectedRevision,
  "Wrong Phase 1 candidate or installed geometry revision")
 assert(services.CourseService.GetRaceFormat() == "LapBased" and services.CourseService.GetLapCount() == 3,
  "The actual course must require three laps")
 waitFor(function() return services.EggRushService.GetDiagnostics().bound == true end,
  math.max(.1, math.min(3, deadline - os.clock())), "Actual Egg Rush runtime did not bind")
 assert(services.PlayerRaceService.IsOfficialRacer(player)
  and services.PlayerRaceService.GetPlayerStatus(player) == "Racing", "Fresh racer was not officially enrolled")
 report.setupSeconds = 65 - (deadline - os.clock())
 report.candidateId, report.geometryRevision = course:GetAttribute("CandidateId"), course:GetAttribute("SampleRevision")
 report.setup = "Fresh Returning racer inspection enrollment, course selection and race restart; unlimited race deadline, unchanged mechanism clock; no checkpoint writes"
 return course, player
end
local function run()
 local report = {test = "R04 consecutive " .. line .. " pacing", line = line, pace = pace, traversalOverride = overrideContract,
  phase = 1, ownerApproval = false, lapsRequired = 3,
  expectedShellEncountersPerLap = #shellNames,
  setupSecondsLimit = 65, traversalSecondsLimit = 360, checkpointWrites = 0, initialPlacements = {}, laps = {},
  resultTransitions = {}, gateCrossings = {}, windowIntervals = {},
  limits = {
   "One scripted native avatar on one consecutive three-lap " .. line .. " route; no human, twenty-racer, device, FPS or owner-acceptance proof",
   if pace then "Uses existing practiced-control admission windows, forward landing aims and two consecutive stable samples; no minimum achievable player-time claim"
    else "Uses existing conservative admission windows, centered landing aims and unchanged .12-second settles; no minimum achievable player-time claim",
   "The existing driver makes its one initial placement and clears velocity only during initial setup and final controller cleanup",
   "Head/Torso overlap queries are sampled at most ten times per second; clear samples do not prove continuous body clearance",
   "Window intervals inferred from existing progress and movement receipts have small callback timing error; tray motion is not idle time",
  }}
 local player, course, character, root, humanoid, observer
 local ownershipSaved, originalOwner, originalAuto = false, nil, nil
 local observerFailure, current, initialFalls, initialRecoveryUntil, raceId, runStart, deadline
 local observations, windowIntervals = {}, report.windowIntervals
 local function publish() storeReport(report) end
 local function finished()
  if not player then return false end
  local value = services.ResultsService.GetPlayerResult(player)
  return value and value.status == "Finished" and value.lapTimes and #value.lapTimes == 3
 end
 local function guard()
  assert(not observerFailure, observerFailure)
  assert(os.clock() < deadline, "Consecutive three-lap driver exceeded 360 seconds")
  assert(player.Character == character and root.Parent and humanoid.Parent and humanoid.Health > 0,
   "Character changed or died; this attempt is not a completed pacing run")
  assert(services.CourseService.GetActiveCourse() == course and services.RaceService.GetCurrentRaceId() == raceId,
   "Course or race changed")
  local done = finished()
  assert(services.PlayerRaceService.IsOfficialRacer(player) and
   ((services.RaceService.IsRaceActive() and services.PlayerRaceService.GetPlayerStatus(player) == "Racing")
    or (done and current and current.finalSegment)), "Official racer status became invalid")
  assert(humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight - 7.2) < .01
   and math.abs(Workspace.Gravity - 196.2) < .01 and not root.Anchored, "Actual movement profile changed")
  local result = assert(services.ResultsService.GetPlayerResult(player))
  assert((result.falls or 0) == initialFalls, "Actual recovery occurred; consecutive clean pacing failed")
  assert((character:GetAttribute("RecoveryUntil") or 0) <= initialRecoveryUntil + .01,
   "Recovery immunity changed; do not count a recovered attempt as continuous pacing")
  assert(services.EggRushService.GetDiagnostics().bound == true, "Actual mechanism runtime unbound")
  return true
 end
 local ok, failure = xpcall(function()
  stored:SetAttribute("State", "Preparing")
  course, player = freshPrepare(report)
  character = assert(player.Character)
  root, humanoid = assert(character:FindFirstChild("HumanoidRootPart")), assert(character:FindFirstChildOfClass("Humanoid"))
  assert(humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight - 7.2) < .01
   and math.abs(Workspace.Gravity - 196.2) < .01 and not root.Anchored, "Expected ordinary actual avatar profile")
  raceId = services.RaceService.GetCurrentRaceId()
  report.raceId, report.userId = raceId, player.UserId
  report.movement = {walk = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight, useJumpPower = humanoid.UseJumpPower,
   gravity = Workspace.Gravity, maxSlopeAngle = humanoid.MaxSlopeAngle}
  report.initialResult = resultSnapshot(player)
  assert(report.initialResult.currentLap == 1 and report.initialResult.nextCheckpointIndex == 1
   and #report.initialResult.lapTimes == 0 and #report.initialResult.checkpointSplits == 0,
   "Fresh race already contains progress; no reset or fake advance will be applied")
  initialFalls, initialRecoveryUntil = report.initialResult.falls, character:GetAttribute("RecoveryUntil") or 0
  assert(initialFalls == 0, "Fresh race already contains recovery")
  local base = traversal.Points(course, line)
  assert(base[1].part == course.Start and base[#base].part == course.Start, "Existing driver must return physically to Start")
  local membership = {}
  for _, point in base do membership[point.part] = true end
  local choices = {}
  report[if line == "Expert" then "expertChoices" else "normalChoices"] = choices
  local routeNames = if line == "Expert" then {"E1_RimSprint", "E2_ChuteCut", "E3_CrownApproach", "E4_RoostCut"}
   else {"S1_Nestyard", "S2_EggRollers", "S3_ShellApproach", "S5_Rookery"}
  for _, routeName in routeNames do
   local refs = assert(course.Routes:FindFirstChild(routeName), "Missing actual " .. line .. " choice " .. routeName):GetChildren()
   local count = 0
   for _, ref in refs do
    assert(ref:IsA("ObjectValue") and ref.Value and membership[ref.Value], "Driver omitted an actual " .. line .. " route member")
    count += 1
   end
   assert(count > 0, "Empty " .. line .. " route")
   table.insert(choices, {route = routeName, members = count})
  end
  for _, name in shellNames do assert(membership[course.Obstacles.Mechanisms[name].ShellContact], "Driver omitted " .. name) end
  assert(membership[course.Obstacles.Shell_ForkWait], "Driver omitted the shared Fork wait")
  if line == "Normal" then assert(membership[course.Obstacles.Shell_MiddleWait], "Normal driver omitted the Middle wait") end
  for _, part in {course.Obstacles.Mechanisms.SidewaysTray.TrayContact, course.Obstacles.Tail_SafeWait,
   course.Obstacles.CP1_Pocket, course.Obstacles.CP2_Pocket, course.Obstacles.CP3_Pocket, course.Obstacles.CP4_Pocket} do
   assert(membership[part], "Driver omitted a shared encounter or checkpoint")
  end
  local points, pointLaps, lapEnds = {table.clone(base[1])}, {1}, {}
  for lap = 1, 3 do
   for i = 2, #base do table.insert(points, table.clone(base[i])); table.insert(pointLaps, lap) end
   lapEnds[#points] = lap
  end
  report.pointsPerLap, report.totalJumpsRequired = #base, #points - 1
  local finish = assert(services.CourseService.GetFinishPart())
  assert(finish:GetAttribute("RequireForwardCrossing") == true, "Use the actual continuous forward finish gate")
  report.lapJoinGeometry = {from = pose(base[#base - 1].part), to = pose(course.Start), finish = pose(finish),
   fromInFinishSpace = vector(finish.CFrame:PointToObjectSpace(base[#base - 1].part.Position)),
   startInFinishSpace = vector(finish.CFrame:PointToObjectSpace(course.Start.Position)),
   startGateCanCollide = course.StartPen.StartGate.CanCollide, requireForwardCrossing = true}
  local rayParams = RaycastParams.new()
  rayParams.FilterType, rayParams.FilterDescendantsInstances, rayParams.RespectCanCollide = Enum.RaycastFilterType.Include, {course}, true
  local function support()
   local hit = Workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + .7), 0), rayParams)
   return hit and hit.Instance
  end
  local mechanisms, shellParts = {}, {}
  for _, model in course.Obstacles.Mechanisms:GetChildren() do
   if model:IsA("Model") then mechanisms[model] = model.Name end
   if not model.Name:match("^CrownLip[1-5]$") and not model.Name:match("^ShellLip[1-4]$") then continue end
   local count = 0
   for _, part in model:GetDescendants() do
    if part:IsA("BasePart") and part.CanCollide then
     assert(part:GetAttribute("ERSupport") == true, "Unexpected colliding shell geometry")
     table.insert(shellParts, part); count += 1
    end
   end
   assert(count == 8, "Expected eight actual solid colliders in " .. model.Name)
  end
  assert(#shellParts == 72, "Expected all nine actual shells")
  local bodyParts = {}
  for _, name in {"Head", "UpperTorso", "LowerTorso", "Torso"} do
   local part = character:FindFirstChild(name)
   if part and part:IsA("BasePart") then table.insert(bodyParts, part) end
  end
  assert(#bodyParts >= 2, "No actual Head/Torso body parts")
  local overlapParams = OverlapParams.new()
  overlapParams.FilterType, overlapParams.FilterDescendantsInstances, overlapParams.RespectCanCollide = Enum.RaycastFilterType.Include, shellParts, true
  overlapParams.MaxParts = 72
  report.observer = {secondsByMotion = {}, phaseSecondsByMechanism = {}, overlapSamples = 0, samples = 0,
   overlapPairs = {}, firstOverlaps = {}, actualShellColliderCount = #shellParts, samplingSeconds = .1,
   overlapMeaning = "Actual Head/Torso shape queries against current colliding shell parts; body CanCollide is recorded separately"}
  local seenPairs, previousPosition, previousAt, previousSupport, previousSupportFrame, previousGatePosition = {}, nil, nil, nil, nil, nil
  local lastResultKey
  originalOwner, originalAuto = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto()
  ownershipSaved = true
  runStart, deadline = os.clock(), os.clock() + report.traversalSecondsLimit
  report.raceElapsedAtDriverStart = services.RaceService.GetElapsedRaceTime()
  report.initialPlacements[1] = {part = course.Start:GetFullName(), position = vector(course.Start.Position + course.Start.CFrame.UpVector * course.Start.Size.Y / 2
   + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + .15, 0)), purpose = "Existing NativeTraversal initial placement only"}
  observer = RunService.Heartbeat:Connect(function(dt)
   if observerFailure then return end
   local sampledOk, sampledFailure = xpcall(function()
    guard()
    local at, position = os.clock(), root.Position
    if previousGatePosition and ForwardGate.Crossed(finish.CFrame, finish.Size, previousGatePosition, position, dt) then
     table.insert(report.gateCrossings, {seconds = at - runStart, raceElapsed = services.RaceService.GetElapsedRaceTime(),
      previousInGate = vector(finish.CFrame:PointToObjectSpace(previousGatePosition)), currentInGate = vector(finish.CFrame:PointToObjectSpace(position)),
      step = current and current.step, result = resultSnapshot(player)})
    end
    previousGatePosition = position
    if previousAt and at - previousAt < .1 then return end
    local result = resultSnapshot(player)
    local key = table.concat({result.status, result.currentLap, result.nextCheckpointIndex, result.falls, #result.lapTimes}, ":")
    if key ~= lastResultKey then
     table.insert(report.resultTransitions, {seconds = at - runStart, result = result})
     lastResultKey = key
    end
    if result.status == "Finished" and not report.observedFinishSeconds then
     report.observedFinishSeconds, report.officialFinishSeconds = at - runStart, result.finishTime
     report.finishReceipt = result
    end
    local part = support()
    if previousAt then
     local elapsed = at - previousAt
     local onMechanism
     for model, name in mechanisms do if part and part:IsDescendantOf(model) then onMechanism = name; break end end
     local movingSupport = onMechanism and previousSupport == part and previousSupportFrame
      and (part.CFrame:PointToWorldSpace(previousSupportFrame:PointToObjectSpace(previousPosition)) - previousPosition).Magnitude > .002
     local kind = if humanoid.FloorMaterial == Enum.Material.Air then "Airborne"
      elseif not part then "NonAirWithoutRootRaySupport" elseif movingSupport then "MovingMechanismSupport"
      elseif (position - previousPosition).Magnitude / elapsed < .25 then "StationarySupported" else "OtherSupportedMovement"
     local observation = {from = previousAt - runStart, to = at - runStart, kind = kind, mechanism = onMechanism}
     table.insert(observations, observation)
     report.observer.secondsByMotion[kind] = (report.observer.secondsByMotion[kind] or 0) + elapsed
     for model, name in mechanisms do
      local durations = report.observer.phaseSecondsByMechanism[name] or {}
      local phase = model:GetAttribute("ERState") or "Missing"
      durations[phase] = (durations[phase] or 0) + elapsed
      report.observer.phaseSecondsByMechanism[name] = durations
     end
    end
    report.observer.samples += 1
    local hitThisSample = false
    for _, body in bodyParts do
     overlapParams.CollisionGroup = body.CollisionGroup
     for _, collider in Workspace:GetPartsInPart(body, overlapParams) do
      hitThisSample = true
      local pair = body.Name .. " -> " .. collider:GetFullName()
      report.observer.overlapPairs[pair] = (report.observer.overlapPairs[pair] or 0) + 1
      if not seenPairs[pair] and #report.observer.firstOverlaps < 8 then
       seenPairs[pair] = true
       table.insert(report.observer.firstOverlaps, {seconds = at - runStart, step = current and current.step,
        body = pose(body), bodyCanCollide = body.CanCollide, bodyCollisionGroup = body.CollisionGroup,
        shellCollider = pose(collider), shellState = collider.Parent:GetAttribute("ERState"),
        root = vector(root.Position), humanoidState = humanoid:GetState().Name, floor = humanoid.FloorMaterial.Name})
      end
     end
    end
    if hitThisSample then report.observer.overlapSamples += 1 end
    previousAt, previousPosition, previousSupport = at, position, part
    previousSupportFrame = part and part.CFrame
   end, debug.traceback)
   if not sampledOk then observerFailure = sampledFailure end
  end)
  stored:SetAttribute("State", "Running")
  local landed = 0
  report.driver = traversal.Run(course, player, points, {placeAtStart = true, pace = pace, guard = guard,
   afterLanding = function(index, point, receipt)
    landed += 1
    local at = os.clock()
    table.insert(windowIntervals, {from = current.began - runStart, to = math.max(current.began - runStart, at - runStart - receipt.seconds), step = current.step})
    local lap = pointLaps[index]
    local checkpoint = tonumber(point.part.Name:match("^CP([1-4])_Pocket$"))
    if checkpoint then
     waitFor(function()
      local value = resultSnapshot(player)
      return value.currentLap == lap and value.nextCheckpointIndex == checkpoint + 1 and splitExists(value, lap, checkpoint)
     end, .65, "Actual checkpoint touch missing at lap " .. lap .. " checkpoint " .. checkpoint, guard)
    end
    if lapEnds[index] then
     local joined = {lap = lap, secondsAtLanding = at - runStart, position = vector(root.Position),
      support = support() and support():GetFullName(), floor = humanoid.FloorMaterial.Name, beforeValidation = resultSnapshot(player)}
     table.insert(report.laps, joined)
     local accepted, joinFailure = pcall(function()
      waitFor(function()
       local value = resultSnapshot(player)
       return if lap < 3 then #value.lapTimes == lap and value.currentLap == lap + 1 and value.nextCheckpointIndex == 1
        else value.status == "Finished" and #value.lapTimes == 3 and value.finishTime ~= nil
      end, .65, "Physical return reached Start but actual forward lap/finish gate did not accept lap " .. lap, guard)
     end)
     joined.accepted, joined.afterValidation = accepted, resultSnapshot(player)
     joined.validationSeconds = os.clock() - at
     if not accepted then
      joined.gateFailure = tostring(joinFailure)
      joined.rootInFinishSpace = vector(finish.CFrame:PointToObjectSpace(root.Position))
      error(joinFailure)
     end
     publish()
    end
   end}, function(index, total, step)
    guard()
    current = {index = index, lap = pointLaps[index + 1], total = total, step = step, began = os.clock(), finalSegment = index == #points - 1}
    report.lastProgress = {index = index, total = total - 1, lap = current.lap, step = step, seconds = current.began - runStart}
    stored:SetAttribute("Progress", Http:JSONEncode({index = index, total = total - 1, lap = current.lap, step = step}))
   end)
  report.afterLandingCallbacks = landed
  assert(report.driver.ok, report.driver.failure)
  assert(report.driver.pace == pace and landed == #points - 1, "Installed NativeTraversal must match selected Pace and current afterLanding hooks")
  guard()
  report.finalResult = resultSnapshot(player)
  assert(report.finalResult.status == "Finished" and #report.finalResult.lapTimes == 3 and #report.finalResult.checkpointSplits == 12,
   "Actual services did not record three complete laps and twelve checkpoints")
  assert(#report.driver.trayCarries == 3, "Retain one actual full tray carry per lap")
  for _, carry in report.driver.trayCarries do assert(carry.supportedThroughout and carry.travelSamples > 0, "Missing actual supported tray travel") end
  local encounterCounts = {}
  for _, window in report.driver.windowTrace do
   encounterCounts[window.model] = (encounterCounts[window.model] or 0) + 1
   if window.model == "EggBand1" or window.model == "EggBand2" then assert(window.crossed == true, "An actual egg crossing was not completed") end
  end
  local requiredEncounters = {"EggBand1", "EggBand2", "GuardianTail", "SidewaysTray"}
  for _, name in shellNames do table.insert(requiredEncounters, name) end
  for _, name in requiredEncounters do
   assert(encounterCounts[name] == 3, "Expected three guarded encounters for " .. name)
  end
  report.encounterCounts = encounterCounts
  for lap = 1, 3 do for checkpoint = 1, 4 do assert(splitExists(report.finalResult, lap, checkpoint), "Missing real checkpoint receipt") end end
  report.officialFinishSeconds = report.finalResult.finishTime
  report.complete = true
 end, debug.traceback)
 if observer then observer:Disconnect() end
 if root and root.Parent and humanoid and humanoid.Parent then
  humanoid:Move(Vector3.zero, false); humanoid.Jump = false
  if ownershipSaved then
   local restored, restoreFailure = pcall(function()
    if originalAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(originalOwner) end
   end)
   report.ownershipRestored, report.ownershipRestoreFailure = restored, if restored then nil else tostring(restoreFailure)
  end
 end
 if player and services.ResultsService.GetPlayerResult(player) then report.lastResult = resultSnapshot(player) end
 report.observerFailure = observerFailure
 report.totalDriverWallSeconds = runStart and os.clock() - runStart
 report.windowAccounting = {driverWindowWaitSeconds = report.driver and report.driver.windowWaitSeconds,
  observedWindowSecondsByMotion = {}, inferredWindowSeconds = 0,
  meaning = "Driver window total includes egg/shell/tail admission, tray boarding and full tray carry; moving support time below is not stationary idle"}
 for _, interval in windowIntervals do
  report.windowAccounting.inferredWindowSeconds += interval.to - interval.from
  for _, observation in observations do
   local overlap = math.max(0, math.min(interval.to, observation.to) - math.max(interval.from, observation.from))
   if overlap > 0 then
    local bins = report.windowAccounting.observedWindowSecondsByMotion
    bins[observation.kind] = (bins[observation.kind] or 0) + overlap
   end
  end
 end
 if report.driver then
  report.windowAccounting.inferenceDifferenceSeconds = report.windowAccounting.inferredWindowSeconds - report.driver.windowWaitSeconds
 end
 report.sampledBodyOverlapObserved = report.observer and report.observer.overlapSamples > 0
 report.ok, report.failure = ok and observerFailure == nil, if ok then observerFailure else failure
 report.cleanup = "Observer disconnected, movement stopped and original root network ownership restored; no return teleport, checkpoint write, clock hold or source change"
 storeReport(report)
 stored:SetAttribute("State", if report.ok then "Complete" else "Failed")
end
stored.Value = Http:JSONEncode({state = "Ready", line = line, pace = pace, traversalOverride = overrideContract,
 ownerApproval = false, expectedSampleRevision = expectedRevision,
 command = {action = "Run"}, setup = "One Run command starts a fresh inspection race and one consecutive three-lap " .. line .. " attempt"})
stored:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end
 local parsed, command = pcall(function() return Http:JSONDecode(stored:GetAttribute("Command")) end)
 if not parsed or typeof(command) ~= "table" or command.action ~= "Run" then return end
 used = true
 task.spawn(run)
end)
