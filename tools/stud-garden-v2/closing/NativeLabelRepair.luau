return function(root)
    assert(root.Name=="SGV2_Phase3_F04" and root:GetAttribute("SGV2Owned"))
    assert(root:GetAttribute("CandidateId")=="SGV2_Closing_C05")
    local route=assert(root:FindFirstChild("ClosingRoute"))
    local labels={}
    for _,v in root:GetDescendants() do
        if v:IsA("TextLabel") and v.Parent.Name=="GardenLabel" then table.insert(labels,v) end
    end
    assert(#labels==33,"Unexpected native garden label count")
    local posts={}
    for _,name in {"StakesChoice","MainCropChoice","TendrilChoice","MainVineChoice","MainThornNotice"} do
        local board=assert(route:FindFirstChild(name))
        local post=assert(route:FindFirstChild(name.."Post"))
        assert(math.abs(post.Size.Y-3.6)<.001 and math.abs((board.CFrame:PointToObjectSpace(post.Position)).Y+2.6)<.001,"Choice post changed")
        table.insert(posts,post)
    end
    for _,v in labels do v.TextScaled=true end
    for _,post in posts do
        post.Size=Vector3.new(post.Size.X,post.Size.Y-1,post.Size.Z)
        post.CFrame=post.CFrame*CFrame.new(0,-.5,0)
    end
    root:SetAttribute("CandidateId","SGV2_Closing_C06")
    root:SetAttribute("NativeLabelRepairRevision",1)
    root:SetAttribute("Phase","Installed local closing candidate; native solo checks in progress")
    root:SetAttribute("RuntimeStatus","Studio selection registered; checkpoint, hazard and critical movement evidence recorded; public selection disabled")
    return {labels=#labels,shortenedSignPosts=#posts}
end
