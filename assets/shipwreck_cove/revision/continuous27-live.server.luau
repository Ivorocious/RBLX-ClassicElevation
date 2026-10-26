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

local map = workspace.RaceCourse
assert(map:GetAttribute("ReviewBuild")=="SC27_FINAL_04")

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

local scenarios = {
    {name="cave27Active",names={"R4_CaveEntry","Cave26Stone00","Cave26Stone01","Cave26Stone02","Cave26Stone03","Cave26Stone04","Cave26Stone05","Cave26Stone06","SurgeEastRefuge","SurgePassage","SurgeWestRefuge"}},
}
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
    local character = original
    local h = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    assert(h and root and h.RigType == Enum.HumanoidRigType.R15, "R15 clone incomplete")
    root:SetNetworkOwner(nil)
    h.WalkSpeed = 16
    h.UseJumpPower = false
    h.JumpHeight = 7.2
    h.EvaluateStateMachine = true

    local direction = Vector3.zero
    local jump = false
    local hits={}
    local recoveryStart=character:GetAttribute("RecoveryUntil") or 0
    local epoch=os.clock()
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
        local first=map.Decoration.Falling.FallingSpike27_0
        assert(waitFor(function() return first:GetAttribute("State")=="Hold" end,6),"no first spike hold")
        assert(waitFor(function() return first:GetAttribute("State")=="Reset" end,2),"no first spike reset")
        record.departure=os.clock()-epoch
        for index = 1, #scenario.names - 1 do
            assert((character:GetAttribute("RecoveryUntil") or 0)==recoveryStart,"production recovery interrupted traversal")
            local a = surfaces[scenario.names[index]]
            if a.Name=="SurgeEastRefuge" then
                direction=Vector3.zero
                assert(waitFor(function() return map.Obstacles.ShipwreckHazards.SurgeBounds:GetAttribute("Phase")~="Dry" end,15),"no tide cycle")
                assert(waitFor(function() return map.Obstacles.ShipwreckHazards.SurgeBounds:GetAttribute("Phase")=="Dry" end,15),"no dry window")
            end
            local b = surfaces[scenario.names[index + 1]]
            assert(groundedOn(a), "not on expected start after prior landing: " .. a.Name)
            local ta, tb = top(a), top(b)
            local delta = flat(tb - ta)
            local d = delta.Unit
            local launchDistance=math.min(math.max(0,edge(a,d)-.65),math.max(0,delta.Magnitude-edge(b,d)-2))
            local takeoff = floorHeight(a, ta + d * launchDistance)
            local stage = floorHeight(a, ta + d * math.max(0, launchDistance - 2.35))
            local gap = delta.Magnitude - edge(a, d) - edge(b, d)
            local needsJump = gap > .2 or tb.Y - ta.Y > .6
            local link = { from = a.Name, to = b.Name, arrivedFromPriorLink = index > 1,
                startPosition = pointRecord(root.Position), gap = math.round(gap * 100) / 100,
                jumpRequired = needsJump, elapsed=os.clock()-epoch,
                tidePhase=map.Obstacles.ShipwreckHazards.SurgeBounds:GetAttribute("Phase"),
                fallingStates={map.Decoration.Falling.FallingSpike27_0:GetAttribute("State"),map.Decoration.Falling.FallingSpike27_1:GetAttribute("State"),map.Decoration.Falling.FallingSpike27_2:GetAttribute("State"),map.Decoration.Falling.FallingSpike27_3:GetAttribute("State")} }
            table.insert(record.links, link)

            local walkDeadline = os.clock() + 3.5
            while (flat(stage - root.Position)).Magnitude > 1.1 do
                assert(groundedOn(a), "left start surface while walking to launch")
                assert(os.clock() < walkDeadline, "could not reach launch staging point")
                direction = flat(stage - root.Position).Unit
                RunService.Heartbeat:Wait()
            end
            direction = Vector3.zero
            assert(waitFor(function() return groundedOn(a) end, .15), "not grounded at launch staging point")
            link.stagingPosition = pointRecord(root.Position)

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
                if (flat(root.Position - tb)):Dot(d) > -.85 then direction = Vector3.zero end
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
    root:SetNetworkOwnershipAuto()
    record.recoveryChanged=(character:GetAttribute("RecoveryUntil") or 0)~=recoveryStart
    record.elapsed=os.clock()-epoch
    record.hazardHits=hits
    record.passed = ok and #record.links == #scenario.names - 1 and not record.recoveryChanged
    record.error = if ok then nil else tostring(errorText)
    record.finalPosition = pointRecord(root.Position)
    script:SetAttribute("LastPosition", scenario.name .. " " .. HttpService:JSONEncode(record.finalPosition))
    
    return record
end

for _, scenario in scenarios do
    table.insert(results, runScenario(scenario))
    script:SetAttribute("Progress", #results)
end

script:SetAttribute("Result", HttpService:JSONEncode({
    build = map:GetAttribute("ReviewBuild"),
    walkSpeed = 16,
    jumpHeight = 7.2,
    method = "Actual official R15 racer, production RaceCourse and real-time ShipwreckService Runtime. StudioDev preset checkpoint4 and one initial placement at R4. Normal movement, no between-link teleports, collider changes or hazard suppression. Waits for first falling spike reset and full dry window at refuge.",
    hazardMode = "Production Runtime, normal recovery service active; records live falling states and tide phase.",
    scenarios = results,
}))

