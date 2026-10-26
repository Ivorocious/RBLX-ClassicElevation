local Test = {}
local RunService = game:GetService("RunService")

function Test.Run(template)
    assert(RunService:IsStudio() and RunService:IsServer(), "Studio server Play required")
    local player = assert(game.Players:GetPlayers()[1], "No player")
    local character = assert(player.Character, "No avatar")
    local root, humanoid = character.HumanoidRootPart, character.Humanoid
    assert(humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2) < .01)
    assert(math.abs(workspace.Gravity-196.2) < .01)
    local saved, anchored, autoRotate = character:GetPivot(), root.Anchored, humanoid.AutoRotate
    local originalPivot = template:GetPivot()
    local fixture = template:Clone()
    fixture.Name = "__C14SlalomFixture"
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
fixture:PivotTo(CFrame.new(8000,100,0))
    fixture.Parent = workspace
    local function world(point)
        return fixture:GetPivot():PointToWorldSpace(originalPivot:PointToObjectSpace(point))
    end
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
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Include
    ray.FilterDescendantsInstances = {fixture}
    ray.RespectCanCollide = true
    local movement = Vector3.zero
    local connection, monitor
    local monitorFailure
    local records, measuredParts = {}, {}
    local maxWidth, maxDepth = 0, 0
    local maxLeft, maxRight, maxFront, maxBack = 0, 0, 0, 0
    local deckCenter = world(Vector3.new(3665,82,-154))
    local deckMin, deckMax = deckCenter.X-6, deckCenter.X+6
    local minDeckClearance = math.huge
    local activeRecord, activePanel
    local function bounds(part)
        local half, cf = part.Size/2, part.CFrame
        local extent = Vector3.new(
            math.abs(cf.XVector.X)*half.X+math.abs(cf.YVector.X)*half.Y+math.abs(cf.ZVector.X)*half.Z,
            math.abs(cf.XVector.Y)*half.X+math.abs(cf.YVector.Y)*half.Y+math.abs(cf.ZVector.Y)*half.Z,
            math.abs(cf.XVector.Z)*half.X+math.abs(cf.YVector.Z)*half.Y+math.abs(cf.ZVector.Z)*half.Z)
        return part.Position-extent, part.Position+extent
    end
    local function bodyBounds()
        local low, high = Vector3.new(math.huge,math.huge,math.huge), Vector3.new(-math.huge,-math.huge,-math.huge)
        local count = 0
        for _, part in character:GetChildren() do
            if part:IsA("BasePart") and part ~= root and part.Transparency < 1 then
                local a,b = bounds(part)
                low = Vector3.new(math.min(low.X,a.X),math.min(low.Y,a.Y),math.min(low.Z,a.Z))
                high = Vector3.new(math.max(high.X,b.X),math.max(high.Y,b.Y),math.max(high.Z,b.Z))
                measuredParts[part.Name] = true
                count += 1
            end
        end
        assert(count >= 3, "Visible avatar body parts missing")
        maxWidth, maxDepth = math.max(maxWidth,high.X-low.X), math.max(maxDepth,high.Z-low.Z)
        maxLeft, maxRight = math.max(maxLeft,root.Position.X-low.X), math.max(maxRight,high.X-root.Position.X)
        maxFront, maxBack = math.max(maxFront,high.Z-root.Position.Z), math.max(maxBack,root.Position.Z-low.Z)
        return low,high
    end
    local function boxSeparation(a,b)
        local aAxes = {a.CFrame.XVector,a.CFrame.YVector,a.CFrame.ZVector}
        local bAxes = {b.CFrame.XVector,b.CFrame.YVector,b.CFrame.ZVector}
        local aHalf,bHalf = {a.Size.X/2,a.Size.Y/2,a.Size.Z/2},{b.Size.X/2,b.Size.Y/2,b.Size.Z/2}
        local axes = {aAxes[1],aAxes[2],aAxes[3],bAxes[1],bAxes[2],bAxes[3]}
        for _,aa in aAxes do for _,bb in bAxes do
            local cross = aa:Cross(bb)
            if cross.Magnitude > .0001 then table.insert(axes,cross.Unit) end
        end end
        local separation = -math.huge
        for _,axis in axes do
            local radiusA,radiusB = 0,0
            for i = 1,3 do
                radiusA += math.abs(axis:Dot(aAxes[i]))*aHalf[i]
                radiusB += math.abs(axis:Dot(bAxes[i]))*bHalf[i]
            end
            separation = math.max(separation,math.abs((a.Position-b.Position):Dot(axis))-radiusA-radiusB)
        end
        return separation
    end
    local function supported()
        if humanoid.FloorMaterial == Enum.Material.Air then return nil end
        local hit = workspace:Raycast(root.Position,Vector3.new(0,-(humanoid.HipHeight+root.Size.Y/2+.4),0),ray)
        return hit and hit.Instance
    end
    local function healthy()
        assert(not monitorFailure, monitorFailure)
        assert(recoveries == 0, "Hazard contact recorded")
        assert(humanoid.Health > 0, "Avatar died")
        assert(humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight-7.2) < .01)
    end
    local function waitUntil(predicate, timeout, message)
        local deadline = os.clock()+timeout
        repeat
            healthy()
            if predicate() then return end
            RunService.Heartbeat:Wait()
        until os.clock() > deadline
        error(message)
    end
    local function walkTo(target, timeout)
        local deadline = os.clock()+timeout
        repeat
            healthy()
            local flat = Vector3.new(target.X-root.Position.X,0,target.Z-root.Position.Z)
            if flat.Magnitude <= .06 then break end
            movement = flat.Unit*math.min(1,flat.Magnitude/.8)
            RunService.Heartbeat:Wait()
        until os.clock() > deadline
        movement = Vector3.zero
        assert((Vector3.new(root.Position.X,0,root.Position.Z)-Vector3.new(target.X,0,target.Z)).Magnitude < .3, "Walking waypoint not reached")
        waitUntil(function() return supported() ~= nil end,.4,"Walking waypoint lost floor support")
    end
    local raceConfig = require(game.ReplicatedStorage.Config.RaceConfig)
    local priorStaging = raceConfig.StagingTeleportEnabled
    local started = os.clock()
    local ok, failure = xpcall(function()
        raceConfig.StagingTeleportEnabled = false
        local panels = {}
        for i = 0,4 do
            local model = fixture.Obstacles.C14Routes.DepotSlalom["C14_DepotSlalom_"..i]
            for _, part in model:GetDescendants() do
                if part:IsA("BasePart") and part:GetAttribute("HazardType") == "Kill" then
                    assert(not panels[i+1], "Expected one moving panel per gate")
                    assert(part:GetAttribute("KitMotion") == "Slide", "Gate is not sliding")
                    panels[i+1] = part
                end
            end
            assert(panels[i+1], "Moving panel missing")
        end
        root.Anchored = false
        root:SetNetworkOwner(nil)
        humanoid.AutoRotate = false
        local start = world(Vector3.new(3665,82,-214))+Vector3.new(0,humanoid.HipHeight+root.Size.Y/2+.15,0)
        character:PivotTo(CFrame.lookAt(start,start+Vector3.zAxis))
        connection = RunService.PreSimulation:Connect(function()
            humanoid:Move(movement,false)
            humanoid.Jump = false
        end)
        service.Start()
        waitUntil(function() return supported() ~= nil end,2,"Depot start unsupported")
        bodyBounds()
        monitor = RunService.PostSimulation:Connect(function()
            local low,high = bodyBounds()
            minDeckClearance = math.min(minDeckClearance,low.X-deckMin,deckMax-high.X)
            if minDeckClearance < -.02 then monitorFailure = "Visible body moved past deck edge" end
            if activePanel and activeRecord then
                local a,b = bounds(activePanel)
                for _,part in character:GetChildren() do
                    if part:IsA("BasePart") and part ~= root and part.Transparency < 1 then
                        local limbLow,limbHigh = bounds(part)
                        if limbHigh.Z >= a.Z and limbLow.Z <= b.Z and limbHigh.Y >= a.Y and limbLow.Y <= b.Y then
                            local clearance = boxSeparation(part,activePanel)
                            activeRecord.minPanelClearance = math.min(activeRecord.minPanelClearance or math.huge,clearance)
                            if clearance < -.01 then monitorFailure = "Visible limb overlaps moving panel: "..part.Name end
                        end
                    end
                end
            end
        end)
        for index,panel in panels do
            local low,high = bounds(panel)
            local side = if index%2 == 1 then "Left" else "Right"
            local record = {name=panel.Parent.Name,side=side,phase="Approach",startedSeconds=os.clock()-started}
            table.insert(records,record)
            activePanel,activeRecord = panel,record
            local margin = .28
            local waitingZ = low.Z-math.max(4.25,maxFront+1.25)
            walkTo(Vector3.new(root.Position.X,root.Position.Y,waitingZ),3)
            -- Forward and lateral walking animate the limbs before choosing the final lane.
            local laneX
            for _ = 1,3 do
                bodyBounds()
                laneX = if side == "Left" then deckMin+maxLeft+margin else deckMax-maxRight-margin
                walkTo(Vector3.new(laneX,root.Position.Y,waitingZ),2)
            end
            record.waitingZ,record.laneX = waitingZ,laneX
            record.phase = "WaitingForOpening"
            local waited = os.clock()
            local previousX,previousTime = panel.Position.X,os.clock()
            local velocity = 0
            local period = panel:GetAttribute("MotionPeriod")
            local distance = panel:GetAttribute("MotionDistance")
            assert(typeof(period)=="number" and typeof(distance)=="number" and distance > 0)
            local baselineGap = 6-(high.X-low.X)/2
            local departureGap
            waitUntil(function()
                local a,b = bounds(panel)
                local now = os.clock()
                if now-previousTime > .025 then
                    velocity = (panel.Position.X-previousX)/(now-previousTime)
                    previousX,previousTime = panel.Position.X,now
                end
                local gap = if side == "Left" then a.X-deckMin else deckMax-b.X
                local widening = if side == "Left" then velocity > .08 else velocity < -.08
                local desired = maxLeft+maxRight+2*margin+.08
                local crossingSeconds = (b.Z+maxBack+.65-root.Position.Z)/16+.2
                local phase = math.asin(math.clamp((gap-baselineGap)/distance,-1,1))
                local futureGap = baselineGap+distance*math.sin(phase+2*math.pi/period*crossingSeconds)
                record.lastGap,record.bodyWidth,record.predictedEndGap = gap,maxLeft+maxRight,futureGap
                if widening and gap >= desired and futureGap >= desired then
                    departureGap = gap
                    record.crossingBudgetSeconds = crossingSeconds
                    return true
                end
                return false
            end,period*2+1,"No opening fits the full visible avatar body")
            record.waitSeconds,record.departureGap = os.clock()-waited,departureGap
            record.phase = "Crossing"
            local crossingStarted = os.clock()
            local _,panelHigh = bounds(panel)
            walkTo(Vector3.new(laneX,root.Position.Y,panelHigh.Z+maxBack+.65),2)
            healthy()
            local bodyLow = bodyBounds()
            assert(bodyLow.Z > panelHigh.Z, "Avatar body has not cleared the panel")
            assert(record.minPanelClearance and record.minPanelClearance >= 0, "Missing positive full-body panel clearance")
            record.crossingSeconds,record.recoveries,record.phase = os.clock()-crossingStarted,recoveries,"Passed"
        end
        activePanel,activeRecord = nil,nil
        local finish = world(Vector3.new(3665,82,-90))
        walkTo(Vector3.new(root.Position.X,root.Position.Y,finish.Z),3)
        walkTo(Vector3.new(finish.X,root.Position.Y,finish.Z),2)
        local support = supported()
        assert(support and support:IsDescendantOf(fixture.Obstacles.C14Routes.DepotExit.C14_DepotCheckpoint), "Did not finish on checkpoint deck")
        healthy()
    end,debug.traceback)
    raceConfig.StagingTeleportEnabled = priorStaging
    if connection then connection:Disconnect() end
    if monitor then monitor:Disconnect() end
    current = nil
    service.BindActiveCourse()
    humanoid:Move(Vector3.zero,false)
    humanoid.Jump = false
    humanoid.AutoRotate = autoRotate
    character:PivotTo(saved)
    root.Anchored = anchored
    if not anchored then root:SetNetworkOwnershipAuto() end
    fixture:Destroy()
    source:Destroy()
    local partNames = {}
    for name in measuredParts do table.insert(partNames,name) end
    table.sort(partNames)
    return {passed=ok,failure=if ok then nil else failure,records=records,recoveries=recoveries,
        elapsedSeconds=os.clock()-started,maxVisibleBodyWidth=maxWidth,maxVisibleBodyDepth=maxDepth,bodyParts=partNames,
        envelope={left=maxLeft,right=maxRight,forward=maxFront,backward=maxBack},
        minDeckEdgeClearance=if minDeckClearance < math.huge then minDeckClearance else nil,
        physics={walkSpeed=humanoid.WalkSpeed,jumpHeight=humanoid.JumpHeight,gravity=workspace.Gravity},
        method="Actual forward-facing avatar, visible direct-body bounds, five alternating live openings, active hazard detection; start-only teleport and normal movement inputs",
        limitation="One avatar and scripted timing; accessories excluded consistently with the active hazard service"}
end
return Test
