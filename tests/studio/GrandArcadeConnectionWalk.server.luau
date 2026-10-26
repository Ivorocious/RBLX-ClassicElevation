-- Run on a normal R15 fixture in the actual Studio Play lobby.
local Test={}
function Test.Run()
 local RunService=game:GetService('RunService')
 assert(RunService:IsStudio() and RunService:IsRunning(),'Studio Play required')
 assert(workspace.Lobby:FindFirstChild('GrandArcadeConnection'),'C01 must be installed')
 local Players=game:GetService('Players')
 local owner=Players:GetPlayers()[1]
 local settings=owner and owner.Character and owner.Character:FindFirstChildOfClass('Humanoid')
 assert(settings,'Player movement settings required')
 local description=Instance.new('HumanoidDescription')
 local rig=Players:CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15)
 description:Destroy()
 rig.Name,rig.Parent='GrandArcadeWalkingFixture',workspace
 local humanoid=rig:FindFirstChildOfClass('Humanoid')
 local root=rig.HumanoidRootPart
 root:SetNetworkOwner(nil)
 humanoid.WalkSpeed,humanoid.UseJumpPower=settings.WalkSpeed,settings.UseJumpPower
 humanoid.JumpHeight,humanoid.JumpPower=0,0
 humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
 local lift=humanoid.HipHeight+root.Size.Y/2
 local records={kind='Normal R15 fixture, current walking speed, actual installed route; no jump or intermediate placement',walkSpeed=humanoid.WalkSpeed,routes={}}
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={rig,owner.Character}
 params.RespectCanCollide=true
 local samples={}
 local function walk(x,z)
  local started=os.clock()
  local lastSample=0
  while os.clock()-started<10 do
   local flat=Vector3.new(x-root.Position.X,0,z-root.Position.Z)
   if os.clock()-lastSample>.2 then
    lastSample=os.clock()
    local hit=workspace:Raycast(root.Position,Vector3.new(0,-8,0),params)
    table.insert(samples,{p={root.Position.X,root.Position.Y,root.Position.Z},grounded=humanoid.FloorMaterial~=Enum.Material.Air,health=humanoid.Health,state=tostring(humanoid:GetState()),support=hit and hit.Instance:GetFullName() or ''})
   end
   if flat.Magnitude<.65 and humanoid.FloorMaterial~=Enum.Material.Air then humanoid:Move(Vector3.zero);return true end
   if humanoid.Health<=0 or root.Position.Y<368 then break end
   humanoid:Move(if flat.Magnitude>.1 then flat.Unit else Vector3.zero,false)
   RunService.Heartbeat:Wait()
  end
  humanoid:Move(Vector3.zero)
  return false
 end
 local ok,err=xpcall(function()
  root.CFrame=CFrame.new(1552,370+lift+.15,-886)
  root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
  task.wait(.5)
  local depths={-891,-894,-898,-902,-906,-910,-918,-928}
  for _,x in {1552,1544.8,1559.2} do
   samples={}
   local route={x=x,start={root.Position.X,root.Position.Y,root.Position.Z},forward={},backward={},passed=walk(x,-886)}
   for _,z in depths do local passed=walk(x,z);table.insert(route.forward,{z=z,passed=passed});route.passed=route.passed and passed;if not passed then break end end
   if route.passed then
    for i=#depths-1,1,-1 do local passed=walk(x,depths[i]);table.insert(route.backward,{z=depths[i],passed=passed});route.passed=route.passed and passed;if not passed then break end end
    route.passed=route.passed and walk(x,-886)
   end
   route.samples=samples
   route.finish={root.Position.X,root.Position.Y,root.Position.Z}
   route.health=humanoid.Health
   route.jumpDisabled=not humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) and humanoid.JumpPower==0 and humanoid.JumpHeight==0
   table.insert(records.routes,route)
   if not route.passed then break end
  end
 end,debug.traceback)
 rig:Destroy()
 if not ok then error(err)end
 return records
end
return Test
