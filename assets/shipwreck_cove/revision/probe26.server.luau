local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Layout=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local Config=require(game.ReplicatedStorage.Config.ShipwreckConfig)

local records={}
local fixture
local controller
local binding
local player
local character
local humanoid
local root
local originalPivot
local origin
local hits={}
local direction=Vector3.zero
local jumpRequested=false

local function check(name,fn)
    local ok,err=pcall(fn)
    table.insert(records,{name=name,passed=ok,error=if ok then nil else tostring(err)})
    script:SetAttribute("Progress",#records)
end

local function place(localTop)
    root:SetNetworkOwner(nil)
    character:PivotTo(origin*CFrame.new(localTop+Vector3.new(0,3.1,0)))
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

local function simulate(startTime,duration,jumpAt)
    controller.Reset()
    controller.Step(startTime,0,false)
    hits={}
    local t=startTime
    local jumped=false
    local airborne=false
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
    jumpRequested=false
    return airborne
end

local ok,fatal=pcall(function()
    assert(game.ServerStorage.CourseLibrary.Course_ShipwreckCove:GetAttribute("ShipwreckBuild")==Layout.build,
        "Live course and source layout differ")
    player=assert(game.Players:GetPlayers()[1],"Need a Studio test player")
    character=assert(player.Character,"Player has no character")
    humanoid=assert(character:FindFirstChildOfClass("Humanoid"),"Character has no humanoid")
    assert(humanoid.RigType==Enum.HumanoidRigType.R15,"Probe requires actual R15")
    root=assert(character:FindFirstChild("HumanoidRootPart"),"Character has no root")
    originalPivot=character:GetPivot()
    local template=assert(game.ServerStorage.CourseLibrary:FindFirstChild("Course_ShipwreckCove"),
        "Missing course fixture template")
    assert(template:GetAttribute("ShipwreckBuild")==Layout.build,"Fixture template differs from layout")
    fixture=template:Clone()
    fixture.Name="__ShipwreckProbe26Fixture"
    fixture:PivotTo(fixture:GetPivot()+Vector3.new(1000,0,0))
    fixture.Parent=workspace
    origin=fixture.Bounds.CourseOrigin.CFrame
    controller=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(fixture,
        function(_,source)table.insert(hits,source)end,function(p)return p==player end)
    binding=RunService.PreSimulation:Connect(function()
        humanoid:Move(direction,false)
        humanoid.Jump=jumpRequested
        jumpRequested=false
    end)

    check("H02 dry and warning do not hit; both crests hit standing R15",function()
        local start=Config.TideDry+Config.TideWarning
        for _,test in {{"dry",1,false},{"warning",Config.TideDry+.3,false},{"first",start+.7,true},{"second",start+2.8,true}} do
            place(Vector3.new(69,5,58))
            simulate(test[2],.5)
            local hit=table.find(hits,"H02 Tide surge")~=nil
            assert(hit==test[3],test[1].." unexpected tide contact "..tostring(hit))
        end
    end)
    check("Both raised refuges stay safe through complete two-crest surge",function()
        for _,x in {91,46} do
            place(Vector3.new(x,10,58))
            simulate(Config.TideDry+Config.TideWarning-.2,Config.TideActive+Config.TideDrain+.3)
            assert(not table.find(hits,"H02 Tide surge"),"Refuge hit at "..x)
        end
    end)
    check("Two separate visible crests, one continuous pool, bounded cleanup",function()
        local h2=fixture.Decoration.H02
        local start=Config.TideDry+Config.TideWarning
        controller.Reset();controller.Step(start+.2,0,false)
        assert(h2.SurgeWave.Transparency<1 and h2.SurgeWave2.Transparency==1,"First crest not isolated")
        controller.Step(start+1.6,.1,false)
        assert(h2.SurgeWave.Transparency<1 and h2.SurgeWave2.Transparency<1,"Two crests not visible together")
        assert((h2.SurgeWave.Position-h2.SurgeWave2.Position).Magnitude>4,"Crests overlap")
        assert(fixture.Obstacles.ShipwreckHazards.SurgeBounds:GetAttribute("WaveNumber")==2)
        controller.Step(start+3,.1,false)
        assert(h2.SurgeWave.Transparency==1 and h2.SurgeWave2.Transparency<1,"Second crest not isolated")
        controller.Step(Config.TideCycle+.1,.1,false)
        assert(h2.SurgeWave.Transparency==1 and h2.SurgeWave2.Transparency==1,"Crest persists into dry window")
    end)

    check("Standing racer arms, drops, and restores a cave stone",function()
        assert(Layout.crumble and #Layout.crumble>0,"No named crumble stones in layout")
        local name=Layout.crumble[1]
        local collider=assert(fixture.Obstacles.WalkingSurfaces:FindFirstChild(name))
        local visual=assert(fixture.Decoration.S04_Entry:FindFirstChild(name))
        local colliderCFrame=collider.CFrame
        local visualCFrame=visual.CFrame
        local top=origin:PointToObjectSpace(collider.Position).Y+collider.Size.Y/2
        local center=origin:PointToObjectSpace(collider.Position)
        controller.Reset()
        place(Vector3.new(center.X,top,center.Z))
        assert(humanoid.FloorMaterial~=Enum.Material.Air,"R15 did not stand on crumble stone")
        controller.Step(0,0,false)
        controller.Step(.11,.11,true)
        controller.Step(.35,.24,true)
        assert(visual.CFrame~=visualCFrame,"Crumble warning did not shake visual")
        assert(collider.CFrame==colliderCFrame and collider.CanCollide,
            "Walking collider moved or disabled during warning")
        place(Vector3.new(108,15,-18))
        controller.Step(.8,.45,true)
        assert(not collider.CanCollide,"Stone did not lose collision after warning")
        controller.Step(1.1,.3,true)
        assert(visual.CFrame~=visualCFrame and collider.CFrame~=colliderCFrame,
            "Stone did not fall")
        controller.Step(1.4,.3,true)
        controller.Step(4.45,.1,true)
        assert(collider.CanCollide and collider.CFrame==colliderCFrame
            and visual.CFrame==visualCFrame,"Stone did not restore after wait")
    end)

    check("Stop restores an active crumble stone and removes bursts",function()
        local name=Layout.crumble[1]
        local collider=assert(fixture.Obstacles.WalkingSurfaces:FindFirstChild(name))
        local visual=assert(fixture.Decoration.S04_Entry:FindFirstChild(name))
        local colliderCFrame=collider.CFrame
        local visualCFrame=visual.CFrame
        local center=origin:PointToObjectSpace(collider.Position)
        controller.Reset()
        place(Vector3.new(center.X,center.Y+collider.Size.Y/2,center.Z))
        controller.Step(0,0,false)
        controller.Step(.11,.11,true)
        controller.Step(.8,.1,true)
        assert(not collider.CanCollide,"Stone did not drop before Stop")
        controller.Stop()
        assert(collider.CanCollide and collider.CFrame==colliderCFrame
            and visual.CFrame==visualCFrame,"Stop did not restore stone")
        local cue=fixture.Decoration.H01[Layout.shots[1].cue]
        assert(not cue:FindFirstChild("MuzzleFire") and not cue:FindFirstChild("MuzzleSmoke"),
            "Stop left burst emitters")
    end)
end)

if binding then binding:Disconnect() end
if controller then pcall(function()controller.Stop()end) end
if fixture then fixture:Destroy() end
if character and originalPivot then
    character:PivotTo(originalPivot)
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
    root:SetNetworkOwnershipAuto()
end
if not ok then table.insert(records,{name="Probe setup/run",passed=false,error=tostring(fatal)}) end
script:SetAttribute("Result",HttpService:JSONEncode({build=Layout.build,records=records,
    limits="Controlled clock and teleported actual R15 in translated production Runtime fixture; particle objects and phases checked, not rendered burst appearance, full route playthrough, or multiplayer load."}))
