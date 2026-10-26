-- Studio-only movement probe. Each scenario gets one initial placement; cave links then run continuously.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
assert(RunService:IsStudio(), "Studio only")

local layout = require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local installed = game.ServerStorage.CourseLibrary.Course_ShipwreckCove
assert(installed:GetAttribute("ShipwreckBuild") == layout.build, "layout and installed build differ")

local player = game.Players:GetPlayers()[1]
assert(player and player.Character, "an R15 test player is required")
local original = player.Character
local humanoid = original:FindFirstChildOfClass("Humanoid")
assert(humanoid and humanoid.RigType == Enum.HumanoidRigType.R15, "probe requires R15")

local fixture
local map = installed
if true then
    local template = game.ServerStorage.CourseLibrary.Course_ShipwreckCove
    assert(template:GetAttribute("ShipwreckBuild") == layout.build, "fixture build differs")
    assert(not workspace:FindFirstChild("__SCContinuousMovement"), "owned fixture already exists")
    fixture = template:Clone()
    fixture.Name = "__SCContinuousMovement"
    fixture:PivotTo(fixture:GetPivot() + Vector3.new(600, 0, 0))
    fixture.Parent = workspace
    fixture.StartPen.StartGate.CanCollide=false
    map = fixture
end

local surfaces = map.Obstacles.WalkingSurfaces
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { surfaces }
rayParams.RespectCanCollide = true

local function top(part)
    return part.Position + part.CFrame.UpVector * part.Size.Y / 2
end

local function flat(point)
    return Vector3.new(point.X, 0, point.Z)
end

local function edge(part, direction)
    return math.min(
        part.Size.X / 2 / math.max(.0001, math.abs(direction:Dot(part.CFrame.RightVector))),
        part.Size.Z / 2 / math.max(.0001, math.abs(direction:Dot(part.CFrame.LookVector)))
    )
end

local function floorHeight(part, position)
    local normal = part.CFrame.UpVector
    local center = top(part)
    return Vector3.new(position.X,
        center.Y - (normal.X * (position.X - center.X) + normal.Z * (position.Z - center.Z)) / normal.Y,
        position.Z)
end

local function pointRecord(point)
    return { math.round(point.X * 100) / 100, math.round(point.Y * 100) / 100, math.round(point.Z * 100) / 100 }
end

local scenarios = {}
for name, names in layout.testRoutes do if name=='expert_spars' then table.insert(scenarios,{name=name,names=names}) end end
table.sort(scenarios,function(a,b)return a.name<b.name end)
local authored = {}
for _, link in layout.links do
    authored[link[1] .. ">" .. link[2]] = true
end
for _, scenario in scenarios do
    for index = 1, #scenario.names - 1 do
        local from, to = scenario.names[index], scenario.names[index + 1]
        assert(authored[from .. ">" .. to], "missing authored link " .. from .. " -> " .. to)
        assert(surfaces:FindFirstChild(from) and surfaces:FindFirstChild(to), "missing walking surface")
    end
end

