return function(root,Kit,studBatches)
    assert(root:GetAttribute("CandidateId")=="SGV2_StudStyle_S02")
    local V,C=Vector3.new,CFrame.new
    local garden=root.StudGardenCompositions
    local retired=0
    for _,name in studBatches.meshes do
        local p=root.Phase3Art:FindFirstChild(name)
        if p then
            assert(p:IsA("MeshPart") and not p.CanCollide and not p.CanTouch and not p.CanQuery)
            p.Transparency=1;p.CastShadow=false
            p:SetAttribute("StudOverlayReplacedByNativeGrid",true)
            retired+=1
        end
    end
    do
        local m=garden.CabbageTerrace;local cf=m:GetPivot()
        for _,p in m:GetChildren() do if p.Name=="CabbageCore" then p.Shape=Enum.PartType.Ball end end
        for index,row in {{-8,8,-2,1},{9,6,7,.72}} do
            local s=row[4];local crown=cf*C(row[1],row[2],row[3])
            for n=0,5 do
                local stem=crown*CFrame.Angles(0,n*math.pi/3,0)*C(0,-4*s,1)
                local old=stem*CFrame.Angles(math.rad(-39),0,0)
                local fresh=stem*CFrame.Angles(math.rad(38),0,0)
                for _,p in m:GetChildren() do
                    if p:IsA("BasePart") and (p.Name=="BroadSteppedLeaf" or p.Name=="JoinedLeafRib" or p.Name=="SquareStud") then
                        local lc=old:ToObjectSpace(p.CFrame)
                        if math.abs(lc.Y)<.8 and lc.Z<0 and lc.Z>-16*s-.5 and math.abs(lc.X)<5.1*s then p.CFrame=fresh*lc end
                    end
                end
            end
        end
    end
    for _,name in {"GiantBeanPodCradle","FinishGoldenSeed"} do
        local m=garden[name]
        for _,p in m:GetChildren() do
            if p.Name=="PodBody" then
                local height=p.Size.Y/.9;local width=p.Size.X;local cf=p.CFrame*C(0,-height*.45,0)
                p.Shape=Enum.PartType.Block;p.Size=V(width*.18,p.Size.Y,width*.36)
                local contour={V(0,1,0),V(-width*.44,height*.20,0),V(-width*.55,height*.47,0),V(-width*.38,height*.79,0),V(0,height*1.06,0),V(width*.40,height*.79,0),V(width*.5,height*.48,0),V(width*.4,height*.20,0)}
                local center=V(0,height*.51,-width*.18)
                for i=1,#contour do
                    Kit.triangle(m,"JoinedPodShell",cf*contour[i],cf*contour[i%#contour+1],cf*center,.5,if name=="FinishGoldenSeed" then "gold" else "grass","Decoration")
                end
            elseif p.Name=="PodShoulder" then p.Shape=Enum.PartType.Block;p.Size*=V(.32,1,.45)
            end
        end
    end
    do
        local m=garden.GiantTurnipHarvest;local cf=m:GetPivot()
        for _,p in m:GetChildren() do
            if p:IsA("BasePart") and p.Name~="GroundedEarth" and p.Name~="StuddedEarthCap" and p.Name~="TimberBedEdge" then p.CFrame-=V(0,2,0) end
            if p.Name=="TurnipShoulder" then p.Size*=V(.48,1,1) end
        end
    end
    do
        local m=garden.CentralNurseryPlanter;local cf=m:GetPivot()
        local rows={{-5,17,3,-25},{5,21,0,60},{-1,26,-5,140}}
        for i,row in rows do
            local old=cf*C(row[1],row[2],row[3])*CFrame.Angles(math.rad(-12),math.rad(row[4]),math.rad(6))
            local fresh=cf*C(row[1],row[2],row[3])*CFrame.Angles(math.rad(12+i*5),math.rad(row[4]),math.rad(6))
            for _,p in m:GetChildren() do
                if p:IsA("BasePart") and (p.Name=="BroadSteppedLeaf" or p.Name=="JoinedLeafRib" or p.Name=="SquareStud") then
                    local lc=old:ToObjectSpace(p.CFrame)
                    if math.abs(lc.Y)<.8 and lc.Z<0 and lc.Z>-23.2 and math.abs(lc.X)<6.2 then p.CFrame=fresh*lc end
                end
            end
        end
    end
    root:SetAttribute("CandidateId","SGV2_StudStyle_S03")
    garden:SetAttribute("ArtRevision","S03")
    return {revision="S03",retiredPureCosmeticStudBatches=retired,retainedMeshSources=true}
end
