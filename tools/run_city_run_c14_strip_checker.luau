local function makeTest()
local Test = {}
local RunService = game:GetService("RunService")

-- Points describe original-template world positions at the collision surface top.
function Test.Run(template, routeData)
    assert(RunService:IsStudio() and RunService:IsServer(), "Run in Studio server Play")
    local player = assert(game.Players:GetPlayers()[1], "No test player")
    local character = assert(player.Character, "No avatar")
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
    local source = game.ServerScriptService.Services.CourseHazardService:Clone()
    source.Parent = game.ServerStorage
    local service = require(source)
    service.Init({Services = {
        RaceService = {IsRaceActive = function() return true end},
        PlayerRaceService = {IsOfficialRacer = function(p) return p == player end, GetPlayerStatus = function() return "Racing" end},
        CourseService = {GetActiveCourse = function() return current end},
        RespawnService = {RecoverPlayer = function() recoveries += 1 return true end},
    }})
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
        service.Start()
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
                    movement = if remaining <= .2 then Vector3.zero else direction
                    reached = supported and remaining <= .2 and math.abs(root.AssemblyLinearVelocity.Y) < 2
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
    service.BindActiveCourse()
    humanoid:Move(Vector3.zero, false)
    humanoid.Jump = false
    character:PivotTo(saved)
    root.Anchored = anchored
    root.AssemblyLinearVelocity = Vector3.zero
    if not anchored then root:SetNetworkOwnershipAuto() end
    fixture:Destroy()
    source:Destroy()
    return {passed = ok, records = records, attempts = attempts, failure = if ok then nil else failure,
        physics = {walkSpeed = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight, gravity = workspace.Gravity},
        method = "Actual avatar, normal movement physics, sequential walk-to-edge jumps and supported settled landings; teleport only at route start",
        limitation = "Scripted server-owned avatar proves selected geometry reachability; human input difficulty, client latency and full-course flow still need playtesting"}
end
return Test


end

local d=require(game.ServerStorage.CourseBuilders.CityRun.C14Manifest)
local strips={}
for i,p in d.routes.DepotEntry do
 local x,y,z=unpack(p.center)
 local a,b
 if i<4 then a={x-3,y,z};b={x+3,y,z}
 else a={x+3,y,z-3.5};b={x+3,y,z+3.5} end
 table.insert(strips,{center=Vector3.new(unpack(a)),part=p.part,launchInset=100})
 table.insert(strips,{center=Vector3.new(unpack(b)),part=p.part,launchInset=.42})
end
local checker={{center=Vector3.new(3665,82,-90),part="Obstacles/C14Routes/DepotExit/C14_DepotCheckpoint/Collider",launchInset=.42}}
for i,p in d.routes.CheckerExit do
 local x,y,z=unpack(p.center);local w,_,depth=unpack(p.size)
 local alongX=i==3 or i==4
 local width=if alongX then depth else w
 local length=if alongX then w else depth
 for row=0,2 do
  local safe=1-(row+(if i==5 then 1 else 0))%2
  local across=-width/2+width/2*(safe+.5)
  local along=-length/2+length/3*(row+.5)
  table.insert(checker,{center=Vector3.new(x+(if alongX then along else across),y,z+(if alongX then across else along)),part=p.part,launchInset=if row<2 then 100 else .42})
 end
end
return makeTest().Run(game.ServerStorage.CourseLibrary.Course_CityRun,{routes={{name="DepotStripTwoJumpCadence",points=strips},{name="HardCheckerSafeSquares",points=checker}}})
