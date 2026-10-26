local function makeTest()
local Test = {}
local RunService = game:GetService("RunService")

-- Points describe original-template world positions at the collision surface top.
function Test.Run(template, routeData)
    assert(RunService:IsStudio() and RunService:IsServer(), "Run in Studio server Play")
    local live = assert(game.Players:GetPlayers()[1].Character, "No avatar")
    local oldArchivable=live.Archivable;live.Archivable=true
    local character=live:Clone();live.Archivable=oldArchivable
    for _,s in character:GetDescendants() do if s:IsA("LuaSourceContainer") then s:Destroy() end end
    character.Name="__C15PhysicsAvatar";character.Parent=workspace
    local root, humanoid = character.HumanoidRootPart, character.Humanoid
    assert(humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight - 7.2) < .01, "Movement tuning changed")
    assert(math.abs(workspace.Gravity - 196.2) < .01, "Gravity changed")
    local saved, anchored = character:GetPivot(), root.Anchored
    local originalPivot = template:GetPivot()
    local fixture = template:Clone()
    fixture.Name = "__C14TraversalFixture"
        local external=Instance.new("Folder")
    external.Name,external.Parent="ExternalCollisionContext",fixture
    for _,item in workspace:GetDescendants() do
        if item:IsA("BasePart") and not item:IsA("Terrain") and item.CanCollide
            and not item:IsDescendantOf(character) and not item:IsDescendantOf(fixture)
            and not item:IsDescendantOf(template)
            and item.Position.X>=3100 and item.Position.X<=4050
            and item.Position.Z>=-500 and item.Position.Z<=400 then
            local copy=item:Clone()
            for _,child in copy:GetDescendants() do if child:IsA("LuaSourceContainer") then child:Destroy() end end
            copy:SetAttribute("ExternalSource",item:GetFullName())
            copy.Parent=external
        end
    end
