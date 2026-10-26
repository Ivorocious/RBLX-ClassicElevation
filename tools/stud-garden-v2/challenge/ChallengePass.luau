return function(root)
    assert(game.PlaceId==85558151074819 and not game.RunService:IsRunning())
    assert(root:GetAttribute("CandidateId")=="SGV2_FinalPass_F01")
    assert(not root:FindFirstChild("ChallengeHazards"))
    local C,V=CFrame.new,Vector3.new
    local frame=root:GetPivot()
    local report={timing={},hazards={},surfaceFixes={},baselineParts=0}
    for _,p in root:GetDescendants() do if p:IsA("BasePart") then report.baselineParts+=1 end end
    local function preserve(p)
        if p:GetAttribute("SGV2C01OriginalSize") then return end
        p:SetAttribute("SGV2C01OriginalSize",p.Size)
        p:SetAttribute("SGV2C01OriginalFrame",p.CFrame)
        table.insert(report.surfaceFixes,p:GetFullName():sub(#root:GetFullName()+2))
    end
    local function resize(p,size,shift)
        preserve(p);p.Size=size;p.CFrame=p.CFrame*(shift or CFrame.identity)
    end
    game.ChangeHistoryService:SetWaypoint("Before Stud Garden challenge and surface fixes")
    for _,row in {{"H1_Sprinkler",5},{"H2_Fruit",5.2}} do
        local h=root[row[1]]
        local before=h:GetAttribute("ClearSeconds")
        h:SetAttribute("C01PreviousClearSeconds",before)
        h:SetAttribute("ClearSeconds",row[2])
        table.insert(report.timing,{name=h.Name,before=before,after=row[2],entrySeconds=row[2]-h:GetAttribute("MinimumEntrySeconds")})
    end

    local group=Instance.new("Model");group.Name="ChallengeHazards";group:PivotTo(frame);group.Parent=root
    local template=root.ClosingRoute.G1_SeedBenchThorns.RedThornCrossbar
    local function hazard(name,pos,size,yaw,kind,axis,period,distance,angle)
        local m=Instance.new("Model");m.Name=name;m.Parent=group
        local p=template:Clone();p.Name="RedThornCrossbar"
        for key in p:GetAttributes() do p:SetAttribute(key,nil) end
        p:SetAttribute("Role","Hazard");p:SetAttribute("HazardType","Kill")
        p.Size=size;p.CFrame=frame*C(pos)*CFrame.Angles(0,math.rad(yaw),0);p.Parent=m
        if kind then
            p:SetAttribute("KitMotion",kind);p:SetAttribute("MotionAxis",axis)
            p:SetAttribute("MotionPeriod",period);p:SetAttribute("MotionDistance",distance or 0);p:SetAttribute("MotionAngle",angle or 0)
        end
        for i=1,4 do
            local stripe=Instance.new("Part");stripe.Name="WarningBand_"..i
            stripe.Anchored=true;stripe.CanCollide=false;stripe.CanTouch=false;stripe.CanQuery=false
            stripe.Material=Enum.Material.Plastic;stripe.Color=Color3.fromRGB(255,239,201)
            stripe.Size=V(.38,.10,size.Z+.06)
            stripe.CFrame=p.CFrame*C((i-2.5)*size.X/4,size.Y/2+.07,0)
            stripe:SetAttribute("Role","Decoration")
            if kind then stripe:SetAttribute("MotionFollows",p.Name) end
            stripe.Parent=m
        end
        table.insert(report.hazards,{name=name,kind=kind or "Staggered hurdle",position={pos.X,pos.Y,pos.Z}})
    end
    hazard("EntryHurdle_Left",V(-66,7.15,53),V(9,1.5,1.5),0)
    hazard("EntryHurdle_Right",V(-60,7.15,46.5),V(9,1.5,1.5),0)
    hazard("ToolBenchSlider",V(-147,9.3,-153),V(14,1.8,1.6),90,"Slide","Z",7,2)
    hazard("SecondWagonSpinner",V(125,12.04,98),V(14,1.8,1.6),90,"Spin","Y",12)
    hazard("LongWagonSwing",V(149,9.14,147),V(14,1.8,1.6),0,"Swing","Y",8,0,32)
    hazard("FestivalRiser",V(154,9.54,122),V(13,1.5,1.6),0,"Slide","Y",6,1.1)

    local foundation=root.ClosingRoute.RaisedSeedShopFloor.ShopFoundation
    resize(foundation,foundation.Size-V(.16,.12,.16),C(0,-.06,0))
    for _,p in root.GardenGiants:GetDescendants() do
        if p:IsA("BasePart") and p.Name=="Brow" then preserve(p);p.CFrame+=V(0,.09,0) end
        if p:IsA("BasePart") and p.Name=="BunnyBank" and p.Size.Y>10 then
            resize(p,p.Size-V(0,.12,0),C(0,-.06,0))
        end
    end
    for _,p in root:GetDescendants() do
        if not p:IsA("Part") then continue end
        if p.Name=="Vein" and p.Parent:FindFirstChild("Midrib") then
            preserve(p);p.CFrame*=C(0,.035,0)
        elseif p:IsDescendantOf(root.ClosingScenery) and p.Name=="CornerPost" then
            resize(p,p.Size-V(.12,.10,.12),C(0,-.05,0))
        elseif p:IsDescendantOf(root.ClosingScenery) and p.Name=="EndSlat" then
            resize(p,p.Size-V(.16,.035,0),C(0,.022,0))
        elseif p.Name=="GroundSeedTray" and p:IsDescendantOf(root.GardenUnderstory) then
            resize(p,p.Size-V(.14,0,.14))
        end
    end
    root:SetAttribute("CandidateId","SGV2_Challenge_C01")
    root:SetAttribute("CandidateRequiresVerification",true)
    root:SetAttribute("Phase","Challenge tuning installed; focused checks pending")
    root:SetAttribute("RuntimeStatus","C01 tighter entry windows and six added hazards; focused checks pending")
    game.ChangeHistoryService:SetWaypoint("Stud Garden challenge and surface fixes")
    return report
end
