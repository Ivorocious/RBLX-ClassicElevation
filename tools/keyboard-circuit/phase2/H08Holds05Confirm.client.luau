assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient())
local c=workspace.KeyboardCircuit_P2_C01
assert(c:GetAttribute("ConstructionIteration")==5)
local player=game.Players.LocalPlayer
assert(player.UserId==-2)
local p=assert(shared.KCP2TraversalProbe)
local u
for _,v in c.Districts:GetDescendants() do if v:IsA("Model") and v:GetAttribute("MechanismId")=="H08" then u=v end end
local r={active=true,records={},staging={},candidate="KC_P2_C01-I05-UI01"}
shared.KCP2H08Holds05Confirm=r
local function fresh(actor)
 local closed=actor:GetAttribute("AdmissionOpen")~=true
 local began=os.clock()
 repeat
  if actor:GetAttribute("AdmissionOpen")~=true then closed=true end
  if closed and actor:GetAttribute("AdmissionOpen")==true then return true end
  task.wait(.02)
 until os.clock()-began>15
 return false
end
task.spawn(function()
 local ok,err=xpcall(function()
  for index=1,4 do
   local bank=u["PassageBank"..index].BankContact
   local setup
   if index>1 then assert(fresh(u["DominoPanel"..(index-1)])) end
   local staging={kind="bank",index=index,before=player:GetAttribute("KCPhase2Recoveries"),at=workspace:GetServerTimeNow()}
   setup=p.Place(bank)
   staging.after=player:GetAttribute("KCPhase2Recoveries");staging.setup=setup;table.insert(r.staging,staging)
   local row={index=index,setup=setup,beforeRecoveries=player:GetAttribute("KCPhase2Recoveries"),began=workspace:GetServerTimeNow(),samples=0,phases={}}
   table.insert(r.records,row)
   assert(p.Move("H08 clear-bank side A",bank.Position-bank.CFrame.RightVector*.8,false,bank,1,.6))
   assert(p.Move("H08 clear-bank side B",bank.Position+bank.CFrame.RightVector*.8,false,bank,1,.6))
   local began=os.clock()
   repeat
    row.samples+=1
    if index>1 then row.phases[u["DominoPanel"..(index-1)]:GetAttribute("CycleState") or "unknown"]=true end
    task.wait(.03)
   until os.clock()-began>=1
   row.afterRecoveries=player:GetAttribute("KCPhase2Recoveries")
   row.passed=row.beforeRecoveries==row.afterRecoveries
   assert(row.passed,"Clear-bank walking/hold recovered")
   local staging={kind="return-to-refuge",index=index,before=player:GetAttribute("KCPhase2Recoveries"),at=workspace:GetServerTimeNow()}
   staging.setup=p.Place(u.PermanentCtrlRefuge.BankContact)
   staging.after=player:GetAttribute("KCPhase2Recoveries");table.insert(r.staging,staging)
  end
  local setup=p.Place(u.PermanentCtrlRefuge.BankContact)
  local root=player.Character.HumanoidRootPart
  local position=root.Position
  local before=player:GetAttribute("KCPhase2Recoveries")
  local begun=c:GetAttribute("KCElapsed")
  local record={refuge=true,setup=setup,states={},drift=0,samples=0}
  table.insert(r.records,record)
  local began=os.clock()
  repeat
   record.states[u.DominoPanel1:GetAttribute("CycleState") or "unknown"]=true
   record.drift=math.max(record.drift,(root.Position-position).Magnitude)
   record.samples+=1
   task.wait(.05)
  until c:GetAttribute("KCElapsed")-begun>=10.6 or os.clock()-began>15
  record.elapsed=c:GetAttribute("KCElapsed")-begun
  record.passed=record.elapsed>=10.6 and player:GetAttribute("KCPhase2Recoveries")==before and record.drift<.8
  assert(record.passed,"Permanent refuge failed")
 end,debug.traceback)
 r.active=false;r.error=if ok then nil else tostring(err);r.passed=ok and #r.records==5
 r.boundary="Staged setups; ordinary within-bank movement and one-second holds during clear admission, not indefinite passage-bank safety. Permanent side refuge is checked through a complete 10.4-second cycle."
end)
return {started=true,bankCases=4,refugeCycle=true}

