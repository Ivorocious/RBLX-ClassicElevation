-- Run in an active Shipwreck Studio race; this moves the test player's character.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient(), "Studio client required")
local player = game.Players.LocalPlayer
local character = assert(player.Character)
local humanoid = character:FindFirstChildOfClass("Humanoid")
local root = character.HumanoidRootPart
local course = workspace.RaceCourse
assert(course.CourseInfo:GetAttribute("CourseId") == "shipwreck_cove")
local zone = course.FallZones.FallZone_Main
assert(zone.CFrame == course.Bounds.CourseOrigin.CFrame * CFrame.new(0, -1, 0))
local remote = game.ReplicatedStorage.Remotes.StudioDevControl
assert(remote:InvokeServer({action="Teleport", destination="Start"}).ok)
task.wait(0.8)
local function falls()
    for _, object in player.PlayerGui:GetDescendants() do
        if object:IsA("TextLabel") then
            local number = object.Text:match("^Falls: (%d+)$")
            if number then return tonumber(number) end
        end
    end
    error("Fall counter unavailable")
end
local before = falls()
local direction = Vector3.zero
local jumping = false
local binding = "ShipwreckFallZoneCheck"
RunService:BindToRenderStep(binding, Enum.RenderPriority.Input.Value + 1, function()
    humanoid:Move(direction, false)
    humanoid.Jump = jumping
end)
local function waitUntil(predicate, seconds)
    local deadline = os.clock() + seconds
    repeat RunService.Heartbeat:Wait() until predicate() or os.clock() > deadline
    assert(predicate(), "Movement check timed out")
end
local ok, result = xpcall(function()
    local peak = root.Position.Y
    jumping = true
    task.wait(0.15)
    jumping = false
    local deadline = os.clock() + 1.3
    repeat
        RunService.Heartbeat:Wait()
        peak = math.max(peak, root.Position.Y)
    until os.clock() > deadline
    assert(peak > 95.1, "Jump did not cross the former reset plane")
    assert(falls() == before, "Normal jump caused a reset")
    local harbor = course.Obstacles.WalkingSurfaces.HarborAssembly
    local dock = course.Obstacles.WalkingSurfaces.S01_00
    local heading = Vector3.new(dock.Position.X-root.Position.X, 0, dock.Position.Z-root.Position.Z).Unit
    direction = heading
    local takeoffZ = harbor.Position.Z - harbor.Size.Z/2 + 1.5
    waitUntil(function() return root.Position.Z <= takeoffZ end, 3)
    jumping = true
    task.wait(0.15)
    jumping = false
    waitUntil(function() return root.Position.Z <= dock.Position.Z + 0.5 end, 2)
    direction = Vector3.zero
    waitUntil(function() return humanoid.FloorMaterial ~= Enum.Material.Air end, 1.5)
    task.wait(0.3)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances = {course.Obstacles.WalkingSurfaces}
    params.RespectCanCollide = true
    local hit = workspace:Raycast(root.Position, Vector3.new(0,-5,0), params)
    assert(hit and hit.Instance == dock, "Did not land on the first dock")
    assert(falls() == before, "First dock jump caused a reset")
    character:PivotTo(course.Bounds.CourseOrigin.CFrame * CFrame.new(0, 8, 20))
    root.AssemblyLinearVelocity = Vector3.zero
    waitUntil(function() return falls() > before end, 4)
    task.wait(0.5)
    assert((root.Position-course.Start.Position).Magnitude < 10, "Fall did not recover to start")
    return {passed=true, normalJumpPeak=peak, firstDockLanding=true,
        fallsBefore=before, fallsAfter=falls(), realFallRecovered=true, zoneY=zone.Position.Y}
end, debug.traceback)
RunService:UnbindFromRenderStep(binding)
humanoid:Move(Vector3.zero, false)
assert(ok, result)
return result
