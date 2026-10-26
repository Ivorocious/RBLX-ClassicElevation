local RunService=game:GetService("RunService")
local Layout=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local Config=require(game.ReplicatedStorage.Config.ShipwreckConfig)
assert(workspace.RaceCourse:GetAttribute("ShipwreckBuild")==Layout.build,
    "Course and source layout differ")
local player=assert(game.Players:GetPlayers()[1],"Need a Studio test player")
local character=assert(player.Character,"Player has no character")
local humanoid=assert(character:FindFirstChildOfClass("Humanoid"),"Character has no humanoid")
assert(humanoid.RigType==Enum.HumanoidRigType.R15,"Probe requires actual R15")
local root=assert(character:FindFirstChild("HumanoidRootPart"),"Character has no root")
local original=character:GetPivot()
local template=game.ServerStorage.CourseLibrary.Course_ShipwreckCove
assert(template:GetAttribute("ShipwreckBuild")==Layout.build,"Fixture template differs from live build")
local fixture=template:Clone()
fixture.Name="__ShipwreckRevisionHazardFixture"
fixture:PivotTo(fixture:GetPivot()+Vector3.new(1000,0,0))
fixture.Parent=workspace
local origin=fixture.Bounds.CourseOrigin.CFrame
local hits={}
local controller=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(fixture,
    function(_,source)table.insert(hits,source)end,function(p)return p==player end)
local records={}
local direction=Vector3.zero
local jumpRequested=false
local binding=RunService.PreSimulation:Connect(function()
    humanoid:Move(direction,false)
    humanoid.Jump=jumpRequested
    jumpRequested=false
end)

local function localPosition()
    return origin:PointToObjectSpace(root.Position)
end

local function place(p)
    root:SetNetworkOwner(nil)
    character:PivotTo(origin*CFrame.new(p+Vector3.new(0,3.1,0)))
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
    direction=Vector3.zero
    jumpRequested=false
    humanoid.PlatformStand=false
    humanoid.Sit=false
    humanoid:ChangeState(Enum.HumanoidStateType.Running)
    character:SetAttribute("RecoveryUntil",0)
    task.wait(.35)
end

local function simulate(startTime,duration,jumpAt,moveDirection)
    controller.Reset()
    controller.Step(startTime,0,false)
    hits={}
    local t=startTime
    local jumped=false
    local airborne=false
    direction=moveDirection or Vector3.zero
    while t<startTime+duration do
        local dt=RunService.Heartbeat:Wait()
        t+=dt
        if jumpAt and not jumped and t>=jumpAt then
            jumpRequested=true
            jumped=true
        end
        if jumped and humanoid.FloorMaterial==Enum.Material.Air then airborne=true end
        controller.Step(t,dt,true)
    end
    direction=Vector3.zero
    jumpRequested=false
    return airborne
end

