local RunService=game:GetService('RunService')
assert(RunService:IsStudio())
local original=game.Players:GetPlayers()[1].Character
local fixture=game.ServerStorage.CourseLibrary.Course_ShipwreckCove:Clone()
fixture.Name='__SC31ShoreFixture';fixture:PivotTo(fixture:GetPivot()+Vector3.new(600,0,0));fixture.Parent=workspace
fixture.StartPen.StartGate.CanCollide=false
local origin=fixture.Bounds.CourseOrigin.CFrame
local parts={fixture.Obstacles.WalkingSurfaces}
for _,p in fixture.Decoration:GetDescendants() do
    if p:IsA('BasePart') and p:GetAttribute('SolidGround') then table.insert(parts,p) end
end
local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances=parts;ray.RespectCanCollide=true
local function ground(p) return workspace:Raycast(p+Vector3.new(0,50,0),Vector3.new(0,-100,0),ray) end
local results={}
for _,offset in {0,-7,7} do
    local archivable=original.Archivable;original.Archivable=true
    local character=original:Clone();original.Archivable=archivable
    for _,v in character:GetDescendants() do if v:IsA('BaseScript') then v.Enabled=false end end
    character.Name='__SC31ShoreR15';character.Parent=workspace
    local h=character.Humanoid;local root=character.HumanoidRootPart;root:SetNetworkOwner(nil)
    h.WalkSpeed=16;h.UseJumpPower=false;h.JumpHeight=7.2
    local direction=Vector3.zero
    local binding=RunService.PreSimulation:Connect(function() h:Move(direction,false);h.Jump=false end)
    local row={laneOffset=offset,waypoints=0,airborneFrames=0,maxGroundError=0}
    local points={}
    for i=0,24 do
        local t=i/24
        local x= -100*t
        local z=78+50*t
        if t>0 then x+=offset*.447;z+=offset*.894 end
        table.insert(points,origin:PointToWorldSpace(Vector3.new(x,8,z)))
    end
    local ok,err=pcall(function()
        local first=ground(points[1]);assert(first,'entry has no support')
        character:PivotTo(CFrame.new(first.Position+Vector3.new(0,3.15,0)))
        root.AssemblyLinearVelocity=Vector3.zero;task.wait(.5)
        for i=2,#points do
            local hit=ground(points[i]);assert(hit,'no ground at waypoint '..i)
            local endTime=os.clock()+3
            repeat
                local delta=(points[i]-root.Position)*Vector3.new(1,0,1)
                direction=if delta.Magnitude>.3 then delta.Unit*math.min(1,delta.Magnitude) else Vector3.zero
                RunService.Heartbeat:Wait()
                if h.FloorMaterial==Enum.Material.Air then row.airborneFrames+=1 end
                assert(root.Position.Y>origin.Position.Y-2,'fell through visible shore at waypoint '..i)
                assert(os.clock()<endTime,'could not reach waypoint '..i)
            until ((points[i]-root.Position)*Vector3.new(1,0,1)).Magnitude<.7
            row.waypoints+=1
        end
    end)
    direction=Vector3.zero;binding:Disconnect();character:Destroy()
    row.passed=ok;row.error=if ok then nil else tostring(err);table.insert(results,row)
end
fixture:Destroy()
script:SetAttribute('Result',game.HttpService:JSONEncode({build=game.ServerStorage.CourseLibrary.Course_ShipwreckCove:GetAttribute('ReviewBuild'),method='Server-owned R15 walking continuously, no jumping or inter-waypoint teleports; hazards inactive.',lanes=results}))
