--!nonstrict
local RunService, Players = game:GetService("RunService"), game:GetService("Players")
local Storage, Workspace, Http = game:GetService("ServerStorage"), game:GetService("Workspace"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819, "Owned native Studio server only")
local reportName = script:GetAttribute("ReportName") or "EggRushP2ReturnProbeReport"
assert(typeof(reportName) == "string" and #reportName > 0 and #reportName <= 80 and reportName:match("^[%w_%-]+$"), "Use a simple ReportName")
assert(not Storage:FindFirstChild(reportName), "Preserve the existing report; use a unique ReportName")
local stored = Instance.new("StringValue")
stored.Name, stored.Parent = reportName, Storage
stored:SetAttribute("State", "Ready")
local expectedCandidate = script:GetAttribute("ExpectedCandidate") or script:GetAttribute("ExpectedCandidateId") or "ER_P2_R01_C05"
local services = {}
for _, name in {"CourseService", "RaceService", "PlayerRaceService", "CheckpointService", "ResultsService", "EggRushService"} do
 services[name] = require(game.ServerScriptService.Services[name])
end
local traversalModule = Storage.CourseBuilders.EggRush.NativeTraversal
local traversal = require(traversalModule)
local MAXIMUM_SECONDS, MAXIMUM_REPEATS, MAXIMUM_FRAMES = 60, 8, 1000
local function vector(v) return {v.X, v.Y, v.Z} end
local function rounded(value, precision) local scale = 10 ^ (precision or 4); return math.round(value * scale) / scale end
local function compactVector(v) return {rounded(v.X), rounded(v.Y), rounded(v.Z)} end
local function compactFrame(frame)
 local values = {frame:GetComponents()}
 for index, value in values do values[index] = rounded(value, if index <= 3 then 4 else 6) end
 return values
end
local function pose(part)
 return {path = part:GetFullName(), cframe = {part.CFrame:GetComponents()}, size = vector(part.Size),
  canCollide = part.CanCollide, collisionGroup = part.CollisionGroup}
end
local function progress(player)
 local value = assert(services.ResultsService.GetPlayerResult(player), "Missing actual result")
 local splits = {}
 for _, split in value.checkpointSplits or {} do
  table.insert(splits, {lap = split.lap, checkpoint = split.checkpointIndex, elapsed = split.elapsedTime})
 end
 return {status = value.status, lap = value.currentLap, nextCheckpoint = value.nextCheckpointIndex,
  latestCheckpoint = services.CheckpointService.GetLatestCheckpointIndex(player), falls = value.falls or 0,
  requiredLaps = value.requiredLaps, lapTimes = table.clone(value.lapTimes or {}), splits = splits,
  finishTime = value.finishTime, placement = value.placement}
end
local function sameProgress(before, after)
 for _, key in {"status", "lap", "nextCheckpoint", "latestCheckpoint", "requiredLaps", "finishTime", "placement"} do
  if before[key] ~= after[key] then return false, key .. " changed" end
 end
 if #before.lapTimes ~= #after.lapTimes or #before.splits ~= #after.splits then return false, "Lap/split count changed" end
 for index, seconds in before.lapTimes do if after.lapTimes[index] ~= seconds then return false, "Lap time changed" end end
 for index, split in before.splits do
  for _, key in {"lap", "checkpoint", "elapsed"} do
   if after.splits[index][key] ~= split[key] then return false, "Ordered checkpoint receipt changed" end
  end
 end
 return true
end
local function edgeDistance(part, position, direction)
 local p, d = part.CFrame:PointToObjectSpace(position), part.CFrame:VectorToObjectSpace(direction)
 local distance = math.huge
 for _, axis in {"X", "Z"} do
  if math.abs(d[axis]) > .0001 then distance = math.min(distance, (math.sign(d[axis]) * part.Size[axis] / 2 - p[axis]) / d[axis]) end
 end
 return distance
end
local function publish(report)
 local encoded, names, offset = Http:JSONEncode(report), {}, 1
 local payload = Instance.new("Folder"); payload.Name = "Payload_001"
 while offset <= #encoded do
  local last = math.min(offset + 149999, #encoded)
  while last < #encoded do local byte = string.byte(encoded, last + 1); if byte < 128 or byte > 191 then break end; last -= 1 end
  local chunk = Instance.new("StringValue"); chunk.Name = string.format("Chunk_%03d", #names + 1)
  chunk.Value, chunk.Parent = string.sub(encoded, offset, last), payload
  table.insert(names, chunk.Name); offset = last + 1
 end
 payload.Parent = stored
 stored.Value = Http:JSONEncode({format = "EggRushP2ReturnProbeChunksV1", payloadFolder = payload.Name, chunks = names,
  jsonBytes = #encoded, ok = report.ok, complete = report.complete, attempts = #report.attempts,
  frames = #report.frames, ownerApproval = false})
end
local function run(command)
 local began, deadline = os.clock(), os.clock() + MAXIMUM_SECONDS
 local requested = command.repeats or 6
 local report = {phase = 2, candidateId = expectedCandidate, ownerApproval = false, ok = false, complete = false,
  maximumSeconds = MAXIMUM_SECONDS, maximumRepeats = MAXIMUM_REPEATS, maximumFrames = MAXIMUM_FRAMES,
  requestedRepeats = requested, checkpointWrites = 0, progressWrites = 0, profileWrites = 0, clockWrites = 0,
  placements = {}, attempts = {}, frames = {}, supports = {},
  frameFields = {"seconds", "serverTime", "stage", "dt", "attempt", "rootCFrame", "rootVelocity", "rootAngularVelocity",
   "colliderCFrame", "colliderVelocity", "jump", "state", "floor", "moveDirection", "supportId", "supportPosition", "supportNormal",
   "edgeDistance005", "rootIn006", "colliderCornersIn006", "falls", "recoveryUntil"},
  diagnosticRounding = "Focused frame positions/velocities/corners rounded to.0001stud; CFrame bases to.000001; endpoint and geometry poses retain native numbers",
  method = "Canonical NativeTraversal.Run, pace=false and placeAtStart=true for each declared 004-to-007 prefix; unchanged .55 takeoff inset",
  limits = {
   "Focused scripted attempts with declared initial placements; not continuous-lap, ordinary-entry, human or crowd proof",
   "PreSimulation observer is installed before the canonical driver listener; its Jump field may precede that frame's driver assignment",
   "PostSimulation records actual physical output; observed positive vertical velocity is distinct from an observed Jump request",
   "The existing driver clears velocity and restores automatic ownership in its final cleanup after each attempt; this helper restores the original ownership on exit",
   "No return placement, geometry change, driver fork, pacing override or service/lifecycle mutation",
   "Recovery source is available in existing RespawnService server Output; this script does not intercept or replace that service",
   "Full Pre/Post frames cover only005-to-006; adjacent hops retain canonical records and actual supported endpoint poses",
  }}
 local player, character, humanoid, root, collider, course, raceId, baseline, originalCollider, recoveryUntil
 local originalOwner, originalAuto, ownershipSaved = nil, nil, false
 local connections, observerFailure, currentAttempt, currentHop, supportIds = {}, nil, nil, nil, {}
 local part005, part006, outgoing005, ray
 local function integrity(value)
  local unchanged, reason = sameProgress(baseline, value)
  assert(unchanged, reason)
  assert(value.falls == baseline.falls, "Actual recovery occurred; stop the focused attempt")
 end
 local function guard()
  assert(not observerFailure, observerFailure)
  assert(os.clock() < deadline, "Return probe exceeded its 60-second bound")
  assert(player.Character == character and root.Parent and humanoid.Parent and humanoid.Health > 0, "Character changed or died")
  assert(services.CourseService.GetActiveCourse() == course and services.RaceService.GetCurrentRaceId() == raceId,
   "Course/race identity changed")
  assert(services.RaceService.IsRaceActive() and services.PlayerRaceService.IsOfficialRacer(player)
   and services.PlayerRaceService.GetPlayerStatus(player) == "Racing", "Expected actual official Racing participant")
  assert(course:GetAttribute("CandidateId") == expectedCandidate and course:GetAttribute("FullBodyContacts") == true
   and services.EggRushService.GetDiagnostics().bound == true, "Candidate or body runtime changed")
  assert(humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight - 7.2) < .01
   and math.abs(Workspace.Gravity - 196.2) < .01 and not root.Anchored, "Ordinary movement profile changed")
  assert(collider.Parent == character and collider.CanCollide and (collider.Size - originalCollider).Magnitude < .02,
   "Accepted fitted collider changed")
  integrity(progress(player))
  if recoveryUntil then assert((character:GetAttribute("RecoveryUntil") or 0) <= recoveryUntil + .01, "New recovery immunity observed") end
  return true
 end
 local function standing()
  local hit = Workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + .7), 0), ray)
  return hit and hit.Instance, hit
 end
 local function observe(stage, dt)
  if not currentAttempt or not currentHop or currentHop.index ~= 2 or not root.Parent or not collider.Parent then return end
  local ok, reason = xpcall(function()
   assert(#report.frames < MAXIMUM_FRAMES, "Frame budget exhausted; stop instead of continuing without a trace")
   local support, hit = standing()
   local in006, corners = part006.CFrame:PointToObjectSpace(root.Position), {}
   local minimum, maximum = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
   for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
    local corner = part006.CFrame:PointToObjectSpace(collider.CFrame:PointToWorldSpace(collider.Size * Vector3.new(x, y, z) / 2))
    table.insert(corners, compactVector(corner))
    minimum = Vector3.new(math.min(minimum.X, corner.X), math.min(minimum.Y, corner.Y), math.min(minimum.Z, corner.Z))
    maximum = Vector3.new(math.max(maximum.X, corner.X), math.max(maximum.Y, corner.Y), math.max(maximum.Z, corner.Z))
   end end end
   local seconds = os.clock() - began
   local sample = {seconds = seconds, serverTime = Workspace:GetServerTimeNow(), stage = stage, dt = dt,
    attempt = currentAttempt.index, hop = currentHop and currentHop.index, rootCFrame = {root.CFrame:GetComponents()},
    rootVelocity = vector(root.AssemblyLinearVelocity), rootAngularVelocity = vector(root.AssemblyAngularVelocity),
    colliderCFrame = {collider.CFrame:GetComponents()}, colliderVelocity = vector(collider.AssemblyLinearVelocity),
    jump = humanoid.Jump, state = tostring(humanoid:GetState()), floor = tostring(humanoid.FloorMaterial),
    moveDirection = vector(humanoid.MoveDirection), support = support and support:GetFullName(),
    supportPosition = hit and vector(hit.Position), supportNormal = hit and vector(hit.Normal),
    edgeDistance005 = edgeDistance(part005, root.Position, outgoing005), rootIn006 = vector(in006),
    colliderCornersIn006 = corners, colliderBoundsIn006 = {minimum = vector(minimum), maximum = vector(maximum)},
    falls = progress(player).falls, recoveryUntil = character:GetAttribute("RecoveryUntil")}
   local supportId = 0
   if support then
    if not supportIds[support] then table.insert(report.supports, support:GetFullName()); supportIds[support] = #report.supports end
    supportId = supportIds[support]
   end
   table.insert(report.frames, {rounded(seconds, 5), rounded(sample.serverTime), stage, rounded(dt, 6), currentAttempt.index,
    compactFrame(root.CFrame), compactVector(root.AssemblyLinearVelocity), compactVector(root.AssemblyAngularVelocity),
    compactFrame(collider.CFrame), compactVector(collider.AssemblyLinearVelocity), humanoid.Jump, humanoid:GetState().Name,
    humanoid.FloorMaterial.Name, compactVector(humanoid.MoveDirection), supportId, hit and compactVector(hit.Position) or false,
    hit and compactVector(hit.Normal) or false, rounded(sample.edgeDistance005), compactVector(in006), corners,
    sample.falls, rounded(sample.recoveryUntil or 0)})
   local receipt = {frame = #report.frames, seconds = seconds, stage = stage, position = vector(root.Position),
    velocity = vector(root.AssemblyLinearVelocity), support = sample.support, floor = sample.floor, state = sample.state,
    edgeDistance005 = sample.edgeDistance005}
   if currentHop then
    if humanoid.Jump and not currentHop.firstJumpObserved then currentHop.firstJumpObserved = receipt end
    if root.AssemblyLinearVelocity.Y > .1 and not currentHop.firstPositiveY then currentHop.firstPositiveY = receipt end
    if root.AssemblyLinearVelocity.Y > 10 and not currentHop.firstUpwardImpulse then currentHop.firstUpwardImpulse = receipt end
    if humanoid.FloorMaterial == Enum.Material.Air and not currentHop.firstAir then currentHop.firstAir = receipt end
    if not currentHop.maximumRootY or root.Position.Y > currentHop.maximumRootY then
     currentHop.maximumRootY, currentHop.maximumYFrame = root.Position.Y, #report.frames
    end
   end
   local stable006 = support == part006 and humanoid.FloorMaterial ~= Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y) < 2
   if support == part006 and not currentAttempt.first006Support then currentAttempt.first006Support = receipt end
   if stable006 then
    currentAttempt.stable006Since = currentAttempt.stable006Since or seconds
    currentAttempt.maximum006StableSeconds = math.max(currentAttempt.maximum006StableSeconds or 0, seconds - currentAttempt.stable006Since)
    if seconds - currentAttempt.stable006Since >= .12 and not currentAttempt.first006Stable012 then currentAttempt.first006Stable012 = receipt end
   else currentAttempt.stable006Since = nil end
   if sample.falls ~= baseline.falls and not report.firstRecovery then report.firstRecovery = receipt end
   if #report.frames % 120 == 0 then stored:SetAttribute("Frames", #report.frames) end
  end, debug.traceback)
  if not ok then observerFailure = observerFailure or reason end
 end
 stored:SetAttribute("State", "Running")
 stored.Value = Http:JSONEncode({state = "Running", expectedCandidate = expectedCandidate, ownerApproval = false})
 local ok, failure = xpcall(function()
  assert(typeof(requested) == "number" and requested % 1 == 0 and requested >= 1 and requested <= MAXIMUM_REPEATS,
   "repeats must be an integer from1to8")
  local actualPlayers = Players:GetPlayers()
  assert(#actualPlayers == 1, "Return probe requires exactly one actual Player")
  player = actualPlayers[1]
  character = assert(player.Character, "Actual character missing")
  humanoid, root = assert(character:FindFirstChildOfClass("Humanoid")), assert(character:FindFirstChild("HumanoidRootPart"))
  collider = assert(character:FindFirstChild("CollisionPart"), "Actual fitted collider missing")
  course, raceId = assert(services.CourseService.GetActiveCourse()), services.RaceService.GetCurrentRaceId()
  assert(course:GetAttribute("CourseId") == "egg_rush_circuit" and course:GetAttribute("CandidateId") == expectedCandidate
   and course:GetAttribute("Phase") == 2 and course:GetAttribute("EROwned") == true and course.CourseInfo:GetAttribute("Enabled") == true,
   "Expected enabled owned Phase2 candidate")
  baseline, originalCollider = progress(player), collider.Size
  report.raceId, report.userId, report.initialResult = raceId, player.UserId, baseline
  report.initialRoot, report.initialCollider, report.initialRecoveryUntil = pose(root), pose(collider), character:GetAttribute("RecoveryUntil")
  guard()
  local immunityBegan = os.clock()
  while (character:GetAttribute("RecoveryUntil") or 0) > Workspace:GetServerTimeNow() do
   guard(); RunService.Heartbeat:Wait()
  end
  report.initialImmunityWaitSeconds = os.clock() - immunityBegan
  recoveryUntil = character:GetAttribute("RecoveryUntil") or 0
  local group = course.Obstacles.S6_ShellSpill
  local points = {}
  for index = 4, 7 do table.insert(points, {part = assert(group:FindFirstChild(string.format("S6_ShellSpill_%03d", index)))}) end
  part005, part006 = points[2].part, points[3].part
  local delta = part006.Position - part005.Position
  outgoing005 = Vector3.new(delta.X, 0, delta.Z).Unit
  ray = RaycastParams.new(); ray.FilterType = Enum.RaycastFilterType.Include; ray.FilterDescendantsInstances = {course}; ray.RespectCanCollide = true
  report.geometry = {}
  for _, point in points do table.insert(report.geometry, pose(point.part)) end
  report.movement = {walkSpeed = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight, useJumpPower = humanoid.UseJumpPower,
   gravity = Workspace.Gravity, hipHeight = humanoid.HipHeight, maxSlopeAngle = humanoid.MaxSlopeAngle, rootSize = vector(root.Size), colliderSize = vector(collider.Size)}
  originalOwner, originalAuto = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto(); ownershipSaved = true
  table.insert(connections, RunService.PreSimulation:Connect(function(dt) observe("PreSimulation", dt) end))
  table.insert(connections, RunService.PostSimulation:Connect(function(dt) observe("PostSimulation", dt) end))
  for index = 1, requested do
   guard()
   local startPart = points[1].part
   local intended = startPart.Position + startPart.CFrame.UpVector * startPart.Size.Y / 2 + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + .15, 0)
   currentAttempt = {index = index, before = progress(player), beganSeconds = os.clock() - began, firstFrame = #report.frames + 1, hops = {}, endpoints = {}}
   table.insert(report.attempts, currentAttempt)
   table.insert(report.placements, {attempt = index, kind = "CanonicalInitialPlacement", part = startPart:GetFullName(),
    intendedCFrame = {CFrame.new(intended):GetComponents()}, priorRoot = pose(root), driverOption = "placeAtStart=true", returnPlacement = false})
   currentHop = nil
   stored:SetAttribute("Attempt", index)
   currentAttempt.driver = traversal.Run(course, player, points, {placeAtStart = true, pace = false, guard = guard,
    afterLanding = function(_, point)
     local support = standing()
     table.insert(currentAttempt.endpoints, {part = point.part.Name, seconds = os.clock() - began, root = pose(root), collider = pose(collider),
      floor = tostring(humanoid.FloorMaterial), support = support and support:GetFullName(), result = progress(player)})
    end}, function(hop, total, step)
    guard()
    currentHop = {index = hop, step = step, beganSeconds = os.clock() - began, firstFrame = #report.frames + 1, root = pose(root)}
    table.insert(currentAttempt.hops, currentHop)
    report.lastProgress = {attempt = index, hop = hop, totalHops = total - 1, step = step}
    stored:SetAttribute("Progress", Http:JSONEncode(report.lastProgress))
   end)
   currentAttempt.after, currentAttempt.lastFrame = progress(player), #report.frames
   currentAttempt.seconds = os.clock() - began - currentAttempt.beganSeconds
   currentAttempt.progressUnchanged, currentAttempt.progressFailure = sameProgress(currentAttempt.before, currentAttempt.after)
   currentAttempt.fallsDelta = currentAttempt.after.falls - currentAttempt.before.falls
   assert(currentAttempt.driver.ok, currentAttempt.driver.failure)
   assert(currentAttempt.driver.pace == false and currentAttempt.driver.jumps == 3, "Canonical prefix/pace contract mismatch")
   assert(currentAttempt.progressUnchanged, currentAttempt.progressFailure)
   guard()
   currentAttempt.ok = true
   currentAttempt, currentHop = nil, nil
  end
  report.complete = #report.attempts == requested
 end, debug.traceback)
 for _, connection in connections do connection:Disconnect() end
 if humanoid and humanoid.Parent then humanoid:Move(Vector3.zero, false); humanoid.Jump = false end
 if root and root.Parent and ownershipSaved then
  local restored, reason = pcall(function() if originalAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(originalOwner) end end)
  report.ownershipRestored, report.ownershipRestoreFailure = restored, if restored then nil else tostring(reason)
 end
 if player and services.ResultsService.GetPlayerResult(player) then
  report.lastResult = progress(player)
  if baseline then
   report.progressUnchanged, report.progressFailure = sameProgress(baseline, report.lastResult)
   report.fallsDuringRun = report.lastResult.falls - baseline.falls
  end
 end
 if currentAttempt then
  currentAttempt.after, currentAttempt.lastFrame = report.lastResult, #report.frames
  currentAttempt.ok, currentAttempt.failure = false, failure or observerFailure
 end
 report.ok = ok and not observerFailure and report.ownershipRestored == true and report.progressUnchanged == true
 report.failure = if not ok then tostring(failure) else observerFailure or report.ownershipRestoreFailure or report.progressFailure
 report.observerFailure, report.seconds = observerFailure, os.clock() - began
 report.cleanup = "All passive observers and canonical movement disconnected; Humanoid movement stopped; original network ownership restored; no return placement"
 stored:SetAttribute("Frames", #report.frames)
 local saved, saveFailure = pcall(publish, report)
 if not saved then stored:SetAttribute("PublicationFailure", tostring(saveFailure)); warn("[ReturnProbe] publication failed: " .. tostring(saveFailure)) end
 stored:SetAttribute("State", if report.ok and saved then "Complete" else "Failed")
end
stored.Value = Http:JSONEncode({state = "Ready", command = {action = "Run", repeats = 6}, expectedCandidate = expectedCandidate,
 canonicalDriver = traversalModule:GetFullName(), maximumSeconds = MAXIMUM_SECONDS, maximumFrames = MAXIMUM_FRAMES,
 placeAtStart = true, pace = false, ownerApproval = false,
 setup = "One actual official Racing Player; script declares one canonical placement at004 per attempt; no prepare/restart/preset/progression writes"})
local used = false
stored:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end
 local parsed, command = pcall(function() return Http:JSONDecode(stored:GetAttribute("Command")) end)
 if not parsed or typeof(command) ~= "table" or command.action ~= "Run" then return end
 used = true
 task.spawn(function() run(command) end)
end)
