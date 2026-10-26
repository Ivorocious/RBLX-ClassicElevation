local RunService=game:GetService("RunService")
local Http=game:GetService("HttpService")
local player=game.Players.LocalPlayer
local state=player.PlayerGui.SGV2F01TestState
assert(not state:GetAttribute("Running") and not state:GetAttribute("BatchRunning"))
local course=workspace.RaceCourse
local char=player.Character
local root=char.HumanoidRootPart
local report={scope="Physical contact fixtures, with setup teleports: seven static bars, ordered nine-checkpoint touches, duplicate/out-of-order rejection, incomplete/complete finish gating",bars={},checkpoints={}}
local remote=game.ReplicatedStorage.Remotes.StudioDevControl
local function place(cf) char:PivotTo(cf);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
local function save() state:SetAttribute("IntegrationResults",Http:JSONEncode(report)) end
local function result()
 local data=Http:JSONDecode(assert(state:GetAttribute("LatestRaceResults")))
 for _,list in {data.activeRacers,data.placements,data.dnfs} do for _,r in list or {} do if r.userId==player.UserId then return r end end end
 error("No player result")
end
local function waitFor(fn,seconds)
 local t=os.clock()
 repeat RunService.Heartbeat:Wait() until fn() or os.clock()-t>seconds
 return fn()
end
state:SetAttribute("Running",true)
task.spawn(function()
 local ok,err=xpcall(function()
  for _,group in course.ClosingRoute:GetChildren() do
   local bar=group:FindFirstChild("RedThornCrossbar")
   if not bar or bar:GetAttribute("KitMotion") then continue end
   assert(remote:InvokeServer({action="Teleport",destination="Checkpoint",checkpointIndex=1}).ok);task.wait(.9)
   local prior=char:GetAttribute("RecoveryUntil") or 0
   place(bar.CFrame+Vector3.new(0,1,0))
   local recovered=waitFor(function()return (char:GetAttribute("RecoveryUntil") or 0)>prior end,2)
   table.insert(report.bars,{name=group.Name,recovered=recovered});save();assert(recovered,"Static bar failed "..group.Name);task.wait(1.8)
  end
  assert(remote:InvokeServer({action="Teleport",destination="Start"}).ok);task.wait(.8)
  assert(result().nextCheckpointIndex==1)
  place(course.Checkpoints.Checkpoint_003.CFrame);task.wait(.6)
  report.outOfOrderRejected=result().nextCheckpointIndex==1;assert(report.outOfOrderRejected)
  for index=1,8 do
   local cp=course.Checkpoints[string.format("Checkpoint_%03d",index)]
   place(cp.CFrame)
   assert(waitFor(function()return result().nextCheckpointIndex==index+1 end,2),"Checkpoint touch "..index.." failed")
   table.insert(report.checkpoints,{index=index,next=result().nextCheckpointIndex});save()
   if index==1 then
    place(cp.CFrame+Vector3.new(0,0,30));task.wait(.25);place(cp.CFrame);task.wait(.4)
    report.duplicateRejected=result().nextCheckpointIndex==2;assert(report.duplicateRejected)
   end
   task.wait(.4)
  end
  place(course.Finish.CFrame);task.wait(.7)
  report.incompleteFinishRejected=result().nextCheckpointIndex==9 and result().status=="Racing"
  assert(report.incompleteFinishRejected)
  place(course.Checkpoints.Checkpoint_009.CFrame)
  assert(waitFor(function()return result().nextCheckpointIndex==10 end,2))
  table.insert(report.checkpoints,{index=9,next=result().nextCheckpointIndex});save()
  place(course.Finish.CFrame)
  report.finishAccepted=waitFor(function()return result().status=="Finished" end,2)
  report.finalResult=result();assert(report.finishAccepted)
 end,debug.traceback)
 report.ok=ok;if not ok then report.error=tostring(err) end
 save();state:SetAttribute("Running",false)
end)
return {started=true}
