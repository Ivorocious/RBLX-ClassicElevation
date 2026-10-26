local c=workspace.KeyboardCircuit_P2_C01
local p=assert(shared.KCP2TraversalProbe)
local player=game.Players.LocalPlayer
local u
for _,v in c.Districts:GetDescendants() do if v:IsA("Model") and v:GetAttribute("MechanismId")=="H07" then u=v;break end end
assert(u)
local frame=u:GetAttribute("EncounterFrame")
local entry, crossing, exit=u.EntryBank.BankContact,u.CrossingBank.BankContact,u.ExitBank.BankContact
shared.KCP2SweepTraversal={active=true,steps={}}
task.spawn(function()
 local r=shared.KCP2SweepTraversal
 local complete,failure=xpcall(function()
  r.setup=p.Place(entry)
  r.beganRecoveries=player:GetAttribute("KCPhase2Recoveries")
  local deadline=os.clock()+12
  while u.SweepArm:GetAttribute("CycleState")=="Rest" and os.clock()<deadline do task.wait(.03) end
  while u.SweepArm:GetAttribute("CycleState")~="Rest" and os.clock()<deadline do task.wait(.03) end
  assert(u.SweepArm:GetAttribute("CycleState")=="Rest","Fresh rest window required")
  r.enteredAt=workspace:GetServerTimeNow()
  local function step(label,callback)
   local result={label=label,at=workspace:GetServerTimeNow(),cycle=u.SweepArm:GetAttribute("CycleState")}
   table.insert(r.steps,result)
   result.passed=callback()
   assert(result.passed,label)
  end
  step("Entry to live crossing",function() return p.Cross("H07 early approach",entry,crossing) end)
  step("Jump through low-arm corridor",function() return p.Move("H07 low-arm jump",frame:PointToWorldSpace(Vector3.new(8,.425,0)),true,crossing,3,.6) end)
  step("Crossing to permanent exit",function() return p.Cross("H07 continuous exit",crossing,exit) end)
  r.finishedRecoveries=player:GetAttribute("KCPhase2Recoveries")
  r.passed=r.beganRecoveries==r.finishedRecoveries
  r.duration=workspace:GetServerTimeNow()-r.enteredAt
 end,debug.traceback)
 r.error=if complete then nil else failure
 if not complete then r.passed=false end
 r.active=false
end)
return {started=true,boundary="Real avatar, fresh visible admission, continuous movement and jump in exposed sweep corridor; staged setup only at approach"}