local results = {}
local function runScenario(scenario)
    local archivable = original.Archivable
    original.Archivable = true
    local character = original:Clone()
    original.Archivable = archivable
    character.Name = "__SCContinuous_" .. scenario.name
    for _, descendant in character:GetDescendants() do
        if descendant:IsA("BaseScript") then descendant.Enabled = false end
        if descendant:IsA("BasePart") then descendant.Anchored = false end
    end
    character.Parent = workspace
    player.Character=character
    character:SetAttribute('RecoveryUntil',0)
    local h = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    assert(h and root and h.RigType == Enum.HumanoidRigType.R15, "R15 clone incomplete")
    root:SetNetworkOwner(nil)
    h.WalkSpeed = 16
    h.UseJumpPower = false
    h.JumpHeight = 7.2
    h.EvaluateStateMachine = true
    local hazardHits={}
    local crumble=require(game.ServerStorage.CourseBuilders.ShipwreckCove.Runtime).Create(map,function(p,reason)table.insert(hazardHits,reason)end,function(candidate) return candidate==player end)
    local time=0
    local states={}
    local tickCrumble=RunService.Heartbeat:Connect(function(delta)
        time+=delta;crumble.Step(time,delta,true)
        for _,name in layout.crumble do
            if not surfaces[name].CanCollide then states[name]=true end
        end
    end)

    local direction = Vector3.zero
    local jump = false
    local binding = RunService.PreSimulation:Connect(function()
        h:Move(direction, false)
        h.Jump = jump
    end)
    local function standingOn()
        local hit = workspace:Raycast(root.Position, Vector3.new(0, -4.3, 0), rayParams)
        return hit and hit.Instance or nil
    end
    local function groundedOn(part)
        return h.FloorMaterial ~= Enum.Material.Air and standingOn() == part
    end
    local function waitFor(predicate, seconds)
        local deadline = os.clock() + seconds
        repeat RunService.Heartbeat:Wait() until predicate() or os.clock() > deadline
        return predicate()
    end

    local start = surfaces[scenario.names[1]]
    character:PivotTo(CFrame.new(top(start) + Vector3.new(0, 3.12, 0)))
    root.AssemblyLinearVelocity = Vector3.zero
    h.PlatformStand = false
    h.Sit = false
    h:ChangeState(Enum.HumanoidStateType.Running)
    local record = { name = scenario.name, links = {}, initialPosition = pointRecord(root.Position) }
    local ok, errorText = pcall(function()
        assert(waitFor(function() return groundedOn(start) end, 1.5), "initial placement did not ground")
        for index = 1, #scenario.names - 1 do
            local a = surfaces[scenario.names[index]]
            local b = surfaces[scenario.names[index + 1]]
            assert(groundedOn(a), "not on expected start after prior landing: " .. a.Name)
            local ta, tb = top(a), top(b)
            local delta = flat(tb - ta)
            local d = delta.Unit
            local launchDistance = math.min(math.max(0, edge(a,d)-.65), math.max(0,delta.Magnitude-edge(b,d)-2))
            local takeoff = floorHeight(a, ta + d * launchDistance)
            local stage = floorHeight(a, ta + d * math.max(0,launchDistance-2.35))
            local gap = delta.Magnitude - edge(a, d) - edge(b, d)
            local needsJump = gap > .2 or tb.Y - ta.Y > .6
            local link = { from = a.Name, to = b.Name, arrivedFromPriorLink = index > 1,
                startPosition = pointRecord(root.Position), gap = math.round(gap * 100) / 100,
                jumpRequired = needsJump }
            table.insert(record.links, link)

            local walkDeadline = os.clock() + 3.5
            while (flat(stage - root.Position)).Magnitude > math.min(1.1,a.Size.X*.15,a.Size.Z*.15) do
                assert(groundedOn(a), "left start surface while walking to launch")
                assert(os.clock() < walkDeadline, "could not reach launch staging point")
                direction = flat(stage - root.Position).Unit
                RunService.Heartbeat:Wait()
            end
            direction = Vector3.zero
            assert(waitFor(function() return groundedOn(a) end, .15), "not grounded at launch staging point")
            link.stagingPosition = pointRecord(root.Position)

            local hazardIndex=({Spar02=0,Spar06=1,Spar08=2})[b.Name]
            if hazardIndex then
                local period=3.1+hazardIndex*.25
                local phase=hazardIndex*1.05
                local deadline=time+period*2
                while math.abs(math.sin((time+.6-phase)*2*math.pi/period))*4.2<3.6 do
                    assert(time<deadline,'no safe crossbar window')
                    direction=Vector3.zero;RunService.Heartbeat:Wait()
                end
            end
            direction = d
            local launchReached = waitFor(function()
                return (flat(root.Position - takeoff)):Dot(d) >= -.6 or not groundedOn(a)
            end, 1)
            if not needsJump and groundedOn(b) then
                link.passed=true;link.landingSurface=b.Name;continue
            end
            assert(launchReached and groundedOn(a), "left start before grounded takeoff")
            link.takeoffPosition = pointRecord(root.Position)
            link.groundedTakeoff = true
            if needsJump then
                jump = true
                assert(waitFor(function() return h.FloorMaterial == Enum.Material.Air end, .4), "jump did not take off")
                jump = false
            end

            local reached = waitFor(function()
                if groundedOn(b) then return true end
                local remaining=flat(tb-root.Position)
                direction=if remaining.Magnitude>.12 then remaining.Unit*math.min(1,remaining.Magnitude/1.1) else Vector3.zero
                return false
            end, 2.25)
            direction = Vector3.zero
            assert(reached, "missed target; floor=" .. tostring(standingOn()))
            link.landingPosition = pointRecord(root.Position)
            link.landingSurface = standingOn().Name
            link.passed = true
            script:SetAttribute("LastLanding", scenario.name .. ":" .. b.Name .. " " .. HttpService:JSONEncode(link.landingPosition))
            script:SetAttribute("CaveProgress", if scenario.name == "continuousCave" then index else script:GetAttribute("CaveProgress"))
        end
    end)
    direction = Vector3.zero
    jump = false
    binding:Disconnect()
    tickCrumble:Disconnect();crumble.Stop()
    player.Character=original
    record.realTimeSeconds=time
    record.collapsedDuringTraversal=states
    record.hazardHits=hazardHits
    record.passed = ok and #record.links == #scenario.names - 1 and #hazardHits==0
    record.error = if ok then nil else tostring(errorText)
    record.finalPosition = pointRecord(root.Position)
    script:SetAttribute("LastPosition", scenario.name .. " " .. HttpService:JSONEncode(record.finalPosition))
    if record.passed or script:GetAttribute("KeepCloneOnFailure") ~= true then character:Destroy() end
    return record
end

for _, scenario in scenarios do
    table.insert(results, runScenario(scenario))
    script:SetAttribute("Progress", #results)
end
if fixture and script:GetAttribute("KeepFixture") ~= true then fixture:Destroy() end
script:SetAttribute("Result", HttpService:JSONEncode({
    build = installed:GetAttribute('ReviewBuild'),
    walkSpeed = 16,
    jumpHeight = 7.2,
    method = "Actual server-owned R15 physics. One initial placement per route; no teleports or velocity resets between links.",
    hazardMode = "Production Runtime and hazards on real Heartbeat clock. Server-driven R15 waits for crossbar windows. Contact callbacks recorded without teleporting the test character. Not human difficulty proof.",
    scenarios = results,
}))






