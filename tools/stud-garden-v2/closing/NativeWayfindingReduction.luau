return function(root, Kit)
    assert(root.Name == "SGV2_Phase3_F04" and root:GetAttribute("SGV2Owned"))
    assert(root:GetAttribute("CandidateId") == "SGV2_Closing_C06")
    local route = assert(root:FindFirstChild("ClosingRoute"))
    local frame = root:GetPivot()
    local mergeCues = {}
    for _, index in {8, 9} do
        local stem = assert(route[string.format("CheckpointGate_%02d", index)]:FindFirstChild("RouteChevronStem"))
        mergeCues[index] = {position = stem.Position + stem.CFrame.LookVector * 1.19, direction = stem.CFrame.LookVector}
    end
    local function path(name)
        local node = root
        for segment in name:gmatch("[^.]+") do node = assert(node:FindFirstChild(segment), name) end
        return node
    end
    local removedParts, removedBoards, oldArrows = 0, 0, 0
    local function remove(object)
        if object:IsA("BasePart") then removedParts += 1 end
        for _, child in object:GetDescendants() do
            if child:IsA("BasePart") then removedParts += 1 end
        end
        object:Destroy()
    end
    local function text(part, words)
        for _, child in part:GetDescendants() do
            if child:IsA("TextLabel") then
                child.Text = words
                child.TextWrapped = true
                child.TextScaled = true
            end
        end
    end
    for index = 1, 9 do
        local gate = assert(route:FindFirstChild(string.format("CheckpointGate_%02d", index)))
        local board = assert(gate:FindFirstChild("CheckpointNumber"))
        assert(not board.CanCollide)
        remove(board)
        removedBoards += 1
        for _, child in gate:GetChildren() do
            if child.Name == "NumberBoardMount" then remove(child) end
        end
        local lintel = assert(gate:FindFirstChild("RaisedLintel"))
        for _, face in {Enum.NormalId.Front, Enum.NormalId.Back} do
            local gui = Instance.new("SurfaceGui")
            gui.Name = "CheckpointNumeral"
            gui.Face = face
            gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
            gui.PixelsPerStud = 48
            gui.LightInfluence = .25
            local label = Instance.new("TextLabel")
            label.AnchorPoint = Vector2.new(.5, .5)
            label.Position = UDim2.fromScale(.5, .5)
            label.Size = UDim2.fromOffset(154, 60)
            label.BackgroundTransparency = 1
            label.Text = string.format("%02d", index)
            label.TextColor3 = Kit.colors.cream
            label.TextWrapped = true
            label.TextScaled = true
            label.Font = Enum.Font.GothamBold
            label.Parent = gui
            gui.Parent = lintel
        end
        gate:SetAttribute("StatePresentation", "Small lintel numeral; personal claimed state remains in existing HUD")
    end
    for _, name in {
        "Obstacles.G1_SeedShop.EntrySign",
        "Obstacles.G2_CropGarden.PlantedContext.SampleEntry",
        "Obstacles.G2_CropGarden.PlantedContext.MainChoice",
        "Obstacles.G2_ToolGardenExit.GroveDirection",
        "Obstacles.G3_CandyGrove.GroveEntry",
        "Obstacles.G4_LowerVine.MainVineChoice",
        "Obstacles.G4_LowerVine.FestivalDirection",
        "H1_Sprinkler.WarningSign",
        "H2_Fruit.WarningSign",
    } do
        local model = path(name)
        assert(model:IsA("Model") and model:FindFirstChild("Board"))
        remove(model)
        removedBoards += 1
    end
    for _, name in {"MainCropChoice", "MainVineChoice", "G1ThornWarning"} do
        remove(assert(route:FindFirstChild(name)))
        removedBoards += 1
        local post = route:FindFirstChild(name .. "Post")
        if post then remove(post) end
    end
    remove(path("ClosingRoute.RaisedSeedShopFloor.SuppliesFrontage"))
    removedBoards += 1
    for _, name in {"PumpkinStall", "AppleStall", "FlowerStall"} do
        remove(path("ClosingScenery." .. name .. ".ProduceSign"))
        removedBoards += 1
    end
    for _, name in {"StakesChoice", "TendrilChoice", "MainThornNotice"} do
        local board = assert(route:FindFirstChild(name))
        local post = assert(route:FindFirstChild(name .. "Post"))
        if name == "MainThornNotice" then
            board.CFrame += Vector3.new(0, 0, 9)
            post.CFrame += Vector3.new(0, 0, 9)
        end
        board.Size = Vector3.new(if name == "MainThornNotice" then 4 else 4.8, 1.35, .24)
        board.CFrame = CFrame.new(board.Position.X, post.Position.Y + post.Size.Y / 2 + board.Size.Y / 2, board.Position.Z) * board.CFrame.Rotation
        text(board, if name == "MainThornNotice" then "THORNS" else "EXPERT")
    end
    local shop = path("Obstacles.G1_SeedShop.SeedShopLandmark")
    local shopSign = assert(shop:FindFirstChild("ShopSign"))
    shopSign.Size = Vector3.new(8, 1.8, shopSign.Size.Z)
    text(shopSign, "SEEDS")
    for _, child in shop:GetChildren() do
        if child.Name == "SignHanger" then
            local relative = shopSign.CFrame:PointToObjectSpace(child.Position)
            child.CFrame = shopSign.CFrame * CFrame.new(if relative.X < 0 then -3 else 3, relative.Y, relative.Z) * shopSign.CFrame.Rotation:Inverse() * child.CFrame.Rotation
        end
    end
    local start = path("Decoration.GardenStartLine.StartBoard")
    local finish = path("Obstacles.G5_HarvestFestival.HarvestFinish.FinishBoard")
    start.Size = Vector3.new(10, 2.6, start.Size.Z)
    finish.Size = Vector3.new(10, 2.6, finish.Size.Z)
    text(start, "START")
    text(finish, "FINISH")
    local arrows = {}
    for _, child in root:GetDescendants() do
        if child:IsA("BasePart") and (child.Name == "OnwardStem" or child.Name == "OnwardTip_1" or child.Name == "OnwardTip_2" or child.Name == "RouteChevronStem" or child.Name == "RouteChevronHead_1" or child.Name == "RouteChevronHead_2") then
            assert(not child.CanCollide and not child.CanTouch, "Arrow unexpectedly affects gameplay")
            if child.Name == "OnwardStem" or child.Name == "RouteChevronStem" then oldArrows += 1 end
            table.insert(arrows, child)
        end
    end
    assert(oldArrows == 45 and #arrows == 135, "Arrow inventory changed")
    for _, child in arrows do remove(child) end
    local markers = Kit.model(route, "DecisionMarkers", frame)
    local V = Vector3.new
    for _, row in {
        {-88, 7.5, -94, V(-1, 0, 1), "cream"},
        {-89, 7.5, -102, V(-1, 0, -1), "gold"},
        {-149, 8.36, -135, V(0, 0, -1), "cream"},
        {145, 11.38, 21, V(0, 0, 1), "cream"},
        {137, 11.38, 11, V(-1, 0, 0), "gold"},
        {25, 6.98, 147, V(0, 0, -1), "cream"},
    } do
        Kit.arrow(markers, frame * V(row[1], row[2], row[3]), row[4], 1.2, row[5])
    end
    for _, index in {8, 9} do
        Kit.arrow(markers, mergeCues[index].position, mergeCues[index].direction, 1.2, "cream")
    end
    root:SetAttribute("CandidateId", "SGV2_Closing_C08")
    root:SetAttribute("WayfindingReductionRevision", 1)
    root:SetAttribute("MinimalLabelLayoutRevision", 1)
    root:SetAttribute("Phase", "Installed local closing candidate; restrained wayfinding review in progress")
    return {removedParts = removedParts, removedBoards = removedBoards, oldArrows = oldArrows, newArrows = 8, checkpointNumerals = 9, expertMarkers = 2, thornMarkers = 1}
end
