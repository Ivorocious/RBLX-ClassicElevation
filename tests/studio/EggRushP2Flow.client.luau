--!nonstrict
local RunService, Players = game:GetService("RunService"), game:GetService("Players")
local Http, ReplicatedStorage = game:GetService("HttpService"), game:GetService("ReplicatedStorage")
assert(RunService:IsStudio() and RunService:IsClient(), "Native Studio LocalScript only")
local player = Players.LocalPlayer
local flowModule = player:WaitForChild("PlayerScripts"):WaitForChild("Controllers"):WaitForChild("RaceFlowController")
local Flow = require(flowModule)
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local stored = Instance.new("StringValue")
stored.Name, stored.Parent = "EggRushP2FlowClientReport", script
local report = {ownerApproval = false, actions = {}, entries = {}, flowModulePath = flowModule:GetFullName(),
 flowInitialization = "Existing Client -> RaceUiController.Init -> cached RaceFlowController.Init; helper never calls Init",
 method = "Existing client race-button action router plus supported ballot RemoteFunction; existing presentation sends all readiness acknowledgements",
 limits = "No synthetic camera/readiness flags, onboarding preset, avatar movement, checkpoint writes or literal mouse-click proof"}
local tournament, busy, sequence = nil, false, 0
local arrivalConnections = {}
local connection = remotes.TournamentChanged.OnClientEvent:Connect(function(value) tournament = value end)
local function waitFor(predicate, seconds, message)
 local deadline = os.clock() + seconds
 repeat
  if predicate() then return end
  RunService.Heartbeat:Wait()
 until os.clock() >= deadline
 error(message)
end
local function ready()
 return player:GetAttribute("OnboardingReady") == true and player:GetAttribute("ArrivalPhase") == "Ready"
  and player:GetAttribute("ArrivalOpen") ~= true and Flow.IsAvailable() and typeof(Flow.Activate) == "function"
end
local function action(name)
 assert(ready(), "Complete the real arrival flow and initialize the existing UI first")
 table.insert(report.actions, {action = name, serverTime = workspace:GetServerTimeNow(), raceId = Flow.GetState().raceId})
 Flow.Activate(name)
end
local function arrival(command)
 local remote = assert(remotes:WaitForChild("ArrivalControl", 15), "Existing ArrivalControl was not created")
 local changed = assert(remotes:WaitForChild("ArrivalChanged", 15), "Existing ArrivalChanged was not created")
 local mode = command.mode or "Custom"
 assert(mode == "Avatar" or mode == "Custom", "Arrival mode must be Avatar or Custom")
 local receipt = {mode = mode, states = {}, localTransitions = {}, operationId = Http:GenerateGUID(false),
  method = "Ordinary Save confirmation payload; existing OnboardingController handles ArrivalChanged and sends the natural Arrived acknowledgment",
  studioStorage = "Existing Studio onboarding uses session.profile rather than DataStore writes",
  choice = if mode == "Custom" then "Create racer using configured default look" else "Use my avatar"}
 report.arrival = receipt
 local function stateReceipt(value)
  local profile = value.profile
  table.insert(receipt.states, {phase = value.phase, ok = value.ok, message = value.message, preset = value.preset,
   completed = profile and profile.completed, revision = profile and profile.revision, mode = profile and profile.mode,
   gold = profile and profile.gold, bonusClaimed = profile and profile.bonusClaimed,
   deliveryToken = value.delivery and value.delivery.token, serverTime = workspace:GetServerTimeNow()})
 end
 table.insert(arrivalConnections, changed.OnClientEvent:Connect(function(value)
  if typeof(value) == "table" then stateReceipt(value) end
 end))
 for _, attribute in {"OnboardingReady", "ArrivalPhase", "ArrivalOpen"} do
  table.insert(arrivalConnections, player:GetAttributeChangedSignal(attribute):Connect(function()
   table.insert(receipt.localTransitions, {attribute = attribute, value = player:GetAttribute(attribute),
    serverTime = workspace:GetServerTimeNow()})
  end))
 end
 waitFor(function() return player.PlayerGui:FindFirstChild("Arrival") ~= nil end, 20, "Existing onboarding UI has not initialized; helper will not call Init")
 local state
 local deadline = os.clock() + 45
 repeat
  state = remote:InvokeServer({action = "State"})
  assert(typeof(state) == "table" and state.preset == nil, "A Studio preset is present; use a fresh natural first visit")
  if state.phase ~= "Loading" then break end
  task.wait(.5)
 until os.clock() >= deadline
 stateReceipt(state)
 assert(state.phase == "Choice" and state.profile and state.profile.completed == false,
  "Arrival requires an actual incomplete first-visit Choice; it will not reset a profile or bypass load failure")
 local payload = {action = "Save", mode = mode, operationId = receipt.operationId}
 if mode == "Custom" then payload.look = table.clone(require(ReplicatedStorage.Config.OnboardingConfig).DefaultLook) end
 local done, requestOk, reply = false, nil, nil
 table.insert(report.actions, {action = "ArrivalSave", mode = mode, operationId = receipt.operationId,
  serverTime = workspace:GetServerTimeNow()})
 task.spawn(function()
  requestOk, reply = pcall(function() return remote:InvokeServer(payload) end)
  done = true
 end)
 waitFor(function() return done end, 45, "Ordinary arrival save has not replied; operationId is retained and will not be resent automatically")
 assert(requestOk and typeof(reply) == "table", "Ordinary arrival request failed: " .. tostring(reply))
 stateReceipt(reply)
 assert(reply.preset == nil and reply.ok == true and reply.phase == "Entering" and reply.delivery,
  "Ordinary first-visit save did not enter natural lobby delivery: " .. tostring(reply.message))
 receipt.enteringToken = reply.delivery.token
 waitFor(ready, 80, "Production lobby preload/entrance/Arrived acknowledgment/camera handoff did not reach natural Ready")
 receipt.completed = true
 receipt.final = {onboardingReady = player:GetAttribute("OnboardingReady"), arrivalPhase = player:GetAttribute("ArrivalPhase"),
  arrivalOpen = player:GetAttribute("ArrivalOpen"), cameraType = workspace.CurrentCamera.CameraType.Name,
  flowAvailable = Flow.IsAvailable(), serverTime = workspace:GetServerTimeNow()}
