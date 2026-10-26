local c = workspace.KeyboardCircuit_P2_C01
local p = assert(shared.KCP2TraversalProbe)
local player = game.Players.LocalPlayer
shared.KCP2ExpertTraversal = {active = true, results = {}}
local function sequence(id)
 for _, item in c.Districts:GetDescendants() do if item:GetAttribute("SequenceId") == id then return item end end
 error("Missing sequence " .. id)
end
task.spawn(function()
 local r = shared.KCP2ExpertTraversal
 local completed, failure = xpcall(function()
 for _, expert in c.ExpertRoutes:GetChildren() do
  local from = sequence(expert:GetAttribute("BranchAfter")).ExitBank.BankContact
  local to = c.CheckpointBays[expert:GetAttribute("MergeBefore")].BankContact
  local caps = {}
  for _, marker in expert.TraversalPoints:GetChildren() do
   table.insert(caps, {ordinal = marker:GetAttribute("Ordinal"), contact = expert["PrecisionLanding" .. marker.Name].KeyContact})
  end
  table.sort(caps, function(a, b) return a.ordinal < b.ordinal end)
  local result = {id = expert:GetAttribute("ExpertId"), landings = #caps, steps = {}, beforeSetupRecoveries = player:GetAttribute("KCPhase2Recoveries")}
  table.insert(r.results, result)
  result.setup = p.Place(from)
  result.beganRecoveries = player:GetAttribute("KCPhase2Recoveries")
  local previous = from
  local ok = true
  for _, cap in caps do
   local passed = p.Cross(result.id .. " cap" .. cap.ordinal, previous, cap.contact)
   table.insert(result.steps, {ordinal = cap.ordinal, passed = passed})
   if not passed then ok = false; break end
   previous = cap.contact
  end
  if ok then result.merged = p.Cross(result.id .. " checkpoint merge", previous, to); ok = result.merged end
  result.finishedRecoveries = player:GetAttribute("KCPhase2Recoveries")
  result.passed = ok and result.finishedRecoveries == result.beganRecoveries
 end
 end, debug.traceback)
 r.error = if completed then nil else failure
 r.recordCount, r.active = #p.Records(), false
end)
return {started = true, boundary = "Staged departure positioning; continuous real-avatar expert hops and checkpoint merges; no human difficulty or full-race proof"}
