--!strict
local RunService,Players,Http=game:GetService("RunService"),game:GetService("Players"),game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient())
assert(not shared.KCP2I09Race or not shared.KCP2I09Race.active)
local player,c=Players.LocalPlayer,workspace.KeyboardCircuit_P2_I09_Experience02
local probe=assert(shared.KCP2I09TraversalProbe)
local function state() return Http:JSONDecode(c:GetAttribute("KCPhase2ServerDiagnostics")).participants[tostring(player.UserId)] end
local function waitFor(predicate,seconds)
 local began=os.clock()
 repeat if predicate() then return true end;task.wait(.05) until os.clock()-began>=seconds
 return false
end
local result={active=true,passed=false,candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),tests={},boundary="Four staged ordinary jump attempts to skip one precision cap, at early and midpoint positions on each Expert route. Each must fail to reach its target and return to the saved permanent midpoint without advancing a gate or lap. Not exhaustive human exploit or skill proof."}
shared.KCP2I09ExpertFocused=result
task.spawn(function()
 local ok,failure=xpcall(function()
  for _,spec in {{id="X03",midpoint="R1",prerequisites={}},{id="X02",midpoint="R3",prerequisites={"CP1","CP2"}}} do
   for _,index in {1,6} do
    assert(game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action="KeyboardCircuitTest"}).ok)
    task.wait(.8)
    for _,id in spec.prerequisites do
     local bank=c.CheckpointBays[id].BankContact
     probe.Place(bank,bank.CFrame:PointToWorldSpace(Vector3.new(-6,0,0)))
     assert(probe.Move(id.." Expert probe prerequisite",bank.CFrame:PointToWorldSpace(Vector3.new(6,0,0)),false,bank,4,.4))
     task.wait(.3)
    end
    local host=c.RecoveryPads[spec.midpoint].HostContact.Value
    probe.Place(host)
    assert(waitFor(function() local s=state();return s and s.recoveryGate==spec.midpoint end,2))
    local branch
    for _,item in c.ExpertRoutes:GetChildren() do if item:GetAttribute("ExpertId")==spec.id then branch=item end end
    local from,to=branch["PrecisionLanding"..index].KeyContact,branch["PrecisionLanding"..(index+2)].KeyContact
    probe.Place(from)
    local before=state()
    local began=os.clock()
    local arrived=probe.Move(spec.id.." cap"..index.." skip attempt",to.Position,true,to,4,.4)
    assert(not arrived,"Skipping a precision cap reached the intended support")
    assert(waitFor(function() return player:GetAttribute("KCPhase2Recoveries")==before.recoveries+1 end,3),"Missing real fall recovery")
    task.wait(.5)
    local after=state()
    local latest
    for _,row in Http:JSONDecode(c:GetAttribute("KCPhase2ServerDiagnostics")).recoveries do if row.userId==player.UserId then latest=row end end
    assert(latest and latest.reason=="Fall" and latest.checkpoint==spec.midpoint,"Wrong failed-jump recovery")
    local root=player.Character.HumanoidRootPart
    local ray=RaycastParams.new()
    ray.FilterType,ray.FilterDescendantsInstances,ray.RespectCanCollide=Enum.RaycastFilterType.Include,{c},true
    local hit=workspace:Raycast(root.Position,Vector3.new(0,-8,0),ray)
    assert(hit and hit.Instance==host,"Wrong recovery support")
    assert(after.nextGate==before.nextGate and after.completedLaps==before.completedLaps and after.recoveryGate==before.recoveryGate)
    table.insert(result.tests,{branch=spec.id,cap=index,targetCap=index+2,arrived=arrived,elapsed=os.clock()-began,before=before,after=after,serverRecord=latest,support=hit.Instance:GetFullName(),checkpointLabel=player.PlayerGui.KeyboardCircuitPhase2Lap.Progress.Text})
   end
  end
 end,debug.traceback)
 probe.Stop()
 result.records=probe.Records()
 result.active,result.passed,result.error=false,ok,if ok then nil else tostring(failure)
end)
return {started=true,report="shared.KCP2I09ExpertFocused"}
