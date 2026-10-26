local p=game:GetService("Players").LocalPlayer
local c=workspace.KeyboardCircuit_P1_C08
local enter=c.S02_ThockySwitchworks.O04_EnterHairpin
local f=p.PlayerGui.KeyboardCircuitAudition
local d=f.Diagnostics:Invoke()
local held
for _,s in d.held do if s.key==enter.EnterStem.KeyTop:GetFullName()then held=s end end
local enabled=0;local visuals=0
for _,v in workspace.CurrentCamera:GetDescendants()do if v.Name=="LocalKeyPress"then visuals+=1;for _,g in v:GetDescendants()do if g:IsA("SurfaceGui") and g.Name=="Legend" and g.Enabled then enabled+=1 end end end end
local out={held=held,enabledCloneLegends=enabled,localVisuals=visuals,primaryOriginalEnabled=enter.EnterStem.KeyTop.Legend.Enabled,secondaryOriginalEnabled=enter.EnterReturn.KeyTop.Legend.Enabled,ground=p.Character:FindFirstChildOfClass("Humanoid").FloorMaterial.Name,diagnostic=d}
out.passed=held~=nil and held.amount==1 and held.visuals==4 and enabled==1 and visuals==4 and not out.primaryOriginalEnabled and not out.secondaryOriginalEnabled and out.ground~="Air"
return out
