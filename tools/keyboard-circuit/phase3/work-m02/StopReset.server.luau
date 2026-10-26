--!strict
assert(game.RunService:IsStudio() and game.RunService:IsServer())
local c=workspace.KeyboardCircuit_P3_M02_01
local runtime=require(c.SourceSnapshot.MechanismRuntime)
local controller=runtime.Start(c,function()return false end,function()return false end)
assert(controller.Diagnostics().active)
controller.Stop()
local stopped={}
for _,sign in c.MapEnvironment.HazardIndicators:GetChildren() do
 local phase=sign.DisplayPanel.HazardDisplay.Phase.Text
 assert(phase=="STOPPED",sign.Name.." retained stale phase "..phase)
 table.insert(stopped,{sign=sign.Name,phase=phase,source=sign.SourceMechanism.Value:GetAttribute("CycleState")})
end
assert(#stopped==17 and controller.Diagnostics().heartbeatConnections==0)
local reset=controller.Reset()
task.wait(.4)
local restarted={}
for _,sign in c.MapEnvironment.HazardIndicators:GetChildren() do
 local phase=sign.DisplayPanel.HazardDisplay.Phase.Text
 assert(phase~="STOPPED",sign.Name.." failed to resume")
 table.insert(restarted,{sign=sign.Name,phase=phase})
end
assert(reset.Diagnostics().active and reset.Diagnostics().heartbeatConnections==1)
local result={candidate=c.Name,passed=true,stopped=stopped,restarted=restarted,stop=controller.Diagnostics(),reset=reset.Diagnostics(),
 boundary="Original owned test runtime Stop and Reset API used; all 17 real displays inspected after both transitions. No synthetic phase writes. The test session is ended immediately afterwards to restore the Session-owned controller reference."}
shared.KCP3M02StopReset01=result
return game.HttpService:JSONEncode(result)

