
local c=workspace.KeyboardCircuit_P1_C05
local p=game.Players:GetPlayerByUserId(86069177)
local r=p.Character.HumanoidRootPart
local lift=c.S02_ThockySwitchworks.H05_SpringLift
shared.KCReset={active=true}
task.spawn(function()
 local result=shared.KCReset
 c.StudioProbeControls.Begin:Fire(86069177,"Sample");task.wait(.3)
 r.CFrame=CFrame.new(lift.RideableBank.PrimaryPart.Position+Vector3.new(0,3.7,0));r.AssemblyLinearVelocity=Vector3.zero
 local deadline=os.clock()+7
 while (lift.Slider.CurrentPosition<2 or lift:GetAttribute("CycleState")~="Rising") and os.clock()<deadline do task.wait(.03) end
 result.before={lift=lift.Slider.CurrentPosition,state=lift:GetAttribute("CycleState"),root=tostring(r.Position),elapsed=c:GetAttribute("KCElapsed")}
 c.StudioProbeControls.Stop:Fire();task.wait(.4)
 local units={}
 for _,v in {lift,c.H06_EarlyProof.H06_CarriageShuttle} do
  local allAnchored=true
  for _,part in v.RideableBank:GetDescendants() do if part:IsA("BasePart") and not part.Anchored then allAnchored=false end end
  table.insert(units,{name=v.Name,anchored=allAnchored,sliderEnabled=v.Slider.Enabled,target=v.Slider.TargetPosition,position=v.Slider.CurrentPosition,pivot=tostring(v.RideableBank:GetPivot().Position),boarding=v:GetAttribute("BoardingWindow"),exit=v:GetAttribute("ExitWindow"),state=v:GetAttribute("CycleState")})
 end
 result.units=units;result.drops={}
 for i=1,3 do local d=c.S02_ThockySwitchworks.H04_FallingKeyFoundry["Drop"..i];table.insert(result.drops,{name=d.Name,pivot=tostring(d:GetPivot().Position),state=d:GetAttribute("CycleState")}) end
 result.after={root=tostring(r.Position),stopped=c:GetAttribute("KCSessionStopped"),elapsed=c:GetAttribute("KCElapsed")}
 result.ok=result.before.state=="Rising" and result.after.stopped==true and result.after.elapsed==0
 result.active=false
end)
return {started=true}

