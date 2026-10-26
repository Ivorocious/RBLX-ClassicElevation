--!strict
assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient())
local c=workspace.KeyboardCircuit_P3_M04_01
local o=c.Districts.S03_ClackyCarriage.O05
local probe=assert(shared.KCP2I09TraversalProbe)
local player=game.Players.LocalPlayer
local feedback=assert(player.PlayerGui:FindFirstChild("KeyboardCircuitAudition"))
assert(feedback.Candidate.Value==c and feedback:FindFirstChild("Diagnostics"))
local rows={}
for _,pair in {{o.BracketLeft,o.BracketLeft.TopArm},{o.BracketRight,o.BracketRight.BottomArm}} do
 local bank,extension=pair[1],pair[2]
 local setup=probe.Place(bank.BankContact)
 local arrived=probe.Move(bank.Name.." extension",extension.BankContact.Position,false,extension.BankContact,3,.3)
 assert(arrived,bank.Name.." extension lacks continuous support")
 task.wait(.45)
 local held={}
 for _,row in feedback.Diagnostics:Invoke().held do
  if row.key:find(extension:GetFullName(),1,true) and row.held and row.amount>.98 then table.insert(held,row) end
 end
 assert(#held>0 and #held<=2,bank.Name.." extension press occupancy")
 assert(probe.Move(bank.Name.." return",bank.BankContact.Position,false,bank.BankContact,3,.5))
 task.wait(.45)
 for _,row in feedback.Diagnostics:Invoke().held do assert(not row.key:find(extension:GetFullName(),1,true) or not row.held,bank.Name.." extension remained held") end
 table.insert(rows,{bank=bank.Name,setup=setup,held=held,continuousSupport=true,released=true})
end
probe.Stop()
shared.KCP3M04BracketReceipt01={candidate=c.Name,passed=true,tests=rows,movement=probe.Records(),
 boundary="Native staged avatar start, then continuous humanoid walking from each repaired main bank to its extension and back. Real support and held/released local key feedback; no camera or computer control."}
return game.HttpService:JSONEncode(shared.KCP3M04BracketReceipt01)

