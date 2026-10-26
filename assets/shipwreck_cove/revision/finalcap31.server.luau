local rs=game:GetService('RunService')
assert(rs:IsStudio())
local player=game.Players:GetPlayers()[1]
local original=player.Character
local map=game.ServerStorage.CourseLibrary.Course_ShipwreckCove:Clone()
map.Name='__SC31FinalCapFixture';map:PivotTo(map:GetPivot()+Vector3.new(800,0,0));map.Parent=workspace
local cap=map.Obstacles.WalkingSurfaces.Spar12
local visual=map.Decoration:FindFirstChild('Spar12',true)
local base=cap.CFrame
local archivable=original.Archivable;original.Archivable=true
local character=original:Clone();original.Archivable=archivable
for _,v in character:GetDescendants() do if v:IsA('BaseScript') then v.Enabled=false end end
character.Parent=workspace;player.Character=character
local h=character.Humanoid;local root=character.HumanoidRootPart
root:SetNetworkOwner(nil);h:Move(Vector3.zero,false)
character:SetAttribute('RecoveryUntil',0)
character:PivotTo(CFrame.new(cap.Position+Vector3.new(0,cap.Size.Y/2+3.3,0)))
root.AssemblyLinearVelocity=Vector3.zero
local controller=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Crumble).Create(map,{'Spar12'},function(p)return p==player end)
local t=0;local droppedAt=nil;local restoredAt=nil;local grounded=false;local maxDrop=0
while t<6 do
    local dt=rs.Heartbeat:Wait();t+=dt
    if h.FloorMaterial~=Enum.Material.Air then grounded=true end
    controller.Step(t,not droppedAt)
    if not cap.CanCollide and not droppedAt then droppedAt=t;player.Character=original;character:Destroy() end
    maxDrop=math.max(maxDrop,base.Y-cap.Position.Y)
    if droppedAt and cap.CanCollide then restoredAt=t;break end
end
local result={build=map:GetAttribute('ReviewBuild'),grounded=grounded,droppedAt=droppedAt,restoredAt=restoredAt,maxDrop=maxDrop,collisionRestored=cap.CanCollide,queryRestored=cap.CanQuery,transformError=(cap.Position-base.Position).Magnitude,method='Actual R15 grounded on final cap, production Crumble on Heartbeat; complete drop and reset. Not multiplayer.'}
controller.Stop();player.Character=original;if character.Parent then character:Destroy() end;map:Destroy()
script:SetAttribute('Result',game.HttpService:JSONEncode(result))
