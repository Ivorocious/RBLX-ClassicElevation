--!nonstrict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

assert(RunService:IsStudio() and RunService:IsServer(), "Native Studio server waits only")
assert(not ServerStorage:FindFirstChild("R01WaitReport"), "A wait report already exists")
local stored = Instance.new("StringValue")
stored.Name = "R01WaitReport"
stored:SetAttribute("State", "Preparing")
stored.Parent = ServerStorage
local report = {candidateId = "ER_P1_R01", cases = {}, setups = {}, ownerApproval = false,
 method = "Sequential actual-runtime Fork and Middle center waits with a settled physical baseline",
 settlePolicy = "Actual pocket support, non-Air floor and absolute vertical velocity below .1 sustained for .25 seconds",
 driftLimits = {horizontal = .1, vertical = .1},
 limits = "Initial setup placements only. Center-standing support and drift through one full cycle; no edge, passing, crowd, human-audibility or owner-acceptance proof."}
local root, humanoid, control, originalOwner, originalAuto
local ownershipSaved = false
local ok, failure = xpcall(function()
 local services = {}
 for _, name in {"CourseService", "RaceService", "PlayerRaceService", "ResultsService", "EggRushService"} do
  services[name] = require(game.ServerScriptService.Services[name])
 end
 local course = assert(services.CourseService.GetActiveCourse(), "No active course")
 assert(course:GetAttribute("CandidateId") == "ER_P1_R01" and course:GetAttribute("Phase") == 1
  and course:GetAttribute("SampleRevision") == 2, "Wrong active R01 sample revision")
 local player = assert(Players:GetPlayers()[1])
 local character = assert(player.Character)
 root, humanoid = character.HumanoidRootPart, assert(character:FindFirstChildOfClass("Humanoid"))
 local raceId = services.RaceService.GetCurrentRaceId()
 local function guard()
  assert(player.Character == character and root.Parent and humanoid.Health > 0, "Wait character changed or died")
  assert(services.CourseService.GetActiveCourse() == course and services.RaceService.IsRaceActive()
   and services.RaceService.GetCurrentRaceId() == raceId, "Wait race changed")
  assert(services.PlayerRaceService.IsOfficialRacer(player) and services.PlayerRaceService.GetPlayerStatus(player) == "Racing", "Wait player is not an official racing inspector")
 end
 guard()
 assert(not root.Anchored and humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower
  and math.abs(humanoid.JumpHeight - 7.2) < .01, "Wrong actual movement profile")
 assert(services.EggRushService.GetDiagnostics().bound == true, "Actual runtime is not bound")
 originalOwner, originalAuto = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto()
 ownershipSaved = true
 root:SetNetworkOwner(nil)
 report.raceId, report.userId = raceId, player.UserId
 report.movement = {walk = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight,
  useJumpPower = humanoid.UseJumpPower, maxSlopeAngle = humanoid.MaxSlopeAngle}
 local params = RaycastParams.new()
 params.FilterType, params.FilterDescendantsInstances, params.RespectCanCollide = Enum.RaycastFilterType.Include, {course}, true
 local function standing()
  local hit = Workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + .7), 0), params)
  return hit and hit.Instance
 end
 local function vector(value) return {value.X, value.Y, value.Z} end
 control = RunService.PreSimulation:Connect(function()
  if humanoid.Parent then humanoid:Move(Vector3.zero, false); humanoid.Jump = false end
 end)
 local function fixedWait(selection)
  guard()
  local pocket = course.Obstacles[if selection == "Fork" then "Shell_ForkWait" else "Shell_MiddleWait"]
  local model = course.Obstacles.Mechanisms[if selection == "Fork" then "ShellLip1" else "ShellLip3"]
  local duration = model:GetAttribute("ClosedSeconds") + model:GetAttribute("WarningSeconds")
   + 2 * model:GetAttribute("MoveSeconds") + model:GetAttribute("OpenSeconds") + model:GetAttribute("ClosingWarningSeconds")
  local result = {selection = selection, part = pocket:GetFullName(), model = model.Name, durationRequired = duration,
   states = {}, samples = 0, maximumHorizontalDrift = 0, maximumVerticalDrift = 0}
  table.insert(report.cases, result)
  stored:SetAttribute("Case", selection)
  stored:SetAttribute("Progress", "Settling")
  local caseOk, caseFailure = xpcall(function()
   local target = pocket.Position + Vector3.new(0, pocket.Size.Y / 2 + humanoid.HipHeight + root.Size.Y / 2 + .15, 0)
   table.insert(report.setups, {kind = "InitialWaitPlacement", selection = selection, position = vector(target), surface = pocket:GetFullName()})
   humanoid:Move(Vector3.zero, false)
   humanoid.Jump = false
   character:PivotTo(CFrame.new(target))
   root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
   local settleStarted, stableSince = os.clock(), nil
   repeat
    RunService.Heartbeat:Wait()
    guard()
    if standing() == pocket and humanoid.FloorMaterial ~= Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y) < .1 then
     stableSince = stableSince or os.clock()
    else stableSince = nil end
    if stableSince and os.clock() - stableSince >= .25 then break end
   until os.clock() - settleStarted >= 2
   assert(stableSince and os.clock() - stableSince >= .25, "Fixed wait did not establish a settled baseline")
   result.settleSeconds, result.baselineVelocityY = os.clock() - settleStarted, root.AssemblyLinearVelocity.Y
   local initial = root.Position
   result.baselinePosition = vector(initial)
   local before = assert(services.ResultsService.GetPlayerResult(player)).falls or 0
   local elapsed = assert(services.EggRushService.GetDiagnostics().elapsed)
   local wall = os.clock()
   stored:SetAttribute("Progress", "ObservingFullCycle")
   repeat
    RunService.Heartbeat:Wait()
    guard()
    result.samples += 1
    result.states[assert(model:GetAttribute("ERState"))] = true
    local delta = root.Position - initial
    result.maximumHorizontalDrift = math.max(result.maximumHorizontalDrift, Vector3.new(delta.X, 0, delta.Z).Magnitude)
    result.maximumVerticalDrift = math.max(result.maximumVerticalDrift, math.abs(delta.Y))
    assert(standing() == pocket and humanoid.FloorMaterial ~= Enum.Material.Air, "Fixed wait lost actual support")
    assert((services.ResultsService.GetPlayerResult(player).falls or 0) == before, "Fixed wait triggered recovery")
    assert(result.maximumHorizontalDrift <= .1 and result.maximumVerticalDrift <= .1, "Fixed wait moved the standing avatar")
    result.elapsed = assert(services.EggRushService.GetDiagnostics().elapsed) - elapsed
    assert(os.clock() - wall < duration + 10, "Runtime clock stalled during wait")
   until result.elapsed >= duration + .05
   result.finalPosition, result.finalVelocityY = vector(root.Position), root.AssemblyLinearVelocity.Y
   result.actualSupport, result.floor = standing() and standing():GetFullName(), humanoid.FloorMaterial.Name
   for _, state in {"Closed", "Warning", "Opening", "Open", "ClosingWarning", "Closing"} do
    assert(result.states[state], "Fixed wait missed actual state " .. state)
   end
  end, debug.traceback)
  result.ok, result.failure = caseOk, if caseOk then nil else tostring(caseFailure)
  stored:SetAttribute("Progress", if caseOk then "Passed" else "Failed")
 end
 stored:SetAttribute("State", "Running")
 fixedWait("Fork")
 guard()
 fixedWait("Middle")
end, debug.traceback)

if control then control:Disconnect() end
if humanoid and humanoid.Parent then humanoid:Move(Vector3.zero, false); humanoid.Jump = false end
if ownershipSaved and root and root.Parent then
 local restored, restoreFailure = pcall(function()
  if originalAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(originalOwner) end
 end)
 report.ownershipRestored = restored
 if not restored then report.ownershipFailure = tostring(restoreFailure) end
end
report.complete, report.failure = ok and #report.cases == 2, if ok then nil else tostring(failure)
report.ok = report.complete
for _, result in report.cases do if not result.ok then report.ok = false end end
stored.Value = Http:JSONEncode(report)
stored:SetAttribute("State", if report.ok then "Complete" elseif report.complete then "Failed" else "Inconclusive")