fixture:PivotTo(CFrame.new(8000, 100, 0))
    fixture.Parent = workspace
    local current, recoveries = fixture, 0
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = {fixture}
    rayParams.RespectCanCollide = true
    local movement, jumping = Vector3.zero, false
    local records, attempts = {}, {}
    local approach
    local connection
    local function waitUntil(predicate, seconds, message)
        local deadline = os.clock() + seconds
        repeat RunService.Heartbeat:Wait() until predicate() or os.clock() > deadline
        assert(predicate(), message)
    end
    local function standingPart()
        local hit = workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + .4), 0), rayParams)
        return hit and hit.Instance
    end
    local function pointWorld(point)
        return fixture:GetPivot():PointToWorldSpace(originalPivot:PointToObjectSpace(point.center))
    end
    local function pointPart(point)
        if point.part then
            local target = fixture
            for token in string.gmatch(point.part, "[^/]+") do target = assert(target:FindFirstChild(token), token .. " missing") end
            assert(target:IsA("BasePart"), "Point part must be a collision BasePart")
            return target
        end
        local center = pointWorld(point)
        local hit = workspace:Raycast(center + Vector3.new(0, .3, 0), Vector3.new(0, -.8, 0), rayParams)
        return assert(hit and hit.Instance, "No collision under route point " .. tostring(center))
    end
    local function edgeDistance(part, position, direction)
        local p, d = part.CFrame:PointToObjectSpace(position), part.CFrame:VectorToObjectSpace(direction)
        local distance = math.huge
        for _, axis in {"X", "Z"} do
            if math.abs(d[axis]) > .0001 then
                local boundary = math.sign(d[axis]) * part.Size[axis] / 2
                distance = math.min(distance, (boundary - p[axis]) / d[axis])
            end
        end
        return distance
    end
    local function edgeMargin(part)
        local p = part.CFrame:PointToObjectSpace(root.Position)
        return math.min(part.Size.X / 2 - math.abs(p.X), part.Size.Z / 2 - math.abs(p.Z))
    end
    local ok, failure = xpcall(function()
        root.Anchored = false
        root:SetNetworkOwner(nil)
        connection = RunService.PreSimulation:Connect(function()
            if approach and not approach.requested and edgeDistance(approach.part, root.Position, approach.direction) <= approach.inset then
                approach.requested = true
                approach.launch = root.Position
                approach.launchMargin = edgeMargin(approach.part)
                jumping = true
            end
            humanoid:Move(movement, false)
            humanoid.Jump = jumping
        end)
        for _, route in routeData.routes do
            local first = pointPart(route.points[1])
            local start = pointWorld(route.points[1])
            movement, jumping = Vector3.zero, false
            character:PivotTo(CFrame.new(start + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2 + .15, 0)))
            root.AssemblyLinearVelocity = Vector3.zero
            waitUntil(function() return standingPart() == first and humanoid.FloorMaterial ~= Enum.Material.Air end, 2, route.name .. " setup unsupported")
            for index = 1, #route.points - 1 do
                local from, to = route.points[index], route.points[index + 1]
                local launchPart, targetPart = pointPart(from), pointPart(to)
                local target = pointWorld(to)
                local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
                local direction = flat.Unit
                local name = route.name .. ":" .. index .. "->" .. (index + 1)
                assert(standingPart() == launchPart, name .. " lost starting support")
                local before = recoveries
                local inset = from.launchInset or route.launchInset or .42
                local attempt = {name = name, phase = "Approach", inset = inset}
                table.insert(attempts,attempt)
                approach = {part = launchPart, direction = direction, inset = inset, requested = false}
                movement = direction
                waitUntil(function() return approach.requested end, 3, name .. " could not reach launch edge")
                local launch, launchMargin = approach.launch, approach.launchMargin
                attempt.launchPosition = {launch.X,launch.Y,launch.Z}
                attempt.launchEdgeMargin = launchMargin
                attempt.phase = "JumpRequested"
                waitUntil(function() return humanoid.FloorMaterial == Enum.Material.Air end, .5, name .. " did not jump")
                jumping, approach = false, nil
                local takeoff = os.clock()
                attempt.phase = "Airborne"
                local deadline = takeoff + 1.8
                local reached = false
                local flightSeconds
                repeat
                    local remaining = Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z):Dot(direction)
                    local supported = humanoid.FloorMaterial ~= Enum.Material.Air and standingPart() == targetPart
                    if humanoid.FloorMaterial ~= Enum.Material.Air and not attempt.firstContact then
                        attempt.firstContact = {root.Position.X,root.Position.Y,root.Position.Z}
                        attempt.firstContactSupported = supported
                        attempt.firstContactSeconds = os.clock()-takeoff
                    end
                    if supported and not flightSeconds then flightSeconds = os.clock()-takeoff end
                    -- Keep walking after first foot contact until the root is actually over the landing.
                    movement = if remaining <= .75 then Vector3.zero else direction
                    reached = supported and remaining <= .75 and math.abs(root.AssemblyLinearVelocity.Y) < 2
                    attempt.position = {root.Position.X,root.Position.Y,root.Position.Z}
                    attempt.remaining = remaining
                    attempt.supported = supported
                    if reached then break end
                    RunService.Heartbeat:Wait()
                until os.clock() > deadline or recoveries > before
                movement = Vector3.zero
                assert(recoveries == before, name .. " touched a hazard")
                assert(reached, name .. " failed centered target landing")
                attempt.phase = "Settling"
                local settledAt = os.clock()
                repeat
                    RunService.Heartbeat:Wait()
                    assert(standingPart() == targetPart and humanoid.FloorMaterial ~= Enum.Material.Air, name .. " slid off landing")
                until os.clock() - settledAt >= .15
                local landingMargin = edgeMargin(targetPart)
                assert(landingMargin >= 0, name .. " landing relies on hanging past edge")
                attempt.phase = "Passed"
                local centerDelta = pointWorld(to) - pointWorld(from)
                table.insert(records, {name = name, passed = true, landing = targetPart:GetFullName(),
                    centerDistance = Vector3.new(centerDelta.X, 0, centerDelta.Z).Magnitude,
                    rise = centerDelta.Y, launchEdgeMargin = launchMargin, landingEdgeMargin = landingMargin,
                    flightSeconds = flightSeconds, actualTravel = Vector3.new(root.Position.X - launch.X, 0, root.Position.Z - launch.Z).Magnitude,
                    recoveryCount = recoveries - before, landingPosition = {root.Position.X, root.Position.Y, root.Position.Z}})
            end
        end
    end, debug.traceback)
    if connection then connection:Disconnect() end
    current = nil
    humanoid:Move(Vector3.zero, false)
    humanoid.Jump = false
    character:PivotTo(saved)
    root.Anchored = anchored
    root.AssemblyLinearVelocity = Vector3.zero
    if not anchored then root:SetNetworkOwnershipAuto() end
    fixture:Destroy()
    character:Destroy()
    return {passed = ok, records = records, attempts = attempts, failure = if ok then nil else failure,
        physics = {walkSpeed = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight, gravity = workspace.Gravity},
        method = "Cloned normal avatar, normal movement physics, sequential walk-to-edge jumps and supported settled landings; teleport only at route start",
        limitation = "Physics rig proves selected geometry reachability only; it does not test server hazard recovery, human input, latency or full-course flow"}
end
return Test


end
local function run()
local points={} local c=game.ServerStorage.CourseLibrary.Course_CityRun local function row(name,section) local m=c.Obstacles.C15Routes[section][name];local p=m.Collider;return {center=p.Position+Vector3.new(0,p.Size.Y/2,0),part='Obstacles/C15Routes/'..section..'/'..name..'/Collider'} end
local routes={}
local e={} for i=1,21 do table.insert(e,row(string.format('C15_Expert_%02d',i),'ExpertOffsets')) end table.insert(e,1,row('C15_Expert_Start','ExpertOffsets'));table.insert(e,row('C15_Expert_End','ExpertOffsets'));table.insert(routes,{name='HarderExpert',points=e,launchInset=.55});
local p={{center=Vector3.new(3695,86,59),launchInset=100,part='Obstacles/WalkingSurfaces/CP08/CP08'}} for i=1,16 do table.insert(p,row(string.format('C15_Post_%02d',i),'TerminalPosts')) end table.insert(p,{center=Vector3.new(3695,132,175.5),part='Obstacles/WalkingSurfaces/CP09/CP09'});table.insert(routes,{name='TerminalPosts',points=p,launchInset=.35})
local k={} for i=0,23 do table.insert(k,row(string.format('C15_Corner_%02d',i),'CornerLedges')) end table.insert(routes,{name='RisingFallingLedges',points=k,launchInset=.5})
return makeTest().Run(c,{routes=routes})
end

local r=Instance.new('StringValue');r.Name='C15TraversalResult';r.Parent=game.ServerStorage;r.Value='Running'
task.spawn(function() local ok,result=pcall(run);r.Value=game:GetService('HttpService'):JSONEncode({ok=ok,result=result}) end)
return 'Started cloned-avatar geometry reachability check'