local c=workspace.KeyboardCircuit_P2_C01
local Probe=assert(shared.KCP2TraversalProbe)
local player=game.Players.LocalPlayer
local state={active=true,records={}}
shared.KCP2TimedArrivals=state
local function waitFor(predicate,seconds)
 local began=os.clock()
 repeat if predicate() then return true,os.clock()-began end;task.wait(.03) until os.clock()-began>seconds
 return false,os.clock()-began
end
task.spawn(function()
 local ok,err=xpcall(function()
  for _,id in {"H03","H01"} do
   local unit
   for _,v in c.Districts:GetDescendants() do if v:IsA("Model") and v:GetAttribute("MechanismId")==id then unit=v;break end end
   local entry=unit.EntryBank.BankContact
   local actor=if id=="H03" then unit.Lane1Row1 else unit.ShiftBridge1
   local record={id=id,beforeRecoveries=player:GetAttribute("KCPhase2Recoveries"),steps={}}
   table.insert(state.records,record)
   record.setup=Probe.Place(entry)
   record.beganRecoveries=player:GetAttribute("KCPhase2Recoveries")
   assert(waitFor(function() return actor:GetAttribute("OpenWindow")==true and actor:GetAttribute("AdmissionOpen")==false end,14))
   local root=player.Character.HumanoidRootPart
   local start=root.Position
   record.arrivalPhase=actor:GetAttribute("CycleState")
   record.arrivalAdmission=actor:GetAttribute("AdmissionOpen")
   record.arrivalPhysicallyOpen=actor:GetAttribute("OpenWindow")
   task.wait(.5)
   record.safeWaitDrift=(root.Position-start).Magnitude
   record.freshAdmission,record.waitSeconds=waitFor(function() return actor:GetAttribute("AdmissionOpen")==true end,14)
   assert(record.freshAdmission,"No next admission window")
   task.wait(.5)
   record.departureAdmission=actor:GetAttribute("AdmissionOpen")
   local previous=entry
   local function cross(label,bank)
    local target=bank:FindFirstChild("BankContact") or bank.KeyContact
    local passed=Probe.Cross(label,previous,target)
    table.insert(record.steps,{label=label,passed=passed})
    previous=target
    return passed
   end
   local passed=true
   if id=="H03" then
    for i=1,3 do if not cross(id.." delayed row "..i,unit["Lane1Row"..i]) then passed=false;break end end
    if passed then passed=cross(id.." delayed exit",unit.ExitBank) end
   else
    passed=cross(id.." delayed first shift",unit.ShiftBridge1)
    if passed then passed=cross(id.." delayed refuge",unit.PermanentCtrlRefuge) end
    if passed then
     assert(waitFor(function() return unit.ShiftBridge2:GetAttribute("AdmissionOpen")==true end,14))
     passed=cross(id.." delayed second shift",unit.ShiftBridge2)
    end
    if passed then passed=cross(id.." delayed exit",unit.ExitBank) end
   end
   record.afterRecoveries=player:GetAttribute("KCPhase2Recoveries")
   record.passed=passed and record.safeWaitDrift<.8 and record.departureAdmission==true and record.afterRecoveries==record.beganRecoveries
   record.boundary="Solo actual avatar arrives during physically open but closed-admission phase, waits on entry, and departs 0.5 seconds after the next admission. No simultaneous follower or crowd claim."
  end
 end,debug.traceback)
 state.error=if ok then nil else tostring(err)
 state.active=false
end)
return {started=true,mechanisms=2}

