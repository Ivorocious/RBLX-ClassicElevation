--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Storage, Workspace, Http = game.ServerStorage, workspace, game.HttpService
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 85558151074819, "Owned Studio server only")

local reportName, fixtureName, dummyName = "EggRushR02TrayCarryReport", "ER_R02CarryFixture", "ER_R02CarryDummy"
assert(not Storage:FindFirstChild(reportName), "Preserve the existing carry report")
local report = Instance.new("StringValue")
report.Name, report.Parent = reportName, Storage
report:SetAttribute("State", "Ready")
local result = {
 candidate = script:GetAttribute("ExpectedCandidate") or "ER_P2_R02_C07", cases = {},
 method = "One copied R15 physical dummy, two sequential tray rides on one translated course clone; actual Runtime.Start and server-owned physics",
 limits = "Declared direct deck placement; no human entry/exit, official NPC enrollment, race progress, recovery, second client, crowd, FPS or full-course proof",
 profileWrites = 0, actualAvatarWrites = "Archivable temporarily enabled only while cloning, then immediately restored",
 manualCarryWrites = 0, fixtureTranslation = {0, 0, 2000},
}
local began, deadline = os.clock(), os.clock() + 55
local fixture, dummy, controller, original, originalArchivable
local function vector(v) return {v.X, v.Y, v.Z} end
local function horizontal(v) return Vector3.new(v.X, 0, v.Z) end
local function boundedFrame(row, sample)
 if #row.frames < 28 then table.insert(row.frames, sample) end
 row.lastFrame = sample
