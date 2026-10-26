--!nonstrict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
assert(RunService:IsStudio() and RunService:IsServer(), "Native Studio server diagnostic only")
local reportName = script:GetAttribute("ReportName") or "R01ClosedCrossingReport"
local fixtureName = script:GetAttribute("FixtureName") or "ER_R01_ClosedCrossingFixture"
local offsetZ = script:GetAttribute("FixtureOffsetZ") or 400
assert(offsetZ == 400 or offsetZ == 800, "Use one of the two isolated test volumes")
assert(not ServerStorage:FindFirstChild(reportName), "A closed-crossing report already exists")
local stored = Instance.new("StringValue")
stored.Name, stored.Parent = reportName, ServerStorage
stored:SetAttribute("State", "Preparing")
local report = {candidateId = "ER_P1_R01", sampleRevision = 3, cases = {}, captures = {}, placements = {}, ownerApproval = false,
 overlapDiagnostics = {}, overlapDiagnosticLimit = 8,
 method = "Four finite ordinary-control routes through actual captured closed-shell collision geometry; overlap findings do not stop physical continuation",
 limits = {
  "Static shells captured individually while fully closed; no actual-cycle or whole-race bypass proof",
  "Two bounded face choices per shell and two attempts per line are not an exhaustive route search",
  "Actual support may differ from the requested face; receipts identify the ray, part, normal and height",
  "Quality records Head/Torso overlap queries against colliding fixture geometry, not all limbs or visual-only art",
  "A failed attempt does not prove every closed route impossible; budget and setup failures remain inconclusive",
 },
 fixtureOffset = {0, 0, offsetZ}, totalSecondsLimit = 60}
local started = os.clock()
local deadline = started + report.totalSecondsLimit
local character, humanoid, root, course, raceId, services
local control, movement, jumpQueued = nil, Vector3.zero, false
local ownershipSaved, originalOwner, originalAuto = false, nil, nil
local legOffset
local diagnosticContext = {}
local function vector(p) return {p.X, p.Y, p.Z} end
local function state(caseName, stage, value)
 diagnosticContext = {case = caseName, stage = stage, state = value}
 stored:SetAttribute("Progress", Http:JSONEncode({case = caseName, stage = stage, state = value}))
end
local function guard()
 assert(character and Players:GetPlayers()[1] and Players:GetPlayers()[1].Character == character
  and root and root.Parent and humanoid and humanoid.Health > 0, "ContextChanged: character changed or died")
 assert(services.CourseService.GetActiveCourse() == course and services.RaceService.IsRaceActive()
  and services.RaceService.GetCurrentRaceId() == raceId, "ContextChanged: inspection race changed")
end

