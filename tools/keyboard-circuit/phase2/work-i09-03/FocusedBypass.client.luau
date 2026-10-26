--!strict
local RunService, Players, Http = game:GetService("RunService"), game:GetService("Players"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient())
assert(not shared.KCP2I09Race or not shared.KCP2I09Race.active)
local player = Players.LocalPlayer
local candidate = workspace.KeyboardCircuit_P2_I09_Experience03
assert(candidate:GetAttribute("PrototypeRevision") == "KC_P2_I09_03")
local probe = assert(shared.KCP2I09TraversalProbe)
local clicky = candidate.Districts.S04_ClickyRelay
local tests = {
 {"H01Entry to O08Exit", clicky.H01_ShiftWindows.EntryBank.BankContact, clicky.O08.Exit.BankContact},
 {"H08Refuge to Finish", clicky.H08_DominoKeyCascade.PermanentCtrlRefuge.BankContact, candidate.CheckpointBays.F01.BankContact},
 {"H01Refuge to Enter2", clicky.H01_ShiftWindows.PermanentCtrlRefuge.BankContact, clicky.O08.LongEnter2.KeyContact},
 {"O08Entry to Finish", clicky.O08.Entry.BankContact, candidate.CheckpointBays.F01.BankContact},
}
local rows = {}
shared.KCP2I09BypassRows06 = rows
for _, test in tests do
 local reply = game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action="KeyboardCircuitTest"})
 assert(reply.ok,reply.message)
 task.wait(1)
 for _,gate in {"CP1","CP2","CP3"} do
  local bank=candidate.CheckpointBays[gate].BankContact
  probe.Place(bank,bank.CFrame:PointToWorldSpace(Vector3.new(-6,0,0)))
  task.wait(.5)
  assert(probe.Move(gate.." focused bypass gate",bank.CFrame:PointToWorldSpace(Vector3.new(6,0,0)),false,bank,4,.4))
  task.wait(.25)
  assert(player:GetAttribute("KCPhase2NextGate")==({CP1="CP2",CP2="CP3",CP3="F01"})[gate],"Ordered prerequisite gate")
 end
 local from, to = test[2], test[3]
 local setup = probe.Place(from)
 local before = Http:JSONDecode(candidate:GetAttribute("KCPhase2ServerDiagnostics")).participants[tostring(player.UserId)]
 local started = os.clock()
 local arrived = probe.Cross(test[1],from,to)
 task.wait(.25)
 local after = Http:JSONDecode(candidate:GetAttribute("KCPhase2ServerDiagnostics")).participants[tostring(player.UserId)]
 local row = {label=test[1],from=from:GetFullName(),to=to:GetFullName(),setup=setup,arrived=arrived,elapsed=os.clock()-started,
  before=before,after=after,movement={walkSpeed=player.Character.Humanoid.WalkSpeed,jumpHeight=player.Character.Humanoid.JumpHeight,useJumpPower=player.Character.Humanoid.UseJumpPower,gravity=workspace.Gravity}}
 table.insert(rows,row)
 assert(not arrived,test[1].." unmarked direct bypass reached intended support")
 assert(after and not after.finished and after.completedLaps==0 and after.nextGate=="F01",test[1].." gave unearned progress")
end
probe.Stop()
shared.KCP2I09BypassReceipt06 = {candidate=candidate.Name,revision=candidate:GetAttribute("PrototypeRevision"),passed=true,tests=rows,records=probe.Records(),
 cleanup="Probe input cleared and render binding removed",
 boundary="Four bounded actual ordinary Move/Jump attempts from staged safe-bank departures. Each starts after legitimate staged CP1/CP2/CP3 crossings and must fail to reach the unintended landing or earn F01 progress. Separate from continuous race timing; this is not exhaustive human shortcut proof."}
return Http:JSONEncode(shared.KCP2I09BypassReceipt06)
