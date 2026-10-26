local player=game.Players.LocalPlayer
local root=player.Character.HumanoidRootPart
local camera=workspace.CurrentCamera
assert(camera.CameraType==Enum.CameraType.Custom and camera.FieldOfView==70)
local stats=game:GetService('Stats')
local times={}
local started=os.clock()
local startUtc=DateTime.now():ToIsoDate()
local connection=game:GetService('RunService').RenderStepped:Connect(function(dt) table.insert(times,dt*1000) end)
task.wait(5)
connection:Disconnect()
local elapsed=os.clock()-started
table.sort(times)
local total=0
for _,value in times do total+=value end
local measures={}
for _,name in {'SceneTriangleCount','SceneDrawcallCount','RenderCPUFrameTime','RenderGPUFrameTime','HeartbeatTimeMs','InstanceCount'} do
 local ok,value=pcall(function() return stats[name] end)
 if ok and typeof(value)=='number' then measures[name]=value
 else
  local object=stats:FindFirstChild(name,true)
  if object then local success,number=pcall(function() return object:GetValue() end);if success then measures[name]=number end end
 end
end
return game.HttpService:JSONEncode({candidate='HA_V1_04',utcStart=startUtc,utcEnd=DateTime.now():ToIsoDate(),seconds=elapsed,
 frames=#times,meanMs=total/#times,p95Ms=times[math.ceil(#times*.95)],maxMs=times[#times],wholePlaceMemoryMB=stats:GetTotalMemoryUsageMb(),
 measures=measures,camera={camera.CFrame:GetComponents()},cameraType=camera.CameraType.Name,fieldOfView=camera.FieldOfView,
 position={root.Position.X,root.Position.Y,root.Position.Z},quality=tostring(settings().Rendering.QualityLevel),savedQuality=tostring(UserSettings().GameSettings.SavedQualityLevel),
 scope='Five-second stationary solo desktop sample. Join with read-only Windows foreground sampling. Whole-place memory includes owner imports and preserved history.'})
