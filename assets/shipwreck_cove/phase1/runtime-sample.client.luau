
local camera=workspace.CurrentCamera
local oldType,oldCF,oldFocus=camera.CameraType,camera.CFrame,camera.Focus
camera.CameraType=Enum.CameraType.Scriptable
camera.CFrame=CFrame.lookAt(Vector3.new(-626,59,12),Vector3.new(-620,58,-20))
local failures={} local cp=game:GetService("ContentProvider")
cp:PreloadAsync(workspace.__ShipwreckCove_Phase1:GetDescendants(),function(id,status) if status~=Enum.AssetFetchStatus.Success then table.insert(failures,{id=id,status=tostring(status)}) end end)
task.wait(1)
local frames={} local start=os.clock()
local connection=game:GetService("RunService").RenderStepped:Connect(function(dt)table.insert(frames,dt*1000)end)
task.wait(5);connection:Disconnect();table.sort(frames)
local stats=game:GetService("Stats")
local result={build=workspace.__ShipwreckCove_Phase1:GetAttribute("Build"),scenario="Dock-wreck study camera; existing City Run and lobby still running elsewhere",players=#game.Players:GetPlayers(),seconds=os.clock()-start,samples=#frames,medianFrameIntervalMs=frames[math.ceil(#frames*.5)],p95FrameIntervalMs=frames[math.ceil(#frames*.95)],memoryTotalMb=stats:GetTotalMemoryUsageMb(),viewport=tostring(camera.ViewportSize),graphicsSetting=tostring(UserSettings():GetService("UserGameSettings").SavedQualityLevel),fetchFailures=failures,limits="Desktop Studio client; mixed existing-place memory, frame interval not isolated GPU time; no real mobile or20-player measurement"}
camera.CameraType=oldType;camera.CFrame=oldCF;camera.Focus=oldFocus
script:SetAttribute("Result",game.HttpService:JSONEncode(result))

