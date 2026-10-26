--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client fixture required")
local player = Players.LocalPlayer
local candidate = assert(workspace:FindFirstChild("KeyboardCircuit_P2_C01"))
assert(candidate:GetAttribute("CourseId") == "keyboard-circuit-phase2", "Isolated Phase2 candidate required")
local p = assert(shared.KCP2TraversalProbe, "Install TraversalProbe.client.luau first")
assert(not shared.KCP2ContinuousLap or not shared.KCP2ContinuousLap.active, "Continuous lap already active")
local Layout = require(candidate.SourceSnapshot.Layout)
local units = {}
for _, item in candidate.Districts:GetDescendants() do
 if item:IsA("Model") then
  local id = item:GetAttribute("SequenceId") or item:GetAttribute("MechanismId")
  if id then assert(not units[id], "Duplicate sequence " .. id); units[id] = item end
 end
end
for _, item in candidate.CheckpointBays:GetChildren() do units[item.Name] = item end
local character = assert(player.Character, "Living character required")
local root = assert(character:FindFirstChild("HumanoidRootPart")) :: BasePart
local humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
local started, firstRecord = os.clock(), #p.Records()
local initialRecoveries = player:GetAttribute("KCPhase2Recoveries")
local runId = candidate:GetAttribute("KCPhase2RunId")
local r: any = {
 active = true, passed = false, secondsLimit = 300, candidate = candidate.Name,
 revision = candidate:GetAttribute("KCPhase2Revision"), layoutRevision = Layout.Revision,
 userId = player.UserId, setupCalls = 0, joins = {}, sequences = {}, checkpoints = {},
 waits = {}, stateChanges = {}, gates = {}, recoveries = {}, diagnosticReads = 0,
 movement = {walkSpeed = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight, jumpPower = humanoid.JumpPower, useJumpPower = humanoid.UseJumpPower, gravity = workspace.Gravity},
 boundary = "One main-F00 setup call, then ordinary humanoid movement/jumps and physical carrying. Automated known paths and fresh-window waits; no human pacing, three-lap, crowd/device or performance proof.",
}
shared.KCP2ContinuousLap = r
local worker: thread? = nil
local monitor: RBXScriptConnection? = nil
local seenGates, seenRecoveries = {}, {}
local lastState, lastDiagnostic = "", -math.huge
local previousPosition: Vector3? = nil
local previousAt = started

local function vector(value: Vector3) return {value.X, value.Y, value.Z} end
local function state()
 return {at = workspace:GetServerTimeNow(), elapsed = os.clock() - started,
  nextGate = player:GetAttribute("KCPhase2NextGate"), lap = player:GetAttribute("KCPhase2Lap"),
  completedLaps = player:GetAttribute("KCPhase2CompletedLaps"), recoveries = player:GetAttribute("KCPhase2Recoveries"),
  finished = player:GetAttribute("KCPhase2Finished"), participant = player:GetAttribute("KCPhase2Candidate"),
  root = vector(root.Position), floor = humanoid.FloorMaterial.Name}
end
local function diagnostics()
 local encoded = candidate:GetAttribute("KCPhase2ServerDiagnostics")
 if type(encoded) ~= "string" then return end
 local ok, data = pcall(Http.JSONDecode, Http, encoded)
 if not ok or type(data) ~= "table" then return end
 r.diagnosticReads += 1
 local participant = data.participants and data.participants[tostring(player.UserId)]
 if participant then r.serverState = participant end
 for _, row in data.gates or {} do
  if row.userId == player.UserId and r.continuousServerStartedAt and row.at >= r.continuousServerStartedAt then
   local key = tostring(row.at) .. ":" .. tostring(row.gate) .. ":" .. tostring(row.reason)
   if not seenGates[key] then seenGates[key] = true; table.insert(r.gates, row) end
  end
 end
 for _, row in data.recoveries or {} do
  if row.userId == player.UserId and row.at >= r.serverStartedAt then
   local key = tostring(row.at) .. ":" .. tostring(row.reason)
   if not seenRecoveries[key] then seenRecoveries[key] = true; table.insert(r.recoveries, row) end
  end
 end
