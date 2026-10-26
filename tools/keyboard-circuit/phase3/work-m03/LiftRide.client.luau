--!strict
assert(game.RunService:IsClient() and game.RunService:IsStudio())
local c=workspace.KeyboardCircuit_P3_M03_01
local h=c.Districts.S02_ThockySwitchworks.H05_SpringLift
local probe=assert(shared.KCP2I09TraversalProbe)
local setup=probe.Place(h.RideableBank.BankContact)
local startY=game.Players.LocalPlayer.Character.HumanoidRootPart.Position.Y
local entry=c.MapEnvironment.HazardIndicators.H05_LiftWarning_Entry.DisplayPanel.HazardDisplay
local exit=c.MapEnvironment.HazardIndicators.H05_LiftWarning_Exit.DisplayPanel.HazardDisplay
local rows,seen={},{}
local last,started="",os.clock()
local high=false
while os.clock()-started<22 do
 local state=h:GetAttribute("CycleState")
 local signature=tostring(state).."|"..entry.Phase.Text.."|"..exit.Phase.Text
 if signature~=last then
  last=signature
  table.insert(rows,{t=os.clock()-started,state=state,entry=entry.Phase.Text,exit=exit.Phase.Text,boarding=h:GetAttribute("BoardingWindow"),exitWindow=h:GetAttribute("ExitWindow"),height=game.Players.LocalPlayer.Character.HumanoidRootPart.Position.Y-startY})
 end
 seen[entry.Phase.Text],seen[exit.Phase.Text]=true,true
 if h:GetAttribute("ExitWindow") and exit.Phase.Text=="EXIT NOW" then high=true end
 if high and state=="Returning" and entry.Phase.Text=="LIFT RETURNING" then break end
 task.wait(.06)
end
assert(high and seen["LIFT RISING"] and seen["LIFT RETURNING"] and seen["EXIT NOW"],"Full ride warning phases missing")
probe.Place(h.ExitBank.BankContact)
probe.Stop()
local result={candidate=c.Name,passed=true,setup=setup,rows=rows,observed=seen,
 boundary="Actual staged avatar occupancy starts the original lift, then native physical ride and replicated warning displays are observed. Qualified high-dock EXIT NOW and returning state checked. No artificial phase writes, camera changes, input control or timing edits."}
shared.KCP3M03LiftRide01=result
return game.HttpService:JSONEncode(result)