end
local ok, failure = xpcall(function()
 report:SetAttribute("State", "Running")
 assert(not Workspace:FindFirstChild(fixtureName) and not Workspace:FindFirstChild(dummyName), "Keep other fixtures untouched")
 local library = Storage:FindFirstChild("CourseLibrary")
 local template = library and library:FindFirstChild("Course_EggRush")
 assert(template and template:GetAttribute("CandidateId") == result.candidate, "Expected R02 course template required")
 assert(result.candidate:sub(1, 10) == "ER_P2_R02_", "R02 candidate only")
 local players = Players:GetPlayers()
 assert(#players == 1, "Use the existing single Play client")
 original = assert(players[1].Character, "Existing actual character required")
 local originalHumanoid = original:FindFirstChildOfClass("Humanoid")
 assert(originalHumanoid and originalHumanoid.RigType == Enum.HumanoidRigType.R15, "Actual R15 character required")
 originalArchivable = original.Archivable
 original.Archivable = true
 local cloned, copy = pcall(function() return original:Clone() end)
 original.Archivable = originalArchivable
 assert(cloned and copy, tostring(copy))
 dummy = copy
 dummy.Name = dummyName
 local removedScripts = 0
 for _, child in dummy:GetDescendants() do
  if child:IsA("LuaSourceContainer") then child:Destroy(); removedScripts += 1 end
 end
 local unanchored = 0
 for _, child in dummy:GetDescendants() do
  if child:IsA("BasePart") and child.Anchored then child.Anchored=false; unanchored+=1 end
 end
 result.unanchoredFixtureParts=unanchored
 result.removedCopiedScripts = removedScripts
 local humanoid = assert(dummy:FindFirstChildOfClass("Humanoid"))
 local root = assert(dummy:FindFirstChild("HumanoidRootPart"))
 local fit = assert(dummy:FindFirstChild("CollisionPart"), "Copied physical collider required")
 assert(root:IsA("BasePart") and fit:IsA("BasePart") and fit.CanCollide, "Preserve the copied colliding body and joints")
 assert(humanoid.Health > 0, "Copy a living character")
 humanoid.WalkSpeed, humanoid.UseJumpPower, humanoid.JumpHeight = 16, false, 7.2
 humanoid.Jump = false
 result.copiedColliderSize = vector(fit.Size)
 fit.Size = Vector3.new(math.max(fit.Size.X, 3.3), math.max(fit.Size.Y, 4.4), math.max(fit.Size.Z, 4.2))
 result.fixtureColliderSize = vector(fit.Size)
 result.colliderMethod = "Copied collider and joints; each dimension conservatively at least 3.3 by 4.4 by 4.2; not an exact live movement-profile fit"
 result.fixtureMovement = {walkSpeed = humanoid.WalkSpeed, useJumpPower = humanoid.UseJumpPower, jumpHeight = humanoid.JumpHeight}
 fixture = template:Clone()
 fixture.Name = fixtureName
 fixture:PivotTo(fixture:GetPivot() + Vector3.new(0, 0, 2000))
 fixture.Parent = Workspace
 local mechanisms = assert(fixture.Obstacles:FindFirstChild("Mechanisms"))
 local trayA, trayB = assert(mechanisms:FindFirstChild("SidewaysTray")), assert(mechanisms:FindFirstChild("SidewaysTrayB"))
 local travelA, travelB = trayA:GetAttribute("Travel"), trayB:GetAttribute("Travel")
 assert(typeof(travelA) == "Vector3" and typeof(travelB) == "Vector3")
 assert(math.abs(travelA.Magnitude - 16) < .001 and math.abs(travelB.Magnitude - 16) < .001, "Two full 16-stud strokes required")
 assert(math.abs(travelA.Unit:Dot(travelB.Unit)) < .001, "Authored tray directions must be orthogonal")
 local Runtime = require(Storage.CourseBuilders.EggRush.Runtime)
 controller = Runtime.Start(fixture, function() return false end, function() error("No player should be recovered by this fixture") end)
 local ray = RaycastParams.new()
 ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {fixture}, true
 ray.CollisionGroup = fit.CollisionGroup
 local function support()
  local length = math.max(humanoid.HipHeight + root.Size.Y / 2 + .8, (root.Position - fit.Position).Y + fit.Size.Y / 2 + .8)
  local hit = Workspace:Raycast(root.Position, Vector3.new(0, -length, 0), ray)
  return hit and hit.Instance
 end
 local function alive(caseDeadline)
  assert(os.clock() < deadline and os.clock() < caseDeadline, "Bounded carry deadline")
  assert(dummy and humanoid.Parent and root.Parent and humanoid.Health > 0, "Physical dummy is no longer alive")
 end
 for _, tray in ipairs({trayA, trayB}) do
  local row = {
   tray = tray.Name, ok = false, frames = {}, supportSamples = 0, supportedSamples = 0,
   airFrames = 0, unsupportedFrames = 0, travelSamples = 0, maximumHorizontalLocalDrift = 0,
   states = {}, expectedDistance = tray:GetAttribute("Travel").Magnitude,
  }
  table.insert(result.cases, row)
  local caseDeadline = math.min(deadline, os.clock() + 18)
  local caseOk, caseFailure = xpcall(function()
   local deck = assert(tray:FindFirstChild("TrayContact"))
   assert(deck:IsA("BasePart") and deck.CanCollide and deck.CanQuery and deck:GetAttribute("ERSupport") == true)
   local settings = {
    phase = tray:GetAttribute("PhaseSeconds") or 0, board = tray:GetAttribute("BoardSeconds"),
    warning = tray:GetAttribute("WarningSeconds"), move = tray:GetAttribute("MoveSeconds"),
    exit = tray:GetAttribute("ExitSeconds"), closingWarning = tray:GetAttribute("ClosingWarningSeconds"),
   }
   local cycle = settings.board + settings.warning + 2 * settings.move + settings.exit + settings.closingWarning
   local boardingRemaining
   repeat
    alive(caseDeadline)
    RunService.Heartbeat:Wait()
    local elapsed = controller.Diagnostics().elapsed
    local _, state = Runtime.Sample("Tray", settings, elapsed)
    local time = (elapsed + settings.phase) % cycle
    boardingRemaining = if state == "Boarding" and tray:GetAttribute("ERState") == "Boarding" then settings.board - time else 0
   until boardingRemaining >= 1.4
   local position = deck.Position + deck.CFrame.UpVector * (deck.Size.Y / 2) + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + .15, 0)
   dummy:PivotTo(CFrame.lookAt(position, position + deck.CFrame.LookVector))
   if not dummy.Parent then dummy.Parent = Workspace end
   root:SetNetworkOwner(nil)
   root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
   humanoid:Move(Vector3.zero, false)
   humanoid.Jump = false
   row.placement = {elapsed = controller.Diagnostics().elapsed, boardingRemaining = boardingRemaining, position = vector(root.Position), deckPosition = vector(deck.Position)}
   local settled, settleDeadline = 0, math.min(caseDeadline, os.clock() + 1.2)
   repeat
    alive(caseDeadline)
    assert(os.clock() < settleDeadline, "Actual colliding deck/FloorMaterial support did not settle")
    RunService.Heartbeat:Wait()
    humanoid:Move(Vector3.zero, false)
    local stable = support() == deck and humanoid.FloorMaterial ~= Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y) < 2
    settled = if stable then settled + 1 else 0
   until settled >= 3
   assert(tray:GetAttribute("ERState") == "Boarding", "Settle must finish before departure")
   row.settledAt = controller.Diagnostics().elapsed
   local startDeck, startRoot = deck.Position, root.Position
   local startLocal = deck.CFrame:PointToObjectSpace(root.Position)
   local sawTravel, sawExit, nextFrame = false, false, 0
   repeat
    alive(caseDeadline)
    RunService.Heartbeat:Wait()
    humanoid:Move(Vector3.zero, false)
    local elapsed = controller.Diagnostics().elapsed
    local _, sampledState = Runtime.Sample("Tray", settings, elapsed)
    local state = tray:GetAttribute("ERState")
    row.states[state] = (row.states[state] or 0) + 1
    assert(state == sampledState, "Published tray state differs from the actual Runtime sampler")
    if state == "Travel" then sawTravel = true; row.travelSamples += 1 end
    if state == "Exit" and sawTravel then sawExit = true end
    local standing, floor = support(), humanoid.FloorMaterial
    row.supportSamples += 1
    if standing == deck then row.supportedSamples += 1 else row.unsupportedFrames += 1 end
    if floor == Enum.Material.Air then row.airFrames += 1 end
    local drift = horizontal(deck.CFrame:PointToObjectSpace(root.Position) - startLocal).Magnitude
    row.maximumHorizontalLocalDrift = math.max(row.maximumHorizontalLocalDrift, drift)
    row.deckDistance, row.rootDistance = (deck.Position - startDeck).Magnitude, (root.Position - startRoot).Magnitude
    local sample = {elapsed = elapsed, state = state, floor = floor.Name, support = standing and standing.Name, deckDistance = row.deckDistance, rootDistance = row.rootDistance, horizontalLocalDrift = drift}
    if os.clock() >= nextFrame or sawExit then nextFrame = os.clock() + .25; boundedFrame(row, sample) end
    assert(state ~= "Returning" and state ~= "ReturnWarning", "Missed the complete outbound Travel to Exit")
   until sawExit
   row.sawTravel, row.sawExit = sawTravel, sawExit
   row.distanceDifference = math.abs(row.deckDistance - row.rootDistance)
   assert(math.abs(row.deckDistance - 16) < .1, "The deck did not complete its full 16-stud stroke")
   assert(math.abs(row.rootDistance - 16) <= 1 and row.distanceDifference <= 1, "The real dummy root did not physically travel the full matching stroke")
   assert(row.maximumHorizontalLocalDrift < 1.5, "Physical rider slipped more than the allowed local drift")
   assert(row.airFrames == 0 and row.unsupportedFrames == 0, "Physical support was lost after settling")
   assert(row.travelSamples > 0 and row.supportedSamples == row.supportSamples, "Actual supported Travel samples missing")
   row.ok = true
  end, debug.traceback)
  row.ok = caseOk and row.ok
  row.failure = if caseOk then nil else caseFailure
 end
 result.runtime = controller.Diagnostics()
 result.ok = #result.cases == 2 and result.cases[1].ok and result.cases[2].ok
