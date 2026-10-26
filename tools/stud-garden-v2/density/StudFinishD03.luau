return function(root)
    assert(root:GetAttribute("CandidateId")=="SGV2_Density_D02")
    local count=0
    for _,p in root.GardenUnderstory:GetDescendants() do
        if p:IsA("BasePart") and (p.Name=="SteppedEarth" or p.Name=="GroundSeedTray" or p.Name=="TraySoil" or p.Name:find("FoldedLeaf",1,true)) then
            p.Material=Enum.Material.Plastic
            if p:IsA("Part") then p.TopSurface=Enum.SurfaceType.Studs end
            count+=1
        end
    end
    root.GardenUnderstory:SetAttribute("ArtRevision","D03")
    root:SetAttribute("CandidateId","SGV2_Density_D03")
    return {finishedParts=count}
end
