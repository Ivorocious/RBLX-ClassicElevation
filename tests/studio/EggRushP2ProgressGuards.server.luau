--!nonstrict
local RunService, Workspace, Players = game:GetService("RunService"), game:GetService("Workspace"), game:GetService("Players")
local Storage, Http = game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819, "Owned native Studio server only")
local reportName = script:GetAttribute("ReportName") or "EggRushP2ProgressGuardsReport"
assert(typeof(reportName) == "string" and #reportName > 0 and #reportName <= 80 and reportName:match("^[%w_%-]+$"), "Use a simple report name")
assert(not Storage:FindFirstChild(reportName), "Preserve the previous receipt; use a fresh ReportName")
local stored = Instance.new("StringValue"); stored.Name, stored.Parent = reportName, Storage
stored:SetAttribute("State", "Ready")
local services = {}
for _, name in {"CourseService", "RaceService", "PlayerRaceService", "CheckpointService", "ResultsService", "EggRushService"} do
 services[name] = require(game.ServerScriptService.Services[name])
end
local ForwardGate = require(game.ReplicatedStorage.Shared.ForwardGate)
local CANDIDATE, MAXIMUM_SECONDS = script:GetAttribute("ExpectedCandidate") or "ER_P2_R01_C04", 90
local function vector(v) return {v.X, v.Y, v.Z} end
local function pose(p) return {path = p:GetFullName(), frame = {p.CFrame:GetComponents()}, size = vector(p.Size),
 canCollide = p.CanCollide, canTouch = p.CanTouch, collisionGroup = p.CollisionGroup} end
local function progress(player)
 local r = assert(services.ResultsService.GetPlayerResult(player), "Missing actual official result")
 local splits = {}
 for _, s in r.checkpointSplits or {} do table.insert(splits, {lap = s.lap, checkpoint = s.checkpointIndex, elapsed = s.elapsedTime}) end
 return {status = r.status, lap = r.currentLap, nextCheckpoint = r.nextCheckpointIndex, requiredLaps = r.requiredLaps,
  latestCheckpoint = services.CheckpointService.GetLatestCheckpointIndex(player), lapTimes = table.clone(r.lapTimes or {}),
  splits = splits, falls = r.falls or 0, finishTime = r.finishTime, placement = r.placement,
  official = services.PlayerRaceService.IsOfficialRacer(player), playerStatus = services.PlayerRaceService.GetPlayerStatus(player)}
end
local function unchanged(a, b)
 for _, key in {"status", "lap", "nextCheckpoint", "requiredLaps", "latestCheckpoint", "falls", "finishTime", "placement", "official", "playerStatus"} do
  if a[key] ~= b[key] then return false, key .. " changed" end
 end
 if #a.lapTimes ~= #b.lapTimes or #a.splits ~= #b.splits then return false, "Lap/split count changed" end
 for i, value in a.lapTimes do if b.lapTimes[i] ~= value then return false, "Lap time changed" end end
 for i, split in a.splits do
  for _, key in {"lap", "checkpoint", "elapsed"} do if b.splits[i][key] ~= split[key] then return false, "Checkpoint split changed" end end
 end
 return true
end
local publication = 0
local function publish(report)
 local encoded, names, offset = Http:JSONEncode(report), {}, 1
 publication += 1
 local folder = Instance.new("Folder"); folder.Name = string.format("Payload_%03d", publication)
 while offset <= #encoded do
  local last = math.min(offset + 149999, #encoded)
  while last < #encoded do local byte = string.byte(encoded, last + 1); if byte < 128 or byte > 191 then break end; last -= 1 end
  local chunk = Instance.new("StringValue"); chunk.Name = string.format("Chunk_%03d", #names + 1)
  chunk.Value, chunk.Parent = string.sub(encoded, offset, last), folder
  table.insert(names, chunk.Name); offset = last + 1
 end
 folder.Parent = stored
 stored.Value = Http:JSONEncode({format = "EggRushP2ProgressGuardsChunksV1", payloadFolder = folder.Name,
  chunks = names, jsonBytes = #encoded, ok = report.ok, complete = report.complete, ownerApproval = false})
end

local function run(command)
 local began, deadline = os.clock(), os.clock() + MAXIMUM_SECONDS
 local report = {phase = 2, candidateId = CANDIDATE, ownerApproval = false, ok = false, complete = false,
  maximumWallSeconds = MAXIMUM_SECONDS, checkpointWrites = 0, progressWrites = 0, profileWrites = 0,
  colliderWrites = 0, clockWrites = 0, placements = {}, actors = {}, cases = {},
  coverage = {incompleteReverse = false, incompleteForwardRejected = false, futureCheckpointRejected = false, isolatedReverseRejected = false},
  method = "Declared initial placements, actual ordinary Humanoid walking, real Finish ForwardGate and checkpoint Touched handlers; exact authoritative progression before and after",
  limits = {
   "Incomplete reverse crosses two guards at once; only the optional all-checkpoints reverse case isolates direction rejection",
   "The optional isolated reverse needs a preexisting Racing actor with four ordered current-lap split receipts; this script does not earn or synthesize those checkpoints",
   "Existing authoritative split receipts do not independently prove that no outside test wrote progression earlier; retain their physical test provenance separately",
   "A future checkpoint may first touch during declared placement/settling; actual Touched records identify that stage separately from walking",
   "No full-lap, ordinary entry, general anti-cheat, human, crowd, device, FPS or owner acceptance claim",
  }}
 local course, finish, ordered, raceId, controlled, controller
 local movement, actors, connections = Vector3.zero, {}, {}
 local ray = RaycastParams.new(); ray.FilterType = Enum.RaycastFilterType.Include; ray.RespectCanCollide = true
 local function clock() return services.EggRushService.GetDiagnostics().elapsed end
 local function support(a)
  local hit = Workspace:Raycast(a.root.Position, Vector3.new(0, -(a.humanoid.HipHeight + a.root.Size.Y / 2 + .7), 0), ray)
  return hit and hit.Instance
 end
 local function snapshot(a)
  local actual = support(a)
  return {progress = progress(a.player), root = pose(a.root), support = actual and actual:GetFullName(),
   floor = a.humanoid.FloorMaterial.Name, velocity = vector(a.root.AssemblyLinearVelocity),
   recoveryUntil = a.character:GetAttribute("RecoveryUntil") or 0, runtimeClock = clock(),
   elapsedRaceTime = services.RaceService.GetElapsedRaceTime(), wallSeconds = os.clock() - began}
 end
 local function guard(a)
  assert(os.clock() < deadline, "90-second total budget exhausted")
  assert(services.CourseService.GetActiveCourse() == course and services.RaceService.IsRaceActive()
   and services.RaceService.GetCurrentRaceId() == raceId, "Actual course/race changed or ended")
  assert(course:GetAttribute("CourseId") == "egg_rush_circuit" and course:GetAttribute("CandidateId") == CANDIDATE
   and course:GetAttribute("Phase") == 2 and course:GetAttribute("EROwned") == true
   and course:GetAttribute("FullBodyContacts") == true and services.EggRushService.GetDiagnostics().bound == true,
   "Actual owned expected-candidate full-body runtime required")
  assert(a.player.Parent == Players and a.player.Character == a.character and a.root.Parent and a.humanoid.Health > 0,
   "Original actual character changed, left or died")
  assert(services.PlayerRaceService.IsOfficialRacer(a.player) and services.PlayerRaceService.GetPlayerStatus(a.player) == "Racing",
   "Actual official Racing participant required")
  assert(not a.root.Anchored and a.humanoid.WalkSpeed == 16 and not a.humanoid.UseJumpPower
   and math.abs(a.humanoid.JumpHeight - 7.2) < .01 and math.abs(Workspace.Gravity - 196.2) < .01,
   "Ordinary native 16/7.2 profile changed")
  assert(a.collider.Parent and a.collider.CanCollide and (a.collider.Size - a.colliderSize).Magnitude < .02, "Accepted body collider changed")
  local delta = a.colliderRelative:ToObjectSpace(a.root.CFrame:ToObjectSpace(a.collider.CFrame)); local _, angle = delta:ToAxisAngle()
  assert(delta.Position.Magnitude < .02 and math.abs(angle) < .002, "Accepted collider attachment changed")
  assert(progress(a.player).falls == a.initialProgress.falls, "Actual fall/recovery occurred; this guard fixture is no longer isolated")
 end
 local function waitFor(a, predicate, seconds, message)
  local limit = math.min(deadline, os.clock() + seconds)
  repeat guard(a); if predicate() then return end; RunService.Heartbeat:Wait() until os.clock() >= limit
  error(message)
 end
 local function hold(a, seconds)
  movement = Vector3.zero
  local untilAt = math.min(deadline, os.clock() + seconds)
  repeat guard(a); RunService.Heartbeat:Wait() until os.clock() >= untilAt
 end
 local function at(pad, a, localX, localZ, direction)
  local p = pad.CFrame:PointToWorldSpace(Vector3.new(localX, pad.Size.Y / 2, localZ))
   + Vector3.yAxis * (a.humanoid.HipHeight + a.root.Size.Y / 2 + .15)
  return CFrame.lookAt(p, p + direction)
 end
 local function placeAndSettle(a, pad, frame, case)
  guard(a); movement = Vector3.zero; controlled = a; a.used = true; a.root:SetNetworkOwner(nil)
  waitFor(a, function() return (a.character:GetAttribute("RecoveryUntil") or 0) <= Workspace:GetServerTimeNow() end,
   5, "Preexisting actual recovery immunity did not expire")
  local localRoot = pad.CFrame:PointToObjectSpace(frame.Position)
  assert(pad.Anchored and pad.CanCollide and pad.CanQuery and pad.CFrame.UpVector:Dot(Vector3.yAxis) > .9999
   and math.abs(localRoot.X) <= pad.Size.X / 2 - .75 and math.abs(localRoot.Z) <= pad.Size.Z / 2 - .75,
   "Declared root placement must remain inside the actual fixed support")
  case.stage = "InitialPlacement"
  table.insert(report.placements, {case = case.name, userId = a.player.UserId, kind = "InitialCasePlacement",
   rootFrame = {frame:GetComponents()}, before = snapshot(a), runtimeClock = clock()})
  a.character:PivotTo(frame * a.root.CFrame:ToObjectSpace(a.character:GetPivot()))
  a.root.AssemblyLinearVelocity, a.root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
  case.stage = "Settling"
  local stableSince
  waitFor(a, function()
   local stable = support(a) == pad and a.humanoid.FloorMaterial ~= Enum.Material.Air and math.abs(a.root.AssemblyLinearVelocity.Y) < .1
   if stable then stableSince = stableSince or os.clock() else stableSince = nil end
   return stableSince and os.clock() - stableSince >= .25
  end, 3, "Actual named support/nonAir/vertical stability did not persist for .25 seconds")
  case.afterSetup = snapshot(a)
  local same, why = unchanged(case.before.progress, case.afterSetup.progress)
  assert(same, "Initial placement changed progression before the walking probe: " .. tostring(why))
 end
 local function walk(a, pad, target, case, watchFinish)
  case.stage, case.samples = "Walking", {}
  case.forwardCrossings, case.reverseCrossings = {}, {}
  local previous, limit = a.root.Position, math.min(deadline, os.clock() + 3)
  repeat
   guard(a)
   assert(support(a) == pad and a.humanoid.FloorMaterial ~= Enum.Material.Air, "Actual named walking support lost")
   local flat = (target - a.root.Position) * Vector3.new(1, 0, 1)
   if flat.Magnitude <= .4 then break end
   movement = flat.Unit
   local dt = RunService.Heartbeat:Wait()
   local current = a.root.Position
   local sample = {runtimeClock = clock(), rootPosition = vector(current), rootGateLocal = watchFinish and vector(finish.CFrame:PointToObjectSpace(current)),
    support = support(a) and support(a):GetFullName(), floor = a.humanoid.FloorMaterial.Name, deltaSeconds = dt}
   table.insert(case.samples, sample)
   if watchFinish then
    if ForwardGate.Crossed(finish.CFrame, finish.Size, previous, current, dt) then table.insert(case.forwardCrossings, sample) end
    if ForwardGate.Crossed(finish.CFrame * CFrame.Angles(0, math.pi, 0), finish.Size, previous, current, dt) then table.insert(case.reverseCrossings, sample) end
   end
   previous = current
  until os.clock() >= limit
  movement = Vector3.zero
  assert(((target - a.root.Position) * Vector3.new(1, 0, 1)).Magnitude <= .4, "Ordinary walking did not reach the target within three seconds")
  case.stage = "PostWalkHold"; hold(a, .35)
  assert(support(a) == pad and a.humanoid.FloorMaterial ~= Enum.Material.Air, "Actual fixed support lost after walking")
 end
 local function caseRecord(name)
  local value = {name = name, status = "Untested", reason = "Prerequisite not yet checked"}
  table.insert(report.cases, value); return value
 end
 local reverse, incomplete, future, isolated = caseRecord("IncompleteReverseFinish"), caseRecord("IncompleteForwardFinish"),
  caseRecord("FutureCheckpointTouch"), caseRecord("AllCheckpointsReverseFinish")
 local function attempt(case, a, action)
  stored:SetAttribute("CurrentCase", case.name)
  case.userId, case.before, case.reason = a.player.UserId, snapshot(a), nil
  local ok, why = xpcall(function() action(); case.after = snapshot(a)
   local same, changed = unchanged(case.before.progress, case.after.progress)
   assert(same, "Actual negative probe changed authoritative progression: " .. tostring(changed))
  end, debug.traceback)
  movement = Vector3.zero; case.stage = "Ended"
  case.status, case.failure = if ok then "Passed" else "Failed", if ok then nil else why
  if not case.after then local captured, state = pcall(snapshot, a); if captured then case.after = state end end
  publish(report)
  assert(ok, why)
 end
 local ok, failure = xpcall(function()
  assert(typeof(CANDIDATE) == "string" and #CANDIDATE > 0, "ExpectedCandidate must be a nonempty exact candidate id")
  local args, tag = game:GetService("StudioTestService"):GetTestArgs(), script:GetAttribute("OwnedStudioTestTag")
  local exactTag = typeof(tag) == "string" and #tag > 0 and typeof(args) == "table" and args.tag == tag
  local exactSolo = args == nil and tag == "EggRush_P2_C05_Solo" and CANDIDATE == "ER_P2_R01_C05" and #Players:GetPlayers() == 1
  assert(exactTag or exactSolo, "Exact owned multiplayer tag or the single-player C05 Solo nil-args fixture required")
  report.ownedTestTagSource, report.getTestArgsWasNil = if exactSolo then "ExactOwnedC05SoloFallback" else "StudioTestServiceExactTag", args == nil
  local requested = command.UserId or command.userId or script:GetAttribute("UserId")
  if requested ~= nil then
   assert(typeof(requested) == "number" and requested % 1 == 0 and Players:GetPlayerByUserId(requested), "UserId must select one actual Player")
  end
  report.requestedUserId = requested
  course = assert(services.CourseService.GetActiveCourse(), "Prepare the actual owned expected-candidate official race first")
  ray.FilterDescendantsInstances = {course}
  raceId = services.RaceService.GetCurrentRaceId()
  assert(typeof(raceId) == "string" and raceId ~= "" and services.EggRushService.GetDiagnostics().raceId == raceId, "Actual bound current race required")
  finish, ordered = assert(services.CourseService.GetFinishPart()), services.CourseService.GetOrderedCheckpoints()
  assert(finish:GetAttribute("RequireForwardCrossing") == true and #ordered == 4
   and services.CourseService.GetRaceFormat() == "LapBased" and services.CourseService.GetLapCount() == 3, "Actual directional four-checkpoint/three-lap course required")
  report.raceId, report.ownedStudioTestTag, report.finish = raceId, tag, pose(finish)
  report.inspectionFixture = {selection = services.CourseService.IsInspectionMode(), unlimitedTime = services.RaceService.IsInspectionUnlimitedTime()}
  local list = Players:GetPlayers(); table.sort(list, function(a, b) return a.UserId < b.UserId end)
  for _, player in list do
   if services.PlayerRaceService.IsOfficialRacer(player) and services.PlayerRaceService.GetPlayerStatus(player) == "Racing" then
    local character = assert(player.Character)
    local a = {player = player, character = character, root = assert(character:FindFirstChild("HumanoidRootPart")),
     humanoid = assert(character:FindFirstChildOfClass("Humanoid")), collider = assert(character:FindFirstChild("CollisionPart"))}
    a.initialProgress, a.colliderSize = progress(player), a.collider.Size
    a.colliderRelative, a.owner, a.ownershipAuto = a.root.CFrame:ToObjectSpace(a.collider.CFrame), a.root:GetNetworkOwner(), a.root:GetNetworkOwnershipAuto()
    guard(a); table.insert(actors, a)
    table.insert(report.actors, {userId = player.UserId, before = snapshot(a), collider = pose(a.collider), colliderRelative = {a.colliderRelative:GetComponents()}})
   end
  end
  assert(#actors > 0, "No actual official Racing actor")
  if requested then
   local found = false
   for _, a in actors do if a.player.UserId == requested then found = true; break end end
   assert(found, "Requested actual Player is not an ordinary official Racing actor")
  end
  controller = RunService.PreSimulation:Connect(function()
   local a = controlled
   if a and a.player.Character == a.character and a.humanoid.Parent then a.humanoid:Move(movement, false); a.humanoid.Jump = false end
  end)
  local incompleteActor, armedActor
  local armedRequested = script:GetAttribute("ArmedUserId") or requested
  for _, a in actors do
   local r = a.initialProgress
   if r.nextCheckpoint <= 4 and (not requested or requested == a.player.UserId) then
    if not incompleteActor or (r.nextCheckpoint <= 3 and incompleteActor.initialProgress.nextCheckpoint > 3) then incompleteActor = a end
   end
   if r.nextCheckpoint == 5 and r.latestCheckpoint == 4 and (not armedRequested or armedRequested == a.player.UserId) then
    local current = {}
    for _, split in r.splits do if split.lap == r.lap then table.insert(current, split) end end
    local valid = #current == 4
    for index, split in current do
     valid = valid and split.checkpoint == index and typeof(split.elapsed) == "number"
      and (index == 1 or split.elapsed >= current[index - 1].elapsed)
    end
    if valid then armedActor = a; isolated.prerequisiteSplits = current end
   end
  end
  local start = assert(course:FindFirstChild("Start"))
  local function finishProbe(case, a, forward)
   attempt(case, a, function()
    local sign = if forward then 1 else -1
    local from, to = finish.CFrame:PointToWorldSpace(Vector3.new(0, 0, sign * 3)), finish.CFrame:PointToWorldSpace(Vector3.new(0, 0, -sign * 3))
    local localFrom = start.CFrame:PointToObjectSpace(from)
    local direction = (to - from) * Vector3.new(1, 0, 1); direction = direction.Unit
    local frame = at(start, a, localFrom.X, localFrom.Z, direction)
    case.direction, case.actualSupport = if forward then "Forward local +Z to -Z" else "Reverse local -Z to +Z", pose(start)
    placeAndSettle(a, start, frame, case)
    local target = Vector3.new(to.X, a.root.Position.Y, to.Z)
    walk(a, start, target, case, true)
    assert((if forward then #case.forwardCrossings else #case.reverseCrossings) >= 1, "Required continuous actual root crossing was not observed")
    assert((if forward then #case.reverseCrossings else #case.forwardCrossings) == 0, "Unexpected opposite gate crossing during the same walking probe")
   end)
  end
  if incompleteActor then
   finishProbe(reverse, incompleteActor, false); report.coverage.incompleteReverse = true
   finishProbe(incomplete, incompleteActor, true); report.coverage.incompleteForwardRejected = true
   local expected = progress(incompleteActor.player).nextCheckpoint
   if expected <= 3 then
    local definition
    for _, value in ordered do if value.index == expected + 1 then definition = value; break end end
    assert(definition, "Future actual checkpoint definition missing")
    attempt(future, incompleteActor, function()
     local a, trigger = incompleteActor, definition.part
     local pad = assert(course.Obstacles:FindFirstChild("CP" .. definition.index .. "_Pocket"))
     assert(trigger.CanTouch and not trigger.CanCollide, "Actual checkpoint touch trigger required")
     future.expectedIndex, future.touchedIndex, future.trigger, future.touchCount = expected, definition.index, pose(trigger), 0
     future.touchStages, future.touches = {}, {}
     local touch = trigger.Touched:Connect(function(part)
      if part:IsDescendantOf(a.character) and part:FindFirstAncestorWhichIsA("Model") == a.character then
       future.touchCount += 1; future.touchStages[future.stage or "BeforePlacement"] = true
       if #future.touches < 32 then table.insert(future.touches, {body = part.Name, stage = future.stage,
        runtimeClock = clock(), bodyFrame = {part.CFrame:GetComponents()}, rootPosition = vector(a.root.Position)}) end
      end
     end)
     table.insert(connections, touch)
     local direction = pad.CFrame.LookVector * Vector3.new(1, 0, 1)
     placeAndSettle(a, pad, at(pad, a, 0, 3, direction.Unit), future)
     local target = pad.CFrame:PointToWorldSpace(Vector3.new(0, pad.Size.Y / 2, -3))
     walk(a, pad, target, future, false)
     touch:Disconnect()
     assert(future.touchCount > 0, "No actual character Touched event; visual/query overlap alone cannot prove rejection")
    end)
    report.coverage.futureCheckpointRejected = true
   else future.reason = "Incomplete actor expects CP4, so no later checkpoint exists; use a fresh actor expecting CP1..CP3" end
  else
   reverse.reason, incomplete.reason, future.reason = "No selected incomplete official racer", "No selected incomplete official racer", "No selected incomplete official racer"
  end
  if armedActor then
   isolated.prerequisite = "Preexisting actual nextCheckpoint5/latest4 and four ordered current-lap split receipts; no checkpoints earned or written by this helper"
   finishProbe(isolated, armedActor, false); report.coverage.isolatedReverseRejected = true
  else isolated.reason = "No selected existing Racing actor has all four ordered current-lap checkpoint receipts; direction-only rejection remains untested" end
 end, debug.traceback)
 movement = Vector3.zero
 if controller then controller:Disconnect() end
 for _, connection in connections do connection:Disconnect() end
 local cleanupErrors = {}
 for index, a in actors do
  local clean, why = pcall(function()
   if a.used then
    if a.humanoid.Parent then a.humanoid:Move(Vector3.zero, false); a.humanoid.Jump = false end
    if a.root.Parent then if a.ownershipAuto then a.root:SetNetworkOwnershipAuto() else a.root:SetNetworkOwner(a.owner) end end
   end
   report.actors[index].after = snapshot(a)
  end)
  if not clean then table.insert(cleanupErrors, tostring(why)) end
 end
 local passed, failed = 0, 0
 for _, case in report.cases do
  if case.status == "Passed" then passed += 1 elseif case.status == "Failed" then failed += 1
  elseif case.reason == "Prerequisite not yet checked" then case.reason = "Stopped before this case; see the retained failure" end
 end
 report.ok, report.failure, report.cleanupErrors = ok and failed == 0 and passed > 0 and #cleanupErrors == 0, if ok then nil else failure, cleanupErrors
 report.complete = report.coverage.incompleteReverse == true and report.coverage.incompleteForwardRejected == true and report.coverage.futureCheckpointRejected == true
 report.wallSeconds, report.finalPlacementWrites = os.clock() - began, 0
 report.cleanup = "Movement and touch observers disconnected, used actors' ordinary movement stopped and original ownership restored where the original root remains; no final placement or direct progression writes"
 publish(report)
 stored:SetAttribute("State", if not report.ok then "Failed" elseif report.complete then "Complete" else "Partial")
 print("ER_P2_PROGRESS_GUARDS", report.ok, report.complete, passed, report.wallSeconds, report.failure or "")
end
stored.Value = Http:JSONEncode({state = "Ready", action = "Run", candidateId = CANDIDATE, maximumWallSeconds = MAXIMUM_SECONDS,
 requiredScriptAttribute = "OwnedStudioTestTag", optionalScriptAttributes = {"UserId", "ArmedUserId", "ReportName", "ExpectedCandidate"},
 expectedCandidateDefault = "ER_P2_R01_C04", soloFallback = "Nil GetTestArgs, exact EggRush_P2_C05_Solo tag, expected C05 and one actual Player only",
 optionalCommandUserId = "UserId selects one actual actor: armed runs only isolated reverse; incomplete runs available incomplete/future cases",
 prerequisites = "Official ordinary actor expecting CP1..CP3 for all three core negatives; optional existing actor with four ordered current-lap CP split receipts isolates reverse Finish", ownerApproval = false})
local used = false
stored:GetAttributeChangedSignal("Command"):Connect(function()
 local raw = stored:GetAttribute("Command")
 if used or typeof(raw) ~= "string" or raw == "" then return end
 used = true; stored:SetAttribute("Command", ""); stored:SetAttribute("State", "Running")
 task.spawn(function()
  local valid, command = pcall(Http.JSONDecode, Http, raw)
  if not valid or typeof(command) ~= "table" or command.action ~= "Run" then
   stored.Value = Http:JSONEncode({ok = false, failure = "Single-use command must be {action=Run}"}); stored:SetAttribute("State", "Failed"); return
  end
  run(command)
 end)
end)
