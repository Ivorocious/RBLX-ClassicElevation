--!nonstrict
local Checks = {}
local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")

local function waitFor(predicate, seconds, message, guard)
 local deadline = os.clock() + seconds
 repeat
  RunService.Heartbeat:Wait()
  if guard then guard() end
  if predicate() then return end
 until os.clock() > deadline
 error(message)
end

function Checks.Start()
 assert(RunService:IsStudio() and RunService:IsServer(), "Phase 1 checks require a native Studio server")
 assert(not game.ServerStorage:FindFirstChild("EggRushP1R01Results"), "Phase 1 runner already exists")
 local results = Instance.new("Folder")
 results.Name = "EggRushP1R01Results"
 results:SetAttribute("CandidateId", "ER_P1_R01")
 results:SetAttribute("OwnerApproval", false)
 results.Parent = game.ServerStorage
 local services = {}
 for _, name in {"CourseService", "RaceService", "PlayerRaceService", "CheckpointService", "OnboardingService", "EggRushService", "ResultsService"} do
  services[name] = require(game.ServerScriptService.Services[name])
 end
 local busy = false
 local function candidate()
  local course = assert(services.CourseService.GetActiveCourse(), "No active course")
  assert(course:GetAttribute("CandidateId") == "ER_P1_R01" and course:GetAttribute("Phase") == 1
   and course:GetAttribute("CourseId") == "egg_rush_circuit" and course:GetAttribute("EROwned") == true, "Wrong Phase 1 candidate")
  return course
 end
 local function prepare()
  local player = assert(game.Players:GetPlayers()[1], "No test player")
  for _, racer in game.Players:GetPlayers() do
   if racer:GetAttribute("OnboardingReady") ~= true then
    local ok, message = services.OnboardingService.SetStudioPreset(racer, "Returning racer")
    assert(ok, message)
    waitFor(function() return racer:GetAttribute("OnboardingReady") == true end, 25, "Returning racer preset did not arrive")
   end
  end
  assert(services.CourseService.SelectCourseForStudio("egg_rush_circuit"), "Install the disabled Phase 1 template for this test deliberately")
  services.RaceService.SetInspectionUnlimitedTime(true)
  local previous = services.RaceService.GetCurrentRaceId()
  assert(services.RaceService.ApplyStudioAction("RestartRace"), "Could not start Phase 1 inspection race")
  waitFor(function()
   return services.RaceService.IsRaceActive() and services.RaceService.GetCurrentRaceId() ~= previous
    and services.CourseService.GetActiveCourseId() == "egg_rush_circuit"
  end, 35, "Fresh inspection race did not become active")
  candidate()
  waitFor(function() return services.EggRushService.GetDiagnostics().bound == true end, 3, "Sample runtime did not bind")
  local humanoid = assert(player.Character):FindFirstChildOfClass("Humanoid")
  return {candidateId = "ER_P1_R01", phase = 1, raceId = services.RaceService.GetCurrentRaceId(),
   official = services.PlayerRaceService.IsOfficialRacer(player), status = services.PlayerRaceService.GetPlayerStatus(player),
   walk = humanoid.WalkSpeed, jump = humanoid.JumpHeight, usePower = humanoid.UseJumpPower, gravity = workspace.Gravity,
   runtime = services.EggRushService.GetDiagnostics(), setup = "Returning racer inspection preset; no human entry claim"}
 end
 local function inspection()
  local course = candidate()
  local player = assert(game.Players:GetPlayers()[1], "No test player")
  assert(services.RaceService.IsRaceActive() and services.PlayerRaceService.IsOfficialRacer(player)
   and services.PlayerRaceService.GetPlayerStatus(player) == "Racing", "Prepare an official inspection racer")
  return course, player
 end
 local function recovery(selection)
  assert(selection == "Fall" or selection == "Red" or selection == "Both", "Recovery selection must be Fall, Red or Both")
  local course, player = inspection()
  local char = assert(player.Character)
  local root = char.HumanoidRootPart
  local humanoid = assert(char:FindFirstChildOfClass("Humanoid"))
  local raceId = services.RaceService.GetCurrentRaceId()
  local receipts = {}
  local function guard()
   assert(player.Character == char and root.Parent and humanoid.Health > 0, "Recovery check character changed")
   assert(services.CourseService.GetActiveCourse() == course and services.RaceService.IsRaceActive()
    and services.RaceService.GetCurrentRaceId() == raceId, "Recovery check race changed")
  end
  local function place(position)
   guard()
   root.Anchored = false
   root:SetNetworkOwner(nil)
   humanoid:Move(Vector3.zero, false)
   humanoid.Jump = false
   char:PivotTo(CFrame.new(position))
   root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
  end
  local ok, failure = xpcall(function()
   for _, kind in if selection == "Both" then {"Fall", "Red"} else {selection} do
    assert(services.CheckpointService.SetInspectionCheckpointForStudio(player, 2), "CP2 inspection setup failed")
    local pocket = course.Obstacles.CP2_Pocket
    place(pocket.Position + Vector3.new(0, pocket.Size.Y / 2 + humanoid.HipHeight + root.Size.Y / 2 + .15, 0))
    local settledAt = os.clock()
    waitFor(function() return os.clock() - settledAt >= 1.65 end, 3, "Recovery cooldown did not settle", guard)
    assert((char:GetAttribute("RecoveryUntil") or 0) <= workspace:GetServerTimeNow(), "Setup still has recovery immunity")
    local result = assert(services.ResultsService.GetPlayerResult(player))
    local before, lap, nextCheckpoint = result.falls or 0, result.currentLap, result.nextCheckpointIndex
    local target, position
    if kind == "Red" then
     target = assert(course.Obstacles:FindFirstChild("Shellworks_RedHop"), "Missing sample red obstacle")
     assert(target:IsA("BasePart") and target.Transparency < 1 and target.CanQuery
      and not target.CanCollide and target:GetAttribute("ERLethal") == true, "Red contact must be visible and queryable")
     position = target.Position
    else
     target = assert(course.FallZones:FindFirstChild("FallZone_Main"), "Missing actual fall zone")
     position = target.Position + Vector3.new(target.Size.X / 2 - 12, target.Size.Y / 2 + 12, 0)
    end
    local receipt = {kind = kind, checkpoint = 2, target = target:GetFullName(),
     setupPosition = {position.X, position.Y, position.Z}, setup = if kind == "Red" then "Deliberate body overlap with actual red contact" else "Deliberate freefall above actual fall zone"}
    table.insert(receipts, receipt)
    place(position)
    waitFor(function() return (services.ResultsService.GetPlayerResult(player).falls or 0) > before end, 4, kind .. " did not trigger recovery", guard)
    local expected = assert(services.CheckpointService.GetCheckpointRespawnCFrame(player))
    waitFor(function() return (root.Position - expected.Position).Magnitude < 3 end, 2, kind .. " missed CP2 recovery", guard)
    local recoveredAt = os.clock()
    waitFor(function() return os.clock() - recoveredAt >= 1.65 end, 3, "Post-recovery observation timed out", guard)
    result = services.ResultsService.GetPlayerResult(player)
    receipt.recoveries = (result.falls or 0) - before
    receipt.recoveryError = (root.Position - expected.Position).Magnitude
    receipt.latestCheckpoint = services.CheckpointService.GetLatestCheckpointIndex(player)
    receipt.progressPreserved = result.currentLap == lap and result.nextCheckpointIndex == nextCheckpoint
    assert(receipt.recoveries == 1 and receipt.latestCheckpoint == 2 and receipt.recoveryError < 3
     and receipt.progressPreserved, kind .. " recovery changed progress, repeated or missed CP2")
   end
  end, debug.traceback)
  if root.Parent then
   humanoid:Move(Vector3.zero, false)
   humanoid.Jump = false
   root:SetNetworkOwnershipAuto()
  end
  return {ok = ok, failure = if ok then nil else failure, candidateId = "ER_P1_R01", checks = receipts,
   limits = "Isolated inspection CP2 writes and listed setup teleports; actual contact/fall and existing recovery. No continuous route or human-control claim."}
 end
 local function fixedWait(selection)
  assert(selection == "Fork" or selection == "Middle", "Wait selection must be Fork or Middle")
  local course, player = inspection()
  local char = assert(player.Character)
  local root, humanoid = char.HumanoidRootPart, assert(char:FindFirstChildOfClass("Humanoid"))
  local raceId = services.RaceService.GetCurrentRaceId()
  local pocket = course.Obstacles[if selection == "Fork" then "Shell_ForkWait" else "Shell_MiddleWait"]
  local model = course.Obstacles.Mechanisms[if selection == "Fork" then "ShellLip1" else "ShellLip3"]
  local duration = model:GetAttribute("ClosedSeconds") + model:GetAttribute("WarningSeconds")
   + 2 * model:GetAttribute("MoveSeconds") + model:GetAttribute("OpenSeconds") + model:GetAttribute("ClosingWarningSeconds")
  local function guard()
   assert(player.Character == char and root.Parent and humanoid.Health > 0, "Wait check character changed")
   assert(services.CourseService.GetActiveCourse() == course and services.RaceService.IsRaceActive()
    and services.RaceService.GetCurrentRaceId() == raceId, "Wait check race changed")
  end
  local params = RaycastParams.new()
  params.FilterType, params.FilterDescendantsInstances, params.RespectCanCollide = Enum.RaycastFilterType.Include, {course}, true
  local function standing()
   local hit = workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + .7), 0), params)
   return hit and hit.Instance
  end
  local report = {candidateId = "ER_P1_R01", part = pocket:GetFullName(), model = model.Name,
   durationRequired = duration, states = {}, samples = 0, maximumHorizontalDrift = 0, maximumVerticalDrift = 0,
   setup = "One initial placement at the authored fixed wait; actual runtime continues through a full cycle",
   limits = "One stationary avatar at the wait center; no edge, crowd or audible-human-listening proof"}
  local ok, failure = xpcall(function()
   root.Anchored = false
   root:SetNetworkOwner(nil)
   humanoid:Move(Vector3.zero, false)
   humanoid.Jump = false
   char:PivotTo(CFrame.new(pocket.Position + Vector3.new(0, pocket.Size.Y / 2 + humanoid.HipHeight + root.Size.Y / 2 + .15, 0)))
   root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
   local stableSince
   waitFor(function()
    if standing() == pocket and humanoid.FloorMaterial ~= Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y) < .1 then
     stableSince = stableSince or os.clock()
    else stableSince = nil end
    return stableSince and os.clock() - stableSince >= .25
   end, 2, "Fixed wait did not settle", guard)
   local initial = root.Position
   local before = services.ResultsService.GetPlayerResult(player).falls or 0
   local elapsed = assert(services.EggRushService.GetDiagnostics().elapsed)
   local wall = os.clock()
   repeat
    RunService.Heartbeat:Wait()
    guard()
    report.samples += 1
    report.states[assert(model:GetAttribute("ERState"))] = true
    local delta = root.Position - initial
    report.maximumHorizontalDrift = math.max(report.maximumHorizontalDrift, Vector3.new(delta.X, 0, delta.Z).Magnitude)
    report.maximumVerticalDrift = math.max(report.maximumVerticalDrift, math.abs(delta.Y))
    assert(standing() == pocket and humanoid.FloorMaterial ~= Enum.Material.Air, "Fixed wait lost actual support")
    assert((services.ResultsService.GetPlayerResult(player).falls or 0) == before, "Fixed wait triggered recovery")
    assert(report.maximumHorizontalDrift <= .1 and report.maximumVerticalDrift <= .1, "Fixed wait moved the standing avatar")
    report.elapsed = assert(services.EggRushService.GetDiagnostics().elapsed) - elapsed
    assert(os.clock() - wall < duration + 10, "Runtime clock stalled during wait")
   until report.elapsed >= duration + .05
   for _, state in {"Closed", "Warning", "Opening", "Open", "ClosingWarning", "Closing"} do
    assert(report.states[state], "Fixed wait missed actual state " .. state)
   end
  end, debug.traceback)
  if root.Parent then
   humanoid:Move(Vector3.zero, false)
   humanoid.Jump = false
   root:SetNetworkOwnershipAuto()
  end
  report.ok, report.failure = ok, if ok then nil else failure
  return report
 end
 results:GetAttributeChangedSignal("Command"):Connect(function()
  if busy then return end
  busy = true
  results:SetAttribute("State", "Running")
  task.spawn(function()
   local ok, value = xpcall(function()
    local command = Http:JSONDecode(assert(results:GetAttribute("Command")))
    results:SetAttribute("Job", command.job or command.action)
    if command.action == "Prepare" then return prepare()
    elseif command.action == "Traverse" or command.action == "Study" then
     local wholeRoute = command.action == "Study"
     if wholeRoute then prepare() end
     local course, player = inspection()
     local line = command.line or "Normal"
     assert(line == "Normal" or line == "Expert", "Unknown sample route")
     assert(services.CheckpointService.SetInspectionCheckpointForStudio(player, if wholeRoute then 0 else 2), "Inspection checkpoint setup failed")
     local traversal = require(script.Parent.Parent.NativeTraversal)
     local points = if wholeRoute then traversal.Points(course, line) else require(script.Parent.Sample).Points(course, line)
     local report = traversal.Run(course, player, points, {placeAtStart = true}, function(index, total, step)
      results:SetAttribute("Progress", Http:JSONEncode({index = index, total = total, step = step}))
     end)
     report.candidateId, report.phase, report.line = "ER_P1_R01", 1, line
     report.setup = if wholeRoute then "Fresh inspection race, checkpoint0 and initial start placement; one rough-study lap" else "CP2 inspection write and initial placement only; continuous sample movement after setup"
     report.scope = if wholeRoute then "Cheap whole-route movement/pacing study; no three-lap target or Phase2 acceptance proof" else "Finished Shellworks sample movement"
     return report
    elseif command.action == "Recovery" then return recovery(command.selection or "Both")
    elseif command.action == "Wait" then return fixedWait(command.selection or "Middle")
    elseif command.action == "State" then
     local player = game.Players:GetPlayers()[1]
     local course = services.CourseService.GetActiveCourse()
     return {candidateId = course and course:GetAttribute("CandidateId"), phase = course and course:GetAttribute("Phase"),
      course = services.CourseService.GetActiveCourseId(), maps = services.CourseService.GetDiscoveredCourseIds(),
      raceState = services.RaceService.GetRaceState(), ready = player and player:GetAttribute("OnboardingReady"),
      runtime = services.EggRushService.GetDiagnostics()}
    else error("Unknown Phase 1 check action") end
   end, debug.traceback)
   local passed = ok and (typeof(value) ~= "table" or value.ok ~= false)
   results:SetAttribute("Result", Http:JSONEncode({ok = passed, value = value, ownerApproval = false}))
   results:SetAttribute("State", if passed then "Complete" else "Failed")
   busy = false
  end)
 end)
 results:SetAttribute("State", "Ready")
 return results
end

return Checks