local ok, failure = xpcall(function()
 services = {}
 for _, name in {"CourseService", "RaceService", "EggRushService"} do services[name] = require(game.ServerScriptService.Services[name]) end
 course = assert(services.CourseService.GetActiveCourse(), "No active course")
 assert(course:GetAttribute("CandidateId") == "ER_P1_R01" and course:GetAttribute("Phase") == 1
  and course:GetAttribute("SampleRevision") == 3, "Expected R01 Phase 1 revision 3")
 assert(services.RaceService.IsRaceActive() and services.EggRushService.GetDiagnostics().bound == true, "Prepare the actual inspection race first")
 raceId = services.RaceService.GetCurrentRaceId()
 local player = assert(Players:GetPlayers()[1])
 character = assert(player.Character)
 root, humanoid = character.HumanoidRootPart, assert(character:FindFirstChildOfClass("Humanoid"))
 assert(not root.Anchored and humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower
  and math.abs(humanoid.JumpHeight - 7.2) < .01 and math.abs(Workspace.Gravity - 196.2) < .01, "Wrong actual movement profile")
 report.raceId, report.userId = raceId, player.UserId
 report.movement = {walk = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight,
  useJumpPower = humanoid.UseJumpPower, maxSlopeAngle = humanoid.MaxSlopeAngle, gravity = Workspace.Gravity,
  climbingEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Climbing)}
 report.bodyContacts = {}
 for _, name in {"Head", "UpperTorso", "LowerTorso", "Torso"} do
  local body = character:FindFirstChild(name)
  if body and body:IsA("BasePart") then report.bodyContacts[name] = body.CanCollide end
 end
 assert(not Workspace:FindFirstChild(fixtureName), "Preserve the existing crossing fixture")
 assert(not Workspace:FindFirstChild("ER_R01_ClosedClimbFixture") and not Workspace:FindFirstChild("ER_R01_ClosedClimbFeetFixture"),
  "Earlier closed-climb fixtures occupy this test volume; use a fresh Play session")
 local template = assert(ServerStorage.CourseLibrary:FindFirstChild("Course_EggRush"), "Missing authored open template")
 assert(template:GetAttribute("SampleRevision") == 3, "The open template must match revision 3")
 local offset = Vector3.new(0, 0, offsetZ)
 local fixture = Instance.new("Model")
 fixture.Name = fixtureName
 fixture:SetAttribute("Purpose", "Static captured closed geometry; no course registration")
 fixture.Parent = Workspace
 local fixed = {}
 for _, entry in {{"Fork", "Shell_ForkWait"}, {"Middle", "Shell_MiddleWait"}, {"Exit", "Shell_ExitWait"}} do
  local group = Instance.new("Folder")
  group.Name, group.Parent = entry[1], fixture
  local count = 0
  for _, source in course.Obstacles:GetChildren() do
   if source:IsA("BasePart") and (source.Name == entry[2] or source.Name:match("^" .. entry[2] .. "_Shoulder")) then
    local copy = source:Clone()
    copy.CFrame += offset
    copy.Parent = group
    count += 1
   end
  end
  assert(count == 3, "Capture the actual main contact and two shoulders for " .. entry[1])
  fixed[entry[1]] = group
 end
 local names = {"ShellLip1", "ShellLip2", "ShellLip3", "ShellLip4", "CrownLip1", "CrownLip2", "CrownLip3", "CrownLip4", "CrownLip5"}
 local captured, remaining = {}, #names
 local captureDeadline = math.min(deadline, os.clock() + 20)
 stored:SetAttribute("State", "CapturingClosed")
 repeat
  guard()
  for _, name in names do
   if captured[name] then continue end
   local source = assert(course.Obstacles.Mechanisms:FindFirstChild(name))
   local open = assert(template.Obstacles.Mechanisms:FindFirstChild(name)):GetPivot()
   local axis, angle = source:GetAttribute("RotationAxis"), source:GetAttribute("ClosedAngleDegrees")
   assert(typeof(axis) == "Vector3" and math.abs(axis.Magnitude - 1) < .001 and typeof(angle) == "number", "Missing actual pose contract")
   local expected = open * CFrame.fromAxisAngle(axis, math.rad(angle))
   local actual = source:GetPivot()
   local positionError = (actual.Position - expected.Position).Magnitude
   local alignment = math.min(actual.RightVector:Dot(expected.RightVector), actual.UpVector:Dot(expected.UpVector), actual.LookVector:Dot(expected.LookVector))
   if source:GetAttribute("ERState") ~= "Closed" or positionError > .03 or alignment < .9998 then continue end
   local copy = source:Clone()
   copy:PivotTo(actual + offset)
   copy.Parent = fixture
   captured[name], remaining = copy, remaining - 1
   table.insert(report.captures, {model = name, sourceState = "Closed", clock = services.EggRushService.GetDiagnostics().elapsed,
    angleDegrees = angle, rotationAxis = vector(axis), positionError = positionError, minimumBasisAlignment = alignment,
    collisionChanges = false})
  end
  if remaining == 0 then break end
  RunService.Heartbeat:Wait()
 until os.clock() >= captureDeadline
 assert(remaining == 0, "Not all nine actual closed poses were captured within twenty seconds")

 local footNames = {LeftFoot = true, RightFoot = true, ["Left Leg"] = true, ["Right Leg"] = true}
 legOffset = humanoid.HipHeight + root.Size.Y / 2
 local footMeasurements = {}
 for _, part in character:GetDescendants() do
  if not part:IsA("BasePart") or not footNames[part.Name] then continue end
  local cf, size = part.CFrame, part.Size
  local extent = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
  local distance = root.Position.Y - (part.Position.Y - extent)
  legOffset = math.max(legOffset, distance)
  table.insert(footMeasurements, {part = part.Name, rootToBottom = distance})
 end
 assert(legOffset >= 1 and legOffset <= 8 and #footMeasurements > 0, "No bounded actual leg measurement")
 report.rig = {type = humanoid.RigType.Name, hipHeight = humanoid.HipHeight, rootSize = vector(root.Size),
  measuredLegOffset = legOffset, feet = footMeasurements}
 local rayParams = RaycastParams.new()
 rayParams.FilterType, rayParams.FilterDescendantsInstances, rayParams.RespectCanCollide = Enum.RaycastFilterType.Include, {fixture}, true
 local overlapParams = OverlapParams.new()
 overlapParams.FilterType, overlapParams.FilterDescendantsInstances, overlapParams.RespectCanCollide = Enum.RaycastFilterType.Include, {fixture}, true
 overlapParams.MaxParts = 32
 local bodyParts = {}
 for _, name in {"Head", "Torso", "UpperTorso", "LowerTorso"} do
  local part = character:FindFirstChild(name)
  if part and part:IsA("BasePart") then table.insert(bodyParts, part) end
 end
 local diagnosticPairs = {}
 local function partPose(part)
  return {name = part.Name, path = part:GetFullName(), cframe = {part.CFrame:GetComponents()}, size = vector(part.Size),
   canCollide = part.CanCollide, canQuery = part.CanQuery, collisionGroup = part.CollisionGroup}
 end
 local function collisionEligibility(part, other)
  local eligibility = {bothCanCollide = part.CanCollide and other.CanCollide,
   groupsCollidable = game:GetService("PhysicsService"):CollisionGroupsAreCollidable(part.CollisionGroup, other.CollisionGroup)}
  local queryOk, queryResult = pcall(function() return part:CanCollideWith(other) end)
  if queryOk then eligibility.canCollideWith = queryResult else eligibility.queryFailure = tostring(queryResult) end
  return eligibility
 end
 local function cornerBounds(body, frame, size)
  local low, high = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
  local outside, inside = Vector3.zero, 0
  for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
   local point = frame:PointToObjectSpace(body.CFrame * Vector3.new(x * body.Size.X / 2, y * body.Size.Y / 2, z * body.Size.Z / 2))
   low = Vector3.new(math.min(low.X, point.X), math.min(low.Y, point.Y), math.min(low.Z, point.Z))
   high = Vector3.new(math.max(high.X, point.X), math.max(high.Y, point.Y), math.max(high.Z, point.Z))
   if size then
    outside = Vector3.new(math.max(outside.X, math.abs(point.X) - size.X / 2), math.max(outside.Y, math.abs(point.Y) - size.Y / 2), math.max(outside.Z, math.abs(point.Z) - size.Z / 2))
    if math.abs(point.X) <= size.X / 2 and math.abs(point.Y) <= size.Y / 2 and math.abs(point.Z) <= size.Z / 2 then inside += 1 end
   end
  end end end
  return {minimum = vector(low), maximum = vector(high), maximumCornerOutsideByAxis = size and vector(outside),
   cornersInsideBox = size and inside}
 end
 local function overlapDiagnostic(body, collider)
  local key = body:GetFullName() .. " -> " .. collider:GetFullName()
  if diagnosticPairs[key] or #report.overlapDiagnostics >= report.overlapDiagnosticLimit then return end
  diagnosticPairs[key] = true
  local entry = {pair = key, seconds = os.clock() - started, context = diagnosticContext}
  table.insert(report.overlapDiagnostics, entry)
  local capturedOk, capturedFailure = pcall(function()
   entry.body, entry.root, entry.shellCollider = partPose(body), partPose(root), partPose(collider)
   entry.humanoidState, entry.floor, entry.rootVelocity = humanoid:GetState().Name, humanoid.FloorMaterial.Name, vector(root.AssemblyLinearVelocity)
   entry.bodyBoundsInRoot = cornerBounds(body, root.CFrame)
   entry.bodyBoundsInShellCollider = cornerBounds(body, collider.CFrame, collider.Size)
   entry.bodyCollisionEligibilityWithShell = collisionEligibility(body, collider)
   for _, joint in character:GetDescendants() do
    if joint:IsA("Motor6D") and joint.Part1 == body then
     entry.joint = {name = joint.Name, path = joint:GetFullName(), part0 = joint.Part0 and joint.Part0:GetFullName(), part1 = body:GetFullName(),
      c0 = {joint.C0:GetComponents()}, c1 = {joint.C1:GetComponents()}, transform = {joint.Transform:GetComponents()}}
     break
    end
   end
   local collisionPart = character:FindFirstChild("CollisionPart", true)
   entry.collisionPartPresent = collisionPart ~= nil and collisionPart:IsA("BasePart")
   if entry.collisionPartPresent then
    entry.collisionPart = partPose(collisionPart)
    entry.collisionPartRootRelativeCFrame = {root.CFrame:ToObjectSpace(collisionPart.CFrame):GetComponents()}
    entry.collisionPartCollisionEligibilityWithShell = collisionEligibility(collisionPart, collider)
    entry.collisionPartJoints, entry.collisionPartJointCount = {}, 0
    for _, joint in character:GetDescendants() do
     if not (joint:IsA("JointInstance") or joint:IsA("WeldConstraint")) then continue end
     if joint.Part0 ~= collisionPart and joint.Part1 ~= collisionPart then continue end
     entry.collisionPartJointCount += 1
     if #entry.collisionPartJoints >= 4 then continue end
     local link = {name = joint.Name, path = joint:GetFullName(), className = joint.ClassName,
      part0 = joint.Part0 and joint.Part0:GetFullName(), part1 = joint.Part1 and joint.Part1:GetFullName()}
     if joint:IsA("JointInstance") then link.c0, link.c1 = {joint.C0:GetComponents()}, {joint.C1:GetComponents()} end
     if joint:IsA("Motor6D") then link.transform = {joint.Transform:GetComponents()} end
     table.insert(entry.collisionPartJoints, link)
    end
    entry.bodyBoundsInCollisionPart = cornerBounds(body, collisionPart.CFrame, collisionPart.Size)
    entry.collisionPartBoundsInRoot = cornerBounds(collisionPart, root.CFrame)
    entry.collisionPartHits, entry.collisionPartHitsThisShellCollider = {}, false
    for _, hit in Workspace:GetPartsInPart(collisionPart, overlapParams) do
     if hit.CanCollide then
      table.insert(entry.collisionPartHits, hit:GetFullName())
      if hit == collider then entry.collisionPartHitsThisShellCollider = true end
     end
    end
   end
  end)
  if not capturedOk then entry.captureFailure = tostring(capturedFailure) end
 end
 local minimumUp = math.cos(math.rad(math.min(humanoid.MaxSlopeAngle, 89)))
 local function inGroup(part, group) return part and (part == group or part:IsDescendantOf(group)) end
 local function supports(group)
  local found = {}
  local function cast(name, origin, length)
   local hit = Workspace:Raycast(origin, Vector3.new(0, -length, 0), rayParams)
   if not hit or hit.Normal.Y < minimumUp or (group and not inGroup(hit.Instance, group)) then return end
   if name == "Root" and math.abs(root.Position.Y - hit.Position.Y - legOffset) > .85 then return end
   if name == "Root" then table.insert(found, {hit = hit, ray = name}) else table.insert(found, 1, {hit = hit, ray = name}) end
  end
  cast("Root", root.Position, legOffset + .7)
  for _, foot in character:GetChildren() do
   if foot:IsA("BasePart") and footNames[foot.Name] then
    local cf, size = foot.CFrame, foot.Size
    local extent = (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z) / 2
    cast(foot.Name, foot.Position, extent + .7)
   end
  end
  return found
 end
 local function overlaps()
  local hits = {}
  for _, body in bodyParts do
   for _, part in Workspace:GetPartsInPart(body, overlapParams) do
    if part.CanCollide then
     table.insert(hits, body.Name .. " -> " .. part:GetFullName())
     overlapDiagnostic(body, part)
    end
   end
  end
  return hits
 end
 local function snapshot(group)
  local contacts = supports(group)
  local contact = contacts[1]
  return {position = vector(root.Position), velocity = vector(root.AssemblyLinearVelocity), floor = humanoid.FloorMaterial.Name,
   humanoidState = humanoid:GetState().Name, support = contact and contact.hit.Instance:GetFullName(), ray = contact and contact.ray,
   surfacePosition = contact and vector(contact.hit.Position), supportNormal = contact and vector(contact.hit.Normal),
   rootAboveSurface = contact and root.Position.Y - contact.hit.Position.Y}, contact
 end
 local function faceList(group, side)
  local faces = {}
  for _, part in group:GetDescendants() do
   if not part:IsA("BasePart") or not part.CanCollide then continue end
   for axisIndex, axis in {"X", "Y", "Z"} do
    local normal = if axis == "X" then part.CFrame.RightVector elseif axis == "Y" then part.CFrame.UpVector else -part.CFrame.LookVector
    for _, sign in {-1, 1} do
     local up = normal * sign
     if up.Y < minimumUp then continue end
     local localCenter = Vector3.zero
     localCenter = if axis == "X" then Vector3.new(sign * part.Size.X / 2, 0, 0)
      elseif axis == "Y" then Vector3.new(0, sign * part.Size.Y / 2, 0) else Vector3.new(0, 0, sign * part.Size.Z / 2)
     local tangentA = if axis == "X" then part.CFrame.UpVector else part.CFrame.RightVector
     local lengthA = if axis == "X" then part.Size.Y else part.Size.X
     local tangentB = if axis == "Z" then part.CFrame.UpVector else -part.CFrame.LookVector
     local lengthB = if axis == "Z" then part.Size.Y else part.Size.Z
     local across, width = tangentA, lengthA
     if math.abs(tangentB.Z) > math.abs(tangentA.Z) then across, width = tangentB, lengthB end
     local center = part.CFrame * localCenter
     local aim = center + across * side * math.max(0, width / 2 - 1.05)
     local buried = false
     for _, other in group:GetDescendants() do
      if other == part or not other:IsA("BasePart") or not other.CanCollide then continue end
      local p = other.CFrame:PointToObjectSpace(aim + up * .03)
      if math.abs(p.X) < other.Size.X / 2 - .01 and math.abs(p.Y) < other.Size.Y / 2 - .01 and math.abs(p.Z) < other.Size.Z / 2 - .01 then buried = true; break end
     end
     if not buried then table.insert(faces, {part = part, axis = axis, sign = sign, aim = aim, up = up, area = lengthA * lengthB}) end
    end
   end
  end
  return faces
 end
 local jumpVelocity = math.sqrt(2 * Workspace.Gravity * humanoid.JumpHeight)
 local function reach(rise)
  local d = jumpVelocity * jumpVelocity - 2 * Workspace.Gravity * rise
  return if d < 0 then -1 else humanoid.WalkSpeed * (jumpVelocity + math.sqrt(d)) / Workspace.Gravity
 end
 local function edgeDistance(part, position, direction)
  local cf, size = part.CFrame, part.Size
  local extentX = (math.abs(cf.RightVector.X) * size.X + math.abs(cf.UpVector.X) * size.Y + math.abs(cf.LookVector.X) * size.Z) / 2
  local extentZ = (math.abs(cf.RightVector.Z) * size.X + math.abs(cf.UpVector.Z) * size.Y + math.abs(cf.LookVector.Z) * size.Z) / 2
  local distance = math.huge
  if math.abs(direction.X) > .0001 then distance = math.min(distance, (cf.Position.X + math.sign(direction.X) * extentX - position.X) / direction.X) end
  if math.abs(direction.Z) > .0001 then distance = math.min(distance, (cf.Position.Z + math.sign(direction.Z) * extentZ - position.Z) / direction.Z) end
  return math.max(0, distance)
 end
 local function chooseFace(group, side, mode, from)
  local candidates = faceList(group, side)
  assert(#candidates > 0, "No exposed up-facing closed collision face in " .. group.Name)
  local _, actual = snapshot(from)
  local footHeight = actual and actual.hit.Position.Y or root.Position.Y - legOffset
  local best, bestScore
  for _, face in candidates do
   local flat = (face.aim - root.Position) * Vector3.new(1, 0, 1)
   local gap = flat.Magnitude
   if actual and gap > .001 then gap = math.max(0, gap - edgeDistance(actual.hit.Instance, root.Position, flat.Unit)) end
   local rise = face.aim.Y - footHeight
   local margin = reach(rise) - gap
   local score = if mode == "ExitFace" then face.aim.Y - footHeight + .15 * (face.aim.X - root.Position.X) + math.min(margin, 0) * 4
    else margin * 2 - .1 * math.abs(rise) - .05 * flat.Magnitude + .1 * face.up.Y
   if not bestScore or score > bestScore then
    bestScore, best = score, face
    best.ranking = {policy = mode, projectedGapEstimate = gap, riseEstimate = rise, idealPointReach = reach(rise), score = score, candidateCount = #candidates}
   end
  end
  return best
 end
 local approach
 originalOwner, originalAuto = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto()
 ownershipSaved = true
 root:SetNetworkOwner(nil)
 control = RunService.PreSimulation:Connect(function()
  if not root.Parent or not humanoid.Parent then return end
  if approach and not approach.requested then
   local contacts = supports(approach.from)
   local actual = contacts[1]
   if actual and edgeDistance(actual.hit.Instance, root.Position, approach.direction) <= .55 then
    approach.requested, approach.launch, approach.presses = true, snapshot(approach.from), 1
    jumpQueued = true
   end
  end
  humanoid:Move(movement, false)
  humanoid.Jump = jumpQueued
  jumpQueued = false
 end)
 local function stopMovement()
  movement, jumpQueued, approach = Vector3.zero, false, nil
  humanoid:Move(Vector3.zero, false)
  humanoid.Jump = false
 end
 local function hop(from, target, face, case, label)
  local record = {stage = label, requestedPart = face.part:GetFullName(), requestedAxis = face.axis, requestedSign = face.sign,
   requestedAim = vector(face.aim), requestedNormal = vector(face.up), ranking = face.ranking,
   start = snapshot(from), samples = {}, bodyOverlaps = {}, secondsLimit = 2}
  table.insert(case.hops, record)
  state(case.name, label, "Attempting")
  local flat = (face.aim - root.Position) * Vector3.new(1, 0, 1)
  local attempt = {from = from, direction = if flat.Magnitude > .001 then flat.Unit else Vector3.xAxis, presses = 0, requested = false}
  approach, movement = attempt, if flat.Magnitude > .35 then flat.Unit else Vector3.zero
  local began, stableSince, lastSample = os.clock(), nil, -math.huge
  local fallFloor = math.max(Workspace.FallenPartsDestroyHeight + 50, math.min(root.Position.Y - legOffset, face.aim.Y) - 8)
  local reached, fell = false, false
  repeat
   RunService.Heartbeat:Wait()
   guard()
   local elapsed = os.clock() - began
   flat = (face.aim - root.Position) * Vector3.new(1, 0, 1)
   movement = if flat.Magnitude > .35 then flat.Unit else Vector3.zero
   if not attempt.requested and flat.Magnitude > .001 then attempt.direction = flat.Unit end
   local current, actual = snapshot(target)
   local bodyHits = overlaps()
   for _, hit in bodyHits do record.bodyOverlaps[hit] = true; case.bodyOverlaps[hit] = true end
   local supported = actual and humanoid.FloorMaterial ~= Enum.Material.Air and flat.Magnitude <= .9 and math.abs(root.AssemblyLinearVelocity.Y) < 1
   if supported then stableSince = stableSince or os.clock() else stableSince = nil end
   if elapsed - lastSample >= .1 then
    current.seconds, current.nearRequestedXZ, current.currentBodyOverlapCount = elapsed, flat.Magnitude <= .9, #bodyHits
    table.insert(record.samples, current)
    lastSample = elapsed
   end
   record.airborneObserved = record.airborneObserved or humanoid.FloorMaterial == Enum.Material.Air
   reached = stableSince and os.clock() - stableSince >= .15
   fell = root.Position.Y < fallFloor
   if reached or fell then break end
  until os.clock() - began >= 2 or os.clock() >= deadline
  record.seconds, record.jumpPresses, record.launch = os.clock() - began, attempt.presses, attempt.launch
  record.final = snapshot(target)
  record.physicallyReached = reached == true
  record.qualityOverlapObserved = next(record.bodyOverlaps) ~= nil
  record.outcome = if reached then "SupportedNearRequestedXZ_ActualSurfaceRecorded"
   elseif fell then "Fall" elseif os.clock() >= deadline then "InconclusiveGlobalBudget" else "NoSupportedTargetWithinTwoSeconds"
  stopMovement()
  state(case.name, label, record.outcome)
  return reached == true
 end

 local cases = {{name = "NormalCenter", line = "Normal", side = 0}, {name = "NormalOuterEdge", line = "Normal", side = -1},
  {name = "ExpertCenter", line = "Expert", side = 0}, {name = "ExpertInnerEdge", line = "Expert", side = 1}}
 local fork = fixed.Fork.Shell_ForkWait
 stored:SetAttribute("State", "Running")
 for _, plan in cases do
  guard()
  local case = {name = plan.name, line = plan.line, side = plan.side, hops = {}, bodyOverlaps = {}}
  table.insert(report.cases, case)
  if os.clock() >= deadline - 1 then case.outcome = "InconclusiveGlobalBudget"; continue end
  stopMovement()
  local firstModel = captured[if plan.line == "Normal" then "ShellLip1" else "CrownLip1"]
  local across = if plan.side == 0 then 0 else math.clamp(fork.CFrame:PointToObjectSpace(firstModel:GetPivot().Position).X, -fork.Size.X / 2 + 1.1, fork.Size.X / 2 - 1.1)
  local position = fork.CFrame * Vector3.new(across, fork.Size.Y / 2 + legOffset + .15, 0)
  local look = firstModel:GetPivot().Position
  table.insert(report.placements, {kind = "InitialCasePlacement", case = case.name, surface = fork:GetFullName(), position = vector(position)})
  character:PivotTo(CFrame.lookAt(position, Vector3.new(look.X, position.Y, look.Z)))
  root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
  local settleStarted, stableSince = os.clock(), nil
  repeat
   RunService.Heartbeat:Wait()
   guard()
   if #supports(fixed.Fork) > 0 and humanoid.FloorMaterial ~= Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y) < .1 then stableSince = stableSince or os.clock() else stableSince = nil end
   if stableSince and os.clock() - stableSince >= .25 then break end
  until os.clock() - settleStarted >= 2 or os.clock() >= deadline
  if not stableSince or os.clock() - stableSince < .25 then case.outcome = "InconclusiveForkSetup"; continue end
  case.initial = snapshot(fixed.Fork)
  local route = if plan.line == "Normal" then {captured.ShellLip1, captured.ShellLip2, fixed.Middle, captured.ShellLip3, captured.ShellLip4, fixed.Exit}
   else {captured.CrownLip1, captured.CrownLip2, captured.CrownLip3, captured.CrownLip4, captured.CrownLip5, fixed.Exit}
  local from, crossed = fixed.Fork, true
  for index, target in route do
   if os.clock() >= deadline then case.outcome = "InconclusiveGlobalBudget"; crossed = false; break end
   local entry = chooseFace(target, plan.side, "EntryFace", from)
   if not hop(from, target, entry, case, string.format("%02d_%s_Entry", index, target.Name)) then
    case.outcome, crossed = if os.clock() >= deadline then "InconclusiveGlobalBudget" else "StoppedBeforeSharedExit", false
    break
   end
   from = target
   if target:IsA("Model") and target ~= fixture then
    local exitFace = chooseFace(target, plan.side, "ExitFace", from)
    local current, actual = snapshot(target)
    local flat = (exitFace.aim - root.Position) * Vector3.new(1, 0, 1)
    if not actual or flat.Magnitude > .9 or math.abs(actual.hit.Position.Y - exitFace.aim.Y) > .5 then
     if not hop(from, target, exitFace, case, string.format("%02d_%s_ExitFace", index, target.Name)) then
      case.outcome, crossed = if os.clock() >= deadline then "InconclusiveGlobalBudget" else "StoppedAtWithinShellFace", false
      break
     end
    else
     case.alreadySupportedExitFaceCount = (case.alreadySupportedExitFaceCount or 0) + 1
    end
   end
  end
  case.traversabilityEstablished = crossed
  case.queriedBodyOverlapObserved = next(case.bodyOverlaps) ~= nil
  case.qualityStatus = if case.queriedBodyOverlapObserved then "HeadTorsoOverlapObserved" else "NoQueriedHeadTorsoOverlapObservedOnVisitedSequence"
  if crossed then case.outcome = "StaticForkToSharedExitReached" end
 end
end, debug.traceback)

if control then control:Disconnect() end
movement, jumpQueued = Vector3.zero, false
if humanoid and humanoid.Parent then humanoid:Move(Vector3.zero, false); humanoid.Jump = false end
if character and root and root.Parent and humanoid and humanoid.Health > 0 and Players:GetPlayers()[1]
 and Players:GetPlayers()[1].Character == character and course and course.Parent then
 local cleanupOk, cleanupFailure = pcall(function()
  local pocket = course.Obstacles.CP2_Pocket
  local target = pocket.Position + Vector3.new(0, pocket.Size.Y / 2 + (legOffset or humanoid.HipHeight + root.Size.Y / 2) + .15, 0)
  table.insert(report.placements, {kind = "PostTestCleanupPlacement", position = vector(target), surface = pocket:GetFullName(),
   purpose = "Authorized return after movement disconnect; not part of any crossing"})
  character:PivotTo(CFrame.new(target))
  root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
 end)
 report.cleanup = {returnedToCP2 = cleanupOk, failure = if cleanupOk then nil else tostring(cleanupFailure)}
end
if ownershipSaved and root and root.Parent then
 local restored, restoreFailure = pcall(function()
  if originalAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(originalOwner) end
 end)
 report.ownershipRestored = restored
 if not restored then report.ownershipFailure = tostring(restoreFailure) end
end
report.probeExecuted, report.failure, report.wallSeconds = ok, if ok then nil else tostring(failure), os.clock() - started
report.staticCrossingsReached = 0
report.caseAttemptsComplete = ok and #report.cases == 4
for _, case in report.cases do
 if case.traversabilityEstablished then report.staticCrossingsReached += 1 end
 if case.outcome and case.outcome:match("^Inconclusive") then report.caseAttemptsComplete = false end
end
report.interpretation = if report.staticCrossingsReached > 0 then "Listed static geometry crossing observed; actual clock, race shortcuts and quality need separate assessment"
 else "No listed static crossing established; this bounded probe cannot exclude every closed route"
stored.Value = Http:JSONEncode(report)
stored:SetAttribute("State", if report.caseAttemptsComplete then "Complete" else "Inconclusive")
