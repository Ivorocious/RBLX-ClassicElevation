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
    assert(workspace.RaceCourse:GetAttribute("ShipwreckBuild")==Layout.build,
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
    fixture.Name="__ShipwreckProbe25Fixture"
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

    check("Four cannon arcs hit grounded R15 at central deck",function()
        assert(#Layout.shots==4,"Expected four cannon shots")
        for i,shot in Layout.shots do
            local deck=assert(fixture.Obstacles.WalkingSurfaces:FindFirstChild("BatteryDeck"..(i-1)))
            local deckCenter=origin:PointToObjectSpace(deck.Position)
            local deckTop=deckCenter.Y+deck.Size.Y/2
            place(Vector3.new(deckCenter.X,deckTop,shot.start[3]))
            assert(humanoid.FloorMaterial~=Enum.Material.Air,"Not grounded on battery deck "..i)
            local fire=shot.phase+Config.CannonWarning
            simulate(fire-.2,1.4)
            assert(table.find(hits,"H01 Cannon"),"Cannon missed grounded racer: "..shot.name)
        end
    end)

    for i,shot in Layout.shots do
        check("Normal jump clears arc "..shot.name,function()
            local deck=assert(fixture.Obstacles.WalkingSurfaces:FindFirstChild("BatteryDeck"..(i-1)))
            local deckCenter=origin:PointToObjectSpace(deck.Position)
            local deckTop=deckCenter.Y+deck.Size.Y/2
            place(Vector3.new(deckCenter.X,deckTop,shot.start[3]))
            assert(humanoid.FloorMaterial~=Enum.Material.Air,"Not grounded before jump")
            local fire=shot.phase+Config.CannonWarning
            local travel=(Vector3.new(shot.finish[1],shot.finish[2],shot.finish[3])
                -Vector3.new(shot.start[1],shot.start[2],shot.start[3])).Magnitude/Config.CannonSpeed
            local crossing=(deckCenter.X-shot.start[1])/(shot.finish[1]-shot.start[1])
            assert(crossing>.1 and crossing<.9,"Deck is outside cannon route")
            local jumpAt=fire+crossing*travel-.2
            assert(simulate(fire-.25,1.15,jumpAt),"R15 never took off")
            assert(not table.find(hits,"H01 Cannon"),"Cannon hit normal jump")
        end)
    end

    check("Arc endpoints, phase, and burst emitters match authored shots",function()
        for _,shot in Layout.shots do
            local start=Vector3.new(shot.start[1],shot.start[2],shot.start[3])
            local finish=Vector3.new(shot.finish[1],shot.finish[2],shot.finish[3])
            assert(math.abs(start.Y-16.1)<.05 and math.abs(finish.Y+3.3)<.05,
                "Unexpected cannon endpoint height: "..shot.name)
            local ball=assert(fixture.Decoration.H01:FindFirstChild(shot.name))
            local cue=assert(fixture.Decoration.H01:FindFirstChild(shot.cue))
            local impact=assert(fixture.Decoration.H01:FindFirstChild(shot.impact))
            local fire=assert(cue:FindFirstChild("MuzzleFire"))
            local smoke=assert(cue:FindFirstChild("MuzzleSmoke"))
            local splash=assert(impact:FindFirstChild("WaterSplash"))
            assert(fire:IsA("ParticleEmitter") and smoke:IsA("ParticleEmitter")
                and splash:IsA("ParticleEmitter"),"Burst effect type is wrong")
            assert(fire.Rate==0 and smoke.Rate==0 and splash.Rate==0,
                "Burst effect runs continuously")
            controller.Reset()
            local travel=(finish-start).Magnitude/Config.CannonSpeed
            local fireTime=shot.phase+Config.CannonWarning
            controller.Step(fireTime+travel*.5,0,false)
            local localBall=origin:PointToObjectSpace(ball.Position)
            local expected=(start.Y+finish.Y)/2+(shot.arcHeight or Config.CannonArcHeight)
            assert(math.abs(localBall.Y-expected)<.15,"Visual ball missed arc midpoint")
            controller.Step(fireTime+travel+.05,.05,true)
            assert(ball:GetAttribute("Phase")=="Clear" and impact.Transparency==0,
                "Impact phase did not appear")
        end
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
