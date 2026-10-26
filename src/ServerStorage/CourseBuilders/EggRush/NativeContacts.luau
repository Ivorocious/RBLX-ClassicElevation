--!nonstrict
local Check = {}
local RunService = game:GetService("RunService")
local function vector(p) return { p.X, p.Y, p.Z } end

function Check.Run(services, options)
 assert(RunService:IsStudio() and RunService:IsServer(), "Studio server contact checks only")
 options = options or {}
 local only = options.only or "All"
 assert(table.find({ "All", "New", "Legacy", "Eggs", "Tail", "TailWait" }, only), "Unknown contact check selection")
 local player = assert(game.Players:GetPlayers()[1], "Missing test player")
 local char = assert(player.Character)
 local root, humanoid = char.HumanoidRootPart, assert(char:FindFirstChildOfClass("Humanoid"))
 local course = assert(services.CourseService.GetActiveCourse())
 assert(course:GetAttribute("CourseId") == "egg_rush_circuit" and course:GetAttribute("EROwned") == true, "Wrong course")
 assert(services.RaceService.IsRaceActive() and services.PlayerRaceService.IsOfficialRacer(player)
  and services.PlayerRaceService.GetPlayerStatus(player) == "Racing", "Prepare an official owned race")
 local raceId = services.RaceService.GetCurrentRaceId()
 local profile = { walk = humanoid.WalkSpeed, jump = humanoid.JumpHeight, usePower = humanoid.UseJumpPower, gravity = workspace.Gravity }
 assert(profile.walk == 16 and not profile.usePower and math.abs(profile.jump - 7.2) < .01
  and math.abs(profile.gravity - 196.2) < .01, "Wrong actual movement profile")
 local results, setups = {}, {}
 local function clock()
  return assert(services.EggRushService.GetDiagnostics().elapsed, "Egg Rush runtime unbound")
 end
 local function valid()
  assert(player.Character == char and root.Parent and humanoid.Health > 0, "Test character changed or died")
  assert(services.CourseService.GetActiveCourse() == course and services.RaceService.IsRaceActive()
   and services.RaceService.GetCurrentRaceId() == raceId, "Race changed during check")
 end
 local function falls()
  return assert(services.ResultsService.GetPlayerResult(player), "Missing official result").falls or 0
 end
 local function waitFor(predicate, seconds, message)
  local stop = os.clock() + seconds
  repeat
   RunService.Heartbeat:Wait()
   valid()
   if predicate() then return end
  until os.clock() > stop
  error(message)
 end
 local function pause(seconds)
  local start = os.clock()
  waitFor(function() return os.clock() - start >= seconds end, seconds + 2, "Settling timed out")
 end
 local function place(position, purpose, part)
  valid()
  root.Anchored = false
  root:SetNetworkOwner(nil)
  humanoid:Move(Vector3.zero, false)
  humanoid.Jump = false
  table.insert(setups, { kind = "Teleport", purpose = purpose, target = part and part:GetFullName(), position = vector(position), clock = clock() })
  char:PivotTo(CFrame.new(position))
  root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
 end
 local function on(part, purpose, offset)
  place(part.Position + Vector3.new(0, part.Size.Y / 2 + humanoid.HipHeight + root.Size.Y / 2 + .15, 0)
   +part.CFrame:VectorToWorldSpace(offset or Vector3.zero), purpose, part)
 end
 local params = RaycastParams.new()
 params.FilterType = Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances = { course }
 params.RespectCanCollide = true
 local function standing()
  local hit = workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + .7), 0), params)
  return hit and hit.Instance
 end
 local function checkpoint(index)
  assert(services.CheckpointService.SetInspectionCheckpointForStudio(player, index), "Inspection checkpoint setup failed")
  table.insert(setups, { kind = "InspectionCheckpoint", checkpoint = index, clock = clock() })
  on(course.Obstacles["CP" .. index .. "_Pocket"], "Safe setup before isolated contact")
  pause(1.65)
  assert((char:GetAttribute("RecoveryUntil") or 0) <= workspace:GetServerTimeNow(), "Contact setup remains immune")
  assert(services.CheckpointService.GetLatestCheckpointIndex(player) == index, "Wrong setup checkpoint")
 end
 local function contactPart(model)
  local candidates = {}
  for _, part in ipairs(model:GetDescendants()) do
   if part:IsA("BasePart") and part:GetAttribute("ERLethal") == true and part.Transparency < 1 then
    assert(part.CanQuery and not part.CanCollide, "Contact must be visible, queryable and noncolliding")
    table.insert(candidates, part)
   end
  end
  table.sort(candidates, function(a, b) return a:GetFullName() < b:GetFullName() end)
  return assert(candidates[1], "No actual visible lethal contact in " .. model.Name)
 end
 local function recoverOnce(key, part, index, model)
  assert(part.Transparency < 1 and part.CanQuery and part:GetAttribute("ERLethal") == true, "Hidden or invalid contact")
  local before = falls()
  local result = services.ResultsService.GetPlayerResult(player)
  local lap, nextCheckpoint = result.currentLap, result.nextCheckpointIndex
  local receipt = { target = part:GetFullName(), stateAtContact = model and model:GetAttribute("ERState"), clock = clock(),
   position = vector(part.Position), size = vector(part.Size), transparency = part.Transparency, checkpoint = index }
  results[key] = receipt
  -- Root is excluded by gameplay; placing the avatar here overlaps its visible torso/limbs with the actual part.
  place(part.Position, "Deliberate visible contact: " .. key, part)
  waitFor(function() return falls() > before end, 2, key .. " visible contact did not recover")
  local expected = assert(services.CheckpointService.GetCheckpointRespawnCFrame(player))
  waitFor(function() return (root.Position - expected.Position).Magnitude < 3 end, 2, key .. " missed authored recovery pocket")
  pause(1.65)
  receipt.recoveries = falls() - before
  receipt.latestCheckpoint = services.CheckpointService.GetLatestCheckpointIndex(player)
  receipt.recoveryError = (root.Position - expected.Position).Magnitude
  receipt.root = vector(root.Position)
  assert(receipt.recoveries == 1, key .. " must recover exactly once, including after cooldown")
  assert(receipt.latestCheckpoint == index and receipt.recoveryError < 3, key .. " lost checkpoint or recovery position")
  result = services.ResultsService.GetPlayerResult(player)
  assert(result.currentLap == lap and result.nextCheckpointIndex == nextCheckpoint, key .. " changed race progress")
 end
 local function fixedWait(key, part, model, duration, horizontalLimit, offset)
  on(part, "Full-cycle fixed-wait setup: " .. key, offset)
  pause(.3)
  assert(standing() == part and humanoid.FloorMaterial ~= Enum.Material.Air, "Fixed wait setup missed support")
  local before, initial, started, wall = falls(), root.Position, clock(), os.clock()
  local receipt = { durationRequired = duration, states = {}, maximumHorizontalDrift = 0, maximumVerticalDrift = 0, samples = 0,
   part = part:GetFullName(), model = model.Name, startClock = started }
  results[key] = receipt
  repeat
   RunService.Heartbeat:Wait()
   valid()
   local state = assert(model:GetAttribute("ERState"), "Missing actual mechanism state")
   receipt.states[state] = true
   receipt.samples += 1
   local delta = root.Position - initial
   receipt.maximumHorizontalDrift = math.max(receipt.maximumHorizontalDrift, Vector3.new(delta.X, 0, delta.Z).Magnitude)
   receipt.maximumVerticalDrift = math.max(receipt.maximumVerticalDrift, math.abs(delta.Y))
   receipt.recoveries = falls() - before
   assert(receipt.recoveries == 0, key .. " triggered recovery")
   assert(standing() == part and humanoid.FloorMaterial ~= Enum.Material.Air, key .. " lost fixed support")
   assert(receipt.maximumHorizontalDrift <= horizontalLimit and receipt.maximumVerticalDrift < .1, key .. " moved the standing avatar")
   assert(os.clock() - wall < duration + 10, key .. " runtime clock stalled")
  until clock() - started >= duration + .05
  receipt.elapsed = clock() - started
  receipt.wallSeconds = os.clock() - wall
  local count = 0
  for _ in pairs(receipt.states) do count += 1 end
  receipt.stateCount = count
  assert(count == 6, key .. " did not observe all six actual states")
 end
 local ok, failure = xpcall(function()
  clock()
  if only == "All" or only == "Legacy" then
   checkpoint(2)
   recoverOnce("red", course.Obstacles.Shellworks_RedHop, 2)
   fixedWait("middleWait", course.Obstacles.Shell_MiddleWait, course.Obstacles.Mechanisms.ShellLip3, 14, 1)
  end
  if only == "All" or only == "New" or only == "Eggs" then
   for band = 1, 2 do
    checkpoint(1)
    local model = course.Obstacles.Mechanisms["EggBand" .. band]
    local clear = model:GetAttribute("RestSeconds") + model:GetAttribute("WarningSeconds")
    local cycle = clear + model:GetAttribute("MoveSeconds")
    waitFor(function()
     local t = (clock() + (model:GetAttribute("PhaseSeconds") or 0)) % cycle
     return model:GetAttribute("ERState") == "Rolling" and t >= clear + .1 and t < cycle - 1
    end, cycle + 3, model.Name .. " did not offer a visible rolling contact")
    recoverOnce(model.Name, contactPart(model), 1, model)
   end
  end
  local tail = course.Obstacles.Mechanisms.GuardianTail
  if only == "All" or only == "New" or only == "Tail" then
   checkpoint(3)
   local rest = tail:GetAttribute("RestSeconds")
   local cycle = rest + tail:GetAttribute("WarningSeconds") + 2 * tail:GetAttribute("MoveSeconds")
    + tail:GetAttribute("FarWaitSeconds") + tail:GetAttribute("ClosingWarningSeconds")
   waitFor(function()
    local t = (clock() + (tail:GetAttribute("PhaseSeconds") or 0)) % cycle
    return tail:GetAttribute("ERState") == "Rest" and t < rest - 1
   end, cycle + 3, "Tail did not offer a resting visible contact")
   recoverOnce("tailRest", contactPart(tail), 3, tail)
   if options.moving then
    for _,case in ipairs({{state="Sweeping",key="tailSweep",start=rest+tail:GetAttribute("WarningSeconds")},
     {state="Returning",key="tailReturn",start=cycle-tail:GetAttribute("MoveSeconds")}})do
     checkpoint(3)
     waitFor(function()
      local t=(clock()+(tail:GetAttribute("PhaseSeconds")or 0))%cycle
      return tail:GetAttribute("ERState")==case.state and t>case.start+.15 and t<case.start+tail:GetAttribute("MoveSeconds")-.5
     end,cycle+3,"Missing moving tail contact window")
     recoverOnce(case.key,contactPart(tail),3,tail)
    end
   end
  end
  if only == "All" or only == "New" or only == "Tail" or only == "TailWait" then
   checkpoint(3)
   local cycle = tail:GetAttribute("RestSeconds") + tail:GetAttribute("WarningSeconds") + 2 * tail:GetAttribute("MoveSeconds")
    + tail:GetAttribute("FarWaitSeconds") + tail:GetAttribute("ClosingWarningSeconds")
   assert(math.abs(cycle - 12.5) < .001, "Tail cycle changed; review focused check")
   fixedWait("tailSafeWait", course.Obstacles.Tail_SafeWait, tail, cycle, .05)
   if options.edges then
    local p=course.Obstacles.Tail_SafeWait
    for _,x in ipairs({-1,1})do for _,z in ipairs({-1,1})do
     fixedWait("tailSafeEdge"..x.."_"..z,p,tail,cycle,.05,
      Vector3.new(x*(p.Size.X/2-1.1),0,z*(p.Size.Z/2-1.1)))
    end end
   end
   assert(services.CheckpointService.GetLatestCheckpointIndex(player) == 3, "Tail wait changed CP3 progress")
  end
 end, debug.traceback)
 if root.Parent then humanoid:Move(Vector3.zero, false); humanoid.Jump = false; root:SetNetworkOwnershipAuto() end
 return { ok = ok, failure = if ok then nil else failure, selection = only, profile = profile, raceId = raceId, checks = results, setups = setups,
  limits = "Isolated scripted contacts use the listed inspection checkpoint writes and setup teleports. Hazards and recovery remain unchanged. Fixed waits use the actual runtime clock and support; drift is measured, with .05-stud horizontal tolerance on Tail_SafeWait. No route, human, crowd, device or audio-audibility proof." }
end
return Check
