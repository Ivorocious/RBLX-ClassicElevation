-- Load this recipe as source in the Play server; the bridge performs and records initial setup separately.
local Probe = {}

function Probe.Run(options)
    options = options or {}
    local RunService = game:GetService("RunService")
    assert(RunService:IsStudio() and RunService:IsRunning() and RunService:IsServer(), "Run in a Studio Play server")
    local Players = game:GetService("Players")
    local player = if options.playerUserId then Players:GetPlayerByUserId(options.playerUserId) else Players:GetPlayers()[1]
    assert(player and player.Character, "Test player is not ready")
    local character = player.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    assert(humanoid and root and root:IsA("BasePart"), "Test character is not ready")
    local course = assert(workspace:FindFirstChild("RaceCourse") or workspace:FindFirstChild("Course_HeartwoodAscent"), "Heartwood course is missing")
    assert(course:GetAttribute("HeartwoodBuild") == (options.expectedBuild or "HA_V1_04"), "Unexpected Heartwood candidate")
    local origin = course.Bounds.CourseOrigin.Position
    local section = course.Decoration.S04_SanctuaryBough
    local catch, receiver = section.Catch, section.J3
    local takeoffPoint = Vector3.new(-31, 101, 77)
    local target = origin + Vector3.new(-30, 122, 78)
    local depth = humanoid.HipHeight + root.Size.Y / 2
    local scan = RaycastParams.new()
    scan.FilterType = Enum.RaycastFilterType.Include
    scan.FilterDescendantsInstances = {course}
    scan.RespectCanCollide = true
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Include
    overlap.FilterDescendantsInstances = {character}
    overlap.RespectCanCollide = false

    local function coordinates(position)
        local p = position - origin
        return {p.X, p.Y, p.Z}
    end

    local function snapshot()
        local hit = workspace:Raycast(root.Position, Vector3.new(0, -(depth + .8), 0), scan)
        local method = if hit then "CenterRay" else "None"
        local distance = hit and hit.Distance
        local supported = distance ~= nil and math.abs(distance - depth) < .8
        if not supported then
            local foot = workspace:Raycast(root.Position - Vector3.new(0, depth - .35, 0), Vector3.new(0, -1.15, 0), scan)
            local footDistance = foot and foot.Distance + depth - .35
            if footDistance and math.abs(footDistance - depth) < .8 then
                hit, distance, supported, method = foot, footDistance, true, "FeetRay"
            end
        end
        if not supported then
            local sphere = workspace:Spherecast(root.Position, .65, Vector3.new(0, -(depth + .8), 0), scan)
            local sphereDistance = sphere and sphere.Distance + .65
            if sphereDistance and math.abs(sphereDistance - depth) < .8 then
                hit, distance, supported, method = sphere, sphereDistance, true, "FootprintSphere"
            end
        end
        local velocity = root.AssemblyLinearVelocity
        return {
            position = coordinates(root.Position), velocity = {velocity.X, velocity.Y, velocity.Z},
            state = humanoid:GetState().Name, jump = humanoid.Jump, floorMaterial = humanoid.FloorMaterial.Name,
            grounded = supported and humanoid.FloorMaterial ~= Enum.Material.Air,
            support = hit and hit.Instance:GetFullName(), supportMethod = method,
            supportDepthDifference = distance and distance - depth,
            onCatch = hit ~= nil and hit.Instance == catch.Top,
            onReceiver = hit ~= nil and hit.Instance == receiver.Top,
            recoveryUntil = character:GetAttribute("RecoveryUntil") or 0,
            targetDistance = ((root.Position - target) * Vector3.new(1, 0, 1)).Magnitude,
        }
    end

    local before = snapshot()
    local takeoffDistance = ((root.Position - origin - takeoffPoint) * Vector3.new(1, 0, 1)).Magnitude
    local report = {
        candidate = course:GetAttribute("HeartwoodBuild"), playerUserId = player.UserId,
        scope = "One forced normal jump in a solo Studio server; bridge state before/after is required separately",
        takeoffPoint = {takeoffPoint.X, takeoffPoint.Y, takeoffPoint.Z}, takeoffDistance = takeoffDistance,
        attemptedReceiver = receiver:GetFullName(), target = {-30, 122, 78}, before = before,
        movement = {walkSpeed = humanoid.WalkSpeed, jumpHeight = humanoid.JumpHeight,
            jumpPower = humanoid.JumpPower, useJumpPower = humanoid.UseJumpPower, gravity = workspace.Gravity,
            autoJump = humanoid.AutoJumpEnabled, serverOwnsRoot = root:GetNetworkOwner() == nil},
        initialSetupInsideRecorder = false, withinRunRepositions = 0, progressWrites = 0,
        jumpCommands = 0, samples = {}, stateChanges = {}, contacts = {},
    }
    local normalJump = if humanoid.UseJumpPower then humanoid.JumpPower ^ 2 / (2 * workspace.Gravity) else humanoid.JumpHeight
    local localPoint = catch.Top.CFrame:PointToObjectSpace(root.Position)
    report.takeoffBoundsMargin = {catch.Top.Size.X / 2 - math.abs(localPoint.X), catch.Top.Size.Z / 2 - math.abs(localPoint.Z)}
    local refusal
    if humanoid.Health <= 0 or root.Anchored then refusal = "character-not-movable"
    elseif not before.grounded or not before.onCatch then refusal = "takeoff-not-grounded-on-catch"
    elseif takeoffDistance > 1.2 then refusal = "outside-selected-edge-takeoff"
    elseif math.min(report.takeoffBoundsMargin[1], report.takeoffBoundsMargin[2]) < 3 then refusal = "insufficient-takeoff-edge-margin"
    elseif before.recoveryUntil > workspace:GetServerTimeNow() then refusal = "takeoff-recovery-immunity-active"
    elseif root:GetNetworkOwner() ~= nil then refusal = "initial-setup-must-give-server-root-ownership"
    elseif humanoid.AutoJumpEnabled then refusal = "initial-setup-must-disable-auto-jump"
    elseif math.abs(humanoid.WalkSpeed - 16) > .01 or math.abs(normalJump - 7.2) > .05
        or math.abs(workspace.Gravity - 196.2) > .01 then refusal = "unexpected-normal-movement"
    elseif options.bridgeBefore and (options.bridgeBefore.checkpoint ~= 3 or options.bridgeBefore.status ~= "Racing") then
        refusal = "bridge-before-is-not-racing-at-checkpoint-three"
    end
    if refusal then
        report.classification = refusal
        report.validAttempt = false
        report.after = snapshot()
        return report
    end

    local started = os.clock()
    local takeoffY, highestY = root.Position.Y, root.Position.Y
    local peakUpwardVelocity, airborne, receiverLanded, recovered, changedCharacter = 0, false, false, false, false
    local finalStable, receiverStable = 0, 0
    local jumpCleared = false
    local lastSample, lastState = -math.huge, before.state
    local contacted = {}
    local connection = humanoid.StateChanged:Connect(function(oldState, newState)
        table.insert(report.stateChanges, {elapsed = os.clock() - started, from = oldState.Name, to = newState.Name,
            position = coordinates(root.Position), velocityY = root.AssemblyLinearVelocity.Y})
    end)

    local function steer()
        local delta = (target - root.Position) * Vector3.new(1, 0, 1)
        humanoid:Move(if delta.Magnitude > .6 then delta.Unit else Vector3.zero, false)
    end

    local function recordContacts(elapsed)
        for _, part in workspace:GetPartsInPart(receiver.Top, overlap) do
            if part.Parent == character and not contacted[part.Name] then
                contacted[part.Name] = true
                table.insert(report.contacts, {elapsed = elapsed, characterPart = part.Name,
                    receiverPart = receiver.Top:GetFullName(), position = coordinates(root.Position),
                    velocityY = root.AssemblyLinearVelocity.Y, grounded = humanoid.FloorMaterial ~= Enum.Material.Air,
                    footY = root.Position.Y - origin.Y - depth,
                    receiverTopY = (receiver.Top:GetAttribute("SurfaceTopCFrame") or receiver.Top.CFrame).Position.Y - origin.Y,
                    kind = "spatial-overlap-with-receiver-top"})
            end
        end
    end

    -- This command is independent of the old gap scanner; only observed lift counts as a physical jump.
    steer()
    humanoid.Jump = true
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    report.jumpCommands = 1
    report.immediatelyAfterCommand = snapshot()
    repeat
        RunService.Heartbeat:Wait()
        local elapsed = os.clock() - started
        if player.Character ~= character or not root.Parent then
            changedCharacter = true
            report.stopReason = "character-changed"
            break
        end
        local state = snapshot()
        if not jumpCleared then
            humanoid.Jump = false
            jumpCleared = true
            report.jumpRequestClearedAt = elapsed
        end
        if state.recoveryUntil > before.recoveryUntil then
            recovered = true
            report.recovery = {elapsed = elapsed, state = state}
            report.stopReason = "recovery-observed"
            break
        end
        peakUpwardVelocity = math.max(peakUpwardVelocity, root.AssemblyLinearVelocity.Y)
        airborne = airborne or (not state.grounded and humanoid.FloorMaterial == Enum.Material.Air)
        if root.Position.Y > highestY then
            highestY = root.Position.Y
            report.apex = {elapsed = elapsed, position = state.position, state = state.state,
                velocityY = root.AssemblyLinearVelocity.Y}
        end
        recordContacts(elapsed)
        if state.grounded and state.onReceiver and math.abs(root.AssemblyLinearVelocity.Y) < 5 then
            receiverStable += 1
        else receiverStable = 0 end
        if receiverStable >= 4 then
            receiverLanded = true
            report.receiverLanding = {elapsed = elapsed, state = state}
            report.stopReason = "receiver-grounded"
        end
        if airborne and state.grounded and math.abs(root.AssemblyLinearVelocity.Y) < 2 then
            finalStable += 1
        else finalStable = 0 end
        if elapsed - lastSample >= .05 or state.state ~= lastState or receiverLanded then
            state.elapsed = elapsed
            table.insert(report.samples, state)
            lastSample, lastState = elapsed, state.state
        end
        if receiverLanded then break end
        if elapsed >= .75 and finalStable >= 6 then report.stopReason = "landed-away-from-receiver"; break end
        steer()
    until os.clock() - started >= 4
    connection:Disconnect()
    humanoid:Move(Vector3.zero, false)
    humanoid.Jump = false
    report.elapsed = os.clock() - started
    report.after = if root.Parent then snapshot() else nil
    report.highestRootY = highestY - origin.Y
    report.highestFootY = highestY - origin.Y - depth
    report.actualRise = highestY - takeoffY
    report.peakUpwardVelocity = peakUpwardVelocity
    report.sawAirborne = airborne
    report.jumpObserved = airborne and peakUpwardVelocity > 1 and report.actualRise >= .25
    report.validAttempt = report.jumpCommands == 1 and report.jumpObserved and not changedCharacter
    report.receiverLanded = receiverLanded
    report.recoveryObserved = recovered
    report.classification = if changedCharacter then "character-changed-inconclusive"
        elseif not report.jumpObserved then "jump-command-without-observed-lift"
        elseif receiverLanded then "direct-receiver-bypass-observed"
        elseif recovered then "jump-recovered-without-receiver"
        elseif #report.contacts > 0 then "receiver-overlap-without-grounded-landing"
        elseif report.after and report.after.grounded then "jump-landed-away-from-receiver"
        else "bounded-timeout-inconclusive"
    report.bypassPreventedInThisAttempt = report.validAttempt and not receiverLanded
        and (recovered or (report.after ~= nil and report.after.grounded))
    report.stopReason = report.stopReason or "bounded-timeout"
    return report
end

return Probe
