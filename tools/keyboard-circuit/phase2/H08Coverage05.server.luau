assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsServer())
local c=workspace.KeyboardCircuit_P2_C01
assert(c:GetAttribute("ConstructionIteration")==5)
local controls=c.StudioProbeControls
local player=assert(game.Players:GetPlayerByUserId(-1))
local u
for _,v in c.Districts:GetDescendants() do if v:IsA("Model") and v:GetAttribute("MechanismId")=="H08" then u=v end end
local actor=u.DominoPanel1
local shape=actor.Contact
local r={active=true,records={},candidate="KC_P2_C01-I05-UI01"}
shared.KCP2H08Coverage05=r
local function await(f,seconds)
 local began=os.clock()
 repeat if f() then return true end;task.wait(.02) until os.clock()-began>seconds
 return f()
end
task.spawn(function()
 local ok,err=xpcall(function()
  for _,phase in {"Upright","Tip","Reset"} do
   local before=controls.State:Invoke().participants["-1"]
   assert(before and before.active)
   local ch=player.Character
   local root=ch.HumanoidRootPart
   local h=ch:FindFirstChildOfClass("Humanoid")
   assert(not root.Anchored and h.Health>0)
   local bank=c.RecoveryPads[before.recoveryGate].BankContact
   ch:PivotTo(CFrame.new(bank.Position+Vector3.new(0,bank.Size.Y/2+h.HipHeight+root.Size.Y/2+.1,0)))
   root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
   task.wait(.5)
   assert(await(function() return actor:GetAttribute("CycleState")==phase end,15),"Phase not reached")
   ch:PivotTo(ch:GetPivot()+shape.Position-root.Position)
   root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
   local params=OverlapParams.new()
   params.FilterType,params.RespectCanCollide,params.FilterDescendantsInstances=Enum.RaycastFilterType.Include,false,{ch}
   local overlap={}
   for _,body in workspace:GetPartsInPart(shape,params) do if not body:FindFirstAncestorWhichIsA("Accessory") then table.insert(overlap,body.Name) end end
   local row={phase=phase,observedPhase=actor:GetAttribute("CycleState"),at=workspace:GetServerTimeNow(),overlap=overlap,before=before}
   table.insert(r.records,row)
   row.recovered=await(function() return controls.State:Invoke().participants["-1"].recoveries>before.recoveries end,1.5)
   local after=controls.State:Invoke()
   row.after=after.participants["-1"]
   row.reason=after.recoveries[#after.recoveries].reason
   row.passed=row.recovered and row.reason=="H08Contact" and table.find(overlap,"HumanoidRootPart")~=nil and row.after.nextGate==before.nextGate and row.after.lap==before.lap and row.after.recoveryGate==before.recoveryGate
   assert(row.passed,"Native H08 contact coverage failed")
  end
 end,debug.traceback)
 r.error=if ok then nil else tostring(err)
 r.active=false;r.passed=ok and #r.records==3
 r.boundary="Actual avatar intentionally placed into upright/tipping/resetting panel geometry. Native body overlaps and authoritative retained-progress recovery; this is hazard coverage, not traversal."
end)
return {started=true,cases=3}

