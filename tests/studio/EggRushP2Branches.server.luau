--!nonstrict
local RunService, Players = game:GetService("RunService"), game:GetService("Players")
local Storage, Workspace, Http = game:GetService("ServerStorage"), game:GetService("Workspace"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819, "Owned native Studio server only")
local reportName = script:GetAttribute("ReportName") or "EggRushP2BranchesReport"
assert(typeof(reportName) == "string" and #reportName > 0 and #reportName <= 80 and reportName:match("^[%w_%-]+$"), "ReportName must be a simple nonempty name")
assert(not Storage:FindFirstChild(reportName), "Preserve the previous paired branch receipt; choose a fresh ReportName")
local stored = Instance.new("StringValue")
stored.Name, stored.Parent = reportName, Storage
stored:SetAttribute("State", "Ready")
local services = {}
for _, name in {"CourseService", "RaceService", "PlayerRaceService", "ResultsService", "CheckpointService", "EggRushService"} do
 services[name] = require(game.ServerScriptService.Services[name])
end
local traversalName = script:GetAttribute("TraversalModule") or "NativeTraversal"
assert(typeof(traversalName) == "string" and traversalName:match("^[%w_%-]+$"), "TraversalModule must name one EggRush ModuleScript sibling")
local traversalModule = assert(Storage.CourseBuilders.EggRush:FindFirstChild(traversalName), "Selected traversal ModuleScript is missing")
assert(traversalModule:IsA("ModuleScript"), "Selected traversal must be an actual ModuleScript")
local traversal = require(traversalModule)
local CANDIDATE, MAXIMUM_SECONDS = script:GetAttribute("ExpectedCandidate") or "ER_P2_R01_C03", 240
local function lineSide(line) return if line == "Normal" then -1 else 1 end
local function vector(v) return {v.X, v.Y, v.Z} end
local function pose(p) return {path = p:GetFullName(), size = vector(p.Size), frame = {p.CFrame:GetComponents()},
 canCollide = p.CanCollide, collisionGroup = p.CollisionGroup} end
local function result(player)
 local r = assert(services.ResultsService.GetPlayerResult(player), "Missing actual official result")
 return {status = r.status, lap = r.currentLap, nextCheckpoint = r.nextCheckpointIndex, falls = r.falls or 0,
  lapTimes = table.clone(r.lapTimes or {}), splitCount = #(r.checkpointSplits or {}),
  latestCheckpoint = services.CheckpointService.GetLatestCheckpointIndex(player)}
end
local publication = 0
local function publish(report)
 local encoded, names, offset = Http:JSONEncode(report), {}, 1
 publication += 1
 local folder = Instance.new("Folder"); folder.Name = string.format("Payload_%03d", publication)
 while offset <= #encoded do
  local last = math.min(offset + 149999, #encoded)
  while last < #encoded do local b = string.byte(encoded, last + 1); if b < 128 or b > 191 then break end; last -= 1 end
  local chunk = Instance.new("StringValue"); chunk.Name = string.format("Chunk_%03d", #names + 1)
  chunk.Value, chunk.Parent = string.sub(encoded, offset, last), folder
  table.insert(names, chunk.Name); offset = last + 1
 end
 folder.Parent = stored
 stored.Value = Http:JSONEncode({format = "EggRushP2BranchesChunksV1", payloadFolder = folder.Name, chunks = names,
  jsonBytes = #encoded, ok = report.ok, complete = report.complete, traversals = report.traversalsCompleted, ownerApproval = false})
end

local used = false
local function run(command)
 local began = os.clock()
 local report = {phase = 2, candidateId = CANDIDATE, ownerApproval = false, pace = true,
  ok = false, complete = false, maximumWallSeconds = MAXIMUM_SECONDS, pairedTrialsRequired = 0, traversalsRequired = 0,
  selectedBranches = {}, excludedBranches = {}, reportName = reportName,
  traversalsCompleted = 0, placements = {}, trials = {}, comparisons = {}, actors = {}, warnings = {},
  checkpointWrites = 0, profileWrites = 0, colliderWrites = 0, clockWrites = 0, hazardResets = 0,
  method = "Two actual official racers, identical common endpoints, matched practiced controls and line-side aim policy, simultaneous releases and one role swap per selected branch",
  steeringPolicy = {fixedActorSide = false, fixedLineSide = true, normalSide = -1, expertSide = 1,
   ordinaryPartOffset = 2, ordinaryPartAxis = "Part local RightVector",
   shellForkExitOffset = 2.4, shellForkExitAxis = "World Z", footprintInset = .75,
   specialParts = {"ShellContact", "Shell_ForkWait", "Shell_ExitWait"},
   balance = "Normal remains on the negative side and Expert on the positive side; actors swap lines and sides together",
   control = "NativeTraversal options.aim only; ordinary movement toward actual in-footprint points, no teleport or physics/profile change"},
  limits = {
   "Each selected branch uses four declared initial placements across its two paired trials; this does not prove ordinary entry, continuous laps or checkpoint order",
   "E1 measures Start through CP1, including the common Start to first Nestyard hop; it is not an exact timing comparison with the source audit's first-pad-only endpoints",
   "No favorable-only average: every requested trial, failed traversal, recovery and setup failure remains in the receipt",
   "Measured movement is the sum of completed native hop seconds; admission is native windowWaitSeconds; failed incomplete time remains separately unclassified",
   "A completed actor walks sideways on the same endpoint only after its native controller returns, to reduce interference with the other arrival; this walk is outside measured segment time",
   "Ordinary two-racer scripted timing is not human, twenty-player, device, FPS, minimum-time or owner acceptance proof",
   "Canonical NativeTraversal clears velocity and returns ownership to Auto in final controller cleanup; no in-hop pose or velocity writes are added",
   "Matched side steering is a new finite control comparison; it does not establish that the retained CP1-to-first-egg-pad miss was fixed",
   "An optional requested E3 release phase tests a conditional shared-window choice; it cannot establish a universal Crown time reward",
  }}
 local actors, course, raceId, holder = {}, nil, nil, nil
 local fatal, activePair, deadline = nil, nil, began + MAXIMUM_SECONDS - 2.5
 local ray = RaycastParams.new(); ray.FilterType = Enum.RaycastFilterType.Include; ray.RespectCanCollide = true
 local function clock() return services.EggRushService.GetDiagnostics().elapsed end
 local function support(a)
  local hit = Workspace:Raycast(a.root.Position, Vector3.new(0, -(a.humanoid.HipHeight + a.root.Size.Y / 2 + .7), 0), ray)
  return hit and hit.Instance
 end
 local function supported(a, pad)
  return support(a) == pad and a.humanoid.FloorMaterial ~= Enum.Material.Air
 end
 local function actorSnapshot(a)
  local p = support(a)
  return {clock = clock(), wallSeconds = os.clock() - began, root = pose(a.root), support = p and p:GetFullName(),
   floor = a.humanoid.FloorMaterial.Name, velocity = vector(a.root.AssemblyLinearVelocity), result = result(a.player),
   recoveryUntil = a.character:GetAttribute("RecoveryUntil") or 0}
 end
 local function guard(a, baselineFalls)
  assert(not fatal, fatal)
  assert(os.clock() < deadline, "Paired test reached its total wall-time budget")
  assert(services.CourseService.GetActiveCourse() == course and services.RaceService.GetCurrentRaceId() == raceId
   and services.RaceService.IsRaceActive(), "Actual course/race changed or ended")
  assert(course:GetAttribute("CandidateId") == CANDIDATE and course:GetAttribute("Phase") == 2
   and course:GetAttribute("FullBodyContacts") == true and services.EggRushService.GetDiagnostics().bound == true,
   "Actual expected-candidate full-body runtime changed")
  assert(a.player.Parent == Players and a.player.Character == a.character and a.humanoid.Health > 0 and a.root.Parent,
   "Actual character changed, left or died")
  assert(services.PlayerRaceService.IsOfficialRacer(a.player) and services.PlayerRaceService.GetPlayerStatus(a.player) == "Racing",
   "Actor is no longer an actual official Racing player")
  assert(not a.root.Anchored and a.humanoid.WalkSpeed == 16 and not a.humanoid.UseJumpPower
   and math.abs(a.humanoid.JumpHeight - 7.2) < .01 and math.abs(Workspace.Gravity - 196.2) < .01,
   "Ordinary 16/7.2 movement profile changed")
  assert(a.collider.Parent and a.collider.CanCollide and (a.collider.Size - a.colliderSize).Magnitude < .02,
   "Accepted full-body physics collider changed")
  local relative = a.root.CFrame:ToObjectSpace(a.collider.CFrame)
  local delta = a.colliderRelative:ToObjectSpace(relative); local _, angle = delta:ToAxisAngle()
  assert(delta.Position.Magnitude < .02 and math.abs(angle) < .002, "Accepted collider attachment changed")
  if baselineFalls then assert(result(a.player).falls == baselineFalls, "Actual service recovery occurred during the measured segment") end
  return true
 end
 local function allGuard() for _, a in actors do guard(a) end end
 local function waitFor(predicate, seconds, message)
  local limit = math.min(deadline, os.clock() + seconds)
  repeat allGuard(); if predicate() then return end; RunService.Heartbeat:Wait() until os.clock() >= limit
  error(message)
 end
 local function phase()
  local out = {clock = clock(), wallSeconds = os.clock() - began, mechanisms = {}}
  for _, m in course.Obstacles.Mechanisms:GetChildren() do
   if m:IsA("Model") and m:GetAttribute("ERMechanism") then
    out.mechanisms[m.Name] = {state = m:GetAttribute("ERState"), phaseSeconds = m:GetAttribute("PhaseSeconds")}
   end
  end
  return out
 end
 local function shellRemaining(model)
  local closed, warning, move = model:GetAttribute("ClosedSeconds"), model:GetAttribute("WarningSeconds"), model:GetAttribute("MoveSeconds")
  local open, closing = model:GetAttribute("OpenSeconds"), model:GetAttribute("ClosingWarningSeconds")
  local t = (clock() + (model:GetAttribute("PhaseSeconds") or 0)) % (closed + warning + move + open + closing + move)
  local starts = closed + warning + move
  return if t >= starts and t < starts + open + closing then starts + open + closing - t else 0
 end
 local function slice(full, first, last)
  local startIndex, endIndex
  for i, point in full do
   if point.part == first then assert(not startIndex, "Duplicate branch start"); startIndex = i end
   if startIndex and point.part == last then endIndex = i; break end
  end
  assert(startIndex and endIndex and endIndex > startIndex, "Common endpoints missing from the full canonical route")
  local out = {}
  for i = startIndex, endIndex do table.insert(out, table.clone(full[i])) end
  return out
 end
 local function pointReceipt(points)
  local out = {}
  for _, p in points do
   local eggs, exits = {}, {}
   for _, egg in p.eggs or {} do table.insert(eggs, {model = egg.model.Name, hops = egg.hops, low = egg.low, high = egg.high}) end
   for _, name in p.eggExit or {} do table.insert(exits, name) end
   table.insert(out, {part = p.part:GetFullName(), waitKind = p.waitKind, eggs = eggs, eggExit = exits})
  end
  return out
 end
 local function rootFrame(a, pad, nextPart, x)
  local p = pad.CFrame:PointToWorldSpace(Vector3.new(x, pad.Size.Y / 2, 0))
   + Vector3.yAxis * (a.humanoid.HipHeight + a.root.Size.Y / 2 + .15)
  local toward = (nextPart.Position - pad.Position) * Vector3.new(1, 0, 1)
  assert(toward.Magnitude > .01 and pad.CFrame.UpVector:Dot(Vector3.yAxis) > .9999, "Expected an actual horizontal fixed start support")
  return CFrame.lookAt(p, p + toward.Unit)
 end
 local function bounds(a, pad, frame)
  local low, high = Vector3.one * math.huge, -Vector3.one * math.huge
  local f = pad.CFrame:ToObjectSpace(frame * a.colliderRelative)
  for x = -1, 1, 2 do for y = -1, 1, 2 do for z = -1, 1, 2 do
   local p = f * (a.collider.Size * Vector3.new(x, y, z) / 2)
   low = Vector3.new(math.min(low.X, p.X), math.min(low.Y, p.Y), math.min(low.Z, p.Z))
   high = Vector3.new(math.max(high.X, p.X), math.max(high.Y, p.Y), math.max(high.Z, p.Z))
  end end end
  return low, high
 end
 local function initialPlacements(trial, def, lines)
  local pad, frames, box = def.first, {}, {}
  assert(pad.Anchored and pad.CanCollide and pad.CanQuery, "Shared fixed initial support must be actually collidable")
  local minOffset, maxOffset = 2.5, math.huge
  for i, a in actors do
   local low, high = bounds(a, pad, rootFrame(a, pad, def.points[lines[i]][2].part, 0))
   box[lines[i]] = {low = low, high = high}
   maxOffset = math.min(maxOffset, if lineSide(lines[i]) < 0 then pad.Size.X / 2 + low.X - .2 else pad.Size.X / 2 - high.X - .2)
   assert(low.Z >= -pad.Size.Z / 2 + .1 and high.Z <= pad.Size.Z / 2 - .1,
    "Actual fitted body does not fit safely in the shared initial pad depth; no fixture geometry change is allowed")
  end
  minOffset = math.max(minOffset, (box.Normal.high.X - box.Expert.low.X + .4) / 2)
  assert(minOffset <= maxOffset, "Two actual fitted actors cannot fit at separate initial side offsets")
  trial.initialOffset, trial.initialPad = minOffset, pose(pad)
  for i, a in actors do
   assert(not a.runActive and a.holdMode == "Hold", "Previous native controller has not returned and cleaned up")
   frames[i] = rootFrame(a, pad, def.points[lines[i]][2].part, lineSide(lines[i]) * minOffset)
   local low, high = bounds(a, pad, frames[i])
   local receipt = {trial = trial.id, actor = i, userId = a.player.UserId, line = lines[i], steeringSide = lineSide(lines[i]), kind = "InitialPairedSegmentPlacement",
    rootFrame = {frames[i]:GetComponents()}, colliderBoundsInPad = {low = vector(low), high = vector(high)}, phase = phase()}
   table.insert(report.placements, receipt)
   local pivot = frames[i] * a.root.CFrame:ToObjectSpace(a.character:GetPivot())
   a.character:PivotTo(pivot); a.root.AssemblyLinearVelocity = Vector3.zero; a.root.AssemblyAngularVelocity = Vector3.zero
   a.root:SetNetworkOwner(nil)
  end
  local stableSince
  waitFor(function()
   local stable = true
   for _, a in actors do stable = stable and supported(a, pad) and math.abs(a.root.AssemblyLinearVelocity.Y) < .1 end
   if stable then stableSince = stableSince or os.clock() else stableSince = nil end
   return stableSince and os.clock() - stableSince >= .25
  end, 3, "Both declared initial placements did not remain actually supported, nonAir and vertically stable for .25 seconds")
  trial.settled = {actorSnapshot(actors[1]), actorSnapshot(actors[2])}
 end
 local function readyForPair()
  allGuard()
  for _, a in actors do assert(not a.runActive, "Previous controller is still active"); a.holdMode = "Hold"; a.root:SetNetworkOwner(nil) end
  waitFor(function()
   for _, a in actors do
    if (a.character:GetAttribute("RecoveryUntil") or 0) + .65 > Workspace:GetServerTimeNow()
     or not support(a) or a.humanoid.FloorMaterial == Enum.Material.Air or math.abs(a.root.AssemblyLinearVelocity.Y) >= 2 then return false end
   end
   return true
  end, 5, "Previous actual fall/recovery did not settle and expire before the next declared trial")
 end
 local function compare(trials, branch)
  local comparison = {branch = branch, trials = {}, roleSwapComplete = #trials == 2, allClean = true,
   measuredStart = report.routes[branch].measuredStart, measuredEnd = report.routes[branch].measuredEnd,
   measurementNote = report.routes[branch].measurementNote}
  for _, trial in trials do
   local normal, expert
   for _, run in trial.runs or {} do if run.line == "Normal" then normal = run else expert = run end end
   local value = {trial = trial.id, clean = normal ~= nil and expert ~= nil and normal.clean == true and expert.clean == true
    and trial.actorColliderOverlapSamples == 0}
   comparison.allClean = comparison.allClean and value.clean
   if normal and expert then
    value.normalUserId, value.expertUserId = normal.userId, expert.userId
    value.normalSeconds, value.expertSeconds = normal.seconds, expert.seconds
    value.rawNormalMinusExpertSeconds = normal.seconds and expert.seconds and normal.seconds - expert.seconds or nil
    if value.clean then
     value.cleanExpertBenefitSeconds = normal.seconds - expert.seconds
     value.movementExpertBenefitSeconds = normal.movementSeconds - expert.movementSeconds
     value.admissionExpertBenefitSeconds = normal.admissionSeconds - expert.admissionSeconds
    end
   end
   table.insert(comparison.trials, value)
  end
  comparison.perActor = {}
  for _, a in actors do
   local affinity = {userId = a.player.UserId, runs = {}}
   for _, trial in trials do
    for _, run in trial.runs or {} do
     if run.userId == a.player.UserId then
      affinity.runs[run.line] = {trial = trial.id, clean = run.clean, seconds = run.seconds,
       movementSeconds = run.movementSeconds, admissionSeconds = run.admissionSeconds, fallsDelta = run.fallsDelta}
     end
    end
   end
   local normal, expert = affinity.runs.Normal, affinity.runs.Expert
   if normal and expert and normal.clean and expert.clean then affinity.sameActorExpertBenefitSeconds = normal.seconds - expert.seconds end
   table.insert(comparison.perActor, affinity)
  end
  comparison.affinity = "User ownership swaps once; inspect both signed paired benefits and both actual release phases; no favorable-only aggregate"
  if branch == "E3" then
   local useful = comparison.allClean and comparison.roleSwapComplete
   for _, value in comparison.trials do useful = useful and value.cleanExpertBenefitSeconds ~= nil and value.cleanExpertBenefitSeconds > 0 end
   comparison.crownUsefulRewardDemonstratedInBothTrials = useful
   if not useful then table.insert(report.warnings, "Crown did not demonstrate a clean positive time reward in both paired role trials; inspect admission phase, failures and movement separately") end
  end
  table.insert(report.comparisons, comparison)
 end

 local ok, failure = xpcall(function()
  local requested = command.branches or {"E1", "E2", "E3", "E4"}
  assert(typeof(requested) == "table" and #requested >= 1 and #requested <= 4, "branches must be a nonempty ordered array of E1..E4")
  local selected = {}
  for index, branch in requested do
   assert(typeof(index) == "number" and index % 1 == 0 and index >= 1 and index <= #requested
    and table.find({"E1", "E2", "E3", "E4"}, branch), "branches contains an invalid index or branch")
   assert(not selected[branch], "branches must not contain duplicates"); selected[branch] = true
  end
  for index = 1, #requested do assert(typeof(requested[index]) == "string", "branches must not contain gaps"); table.insert(report.selectedBranches, requested[index]) end
  for _, branch in {"E1", "E2", "E3", "E4"} do if not selected[branch] then table.insert(report.excludedBranches, branch) end end
  local crownPhase = command.CrownReleasePhase
  assert(crownPhase == nil or (typeof(crownPhase) == "number" and crownPhase >= 0 and crownPhase < 14.8), "CrownReleasePhase must be a number in [0,14.8)")
  assert(crownPhase == nil or selected.E3, "CrownReleasePhase requires selected branch E3")
  report.requestedCrownReleasePhase, report.crownReleaseTolerance = crownPhase, if crownPhase ~= nil then .15 else nil
  report.pairedTrialsRequired, report.traversalsRequired = #requested * 2, #requested * 4
  local args, tag = game:GetService("StudioTestService"):GetTestArgs(), script:GetAttribute("OwnedStudioTestTag")
  assert(typeof(tag) == "string" and #tag > 0 and typeof(args) == "table" and args.tag == tag, "Exact owned StudioTestService tag required")
  assert(typeof(CANDIDATE) == "string" and #CANDIDATE > 0, "ExpectedCandidate must be a nonempty exact candidate id")
  course = assert(services.CourseService.GetActiveCourse(), "Prepare the actual official expected-candidate race first")
  assert(course:GetAttribute("CourseId") == "egg_rush_circuit" and course:GetAttribute("EROwned") == true
   and course:GetAttribute("CandidateId") == CANDIDATE and course:GetAttribute("Phase") == 2
   and course:GetAttribute("FullBodyContacts") == true, "Expected actual owned Phase2 FullBody course with the exact expected candidate id")
  raceId = services.RaceService.GetCurrentRaceId()
  assert(typeof(raceId) == "string" and raceId ~= "" and services.EggRushService.GetDiagnostics().raceId == raceId, "Actual bound race id required")
  local list = Players:GetPlayers(); assert(#list == 2, "Exactly two actual Players required")
  table.sort(list, function(a, b) return a.UserId < b.UserId end)
  ray.FilterDescendantsInstances = {course}
  for i, player in list do
   local character = assert(player.Character)
   local a = {player = player, character = character, root = assert(character:FindFirstChild("HumanoidRootPart")),
    humanoid = assert(character:FindFirstChildOfClass("Humanoid")), collider = assert(character:FindFirstChild("CollisionPart")),
    runActive = false, holdMode = "Hold"}
   a.colliderSize, a.colliderRelative = a.collider.Size, a.root.CFrame:ToObjectSpace(a.collider.CFrame)
   a.owner, a.ownershipAuto = a.root:GetNetworkOwner(), a.root:GetNetworkOwnershipAuto()
   table.insert(actors, a); guard(a); a.root:SetNetworkOwner(nil)
   report.actors[i] = {userId = player.UserId, initial = actorSnapshot(a), collider = pose(a.collider),
    colliderRelativeFrame = {a.colliderRelative:GetComponents()}, originalOwnershipAuto = a.ownershipAuto,
    originalOwnerUserId = a.owner and a.owner.UserId}
  end
  report.ownedStudioTestTag, report.raceId, report.driverModule = tag, raceId, traversalModule:GetFullName()
  report.inspectionFixture = {selection = services.CourseService.IsInspectionMode(), unlimitedTime = services.RaceService.IsInspectionUnlimitedTime()}
  holder = RunService.PreSimulation:Connect(function()
   for _, a in actors do
    if not a.runActive and a.holdMode and a.player.Character == a.character and a.humanoid.Parent then
     local movement = Vector3.zero
     if a.holdMode == "ClearEnd" then
      local delta = (a.clearTarget - a.root.Position) * Vector3.new(1, 0, 1)
      if delta.Magnitude > .45 then movement = delta.Unit end
     end
     a.humanoid:Move(movement, false); a.humanoid.Jump = false
    end
   end
  end)
  local normal, expert = traversal.Points(course, "Normal"), traversal.Points(course, "Expert")
  local o = course.Obstacles
  local available = {
   {name = "E1", first = course.Start, last = o.CP1_Pocket,
    note = "Both lines include Start -> S1_Nestyard_001. Practiced forward landing aim follows each line's next target; times do not reproduce the source audit's first-pad-only comparison."},
   {name = "E2", first = o.CP1_Pocket, last = o.CP2_Pocket},
   {name = "E3", first = o.Shell_ForkWait, last = o.Shell_ExitWait},
   {name = "E4", first = o.CP3_Pocket, last = o.Tail_SafeWait},
  }
  local definitions = {}
  for _, name in report.selectedBranches do
   for _, def in available do if def.name == name then table.insert(definitions, def); break end end
  end
  report.routes = {}
  for _, def in definitions do
   def.points = {Normal = slice(normal, def.first, def.last), Expert = slice(expert, def.first, def.last)}
   report.routes[def.name] = {Normal = pointReceipt(def.points.Normal), Expert = pointReceipt(def.points.Expert),
    measuredStart = def.first:GetFullName(), measuredEnd = def.last:GetFullName(), measurementNote = def.note}
  end
  if selected.E3 then
   report.shellCadence = {}
   for _, model in o.Mechanisms:GetChildren() do
    if model:GetAttribute("ERMechanism") == "ShellLip" then
     local c, w, m, open, close = model:GetAttribute("ClosedSeconds"), model:GetAttribute("WarningSeconds"), model:GetAttribute("MoveSeconds"),
      model:GetAttribute("OpenSeconds"), model:GetAttribute("ClosingWarningSeconds")
     local period = c + w + m + open + close + m
     if crownPhase ~= nil then assert(math.abs(period - 14.8) < .001, "Requested phase requires the actual shared 14.8-second shell cadence") end
     report.shellCadence[model.Name] = {period = period, phaseOffset = model:GetAttribute("PhaseSeconds") or 0,
      openAt = c + w + m, openThrough = c + w + m + open + close}
    end
   end
  end
  for _, def in definitions do
   local branchTrials = {}
   for swap = 1, 2 do
    local trial = {id = def.name .. "_Role" .. swap, branch = def.name, role = swap, runs = {}, ok = false,
     initialPlacementCount = 2, pace = true, startEndpoint = def.first:GetFullName(), endEndpoint = def.last:GetFullName(),
     measurementNote = def.note}
    table.insert(report.trials, trial); table.insert(branchTrials, trial)
    stored:SetAttribute("CurrentTrial", trial.id)
    local lines = if swap == 1 then {"Normal", "Expert"} else {"Expert", "Normal"}
    readyForPair()
    trial.beforeSetup = {actorSnapshot(actors[1]), actorSnapshot(actors[2])}
    initialPlacements(trial, def, lines)
    for i, a in actors do
     assert(result(a.player).falls == trial.beforeSetup[i].result.falls, "Actual recovery occurred during paired initial setup")
    end
    if def.name == "E3" and crownPhase ~= nil then
     trial.phaseRequest = {kind = "RequestedSharedGlobalShellPhase", target = crownPhase, tolerance = .15, period = 14.8,
      clockSource = "EggRushService.GetDiagnostics().elapsed modulo the actual shared shell period",
      before = phase(), reason = "Same conditional admission phase for both role trials; natural wait only, no clock or schedule writes"}
    elseif def.name == "E3" and swap == 2 then
     local model = o.Mechanisms.CrownLip1
     local first = branchTrials[1].crownRemainingAtRelease
     local wantAdmissible = not (first and first >= 4.8)
     trial.phaseRequest = {kind = if wantAdmissible then "CrownAdmissibleAtLeast4.8" else "CrownLateOpenLessThan4.8",
      reason = "Opposite Crown admission condition to the first role trial, reached only by the natural shared clock", before = phase()}
     local t = os.clock()
     waitFor(function()
      for _, a in actors do assert(supported(a, def.first), "Lost actual Fork support during natural phase alignment") end
      local remaining = shellRemaining(model)
      return if wantAdmissible then remaining >= 4.8 else remaining > .25 and remaining < 4.8
     end, 16, "Opposite natural Crown admission phase did not occur within one bounded wait")
     trial.phaseRequest.waitSeconds, trial.phaseRequest.after = os.clock() - t, phase()
    end
    trial.release, trial.crownRemainingAtRelease = phase(), shellRemaining(o.Mechanisms.CrownLip1)
    local release, done, actorContactFrames, supportSampleAt = false, 0, 0, 0
    local contactQuery = OverlapParams.new(); contactQuery.FilterType = Enum.RaycastFilterType.Include; contactQuery.RespectCanCollide = true
    contactQuery.FilterDescendantsInstances = {actors[2].collider}
    contactQuery.CollisionGroup = actors[1].collider.CollisionGroup
    trial.actorCollisionEnabled = game:GetService("PhysicsService"):CollisionGroupsAreCollidable(
     actors[1].collider.CollisionGroup, actors[2].collider.CollisionGroup)
    for i, a in actors do
     trial.runs[i] = {line = lines[i], userId = a.player.UserId, actor = i, before = actorSnapshot(a), supportTrace = {}, landings = {},
      steeringSide = lineSide(lines[i]), aimCalls = 0, aimTrace = {}, actualLandingAims = {}}
     a.runActive, a.holdMode = true, false
     task.spawn(function()
      local taskOk, taskFailure = xpcall(function()
      while not release do guard(a); RunService.Heartbeat:Wait() end
      local runReceipt = trial.runs[i]
      local baselineFalls = runReceipt.before.result.falls
      runReceipt.actualStartWall, runReceipt.actualStartClock = os.clock() - began, clock()
      if def.name == "E3" then runReceipt.actualStartGlobalShellPhase = runReceipt.actualStartClock % 14.8 end
      runReceipt.nativeInvoked = true
      local function matchedAim(part, nextPart, defaultAim)
       assert(typeof(defaultAim) == "Vector3" and part:IsA("BasePart") and part:IsDescendantOf(course), "Actual part and native default Vector3 aim required")
       local special = part.Name == "ShellContact" or part.Name == "Shell_ForkWait" or part.Name == "Shell_ExitWait"
       local offset = (if special then Vector3.zAxis * 2.4 else part.CFrame.RightVector * 2) * runReceipt.steeringSide
       local localAim = part.CFrame:PointToObjectSpace(defaultAim + offset)
       local xLimit, zLimit = part.Size.X / 2 - .75, part.Size.Z / 2 - .75
       assert(xLimit >= 0 and zLimit >= 0, "Actual target footprint is too small for the declared .75-stud inset")
       local clamped = Vector3.new(math.clamp(localAim.X, -xLimit, xLimit), localAim.Y, math.clamp(localAim.Z, -zLimit, zLimit))
       local chosen = part.CFrame:PointToWorldSpace(clamped)
       assert(math.abs(clamped.X) <= xLimit + .001 and math.abs(clamped.Z) <= zLimit + .001, "Chosen aim left the actual footprint")
       runReceipt.aimCalls += 1
       local index = assert(runReceipt.progress, "Native progress must identify the current hop before its aim hook").index
       local receipt = runReceipt.aimTrace[index]
       if not receipt then
        receipt = {hop = index, part = part:GetFullName(), nextPart = nextPart and nextPart:GetFullName(),
         axis = if special then "World Z" else "Part local RightVector", side = runReceipt.steeringSide, calls = 0, transitions = {}, droppedTransitions = 0}
        runReceipt.aimTrace[index] = receipt
       end
       local sample = {clock = clock(), defaultAim = vector(defaultAim), requestedOffset = vector(offset), chosenAim = vector(chosen),
        localAim = vector(clamped), wasClamped = (localAim - clamped).Magnitude > .001, partFrame = {part.CFrame:GetComponents()}}
       receipt.calls += 1; receipt.first = receipt.first or sample
       local previous = receipt.last
       if not previous or (Vector3.new(table.unpack(previous.chosenAim)) - chosen).Magnitude > .001 then
        if #receipt.transitions < 32 then table.insert(receipt.transitions, sample) else receipt.droppedTransitions += 1 end
       end
       receipt.last = sample
       return chosen
      end
      local returned, driver = xpcall(function()
       return traversal.Run(course, a.player, def.points[lines[i]], {placeAtStart = false, pace = true,
        aim = matchedAim,
        guard = function() return guard(a, baselineFalls) end,
        afterLanding = function(index, point)
         table.insert(runReceipt.landings, {index = index, wanted = point.part:GetFullName(), actual = actorSnapshot(a)})
        end}, function(index, total, step)
         runReceipt.progress = {index = index, total = total, step = step, clock = clock(), wallSeconds = os.clock() - began}
        end)
      end, debug.traceback)
      a.runActive = false; a.holdMode = "Hold"
      runReceipt.nativeReturned = returned
      if returned then
       runReceipt.driver, runReceipt.seconds = driver, driver.seconds
       assert(runReceipt.aimCalls > 0, "Selected traversal did not call options.aim; matched steering was not used and no center-control fallback is accepted")
       runReceipt.movementSeconds, runReceipt.admissionSeconds = 0, driver.windowWaitSeconds
       for index, hop in driver.records do
        runReceipt.movementSeconds += hop.seconds
        local trace = runReceipt.aimTrace[index]
        local exact = trace and trace.last and hop.landingAim
         and (Vector3.new(table.unpack(hop.landingAim)) - Vector3.new(table.unpack(trace.last.chosenAim))).Magnitude < .025
        table.insert(runReceipt.actualLandingAims, {from = hop.from, to = hop.to, nativeAim = hop.landingAim, matchesLastCallback = exact == true})
        assert(exact and trace.calls >= 2, "Completed native hop did not report the actual matched callback aim with repeated steering calls")
       end
       runReceipt.unclassifiedSeconds = driver.seconds - runReceipt.movementSeconds - runReceipt.admissionSeconds
       runReceipt.after = actorSnapshot(a); runReceipt.fallsDelta = runReceipt.after.result.falls - baselineFalls
       runReceipt.clean = driver.ok and driver.pace == true and driver.jumps == #def.points[lines[i]] - 1
        and runReceipt.fallsDelta == 0 and supported(a, def.last)
       runReceipt.guardedEncounters = {trace = driver.windowTrace, eggs = driver.eggCrossings, expectedShellLips = if def.name == "E3" then (if lines[i] == "Expert" then 5 else 4) else 0}
       if def.name == "E2" then
        for _, name in {"EggBand1", "EggBand2"} do
         local crossing = driver.eggCrossings[name]
         runReceipt.clean = runReceipt.clean and crossing ~= nil and crossing.crossed == true
        end
       end
       if def.name == "E3" then runReceipt.clean = runReceipt.clean and #driver.windowTrace == runReceipt.guardedEncounters.expectedShellLips end
       assert(#driver.trayCarries == 0, "Unexpected tray in a branch segment")
       if a.root.Parent then a.root:SetNetworkOwner(nil) end
       if driver.ok and supported(a, def.last) then
        local x = lineSide(lines[i]) * math.min(3, def.last.Size.X / 2 - 1.25)
        a.clearTarget = def.last.CFrame:PointToWorldSpace(Vector3.new(x, def.last.Size.Y / 2, 0))
        local clear = {kind = "PostMeasurementSamePadWalk", target = vector(a.clearTarget), before = actorSnapshot(a)}
        runReceipt.endClearance = clear; a.holdMode = "ClearEnd"
        local clearUntil = math.min(deadline, os.clock() + 1.5)
        repeat RunService.Heartbeat:Wait() until not supported(a, def.last)
         or ((a.clearTarget - a.root.Position) * Vector3.new(1, 0, 1)).Magnitude <= .45 or os.clock() >= clearUntil
        a.holdMode = "Hold"; clear.after = actorSnapshot(a)
        clear.supportedSamePad = supported(a, def.last)
        clear.reachedSide = ((a.clearTarget - a.root.Position) * Vector3.new(1, 0, 1)).Magnitude <= .45
       end
      else
       runReceipt.clean, runReceipt.failure = false, driver
       fatal = "NativeTraversal raised outside its normal returned receipt; controller cleanup cannot be independently confirmed: " .. tostring(driver)
      end
      end, debug.traceback)
      if not taskOk then
       trial.runs[i].clean, trial.runs[i].workerFailure = false, taskFailure
       fatal = fatal or "Paired worker failed; stop future trials: " .. tostring(taskFailure)
      end
      a.runActive, a.holdMode = false, "Hold"
      if trial.runs[i].nativeInvoked then report.traversalsCompleted += 1 end
      done += 1
     end)
    end
    activePair = trial
    RunService.Heartbeat:Wait()
    if def.name == "E3" and crownPhase ~= nil then
     local waiting = os.clock()
     waitFor(function()
      for _, a in actors do assert(supported(a, def.first), "Lost actual Fork support during requested natural release wait") end
      local difference = ((clock() % 14.8 - crownPhase + 7.4) % 14.8) - 7.4
      return math.abs(difference) <= .15
     end, 15.8, "Requested shared shell phase did not occur within one natural cycle")
     trial.phaseRequest.waitSeconds, trial.phaseRequest.after = os.clock() - waiting, phase()
    end
    trial.release = phase(); trial.crownRemainingAtRelease = shellRemaining(o.Mechanisms.CrownLip1)
    if def.name == "E3" then
     trial.releaseGlobalShellPhase = trial.release.clock % 14.8
     if crownPhase ~= nil then
      trial.phaseRequest.actualReleasePhase = trial.releaseGlobalShellPhase
      trial.phaseRequest.releasePhaseError = ((trial.releaseGlobalShellPhase - crownPhase + 7.4) % 14.8) - 7.4
     end
    end
    trial.releaseWallSeconds = os.clock() - began; release = true
    while done < 2 do
     RunService.Heartbeat:Wait()
     if os.clock() > deadline then fatal = fatal or "Total wall-time budget reached; stop both native controllers at their next guard" end
     if os.clock() - supportSampleAt >= .1 then
      supportSampleAt = os.clock()
      local touches = Workspace:GetPartsInPart(actors[1].collider, contactQuery)
      if #touches > 0 then
       actorContactFrames += 1
       trial.firstActorColliderOverlap = trial.firstActorColliderOverlap or {clock = clock(), actors = {pose(actors[1].collider), pose(actors[2].collider)}}
      end
      for i, a in actors do
       if a.runActive and #trial.runs[i].supportTrace < 650 then
        local actual = support(a)
        table.insert(trial.runs[i].supportTrace, {clock = clock(), support = actual and actual:GetFullName(),
         floor = a.humanoid.FloorMaterial.Name, position = vector(a.root.Position), falls = result(a.player).falls})
       end
      end
     end
    end
    activePair = nil
    trial.actorColliderOverlapSamples = actorContactFrames
    if trial.runs[1].actualStartWall and trial.runs[2].actualStartWall then
     trial.startSkewSeconds = math.abs(trial.runs[1].actualStartWall - trial.runs[2].actualStartWall)
    end
    trial.endPhase, trial.ok = phase(), true
    for i, a in actors do
     assert(not a.runActive and a.holdMode == "Hold", "Controller must return before any next pair")
     trial.runs[i].pairEnd = actorSnapshot(a)
     trial.runs[i].pairFallsDelta = trial.runs[i].pairEnd.result.falls - trial.runs[i].before.result.falls
     trial.runs[i].clean = trial.runs[i].clean and trial.runs[i].pairFallsDelta == 0
     trial.ok = trial.ok and trial.runs[i].clean
    end
    if actorContactFrames > 0 then
     trial.comparisonConfound = "Actual colliding fitted actor boxes overlapped; retain this paired result but do not call its time difference an isolated route benefit"
     table.insert(report.warnings, trial.id .. ": colliding fitted actor overlap observed")
    end
    publish(report)
    assert(not fatal, fatal)
   end
   compare(branchTrials, def.name)
  end
  report.complete = #report.trials == report.pairedTrialsRequired and report.traversalsCompleted == report.traversalsRequired
   and #report.placements == report.traversalsRequired
  report.ok = report.complete
  for _, trial in report.trials do report.ok = report.ok and trial.ok end
 end, debug.traceback)
 if not ok then
  fatal = fatal or "Outer paired test stopped; drain existing native controllers"
  local drainUntil = os.clock() + 2.3
  repeat
   local running = false
   for _, a in actors do running = running or a.runActive end
   if not running then break end
   RunService.Heartbeat:Wait()
  until os.clock() >= drainUntil
 end
 if holder then holder:Disconnect() end
 local cleanupErrors = {}
 for _, a in actors do
  local cleaned, why = pcall(function()
   assert(not a.runActive, "A native controller has not drained; no new placement or movement controller is started")
   if a.humanoid.Parent then a.humanoid:Move(Vector3.zero, false); a.humanoid.Jump = false end
   if a.root.Parent then if a.ownershipAuto then a.root:SetNetworkOwnershipAuto() else a.root:SetNetworkOwner(a.owner) end end
  end)
  if not cleaned then table.insert(cleanupErrors, tostring(why)) end
 end
 report.wallSeconds, report.failure, report.cleanupErrors = os.clock() - began, if ok then nil else failure, cleanupErrors
 report.ok = ok and report.ok and #cleanupErrors == 0
 report.finalPlacementWrites = 0
 report.cleanup = "Holder disconnected; all returned native controllers ended; ordinary movement stopped and original ownership restored where the original root remains. No final placement."
 for i, a in actors do
  local captured, value = pcall(actorSnapshot, a)
  if captured and report.actors[i] then report.actors[i].final = value end
 end
 if activePair then activePair.aborted = true end
 report.notRun = {}
 for _, branch in report.selectedBranches do
  for role = 1, 2 do
   local id, found = branch .. "_Role" .. role, false
   for _, trial in report.trials do if trial.id == id then found = true; break end end
   if not found then table.insert(report.notRun, {trial = id, reason = "Stopped before this paired trial; see the retained failure"}) end
  end
 end
 publish(report)
 stored:SetAttribute("State", if report.ok then "Complete" else "Failed")
 stored:SetAttribute("TraversalsCompleted", report.traversalsCompleted)
 print("ER_P2_BRANCHES", report.ok, report.complete, report.traversalsCompleted, report.wallSeconds, report.failure or "")
end
stored.Value = Http:JSONEncode({state = "Ready", action = "Run", requiredScriptAttribute = "OwnedStudioTestTag", candidateId = CANDIDATE,
 optionalScriptAttributes = {ExpectedCandidate = "ER_P2_R01_C03", TraversalModule = "NativeTraversal (EggRush ModuleScript sibling name)",
  ReportName = "EggRushP2BranchesReport"}, driverModule = traversalModule:GetFullName(), reportName = reportName,
 optionalCommandBranches = {"E1", "E2", "E3", "E4"}, E1Endpoints = "Start -> CP1_Pocket",
 optionalCrownReleasePhase = "Number [0,14.8), E3 only; both roles wait for natural runtime phase within .15 seconds of target",
 actualPlayers = 2, pairedTrials = 8, traversals = 16, pace = true, maximumWallSeconds = MAXIMUM_SECONDS, ownerApproval = false})
stored:GetAttributeChangedSignal("Command"):Connect(function()
 local raw = stored:GetAttribute("Command")
 if typeof(raw) ~= "string" or raw == "" or used then return end
 used = true; stored:SetAttribute("Command", ""); stored:SetAttribute("State", "Running")
 task.spawn(function()
  local valid, command = pcall(Http.JSONDecode, Http, raw)
  if not valid or typeof(command) ~= "table" or command.action ~= "Run" then
   stored.Value = Http:JSONEncode({ok = false, failure = "Single-use command must be {action=Run}"})
   stored:SetAttribute("State", "Failed"); return
  end
  run(command)
 end)
end)
