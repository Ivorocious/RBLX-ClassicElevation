local candidate=workspace.KeyboardCircuit_P2_C01
local controls=candidate.StudioProbeControls
local player=game.Players:GetPlayerByUserId(86069177)
local state={active=true,records={}}
shared.KCP2ContactProbe=state
local function await(callback,seconds)
 local began=os.clock()
 repeat if callback() then return true end;task.wait(.02) until os.clock()-began>seconds
 return callback()
end
task.spawn(function()
 local ok,err=xpcall(function()
  for _,case in {{id="H04",body="Head"},{id="H04",body="HumanoidRootPart"},{id="H07",body="HumanoidRootPart"},{id="H08",body="HumanoidRootPart"}} do
   local unit
   for _,v in candidate.Districts:GetDescendants() do if v:IsA("Model") and v:GetAttribute("MechanismId")==case.id then unit=v;break end end
   local shape
   for _,v in unit:GetDescendants() do if v:IsA("BasePart") and v.Name=="Contact" and v:GetAttribute("Role")=="Lethal" then shape=v;break end end
   assert(shape)
   local current=controls.State:Invoke()
   local before=current.participants[tostring(player.UserId)]
   assert(current.active and before and before.active)
   local bank=candidate.RecoveryPads[before.recoveryGate].BankContact
   local character,root,humanoid=player.Character,player.Character.HumanoidRootPart,player.Character:FindFirstChildOfClass("Humanoid")
   character:PivotTo(CFrame.new(bank.Position+Vector3.new(0,bank.Size.Y/2+humanoid.HipHeight+root.Size.Y/2+.1,0)))
   root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
   task.wait(1)
   local body=character[case.body]
   local target=if case.body=="Head" then shape.CFrame:PointToWorldSpace(Vector3.new(0,-shape.Size.Y/2+.1,0)) else shape.Position
   character:PivotTo(character:GetPivot()+target-body.Position)
   root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
   local params=OverlapParams.new()
   params.FilterType,params.FilterDescendantsInstances,params.RespectCanCollide=Enum.RaycastFilterType.Include,{character},false
   local overlap={}
   for _,v in workspace:GetPartsInPart(shape,params) do if not v:FindFirstAncestorWhichIsA("Accessory") then table.insert(overlap,v.Name) end end
   local record={id=case.id,body=case.body,before=before,shape=shape:GetFullName(),phase=shape.Parent:GetAttribute("CycleState"),overlap=overlap,nativeExecuted=true}
   table.insert(state.records,record)
   record.recovered=await(function() return controls.State:Invoke().participants[tostring(player.UserId)].recoveries>before.recoveries end,1.5)
   local after=controls.State:Invoke()
   record.after=after.participants[tostring(player.UserId)]
   record.reason=after.recoveries[#after.recoveries] and after.recoveries[#after.recoveries].reason
   local ray=RaycastParams.new()
   ray.FilterType,ray.FilterDescendantsInstances,ray.RespectCanCollide=Enum.RaycastFilterType.Include,{bank},true
   record.recoverySupport=workspace:Raycast(root.Position,Vector3.new(0,-7,0),ray)~=nil
   record.passed=record.recovered and record.recoverySupport and record.reason==case.id.."Contact" and record.after.nextGate==before.nextGate and record.after.lap==before.lap and record.after.recoveryGate==before.recoveryGate and table.find(overlap,case.body)~=nil
   if case.body=="Head" then record.headOnlyFromRoot=table.find(overlap,"HumanoidRootPart")==nil;record.passed=record.passed and record.headOnlyFromRoot end
   record.boundary="Actual avatar intentionally positioned into live lethal geometry; native overlap and authoritative retained-checkpoint recovery. This is contact coverage, not traversal difficulty."
  end
 end,debug.traceback)
 state.error=if ok then nil else tostring(err)
 state.active=false
end)
return {started=true,cases=4}

