--!nonstrict
local M,state={}
local R,H=game.RunService,game.HttpService
function M.Start(name,a,b,lookA,lookB)
assert(not R:IsRunning() and not state and workspace.Course_MoonlitCitadel:GetAttribute("SourceRevision")==49)
R:UnbindFromRenderStep("EnclosureCapturePose49")
local ca,cb=CFrame.lookAt(a,lookA),CFrame.lookAt(b,lookB)
local t0=os.clock()
state={name=name,sourceHash=workspace.Course_MoonlitCitadel:GetAttribute("SourcePacketHash"),clock=game.Lighting.ClockTime,shadows=game.Lighting.GlobalShadows,hover=settings().Studio["Show Hover Over"],frames={},renderFrames=0,last=-1,started=t0}
local s=state
R:BindToRenderStep("EnclosureMoving49",Enum.RenderPriority.Camera.Value+1,function()
local elapsed=os.clock()-t0
if elapsed>45 then R:UnbindFromRenderStep("EnclosureMoving49");return end
local cycle=(elapsed%4)/2;local alpha=if cycle<=1 then cycle else 2-cycle
local c=workspace.CurrentCamera;c.CameraType=Enum.CameraType.Scriptable;c.CFrame=ca:Lerp(cb,alpha);c.Focus=CFrame.new(lookA:Lerp(lookB,alpha))
s.renderFrames+=1
if elapsed-s.last>=.05 then s.last=elapsed;table.insert(s.frames,{time=elapsed,alpha=alpha,cf={c.CFrame:GetComponents()}}) end
end)
task.wait(.25)
return H:JSONEncode({started=name,hash=s.sourceHash,clock=s.clock,shadows=s.shadows,hover=s.hover})
end
function M.Stop()
assert(state);R:UnbindFromRenderStep("EnclosureMoving49");state.duration=os.clock()-state.started;state.started=nil;state.last=nil;local result=state;state=nil
return H:JSONEncode(result)
end
return M