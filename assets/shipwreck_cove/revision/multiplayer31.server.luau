local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
assert(RunService:IsStudio())
local layout=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local template=game.ServerStorage.CourseLibrary.Course_ShipwreckCove
assert(template:GetAttribute("ReviewBuild")=="SC31_CANDIDATE_09")
local players=game.Players:GetPlayers()
table.sort(players,function(a,b)return a.Name<b.Name end)
assert(#players==2)
local map=template:Clone()
map.Name="__SC31MultiplayerProbe"
map.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
map:PivotTo(map:GetPivot()+Vector3.new(600,0,0))
map.Parent=workspace
local catch=Instance.new("Part");catch.Name="ProbeCatch";catch.Anchored=true;catch.Size=Vector3.new(80,2,80);catch.Position=map.Obstacles.WalkingSurfaces.Spar00.Position-Vector3.new(0,15,0);catch.Parent=map
map:SetAttribute("ProbePhase","WaitingForObservers")
local cap=map.Obstacles.WalkingSurfaces.Spar00
local base=cap.CFrame
local originals={}
for _,p in players do
 local c=p.Character;local root=c.HumanoidRootPart;local h=c:FindFirstChildOfClass("Humanoid")
 originals[p]={cf=c:GetPivot(),speed=h.WalkSpeed}
 root:SetNetworkOwner(nil);h.WalkSpeed=0;c:SetAttribute("RecoveryUntil",0)
end
local controller=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Crumble).Create(map,{"Spar00"},function(p)return p==players[1] or p==players[2]end)
local elapsed=0
local conn=RunService.Heartbeat:Connect(function(dt)elapsed+=dt;controller.Step(elapsed,true)end)
local results={}
local function place(p,offset)
 local c=p.Character;c:PivotTo(CFrame.new(base.Position+base.UpVector*cap.Size.Y/2+Vector3.new(offset,3.12,0)))
 c.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
 c:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Running)
end
local function park(p)
 local c=p.Character;c:PivotTo(originals[p].cf);c.HumanoidRootPart.AssemblyLinearVelocity=Vector3.zero
end
repeat task.wait(.1) until map:GetAttribute("ObserversReady")==true
for _,delay in {0.2,0.9} do
 controller.Reset();elapsed=0
 map:SetAttribute("ProbePhase","FollowerDelay"..delay)
 place(players[1],0)
 task.wait(delay)
 local record={delay=delay,atFollowerArrivalCollidable=cap.CanCollide,events={}}
 place(players[2],0)
 local start=os.clock();local prior=cap.CanCollide
 while os.clock()-start<5 do
  if cap.CanCollide~=prior then
   prior=cap.CanCollide
   table.insert(record.events,{t=elapsed,collide=prior,query=cap.CanQuery,offset=(cap.Position-base.Position).Magnitude})
  end
  RunService.Heartbeat:Wait()
 end
 record.restored=cap.CanCollide and cap.CanQuery and (cap.Position-base.Position).Magnitude<.001
 record.players={}
 for _,p in players do table.insert(record.players,{name=p.Name,health=p.Character.Humanoid.Health,y=p.Character.HumanoidRootPart.Position.Y}) park(p) end
 table.insert(results,record)
 task.wait(.5)
end
conn:Disconnect();controller.Stop()
map:SetAttribute("ProbePhase","Complete")
script:SetAttribute("Result",HttpService:JSONEncode({build="SC31_CANDIDATE_09",players={players[1].Name,players[2].Name},method="Two connected Studio clients; actual server-owned R15 characters placed on one production crumble cap. Delayed arrivals test shared state/reset, not a continuous human race.",scenarios=results}))
for _,p in players do p.Character.Humanoid.WalkSpeed=originals[p].speed;p.Character.HumanoidRootPart:SetNetworkOwnershipAuto() end
