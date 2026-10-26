--!nonstrict
local M,state={},nil
local R,H=game.RunService,game.HttpService
local binding="MoonlitCloseoutMoving51"
function M.Start(name,a,b,look)
 assert(not R:IsRunning() and not state)
 assert(workspace.Course_MoonlitCitadel:GetAttribute("SourceRevision")==51)
 assert(math.abs(game.Lighting.ClockTime-19.2)<.001)
 local camera=workspace.CurrentCamera
 local original={cf=camera.CFrame,focus=camera.Focus,kind=camera.CameraType,fov=camera.FieldOfView,hover=settings().Studio["Show Hover Over"]}
 settings().Studio["Show Hover Over"]=false
 local ca,cb=CFrame.lookAt(a,look),CFrame.lookAt(b,look)
 local started=os.clock()
 state={name=name,source=51,packet=workspace.Course_MoonlitCitadel:GetAttribute("SourcePacketHash"),clock=game.Lighting.ClockTime,shadows=game.Lighting.GlobalShadows,hover=false,startUtcMillis=DateTime.now().UnixTimestampMillis,frames={},renderFrames=0,last=-1,original=original}
 local s=state
 R:BindToRenderStep(binding,Enum.RenderPriority.Camera.Value+1,function()
  local elapsed=os.clock()-started
  if elapsed>55 then R:UnbindFromRenderStep(binding);return end
  local cycle=(elapsed%4)/2;local alpha=if cycle<=1 then cycle else 2-cycle
  camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=70;camera.CFrame=ca:Lerp(cb,alpha);camera.Focus=CFrame.new(look)
  s.renderFrames+=1
  if elapsed-s.last>=.05 then s.last=elapsed;table.insert(s.frames,{time=elapsed,utcMillis=DateTime.now().UnixTimestampMillis,alpha=alpha,cf={camera.CFrame:GetComponents()}}) end
 end)
 state.started=started
 task.wait(1)
 return H:JSONEncode({name=name,started=state.startUtcMillis,source=51,packet=state.packet,clock=state.clock,shadows=state.shadows,hover=false})
end
function M.Stop()
 assert(state);R:UnbindFromRenderStep(binding)
 local s=state;state=nil;s.duration=os.clock()-s.started;s.endUtcMillis=DateTime.now().UnixTimestampMillis
 local c=workspace.CurrentCamera;c.CFrame=s.original.cf;c.Focus=s.original.focus;c.CameraType=s.original.kind;c.FieldOfView=s.original.fov
 settings().Studio["Show Hover Over"]=s.original.hover
 s.original=nil;s.started=nil;s.last=nil
 local raw=H:JSONEncode(s);local old=H.HttpEnabled
 local ok,response=pcall(function()if not old then H.HttpEnabled=true end;return H:RequestAsync({Url="http://127.0.0.1:56118/closeout_moving_"..s.name..".json",Method="POST",Headers={["Content-Type"]="application/json"},Body=raw})end)
 if H.HttpEnabled~=old then H.HttpEnabled=old end
 assert(ok,response);assert(response.Success,response.Body)
 return H:JSONEncode({name=s.name,duration=s.duration,renderFrames=s.renderFrames,poseSamples=#s.frames,source=51,receipt=H:JSONDecode(response.Body),httpRestored=H.HttpEnabled==old})
end
return M