end, debug.traceback)

local cleanupErrors = {}
local function cleanup(label, action)
 local cleaned, message = pcall(action)
 if not cleaned then table.insert(cleanupErrors, {label = label, failure = tostring(message)}) end
end
if controller then cleanup("Runtime.Stop", function() controller.Stop() end) end
if dummy then cleanup("dummy", function() dummy:Destroy() end) end
if fixture then cleanup("fixture", function() fixture:Destroy() end) end
if original and originalArchivable ~= nil then cleanup("Archivable", function() original.Archivable = originalArchivable end) end
result.seconds = os.clock() - began
result.fixtureRemoved, result.dummyRemoved = not Workspace:FindFirstChild(fixtureName), not Workspace:FindFirstChild(dummyName)
result.archivableRestored = original == nil or originalArchivable == nil or original.Archivable == originalArchivable
result.cleanupErrors = cleanupErrors
result.ok = ok and result.ok == true and #cleanupErrors == 0 and result.fixtureRemoved and result.dummyRemoved and result.archivableRestored
result.failure = if ok then nil else failure
local json = Http:JSONEncode(result)
assert(#json < 30000, "Carry report unexpectedly exceeds its bounded report size")
report.Value = json
report:SetAttribute("State", if result.ok then "Complete" else "Failed")