end
local function finish(passed: boolean, failure: string?, cancelWorker: boolean?)
 if not r.active then return end
 r.active, r.passed, r.error = false, passed, failure
 if r.currentWait then
  r.currentWait.elapsed = os.clock() - r.currentWait.beganClock
  r.currentWait.passed, r.currentWait.interrupted = false, true
  r.currentWait = nil
 end
 if monitor then monitor:Disconnect(); monitor = nil end
 p.Stop()
 if humanoid.Parent then humanoid.Jump = false; humanoid:Move(Vector3.zero, false) end
 diagnostics()
 r.finalState, r.elapsed = state(), os.clock() - started
 r.records = {}
 for index = firstRecord + 1, #p.Records() do table.insert(r.records, p.Records()[index]) end
 r.waitSeconds = 0
 for _, wait in r.waits do r.waitSeconds += wait.elapsed or 0 end
 if r.continuousBeganAt then r.continuousSeconds = os.clock() - r.continuousBeganAt end
 if cancelWorker and worker then task.cancel(worker) end
end
local function guard()
 assert(r.active, r.error or "Fixture stopped")
 assert(os.clock() - started < r.secondsLimit, "300-second deadline")
 assert(candidate.Parent and candidate:GetAttribute("KCPhase2RunId") == runId and candidate:GetAttribute("KCPhase2Stopped") ~= true, "Session changed or stopped")
 assert(player.Character == character and root.Parent == character and humanoid.Health > 0 and not root.Anchored, "Character unavailable, replaced or anchored")
 assert(player:GetAttribute("KCPhase2Candidate") == candidate.Name, "Participant left candidate")
 assert(player:GetAttribute("KCPhase2Recoveries") == initialRecoveries, "Authoritative recovery interrupted continuous lap")
end
local function contact(bank: Instance): BasePart
 local part = assert(bank:FindFirstChild("BankContact") or bank:FindFirstChild("KeyContact"), "Missing traversal contact " .. bank.Name)
 assert(part:IsA("BasePart"))
 return part
end
local function endpoint(id: string, departing: boolean): BasePart
 local unit = assert(units[id], "Missing route unit " .. id)
 if unit:FindFirstChild("BankContact") then return contact(unit) end
 return contact(assert(unit:FindFirstChild(if departing then "ExitBank" else "EntryBank") or unit:FindFirstChild(if departing then "Exit" else "Entry")))
end
local function move(label: string, target: Vector3, jumping: boolean, support: BasePart, seconds: number?, tolerance: number?)
 guard()
 assert(p.Move(label, target, jumping, support, math.min(seconds or 4, r.secondsLimit - (os.clock() - started)), tolerance or .7), label)
 guard()
end
local function cross(label: string, from: BasePart, to: BasePart)
 guard()
 assert(p.Cross(label, from, to), label)
 guard()
end
local function waitFor(label: string, predicate: () -> boolean, seconds: number, fresh: boolean?, observe: (() -> any)?)
 local began = os.clock()
 local wait: any = {label = label, at = workspace:GetServerTimeNow(), beganClock = began, freshWindow = fresh == true, samples = {}}
 table.insert(r.waits, wait)
 r.currentWait = wait
 local needClosed = fresh == true and predicate()
 local sampled = -math.huge
 while os.clock() - began < seconds do
  guard()
  local open = predicate()
  if needClosed and not open then needClosed = false end
  if not needClosed and open then wait.elapsed, wait.passed, r.currentWait = os.clock() - began, true, nil; return end
  if observe and os.clock() - sampled >= .2 then sampled = os.clock(); table.insert(wait.samples, {elapsed = os.clock() - began, value = observe()}) end
  task.wait(.03)
 end
 wait.elapsed, wait.passed = os.clock() - began, false
 r.currentWait = nil
 error("Window timeout: " .. label)