local function check(name,fn)
    local ok,err=pcall(fn)
    table.insert(records,{name=name,passed=ok,error=if ok then nil else tostring(err)})
    script:SetAttribute("Progress",#records)
end

check("Four alternating cannon lanes hit standing R15",function()
    assert(#Layout.shots==4,"Expected four authored shots")
    for i,shot in Layout.shots do
        local deck=fixture.Obstacles.WalkingSurfaces["BatteryDeck"..(i-1)]
        assert(deck,"Missing battery deck "..i)
        local start=Vector3.new(shot.start[1],shot.start[2],shot.start[3])
        local finish=Vector3.new(shot.finish[1],shot.finish[2],shot.finish[3])
        assert((finish.X-start.X)*(if i%2==1 then -1 else 1)>0,"Cannon side did not alternate")
        place(Vector3.new(-108,deck.Position.Y+deck.Size.Y/2-origin.Position.Y,shot.start[3]))
        local fire=shot.phase+Config.CannonWarning
        simulate(fire-.2,1.5)
        assert(table.find(hits,"H01 Cannon"),"No hit from "..shot.name)
    end
end)

for _,shot in Layout.shots do
    check("Normal R15 jump clears "..shot.name,function()
        place(Vector3.new(-108,13,shot.start[3]))
        local fire=shot.phase+Config.CannonWarning
        assert(simulate(fire-.3,1.3,fire+.1),"R15 never took off")
        assert(not table.find(hits,"H01 Cannon"),"Cannon hit during normal jump")
    end)
end

check("Server stall does not replay cannon contact against current position",function()
    place(Vector3.new(-108,13,Layout.shots[1].start[3]))
    controller.Reset()
    hits={}
    controller.Step(1.5,0,false)
    controller.Step(3,1.5,true)
    assert(#hits==0,"Stale cannon interval punished current player position")
end)

for i=0,2 do
    check("Protected CoverPocket"..i.." survives a full volley",function()
        local pocket=assert(fixture.Obstacles.WalkingSurfaces["CoverPocket"..i])
        local localCenter=origin:PointToObjectSpace(pocket.Position)
        place(Vector3.new(localCenter.X,localCenter.Y+pocket.Size.Y/2,localCenter.Z))
        simulate(0,Config.CannonCycle)
        assert(#hits==0,"Protected wait pocket was hit")
        assert(humanoid.FloorMaterial~=Enum.Material.Air,"Player left the wait platform")
    end)
end

check("Static cargo band resets a standing R15",function()
    place(Vector3.new(-115,17,41))
    simulate(0,.25)
    assert(table.find(hits,"HotCargoBand"),"No static strip contact")
end)

check("Normal jump crosses static cargo band",function()
    place(Vector3.new(-115,17,45))
    assert(simulate(0,.48,.03,-Vector3.zAxis),"R15 never took off")
    assert(localPosition().Z<41,"Character did not pass the strip")
    assert(localPosition().Y>21,"Character crossed below the strip")
    assert(not table.find(hits,"HotCargoBand"),"Static strip hit airborne R15")
end)

check("Moving dock rope contacts off-center R15",function()
    place(Vector3.new(-111,12,77))
    simulate(.7,.75)
    assert(table.find(hits,"DockRopeSweep"),"Sweeping rope missed off-center player")
end)

check("Ship sweep does not hit just outside its travel envelope",function()
    place(Vector3.new(-74,24,-104.5))
    simulate(0,4.5)
    assert(not table.find(hits,"ShipSweep3"),"Sweep hit outside its travel envelope")
    assert(humanoid.FloorMaterial~=Enum.Material.Air,"Near-miss player left the platform")
end)

check("Cave passage is safe in dry window",function()
    place(Vector3.new(69,5,58))
    simulate(2,1)
    assert(#hits==0,"Dry passage reset player")
    assert(fixture.Decoration.H02.SurgeWave.Transparency==1,"Wave remained visible while dry")
end)

check("Cave wave advances and resets in low passage",function()
    place(Vector3.new(69,5,58))
    simulate(8.1,2.3)
    assert(table.find(hits,"H02 Tide surge"),"Wave did not reach passage")
    local foam=fixture.Decoration.H02.SurgeFoam
    assert(origin:PointToObjectSpace(foam.Position).Z<60,"Foam did not visibly sweep across")
    assert(fixture.Decoration.H02.SurgeWave.Transparency<1,"Wave did not appear at peak")
end)

check("Raised refuge centers and inner edges survive warning, surge and drain",function()
    for _,x in {91,81.5,56.5,46} do
        place(Vector3.new(x,10,58))
        simulate(7.4,4.6)
        assert(#hits==0,"Raised refuge reset player at x="..x)
    end
end)

controller.Stop()
binding:Disconnect()
fixture:Destroy()
character:PivotTo(original)
root.AssemblyLinearVelocity=Vector3.zero
root.AssemblyAngularVelocity=Vector3.zero
root:SetNetworkOwnershipAuto()
script:SetAttribute("Result",game.HttpService:JSONEncode({build=Layout.build,records=records,
    method="Production Runtime.Create on translated fixture with actual R15, timed normal jumps, full-cycle stationary pockets, and server contact checks; controlled clock and teleported setup, not full-race traversal or 20-player load"}))


