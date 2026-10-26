assert(game.PlaceId==0 and not game.RunService:IsRunning(),"owned Edit fixture only")
local camera=workspace.CurrentCamera
local before={frame=camera.CFrame,focus=camera.Focus,type=camera.CameraType}
local folder=Instance.new("Folder");folder.Name="MC_P2_C01_R04_CameraPan01";folder.Parent=game.ServerStorage
local value=Instance.new("StringValue");value.Name="ReportJSON";value.Parent=folder
local report={candidate="MC_P2_C01_R04",source="Native Edit camera movement; captured images are sparse frame observations, not video or human comfort proof",startedAt=os.clock(),frames={}}
local a=CFrame.lookAt(Vector3.new(3989,359,2647),Vector3.new(4002,355,2662))
local b=CFrame.lookAt(Vector3.new(4005,359,2647),Vector3.new(4018,355,2662))
folder:SetAttribute("State","Running")
task.spawn(function()
 local ok,err=xpcall(function()
  camera.CameraType=Enum.CameraType.Scriptable
  for i=0,400 do camera.CFrame=a:Lerp(b,i/400);local f=camera.CFrame;table.insert(report.frames,{at=os.clock(),frame={f:GetComponents()}});task.wait(.05) end
 end,debug.traceback)
 camera.CFrame,camera.Focus,camera.CameraType=before.frame,before.focus,before.type
 report.state=if ok then "Complete" else "Failed";report.failure=if not ok then tostring(err) else nil
 report.restored=camera.CFrame==before.frame and camera.Focus==before.focus and camera.CameraType==before.type
 report.endedAt=os.clock();value.Value=game.HttpService:JSONEncode(report);folder:SetAttribute("State",report.state)
end)
return game.HttpService:JSONEncode({state="Running",path=folder:GetFullName()})
