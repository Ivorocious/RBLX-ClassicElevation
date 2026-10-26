--!nonstrict
local RunService, Players = game:GetService("RunService"), game:GetService("Players")
local ServerStorage, Workspace, Http = game:GetService("ServerStorage"), game:GetService("Workspace"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer(), "Native Studio server traversal only")
local reportName = script:GetAttribute("ReportName") or "EggRushP2ContinuousReport"
assert(not ServerStorage:FindFirstChild(reportName), "Preserve the previous continuous receipt")
local stored = Instance.new("StringValue")
stored.Name, stored.Parent = reportName, ServerStorage
stored:SetAttribute("State", "Ready")
local services = {}
for _, name in {"CourseService", "RaceService", "PlayerRaceService", "CheckpointService", "ResultsService", "EggRushService"} do
 services[name] = require(game.ServerScriptService.Services[name])
end
local traversalModule = ServerStorage.CourseBuilders.EggRush.NativeTraversal
local traversal = require(traversalModule)
local ForwardGate = require(game.ReplicatedStorage.Shared.ForwardGate)
local CourseConfig = require(game.ReplicatedStorage.Config.CourseConfig)
local expectedCandidate = script:GetAttribute("ExpectedCandidateId") or "ER_P2_R01_C01"
local inspectionFixture = script:GetAttribute("StudioInspectionFixture") == true
local function vector(value) return {value.X, value.Y, value.Z} end
local function pose(part) return {path = part:GetFullName(), cframe = {part.CFrame:GetComponents()}, size = vector(part.Size),
 canCollide = part.CanCollide, collisionGroup = part.CollisionGroup} end
local function result(player)
 local value = assert(services.ResultsService.GetPlayerResult(player), "Missing official result")
 local laps, splits = {}, {}
 for index, seconds in value.lapTimes or {} do laps[index] = seconds end
 for _, split in value.checkpointSplits or {} do
  table.insert(splits, {lap = split.lap, checkpoint = split.checkpointIndex, elapsed = split.elapsedTime})
 end
 return {status = value.status, lap = value.currentLap, nextCheckpoint = value.nextCheckpointIndex,
  requiredLaps = value.requiredLaps, falls = value.falls or 0, lapTimes = laps, splits = splits,
  finishTime = value.finishTime, placement = value.placement}
end
local function hasSplit(value, lap, checkpoint)
 for _, split in value.splits do if split.lap == lap and split.checkpoint == checkpoint then return true end end
 return false
