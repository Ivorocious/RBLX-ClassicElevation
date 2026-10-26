local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")

assert(RunService:IsStudio(), "Studio diagnostic only")
local Layout = require(ServerStorage.CourseBuilders.ShipwreckCove.Layout)
local Config = require(game.ReplicatedStorage.Config.ShipwreckConfig)
local Runtime = require(ServerStorage.CourseBuilders.ShipwreckCove.Runtime)
local player = assert(Players:GetPlayers()[1], "Need a Studio test player")
local originalCharacter = assert(player.Character, "Player has no character")
local originalHumanoid = assert(originalCharacter:FindFirstChildOfClass("Humanoid"))
assert(originalHumanoid.RigType == Enum.HumanoidRigType.R15, "Need an R15 test player")
local template = assert(ServerStorage.CourseLibrary:FindFirstChild("Course_ShipwreckCove"))
assert(template:GetAttribute("ShipwreckBuild") == Layout.build, "Fixture and source differ")

local fixture, clone, controller
local records = {}
local hits = {}
local function position(p)
    return {p.X, p.Y, p.Z}
end
local function cleanup()
    if controller then pcall(controller.Stop) end
    if clone and player.Character == clone then player.Character = originalCharacter end
    if clone then clone:Destroy() end
    if fixture then fixture:Destroy() end
end

local ok, err = xpcall(function()
    fixture = template:Clone()
    fixture.Name = "__SCBall0Diagnostic"
    fixture:PivotTo(fixture:GetPivot() + Vector3.new(1000, 0, 0))
    fixture.Parent = workspace
    local origin = fixture.Bounds.CourseOrigin.CFrame
    local deck = assert(fixture.Obstacles.WalkingSurfaces:FindFirstChild("BatteryDeck0"))
    local shot = assert(Layout.shots[1])
    assert(shot.name == "Ball0", "First shot is not Ball0")

    local wasArchivable = originalCharacter.Archivable
    originalCharacter.Archivable = true
    clone = originalCharacter:Clone()
    originalCharacter.Archivable = wasArchivable
    assert(clone, "Could not clone R15")
    clone.Name = "__SCBall0R15"
    for _, descendant in clone:GetDescendants() do
        if descendant:IsA("BaseScript") then descendant.Disabled = true end
    end
    clone.Parent = workspace
    local humanoid = assert(clone:FindFirstChildOfClass("Humanoid"))
    local root = assert(clone:FindFirstChild("HumanoidRootPart"))
    player.Character = clone -- Runtime reads the player's Character; the real R15 stays in place.
    root:SetNetworkOwner(nil)

    controller = Runtime.Create(fixture, function(_, source)
        table.insert(hits, source)
    end, function(candidate)
        return candidate == player
    end)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = {fixture.Obstacles.WalkingSurfaces}
    local function support()
        local ray = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), rayParams)
        return ray and ray.Instance.Name or nil
    end

    local deckLocal = origin:PointToObjectSpace(deck.Position)
    local fire = shot.phase + Config.CannonWarning
    for trial = 1, 3 do
        clone:PivotTo(origin * CFrame.new(deckLocal.X, deckLocal.Y + deck.Size.Y / 2 + 3.1, shot.start[3]))
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        humanoid.PlatformStand = false
        humanoid.Sit = false
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
        clone:SetAttribute("RecoveryUntil", 0)
        task.wait(0.35)

        hits = {}
        controller.Reset()
        local t = fire - 0.2
        controller.Step(t, 0, false)
        local record = {
            trial = trial,
            startRootLocal = position(origin:PointToObjectSpace(root.Position)),
            startSupport = support(),
            startFloorMaterial = humanoid.FloorMaterial.Name,
            maxDt = 0,
            frameCount = 0,
        }
        while t < fire + 1.3 do
            local dt = RunService.Heartbeat:Wait()
            record.maxDt = math.max(record.maxDt, dt)
            record.frameCount += 1
            t += dt
            controller.Step(t, dt, true)
        end
        record.endRootLocal = position(origin:PointToObjectSpace(root.Position))
        record.endSupport = support()
        record.endFloorMaterial = humanoid.FloorMaterial.Name
        record.hits = table.clone(hits)
        record.ball0Hit = table.find(hits, "H01 Cannon") ~= nil
        table.insert(records, record)
        script:SetAttribute("Progress", trial)
    end
end, debug.traceback)

cleanup()
script:SetAttribute("Result", HttpService:JSONEncode({
    build = Layout.build,
    records = records,
    error = if ok then nil else tostring(err),
    method = "Three standing cloned-R15 Ball0 trials on the production Runtime and translated course fixture; controlled clock, not a full race or device/load test",
}))
