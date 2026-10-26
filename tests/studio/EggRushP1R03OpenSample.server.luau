--!nonstrict
local RunService, Storage, Workspace = game:GetService("RunService"), game:GetService("ServerStorage"), game:GetService("Workspace")
local Http, Players = game:GetService("HttpService"), game:GetService("Players")
assert(RunService:IsStudio() and RunService:IsServer(), "Native Studio server only")
local line = script:GetAttribute("Line") or "Normal"
assert(line == "Normal" or line == "Expert", "Line must be Normal or Expert")
local scope = script:GetAttribute("Scope") or "Sample"
assert(scope == "Sample" or scope == "Study", "Unknown traversal scope")
local name = (if scope == "Study" then "R03Study" else "R03OpenSample") .. line
assert(not Storage:FindFirstChild(name), "Preserve the existing report before another execution")
local result = Instance.new("StringValue"); result.Name = name; result:SetAttribute("State", "Running"); result.Parent = Storage
local quality = {frames = 0, overlapFrames = 0, peakPairs = 0, maximumConsecutiveOverlapFrames = 0, pairs = {}, samples = {}, shellContacts = {}}
local report = {candidateId = "ER_P1_R01", sampleRevision = 3, line = line, scope = scope, quality = quality, ownerApproval = false,
 setup = "CP2 inspection checkpoint write and driver placeAtStart only; continuous ordinary movement through the sample and first S4 landing",
 limits = "Traversal and passive overlap observations are separate evidence; no human, crowd, all-avatar, three-lap target or FPS acceptance"}
