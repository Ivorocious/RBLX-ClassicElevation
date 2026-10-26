return function(root,Kit,avatarSource)
    assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning())
    assert(root:GetAttribute("CandidateId")=="SGV2_Density_D03")
    assert(not root:FindFirstChild("GardenGiants"))
    local V,C,A=Vector3.new,CFrame.new,CFrame.Angles
    local frame=C(root:GetPivot().Position)
    local report={workyard=0,moving={},giants={}}
    local function box(m,n,f,pos,size,color)
        local p=Kit.box(m,n,f,pos,size,color,"Decoration")
        p.Material=Enum.Material.Plastic;p.TopSurface=Enum.SurfaceType.Studs
        return p
    end
    local function label(p,words,color)
        for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do Kit.label(p,words,color,face) end
    end
    local yard=root.GardenUnderstory.GardenerWorkyard
    local yf=yard:GetPivot()
    local cf=yf*C(-3,0,-12)
    local sacks,folds,seeds={},{},{}
    for _,p in yard:GetChildren() do
        if p.Name=="FoldedSeedSack" then table.insert(sacks,p)
        elseif p.Name=="SackFold" then table.insert(folds,p)
        elseif p.Name=="LargeSupportedSeed" then table.insert(seeds,p) end
    end
    assert(#sacks==3 and #folds==2)
    table.sort(sacks,function(a,b)return a.Position.Y<b.Position.Y end)
    local walls={{V(-6,3.8,0),V(.8,8.2,11)},{V(6,3.8,0),V(.8,8.2,11)},{V(0,3.8,-5.1),V(11.3,8.2,.8)}}
    for i,p in sacks do p.Shape=Enum.PartType.Block;p.CFrame=cf*C(walls[i][1]);p.Size=walls[i][2];p.Color=Kit.colors.timber;p.Material=Enum.Material.Plastic;p.TopSurface=Enum.SurfaceType.Studs end
    for i,p in folds do p.CFrame=cf*C(0,if i==1 then 3.8 else -.5,if i==1 then 5.1 else 0);p.Size=if i==1 then V(11.3,8.2,.8) else V(11.3,.8,9.4);p.Color=Kit.colors.honey end
    box(yard,"SeedCrateDarkInterior",cf,V(0,5.5,0),V(11.1,.5,9.3),"soil")
    for _,s in {-1,1} do
        for _,y in {1.1,6.5} do box(yard,"CrateSlat",cf,V(0,y,s*5.55),V(12.5,.5,.25),"cream") end
        for _,x in {-5.5,5.5} do box(yard,"CrateCornerStrap",cf,V(x,3.7,s*5.55),V(.45,8.3,.28),"edge") end
        box(yard,"CrateCarryGrip",cf,V(s*6.43,6.2,0),V(.2,1,3.2),"dark")
    end
    table.sort(seeds,function(a,b)return a.Position.Y>b.Position.Y end)
    for i,p in seeds do
        if i<=3 then p.CFrame=cf*C((i-2)*3.1,6.45,if i==2 then -1.5 else 1.6)*A(0,i*.7,.12);p.Size=V(4.2,1.6,2.6)
        else p.Size=V(4.2,1.3,2.6);local lp=yf:PointToObjectSpace(p.Position);p.CFrame=yf*C(lp.X,.92,lp.Z)*p.CFrame.Rotation end
        p.Color=Color3.fromRGB(212,174,94)
    end
    local paper=yard.FoldedSeedPaper
    paper.Size=V(8,7,.4);paper.CFrame=cf*C(0,4.1,5.65);paper.Color=Kit.colors.cream
    label(paper,"GARDEN\nSEEDS","leaf")
    local fold=yard.SeedPaperFold;fold.Size=V(8.5,.55,.5);fold.CFrame=cf*C(0,7.8,5.68);fold.Color=Kit.colors.leaf
    local tray=yf*C(1,0,7)*A(0,.16,0)
    for _,x in {-2.8,2.8} do box(yard,"SeedTrayDivider",tray,V(x,.15,0),V(.3,.7,17.9),"honey") end
    for _,z in {-3,3} do box(yard,"SeedTrayDivider",tray,V(0,.15,z),V(16.8,.7,.3),"honey") end
    for _,p in yard:GetDescendants() do if p:IsA("BasePart") then report.workyard+=1 end end

    local giants=Kit.model(root,"GardenGiants",frame)
    local avatar=avatarSource:Clone();avatar.Name="GiantIvor"
    -- Preserve the downloaded source; the displayed sculpture has no running scripts.
    for _,v in avatar:GetDescendants() do
        if v:IsA("LuaSourceContainer") then v.Parent=nil
        elseif v:IsA("BasePart") then v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false;v.CastShadow=false;v:SetAttribute("Role","Decoration") end
    end
    local humanoid=avatar:FindFirstChildOfClass("Humanoid")
    humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
    humanoid.EvaluateStateMachine=false
    avatar:ScaleTo(38)
    avatar:PivotTo(frame*C(-40,114,-247)*A(0,math.pi,0));avatar.Parent=giants
    for _,p in avatar:GetDescendants() do if p:IsA("BasePart") then p.CanCollide=false;p.CanTouch=false;p.CanQuery=false end end
    avatar:SetAttribute("OwnerUserId",86069177);avatar:SetAttribute("OwnerUsername","ThisisIvorrovI")
    avatar:SetAttribute("FrozenAppearanceDate","2026-10-06")
    report.giants.avatar={height=avatar:GetExtentsSize().Y,userId=86069177}

    local pet=Kit.model(giants,"GiantGardenBunny",frame*C(-226,-1,-40)*A(0,math.rad(-100),0))
    local pf=pet:GetPivot()
    local fur=Color3.fromRGB(229,212,177)
    local light=Color3.fromRGB(255,237,204)
    local rose=Color3.fromRGB(218,149,147)
    local function b(n,pos,size,col,rot)return box(pet,n,pf*(rot or CFrame.identity),pos,size,col)end
    b("Body",V(0,28,7),V(48,48,43),fur)
    b("Chest",V(0,30,-15),V(35,33,8),light)
    b("Head",V(0,63,-3),V(47,39,35),fur)
    b("Brow",V(0,80,-4),V(40,5,29),light)
    b("Muzzle",V(0,53,-23),V(28,15,12),light)
    b("Nose",V(0,58,-30),V(7,4.8,3.5),rose)
    b("Mouth",V(0,52,-29.5),V(2,4,.4),"dark")
    b("FrontTeeth",V(0,48,-28.8),V(6,4,.65),"cream")
    b("ToothGap",V(0,48,-29.2),V(.45,4,.3),"dark")
    for _,s in {-1,1} do
        b("Haunch",V(s*22,17,12),V(15,28,32),fur)
        b("BigFoot",V(s*18,5,-17),V(21,12,34),light)
        b("Paw",V(s*17,25,-25),V(13,24,13),fur)
        b("Eye",V(s*11.4,67,-21),V(5.2,7.4,.9),"dark")
        b("EyeGlint",V(s*11.4-1,69,-21.55),V(1.6,2,.3),"cream")
        b("Cheek",V(s*16.5,57,-21.3),V(5.8,3.5,.7),rose)
        local ef=pf*C(s*12,80,0)*A(0,0,-s*.13)
        box(pet,"TallEar",ef,V(0,24,0),V(14,50,14),fur)
        box(pet,"EarTip",ef,V(0,49,0),V(10,6,11),light)
        box(pet,"InnerEar",ef,V(0,26,-7.2),V(7,37,.8),rose)
        for _,x in {-5,1,7} do b("Toe",V(s*18+x,8,-34.2),V(1.2,3,.4),rose) end
    end
    local tail=Kit.part(pet,"CottonTail",pf*C(0,22,34),V(22,22,22),light,"Decoration","Ball")
    local carrot=pf*C(0,21,-37)*A(0,0,math.rad(-18))
    box(pet,"GiantCarrot",carrot,V(0,0,0),V(12,27,12),"orange")
    box(pet,"CarrotTip",carrot,V(0,-17,0),V(7,9,7),"terra")
    for _,s in {-1,0,1} do Kit.leaf(pet,"CarrotLeaf",carrot*C(0,14,0)*A(math.rad(-65),s*.75,0),24,10,if s==0 then "lime" else "leaf") end
    for _,p in pet:GetDescendants() do if p:IsA("BasePart") then p.CastShadow=false end end
    pet:SetAttribute("SignaturePet",true);report.giants.pet={height=pet:GetExtentsSize().Y}

    for _,row in {{"H1_Sprinkler","SPRINKLER",1.5},{"H2_Fruit","FRUIT",2.6}} do
        local h=root[row[1]];h:SetAttribute("ActiveSeconds",row[3])
        local board=h.StatusBoard
        board.Size=V(19,5.1,.45)
        board.Color=Color3.fromRGB(255,204,74)
        for _,v in board:GetDescendants() do if v:IsA("TextLabel") then v.Text=row[2].."\nWAIT FOR GREEN\nStay behind line";v.TextColor3=Color3.fromRGB(30,40,32) end end
        for _,p in h:GetChildren() do if p.Name=="WarningStripe" and p:IsA("BasePart") then p:SetAttribute("TimedWarningStripe",true) end end
    end
    for _,row in {{"G1_SeedBenchThorns","Slide","Z",7,2,0},{"G3_SporeRoot_4","Swing","Y",8,0,28},{"G5_FirstWagonThorns","Spin","Y",14,0,0}} do
        local group=root.ClosingRoute[row[1]];local bar=group.RedThornCrossbar
        bar:SetAttribute("KitMotion",row[2]);bar:SetAttribute("MotionAxis",row[3]);bar:SetAttribute("MotionPeriod",row[4]);bar:SetAttribute("MotionDistance",row[5]);bar:SetAttribute("MotionAngle",row[6])
        local followers=0
        for _,p in group:GetChildren() do if p:IsA("BasePart") and p.Name=="WarningBand" then p:SetAttribute("MotionFollows",bar.Name);followers+=1 end end
        table.insert(report.moving,{group=row[1],kind=row[2],followers=followers})
    end
    root:SetAttribute("CandidateId","SGV2_FinalPass_F01")
    root:SetAttribute("Phase","Final pass candidate awaiting comprehensive checks")
    root:SetAttribute("FinalPassEvidence","docs/artifacts/stud-garden-v2/finalpass-20261006")
    root:SetAttribute("TriangleCountScope","Legacy 377 MeshParts only; excludes 18 added avatar meshes and native primitive tessellation; no whole-F01 triangle or FPS claim")
    return report
end
