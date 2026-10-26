--!nonstrict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

assert(RunService:IsStudio() and RunService:IsServer(), "Native Studio server probe only")
assert(not ServerStorage:FindFirstChild("R01ClosedClimbFeetReport"), "A closed-climb report already exists")
local stored = Instance.new("StringValue")
stored.Name = "R01ClosedClimbFeetReport"
stored:SetAttribute("State", "Preparing")
stored.Parent = ServerStorage

local report = {
 candidateId = "ER_P1_R01", sampleRevision = 2, cases = {}, placements = {},
 fixtureOffset = {0, 0, 400}, ownerApproval = false,
 method = "Three bounded real-avatar attempts in static clones of two actual fully closed Crown shells and the fork",
 limits = {
  "Favorable isolated geometry probe; no actual-cycle timing, complete bypass or human-control proof",
  "One initial fork placement per case, at most one jump press per target, no movement-time position or velocity writes",
  "A failed centered or edge attempt does not exclude other launches, arcs, rigs or closed routes",
  "Fixture keeps the actual captured collision geometry; original race and mechanism clock continue unchanged",
 },
}
local character, humanoid, root, course, raceService, raceId
local control, movement, jumpHeld = nil, Vector3.zero, false
local ownershipSaved, originalOwner, originalAuto = false, nil, nil
local completedCases = false

local function vector(value) return {value.X, value.Y, value.Z} end
local function progress(caseName, stage, state)
 stored:SetAttribute("Progress", Http:JSONEncode({case = caseName, stage = stage, state = state}))
end
local function guard()
 assert(character and Players:GetPlayers()[1] and Players:GetPlayers()[1].Character == character
  and root and root.Parent and humanoid and humanoid.Health > 0, "ContextChanged: character changed or died")
 assert(raceService.IsRaceActive() and raceService.GetCurrentRaceId() == raceId,
  "ContextChanged: original inspection race changed")
end

