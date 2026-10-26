--!nonstrict
local RunService, Players = game:GetService("RunService"), game:GetService("Players")
local ServerStorage, Workspace, Http = game:GetService("ServerStorage"), game:GetService("Workspace"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer(), "Native Studio server observer only")
assert(not ServerStorage:FindFirstChild("EggRushP2FlowReport"), "Preserve the earlier flow receipt")
local stored = Instance.new("StringValue")
stored.Name, stored.Parent = "EggRushP2FlowReport", ServerStorage
stored:SetAttribute("State", "Ready")
local services = {}
for _, name in {"CourseService", "RaceService", "PlayerRaceService", "StagingService", "CheckpointService", "ResultsService", "EggRushService"} do
 services[name] = require(game.ServerScriptService.Services[name])
end
local RaceConfig = require(game.ReplicatedStorage.Config.RaceConfig)
local CourseConfig = require(game.ReplicatedStorage.Config.CourseConfig)
local ForwardGate = require(game.ReplicatedStorage.Shared.ForwardGate)
local function vector(value) return {value.X, value.Y, value.Z} end
local function result(player)
 local value = services.ResultsService.GetPlayerResult(player)
 if not value then return nil end
 local laps, splits = {}, {}
 for index, seconds in value.lapTimes or {} do laps[index] = seconds end
 for _, split in value.checkpointSplits or {} do
  table.insert(splits, {lap = split.lap, checkpoint = split.checkpointIndex, elapsed = split.elapsedTime})
 end
 return {status = value.status, lap = value.currentLap, requiredLaps = value.requiredLaps,
  nextCheckpoint = value.nextCheckpointIndex, falls = value.falls or 0, finishTime = value.finishTime,
  lapTimes = laps, splits = splits}