end
local function join(from: string, to: string)
 local links = {}
 for _, bank in candidate.RouteLinks:GetChildren() do
  if bank:GetAttribute("FromSequence") == from and bank:GetAttribute("ToSequence") == to then table.insert(links, bank) end
 end
 table.sort(links, function(a, b) return tonumber(a.Name:match("_(%d+)$")) < tonumber(b.Name:match("_(%d+)$")) end)
 local result: any = {from = from, to = to, connectors = #links, began = os.clock() - started, before = state()}
 table.insert(r.joins, result)
 local previous = endpoint(from, true)
 for index, bank in links do
  local target = contact(bank)
  cross(from .. "→" .. to .. " connector" .. index, previous, target)
  previous = target
 end
 cross(from .. "→" .. to .. " arrival", previous, endpoint(to, false))
 result.passed, result.after, result.elapsed = true, state(), os.clock() - started - result.began
end
local nextGate = {CP1 = "CP2", CP2 = "CP3", CP3 = "F01", F01 = "F00", F00 = "CP1"}
local function checkpoint(id: string)
 local bay = endpoint(id, false)
 local result: any = {id = id, before = state(), at = workspace:GetServerTimeNow()}
 table.insert(r.checkpoints, result)
 local function accepted()
  return player:GetAttribute("KCPhase2NextGate") == nextGate[id] and player:GetAttribute("KCPhase2CompletedLaps") == (if id == "F00" then 1 else 0)
 end
 if not accepted() then
  assert(player:GetAttribute("KCPhase2NextGate") == id, "Unexpected authoritative gate at " .. id)
  move(id .. " back side", bay.CFrame:PointToWorldSpace(Vector3.new(-8, 0, 0)), false, bay)
  move(id .. " forward crossing", bay.CFrame:PointToWorldSpace(Vector3.new(8, 0, 0)), false, bay)
 end
 waitFor(id .. " authoritative acceptance", accepted, 2)
 result.passed, result.after = true, state()
end
local function modelNamed(unit: Instance, name: string): Model
 for _, item in unit:GetDescendants() do if item:IsA("Model") and item.Name == name then return item end end
 error("Missing traversal Model " .. name)
end
local function staticSequence(id: string, unit: Model)
 local points = unit.TraversalPoints:GetChildren()
 table.sort(points, function(a, b) return a:GetAttribute("Ordinal") < b:GetAttribute("Ordinal") end)
 local previous = endpoint(id, false)
 for index = 2, #points do
  local point = points[index]
  if id == "O04" and point.Name == "EnterTurn" then
   local stem = contact(modelNamed(unit, "EnterStem"))
   move("O04 continuous Enter hairpin turn", stem.Position - stem.CFrame.LookVector * 7, false, stem, 3)
  else
   local target = contact(modelNamed(unit, point.Name))
   if point:GetAttribute("JumpFromPrevious") then cross(id .. " " .. point.Name, previous, target)
   else move(id .. " " .. point.Name, target.Position, false, target) end
   previous = target
  end
 end
end
local function mechanism(id: string, unit: Model)
 local entry, exit = endpoint(id, false), endpoint(id, true)
 if id == "H02" then
  cross("H02 first seesaw", entry, contact(unit.Spacebar1))
  cross("H02 second seesaw", contact(unit.Spacebar1), contact(unit.Spacebar2))
  cross("H02 permanent exit", contact(unit.Spacebar2), exit)
 elseif id == "H03" then
  waitFor("H03 fresh lane1 admission", function() return unit.Lane1Row1:GetAttribute("AdmissionOpen") == true end, 18, true)
  local previous = entry
  for row = 1, 3 do local target = contact(unit["Lane1Row" .. row]); cross("H03 lane1 row" .. row, previous, target); previous = target end
  cross("H03 permanent exit", previous, exit)
 elseif id == "H04" then
  local crossing = contact(unit.CrossingBank)
  waitFor("H04 fresh first drop clearance", function() return unit.Drop1:GetAttribute("CycleState") == "Clear" end, 12, true)
  cross("H04 entry to crossing", entry, crossing)
  waitFor("H04 final drop clearance", function() return unit.Drop3:GetAttribute("CycleState") == "Clear" end, 12)
  cross("H04 permanent exit", crossing, exit)
 elseif id == "H05" or id == "H06" then
  local ride = contact(unit.RideableBank)
  waitFor(id .. " boarding", function() return unit:GetAttribute("BoardingWindow") == true end, 18, id == "H06")
  cross(id .. " physical boarding", entry, ride)
  local boardedAt = root.Position
  waitFor(id .. " carried to exit", function() return unit:GetAttribute("ExitWindow") == true end, 12, false, function()
   return {root = vector(root.Position), relative = vector(ride.CFrame:PointToObjectSpace(root.Position)), slider = unit.Slider.CurrentPosition, cycle = unit:GetAttribute("CycleState")}
  end)
  local carriedDistance, verticalGain = (root.Position - boardedAt).Magnitude, root.Position.Y - boardedAt.Y
  table.insert(r.currentSequence.rides, {carriedDistance = carriedDistance, verticalGain = verticalGain})
  assert(if id == "H05" then verticalGain > 5 else carriedDistance > 12, id .. " actual carrying was not observed")
  cross(id .. " ride exit", ride, exit)
 elseif id == "H07" then
  local crossing = contact(unit.CrossingBank)
  waitFor("H07 fresh rest window", function() return unit.SweepArm:GetAttribute("CycleState") == "Rest" end, 18, true)
  cross("H07 early approach", entry, crossing)
  move("H07 low-arm corridor jump", unit:GetAttribute("EncounterFrame"):PointToWorldSpace(Vector3.new(8, .425, 0)), true, crossing, 3, .6)
  cross("H07 permanent exit", crossing, exit)
 elseif id == "H08" then
  local previous = entry
  for index = 1, 4 do
   if index > 1 then
    local panel = unit["DominoPanel" .. (index - 1)]
    waitFor("H08 passage" .. index .. " fresh admission", function() return panel:GetAttribute("AdmissionOpen") == true end, 18, true)
   end
   local target = contact(unit["PassageBank" .. index]); cross("H08 passage" .. index, previous, target); previous = target
  end
  cross("H08 permanent exit", previous, exit)
 elseif id == "H01" then
  local middle = contact(unit.PermanentCtrlRefuge)
  waitFor("H01 fresh first Shift admission", function() return unit.ShiftBridge1:GetAttribute("AdmissionOpen") == true end, 18, true)
  cross("H01 first Shift", entry, contact(unit.ShiftBridge1))
  cross("H01 Ctrl refuge", contact(unit.ShiftBridge1), middle)
  waitFor("H01 fresh second Shift admission", function() return unit.ShiftBridge2:GetAttribute("AdmissionOpen") == true end, 18, true)
  cross("H01 second Shift", middle, contact(unit.ShiftBridge2))
  cross("H01 permanent exit", contact(unit.ShiftBridge2), exit)
 else error("Unexpected mechanism " .. id) end
end

r.serverStartedAt = workspace:GetServerTimeNow()
monitor = RunService.Heartbeat:Connect(function()
 if not r.active then return end
 local ok, failure = pcall(guard)
 if not ok then finish(false, tostring(failure), true); return end
 if r.cancelRequested then finish(false, "Fixture cancelled", true); return end
 local now = os.clock()
 if r.continuousBeganAt then
  if previousPosition and now - previousAt <= .5 and (root.Position - previousPosition).Magnitude > math.max(12, (now - previousAt) * 80) then
   finish(false, "Unexpected position discontinuity", true); return
  end
  previousPosition, previousAt = root.Position, now
 end
 local signature = tostring(player:GetAttribute("KCPhase2NextGate")) .. ":" .. tostring(player:GetAttribute("KCPhase2CompletedLaps")) .. ":" .. tostring(player:GetAttribute("KCPhase2Recoveries"))
 if signature ~= lastState then lastState = signature; table.insert(r.stateChanges, state()); diagnostics() end
 if now - lastDiagnostic >= 1 then lastDiagnostic = now; diagnostics() end
end)
worker = task.spawn(function()
 local ok, failure = xpcall(function()
  assert(player:GetAttribute("KCPhase2NextGate") == "CP1" and player:GetAttribute("KCPhase2CompletedLaps") == 0 and player:GetAttribute("KCPhase2Lap") == 1, "Prepare a fresh active participant before staging; fixture does not call Begin/Restart")
  assert(type(initialRecoveries) == "number", "Authoritative participant attributes required")
  assert(#Layout.Main == 21 and #Layout.Sequences == 16 and Layout.Main[1] == "F00", "Current normal route contract required")
  guard()
  r.setupCalls += 1
  r.setup = p.Place(endpoint("F00", false))
  guard()
  r.startState, r.continuousBeganAt, r.continuousServerStartedAt = state(), os.clock(), workspace:GetServerTimeNow()
  previousPosition, previousAt = root.Position, os.clock()
  for index, id in Layout.Main do
   local after = Layout.Main[index % #Layout.Main + 1]
   join(id, after)
   if nextGate[after] then checkpoint(after)
   else
    local result: any = {id = after, before = state(), began = os.clock() - started, rides = {}}
    table.insert(r.sequences, result)
    r.currentSequence = result
    local unit = assert(units[after])
    if unit:GetAttribute("MechanismId") then mechanism(after, unit) else staticSequence(after, unit) end
    result.passed, result.after, result.elapsed = true, state(), os.clock() - started - result.began
   end
  end
  waitFor("complete authoritative gate receipt", function() diagnostics(); return #r.gates >= 5 end, 2)
  assert(#r.joins == 21 and #r.sequences == 16 and #r.checkpoints == 5 and #r.gates == 5, "Incomplete continuous normal lap")
  for index, gate in {"CP1", "CP2", "CP3", "F01", "F00"} do assert(r.gates[index].gate == gate, "Authoritative gate order mismatch") end
  assert(player:GetAttribute("KCPhase2CompletedLaps") == 1 and player:GetAttribute("KCPhase2NextGate") == "CP1" and player:GetAttribute("KCPhase2Lap") == 2, "Server did not accept one complete lap")
  guard()
 end, debug.traceback)
 finish(ok, if ok then nil else tostring(failure), false)
end)
return {started = true, secondsLimit = r.secondsLimit, report = "shared.KCP2ContinuousLap", setup = "Fresh participant; one Place on main F00 bay", boundary = r.boundary}