local ok, failure = xpcall(function()
 local courseService = require(game.ServerScriptService.Services.CourseService)
 raceService = require(game.ServerScriptService.Services.RaceService)
 local eggService = require(game.ServerScriptService.Services.EggRushService)
 course = assert(courseService.GetActiveCourse(), "No active course")
 assert(course:GetAttribute("CandidateId") == "ER_P1_R01" and course:GetAttribute("Phase") == 1
  and course:GetAttribute("SampleRevision") == 2, "Wrong R01 Phase 1 sample revision")
 assert(raceService.IsRaceActive() and eggService.GetDiagnostics().bound == true, "Prepare the native inspection race first")
 raceId = raceService.GetCurrentRaceId()
 local player = assert(Players:GetPlayers()[1], "No first test player")
 character = assert(player.Character)
 humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
 root = assert(character:FindFirstChild("HumanoidRootPart"))
 assert(not root.Anchored and humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower
  and math.abs(humanoid.JumpHeight - 7.2) < .01 and math.abs(humanoid.MaxSlopeAngle - 89) < .01
  and math.abs(Workspace.Gravity - 196.2) < .01, "Unexpected actual avatar movement profile")
 report.raceId, report.userId = raceId, player.UserId
 report.movement = {walk = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight,
  useJumpPower = humanoid.UseJumpPower, maxSlopeAngle = humanoid.MaxSlopeAngle, gravity = Workspace.Gravity}

 local first = assert(course.Obstacles.Mechanisms:FindFirstChild("CrownLip1"))
 local second = assert(course.Obstacles.Mechanisms:FindFirstChild("CrownLip2"))
 local expectedUp = math.cos(math.rad(82))
 local function fullyClosed(model)
  return model:GetAttribute("ERState") == "Closed"
   and math.abs(model.ShellContact.CFrame.UpVector.Y - expectedUp) < .001
 end
 stored:SetAttribute("State", "WaitingForClosed")
 local untilClosed = os.clock() + 20
 repeat
  guard()
  if fullyClosed(first) and fullyClosed(second) then break end
  RunService.Heartbeat:Wait()
 until os.clock() >= untilClosed
 assert(fullyClosed(first) and fullyClosed(second), "No simultaneous fully closed capture within twenty seconds")
 assert(not Workspace:FindFirstChild("ER_R01_ClosedClimbFeetFixture"), "Keep the existing closed-climb fixture for inspection")

 local offset = Vector3.new(0, 0, 400)
 local fixture = Instance.new("Model")
 fixture.Name = "ER_R01_ClosedClimbFeetFixture"
 fixture:SetAttribute("Purpose", "Static captured closed geometry; no course registration")
 local forkGroup = Instance.new("Folder")
 forkGroup.Name, forkGroup.Parent = "Fork", fixture
 local forkSource = assert(course.Obstacles:FindFirstChild("Shell_ForkWait"))
 local fork
 local forkCount = 0
 for _, source in course.Obstacles:GetChildren() do
  if not source:IsA("BasePart") or not (source == forkSource or source.Name:match("^Shell_ForkWait_Shoulder")) then continue end
  local copy = source:Clone()
  copy.CFrame += offset
  copy.Parent = forkGroup
  forkCount += 1
  if source == forkSource then fork = copy end
 end
 assert(fork and forkCount == 3, "Capture the fork main contact and its two actual shoulders")
 local captured = {}
 for _, source in {first, second} do
  local copy = source:Clone()
  copy:PivotTo(source:GetPivot() + offset)
  copy.Parent = fixture
  table.insert(captured, copy)
 end
 fixture.Parent = Workspace
 report.capture = {sourceState = "Closed", originalClock = eggService.GetDiagnostics().elapsed,
  firstUpY = first.ShellContact.CFrame.UpVector.Y, secondUpY = second.ShellContact.CFrame.UpVector.Y,
  collisionChanges = false, forkParts = forkCount, fixture = fixture:GetFullName()}
 local crown1, crown2 = captured[1], captured[2]

 local legOffset = humanoid.HipHeight + root.Size.Y / 2
 local footNames = {LeftFoot = true, RightFoot = true, ["Left Leg"] = true, ["Right Leg"] = true}
 local measuredFeet = {}
 for _, part in character:GetDescendants() do
  if not part:IsA("BasePart") or not footNames[part.Name] then continue end
  local cf, size = part.CFrame, part.Size
  local extent = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
  local distance = root.Position.Y - (part.Position.Y - extent)
  legOffset = math.max(legOffset, distance)
  table.insert(measuredFeet, {part = part.Name, rootToBottom = distance})
 end
 assert(legOffset >= 1 and legOffset <= 8 and #measuredFeet > 0, "Cannot establish the actual rig's leg reach")
 local rayLength = legOffset + .7
 report.rig = {name = character.Name, type = humanoid.RigType.Name, hipHeight = humanoid.HipHeight,
  rootSize = vector(root.Size), footMeasurements = measuredFeet, measuredLegOffset = legOffset, rayLength = rayLength}
 local rayParams = RaycastParams.new()
 rayParams.FilterType, rayParams.FilterDescendantsInstances, rayParams.RespectCanCollide = Enum.RaycastFilterType.Include, {fixture}, true
 local overlapParams = OverlapParams.new()
 overlapParams.FilterType, overlapParams.FilterDescendantsInstances, overlapParams.RespectCanCollide = Enum.RaycastFilterType.Include, {fixture}, true
 overlapParams.MaxParts = 24
 local bodyParts = {}
 for _, name in {"Head", "Torso", "UpperTorso", "LowerTorso"} do
  local part = character:FindFirstChild(name)
  if part and part:IsA("BasePart") then table.insert(bodyParts, part) end
 end
 local function standing()
  local hit = Workspace:Raycast(root.Position, Vector3.new(0, -rayLength, 0), rayParams)
  if hit then return hit end
  for _, foot in character:GetChildren() do
   if foot:IsA("BasePart") and footNames[foot.Name] then
    local underFoot = Workspace:Raycast(foot.Position, Vector3.new(0, -(foot.Size.Y / 2 + .7), 0), rayParams)
    if underFoot then return underFoot end
   end
  end
  return nil
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
  local hit = standing()
  return {position = vector(root.Position), velocity = vector(root.AssemblyLinearVelocity),
   floor = humanoid.FloorMaterial.Name, humanoidState = humanoid:GetState().Name,
   support = hit and hit.Instance:GetFullName(), supportNormal = hit and vector(hit.Normal)}
 end
 local function isIn(part, group)
  return part and (part == group or part:IsDescendantOf(group))
 end
 local function edgeDistance(part, position, direction)
  local cf, size = part.CFrame, part.Size
  local extentX = (math.abs(cf.RightVector.X) * size.X + math.abs(cf.UpVector.X) * size.Y + math.abs(cf.LookVector.X) * size.Z) / 2
  local extentZ = (math.abs(cf.RightVector.Z) * size.X + math.abs(cf.UpVector.Z) * size.Y + math.abs(cf.LookVector.Z) * size.Z) / 2
  local answer = math.huge
  if math.abs(direction.X) > .0001 then answer = math.min(answer, (cf.Position.X + math.sign(direction.X) * extentX - position.X) / direction.X) end
  if math.abs(direction.Z) > .0001 then answer = math.min(answer, (cf.Position.Z + math.sign(direction.Z) * extentZ - position.Z) / direction.Z) end
  return answer
 end
 local approach
 originalOwner, originalAuto = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto()
 ownershipSaved = true
 root:SetNetworkOwner(nil)
 control = RunService.PreSimulation:Connect(function()
  if not root.Parent or not humanoid.Parent then return end
  if approach and not approach.requested then
   local hit = standing()
   if hit and isIn(hit.Instance, approach.from) and edgeDistance(hit.Instance, root.Position, approach.direction) <= .55 then
    approach.requested = true
    approach.launch = snapshot()
    approach.jumpPresses += 1
    jumpHeld = true
   end
  end
  humanoid:Move(movement, false)
  humanoid.Jump = jumpHeld
  jumpHeld = false
 end)
 local function endMovement()
  movement, jumpHeld, approach = Vector3.zero, false, nil
  humanoid:Move(Vector3.zero, false)
  humanoid.Jump = false
 end
 local function faceAim(part, side)
  local across = side * math.max(0, part.Size.X / 2 - 1.05)
  return part.CFrame * Vector3.new(across, 0, -part.Size.Z / 2)
 end
 local function hop(from, targetModel, targetPart, side, caseName, stage)
  local aim = faceAim(targetPart, side)
  local record = {target = targetPart:GetFullName(), aim = vector(aim), start = snapshot(), samples = {}, bodyHits = {},
   jumpPresses = 0, airborneObserved = false, secondsLimit = 2}
  progress(caseName, stage, "Attempting")
  local delta = (aim - root.Position) * Vector3.new(1, 0, 1)
  assert(delta.Magnitude > .01, "Degenerate hop direction")
  local attempt = {from = from, direction = delta.Unit, requested = false, jumpPresses = 0}
  approach, movement = attempt, delta.Unit
  local started, stableSince, lastSample = os.clock(), nil, -math.huge
  local fallFloor = math.max(Workspace.FallenPartsDestroyHeight + 50, math.min(root.Position.Y - legOffset, aim.Y) - 8)
  local reached, fell, targetBodyOverlap = false, false, false
  repeat
   RunService.Heartbeat:Wait()
   guard()
   assert(courseService.GetActiveCourse() == course, "ContextChanged: active course changed")
   local elapsed = os.clock() - started
   local flat = (aim - root.Position) * Vector3.new(1, 0, 1)
   movement = if flat.Magnitude <= .35 then Vector3.zero else flat.Unit
   if not attempt.requested then attempt.direction = if flat.Magnitude > .001 then flat.Unit else attempt.direction end
   if humanoid.FloorMaterial == Enum.Material.Air then
    record.airborneObserved = true
    if attempt.requested then jumpHeld = false end
   end
   local bodyHits = overlaps()
   for _, hit in bodyHits do record.bodyHits[hit] = true end
   local support = standing()
   local wanted = support and isIn(support.Instance, targetModel)
   local near = flat.Magnitude <= .9
   local supported = wanted and near and humanoid.FloorMaterial ~= Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y) < 3
   targetBodyOverlap = supported and #bodyHits > 0
   if supported and #bodyHits == 0 then stableSince = stableSince or os.clock() else stableSince = nil end
   if elapsed - lastSample >= .08 then
    local state = snapshot()
    state.seconds, state.nearTargetXZ, state.targetBodyOverlap = elapsed, near, targetBodyOverlap
    table.insert(record.samples, state)
    lastSample = elapsed
   end
   reached = attempt.requested and record.airborneObserved and stableSince and os.clock() - stableSince >= .1
   fell = root.Position.Y < fallFloor
   if reached or fell then break end
  until os.clock() - started >= 2
  record.seconds, record.jumpPresses, record.launch = os.clock() - started, attempt.jumpPresses, attempt.launch
  record.final, record.targetBodyOverlap = snapshot(), targetBodyOverlap
  if reached then record.outcome = "ReachedWithStableActualSupport"
  elseif fell then record.outcome = "Fall"
  elseif targetBodyOverlap or next(record.bodyHits) then record.outcome = "BodyContactWithoutValidTargetSettle"
  elseif not attempt.requested then record.outcome = "NoEdgeTakeoffWithinLimit"
  elseif not record.airborneObserved then record.outcome = "JumpDidNotBecomeAirborne"
  else record.outcome = "NoStableTargetWithinLimit" end
  endMovement()
  progress(caseName, stage, record.outcome)
  return reached, record
 end

 stored:SetAttribute("State", "Running")
 for _, case in {{name = "Center", side = 0}, {name = "LeftEdge", side = -1}, {name = "RightEdge", side = 1}} do
  guard()
  endMovement()
  local initialAcross = if case.side == 0 then 0 else fork.Size.X / 2 - 1.1
  local start = fork.CFrame * Vector3.new(initialAcross, fork.Size.Y / 2 + legOffset + .15, 0)
  local aim = faceAim(crown1.BackRim, case.side)
  local setup = {kind = "InitialCasePlacement", case = case.name, surface = fork:GetFullName(),
   position = vector(start), purpose = if case.side == 0 then "Clear main fork center" else "Clear main fork side nearest the Crown route"}
  table.insert(report.placements, setup)
  character:PivotTo(CFrame.lookAt(start, Vector3.new(aim.X, start.Y, aim.Z)))
  root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
  progress(case.name, "ForkSetup", "Settling")
  local settled, settleStarted, stable = false, os.clock(), nil
  repeat
   RunService.Heartbeat:Wait()
   guard()
   local hit = standing()
   if hit and isIn(hit.Instance, forkGroup) and humanoid.FloorMaterial ~= Enum.Material.Air and #overlaps() == 0 then stable = stable or os.clock() else stable = nil end
   settled = stable and os.clock() - stable >= .15
  until settled or os.clock() - settleStarted >= 2
  local result = {name = case.name, side = case.side, setup = setup, initial = snapshot(), hops = {}}
  table.insert(report.cases, result)
  if not settled then
   result.outcome = "InconclusiveForkSetupDidNotSettle"
  else
   local reached, receipt = hop(forkGroup, crown1, crown1.BackRim, case.side, case.name, "BackRim1")
   table.insert(result.hops, receipt)
   result.outcome = "EntryNotEstablished"
   if reached then
    reached, receipt = hop(crown1, crown1, crown1.CupFloor, case.side, case.name, "CupFloor1HighEnd")
    table.insert(result.hops, receipt)
    result.outcome = "HighEndNotReached"
    if reached then
     reached, receipt = hop(crown1, crown2, crown2.BackRim, case.side, case.name, "BackRim2")
     table.insert(result.hops, receipt)
     result.outcome = if reached then "StaticThreeHopSequenceReached" else "SecondRearRimNotReached"
    end
   end
  end
 end
 completedCases = true
end, debug.traceback)

