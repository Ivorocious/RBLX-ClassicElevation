local c = workspace.KeyboardCircuit_P2_C01
local p = assert(shared.KCP2TraversalProbe)
local player = game.Players.LocalPlayer
shared.KCP2MechanismTraversal = {active = true, results = {}}
local function unit(id)
 for _, item in c.Districts:GetDescendants() do if item:GetAttribute("MechanismId") == id then return item end end
 error("Missing mechanism " .. id)
end
local function contact(bank) return assert(bank:FindFirstChild("BankContact") or bank:FindFirstChild("KeyContact")) end
local function waitFor(predicate, seconds)
 local start = os.clock()
 while os.clock() - start < seconds do if predicate() then return true, os.clock() - start end; task.wait(.03) end
 return false, os.clock() - start
end
task.spawn(function()
 local r = shared.KCP2MechanismTraversal
 local completed, failure = xpcall(function()
 for _, id in {"H02", "H03", "H04", "H07", "H08", "H01"} do
  local u = unit(id)
  local result = {id = id, beforeSetupRecoveries = player:GetAttribute("KCPhase2Recoveries"), steps = {}}
  table.insert(r.results, result)
  local entry, exit = contact(u.EntryBank), contact(u.ExitBank)
  result.setup = p.Place(entry)
  result.beganRecoveries = player:GetAttribute("KCPhase2Recoveries")
  local function cross(label, from, to, predicate)
   local step = {label = label}
   table.insert(result.steps, step)
   if predicate then step.window, step.wait = waitFor(predicate, 18); if not step.window then return false end end
   step.passed = p.Cross(label, from, to)
   return step.passed
  end
  local ok = true
  if id == "H02" then
   ok = cross("H02 entry to first seesaw", entry, contact(u.Spacebar1))
   if ok then ok = cross("H02 first to second seesaw", contact(u.Spacebar1), contact(u.Spacebar2)) end
   if ok then ok = cross("H02 second seesaw to exit", contact(u.Spacebar2), exit) end
   result.hingeAngles = {u.Hinge1.CurrentAngle, u.Hinge2.CurrentAngle}
  elseif id == "H03" then
   local previous = entry
   for row = 1, 3 do
    local bank = u["Lane1Row" .. row]
    local admission = if row == 1 then function() return bank:GetAttribute("AdmissionOpen") == true end else nil
    if not cross("H03 lane1 row" .. row, previous, contact(bank), admission) then ok = false; break end
    previous = contact(bank)
   end
   if ok then ok = cross("H03 last row to exit", previous, exit) end
  elseif id == "H04" then
   local crossing = contact(u.CrossingBank)
   ok = cross("H04 entry to crossing", entry, crossing, function() return u.Drop1:GetAttribute("CycleState") == "Clear" end)
   if ok then ok = cross("H04 crossing to exit", crossing, exit, function() return u.Drop3:GetAttribute("CycleState") == "Clear" end) end
  elseif id == "H07" then
   local crossing = contact(u.CrossingBank)
   ok = cross("H07 entry to crossing", entry, crossing, function() return u.SweepArm:GetAttribute("CycleState") == "Rest" end)
   if ok then ok = cross("H07 crossing to exit", crossing, exit, function() return u.SweepArm:GetAttribute("CycleState") == "Rest" end) end
  elseif id == "H08" then
   local previous = entry
   for index = 1, 4 do
    local target = contact(u["PassageBank" .. index])
    local admission = if index == 1 then nil else function() return u["DominoPanel" .. (index - 1)]:GetAttribute("AdmissionOpen") == true end
    if not cross("H08 passage" .. index, previous, target, admission) then ok = false; break end
    previous = target
   end
   if ok then ok = cross("H08 last passage to exit", previous, exit) end
  elseif id == "H01" then
   local middle = contact(u.PermanentCtrlRefuge)
   ok = cross("H01 entry to first Shift", entry, contact(u.ShiftBridge1), function() return u.ShiftBridge1:GetAttribute("AdmissionOpen") == true end)
   if ok then ok = cross("H01 first Shift to refuge", contact(u.ShiftBridge1), middle) end
   if ok then ok = cross("H01 refuge to second Shift", middle, contact(u.ShiftBridge2), function() return u.ShiftBridge2:GetAttribute("AdmissionOpen") == true end) end
   if ok then ok = cross("H01 second Shift to exit", contact(u.ShiftBridge2), exit) end
  end
  result.finishedRecoveries = player:GetAttribute("KCPhase2Recoveries")
  result.passed = ok and result.finishedRecoveries == result.beganRecoveries
 end
 end, debug.traceback)
 r.error = if completed then nil else failure
 r.recordCount, r.active = #p.Records(), false
end)
return {started = true, mechanisms = 6, boundary = "Staged position between encounters; continuous ordinary humanoid movement inside each encounter; real warning phases and contacts; no whole-race or human difficulty proof"}
