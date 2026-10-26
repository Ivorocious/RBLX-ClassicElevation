--!strict
local Players=game:GetService("Players")
local Workspace=game:GetService("Workspace")
local candidate=Workspace.KeyboardCircuit_P1_C03
local player=Players:GetPlayerByUserId(86069177)
local root=player.Character.HumanoidRootPart
local foundry=candidate.S02_ThockySwitchworks.H04_FallingKeyFoundry
local drop=foundry.Drop1
local params=OverlapParams.new()
params.FilterType,params.FilterDescendantsInstances=Enum.RaycastFilterType.Include,{player.Character}
params.RespectCanCollide=false
shared.KCContact={active=true,records={}}
local function phase(minimum,maximum)
 local began=os.clock()
 while os.clock()-began<9 do
  local p=candidate:GetAttribute("KCElapsed")%6.6
  if p>=minimum and p<maximum then return p end
  task.wait(.01)
 end
 error("Contact fixture missed its phase")
end
local function names(part)
 local out={} for _,p in Workspace:GetPartsInPart(part,params) do table.insert(out,p.Name) end return out
end
local function fixture(label,part,heightOffset)
 local p=phase(2.5,2.75)
 root.CFrame=CFrame.new(part.Position+Vector3.new(0,heightOffset,0))
 root.AssemblyLinearVelocity=Vector3.zero
 local row={label=label,phase=p,body=names(drop.Contact),plunger=names(drop.Plunger),before=tostring(root.Position)}
 table.insert(shared.KCContact.records,row)
 task.wait(.2)
 row.after,row.diagnostics=tostring(root.Position),candidate:GetAttribute("KCServerDiagnostics")
end
task.spawn(function()
 fixture("Returning key head contact",drop.Contact,-drop.Contact.Size.Y/2-2.5)
 task.wait(.9)
 fixture("Returning plunger contact above key",drop.Contact,drop.Contact.Size.Y/2+3.5)
 candidate.StudioProbeControls.Begin:Fire(86069177,"Sample")
 task.wait(.8)
 local p=phase(.75,.9)
 root.CFrame=CFrame.new(2384,339.2,-1304)
 root.AssemblyLinearVelocity=Vector3.zero
 local row={label="Warning followed by actual falling contact",phase=p,before=tostring(root.Position)}
 table.insert(shared.KCContact.records,row)
 task.wait(1)
 row.after,row.diagnostics=tostring(root.Position),candidate:GetAttribute("KCServerDiagnostics")
 shared.KCContact.active=false
end)
return {started=true}
