-- Studio-only movement fixture. One R15 placement at the first shore cap, then continuous walking.
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
assert(RunService:IsStudio(), "Studio only")

local layout = require(game.ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local template = game.ServerStorage.CourseLibrary.Course_ShipwreckCove
assert(template:GetAttribute("ShipwreckBuild") == layout.build, "template and layout builds differ")
assert(not workspace:FindFirstChild("__SCShoreWalkProbe"), "owned fixture already exists")

local player = game.Players:GetPlayers()[1]
assert(player and player.Character, "an R15 test player is required")
local original = player.Character
local originalHumanoid = original:FindFirstChildOfClass("Humanoid")
assert(originalHumanoid and originalHumanoid.RigType == Enum.HumanoidRigType.R15, "probe requires R15")

local fixture = template:Clone()
fixture.Name = "__SCShoreWalkProbe"
for _, descendant in fixture:GetDescendants() do
    if descendant:IsA("BaseScript") then descendant.Enabled = false end
end
fixture:PivotTo(fixture:GetPivot() + Vector3.new(1600, 0, 0))
fixture.Parent = workspace

local surfaces = fixture.Obstacles.WalkingSurfaces
local bars = fixture.Decoration.Obstacles
local names = { "S04_Shore_00", "S04_Shore_01", "S04_Shore_02", "S04_Shore_03",
    "S04_Shore_04", "S04_Shore_05", "S04_Shore_06", "HarborAssembly" }
for _, name in names do assert(surfaces:FindFirstChild(name), "missing " .. name) end
local timber = { [3] = assert(bars:FindFirstChild("ShoreTimber2")),
    [6] = assert(bars:FindFirstChild("ShoreTimber5")) }
for _, bar in timber do assert(not bar.CanCollide and not bar.CanTouch, "timber bar must be noncolliding in movement fixture") end
local launchDistance = script:GetAttribute("LaunchDistance") or 7
assert(type(launchDistance) == "number" and launchDistance >= 4 and launchDistance <= 8,
    "LaunchDistance must be between 4 and 8 studs")

local archivable = original.Archivable
original.Archivable = true
local character = original:Clone()
original.Archivable = archivable
character.Name = "__SCShoreWalker"
for _, descendant in character:GetDescendants() do
    if descendant:IsA("BaseScript") then descendant.Enabled = false end
    if descendant:IsA("BasePart") then descendant.Anchored = false end
end
character.Parent = workspace
local humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
local root = assert(character:FindFirstChild("HumanoidRootPart"))
local feet = { assert(character:FindFirstChild("LeftFoot")), assert(character:FindFirstChild("RightFoot")) }
root:SetNetworkOwner(nil)
humanoid.WalkSpeed = 16
humanoid.UseJumpPower = false
humanoid.JumpHeight = 7.2
humanoid.EvaluateStateMachine = true

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { surfaces }
rayParams.RespectCanCollide = true
local direction = Vector3.zero
local jump = false
local binding = RunService.PreSimulation:Connect(function()
    humanoid:Move(direction, false)
    humanoid.Jump = jump
end)

local function flat(point)
    return Vector3.new(point.X, 0, point.Z)
end

local function pointRecord(point)
    return { math.round(point.X * 100) / 100, math.round(point.Y * 100) / 100,
        math.round(point.Z * 100) / 100 }
end

local function top(part)
    return part.Position + part.CFrame.UpVector * part.Size.Y / 2
end

local function support()
    local hit = workspace:Raycast(root.Position, Vector3.new(0, -4.3, 0), rayParams)
    if not hit or humanoid.FloorMaterial == Enum.Material.Air then return nil end
    local part = hit.Instance
    if part.Name == "HarborAssembly" or part:GetAttribute("Section") == "S04_Shore" then return part end
    return nil
end

local function waitFor(predicate, seconds)
    local deadline = os.clock() + seconds
    repeat RunService.Heartbeat:Wait() until predicate() or os.clock() > deadline
    return predicate()
end

local function walkTo(target, seconds, record, allowAir)
    local deadline = os.clock() + seconds
    while (flat(target - root.Position)).Magnitude > 1.1 do
        assert(os.clock() < deadline, "walk timed out toward " .. record.to)
        if not allowAir then assert(support(), "lost shore support toward " .. record.to) end
        local delta = flat(target - root.Position)
        direction = delta.Unit
        RunService.Heartbeat:Wait()
    end
    direction = Vector3.zero
    assert(waitFor(function() return support() ~= nil end, if allowAir then 1 else .2),
        "did not ground near " .. record.to)
end

local function footExtents(part)
    local cf, half = part.CFrame, part.Size / 2
    local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector
    return Vector3.new(
        math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(look.X) * half.Z,
        math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(look.Y) * half.Z,
        math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(look.Z) * half.Z)
end

local function sampleBar(bar, record)
    local barHalf = bar.Size / 2
    local barTop = bar.Position.Y + barHalf.Y
    for _, foot in feet do
        local half = footExtents(foot)
        if math.abs(foot.Position.X - bar.Position.X) <= barHalf.X + half.X
            and math.abs(foot.Position.Z - bar.Position.Z) <= barHalf.Z + half.Z then
            local margin = foot.Position.Y - half.Y - barTop
            record.overlapFrames += 1
            record.firstOverlapSignedDistance = record.firstOverlapSignedDistance
                or math.round(record.signedDistance * 100) / 100
            record.lastOverlapSignedDistance = math.round(record.signedDistance * 100) / 100
            if margin < (record.minimumFootMargin or math.huge) then
                record.minimumFootMargin = margin
                record.minimumMarginObservation = { foot = foot.Name,
                    footBottom = math.round((foot.Position.Y - half.Y) * 1000) / 1000,
                    barTop = math.round(barTop * 1000) / 1000,
                    position = pointRecord(root.Position),
                    grounded = humanoid.FloorMaterial ~= Enum.Material.Air,
                    signedDistance = math.round(record.signedDistance * 100) / 100 }
            end
        end
    end
end

local first = surfaces[names[1]]
character:PivotTo(CFrame.new(top(first) + Vector3.new(0, 3.12, 0)))
root.AssemblyLinearVelocity = Vector3.zero
humanoid.PlatformStand = false
humanoid.Sit = false
humanoid:ChangeState(Enum.HumanoidStateType.Running)

local result = { build = layout.build, walkSpeed = 16, jumpHeight = 7.2,
    requestedLaunchDistance = launchDistance,
    method = "Server-owned R15 clone on course template translated 1600 studs. One initial teleport, continuous shore movement, no Runtime.Create; timed hazards inactive. Both static timber bars are noncolliding.",
    records = {}, initialPosition = pointRecord(root.Position) }

local ok, errorText = pcall(function()
    assert(waitFor(function() return support() ~= nil end, 1.5), "initial shore cap did not ground")
    for index = 2, #names do
        local destination = surfaces[names[index]]
        local previous = surfaces[names[index - 1]]
        local d = flat(top(destination) - top(previous)).Unit
        local record = { from = names[index - 1], to = names[index],
            actualStart = pointRecord(root.Position), startSupport = support().Name }
        table.insert(result.records, record)

        local bar = timber[index]
        if bar then
            local launch = top(bar) - d * launchDistance
            walkTo(launch, 3.5, record, false)
            assert(support(), "not grounded seven studs before " .. bar.Name)
            record.bar = bar.Name
            record.launchPosition = pointRecord(root.Position)
            record.launchDistance = math.round(flat(root.Position - bar.Position).Magnitude * 100) / 100
            record.groundedTakeoff = true
            record.overlapFrames = 0
            local before = flat(root.Position - bar.Position):Dot(d)
            record.takeoffSignedDistance = math.round(before * 100) / 100
            local barHalfAlongPath = math.abs(d:Dot(bar.CFrame.RightVector)) * bar.Size.X / 2
                + math.abs(d:Dot(bar.CFrame.LookVector)) * bar.Size.Z / 2
            local exitDistance = barHalfAlongPath + 1.2
            local centerlineHalfChord = math.min(
                bar.Size.X / 2 / math.max(.0001, math.abs(d:Dot(bar.CFrame.RightVector))),
                bar.Size.Z / 2 / math.max(.0001, math.abs(d:Dot(bar.CFrame.LookVector))))
            record.barProjectedHalfExtent = math.round(barHalfAlongPath * 100) / 100
            record.centerlineHalfChord = math.round(centerlineHalfChord * 100) / 100
            record.exitDistanceIncludingFeet = math.round(exitDistance * 100) / 100
            assert(before < -(launchDistance - 2), "launch was too close to " .. bar.Name)
            direction = d
            jump = true
            assert(waitFor(function() return humanoid.FloorMaterial == Enum.Material.Air end, .4),
                "jump did not take off before " .. bar.Name)
            jump = false
            record.jumpPerformed = true
            local deadline = os.clock() + 2.5
            local crossed = false
            while os.clock() < deadline do
                RunService.Heartbeat:Wait()
                local signed = flat(root.Position - bar.Position):Dot(d)
                record.signedDistance = signed
                sampleBar(bar, record)
                if before < 0 and signed >= 0 then crossed = true end
                before = signed
                if humanoid.FloorMaterial == Enum.Material.Air then
                    record.lastAirborneSignedDistance = math.round(signed * 100) / 100
                elseif record.firstGroundedSignedDistance == nil then
                    record.firstGroundedSignedDistance = math.round(signed * 100) / 100
                    record.firstGroundedPosition = pointRecord(root.Position)
                    local firstSupport = support()
                    record.firstGroundedSupport = if firstSupport then firstSupport.Name else nil
                end
                if signed > exitDistance and support() then break end
            end
            direction = Vector3.zero
            record.crossedBarPlane = crossed
            record.exitSignedDistance = math.round(before * 100) / 100
            record.afterBarPosition = pointRecord(root.Position)
            record.afterBarSupport = if support() then support().Name else nil
            if record.firstGroundedSignedDistance then
                record.airborneTravel = math.round((record.firstGroundedSignedDistance
                    - record.takeoffSignedDistance) * 100) / 100
            end
            record.minimumFootMargin = if record.minimumFootMargin then
                math.round(record.minimumFootMargin * 1000) / 1000 else nil
            record.feetClearanceVerified = crossed and record.overlapFrames > 0
                and record.minimumFootMargin ~= nil and record.minimumFootMargin > .1
            assert(crossed, "did not cross " .. bar.Name)
            assert(before > exitDistance, "did not move fully beyond " .. bar.Name)
            assert(support(), "did not land on shore after " .. bar.Name)
        end

        if not bar then walkTo(top(destination), 3.5, record, false) end
        record.actualLanding = record.firstGroundedPosition or pointRecord(root.Position)
        record.landingSupport = record.firstGroundedSupport or support().Name
        record.movementPassed = true
        record.passed = not bar or record.feetClearanceVerified
        script:SetAttribute("Progress", index - 1)
        script:SetAttribute("LastLanding", record.to .. " " .. HttpService:JSONEncode(record.actualLanding))
    end
end)

direction = Vector3.zero
jump = false
binding:Disconnect()
result.movementPassed = ok and #result.records == #names - 1
local barsCleared = 0
for _, record in result.records do
    if record.feetClearanceVerified then barsCleared += 1 end
end
result.barClearanceVerified = barsCleared == 2
result.passed = result.movementPassed and result.barClearanceVerified
result.error = if ok then nil else tostring(errorText)
result.finalPosition = pointRecord(root.Position)
script:SetAttribute("Result", HttpService:JSONEncode(result))
if result.passed or script:GetAttribute("KeepOnFailure") ~= true then
    character:Destroy()
    fixture:Destroy()
end