end
local publication = 0
local function publish(report)
 local encoded = Http:JSONEncode(report)
 publication += 1
 local folder = Instance.new("Folder"); folder.Name = string.format("Payload_%03d", publication)
 local names, offset = {}, 1
 while offset <= #encoded do
  local last = math.min(offset + 149999, #encoded)
  while last < #encoded do local byte = string.byte(encoded, last + 1); if byte < 128 or byte > 191 then break end; last -= 1 end
  local chunk = Instance.new("StringValue"); chunk.Name = string.format("Chunk_%03d", #names + 1)
  chunk.Value = string.sub(encoded, offset, last); chunk.Parent = folder
  table.insert(names, chunk.Name); offset = last + 1
 end
 folder.Parent = stored
 stored.Value = Http:JSONEncode({format = "EggRushP2ContinuousChunksV1", payloadFolder = folder.Name, chunks = names,
  jsonBytes = #encoded, line = report.line, ok = report.ok, complete = report.complete,
  officialFinishSeconds = report.officialFinishSeconds, ownerApproval = false})
end
local function run(command)
 local line = command.line or "Normal"
 local pace = line == "Expert"
 local report = {line = line, pace = pace, phase = 2, candidateId = expectedCandidate, ownerApproval = false,
  studioInspectionFixture = inspectionFixture,
  entryEvidence = if inspectionFixture then "Existing Studio returning-racer preset and developer race start; not supported entry proof" else "Ordinary entry observed separately",
  placements = 0, checkpointWrites = 0, profileWrites = 0, clockWrites = 0, lapsRequired = 3, maximumSeconds = 450,
  checkpointReceipts = {}, laps = {}, gateCrossings = {}, resultTransitions = {}, fallsObserved = {},
  method = "One canonical NativeTraversal.Run, placeAtStart=false, actual delivered Start slot and continuous physical lap joins",
  limits = {
   "One scripted native three-lap route, actual timing only; no human, crowd, device, FPS or owner acceptance claim",
   "Normal uses existing conservative control; Expert uses existing practiced control; no scoped takeoff override",
   "Existing driver clears velocity only in final controller cleanup; this runner performs no avatar placement or velocity writes",
   "Flow admission is observed by the separate passive Flow test; this runner never prepares or restarts a race",
   "Body profile/collider is preserved and monitored while Racing; Head/Torso overlap clearance needs the separate focused checks",
  }}
 local player, character, humanoid, root, course, collider, initialColliderSize
 local observer, observerFailure, current, raceId, baselineFalls, recoveryUntil
 local ownershipSaved, originalOwner, originalAuto = false, nil, nil
 local started, deadline = os.clock(), os.clock() + report.maximumSeconds
 local function logicalFinish()
  if not player or not current or not current.finalSegment then return false end
  local value = result(player)
  return value.status == "Finished" and #value.lapTimes == 3 and #value.splits == 12 and value.finishTime ~= nil
 end
 local function guard()
  assert(not observerFailure, observerFailure)
  assert(os.clock() < deadline, "Continuous route exceeded the 450-second bound")
  assert(player.Character == character and root.Parent and humanoid.Parent and humanoid.Health > 0,
   "Character changed or died; stop this continuous attempt")
  assert(services.CourseService.GetActiveCourse() == course and services.RaceService.GetCurrentRaceId() == raceId,
   "Race/course changed during continuous traversal")
  assert(not services.CourseService.IsInspectionMode() and not services.RaceService.IsInspectionUnlimitedTime()
   and (inspectionFixture or services.CourseService.GetSelectedCourseId() == CourseConfig.ActiveCourseId), "An inspection override/time change is present")
  assert((result(player).falls or 0) == baselineFalls, "Actual recovery occurred; continuous traversal failed")
  assert((character:GetAttribute("RecoveryUntil") or 0) <= recoveryUntil + .01, "Recovery immunity changed during traversal")
  if logicalFinish() then return true end
  assert(services.RaceService.IsRaceActive() and services.PlayerRaceService.IsOfficialRacer(player)
   and services.PlayerRaceService.GetPlayerStatus(player) == "Racing", "Not an actual official Racing participant")
  assert(not root.Anchored and humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower
   and math.abs(humanoid.JumpHeight - 7.2) < .01 and math.abs(Workspace.Gravity - 196.2) < .01,
   "Actual ordinary movement profile changed")
  assert(collider and collider.Parent and collider.CanCollide and (collider.Size - initialColliderSize).Magnitude < .02,
   "Accepted fitted physics collider changed while Racing")
  assert(services.EggRushService.GetDiagnostics().bound == true and course:GetAttribute("FullBodyContacts") == true,
   "Actual runtime/body repair no longer bound")
  return true
 end
 local function waitFor(predicate, seconds, message)
  local untilAt = os.clock() + seconds
  repeat
   guard()
   if predicate() then return end
   RunService.Heartbeat:Wait()
  until os.clock() >= untilAt
  error(message)
 end
 local ok, failure = xpcall(function()
  assert(line == "Normal" or line == "Expert", "Line must be Normal or Expert")
  player = assert(Players:GetPlayers()[1], "No first actual racer")
  character = assert(player.Character)
  root, humanoid = assert(character:FindFirstChild("HumanoidRootPart")), assert(character:FindFirstChildOfClass("Humanoid"))
  course = assert(services.CourseService.GetActiveCourse())
  assert(course:GetAttribute("CourseId") == "egg_rush_circuit" and course:GetAttribute("CandidateId") == expectedCandidate
   and course:GetAttribute("Phase") == 2 and course:GetAttribute("EROwned") == true
   and course:GetAttribute("FullBodyContacts") == true and course.CourseInfo:GetAttribute("Enabled") == true,
   "Expected the actual playable owned Phase 2 candidate")
  assert(services.CourseService.GetRaceFormat() == "LapBased" and services.CourseService.GetLapCount() == 3
   and #services.CourseService.GetOrderedCheckpoints() == 4, "Expected real four-checkpoint/three-lap course")
  raceId, baselineFalls, recoveryUntil = services.RaceService.GetCurrentRaceId(), result(player).falls, character:GetAttribute("RecoveryUntil") or 0
  collider = assert(character:FindFirstChild("CollisionPart"), "Actual fitted physics collider missing")
  initialColliderSize = collider.Size
  guard()
  report.raceId, report.userId, report.initialResult = raceId, player.UserId, result(player)
  assert(report.initialResult.lap == 1 and report.initialResult.nextCheckpoint == 1 and #report.initialResult.splits == 0
   and #report.initialResult.lapTimes == 0, "Start before checkpoint1; this runner will not reset progress")
  report.raceElapsedAtDriverStart = services.RaceService.GetElapsedRaceTime()
  report.actualStart = {root = pose(root), inStartSpace = vector(course.Start.CFrame:PointToObjectSpace(root.Position)), collider = pose(collider),
   movement = {walk = humanoid.WalkSpeed, useJumpPower = humanoid.UseJumpPower, jumpHeight = humanoid.JumpHeight, gravity = Workspace.Gravity}}
  local params = RaycastParams.new()
  params.FilterType, params.FilterDescendantsInstances, params.RespectCanCollide = Enum.RaycastFilterType.Include, {course}, true
  local function standing()
   local hit = Workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + .7), 0), params)
   return hit and hit.Instance
  end
  assert(standing() == course.Start and humanoid.FloorMaterial ~= Enum.Material.Air,
   "Avatar is not actually supported at the delivered Start slot; no corrective placement is allowed")
  report.actualStart.support = standing():GetFullName()
  local base = traversal.Points(course, line)
  assert(base[1].part == course.Start and base[#base].part == course.Start, "Canonical route must physically return through Start")
  local points, pointLap, lapEnds = {table.clone(base[1])}, {1}, {}
  for lap = 1, 3 do
   for i = 2, #base do table.insert(points, table.clone(base[i])); table.insert(pointLap, lap) end
   lapEnds[#points] = lap
  end
  report.pointsPerLap, report.jumpsRequired, report.driverModule = #base, #points - 1, traversalModule:GetFullName()
  local finish = assert(services.CourseService.GetFinishPart())
  assert(finish:GetAttribute("RequireForwardCrossing") == true, "Actual finish must require forward crossing")
  report.joinGeometry = {from = pose(base[#base - 1].part), to = pose(course.Start), gate = pose(finish)}
  local previousPosition, previousResult, previousKey, lastSample = nil, nil, nil, 0
  originalOwner, originalAuto = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto()
  ownershipSaved = true
  observer = RunService.Heartbeat:Connect(function(dt)
   local observed, message = xpcall(function()
    local value = result(player)
    if value.falls > baselineFalls and #report.fallsObserved == 0 then
     table.insert(report.fallsObserved, {seconds = os.clock() - started, result = value, position = vector(root.Position),
      previousResult = previousResult, recoveryUntil = character:GetAttribute("RecoveryUntil")})
    end
    guard()
    if previousPosition and ForwardGate.Crossed(finish.CFrame, finish.Size, previousPosition, root.Position, dt) then
     table.insert(report.gateCrossings, {seconds = os.clock() - started, before = previousResult, after = value,
      fromInGate = vector(finish.CFrame:PointToObjectSpace(previousPosition)), toInGate = vector(finish.CFrame:PointToObjectSpace(root.Position))})
    end
    previousPosition, previousResult = root.Position, value
    if os.clock() - lastSample < .1 then return end
    lastSample = os.clock()
    local key = table.concat({value.status, value.lap, value.nextCheckpoint, value.falls, #value.lapTimes}, ":")
    if key ~= previousKey then
     table.insert(report.resultTransitions, {seconds = os.clock() - started, result = value, position = vector(root.Position),
      status = services.PlayerRaceService.GetPlayerStatus(player), collider = pose(collider)})
     previousKey = key
    end
    if logicalFinish() and not report.finishReceipt then
     report.finishReceipt, report.officialFinishSeconds, report.observedFinishSeconds = value, value.finishTime, os.clock() - started
    end
   end, debug.traceback)
   if not observed then observerFailure = message end
  end)
  stored:SetAttribute("State", "Running")
  local landings = 0
  report.driver = traversal.Run(course, player, points, {placeAtStart = false, pace = pace, guard = guard,
   afterLanding = function(index, point)
    landings += 1
    local lap = pointLap[index]
    local checkpoint = tonumber(point.part.Name:match("^CP([1-4])_Pocket$"))
    if checkpoint then
     waitFor(function()
      local value = result(player)
      return value.lap == lap and value.nextCheckpoint == checkpoint + 1 and hasSplit(value, lap, checkpoint)
     end, .65, "Actual checkpoint touch missing: lap " .. lap .. ", checkpoint " .. checkpoint)
     table.insert(report.checkpointReceipts, {lap = lap, checkpoint = checkpoint, seconds = os.clock() - started, result = result(player)})
    end
    if lapEnds[index] then
     local joined = {lap = lap, seconds = os.clock() - started, position = vector(root.Position), support = standing() and standing():GetFullName(),
      beforeValidation = result(player), placement = false}
     table.insert(report.laps, joined)
     waitFor(function()
      local value = result(player)
      return if lap < 3 then #value.lapTimes == lap and value.lap == lap + 1 and value.nextCheckpoint == 1 else logicalFinish()
     end, .65, "Physical Start return did not produce the actual lap/finish gate receipt: lap " .. lap)
     joined.afterValidation = result(player)
     publish(report)
    end
   end}, function(index, total, step)
    guard()
    current = {index = index, total = total - 1, lap = pointLap[index + 1], step = step, finalSegment = index == #points - 1}
    report.lastProgress = current
    stored:SetAttribute("Progress", Http:JSONEncode(current))
   end)
  report.landingCallbacks = landings
  assert(report.driver.ok, report.driver.failure)
  assert(report.driver.pace == pace and landings == #points - 1, "Canonical native pace/landing hook contract mismatch")
  guard()
  report.finalResult = result(player)
  assert(logicalFinish() and #report.checkpointReceipts == 12 and #report.laps == 3, "Actual final lap/checkpoint/finish receipts incomplete")
  for lap = 1, 3 do for checkpoint = 1, 4 do assert(hasSplit(report.finalResult, lap, checkpoint), "Missing actual ordered split") end end
  assert(#report.driver.trayCarries == 3, "Expected one actual full tray ride per lap")
  for _, carry in report.driver.trayCarries do assert(carry.supportedThroughout and carry.travelSamples > 0, "Actual full tray carry missing") end
  report.encounterCounts = {}
  for _, window in report.driver.windowTrace do
   report.encounterCounts[window.model] = (report.encounterCounts[window.model] or 0) + 1
   if window.model == "EggBand1" or window.model == "EggBand2" then assert(window.crossed, "Guarded egg crossing did not complete") end
  end
  local required = {"EggBand1", "EggBand2", "GuardianTail", "SidewaysTray"}
  for i = 1, if line == "Expert" then 5 else 4 do table.insert(required, (if line == "Expert" then "CrownLip" else "ShellLip") .. i) end
  for _, name in required do assert(report.encounterCounts[name] == 3, "Missing three actual guarded encounters: " .. name) end
  report.officialFinishSeconds, report.complete = report.finalResult.finishTime, true
 end, debug.traceback)
 if observer then observer:Disconnect() end
 if root and root.Parent and humanoid and humanoid.Parent then
  humanoid:Move(Vector3.zero, false); humanoid.Jump = false
  if ownershipSaved then
   local restored, message = pcall(function() if originalAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(originalOwner) end end)
   report.ownershipRestored, report.ownershipRestoreFailure = restored, if restored then nil else tostring(message)
  end
 end
 if player and services.ResultsService.GetPlayerResult(player) then report.lastResult = result(player) end
 report.ok, report.failure = ok and observerFailure == nil, if ok then observerFailure else failure
 report.observerFailure, report.driverWallSeconds = observerFailure, os.clock() - started
 report.fallsDuringRun = report.lastResult and baselineFalls and report.lastResult.falls - baselineFalls
 report.cleanup = "Controller/observer disconnected, movement stopped and original network ownership restored; no return placement"
 publish(report); stored:SetAttribute("State", if report.ok then "Complete" else "Failed")
end
stored.Value = Http:JSONEncode({state = "Ready", command = {action = "Run", line = "Normal"}, lines = {"Normal", "Expert"},
 expectedCandidate = expectedCandidate, placeAtStart = false, ownerApproval = false,
 setup = "Actual ordinary official Racing participant still supported on delivered Start, before checkpoint1; no preparation/inspection helper"})
local used = false
stored:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end
 local parsed, command = pcall(function() return Http:JSONDecode(stored:GetAttribute("Command")) end)
 if not parsed or typeof(command) ~= "table" or command.action ~= "Run" then return end
 used = true; task.spawn(function()run(command)end)
end)
