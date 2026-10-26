--!strict
local Players = game:GetService("Players")
local CameraOwnership = {}
local active: any = nil
local priorities = {Arrival=100, Course=80, Spectate=50, Intro=30, Finale=20}

function CameraOwnership.Acquire(name: string, cancel: () -> (), holdControls: boolean?): any
 if active and priorities[active.name] > priorities[name] then return nil end
 if active then active.cancel() end
 local player = Players.LocalPlayer
 local camera = workspace.CurrentCamera
 if not camera then return nil end
 local controls = nil
 local module = player.PlayerScripts:FindFirstChild("PlayerModule")
 if holdControls and module then controls = require(module):GetControls(); controls:Disable() end
 local lease = {name=name,cancel=cancel,camera=camera,kind=camera.CameraType,subject=camera.CameraSubject,fov=camera.FieldOfView,controls=controls}
 active = lease
 player:SetAttribute("PresentationCameraOwner",name)
 return lease
end

function CameraOwnership.IsOwner(lease: any): boolean return lease ~= nil and active == lease end
function CameraOwnership.IsIdle(): boolean return active==nil end

function CameraOwnership.Release(lease: any)
 if not CameraOwnership.IsOwner(lease) then return end
 active = nil
 local player = Players.LocalPlayer
 local camera = workspace.CurrentCamera
 local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 if camera then
  camera.CameraType = Enum.CameraType.Custom
  camera.CameraSubject = humanoid or lease.subject
  camera.FieldOfView = lease.fov
 end
 if lease.controls and player:GetAttribute("ArrivalOpen") ~= true then lease.controls:Enable() end
 player:SetAttribute("PresentationCameraOwner",nil)
end

return CameraOwnership
