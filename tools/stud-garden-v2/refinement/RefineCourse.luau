return function(root, Kit, Route, botanicalArt, botanicalSpec, routeSpec)
    assert(root.Name == "SGV2_Phase3_F04" and root:GetAttribute("CandidateId") == "SGV2_Closing_C08")
    assert(not root:FindFirstChild("BotanicalRefinement"), "Refinement is already present")
    local origin = root:GetPivot().Position
    local frame = CFrame.new(origin)
    local V = Vector3.new
    local ledger = {removedMeshes = {}, removedPlantGroups = {}, walls = {}, experts = {}, neonBars = 0}

    for _, name in botanicalSpec.replaceMeshes do
        local part = assert(root.Phase3Art:FindFirstChild(name), "Missing scenery mesh " .. name)
        assert(part:IsA("MeshPart") and not part.CanCollide)
        part:Destroy()
        table.insert(ledger.removedMeshes, name)
    end
    for _, name in botanicalSpec.removeCollisionGroups do
        local group = root.Phase3SceneryCollision:FindFirstChild(name)
        if group then
            table.insert(ledger.removedPlantGroups, {name = name, objects = #group:GetDescendants()})
            group:Destroy()
        end
    end
    root.ClosingScenery.GreatTwistingBeanstalk:Destroy()
    local art = botanicalArt:Clone()
    art.Name = "BotanicalRefinement"
    art.Parent = root
    local solids = Kit.model(root, "BotanicalStemCollision", frame)
    for index, row in botanicalSpec.colliders do
        local part = Kit.rod(solids, string.format("Stem_%03d", index), frame * V(unpack(row.a)), frame * V(unpack(row.b)), row.radius * .96, "leaf", "Blocker")
        part.Transparency = 1
        part.CastShadow = false
        part:SetAttribute("VisiblePlant", row.group)
    end

    for _, part in root:GetDescendants() do
        if part:IsA("BasePart") and part:GetAttribute("HazardType") == "Kill" then
            assert(part.Name == "RedThornCrossbar" and part.CanTouch and part.CanCollide)
            part.Material = Enum.Material.Neon
            ledger.neonBars += 1
        end
    end
    assert(ledger.neonBars == 10, "Kill-bar count changed")

    local boundaries = Kit.model(root, "RefinedGardenBoundaries", frame)
    local function segment(name, a, b, height, planted)
        local length = (b - a).Magnitude
        local right = (b - a).Unit
        local up = Vector3.yAxis
        local cf = CFrame.fromMatrix(frame * ((a + b) / 2), right, up, right:Cross(up))
        local model = Kit.model(boundaries, name, cf)
        local base = -2.8
        local top = height or 26
        Kit.box(model, "ContinuousBoundary", cf, V(0, (base + top) / 2, 0), V(length + .08, top - base, 1.6), planted and "leaf" or "timber", "Blocker")
        Kit.box(model, "TimberFooting", cf, V(0, 1.4, 0), V(length + .12, 8.4, 1.72), "timber")
        Kit.box(model, "JoinedTopCap", cf, V(0, top + .25, 0), V(length + .5, .5, 1.9), "honey")
        local bays = math.max(1, math.ceil(length / 18))
        for i = 0, bays do
            local x = -length / 2 + i * length / bays
            Kit.box(model, "GardenUpright", cf, V(x, (base + top) / 2, 0), V(.7, top - base + .5, 1.94), planted and "timber" or "honey")
        end
        for _, side in {-1, 1} do
            Kit.box(model, "TimberRail", cf, V(0, 4.5, side * .96), V(length, .48, .34), "honey")
            Kit.box(model, "TimberRail", cf, V(0, 15.2, side * .96), V(length, .40, .34), planted and "leaf" or "honey")
            for i = 1, math.max(1, math.floor(length / 24)) do
                local count = math.max(1, math.floor(length / 24))
                local x = (i - (count + 1) / 2) * length / count
                local lower, upper = V(x - 1, 5, side * 1.1), V(x + 1, top - 2, side * 1.1)
                Kit.rod(model, "AttachedClimbingStem", cf * lower, cf * upper, .28, "leaf")
                for level = 1, 2 do
                    local y = 8 + level * 5.5
                    local center = V(x - 1 + (y - 5) / (top - 7) * 2, y, side * 1.16)
                    local tip = center + V(if level == 1 then -4.5 else 4.5, 4, side * .28)
                    local leaf = Kit.model(model, "BroadWallLeaf", cf * CFrame.new(center))
                    local midpoint = (center + tip) / 2
                    Kit.triangle(leaf, "LeafHalf", cf * center, cf * (midpoint + V(0, 1.9, side * .28)), cf * tip, .35, "grass", "Decoration")
                    Kit.triangle(leaf, "LeafHalf", cf * center, cf * tip, cf * (midpoint - V(0, 1.9, -side * .28)), .35, "leaf", "Decoration")
                end
            end
        end
        table.insert(ledger.walls, {name = name, a = {a.X, a.Z}, b = {b.X, b.Z}, height = top, thickness = 1.6})
        return model
    end

    root.ClosingRoute.ForkReturnBoundary:Destroy()
    root.ClosingRoute.EarlyToolFinishBoundary:Destroy()
    segment("ForkReturnBoundary", V(-139, 0, 64), V(-40, 0, 64), 26, false)
    segment("EarlyToolFinishBoundary", V(-32, 0, 90), V(-32, 0, 160), 26, false)
    for _, row in routeSpec.barriers do
        if row.name ~= "image5_fork_wall_east" and row.name ~= "image1_pet_front" then
            for i = 1, #row.spine - 1 do
                local a, b = row.spine[i], row.spine[i + 1]
                segment(row.name .. "_" .. i, V(a[1], 0, a[2]), V(b[1], 0, b[2]), 26, true)
            end
        end
    end

    local pet = Kit.model(boundaries, "PetDisplayFront", frame)
    for i = 0, 13 do
        local z = 13.8 + i * 24.4 / 13
        Kit.box(pet, "PetFencePaling", frame, V(-35.7, 8.9, z), V(.8, 11.4, 1.1), "honey", "Blocker")
    end
    for _, z in {13.8, 26, 38.2} do
        Kit.box(pet, "PetFencePost", frame, V(-35.7, 9.1, z), V(1.0, 11.8, 1.25), "timber", "Blocker")
    end
    for _, y in {5.0, 11.6} do Kit.box(pet, "PetFenceRail", frame, V(-35.7, y, 26), V(1.1, .65, 25.4), "timber", "Blocker") end
    table.insert(ledger.walls, {name = "PetDisplayFront", a = {-35.7, 13.8}, b = {-35.7, 38.2}, height = 15, thickness = 1.1, type = "Paling fence"})

    local stakes = root.Obstacles.G2_CropGarden.PlayableObjects.ExpertStakes
    for _, old in stakes:GetChildren() do old:Destroy() end
    local stakeRows = {{-103, 11.3, -108, 70}, {-112.5, 8.8, -112, 95}, {-121.5, 11.1, -116.5, 70}, {-131, 8.6, -121, 95}, {-140, 10.7, -126, 70}}
    for i, row in stakeRows do
        local cf = frame * CFrame.new(row[1], row[2] - .4, row[3]) * CFrame.Angles(0, math.rad(row[4]), 0)
        local model = Kit.model(stakes, "Stake_" .. i, cf)
        local height = row[2] - .8 + 2.8
        Kit.box(model, "Timber", frame, V(row[1], -2.8 + height / 2, row[3]), V(1.3, height, 1.3), "timber", "Blocker")
        Kit.box(model, "Cap", cf, V(0, 0, 0), V(1.6, .8, 4.8), "gold", "Walk")
        model:SetAttribute("LandingWidth", 1.6)
        model:SetAttribute("LandingLength", 4.8)
        model:SetAttribute("RouteIndex", i)
    end
    local vine = root.Obstacles.G4_LowerVine
    for _, old in vine:GetChildren() do if old.Name:match("^ExpertTendril_%d+$") then old:Destroy() end end
    local vineRows = {{121, 13.65, 12, 78}, {110.5, 11.15, 15, 105}, {100, 13.35, 11, 78}, {89.5, 11.25, 15, 107}, {79, 13.25, 11, 78}, {68.5, 11.35, 15, 105}, {58, 12.75, 12, 80}}
    for i, row in vineRows do
        local cf = frame * CFrame.new(row[1], row[2] - .25, row[3]) * CFrame.Angles(0, math.rad(row[4]), 0)
        local model = Route.racingLeaf(vine, "ExpertTendril_" .. i, cf, 1.7, 7.2)
        model:SetAttribute("LandingWidth", 1.7)
        model:SetAttribute("LandingLength", 7.2)
        model:SetAttribute("RouteIndex", i)
    end
    ledger.experts = {stakes = stakeRows, vines = vineRows, stakeSize = {1.6, .8, 4.8}, leafSize = {1.7, 7.2}}
    local function markers(folder, rows, first, last)
        local prototype = folder:FindFirstChild("Point_001"):Clone()
        for _, old in folder:GetChildren() do old:Destroy() end
        local points = {first}
        for _, row in rows do table.insert(points, {row[1], row[2], row[3]}) end
        table.insert(points, last)
        for i, point in points do
            local marker = prototype:Clone()
            marker.Name = string.format("Point_%03d", i)
            marker.CFrame = frame * CFrame.new(unpack(point))
            marker:SetAttribute("Order", i)
            marker:SetAttribute("SourceR305Path", nil)
            marker.Parent = folder
        end
        prototype:Destroy()
    end
    markers(root.RouteMarkers.G2_Expert, stakeRows, {-89, 7.4, -97}, {-153, 8.24, -126})
    markers(root.RouteMarkers.G4_Expert, vineRows, {144, 11.25, 15}, {31, 10.75, 16})
    root:SetAttribute("CandidateId", "SGV2_Refinement_R01")
    root:SetAttribute("Phase", "Owner refinement; fresh native verification pending")
    root:SetAttribute("BotanicalSourceTriangles", botanicalSpec.sourceTriangles)
    root:SetAttribute("BotanicalFbxSha256", botanicalSpec.fbxSha256)
    root:SetAttribute("GameplayValidated", false)
    return ledger
end
