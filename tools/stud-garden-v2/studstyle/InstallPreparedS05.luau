return function(fingerprint)
    assert(game.PlaceId == 85558151074819, "Wrong experience")
    assert(not game:GetService("RunService"):IsRunning(), "Edit mode required")
    local storage = game:GetService("ServerStorage")
    local original = assert(workspace:FindFirstChild("SGV2_Phase3_F04"))
    local prepared = assert(storage:FindFirstChild("SGV2_StudStyle_S01_Prepared"))
    local staged = assert(storage:FindFirstChild("SGV2_StudStyle_S01_Staged"))
    local preview = assert(workspace:FindFirstChild("SGV2_StudStyle_S01_Preview"))
    local recoveryName = "SGV2_R02_Recovery_20261006"
    assert(not storage:FindFirstChild(recoveryName), "Recovery name already exists")
    local function check(root, geometry, content)
        local record = fingerprint(root)
        assert(record.geometry.hash == geometry and record.contentHash == content, "Changed model: " .. root:GetFullName())
        return record
    end
    check(original, "3b36ec9d", "e6789f4c")
    check(prepared, "55dd715a", "e2dacdd1")
    check(staged, "c73ec499", "e994a33c")
    check(preview, "a0df5d3e", "4f4e1d83")
    check(workspace.Lobby, "497b2f58", "1786c65e")
    check(workspace.GrandArcade, "9c7d01a6", "06fea42e")
    check(workspace.ObstacleKit_Palette, "fba04bca", "83b29b3c")
    assert(prepared:GetAttribute("CandidateId") == "SGV2_StudStyle_S05")
    assert(prepared.CourseInfo:GetAttribute("Enabled") == false)
    assert((prepared:GetPivot().Position - Vector3.new(1563, 257, -1053)).Magnitude < .001)
    for _, part in prepared:GetDescendants() do
        assert(not part:IsA("LuaSourceContainer"), "Unexpected script")
        if part:IsA("BasePart") then assert(part.Anchored, "Unanchored part") end
    end
    -- The edited preview has a verified native recovery file before its approved removal.
    local priorPreparedName = prepared.Name
    local ok, result = xpcall(function()
        original.Name = recoveryName
        original.Parent = storage
        prepared.Name = "SGV2_Phase3_F04"
        prepared.Parent = workspace
        return {
            installed = check(prepared, "55dd715a", "e2dacdd1"),
            recovery = check(original, "3b36ec9d", "e6789f4c"),
        }
    end, debug.traceback)
    if not ok then
        prepared.Parent = storage
        prepared.Name = priorPreparedName
        original.Name = "SGV2_Phase3_F04"
        original.Parent = workspace
        error(result)
    end
    staged:Destroy()
    preview:Destroy()
    result.candidate = prepared:GetAttribute("CandidateId")
    result.installedPath = prepared:GetFullName()
    result.recoveryPath = original:GetFullName()
    result.enabled = prepared.CourseInfo:GetAttribute("Enabled")
    result.running = false
    result.temporaryModelsRemoved = not storage:FindFirstChild("SGV2_StudStyle_S01_Staged")
        and not workspace:FindFirstChild("SGV2_StudStyle_S01_Preview")
        and not storage:FindFirstChild("SGV2_StudStyle_S01_Prepared")
    result.unrelated = {
        lobby = check(workspace.Lobby, "497b2f58", "1786c65e"),
        arcade = check(workspace.GrandArcade, "9c7d01a6", "06fea42e"),
        palette = check(workspace.ObstacleKit_Palette, "fba04bca", "83b29b3c"),
    }
    return result
end