end
local function entry()
 waitFor(ready, 60, "Real arrival/UI readiness did not complete; this helper will not set a preset")
 local initial = Flow.GetState()
 assert(initial.status == "Lobby" and not initial.enrolled and initial.state == "WaitingForPlayers", "Use a fresh solo ordinary lobby for Entry/Retry")
 action("Join")
 waitFor(function() return Flow.GetState().enrolled == true end, 8, "Supported Join action was not accepted")
 waitFor(function() return tournament and tournament.phase == "Voting" and tournament.enrolled == true end, 25, "Ordinary opening-course ballot did not appear")
 local eligible = false
 for _, course in tournament.catalog or {} do if course.id == "egg_rush_circuit" then eligible = true end end
 assert(eligible, "Egg Rush is missing from the real voting catalog")
 local reply = remotes.SubmitMapVotes:InvokeServer({tournamentId = tournament.tournamentId,
  requestId = 1000000 + sequence, picks = {"egg_rush_circuit"}})
 assert(typeof(reply) == "table" and reply.ok == true, "Supported opening-course vote was rejected: " .. tostring(reply and reply.message))
 table.insert(report.actions, {action = "OpeningCourseVote", courseId = "egg_rush_circuit", accepted = reply.ok,
  tournamentId = tournament.tournamentId, serverTime = workspace:GetServerTimeNow()})
 waitFor(function()
  local value = Flow.GetState()
  return value.status == "Racing" and value.state == "Racing" and value.courseId == "egg_rush_circuit"
 end, 100, "Ordinary real-client delivery/camera/countdown admission did not reach Racing")
 local value = Flow.GetState()
 table.insert(report.entries, {raceId = value.raceId, serverTime = workspace:GetServerTimeNow(),
  courseId = value.courseId, enrolled = value.enrolled, ready = player:GetAttribute("TournamentCourseReady"),
  presentationOpen = player:GetAttribute("TournamentPresentation"), cameraType = workspace.CurrentCamera.CameraType.Name})
end
stored.Value = Http:JSONEncode({state = "Ready", actions = {"Arrival", "ArrivalAndEntry", "Entry", "FinishAndRetry", "Break"},
 defaultArrivalMode = "Custom", flowModulePath = flowModule:GetFullName(), callsInit = false, ownerApproval = false})
stored:SetAttribute("State", "Ready")
script:GetAttributeChangedSignal("Command"):Connect(function()
 if busy then return end
 local parsed, command = pcall(function() return Http:JSONDecode(script:GetAttribute("Command")) end)
 if not parsed or typeof(command) ~= "table" then return end
 busy, sequence = true, sequence + 1
 stored:SetAttribute("State", "Running")
 task.spawn(function()
  local ok, failure = xpcall(function()
   assert(#Players:GetPlayers() == 1, "This focused supported-flow helper requires one actual client")
   if command.action == "Arrival" then arrival(command)
   elseif command.action == "ArrivalAndEntry" then arrival(command); entry()
   elseif command.action == "Entry" then entry()
   elseif command.action == "FinishAndRetry" then
    local original = assert(report.entries[1], "Run Entry first and complete its real three laps with the lead's sole avatar controller")
    waitFor(function()
     local value = Flow.GetState()
     return value and value.finishTicket and value.finishTicket.raceId == original.raceId
      and value.finishTicket.status == "Finished" and value.finishTicket.official == true
    end, 600, "Actual official three-lap finish ticket did not arrive")
    waitFor(function() return Flow.GetState().status == "Lobby" end, 8, "Actual automatic finish return to lobby did not arrive")
    action("Break")
    waitFor(function() return Flow.GetState().enrolled == false and Flow.GetState().status == "Lobby" end, 8, "Supported Break was not accepted")
    waitFor(function() return Flow.GetState().state == "WaitingForPlayers" end, 20, "Ordinary solo round did not return to waiting")
    entry()
   elseif command.action == "Break" then
    action("Break")
    waitFor(function() return Flow.GetState().enrolled == false and Flow.GetState().status == "Lobby" end, 8, "Supported Break was not accepted")
   else error("Unknown client flow action") end
  end, debug.traceback)
  for _, listener in arrivalConnections do listener:Disconnect() end
  table.clear(arrivalConnections)
  report.ok, report.failure = ok, if ok then nil else failure
  report.lastAction = command.action
  stored.Value = Http:JSONEncode(report)
  stored:SetAttribute("State", if ok then "Complete" else "Failed")
  busy = false
 end)
end)
script.Destroying:Connect(function() connection:Disconnect() end)