local observer, root, savedOwner, savedAuto, ownershipSaved
local function stopObserver() if observer then observer:Disconnect(); observer = nil end end
local function vector(v) return {v.X, v.Y, v.Z} end
local function snapshot(p) return {path = p:GetFullName(), size = vector(p.Size), frame = {p.CFrame:GetComponents()}, canCollide = p.CanCollide, canQuery = p.CanQuery} end
local ok, failure = xpcall(function()
 local services = {}
 for _, service in {"CourseService", "RaceService", "PlayerRaceService", "CheckpointService", "EggRushService"} do services[service] = require(game.ServerScriptService.Services[service]) end
 local course = assert(services.CourseService.GetActiveCourse(), "No active course")
 assert(course:GetAttribute("CandidateId") == "ER_P1_R01" and course:GetAttribute("Phase") == 1
  and course:GetAttribute("SampleRevision") == 3 and course:GetAttribute("FullBodyContacts") == true, "Wrong full-contact R03 course")
 local player = assert(Players:GetPlayers()[1], "No inspector")
 local character = assert(player.Character); root = assert(character:FindFirstChild("HumanoidRootPart"))
 local humanoid = assert(character:FindFirstChildOfClass("Humanoid")); local collider = assert(character:FindFirstChild("CollisionPart"), "Missing fitted CollisionPart")
 local raceId = services.RaceService.GetCurrentRaceId()
 local function guard()
  local valid = not quality.observerError and player.Character == character and humanoid.Health > 0 and root.Parent
   and services.CourseService.GetActiveCourse() == course and services.RaceService.IsRaceActive()
   and services.RaceService.GetCurrentRaceId() == raceId and services.PlayerRaceService.IsOfficialRacer(player)
   and services.PlayerRaceService.GetPlayerStatus(player) == "Racing"
  if not valid then stopObserver() end
  return valid
 end
 assert(guard() and services.EggRushService.GetDiagnostics().bound == true, "Prepare the actual official R03 inspection race first")
 assert(collider:IsA("BasePart") and collider.CanCollide, "Fitted CollisionPart must be physically enabled")
 savedOwner, savedAuto, ownershipSaved = root:GetNetworkOwner(), root:GetNetworkOwnershipAuto(), true
 report.raceId, report.userId = raceId, player.UserId
 report.movement = {walk = humanoid.WalkSpeed, jump = humanoid.JumpHeight, maxSlopeAngle = humanoid.MaxSlopeAngle}
 quality.actualCollisionPartInitial = snapshot(collider)
 local bodies, shells = {}, {}
 for _, bodyName in {"Head", "UpperTorso", "LowerTorso"} do table.insert(bodies, (assert(character:FindFirstChild(bodyName), "R15 body required"))) end
 quality.bodyInitial = {}; for _, body in bodies do table.insert(quality.bodyInitial, snapshot(body)) end
 for _, model in course.Obstacles.Mechanisms:GetChildren() do
  if model:GetAttribute("ERMechanism") ~= "ShellLip" then continue end
  table.insert(shells, model); local count = 0
  for _, p in model:GetDescendants() do
   if p:IsA("BasePart") and p:GetAttribute("ERSupport") == true then
    count += 1; table.insert(quality.shellContacts, snapshot(p)); assert(p.CanCollide, "Moving shell support collision disabled")
   end
  end
  assert(count == 8, "Each R03 shell needs its eight physical volumes")
 end
 assert(#shells == 9, "Expected four Normal and five Crown shells")
 local params = OverlapParams.new(); params.FilterType = Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances = shells; params.RespectCanCollide = true
 local started, consecutive = os.clock(), 0
 observer = RunService.Heartbeat:Connect(function()
  local observed, message = xpcall(function()
   quality.frames += 1; local hits = 0
   for _, body in bodies do for _, contact in Workspace:GetPartsInPart(body, params) do
    if not contact.CanCollide or contact:GetAttribute("ERSupport") ~= true then continue end
    hits += 1; local key = body:GetFullName() .. " -> " .. contact:GetFullName()
    quality.pairs[key] = (quality.pairs[key] or 0) + 1
    if #quality.samples < 32 then table.insert(quality.samples, {seconds = os.clock() - started, body = snapshot(body), contact = snapshot(contact), actualCollisionPart = snapshot(collider), state = contact.Parent:GetAttribute("ERState")}) end
   end end
   consecutive = if hits > 0 then consecutive + 1 else 0
   if hits > 0 then quality.overlapFrames += 1 end
   quality.peakPairs = math.max(quality.peakPairs, hits)
   quality.maximumConsecutiveOverlapFrames = math.max(quality.maximumConsecutiveOverlapFrames, consecutive)
  end, debug.traceback)
  if not observed then quality.observerError = message; stopObserver() end
 end)
 assert(services.CheckpointService.SetInspectionCheckpointForStudio(player, if scope == "Study" then 0 else 2), "Inspection checkpoint write failed")
 local points = if scope == "Study" then require(Storage.CourseBuilders.EggRush.NativeTraversal).Points(course, line)
  else require(Storage.CourseBuilders.EggRush.RestartR01.Sample).Points(course, line)
 if scope == "Sample" then table.insert(points, {part = assert(course.Routes.S4_IncubatorApproach["001"].Value)}) end
 if scope == "Study" then report.setup = "Inspection checkpoint0 write and initial start placement only; one complete rough lap, including the revised sample and S4 join" end
 report.traversal = require(Storage.CourseBuilders.EggRush.NativeTraversal).Run(course, player, points, {placeAtStart = true, guard = guard,
  pace = script:GetAttribute("Pace") == true,
  afterLanding = function(index) if index == #points then stopObserver() end end})
 stopObserver(); quality.actualCollisionPartFinal = snapshot(collider)
 quality.bodyFinal = {}; for _, body in bodies do table.insert(quality.bodyFinal, snapshot(body)) end
end, debug.traceback)
stopObserver()
if ownershipSaved and root and root.Parent then
 local restored, message = pcall(function() if savedAuto then root:SetNetworkOwnershipAuto() else root:SetNetworkOwner(savedOwner) end end)
 report.ownershipRestored = restored; if not restored then report.ownershipRestoreError = tostring(message) end
end
report.ok = ok and report.traversal ~= nil and report.traversal.ok == true and not quality.observerError and report.ownershipRestored == true
report.failure = if not ok then failure else nil
quality.interpretation = if quality.overlapFrames > 0 then "Observed body/shell overlap requires review; traversal success does not clear clipping" else "No body/shell overlap observed in sampled Heartbeats; no universal clipping exclusion"
result.Value = Http:JSONEncode(report)
result:SetAttribute("State", if report.ok then "Complete" else "Failed")
