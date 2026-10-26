local HttpService=game:GetService("HttpService")
local Layout=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local Config=require(game.ReplicatedStorage.Config.ShipwreckConfig)
local records={}
local fixture,controller,player,character,root,origin
local originalPivot,originalAnchored
local initialWaveCFrame,initialDropCFrame,initialDropColor
local hits={}

local function check(name,fn)
    local ok,err=pcall(fn)
    table.insert(records,{name=name,passed=ok,error=if ok then nil else tostring(err)})
    script:SetAttribute("Progress",#records)
end

local function position(localPoint)
    return origin:PointToWorldSpace(Vector3.new(localPoint[1],localPoint[2],localPoint[3]))
end

local function place(localPoint)
    local wanted=position(localPoint)
    character:PivotTo(character:GetPivot()+(wanted-root.Position))
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
    character:SetAttribute("RecoveryUntil",0)
end

local function step(t,dt)
    hits={}
    controller.Step(t,dt,true)
end

local function hit(reason)
    return table.find(hits,reason)~=nil
end

local ok,fatal=pcall(function()
    local template=assert(game.ServerStorage.CourseLibrary:FindFirstChild("Course_ShipwreckCove"),
        "Missing installed Shipwreck Cove course")
    assert(template:GetAttribute("ShipwreckBuild")==Layout.build,"Installed course differs from Layout")
    player=assert(game.Players:GetPlayers()[1],"Need Studio test player")
    character=assert(player.Character,"Player has no character")
    local humanoid=assert(character:FindFirstChildOfClass("Humanoid"),"Missing humanoid")
    assert(humanoid.RigType==Enum.HumanoidRigType.R15,"Probe requires actual R15")
    root=assert(character:FindFirstChild("HumanoidRootPart"),"Missing HumanoidRootPart")
    originalPivot=character:GetPivot()
    originalAnchored=root.Anchored
    root.Anchored=true
    fixture=template:Clone()
    fixture.Name="__ShipwreckHazards27Fixture"
    fixture:PivotTo(fixture:GetPivot()+Vector3.new(1000,0,0))
    fixture.Parent=workspace
    origin=fixture.Bounds.CourseOrigin.CFrame
    initialWaveCFrame=fixture.Decoration.H02.SurgeWave.CFrame
    initialDropCFrame=fixture.Decoration.Falling[Layout.falling[1].name].CFrame
    initialDropColor=fixture.Decoration.Falling[Layout.falling[1].name].Color
    controller=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(fixture,
        function(_,source)table.insert(hits,source)end,function(p)return p==player end)

    check("Nine named droppers have one matte warning marker each",function()
        assert(#Layout.falling==9,"Expected nine authored droppers")
        for _,d in Layout.falling do
            local visual=assert(fixture.Decoration.Falling:FindFirstChild(d.name),d.name.." missing")
            local marker=assert(fixture.Decoration.Falling:FindFirstChild(d.name.."Warning"),d.name.." marker missing")
            assert(marker.Material==Enum.Material.SmoothPlastic,"Marker is not matte")
            assert(not marker.CanCollide and not marker.CanTouch and not marker.CanQuery,"Marker is interactive")
            assert(visual:IsA("BasePart"),"Drop visual is not a BasePart")
        end
    end)

    check("Stalactite warns before contact and crossed fall hits R15",function()
        local d=Layout.falling[1]
        local visual=fixture.Decoration.Falling[d.name]
        place(d.bottom)
        controller.Reset()
        step(d.phase+.5,0)
        assert(visual:GetAttribute("State")=="Warning" and visual:GetAttribute("Warning"),"Warning state missing")
        assert(not hit(d.name),"Stalactite hit during warning")
        step(d.phase+d.warning+d.fallTime+.01,.49)
        assert(hit(d.name),"Swept fall missed R15 after frame crossed the fall")
        assert(visual:GetAttribute("State")=="Hold","Hold state missing")
    end)

    check("Thin stalactite misses R15 outside visible width",function()
        local d=Layout.falling[1]
        local visual=fixture.Decoration.Falling[d.name]
        place({d.bottom[1]+visual.Size.X/2+4,d.bottom[2],d.bottom[3]})
        controller.Reset()
        step(d.phase+d.warning+.25,.25)
        assert(not hit(d.name),"Stalactite hit beyond visual width")
    end)

    check("Coconut warns and contacts standing R15",function()
        local d=Layout.falling[5]
        place(d.bottom)
        controller.Reset()
        step(d.phase+.4,0)
        assert(not hit(d.name),"Coconut hit during warning")
        step(d.phase+d.warning+d.fallTime+.01,.49)
        assert(hit(d.name),"Coconut fall missed R15")
    end)

    check("Red cargo and moving ship sweep retain server contact",function()
        local cargo
        for _,d in Layout.hazards do
            if d.name=="RedCargo1_0" then cargo=d;break end
        end
        assert(cargo and cargo.kind=="sweep","Red cargo sweep missing from layout")
        local peak=cargo.phase+cargo.period/4
        place({cargo.p[1]+cargo.amplitude,cargo.p[2],cargo.p[3]})
        controller.Reset()
        controller.Step(peak-.1,0,false)
        step(peak,.1)
        assert(hit("RedCargo1_0"),"Red cargo missed R15")
        place({-74,25.2,-110})
        controller.Reset()
        controller.Step(1.1,0,false)
        step(1.2,.1)
        assert(hit("ShipSweep3"),"Ship sweep missed R15")
    end)

    check("First crest leads connected flood and second crest follows",function()
        local h2=fixture.Decoration.H02
        local bounds=fixture.Obstacles.ShipwreckHazards.SurgeBounds
        local start=Config.TideDry+Config.TideWarning
        controller.Reset()
        step(start+.2,.1)
        assert(h2.SurgeWave.Transparency<1 and h2.SurgeWave2.Transparency==1,"First crest not isolated")
        assert(math.abs(h2.SurgeWave.CFrame.RightVector:Dot(bounds.CFrame.RightVector))>.99,
            "Crest width is turned away from the flood width")
        local front=bounds.CFrame:PointToObjectSpace(h2.SurgeWave.Position).Z-h2.SurgeWave.Size.Z/2
        local waterFront=bounds.CFrame:PointToObjectSpace(h2.SurgeWater.Position).Z-h2.SurgeWater.Size.Z/2
        assert(math.abs(front-waterFront)<.35,"Flood does not trail visible first crest")
        step(start+1.6,.1)
        assert(h2.SurgeWave.Transparency<1 and h2.SurgeWave2.Transparency<1,"Two crests not visible")
        assert(bounds.CFrame:PointToObjectSpace(h2.SurgeWave.Position).Z
            <bounds.CFrame:PointToObjectSpace(h2.SurgeWave2.Position).Z,"Second crest not behind first")
        assert(h2.SurgeWater.Position.Y+h2.SurgeWater.Size.Y/2<=bounds.Position.Y+bounds.Size.Y/2+.1,
            "Visible flood exceeds collision height")
    end)

    check("Raised refuges remain outside full tide contact",function()
        for _,x in {91,46} do
            place({x,13.1,58})
            controller.Reset()
            step(Config.TideDry+Config.TideWarning+Config.TideActive-.2,.1)
            assert(not hit("H02 Tide surge"),"Refuge hit at x="..x)
        end
    end)

    check("Stop restores droppers and removes temporary wave and markers",function()
        local d=Layout.falling[1]
        local visual=fixture.Decoration.Falling[d.name]
        local wave=fixture.Decoration.H02.SurgeWave
        controller.Reset()
        step(d.phase+.5,.1)
        controller.Stop()
        controller=nil
        assert(visual.CFrame==initialDropCFrame and visual.Color==initialDropColor,
            "Dropper pose or color remained changed")
        assert(wave.CFrame==initialWaveCFrame,"Wave pose remained changed")
        assert(not fixture.Decoration.Falling:FindFirstChild(d.name.."Warning"),"Warning marker remained")
        assert(not fixture.Decoration.H02:FindFirstChild("SurgeWave2"),"Second crest remained")
        assert(not fixture.Decoration.H02:FindFirstChild("SurgeFoam2"),"Second foam remained")
    end)
end)

if controller then pcall(function()controller.Stop()end) end
if fixture then fixture:Destroy() end
if character and originalPivot then
    character:PivotTo(originalPivot)
    root.AssemblyLinearVelocity=Vector3.zero
    root.AssemblyAngularVelocity=Vector3.zero
    root.Anchored=originalAnchored
end
if not ok then table.insert(records,{name="Probe setup/run",passed=false,error=tostring(fatal)}) end
local passed=0
for _,record in records do if record.passed then passed+=1 end end
script:SetAttribute("Result",HttpService:JSONEncode({build=Layout.build,passed=passed,total=#records,
    records=records,method="Controlled fixture clock and teleported actual R15; not route traversal, visual acceptance, or multiplayer load."}))
