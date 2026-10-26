return function(root)
    assert(root.Name == "SGV2_Phase3_F04" and root:GetAttribute("CandidateId") == "SGV2_Closing_C07")
    local labels = {}
    for _, label in root:GetDescendants() do
        if label:IsA("TextLabel") and label.Parent:IsA("SurfaceGui") then
            local gui = label.Parent
            local part = gui.Parent
            if gui.Name == "GardenLabel" or gui.Name == "CheckpointNumeral" or part.Name == "ShopSign" or part.Name == "StartBoard" or part.Name == "FinishBoard" then
                table.insert(labels, label)
            end
        end
    end
    assert(#labels == 28, "Unexpected minimal-label inventory")
    for _, label in labels do
        -- Roblox disables TextScaled when TextWrapped is set false.
        label.TextWrapped = true
        label.TextScaled = true
    end
    root:SetAttribute("CandidateId", "SGV2_Closing_C08")
    root:SetAttribute("MinimalLabelLayoutRevision", 1)
    return {labels = #labels, geometryChanges = 0}
end
