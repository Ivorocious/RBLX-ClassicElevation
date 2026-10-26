local c = workspace.KeyboardCircuit_P2_C01
local Probe = assert(shared.KCP2TraversalProbe)
local player = game.Players.LocalPlayer
local Motion = require(c.SourceSnapshot.Motion)
local state = {active=true, records={}}
shared.KCP2RefugeProbe = state
task.spawn(function()
 local ok, err = xpcall(function()
  for _, id in {"H02","H03","H04","H05","H06","H07","H08","H01"} do
   local unit
   for _, item in c.Districts:GetDescendants() do if item:IsA("Model") and item:GetAttribute("MechanismId")==id then unit=item; break end end
   local bank = unit:FindFirstChild("PermanentCtrlRefuge") or unit.EntryBank
   local setup = Probe.Place(bank.BankContact)
   local record = {id=id,bank=bank.Name,setup=setup,states={},warnings=0,samples=0,rootDrift=0,beforeRecoveries=player:GetAttribute("KCPhase2Recoveries")}
   table.insert(state.records,record)
   local root = player.Character.HumanoidRootPart
   local start = root.Position
   local period = Motion.Tuning(unit:GetAttribute("MechanismKind")).Period or 3
   local before, duration = c:GetAttribute("KCElapsed"), math.min(period+.2,14.2)
   local began = os.clock()
   repeat
    local phase = unit:GetAttribute("CycleState")
    record.states[phase or "unknown"]=true
    for _, part in unit:GetDescendants() do if part:IsA("BasePart") and part:GetAttribute("WarningActive")==true then record.warnings+=1;break end end
    record.rootDrift=math.max(record.rootDrift,(root.Position-start).Magnitude)
    record.samples+=1
    task.wait(.08)
   until c:GetAttribute("KCElapsed")-before>=duration or os.clock()-began>duration+3
   record.elapsed=c:GetAttribute("KCElapsed")-before
   record.afterRecoveries=player:GetAttribute("KCPhase2Recoveries")
   record.passed=record.elapsed>=duration and record.afterRecoveries==record.beforeRecoveries and record.rootDrift<.8
   record.boundary=if id=="H05" then "Actual avatar at permanent entry while lift is idle; its boarding/carry/reset cycle is in separate ride evidence" else "Actual avatar waits on permanent refuge through at least one complete configured cycle"
  end
 end,debug.traceback)
 state.error=if ok then nil else tostring(err)
 state.active=false
end)
return {started=true,boundary="Sequential real-avatar refuge waits; no simultaneous-client claim"}

