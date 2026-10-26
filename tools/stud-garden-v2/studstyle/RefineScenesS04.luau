return function(root,Kit)
    assert(root:GetAttribute("CandidateId")=="SGV2_StudStyle_S03")
    local V,C=Vector3.new,CFrame.new
    local tools=root.CreativeGardenBoundaries.ForkToolCaddy
    for _,p in tools:GetChildren() do
        if p.Name=="GripTop" then
            Kit.part(tools,"GripBottomSocket",p.CFrame*C(0,-3.6,0),V(6.1,.85,1.4),"honey","Decoration")
        end
    end
    for _,name in {"GiantBeanPodCradle","FinishGoldenSeed"} do
        for _,p in root.StudGardenCompositions[name]:GetChildren() do
            if p.Name=="PodRaisedSeed" then
                local width=p.Size.X/.56
                p.CFrame*=C(0,0,width*.18)
                p.Size=V(width*.53,width*.53,width*.53)
            elseif p.Name=="PodTip" then
                p.Shape=Enum.PartType.Block
                p.Size*=V(.42,1,.48)
            end
        end
    end
    root:SetAttribute("CandidateId","SGV2_StudStyle_S04")
    root.StudGardenCompositions:SetAttribute("ArtRevision","S04")
    return {revision="S04",joinedToolGrips=4,insetPodSeeds=9}
end
