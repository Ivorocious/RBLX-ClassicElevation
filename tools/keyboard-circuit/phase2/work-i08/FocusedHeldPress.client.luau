--!strict
local RunService, Players, Http = game:GetService("RunService"), game:GetService("Players"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient())
assert(not shared.KCP2I08Race or not shared.KCP2I08Race.active)
local player = Players.LocalPlayer
local c = workspace.KeyboardCircuit_P2_I08_TwoLaps01
local probe = assert(shared.KCP2I08TraversalProbe)
local folder
for _,v in player.PlayerGui:GetDescendants() do
 if v:IsA("ObjectValue") and v.Name=="Candidate" and v.Value==c and v.Parent:FindFirstChild("Diagnostics") then folder=v.Parent end
end
assert(folder,"Exact candidate feedback required")
local arrow = c.Districts.S04_ClickyRelay.O07.ArrowTurnRight
local hairpin = c.Districts.S02_ThockySwitchworks.O04.EnterHairpin
local tests = {
 {"Arrow",arrow.KeyContact,arrow.KeyTop,c.Districts.S04_ClickyRelay.O07.Entry.BankContact,2},
 {"EnterStem",hairpin.EnterStem.KeyContact,hairpin.EnterStem.KeyTop,c.Districts.S02_ThockySwitchworks.O04.Exit.BankContact,4},
 {"EnterReturn",hairpin.EnterReturn.KeyContact,hairpin.EnterStem.KeyTop,c.Districts.S02_ThockySwitchworks.O04.Exit.BankContact,4},
}
local rows={}
for _,test in tests do
 local setup=probe.Place(test[2])
 task.wait(.45)
 local first,held
 for _,row in folder.Diagnostics:Invoke().held do if row.key==test[3]:GetFullName() then held=row end end
 assert(held and held.held and held.amount>=.98 and held.visuals==test[5],test[1].." held press")
 local expectedPose=test[3].CFrame*CFrame.new(0,-test[3]:GetAttribute("PressDepth"),0)
 local clone
 for _,v in workspace.CurrentCamera:GetChildren() do
  if v:IsA("MeshPart") and v.Name=="LocalKeyPress" and v.MeshId==test[3].MeshId and (v.Size-test[3].Size).Magnitude<.01 and (v.Position-expectedPose.Position).Magnitude<.03 then clone=v end
 end
 assert(clone,test[1].." visible depressed clone")
 local offset=test[3].CFrame:PointToObjectSpace(clone.Position).Y
 task.wait(.65)
 for _,row in folder.Diagnostics:Invoke().held do if row.key==test[3]:GetFullName() then first=row end end
 assert(first and first.held and first.amount>=.98,test[1].." sustained hold")
 probe.Place(test[4])
 task.wait(.45)
 local released=true
 for _,row in folder.Diagnostics:Invoke().held do if row.key==test[3]:GetFullName() and (row.held or row.amount>.01) then released=false end end
 assert(released and test[3].LocalTransparencyModifier==0 and test[3].Legend.Enabled,test[1].." clean release")
 if test[1]:find("Enter") then assert(not hairpin.EnterReturn.KeyTop.Legend.Enabled,"Joined Enter has a second visible legend") end
 table.insert(rows,{key=test[1],setup=setup,held=held,sustained=first,visualVerticalOffset=offset,pressDepth=test[3]:GetAttribute("PressDepth"),released=true,primaryLegendRestored=true})
end
probe.Stop()
shared.KCP2I08HeldPressReceipt06={candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),passed=true,tests=rows,
 cleanup="Probe input cleared and render binding removed",
 boundary="Native local held/depressed visual and clean release checks for big arrow and both joined Enter contacts. Actual staged avatar occupancy; fixed collision support is unchanged. No subjective feel/audio or multi-player claim."}
return Http:JSONEncode(shared.KCP2I08HeldPressReceipt06)
