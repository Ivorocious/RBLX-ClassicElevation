local candidate = workspace.KeyboardCircuit_P1_C08
local bank = candidate.S02_ThockySwitchworks.H04_FallingKeyFoundry.CrossingBank
local drop = candidate.S02_ThockySwitchworks.H04_FallingKeyFoundry.Drop1
local player = game:GetService("Players").LocalPlayer
local root = player.Character.HumanoidRootPart
local key = bank.Key_3_2
local started = os.clock()
repeat task.wait(.02) until candidate:GetAttribute("KCElapsed")%6.6>5.65 and candidate:GetAttribute("KCElapsed")%6.6<5.95 or os.clock()-started>7.2
assert(drop:GetAttribute("CycleState")=="Clear", "Clear staging window not reached")
root.CFrame = CFrame.new(key.Position.X,key.Position.Y+.425-.45+3.2,key.Position.Z)
root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
task.wait(.25)
local folder = player.PlayerGui:FindFirstChild("KeyboardCircuitAudition")
assert(folder and folder:FindFirstChild("Diagnostics"),"Native feedback missing")
local clear = folder.Diagnostics:Invoke()
started=os.clock()
repeat task.wait(.01) until drop:GetAttribute("CycleState")=="Warning" or os.clock()-started>1.5
task.wait(.08)
local warning = folder.Diagnostics:Invoke()
local originalFrame=key.Legend.DropWarning
local visuals={}
for _,visual in workspace.CurrentCamera:GetChildren() do
 if visual:IsA("BasePart") and visual.Name=="LocalKeyPress" and visual:GetAttribute("DropWarningIndex")==1 then
  local frame=visual.Legend.DropWarning
  table.insert(visuals,{legend=visual:GetAttribute("KeyLegend"),position=tostring(visual.Position),backgroundTransparency=frame.BackgroundTransparency,strokeColor=tostring(frame.UIStroke.Color),arrow=frame:FindFirstChildWhichIsA("TextLabel") and frame:FindFirstChildWhichIsA("TextLabel").Text})
 end
end
local held=false
for _,entry in warning.held do if entry.key==key:GetFullName() and entry.held and entry.amount==1 then held=true end end
local passed=held and drop:GetAttribute("CycleState")=="Warning" and math.abs(originalFrame.BackgroundTransparency-.45)<1e-6 and #visuals>0
for _,visual in visuals do if math.abs(visual.backgroundTransparency-.45)>1e-6 or visual.strokeColor~=tostring(originalFrame.UIStroke.Color) then passed=false end end
local receipt={label="Actual held foundry cap copies the server Warning border and arrow",passed=passed,
phase=candidate:GetAttribute("KCElapsed")%6.6,state=drop:GetAttribute("CycleState"),held=held,
original={backgroundTransparency=originalFrame.BackgroundTransparency,strokeColor=tostring(originalFrame.UIStroke.Color),position=tostring(key.Position)},
pressedVisuals=visuals,clear=clear,warning=warning,
limitation="One native R15 avatar staged on a marked bank cell, then actual grounded occupancy and replicated warning state; not a human recognition judgment."}
shared.KC08WarningContact=receipt
return receipt