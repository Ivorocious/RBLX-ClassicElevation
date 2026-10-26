--!strict
local RunService, Players, Http = game:GetService("RunService"), game:GetService("Players"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient())
assert(not shared.KCP2I09Race or not shared.KCP2I09Race.active)
local c, player = workspace.KeyboardCircuit_P2_I09_Experience03, Players.LocalPlayer
local setup, Factory = assert(shared.KCP2I09TraversalProbe), assert(shared.KCP2I09EfficientTraversal)
local Motion = require(c.SourceSnapshot.Motion)
local Timing = assert(shared.KCP2I09Timing)
local unit = c.Districts.S04_ClickyRelay.H08_DominoKeyCascade
local report = {active=true,passed=false,trials={},candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),boundary="Three focused ordinary domino traversals with different initial waiting offsets. Staged setup between trials; visible admission, centered landings and zero contacts required. Separate from full race timing."}
shared.KCP2I09DominoFocused = report
local driver
local function guard()
 assert(player:GetAttribute("KCPhase2Candidate")==c.Name and player.Character.Humanoid.Health>0)
 assert(player:GetAttribute("KCPhase2Recoveries")==0,"Unexpected authoritative recovery")
 assert(math.abs(player.Character.Humanoid.WalkSpeed-16)<.001 and math.abs(player.Character.Humanoid.JumpHeight-7.2)<.001 and not player.Character.Humanoid.UseJumpPower and math.abs(workspace.Gravity-196.2)<.001)
end
local worker = task.spawn(function()
 local ok, failure = xpcall(function()
  for _,offset in {0,2,4} do
   assert(game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action="KeyboardCircuitTest"}).ok)
   task.wait(.8)
   local trial = {offset=offset,setup=setup.Place(unit.EntryBank.BankContact)}
   table.insert(report.trials,trial)
   driver=Factory.New(c,player,guard)
   task.wait(offset)
   local previous=unit.EntryBank.BankContact
   for index=1,4 do
    local target=unit["PassageBank"..index].BankContact
    local panelIndex=math.max(1,index-1)
    local started=os.clock()
    repeat
     guard()
     local remaining=Timing.Remaining("Domino",c:GetAttribute("KCElapsed") or 0,panelIndex,Motion.Tuning("Domino"))
     if unit["DominoPanel"..panelIndex]:GetAttribute("AdmissionOpen")==true and remaining>=1.7 then break end
     assert(os.clock()-started<18,"No bounded admission")
     task.wait(.02)
    until false
    local direction=driver.Prepare("Domino focused passage"..index,previous,target)
    assert(driver.Cross("Domino focused passage"..index,previous,target,direction,target.Position))
    assert(driver.Move("Domino focused center"..index,target.Position,false,target,{precision=true,tolerance=.2,stopRadius=.1,holdOnArrival=true}))
    previous=target
   end
   assert(driver.Cross("Domino focused exit",previous,unit.ExitBank.BankContact))
   trial.passed,trial.records,trial.cleanup=true,driver.Records(),driver.Stop()
  end
 end,debug.traceback)
 if driver then driver.Stop() end
 setup.Stop()
 report.active,report.passed,report.error=false,ok,if ok then nil else tostring(failure)
end)
return {started=true,report="shared.KCP2I09DominoFocused"}
