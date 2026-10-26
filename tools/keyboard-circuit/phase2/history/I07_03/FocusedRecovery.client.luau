--!strict
local RunService, Http, Players = game:GetService("RunService"), game:GetService("HttpService"), game:GetService("Players")
assert(RunService:IsStudio() and RunService:IsClient())
assert(not shared.KCP2I07Race or not shared.KCP2I07Race.active)
local player = Players.LocalPlayer
local candidate = workspace.KeyboardCircuit_P2_I07_Final
assert(candidate:GetAttribute("PrototypeRevision") == "KC_P2_I07_03")
local probe = assert(shared.KCP2I07TraversalProbe)
local results = {}
shared.KCP2I07RecoveryFocused03 = results
local function currentState()
 return Http:JSONDecode(candidate:GetAttribute("KCPhase2ServerDiagnostics")).participants[tostring(player.UserId)]
end
local function waitFor(predicate, seconds)
 local began=os.clock()
 repeat if predicate() then return true end; task.wait(.05) until os.clock()-began>seconds
 return false
end
for _, gate in {"F00","CP1","CP2","CP3"} do
 if gate ~= "F00" then
  local bank = candidate.CheckpointBays[gate].BankContact
  local setup = probe.Place(bank,bank.CFrame:PointToWorldSpace(Vector3.new(-6,0,0)))
  task.wait(.5)
  assert(probe.Move(gate.." focused gate",bank.CFrame:PointToWorldSpace(Vector3.new(6,0,0)),false,bank,4,.4))
  assert(waitFor(function() local state=currentState(); return state and state.recoveryGate==gate end,2),gate.." gate receipt")
  table.insert(results,{event="focused-gate",gate=gate,setup=setup,state=currentState()})
 end
 local before=currentState()
 assert(before and before.recoveryGate==gate and not before.finished)
 assert(waitFor(function() return player.Character.HumanoidRootPart.AssemblyLinearVelocity.Magnitude<.8 end,2))
 task.wait(.8)
 local root = player.Character.HumanoidRootPart
 player.Character:PivotTo(CFrame.new(root.Position.X,candidate:GetAttribute("Origin").Y-18,root.Position.Z))
 root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
 assert(waitFor(function() return player:GetAttribute("KCPhase2Recoveries")==before.recoveries+1 end,3),gate.." fall recovery")
 task.wait(.8)
 local after=currentState()
 local ray=RaycastParams.new()
 ray.FilterType,ray.FilterDescendantsInstances,ray.RespectCanCollide=Enum.RaycastFilterType.Include,{candidate},true
 local support=workspace:Raycast(root.Position,Vector3.new(0,-8,0),ray)
 local expected=candidate.CheckpointBays[gate].BankContact
 assert(support and support.Instance==expected,gate.." permanent recovery support")
 assert(after.nextGate==before.nextGate and after.completedLaps==before.completedLaps and after.recoveryGate==gate)
 local latest
 for _, row in Http:JSONDecode(candidate:GetAttribute("KCPhase2ServerDiagnostics")).recoveries do if row.userId==player.UserId then latest=row end end
 assert(latest and latest.reason=="Fall" and latest.checkpoint==gate)
 table.insert(results,{event="fall-recovery",gate=gate,before=before,after=after,serverRecord=latest,support=support.Instance:GetFullName(),upstream=expected.CFrame:PointToObjectSpace(root.Position).X<0})
end
probe.Stop()
shared.KCP2I07RecoveryFocusedReceipt03 = {candidate=candidate.Name,revision=candidate:GetAttribute("PrototypeRevision"),passed=true,results=results,cleanup="Probe input cleared and render binding removed",
 boundary="Four real server fall recoveries on marked permanent checkpoints. Staged positioning between focused tests; ordinary movement crosses each ordered checkpoint. Separate from continuous race timing, no crowd proof."}
return Http:JSONEncode(shared.KCP2I07RecoveryFocusedReceipt03)
