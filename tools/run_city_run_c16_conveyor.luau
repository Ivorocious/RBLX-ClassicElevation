
local function conveyorSource()
--!strict
local Conveyors = {}
function Conveyors.Create(course: Model)
 local records = {}
 for _,part in course:GetDescendants() do
  if not part:IsA("BasePart") or part:GetAttribute("ConveyorSpeed") == nil then continue end
  local marks={}
  for _,p in part.Parent:GetChildren() do
   if p:IsA("BasePart") and p:GetAttribute("ConveyorTread") then
    table.insert(marks,{part=p,relative=part.CFrame:ToObjectSpace(p.CFrame)})
   end
  end
  table.insert(records,{part=part,marks=marks})
 end
 local controller={}
 function controller.Step(elapsed: number)
  for _,r in records do
   local p=r.part;local speed=p:GetAttribute("ConveyorSpeed") or 0
   -- Anchored surface velocity carries grounded avatars without moving the beam.
   p.AssemblyLinearVelocity=p.CFrame.RightVector*speed
   local span=p.Size.X-1
   for _,mark in r.marks do
    local relative=mark.relative
    local x=(relative.X+span/2+elapsed*speed)%span-span/2
    mark.part.CFrame=p.CFrame*CFrame.new(x,relative.Y,relative.Z)*relative.Rotation
   end
  end
 end
 function controller.Stop()
  for _,r in records do
   r.part.AssemblyLinearVelocity=Vector3.zero
   for _,mark in r.marks do mark.part.CFrame=r.part.CFrame*mark.relative end
  end
 end
 return controller
end
return Conveyors

end
local source=game.ServerStorage.CourseLibrary.Course_CityRun
assert(source:GetAttribute("ReviewBuildId")=="C16_02")
local live=game.Players:GetPlayers()[1].Character
local prior=live.Archivable;live.Archivable=true;local avatar=live:Clone();live.Archivable=prior
for _,p in avatar:GetDescendants() do if p:IsA("LuaSourceContainer") then p:Destroy() end end
avatar.Name="C16ConveyorAvatar";avatar.Parent=workspace
local fixture=source:Clone();fixture.Name="C16ConveyorCourse";local origin=source:GetPivot()
fixture:PivotTo(CFrame.new(9000,100,1000));fixture.Parent=workspace
local function world(p)return fixture:GetPivot():PointToWorldSpace(origin:PointToObjectSpace(p)) end
local ctl=conveyorSource().Create(fixture)
local h,root=avatar.Humanoid,avatar.HumanoidRootPart
root:SetNetworkOwner(nil);assert(h.WalkSpeed==16)
local dir=Vector3.zero;local began=os.clock()
local beat=game:GetService("RunService").PreSimulation:Connect(function()ctl.Step(os.clock()-began);h:Move(dir,false) end)
local result=Instance.new("StringValue");result.Name="C16ConveyorAvatarResult";result.Value="Running";result.Parent=game.ServerStorage
task.spawn(function()
 local rows={}
 local ok,err=xpcall(function()
  avatar:PivotTo(CFrame.new(world(Vector3.new(3713,90,59))))
  root.AssemblyLinearVelocity=Vector3.zero
  task.wait(.5)
  local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={fixture};rays.RespectCanCollide=true
  for i=1,9 do
   local target=world(Vector3.new(3714+116*i/9,86.7+8.3*i/9,57+(-1)^i*3.3))
   if i==9 then target=world(Vector3.new(3830,95,57)) end
   local deadline=os.clock()+8
   repeat
    local delta=Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
    dir=if delta.Magnitude>1 then delta.Unit else delta
    game:GetService("RunService").Heartbeat:Wait()
    assert(root.Position.Y>target.Y-8,"Fell at turn "..i)
   until (Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)).Magnitude<.6 or os.clock()>deadline
   assert(os.clock()<=deadline,"Could not walk turn "..i)
   table.insert(rows,{turn=i,position={root.Position.X,root.Position.Y,root.Position.Z}})
  end
  dir=Vector3.zero;task.wait(.25)
  local hit=workspace:Raycast(root.Position,Vector3.new(0,-6,0),rays)
  assert(hit and h.FloorMaterial~=Enum.Material.Air,"Exit unsupported")
 end,debug.traceback)
 beat:Disconnect();ctl.Stop()
 result.Value=game:GetService("HttpService"):JSONEncode({build="C16_02",passed=ok,turns=rows,error=not ok and err or nil,method="Normal cloned avatar walks all nine counterflow beam turns; no jump/teleport after setup"})
 fixture:Destroy();avatar:Destroy()
end)
return "Started nine-turn grounded conveyor avatar check"
