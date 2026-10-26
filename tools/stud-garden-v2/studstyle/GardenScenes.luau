return function(root, Kit)
    assert(root:GetAttribute("CandidateId") == "SGV2_Refinement_R02", "Fresh owner baseline required")
    local V, C = Vector3.new, CFrame.new
    local origin = root:GetPivot().Position
    local frame = C(origin)
    local ledger = {removed = {}, scenes = {}, nativeStudFaces = 0, squareAccents = 0, convertedStuds = 0}
    local garden = Kit.model(root, "StudGardenCompositions", frame)
    garden:SetAttribute("ArtRevision", "S01")
    local colors = Kit.colors
    colors.moss = Color3.fromRGB(76, 128, 49)
    colors.chalk = Color3.fromRGB(235, 222, 175)
    colors.clayLight = Color3.fromRGB(222, 148, 88)

    local function remove(object)
        table.insert(ledger.removed, {path = object:GetFullName():sub(#root:GetFullName() + 2), instances = #object:GetDescendants() + 1})
        object:Destroy()
    end
    for _, wall in root.RefinedGardenBoundaries:GetChildren() do
        if wall.Name ~= "PetDisplayFront" then remove(wall) end
    end
    for _, name in {"AppleStall", "PumpkinStall", "FlowerStall", "MarketGarlands"} do remove(root.ClosingScenery[name]) end

    local function scene(name, x, z, yaw)
        local cf = frame * C(x, -2.8, z) * CFrame.Angles(0, math.rad(yaw or 0), 0)
        local model = Kit.model(garden, name, cf)
        model:SetAttribute("Composition", true)
        table.insert(ledger.scenes, name)
        return model, cf
    end
    local function box(model, name, cf, x, y, z, sx, sy, sz, color, solid)
        return Kit.box(model, name, cf, V(x,y,z), V(sx,sy,sz), color, if solid then "Blocker" else "Decoration")
    end
    local function rod(model, name, cf, a, b, radius, color, solid)
        return Kit.rod(model, name, cf*a, cf*b, radius, color, if solid then "Blocker" else "Decoration")
    end
    local function studs(model, cf, width, depth, color, pitch)
        pitch = pitch or 3
        local nx, nz = math.floor((width-.6)/pitch), math.floor((depth-.6)/pitch)
        for ix=1,nx do
            for iz=1,nz do
                local p = box(model, "SquareStud", cf, (ix-(nx+1)/2)*pitch, .10, (iz-(nz+1)/2)*pitch, .65*pitch, .20, .65*pitch, color)
                p.CastShadow = false
                p:SetAttribute("StudGridPitch", pitch)
                ledger.squareAccents += 1
            end
        end
    end
    local function groundBed(model, cf, width, depth, tint)
        box(model, "GroundedEarth", cf, 0,.65,0,width,1.3,depth,"soil",true)
        box(model, "StuddedEarthCap", cf, 0,1.37,0,width-.8,.18,depth-.8,tint or "soil")
        for _,side in {-1,1} do
            box(model, "TimberBedEdge", cf, side*(width/2-.4),1,0,.8,2,depth,"timber",true)
            box(model, "TimberBedEdge", cf, 0,1,side*(depth/2-.4),width,2,.8,"timber",true)
        end
    end
    local function leaf(model, cf, length, width, color, coarse)
        local widths = {.40,.86,1,.82,.42}
        local step = length/5
        for i=1,5 do
            local p = box(model, "BroadSteppedLeaf", cf, 0,0,-(i-.5)*step,width*widths[i],.65,step+.05,color)
            p.TopSurface = Enum.SurfaceType.Studs
            if coarse and i==3 then studs(model,p.CFrame*C(0,.325,0),width*widths[i]-.6,step-.2,color,2.5) end
        end
        box(model, "JoinedLeafRib", cf, 0,.43,-length*.49,.6,.4,length*.90,"lime")
    end
    local function planter(model, cf, width, depth, height, color)
        box(model,"TaperedFoot",cf,0,2.5,0,width*.72,5,depth*.72,color,true)
        box(model,"PlanterLower",cf,0,7,0,width*.84,9,depth*.84,color,true)
        box(model,"PlanterUpper",cf,0,(height+10)/2,0,width,height-10,depth,color,true)
        local rim=height+1
        box(model,"StuddedSoil",cf,0,height-.25,0,width-2,.5,depth-2,"soil")
        for _,side in {-1,1} do
            box(model,"ThickRim",cf,side*(width/2-.65),rim,0,1.7,2,depth+1,"clayLight",true)
            box(model,"ThickRim",cf,0,rim,side*(depth/2-.65),width+1,2,1.7,"clayLight",true)
        end
        for x=-width*.28,width*.28,width*.56 do
            box(model,"JoinedPotRib",cf,x,(height+3)/2,-depth/2-.1,1.2,height-3,.25,"clayLight")
        end
    end

    -- Broad native surfaces carry the ordinary grid; narrow landings and hazards stay calm.
    for _,p in root:GetDescendants() do
        if p:IsA("Part") and p.Transparency<.05 and not p:IsDescendantOf(garden) then
            if p.Name=="RaisedStud" and not p.CanCollide then
                p.Shape=Enum.PartType.Block
                p.Size=V(p.Size.X, p.Size.Y*.78, p.Size.Z*.78)
                ledger.convertedStuds+=1
            elseif p.Shape==Enum.PartType.Block and p.Size.X>=3 and p.Size.Z>=3 and p.CFrame.UpVector.Y>.8
                and p.Material~=Enum.Material.Neon and p:GetAttribute("Role")~="Marker"
                and not p:GetFullName():find("Expert",1,true) and not p:GetFullName():find("Choice",1,true) then
                p.TopSurface=Enum.SurfaceType.Studs
                ledger.nativeStudFaces+=1
            end
        end
    end

    do
        local m,cf=scene("EntryWateringCan",-174,108,-18)
        groundBed(m,cf,24,29,"moss")
        box(m,"CanBody",cf,0,13,0,18,24,17,"teal",true)
        box(m,"CanShoulder",cf,0,24,0,16,4,15,"aqua",true)
        box(m,"CanTop",cf,0,26.2,0,14,.6,13,"teal",true)
        box(m,"DarkFillOpening",cf,-2,26.55,1,6,.15,6,"dark")
        for _,side in {-1,1} do box(m,"CanRaisedBand",cf,side*9.1,12,0,.45,17,15,"aqua") end
        box(m,"HandleUpright",cf,-11,29,0,2,16,2,"honey")
        box(m,"HandleTop",cf,-3.5,36,0,17,2,2,"honey")
        box(m,"HandleReturn",cf,4,30.5,0,2,11,2,"honey")
        rod(m,"JoinedSpout",cf,V(7,10,0),V(16,26,0),2.3,"teal")
        rod(m,"SpoutRose",cf,V(15.8,25.7,0),V(18,29,0),4.3,"honey")
        studs(m,cf*C(0,26.53,0),13,12,"teal",3)
        leaf(m,cf*C(-7,2,9)*CFrame.Angles(0,math.rad(-30),math.rad(15)),13,7,"leaf")
        leaf(m,cf*C(7,2,8)*CFrame.Angles(math.rad(12),math.rad(60),0),16,8,"grass")
    end
    do
        local m,cf=scene("CabbageTerrace",-161,-31,7)
        groundBed(m,cf,35,29,"soil")
        for index,row in {{-8,8,-2,1},{9,6,7,.72}} do
            local crown=cf*C(row[1],row[2],row[3]);local scale=row[4]
            box(m,"CabbageCore",crown,0,0,0,8*scale,13*scale,8*scale,"lime",true)
            for n=0,5 do
                local f=crown*CFrame.Angles(0,n*math.pi/3,0)*C(0,-4*scale,1)*CFrame.Angles(math.rad(-39),0,0)
                leaf(m,f,16*scale,10*scale,if n%2==0 then "moss" else "grass",index==1 and n==1)
            end
        end
        box(m,"BroadEarthShoulder",cf,0,2,0,27,2,21,"soil",true)
    end
    do
        local m,cf=scene("GiantTurnipHarvest",-119,-172,-5)
        groundBed(m,cf,39,22,"soil")
        for index,row in {{-10,0,1},{10,2,.82}} do
            local t=cf*C(row[1],1,row[2]);local s=row[3]
            box(m,"TurnipRoot",t,0,3*s,0,8*s,6*s,8*s,"cream",true)
            box(m,"TurnipBody",t,0,12*s,0,15*s,17*s,15*s,"cream",true)
            box(m,"TurnipShoulder",t,0,21*s,0,12*s,5*s,12*s,"pink",true)
            box(m,"LeafCrown",t,0,25*s,0,4*s,5*s,4*s,"leaf")
            for n=0,3 do leaf(m,t*C(0,26*s,0)*CFrame.Angles(math.rad(-35),n*math.pi/2,0),14*s,8*s,"grass",index==1 and n==1) end
            studs(m,t*C(0,23.51*s,0),10*s,10*s,"pink",3)
        end
    end
    do
        local m,cf=scene("CentralNurseryPlanter",22,-31,-8)
        groundBed(m,cf,35,26,"soil")
        planter(m,cf*C(0,1.5,0),29,21,24,"terra")
        for i,row in {{-5,30,3,-25},{5,34,0,60},{-1,39,-5,140}} do
            rod(m,"SubstantialJoinedStalk",cf,V(row[1]*.5,25,0),V(row[1],row[2],row[3]),1.2,"leaf")
            local crown=cf*C(row[1],row[2],row[3])*CFrame.Angles(math.rad(-12),math.rad(row[4]),math.rad(6))
            leaf(m,crown,23,12,if i==2 then "lime" else "grass",true)
            leaf(m,crown*CFrame.Angles(math.rad(15),math.pi,0),18,10,"leaf")
        end
    end
    do
        local m,cf=scene("CandyMushroomBed",79,-174,0)
        groundBed(m,cf,37,24,"pinkDark")
        for index,row in {{-9,2,29,25},{10,3,20,17}} do
            local x,z,height,width=unpack(row)
            box(m,"MushroomStem",cf,x,height/2,z,6,height,6,"cream",true)
            box(m,"SquareGilledCap",cf,x,height,z,width,3,width,"pinkLight")
            box(m,"SteppedCandyCap",cf,x,height+3,z,width-3,4,width-3,"pink")
            box(m,"SteppedCandyCrown",cf,x,height+5.8,z,width-9,2,width-9,"pinkDark")
            studs(m,cf*C(x,height+6.8,z),width-10,width-10,"pinkLight",3)
            for _,dx in {-1,1} do box(m,"CapJoinedGills",cf,x+dx*width*.27,height-1.7,z,1,.5,width-3,"pinkDark") end
        end
    end
    local function beanPod(m,cf,height,width,color)
        box(m,"PodHeel",cf,0,3,0,width*.6,6,width*.55,color,true)
        box(m,"PodBody",cf,0,height*.45,0,width,height*.9,width*.65,color,true)
        box(m,"PodShoulder",cf,0,height*.90,0,width*.75,height*.20,width*.53,color,true)
        box(m,"PodTip",cf,0,height*1.04,0,width*.38,height*.10,width*.34,"lime")
        for i=1,3 do
            box(m,"PodRaisedSeed",cf,0,height*(.22+i*.16),-width*.36,width*.56,width*.56,.65,"lime")
        end
        box(m,"PodJoinedSeam",cf,0,height*.48,-width*.4,.65,height*.78,.4,"leaf")
    end
    do
        local m,cf=scene("GiantBeanPodCradle",151,-48,13)
        groundBed(m,cf,29,26,"soil")
        beanPod(m,cf*C(-6,2,0)*CFrame.Angles(0,0,math.rad(-12)),32,10,"grass")
        beanPod(m,cf*C(7,2,4)*CFrame.Angles(0,math.rad(-14),math.rad(8)),25,9,"leaf")
        leaf(m,cf*C(0,3,6)*CFrame.Angles(math.rad(-25),math.rad(80),0),22,12,"moss",true)
    end
    do
        local m,cf=scene("HarvestGlasshouse",87,182,0)
        groundBed(m,cf,59,22,"soil")
        box(m,"GreenhouseFoundation",cf,0,3,0,55,6,18,"terra",true)
        box(m,"OpaqueRear",cf,0,20,7,55,28,2,"teal",true)
        for _,side in {-1,1} do
            box(m,"OpaqueSide",cf,side*26.5,20,0,2,28,16,"teal",true)
            box(m,"RoofBeam",cf,side*14,36,0,29,2,22,"honey",false)
        end
        for i=-2,2 do
            local x=i*10
            box(m,"FrontWindowBay",cf,x,20,-8,8.5,22,1.4,"aqua",true)
            box(m,"WindowHeader",cf,x,32,-9,10,2,2,"cream")
            box(m,"WindowVerticalMullion",cf,x,21,-9,1,20,1,"cream")
            box(m,"WindowHorizontalMullion",cf,x,21,-9,9,1,1,"cream")
            box(m,"GroundedBayPost",cf,x-5,18,-9,1.5,36,1.5,"honey",true)
            local leafFrame=cf*C(x,13,-9.8)*CFrame.Angles(math.rad(-65),math.pi,0)
            leaf(m,leafFrame,8,4,"leaf")
        end
        box(m,"LastBayPost",cf,25,18,-9,1.5,36,1.5,"honey",true)
        local pitch=math.rad(19)
        for _,side in {-1,1} do
            local roof=box(m,"StuddedRoofSlope",cf*C(side*13.8,39,0)*CFrame.Angles(0,0,-side*pitch),0,0,0,29,1.5,23,"cream")
            roof.TopSurface=Enum.SurfaceType.Studs
        end
        box(m,"RoofRidge",cf,0,44,0,2,2,24,"honey")
    end
    do
        local m,cf=scene("FinishGoldenSeed",-51,172,12)
        groundBed(m,cf,23,24,"soil")
        planter(m,cf,17,17,20,"terra")
        beanPod(m,cf*C(0,22,0),19,9,"gold")
        leaf(m,cf*C(0,24,0)*CFrame.Angles(math.rad(-17),math.rad(110),0),17,8,"grass",true)
        leaf(m,cf*C(0,26,0)*CFrame.Angles(math.rad(-30),math.rad(-65),0),14,8,"leaf")
    end

    local boundaries=Kit.model(root,"CreativeGardenBoundaries",frame)
    do
        local cf=frame*C(-118,0,63.5)
        local m=Kit.model(boundaries,"ForkToolCaddy",cf)
        -- The forged necks occupy the one-stud seam; decorative grips open overhead.
        for index,row in {{-16,23},{-5.3,27},{5.4,24},{16.1,26}} do
            local x,top=row[1],row[2]
            box(m,"ForgedSpadeBlade",cf,x,(top-2.8)/2,0,10.8,top+2.8,.72,if index%2==0 then "steel" else "steelLight",true)
            box(m,"SteppedBladeShoulder",cf,x,top+1.7,0,7.6,3.4,.8,"steel",true)
            box(m,"LongTimberHandle",cf,x,top+9,0,1.8,14,1.15,"timber",true)
            for _,side in {-1,1} do box(m,"GripSide",cf,x+side*2.6,top+17,0,.9,5,1.05,"honey") end
            box(m,"GripTop",cf,x,top+19.5,0,6.1,.9,1.05,"honey")
            for _,side in {-1,1} do box(m,"BladeJoinedRib",cf,x,(top+1)/2,side*.44,.45,top-3,.18,"edge") end
        end
        box(m,"ToolRestBelowRoute",cf,0,-.8,0,44,3,3,"timber",true)
    end
    do
        local cf=frame*C(-77.7,0,64.8)
        local m=Kit.model(boundaries,"ForkRosemaryClump",cf)
        for index,row in {{-6.7,22},{0,28},{6.7,24}} do
            local x,h=row[1],row[2]
            box(m,"BroadUprightLeaf",cf,x,(h-2.8)/2,0,6.9,h+2.8,1.8,if index==2 then "grass" else "leaf",true)
            box(m,"LeafShoulder",cf,x,h+1.1,0,4.5,2.2,1.7,"grass",true)
            box(m,"LeafTip",cf,x,h+3,0,2,2,1.5,"lime")
            for _,side in {-1,1} do box(m,"LeafRib",cf,x,h*.5,side*.99,.6,h*.8,.25,"lime") end
        end
    end
    do
        local cf=frame*C(129,0,86.15)
        local m=Kit.model(boundaries,"MarketRhubarbClump",cf)
        for index,row in {{-7.2,28},{0,34},{7.2,29}} do
            local x,h=row[1],row[2]
            box(m,"BroadRhubarbLeaf",cf,x,(h-2.8)/2,0,7.6,h+2.8,3.2,if index==2 then "grass" else "leaf",true)
            box(m,"RhubarbShoulder",cf,x,h+1.3,0,5,2.6,3.0,"grass",true)
            box(m,"RhubarbTip",cf,x,h+3.5,0,2.5,2,2.4,"lime")
            for _,side in {-1,1} do
                box(m,"JoinedRhubarbVein",cf,x,h*.5,side*1.72,.7,h*.82,.25,"lime")
                for j=1,5 do box(m,"SquareLeafStud",cf,x+1.7,h*.14+j*4,side*1.68,1.3,1.3,.2,"grass") end
            end
        end
    end
    for _,p in garden:GetDescendants() do
        if p:IsA("Part") and p.Shape==Enum.PartType.Block and p.Size.X>=3 and p.Size.Z>=3 and p.Name~="SquareStud" then
            p.TopSurface=Enum.SurfaceType.Studs
            ledger.nativeStudFaces+=1
        end
    end
    root:SetAttribute("CandidateId","SGV2_StudStyle_S01")
    root:SetAttribute("Phase","Researched stud style and large garden compositions; native review pending")
    root:SetAttribute("GameplayValidated",false)
    root:SetAttribute("CandidateRequiresVerification",true)
    root:SetAttribute("StudStyle","Native square grid on broad parts; low square accents on selected hero faces")
    root:SetAttribute("LongPanelWalls",0)
    root:SetAttribute("RuntimeStatus","New scenery and boundary checks pending")
    return ledger
end
