local RunService=game:GetService('RunService')
assert(RunService:IsStudio())
local player=assert(game.Players:GetPlayers()[1])
local character=assert(player.Character)
local root=assert(character:FindFirstChild('HumanoidRootPart'))
local humanoid=assert(character:FindFirstChildOfClass('Humanoid'))
local saved={pivot=character:GetPivot(),anchored=root.Anchored,rotate=humanoid.AutoRotate,recovery=character:GetAttribute('RecoveryUntil')}
local template=game.ServerStorage.CourseLibrary.Course_ShipwreckCove
local fixture=template:Clone();fixture.Name='__SCCrumble30Probe'
fixture:PivotTo(fixture:GetPivot()+Vector3.new(900,0,0));fixture.Parent=workspace
local controller
local records={}
local config=require(game.ReplicatedStorage.Config.ShipwreckConfig)
local function check(name)
 local ok,err=pcall(function()
  local p=fixture.Obstacles.WalkingSurfaces[name]
  local v=fixture.Decoration:FindFirstChild(name,true)
  local original=p.CFrame;local visible=v.CFrame
  local marker=fixture.RouteMarkers:FindFirstChild('ExpertLanding_'..name) or fixture.RouteMarkers:FindFirstChild('CliffLanding_'..name)
  local markerFrame=marker and marker.CFrame
  controller=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Crumble).Create(fixture,{name},function(p) return p==player end)
  character:SetAttribute('RecoveryUntil',0)
  humanoid.AutoRotate=false;root.Anchored=false;root:SetNetworkOwner(nil)
  local target=p.Position+p.CFrame.UpVector*p.Size.Y/2+Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+.08,0)
  character:PivotTo(character:GetPivot()+(target-root.Position))
  root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
  local grounded=false
  for i=1,40 do
   RunService.Heartbeat:Wait()
   if humanoid.FloorMaterial~=Enum.Material.Air then grounded=true;break end
  end
  assert(grounded,'Player never grounded on '..name)
  controller.Step(0,true)
  controller.Step(.17,true)
  assert(v.CFrame~=visible,'Landing did not arm visible warning')
  root.Anchored=true
  controller.Step(config.CrumbleWarning+.02,true)
  assert(not p.CanCollide and not p.CanQuery,'Falling collision did not disable')
  controller.Step(config.CrumbleWarning+config.CrumbleFall+.05,false)
  assert((p.Position-original.Position).Y < -config.CrumbleDrop+.01,'Crumble did not drop')
  if marker then assert(math.abs((marker.Position-markerFrame.Position).Y+config.CrumbleDrop)<.01,'Landing marker stayed floating') end
  controller.Step(config.CrumbleWarning+config.CrumbleFall+config.CrumbleReset+.1,false)
  assert(p.CFrame==original and p.CanCollide and p.CanQuery,'Crumble did not recover')
  controller.Stop();controller=nil
  assert(v.CFrame==visible,'Stop did not restore visible platform')
  if marker then assert(marker.CFrame==markerFrame,'Stop did not restore marker') end
 end)
 if controller then controller.Stop();controller=nil end
 table.insert(records,{name=name,passed=ok,error=if ok then nil else tostring(err)})
end
for _,name in {'Spar02','Spar05','Spar08','Rib03','Rib07','Rib11','Cave26Stone00','S03_04'} do check(name) end
fixture:Destroy()
character:PivotTo(saved.pivot);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
root.Anchored=saved.anchored;humanoid.AutoRotate=saved.rotate;character:SetAttribute('RecoveryUntil',saved.recovery)
pcall(function() root:SetNetworkOwnershipAuto() end)
script:SetAttribute('Result',game.HttpService:JSONEncode({build=template:GetAttribute('ReviewBuild'),records=records,
 method='Actual Studio R15 grounded on each new expert crumble; controlled clock tests warning, fall, reset. Not a full live race.'}))
