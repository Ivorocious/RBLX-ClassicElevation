--!strict
local RunService, Players, Http = game:GetService("RunService"), game:GetService("Players"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient())
assert(not shared.KCP2I07Race or not shared.KCP2I07Race.active)
local player = Players.LocalPlayer
local candidate = workspace.KeyboardCircuit_P2_I07_Final05
assert(candidate:GetAttribute("PrototypeRevision") == "KC_P2_I07_05")
local probe = assert(shared.KCP2I07TraversalProbe)
local clicky = candidate.Districts.S04_ClickyRelay
local tests = {
 {"H01Entry to O08Exit", clicky.H01_ShiftWindows.EntryBank.BankContact, clicky.O08.Exit.BankContact},
 {"H08Refuge to Finish", clicky.H08_DominoKeyCascade.PermanentCtrlRefuge.BankContact, candidate.CheckpointBays.F01.BankContact},
 {"H01Refuge to Enter2", clicky.H01_ShiftWindows.PermanentCtrlRefuge.BankContact, clicky.O08.LongEnter2.KeyContact},
 {"O08Entry to Finish", clicky.O08.Entry.BankContact, candidate.CheckpointBays.F01.BankContact},
}
local rows = {}
shared.KCP2I07BypassRows05 = rows
for _, test in tests do
 local reply = game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action="KeyboardCircuitTest"})
 assert(reply.ok,reply.message)
 task.wait(1)
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
 assert(after and not after.finished and after.completedLaps==0 and after.nextGate=="CP1",test[1].." gave unearned progress")
end
probe.Stop()
shared.KCP2I07BypassReceipt05 = {candidate=candidate.Name,revision=candidate:GetAttribute("PrototypeRevision"),passed=true,tests=rows,records=probe.Records(),
 cleanup="Probe input cleared and render binding removed",
 boundary="Four bounded actual ordinary Move/Jump attempts from staged safe-bank departures. Each failed to reach the unintended landing or earn finish/progress. Separate from continuous race timing; this is not exhaustive human shortcut proof."}
return Http:JSONEncode(shared.KCP2I07BypassReceipt05)
