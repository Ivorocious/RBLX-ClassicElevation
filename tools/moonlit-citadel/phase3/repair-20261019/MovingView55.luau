local rec=game.ServerStorage.MoonlitP3ReworkRecovery.Repair20261019 local H=game:GetService("HttpService")
assert(not game:GetService("RunService"):IsRunning() and not rec:FindFirstChild("MovingView55"))
local probe=Instance.new("StringValue") probe.Name,probe.Parent="MovingView55",rec
local c=workspace.CurrentCamera local saved={frame=c.CFrame,focus=c.Focus,fov=c.FieldOfView,kind=c.CameraType}
probe:SetAttribute("Packet",workspace.Course_MoonlitCitadel:GetAttribute("SourcePacketHash"))
probe:SetAttribute("Running",true)
task.spawn(function()
 local ok,err=xpcall(function()
  local rows={} local start=os.clock()
  while os.clock()-start<10 do
   local t=os.clock()-start local offset=math.sin(t*.8)*2.6
   c.CameraType=Enum.CameraType.Fixed c.CFrame=saved.frame*CFrame.new(offset,0,0)
   c.Focus=c.CFrame*CFrame.new(0,0,-60)
   rows[#rows+1]={t=t,frame={c.CFrame:GetComponents()},clock=game.Lighting.ClockTime}
   probe.Value=H:JSONEncode(rows)
   task.wait(.04)
  end
 end,debug.traceback)
 c.CFrame,c.Focus,c.FieldOfView,c.CameraType=saved.frame,saved.focus,saved.fov,saved.kind
 probe:SetAttribute("Running",false) probe:SetAttribute("Restored",c.CFrame==saved.frame and c.Focus==saved.focus and c.FieldOfView==saved.fov and c.CameraType==saved.kind)
 if not ok then probe:SetAttribute("Error",err) end
end)
return {running=true,seconds=10,scope="Edit camera only, no scene/lighting/source mutation"}