if control then control:Disconnect(); control = nil end
movement, jumpHeld = Vector3.zero, false
if humanoid and humanoid.Parent then humanoid:Move(Vector3.zero, false); humanoid.Jump = false end
if character and root and root.Parent and humanoid and humanoid.Health > 0
 and Players:GetPlayers()[1] and Players:GetPlayers()[1].Character == character and course and course.Parent then
 local cleanupOk, cleanupFailure = pcall(function()
  local pocket = course.Obstacles.CP2_Pocket
  local distance = report.rig and report.rig.measuredLegOffset or humanoid.HipHeight + root.Size.Y / 2
  local target = pocket.CFrame * Vector3.new(0, pocket.Size.Y / 2 + distance + .15, 0)
  table.insert(report.placements, {kind = "PostTestCleanupPlacement", surface = pocket:GetFullName(), position = vector(target),
   purpose = "Authorized return after every attempt ended and the movement connection disconnected; not a hop or traversal"})
  character:PivotTo(CFrame.new(target))
  root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
 end)
 report.cleanup = {returnedToOriginalCP2 = cleanupOk, failure = if cleanupOk then nil else tostring(cleanupFailure)}
end
if ownershipSaved and root and root.Parent then
 local ownershipOk, ownershipFailure = pcall(function()
  if originalAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(originalOwner) end
 end)
 report.ownershipRestored = ownershipOk
 if not ownershipOk then report.ownershipFailure = tostring(ownershipFailure) end
end
report.probeComplete = ok and completedCases
report.failure = if ok then nil else tostring(failure)
report.staticSequenceReachedCases = 0
for _, case in report.cases do if case.outcome == "StaticThreeHopSequenceReached" then report.staticSequenceReachedCases += 1 end end
report.interpretation = if report.staticSequenceReachedCases > 0
 then "At least one listed static closed-geometry sequence worked; actual cycle and complete route remain unverified"
 else "The listed attempts did not establish the static sequence; no universal closed-route exclusion follows"
stored.Value = Http:JSONEncode(report)
stored:SetAttribute("State", if report.probeComplete then "Complete" else "Inconclusive")


