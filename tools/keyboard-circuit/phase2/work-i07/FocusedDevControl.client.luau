--!strict
local RunService,Players,Http=game:GetService("RunService"),game:GetService("Players"),game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient())
assert(not shared.KCP2I07Race or not shared.KCP2I07Race.active)
local player=Players.LocalPlayer
local c=workspace.KeyboardCircuit_P2_I07_Final06
local remote=game.ReplicatedStorage.Remotes.StudioDevControl
local gui=player.PlayerGui:FindFirstChild("StudioDevControls")
local button=gui and gui.Panel:FindFirstChild("KeyboardCircuitShorterRoutes")
assert(gui and gui.Enabled and gui.Toggle.Visible and button and button.Text=="Keyboard Circuit — Timing Pass","F6 control caption/availability")
local function state()
 local diagnostics=Http:JSONDecode(c:GetAttribute("KCPhase2ServerDiagnostics"))
 local row=diagnostics.participants[tostring(player.UserId)]
 local root=player.Character.HumanoidRootPart
 local ray=RaycastParams.new()
 ray.FilterType,ray.FilterDescendantsInstances,ray.RespectCanCollide=Enum.RaycastFilterType.Include,{c},true
 local hit=workspace:Raycast(root.Position,Vector3.new(0,-8,0),ray)
 return {participant=player:GetAttribute("KCPhase2Candidate"),server=row,support=hit and hit.Instance:GetFullName(),root={root.Position.X,root.Position.Y,root.Position.Z},
  onboardingReady=player:GetAttribute("OnboardingReady"),arrivalOpen=player:GetAttribute("ArrivalOpen"),rootAnchored=root.Anchored}
end
local rows={}
for _,action in { "entry","restart" } do
 local reply=remote:InvokeServer({action="KeyboardCircuitTest"})
 assert(reply.ok,reply.message)
 task.wait(1)
 local after=state()
 assert(after.participant==c.Name and after.server and after.server.active and not after.server.finished and after.server.completedLaps==0 and after.server.nextGate=="CP1" and after.server.recoveries==0,action.." clean state")
 assert(after.support==c.CheckpointBays.F00.BankContact:GetFullName() and not after.rootAnchored,action.." permanent start support")
 table.insert(rows,{action=action,reply=reply,after=after})
end
local reply=remote:InvokeServer({action="Teleport",destination="Lobby"})
assert(reply.ok,reply.message)
task.wait(1)
local exited=state()
assert(exited.participant~=c.Name and not exited.server and not exited.rootAnchored,"Lobby detach")
table.insert(rows,{action="Lobby",reply=reply,after=exited})
local entered=remote:InvokeServer({action="KeyboardCircuitTest"})
assert(entered.ok,entered.message)
task.wait(1)
local ready=state()
assert(ready.participant==c.Name and ready.server and ready.server.nextGate=="CP1" and ready.support==c.CheckpointBays.F00.BankContact:GetFullName(),"Owner ready")
shared.KCP2I07DevControlReceipt06={candidate=c.Name,revision=c:GetAttribute("PrototypeRevision"),passed=true,button={path=button:GetFullName(),text=button.Text,toggleText=gui.Toggle.Text,enabled=gui.Enabled},tests=rows,ownerReady=ready,
 boundary="Existing action bound to the F6 course-test button invoked through its real Studio server remote: clean entry, restart, Lobby detach and fresh supported owner start. UI caption/toggle inspected; no mouse/keyboard, camera, computer control, publication or stored player data changes."}
return Http:JSONEncode(shared.KCP2I07DevControlReceipt06)
