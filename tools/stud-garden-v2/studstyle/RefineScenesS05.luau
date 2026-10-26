return function(root)
    assert(root:GetAttribute("CandidateId")=="SGV2_StudStyle_S04")
    local m=root.StudGardenCompositions.GiantTurnipHarvest
    local adjusted=0
    for _,p in m:GetChildren() do
        if p:IsA("BasePart") and (p.Name=="SquareStud" or p.Name=="LeafCrown") then
            assert(not p.CanCollide and not p.CanTouch and not p.CanQuery)
            p.CFrame-=Vector3.new(0,if p.Name=="SquareStud" then 1.55 else .65,0)
            adjusted+=1
        end
    end
    root:SetAttribute("CandidateId","SGV2_StudStyle_S05")
    root.StudGardenCompositions:SetAttribute("ArtRevision","S05")
    return {revision="S05",turnipDecorationsSeated=adjusted}
end
