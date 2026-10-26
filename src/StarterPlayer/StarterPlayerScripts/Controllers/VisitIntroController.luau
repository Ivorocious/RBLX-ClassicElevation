--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Config=require(game.ReplicatedStorage.Config.GrandArcadeConfig)
local Ownership=require(script.Parent.CameraOwnership)
local Controller={}
local player=Players.LocalPlayer
local current: any=nil
local flow: any=nil
local function arrived(): boolean
 return player:GetAttribute("OnboardingReady")==true
  and player:GetAttribute("ArrivalPhase")=="Ready" and player:GetAttribute("ArrivalOpen")~=true
end
function Controller.CanStart(state: any): boolean
 return current==nil and player:GetAttribute("VisitIntroAvailable")==true and arrived() and state~=nil and state.status=="Lobby" and state.enrolled~=true
  and (not state.practice or state.practice.inRoom~=true)
end
function Controller.IsActive(): boolean return current~=nil end
function Controller.Stop()
 local owner=current; current=nil
 RunService:UnbindFromRenderStep("FirstVisitIntroCamera")
 if not owner then return end
 for _,connection in owner.connections do connection:Disconnect() end
 Ownership.Release(owner.lease)
end
function Controller.Update(state: any)
 flow=state
 if not current then return end
 local token=state and state.preparation and state.preparation.token
 if not state or state.status~="Lobby" or state.enrolled==true or token~=current.preparationToken then Controller.Stop() end
end
function Controller.GetCue(): any
 if not current then return nil end
 local fraction=math.clamp((os.clock()-current.startedAt)/Config.IntroSeconds,0,1)
 local index=math.min(3,math.floor(fraction*3)+1)
 local cues={
  {title="Your racer",message="This is your racer. Your saved look stays with you in this experience."},
  {title="Grand Arcade",message="These arches show the upcoming courses and real finishes. Practice stays open while races run."},
  {title="Start racing when you're ready",message="Choose "..tostring(flow and flow.actionLabel or "Start racing").." to join. You'll stay enrolled until you choose Take a break."},
 }
 local cue=cues[index]
 cue.step,cue.count=index,#cues
 return cue
end
function Controller.Start(state: any): boolean
 if not Controller.CanStart(state) then return false end
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local stage=workspace:FindFirstChild("GrandArcade")
 local camera=workspace.CurrentCamera
 if not humanoid or humanoid.Health<=0 or not root or not root:IsA("BasePart") or not stage or not stage:IsA("Model") or not camera then return false end
 local owner: any={character=character,humanoid=humanoid,root=root,camera=camera,origin=root.Position,startedAt=os.clock(),connections={},
  preparationToken=state.preparation and state.preparation.token,static=player:GetAttribute("ReducedMotion")==true,initial=camera.CFrame}
 current,flow=owner,state
 if not owner.static then
  owner.lease=Ownership.Acquire("Intro",Controller.Stop,false)
  if not owner.lease then current=nil; return false end
 end
 player:SetAttribute("VisitIntroAvailable",false)
 table.insert(owner.connections,humanoid.Died:Connect(Controller.Stop))
 table.insert(owner.connections,player.CharacterRemoving:Connect(Controller.Stop))
 table.insert(owner.connections,workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(Controller.Stop))
 for _,name in {"ArrivalOpen","ArrivalPhase","OnboardingReady","RaceEnrolled"} do
  table.insert(owner.connections,player:GetAttributeChangedSignal(name):Connect(function()
   if player:GetAttribute("ArrivalOpen")==true or player:GetAttribute("ArrivalPhase")~="Ready" or player:GetAttribute("OnboardingReady")~=true or player:GetAttribute("RaceEnrolled")==true then Controller.Stop() end
  end))
 end
 local stageFrame=stage:GetPivot()
 local portrait=CFrame.lookAt(root.Position+root.CFrame.LookVector*8+Vector3.new(0,3,0),root.Position+Vector3.new(0,2,0))
 local arcade=CFrame.lookAt(stageFrame:PointToWorldSpace(Config.CameraOffset),stageFrame:PointToWorldSpace(Config.CameraTarget))
 local behind=CFrame.lookAt(root.Position-root.CFrame.LookVector*12+Vector3.new(0,5,0),root.Position+Vector3.new(0,2,0))
 RunService:BindToRenderStep("FirstVisitIntroCamera",Enum.RenderPriority.Camera.Value+2,function()
  if current~=owner then return end
  local age=os.clock()-owner.startedAt
  if age>=Config.IntroSeconds or not arrived() or player:GetAttribute("RaceEnrolled")==true or player.Character~=character or humanoid.Health<=0 or humanoid.MoveDirection.Magnitude>.05 or (root.Position-owner.origin).Magnitude>.5 or not stage.Parent or workspace.CurrentCamera~=camera then Controller.Stop(); return end
  if player:GetAttribute("ReducedMotion")==true and owner.lease then Ownership.Release(owner.lease); owner.lease=nil; owner.static=true end
  if owner.static then return end
  if not Ownership.IsOwner(owner.lease) then Controller.Stop(); return end
  local segment=Config.IntroSeconds/3
  local index=math.min(3,math.floor(age/segment)+1)
  local from=if index==1 then owner.initial elseif index==2 then portrait else arcade
  local target=if index==1 then portrait elseif index==2 then arcade else behind
  local blend=math.clamp((age-(index-1)*segment)/math.min(segment,.7),0,1)
  camera.CameraType=Enum.CameraType.Scriptable
  camera.CFrame=from:Lerp(target,blend*blend*(3-2*blend))
 end)
 return true
end
return Controller
