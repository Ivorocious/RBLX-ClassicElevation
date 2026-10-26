local c = workspace.KeyboardCircuit_P2_C01
local p = assert(shared.KCP2TraversalProbe)
local player = game.Players.LocalPlayer
local order = require(c.SourceSnapshot.Layout).Main
local units = {}
for _, item in c.Districts:GetDescendants() do if item:GetAttribute("SequenceId") then units[item:GetAttribute("SequenceId")] = item end end
for _, item in c.CheckpointBays:GetChildren() do units[item.Name] = item end
local function endpoint(id, departing)
 local u = assert(units[id])
 if u:FindFirstChild("BankContact") then return u.BankContact end
 local bank = u:FindFirstChild(if departing then "ExitBank" else "EntryBank") or u:FindFirstChild(if departing then "Exit" else "Entry")
 return assert(bank.BankContact)
end
shared.KCP2JoinTraversal = {active = true, results = {}}
task.spawn(function()
 local r = shared.KCP2JoinTraversal
 local completed, failure = xpcall(function()
 for index, id in order do
  local nextId = order[index % #order + 1]
  local edge = id .. "_to_" .. nextId
  local route = {endpoint(id, true)}
  local links = {}
  for _, bank in c.RouteLinks:GetChildren() do
   if bank:GetAttribute("FromSequence") == id and bank:GetAttribute("ToSequence") == nextId then table.insert(links, bank) end
  end
  table.sort(links, function(a, b) return tonumber(a.Name:match("_(%d+)$")) < tonumber(b.Name:match("_(%d+)$")) end)
  for _, bank in links do table.insert(route, bank.BankContact) end
  table.insert(route, endpoint(nextId, false))
  local beforeSetupRecoveries = player:GetAttribute("KCPhase2Recoveries")
  local setup = p.Place(route[1])
  local result = {edge = edge, links = #links, steps = {}, setup = setup, beforeSetupRecoveries = beforeSetupRecoveries, beganRecoveries = player:GetAttribute("KCPhase2Recoveries")}
  table.insert(r.results, result)
  local ok = true
  for step = 2, #route do
   local passed = p.Cross(edge .. " transfer" .. (step - 1), route[step - 1], route[step])
   table.insert(result.steps, {step = step - 1, passed = passed})
   if not passed then ok = false; break end
  end
  result.finishedRecoveries = player:GetAttribute("KCPhase2Recoveries")
  result.passed = ok and result.finishedRecoveries == result.beganRecoveries
 end
 end, debug.traceback)
 r.error = if completed then nil else failure
 r.recordCount, r.active = #p.Records(), false
end)
return {started = true, edges = #order, boundary = "Actual-avatar staged setup for each normal edge, continuous key-bank transfers within each join; no continuous lap-duration claim"}

