--!nonstrict
-- Owned Edit-only renderer probe; source/model identity must be pinned by the caller.
return function(options)
 local R,H,E=game.RunService,game.HttpService,game.EncodingService
 assert(not R:IsRunning() and game.PlaceId==85558151074819)
 assert(workspace.Course_MoonlitCitadel:GetAttribute('SourcePacketHash')==options.packetHash)
 local S=game:GetService('StudioCaptureService')
 assert(S:CanCaptureScreenshot(),'This plugin context has no native screenshot permission; use the authorized capture tool or obtain specific permission')
 local camera=workspace.CurrentCamera
 local beforeFrame,beforeFocus,beforeType=camera.CFrame,camera.Focus,camera.CameraType
 local begin=os.clock();local last=-1;local trace={};local frames={}
 local a,b=CFrame.lookAt(options.a,options.lookA),CFrame.lookAt(options.b,options.lookB)
 local binding='MoonlitCloseoutRenderedSequence'
 R:BindToRenderStep(binding,Enum.RenderPriority.Camera.Value+1,function()
  local t=os.clock()-begin;local p=(t%4)/2;local alpha=if p<=1 then p else 2-p
  camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=a:Lerp(b,alpha);camera.Focus=CFrame.new(options.lookA:Lerp(options.lookB,alpha))
  if t-last>=.05 then last=t;table.insert(trace,{time=t,alpha=alpha,cf={camera.CFrame:GetComponents()}}) end
 end)
 local ok,err=xpcall(function()
  for i=1,options.frames or 48 do
   local t=os.clock()-begin;local shot=S:CaptureScreenshot({Format=Enum.StudioCaptureScreenshotFormat.PNG})
   local ready=os.clock()
   while shot.BufferStatus==Enum.StudioCaptureBufferStatus.Pending or shot.BufferStatus==Enum.StudioCaptureBufferStatus.NotStarted do
    assert(os.clock()-ready<8,'Native encoding timed out');task.wait()
   end
   assert(shot.BufferStatus==Enum.StudioCaptureBufferStatus.Ready,H:JSONEncode(shot:GetErrors()))
   local bytes=shot:GetBuffer();local frame={index=i,timeRequested=t,timeReady=os.clock()-begin,cf={camera.CFrame:GetComponents()},width=shot.Resolution.X,height=shot.Resolution.Y,data=buffer.tostring(E:Base64Encode(bytes))}
   if options.onFrame then frame.receipt=options.onFrame(frame);frame.data=nil end
   table.insert(frames,frame)
   task.wait(options.interval or .15)
  end
 end,debug.traceback)
 R:UnbindFromRenderStep(binding);camera.CFrame,camera.Focus,camera.CameraType=beforeFrame,beforeFocus,beforeType
 assert(ok,err)
 return {sourceHash=options.packetHash,duration=os.clock()-begin,clock=game.Lighting.ClockTime,shadows=game.Lighting.GlobalShadows,hover=settings().Studio['Show Hover Over'],trace=trace,frames=frames,originalPNGs=true,retouched=false}
end
