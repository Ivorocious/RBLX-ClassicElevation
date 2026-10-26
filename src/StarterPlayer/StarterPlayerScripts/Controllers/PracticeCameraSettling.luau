--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Ownership=require(script.Parent.CameraOwnership)
local Config=require(game.ReplicatedStorage.Config.PracticeConfig)
local Controller={}
local connection: RBXScriptConnection?=nil
function Controller.Cancel()
 if connection then connection:Disconnect(); connection=nil end
end
function Controller.Schedule(getState: () -> any,getPractice: () -> any)
 Controller.Cancel()
 local player=Players.LocalPlayer
 local character=player.Character
 local camera=workspace.CurrentCamera
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not camera or not humanoid or not root or not root:IsA("BasePart") then return end
 local started,lastPosition,settled=os.clock(),root.Position,0
 local circuit=workspace:FindFirstChild(Config.CircuitName,true)
 connection=RunService.Heartbeat:Connect(function(dt)
  local state,practice=getState(),getPractice()
  if not state or state.status~="Lobby" or not practice or practice.inRoom~=true
   or player:GetAttribute("ArrivalOpen")==true or player:GetAttribute("ArrivalPhase")~="Ready" or player:GetAttribute("OnboardingReady")~=true
   or player.Character~=character or humanoid.Health<=0 or workspace.CurrentCamera~=camera or camera.CameraType~=Enum.CameraType.Custom
   or not Ownership.IsIdle() or humanoid.MoveDirection.Magnitude>.05 or os.clock()-started>Config.CameraSettleTimeout then Controller.Cancel(); return end
  local moved=(root.Position-lastPosition).Magnitude
  lastPosition=root.Position
  circuit=circuit or workspace:FindFirstChild(Config.CircuitName,true)
  local center=circuit and circuit:GetAttribute("Center")
  local size=circuit and circuit:GetAttribute("InteriorSize")
  if typeof(center)~="Vector3" or typeof(size)~="Vector3" then settled=0; return end
  local relative,half=root.Position-center,size*.5
  if math.abs(relative.X)>half.X+1 or math.abs(relative.Z)>half.Z+1 or relative.Y< -3 or relative.Y>half.Y+5 then settled=0; return end
  settled=if moved<.05 and root.AssemblyLinearVelocity.Magnitude<2 then settled+dt else 0
  if settled<Config.CameraSettleSeconds then return end
  local focus=root.Position+Vector3.new(0,2,0)
  camera.CameraSubject,camera.CameraType=humanoid,Enum.CameraType.Custom
  camera.CFrame=CFrame.lookAt(root.Position-root.CFrame.LookVector*Config.CameraDistance+Vector3.new(0,Config.CameraHeight,0),focus)
  camera.Focus=CFrame.new(focus)
  Controller.Cancel()
 end)
end
return Controller