end
local publication = 0
local function publish(report)
 local encoded = Http:JSONEncode(report)
 publication += 1
 local folder = Instance.new("Folder"); folder.Name = string.format("Payload_%03d", publication)
 local names, offset = {}, 1
 while offset <= #encoded do
  local last = math.min(offset + 149999, #encoded)
  while last < #encoded do local byte = string.byte(encoded, last + 1); if byte < 128 or byte > 191 then break end; last -= 1 end
  local chunk = Instance.new("StringValue"); chunk.Name = string.format("Chunk_%03d", #names + 1)
  chunk.Value = string.sub(encoded, offset, last); chunk.Parent = folder
  table.insert(names, chunk.Name); offset = last + 1
 end
 folder.Parent = stored
 stored.Value = Http:JSONEncode({format = "EggRushP2FlowChunksV1", payloadFolder = folder.Name, chunks = names,
  jsonBytes = #encoded, complete = report.complete, ok = report.ok, ownerApproval = false})
end
local function observe()
 local report = {test = "Supported Egg Rush entry, finish, lobby return and retry", ownerApproval = false, phase = 2,
  method = "Passive actual-service observer; no enrollment, readiness, checkpoint, movement, race-clock or geometry writes",
  transitions = {}, acknowledgements = {}, gates = {}, recoveries = {}, futureCheckpointTouches = {},
  coverage = {reverseGate = false, incompleteCheckpointForwardGate = false, futureCheckpointRejected = false, recovery = false},
  limits = {
   "Requires fresh ordinary solo Play, natural onboarding, existing client presentation and real supported client actions",
   "A server observer cannot prove a mouse click or detect every direct external server call; keep other inspection runners inactive",
   "Completion covers one three-lap finish and admission into one retry; remaining negative and recovery coverage is reported separately",
   "No human, twenty-racer, device, FPS or Phase 2 owner-acceptance claim",
  }}
 local connections, player, firstRaceId, finished, returned, broke, rejoined = {}, nil, nil, false, false, false, false
 local started, lastAt, previousKey, previousFrame = os.clock(), 0, nil, nil
 local observerFailure, complete, watchedCourse, launchObservedAt
 local function flow() return services.PlayerRaceService.GetFlowSnapshot(player) end
 local function snapshot()
  local current = flow()
  local course = services.CourseService.GetActiveCourse()
  local character = player.Character
  local humanoid = character and character:FindFirstChildOfClass("Humanoid")
  local root = character and character:FindFirstChild("HumanoidRootPart")
  local pen = course and course:FindFirstChild("StartPen")
  local gate = pen and pen:FindFirstChild("StartGate")
  return {seconds = os.clock() - started, raceId = current.raceId, state = current.state, status = current.status,
   enrolled = current.enrolled, entryOpen = current.entryOpen, courseId = current.courseId,
   official = services.PlayerRaceService.IsOfficialRacer(player), result = result(player),
   ready = player:GetAttribute("TournamentCourseReady"), onboardingReady = player:GetAttribute("OnboardingReady"),
   arrivalPhase = player:GetAttribute("ArrivalPhase"), preparationToken = current.preparation and current.preparation.token,
   delivered = current.status == "Queued" and services.StagingService.IsPlayerDelivered(player) or nil,
   gateClosed = gate and gate.CanCollide, position = root and vector(root.Position),
   walk = humanoid and humanoid.WalkSpeed, jumpHeight = humanoid and humanoid.JumpHeight,
   useJumpPower = humanoid and humanoid.UseJumpPower, colliderSize = character and character:FindFirstChild("CollisionPart")
    and vector(character.CollisionPart.Size), finishTicket = current.finishTicket}
 end
 local ok, failure = xpcall(function()
  assert(#Players:GetPlayers() == 1, "Use one actual client for this bounded ordinary-flow check")
  player = Players:GetPlayers()[1]
  assert(services.RaceService.GetRaceState() == "WaitingForPlayers" and not services.RaceService.IsInspectionUnlimitedTime()
   and not services.CourseService.IsInspectionMode() and services.CourseService.GetActiveCourse() == nil,
   "Start from fresh ordinary lobby Play, without a prepared inspection race")
  assert(services.CourseService.GetSelectedCourseId() == CourseConfig.ActiveCourseId, "A Studio course-selection override is present")
  local initial = flow()
  assert(initial.status == "Lobby" and not initial.enrolled and not services.PlayerRaceService.IsOfficialRacer(player), "Start unenrolled in the ordinary lobby")
  local eligible = false
  report.eligibleCourses = {}
  for _, info in services.CourseService.GetEligibleCourses() do
   table.insert(report.eligibleCourses, info.courseId)
   if info.courseId == "egg_rush_circuit" then eligible = true end
  end
  assert(eligible, "Egg Rush must be enabled in the normal eligible catalog before this test")
  report.initial = snapshot()
  table.insert(connections, game.ReplicatedStorage.Remotes.TournamentStageReady.OnServerEvent:Connect(function(sender, payload)
   if sender == player and typeof(payload) == "table" and #report.acknowledgements < 32 then
    table.insert(report.acknowledgements, {seconds = os.clock() - started, token = payload.token, step = payload.step,
     state = services.RaceService.GetRaceState(), status = services.PlayerRaceService.GetPlayerStatus(player)})
   end
  end))
  table.insert(connections, game.ReplicatedStorage.Remotes.RequestDevRaceState.OnServerEvent:Connect(function(sender)
   if sender == player then observerFailure = "Client developer race control used during ordinary-flow observation" end
  end))
  stored:SetAttribute("State", "Observing")
  local deadline = os.clock() + 720
  repeat
   local dt = RunService.Heartbeat:Wait()
   assert(not observerFailure, observerFailure)
   assert(player.Parent == Players, "Observed client left")
   assert(not services.RaceService.IsInspectionUnlimitedTime() and not services.CourseService.IsInspectionMode(), "Inspection mode/time was enabled")
   local current = flow()
   local course = services.CourseService.GetActiveCourse()
   local character = player.Character
   local root = character and character:FindFirstChild("HumanoidRootPart")
   if course and services.CourseService.GetActiveCourseId() == "egg_rush_circuit" then
    if watchedCourse ~= course then
     watchedCourse = course
     assert(course:GetAttribute("Phase") == 2 and course:GetAttribute("EROwned") == true
      and course:GetAttribute("FullBodyContacts") == true, "Expected the playable Phase 2 course with preserved body repair")
     assert(services.CourseService.GetRaceFormat() == "LapBased" and services.CourseService.GetLapCount() == 3
      and #services.CourseService.GetOrderedCheckpoints() == 4, "Expected actual three-lap/four-checkpoint contract")
     for _, checkpoint in services.CourseService.GetOrderedCheckpoints() do
      local trigger = checkpoint.part
      table.insert(connections, trigger.Touched:Connect(function(body)
       if not player.Character or not body:IsDescendantOf(player.Character) then return end
       local before = result(player)
       if before and checkpoint.index > before.nextCheckpoint and #report.futureCheckpointTouches < 16 then
        local receipt = {seconds = os.clock() - started, touched = checkpoint.index, before = before}
        table.insert(report.futureCheckpointTouches, receipt)
        task.delay(.15, function()
         if player.Parent ~= Players then return end
         receipt.after = result(player)
         receipt.rejected = receipt.after and receipt.after.lap == before.lap and receipt.after.nextCheckpoint == before.nextCheckpoint
         if receipt.rejected then report.coverage.futureCheckpointRejected = true else observerFailure = "Future checkpoint touch advanced progress" end
        end)
       end
      end))
     end
    end
    local finish = services.CourseService.GetFinishPart()
    assert(finish and finish:GetAttribute("RequireForwardCrossing") == true, "Actual finish must require continuous forward crossing")
    if previousFrame and previousFrame.character == character and previousFrame.raceId == current.raceId and root
     and current.status == "Racing" and (character:GetAttribute("RecoveryUntil") or 0) <= Workspace:GetServerTimeNow() then
     local forward = ForwardGate.Crossed(finish.CFrame, finish.Size, previousFrame.position, root.Position, dt)
     local backward = ForwardGate.Crossed(finish.CFrame, finish.Size, root.Position, previousFrame.position, dt)
     if forward or backward then
      local before = previousFrame.result
      local receipt = {seconds = os.clock() - started, direction = if forward then "Forward" else "Backward",
       from = vector(finish.CFrame:PointToObjectSpace(previousFrame.position)), to = vector(finish.CFrame:PointToObjectSpace(root.Position)),
       before = before, atCrossing = result(player)}
      table.insert(report.gates, receipt)
      if backward then report.coverage.reverseGate = true end
      if forward and before and before.nextCheckpoint <= 4 then report.coverage.incompleteCheckpointForwardGate = true end
      if before and (backward or (forward and before.nextCheckpoint <= 4)) then
       task.delay(.15, function()
        receipt.after = result(player)
        receipt.didNotAdvance = receipt.after and #receipt.after.lapTimes == #before.lapTimes and receipt.after.status ~= "Finished"
        if not receipt.didNotAdvance then observerFailure = "Rejected-direction/incomplete-checkpoint gate advanced the lap" end
       end)
      end
     end
    end
   end
   if root then previousFrame = {character = character, position = root.Position, raceId = current.raceId, result = result(player)} else previousFrame = nil end
   if os.clock() - lastAt < .1 then continue end
   lastAt = os.clock()
   local value = snapshot()
   local progress = value.result
   local key = table.concat({value.raceId, value.state, value.status, tostring(value.enrolled), tostring(value.ready),
    tostring(progress and progress.lap), tostring(progress and progress.nextCheckpoint), tostring(progress and progress.falls)}, ":")
   if key ~= previousKey then table.insert(report.transitions, value); previousKey = key; publish(report) end
   stored:SetAttribute("Progress", value.state .. "/" .. value.status .. "/" .. tostring(progress and progress.lap))
   if value.state == "Countdown" and value.courseId == "egg_rush_circuit" then
    assert(value.status == "Queued" and value.ready == true and value.delivered == true and value.gateClosed == true,
     "Countdown admission did not retain real readiness, support and closed start gate")
    report.countdownObserved = true
   end
   if not firstRaceId and value.state == "Racing" and value.status == "Racing" and value.courseId == "egg_rush_circuit" then
    assert(report.countdownObserved and value.official and value.gateClosed == false, "Ordinary launch admission/gate invalid")
    launchObservedAt = launchObservedAt or os.clock()
    if value.walk == 16 and value.useJumpPower == false and math.abs(value.jumpHeight - 7.2) < .01
     and services.EggRushService.GetDiagnostics().bound == true then
     firstRaceId, report.firstRaceId, report.launch = value.raceId, value.raceId, value
     report.profileBindingSeconds = os.clock() - launchObservedAt
    else assert(os.clock() - launchObservedAt < 2, "Actual Egg Rush runtime/profile did not bind after ordinary launch") end
   end
   if firstRaceId and value.raceId == firstRaceId and progress then
    if progress.falls > 0 and (#report.recoveries == 0 or report.recoveries[#report.recoveries].falls ~= progress.falls) then
     local expected = services.CheckpointService.GetCheckpointRespawnCFrame(player)
     table.insert(report.recoveries, {falls = progress.falls, seconds = value.seconds, lap = progress.lap,
      nextCheckpoint = progress.nextCheckpoint, expectedPosition = expected and vector(expected.Position), actualPosition = value.position})
     report.coverage.recovery = true
    end
    if progress.status == "Finished" and not finished then
     assert(#progress.lapTimes == 3 and #progress.splits == 12 and progress.finishTime and value.finishTicket
      and value.finishTicket.official == true, "Finish lacks real three-lap/checkpoint/official ticket receipts")
     local seen = {}
     for _, split in progress.splits do seen[tostring(split.lap) .. ":" .. tostring(split.checkpoint)] = true end
     for lap = 1, 3 do for checkpoint = 1, 4 do assert(seen[lap .. ":" .. checkpoint], "Missing ordered checkpoint receipt") end end
     finished, report.finish = true, value
    end
   end
   if finished and value.status == "Lobby" then
    local lobby = Workspace:FindFirstChild(RaceConfig.LobbyModelName)
    local marker = lobby and (lobby:FindFirstChild(RaceConfig.LobbySpawnMarkerName) or lobby:FindFirstChild(RaceConfig.LobbyFallbackPartName))
    if root and marker and (root.Position - marker.Position).Magnitude <= math.max(30, marker.Size.Magnitude / 2 + 10) then
     if not returned then report.lobbyReturn = value end
     returned = true
    end
    if returned and not value.enrolled then broke, report.breakObserved = true, value end
   end
   if broke and value.enrolled then rejoined = true end
   if finished and returned and broke and rejoined and value.state == "Racing" and value.status == "Racing"
    and value.raceId ~= firstRaceId and value.courseId == "egg_rush_circuit" then
    assert(value.official and value.ready == true and value.gateClosed == false, "Retry was not ordinarily admitted")
    report.retryLaunch, complete = value, true
   end
  until complete or os.clock() >= deadline
  assert(complete, "Ordinary entry/finish/return/break/rejoin/retry sequence did not complete within 720 seconds")
  report.complete = true
 end, debug.traceback)
 for _, connection in connections do connection:Disconnect() end
 report.ok, report.failure, report.seconds = ok, if ok then nil else failure, os.clock() - started
 report.pendingCoverage = {}
 for name, covered in report.coverage do if not covered then table.insert(report.pendingCoverage, name) end end
 publish(report); stored:SetAttribute("State", if ok then "Complete" else "Failed")
end
stored.Value = Http:JSONEncode({state = "Ready", command = {action = "Observe"}, ownerApproval = false,
 setup = "Fresh ordinary solo Play, playable Phase2 Egg Rush catalog entry; no inspection presets/selection/start/readiness helpers"})
local used = false
stored:GetAttributeChangedSignal("Command"):Connect(function()
 if used then return end
 local parsed, command = pcall(function() return Http:JSONDecode(stored:GetAttribute("Command")) end)
 if not parsed or typeof(command) ~= "table" or command.action ~= "Observe" then return end
 used = true; task.spawn(observe)
end)
