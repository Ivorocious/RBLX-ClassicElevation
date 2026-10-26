assert(game:GetService("RunService"):IsServer())
local c = workspace.KeyboardCircuit_P2_C01
local probe = {active = true, started = workspace:GetServerTimeNow(), units = {}, samples = 0}
shared.KCP2Cycles = probe
local units = {}
for _, u in c.Districts:GetDescendants() do
 if u:GetAttribute("MechanismId") then
  local row = {id = u:GetAttribute("MechanismId"), kind = u:GetAttribute("MechanismKind"), states = {}, warningSeen = false, admissionSeen = false, actors = {}}
  probe.units[row.id] = row
  local actors = {}
  for _, a in u:GetDescendants() do
   if a:IsA("Model") and a:GetAttribute("KCMover") then
    local pivot = a:GetPivot()
    row.actors[a.Name] = {first = {pivot.Position.X, pivot.Position.Y, pivot.Position.Z}, maxDisplacement = 0, maxAngle = 0, states = {}}
    table.insert(actors, {model = a, first = pivot})
   end
  end
  table.insert(units, {model = u, row = row, actors = actors})
 end
end
task.spawn(function()
 while workspace:GetServerTimeNow() - probe.started < 28 do
  for _, item in units do
   local u, row = item.model, item.row
   row.states[u:GetAttribute("CycleState") or "Unknown"] = true
   for _, actor in item.actors do
    local a = actor.model
    local state = row.actors[a.Name]
    local pivot = a:GetPivot()
    local _, angle = actor.first:ToObjectSpace(pivot):ToAxisAngle()
    state.maxDisplacement = math.max(state.maxDisplacement, (pivot.Position - actor.first.Position).Magnitude)
    state.maxAngle = math.max(state.maxAngle, math.abs(math.deg(angle)))
    state.states[a:GetAttribute("CycleState") or "Unknown"] = true
   end
   for _, warning in u:GetDescendants() do
    if warning:GetAttribute("KCWarning") then
     row.warningSeen = row.warningSeen or warning:GetAttribute("WarningActive") == true
     row.admissionSeen = row.admissionSeen or warning:GetAttribute("AdmissionOpen") == true
    end
   end
   if u:FindFirstChild("Slider") then row.slider = u.Slider.CurrentPosition end
   if u:FindFirstChild("Hinge1") then row.hinge1 = u.Hinge1.CurrentAngle; row.hinge2 = u.Hinge2.CurrentAngle end
  end
  probe.samples += 1
  task.wait(.05)
 end
 probe.finished = workspace:GetServerTimeNow()
 probe.server = c.StudioProbeControls.State:Invoke()
 probe.active = false
end)
return {started = true, seconds = 28, units = #units, boundary = "Actual server actor poses/warnings over complete passive cycles; H05 requires an actual rider to trigger its complete cycle"}
