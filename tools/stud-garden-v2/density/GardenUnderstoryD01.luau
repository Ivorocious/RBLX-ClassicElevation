return function(root, Kit)
    assert(root:GetAttribute("CandidateId") == "SGV2_StudStyle_S05")
    assert(not root:FindFirstChild("GardenUnderstory"))
    local V, C, A = Vector3.new, CFrame.new, CFrame.Angles
    local origin = root:GetPivot().Position
    local frame = C(origin)
    local colors = Kit.colors
    colors.forest = Color3.fromRGB(37, 102, 62)
    colors.sage = Color3.fromRGB(121, 159, 84)
    colors.moss = Color3.fromRGB(81, 126, 50)
    colors.berry = Color3.fromRGB(176, 64, 99)
    colors.berryLight = Color3.fromRGB(220, 112, 144)
    colors.earthLight = Color3.fromRGB(117, 80, 47)
    colors.earthGrove = Color3.fromRGB(106, 74, 104)
    colors.flax = Color3.fromRGB(209, 179, 119)
    local garden = Kit.model(root, "GardenUnderstory", frame)
    garden:SetAttribute("ArtRevision", "D01")
    local ledger = {scenes={}, lowColliders=0, decorativeParts=0, translatedRespawns=0, translatedOrigins=0}
    local function scene(name, x, z, yaw, marks)
        local cf = frame*C(x, 0, z)*A(0, math.rad(yaw or 0), 0)
        local m = Kit.model(garden, name, cf)
        m:SetAttribute("OwnerVoidMarks", marks)
        table.insert(ledger.scenes, {name=name, center={x,z}, marks=marks})
        return m, cf
    end
    local function box(m, name, cf, pos, size, color, solid)
        return Kit.box(m,name,cf,pos,size,color,if solid then "Blocker" else "Decoration")
    end
    local function ball(m, name, cf, size, color)
        return Kit.part(m,name,cf,size,color,"Decoration","Ball")
    end
    local function rod(m, name, cf, a, b, radius, color, solid)
        return Kit.rod(m,name,cf*a,cf*b,radius,color,if solid then "Blocker" else "Decoration")
    end
    local function groundLobe(m, cf, width, depth, top, color)
        local bottom=-2.85
        local h=top-bottom
        for _,row in {{0,width*.68,depth},{-width*.42,width*.16,depth*.64},{width*.42,width*.16,depth*.64}} do
            local p=box(m,"SteppedEarth",cf,V(row[1],(top+bottom)/2,0),V(row[2],h,row[3]),color,true)
            p.TopSurface=Enum.SurfaceType.Studs
        end
    end
    local function roots(m, cf, length, yaw, color)
        local f=cf*A(0,math.rad(yaw),0)
        rod(m,"GroundedRoot",f,V(0,-1.15,0),V(0,-1.0,-length),1.15,color,true)
        rod(m,"RootShoulder",f,V(0,-1.15,-length*.4),V(length*.26,-1.3,-length*.76),.8,color,true)
    end
    local function leaf(m, cf, length, width, rise, color)
        local points={V(0,0,0),V(-width*.48,rise*.57,-length*.34),V(-width*.34,rise*.78,-length*.77),
            V(0,rise*.58,-length),V(width*.34,rise*.78,-length*.77),V(width*.48,rise*.57,-length*.34)}
        local ridge=V(0,rise+1.1,-length*.48)
        for i=1,6 do
            Kit.triangle(m,"FoldedLeaf",cf*points[i],cf*points[i%6+1],cf*ridge,.5,color,"Decoration")
        end
        local lighter=if color=="pink" or color=="pinkDark" then "pinkLight" else "sage"
        rod(m,"LeafJoinedMidrib",cf,V(0,.12,0),ridge+V(0,.18,0),.22,lighter)
        rod(m,"LeafJoinedMidrib",cf,ridge+V(0,.18,0),points[4]+V(0,.18,0),.18,lighter)
    end
    local function fan(m, cf, length, width, rise, yaw, tint)
        for i,row in {{-31,.90,.86},{8,1,1},{47,.82,.80}} do
            leaf(m,cf*A(0,math.rad(yaw+row[1]),0),length*row[2],width*row[3],rise*(.82+i*.06),if i==2 then tint or "moss" else "forest")
        end
    end
    local function seed(m, cf, size, color)
        local p=ball(m,"LargeSupportedSeed",cf,size,color or "flax")
        return p
    end
    local function pumpkin(m,cf,size,tilt)
        local f=cf*A(math.rad(tilt or 0),0,math.rad(-9))
        for n=0,7 do
            local a=n*math.pi/4
            ball(m,"SquashRib",f*C(math.cos(a)*size*.24,size*.45,math.sin(a)*size*.24),V(size*.59,size*.86,size*.59),if n%2==0 then "orange" else "terra")
        end
        rod(m,"SquashStem",f,V(0,size*.78,0),V(1.5,size*1.02,-.8),.8,"leaf")
        leaf(m,f*C(0,size*.78,0)*A(0,.4,0),size*.75,size*.4,size*.12,"forest")
    end
    local function berry(m,cf,size)
        ball(m,"GiantBerry",cf*C(0,size*.48,0),V(size*.95,size,size*.88),"berry")
        ball(m,"BerryShoulder",cf*C(0,size*.71,0),V(size,size*.54,size*.88),"berryLight")
        for i,row in {{-.27,.43},{0,.34},{.27,.43},{-.24,.65},{.03,.60},{.26,.65}} do
            local x,y=row[1]*size,row[2]*size
            local depth=-size*.42*math.sqrt(math.max(.1,1-(x/(size*.5))^2))
            local p=box(m,"BerrySeed",cf,V(x,y,depth-.04),V(.65,1.2,.18),"flax")
            p.CFrame*=A(0,0,math.rad(if i%2==0 then 20 else -15))
            p.CastShadow=false
        end
        for i=0,2 do leaf(m,cf*C(0,size*.91,0)*A(0,i*math.pi*2/3,0),size*.42,size*.22,1.2,"forest") end
    end
    local function tray(m,cf,width,depth)
        local floor=box(m,"GroundSeedTray",cf,V(0,-.9,0),V(width,1.2,depth),"timber",true)
        floor.TopSurface=Enum.SurfaceType.Studs
        for _,side in {-1,1} do
            box(m,"LowTrayRim",cf,V(side*(width/2-.5),-.25,0),V(1,1.8,depth),"honey",true)
            box(m,"LowTrayRim",cf,V(0,-.25,side*(depth/2-.5)),V(width-2,1.8,1),"honey",true)
        end
        box(m,"TraySoil",cf,V(0,-.15,0),V(width-2.1,.25,depth-2.1),"soil")
    end
    local function sack(m,cf,width,height)
        for i,row in {{0,.4,1},{1,.66,.85},{2,.86,.61}} do
            local y=height*row[2]
            ball(m,"FoldedSeedSack",cf*C(0,y,0),V(width*row[3],height*(if i==1 then .94 else .38),width*.78*row[3]),if i==2 then "honey" else "flax")
        end
        for i,row in {{-1,-.26,2},{1,.27,-3}} do
            local p=box(m,"SackFold",cf,V(row[1]*width*.2,height*.77,row[2]*width),V(width*.5,.7,width*.28),"cream")
            p.CFrame*=A(math.rad(28),math.rad(row[3]*7),math.rad(row[1]*18))
        end
        for i,row in {{-2.3,0,-1},{1.8,.3,-2.3},{3,-.1,1.4}} do seed(m,cf*C(row[1],height*.88+row[2],row[3])*A(.3,i*.8,.2),V(3.2,1.8,2.3)) end
    end
    local function tippedPot(m,cf,width,height)
        local f=cf*C(0,height*.45,0)*A(math.rad(64),0,math.rad(-12))
        local count=8
        for n=0,count-1 do
            local a=n*math.pi*2/count
            local b=(n+1)*math.pi*2/count
            Kit.quad(m,"FacetedPotShell",f,V(math.cos(a)*width*.33,0,math.sin(a)*width*.33),
                V(math.cos(b)*width*.33,0,math.sin(b)*width*.33),V(math.cos(b)*width*.5,height,math.sin(b)*width*.5),
                V(math.cos(a)*width*.5,height,math.sin(a)*width*.5),.7,if n%2==0 then "terra" else "orange","Decoration")
            rod(m,"PotRolledLip",f,V(math.cos(a)*width*.5,height,math.sin(a)*width*.5),
                V(math.cos(b)*width*.5,height,math.sin(b)*width*.5),.5,"terra")
        end
        ball(m,"PotRootball",f*C(0,height*.45,0),V(width*.76,height*.74,width*.76),"soil")
        roots(m,cf,13,-12,"earthLight")
    end
    local function fallenCap(m,cf,width,tilt,color)
        local f=cf*C(0,width*.40,0)*A(math.rad(tilt),math.rad(22),0)
        Kit.part(m,"FallenMushroomCap",f*A(0,0,math.pi/2),V(width*.18,width,width),color,"Decoration","Cylinder")
        Kit.part(m,"MushroomRaisedCrown",f*C(0,width*.1,0)*A(0,0,math.pi/2),V(width*.18,width*.76,width*.76),"pinkDark","Decoration","Cylinder")
        for n=0,5 do
            local a=n*math.pi/3
            rod(m,"CapGills",f,V(0,-width*.1,0),V(math.cos(a)*width*.40,-width*.1,math.sin(a)*width*.40),.24,"cream")
        end
        rod(m,"FallenStem",f,V(0,-width*.1,0),V(0,-width*.39,0),width*.11,"cream")
    end

    do
        local m,cf=scene("SeedlingCrescent",-102,108,0,"M01")
        groundLobe(m,cf*C(-22,0,-2),22,14,-.85,"soil")
        groundLobe(m,cf,32,15,-.65,"soil")
        groundLobe(m,cf*C(23,0,-7),20,18,-.9,"earthLight")
        sack(m,cf*C(-22,-.9,-3)*A(0,.25,0),10,8)
        fan(m,cf*C(-2,-.7,1),16,9,9,85,"sage")
        fan(m,cf*C(24,-.9,-7),17,9,10,100,"moss")
        roots(m,cf*C(-6,0,0),22,-90,"earthLight")
    end
    do
        local m,cf=scene("GardenerWorkyard",-16,96,-10,"M02")
        groundLobe(m,cf,26,43,-.6,"soil")
        groundLobe(m,cf*C(10,0,18),19,20,-.9,"earthLight")
        groundLobe(m,cf*C(-8,0,-23),18,21,-.85,"soil")
        tray(m,cf*C(1,0,7)*A(0,.16,0),19,20)
        sack(m,cf*C(-3,-.8,-12)*A(0,-.3,0),15,11)
        for i,row in {{-5,0,8},{2,.2,11},{5,.1,2}} do seed(m,cf*C(row[1],row[2]+1.3,row[3])*A(.2,i*.7,.3),V(5,2.6,3),"honey") end
        local packet=cf*C(6,3.5,-17)*A(math.rad(48),math.rad(-10),math.rad(8))
        box(m,"FoldedSeedPaper",packet,V(0,0,0),V(10,.5,14),"cream")
        box(m,"SeedPaperFold",packet*A(math.rad(-21),0,0),V(0,-.4,6.5),V(10,.4,2),"flax")
        seed(m,packet*C(0,.55,0)*A(0,.4,0),V(4,.6,6),"honey")
        fan(m,cf*C(6,-.6,17),19,11,12,-105,"forest")
        leaf(m,cf*C(-8,-.8,-18)*A(0,2.7,0),15,10,9,"moss")
    end
    do
        local m,cf=scene("MarketHarvestRibbon",98,133,0,"M03")
        groundLobe(m,cf*C(-31,0,0),22,16,-.95,"soil")
        groundLobe(m,cf*C(-8,0,2),29,20,-.7,"earthLight")
        groundLobe(m,cf*C(19,0,2),29,19,-.9,"soil")
        groundLobe(m,cf*C(42,0,-1),23,17,-1.0,"soil")
        pumpkin(m,cf*C(5,-1,2)*A(0,.4,0),14,13)
        tray(m,cf*C(27,0,1)*A(0,.24,0),16,13)
        seed(m,cf*C(27,2,1)*A(.4,.2,.5),V(10,5,7),"honey")
        fan(m,cf*C(-15,-.7,3),16,9,10,88,"moss")
        fan(m,cf*C(41,-1,-1),18,10,12,110,"forest")
        leaf(m,cf*C(5,-.8,3)*A(0,-math.pi/2,0),15,9,8,"sage")
        roots(m,cf*C(-18,0,0),48,-90,"earthLight")
    end
    do
        local m,cf=scene("VineSeedCradle",30,59,-20,"M04")
        groundLobe(m,cf,17,18,-.85,"soil")
        leaf(m,cf*C(-4,-.8,4)*A(0,-.7,0),12,8,6,"forest")
        leaf(m,cf*C(4,-.8,-3)*A(0,2.8,0),11,8,5,"moss")
        seed(m,cf*C(0,2.3,0)*A(.1,.3,.5),V(7,6,5),"lime")
        roots(m,cf,7,20,"earthLight")
    end
    do
        local m,cf=scene("SplitSquashHarvest",-94,-123,0,"M05")
        groundLobe(m,cf*C(-16,0,0),25,19,-.8,"soil")
        groundLobe(m,cf*C(8,0,0),30,20,-.6,"earthLight")
        pumpkin(m,cf*C(-12,-1,0)*A(0,.4,0),15,8)
        pumpkin(m,cf*C(12,-1,2)*A(0,1.2,0),11,30)
        fan(m,cf*C(3,-.8,4),17,10,11,75,"forest")
        leaf(m,cf*C(-19,-.8,-1)*A(0,.4,0),14,10,7,"moss")
        roots(m,cf*C(-13,0,0),28,-90,"earthLight")
    end
    do
        local m,cf=scene("SpilledPotShoulder",-84,-168,15,"M06")
        groundLobe(m,cf,20,18,-.85,"soil")
        groundLobe(m,cf*C(8,0,3),16,14,-1,"earthLight")
        tippedPot(m,cf*C(-2,-.8,-2),12,10)
        fan(m,cf*C(7,-.9,3),12,8,7,100,"sage")
    end
    do
        local m,cf=scene("HoseFernTurn",-31,-172,0,"M07")
        groundLobe(m,cf,25,19,-.9,"soil")
        groundLobe(m,cf*C(-10,0,1),17,16,-1.15,"soil")
        for ring=0,1 do
            local radius=4.2+ring*1.5
            for n=0,9 do
                local a=n*math.pi/5
                local b=(n+1)*math.pi/5
                rod(m,"CoiledGardenHose",cf,V(math.cos(a)*radius,-.55,math.sin(a)*radius),V(math.cos(b)*radius,-.55,math.sin(b)*radius),.6,"teal",true)
            end
        end
        fan(m,cf*C(6,-.9,1),15,10,10,70,"forest")
        leaf(m,cf*C(-3,-.9,-4)*A(0,-1.8,0),12,9,7,"sage")
    end
    do
        local m,cf=scene("StrawberryRunner",-2,-88,-18,"M08")
        groundLobe(m,cf*C(-4,0,-17),23,23,-.9,"soil")
        groundLobe(m,cf,29,32,-.65,"soil")
        groundLobe(m,cf*C(5,0,22),23,25,-1,"earthLight")
        berry(m,cf*C(-3,-1,-9)*A(0,.3,math.rad(-12)),13)
        berry(m,cf*C(5,-1,14)*A(0,-.7,math.rad(18)),10)
        fan(m,cf*C(-1,-.7,6),20,12,12,115,"forest")
        leaf(m,cf*C(6,-.8,22)*A(0,-1.7,0),17,11,10,"moss")
        leaf(m,cf*C(-3,-.9,-19)*A(0,1.0,0),15,11,9,"sage")
        roots(m,cf*C(0,0,17),34,5,"leaf")
    end
    do
        local m,cf=scene("GroveRootSkirt",42,-131,0,"M09")
        groundLobe(m,cf,23,26,-1.0,"earthGrove")
        leaf(m,cf*C(-5,-1,6)*A(0,-.8,0),14,10,3.2,"sage")
        leaf(m,cf*C(6,-1,-6)*A(0,2.5,0),14,10,3.8,"pinkDark")
        roots(m,cf*C(-5,0,-3),16,-90,"earthGrove")
    end
    do
        local m,cf=scene("SpreadingMushroomFloor",109,-76,0,"M10")
        groundLobe(m,cf*C(-18,0,-7),24,18,-.95,"earthGrove")
        groundLobe(m,cf*C(4,0,3),32,24,-.7,"earthGrove")
        groundLobe(m,cf*C(29,0,-1),27,21,-1,"soil")
        fallenCap(m,cf*C(6,-.9,2),17,67,"pinkLight")
        fallenCap(m,cf*C(29,-.9,-3)*A(0,-.4,0),13,52,"pink")
        leaf(m,cf*C(-20,-.9,-8)*A(0,-2.3,0),17,11,7,"forest")
        leaf(m,cf*C(22,-.9,5)*A(0,1.5,0),17,12,8,"sage")
        roots(m,cf*C(-11,0,1),35,-90,"earthGrove")
    end
    do
        local m,cf=scene("GrovePetalCradle",158,-173,0,"M11")
        groundLobe(m,cf,29,23,-.7,"earthGrove")
        groundLobe(m,cf*C(13,0,4),17,18,-1,"soil")
        leaf(m,cf*C(-7,-.8,3)*A(0,-.5,0),17,13,11,"pinkDark")
        leaf(m,cf*C(7,-.8,-4)*A(0,2.8,0),16,12,10,"pink")
        seed(m,cf*C(0,4,0)*A(.1,.2,.4),V(10,9,8),"gold")
        leaf(m,cf*C(13,-1,5)*A(0,1.1,0),13,9,5,"forest")
        roots(m,cf*C(-4,0,0),15,-90,"earthGrove")
    end
    do
        local m,cf=scene("BrassicaBedShoulder",-131,13,-12,"E_CENTRAL_CROP")
        groundLobe(m,cf,33,25,-.9,"soil")
        groundLobe(m,cf*C(-12,0,-8),20,18,-1.1,"earthLight")
        fan(m,cf*C(2,-1,6),20,13,12,60,"sage")
        fan(m,cf*C(-6,-1,-8),16,11,10,-100,"forest")
        roots(m,cf*C(-12,0,-3),23,-90,"earthLight")
    end
    do
        local m,cf=scene("BeanRootApron",109,-3,-4,"E_VINE_BASE")
        groundLobe(m,cf,24,21,-1.0,"soil")
        groundLobe(m,cf*C(-26,0,0),25,19,-1.15,"soil")
        leaf(m,cf*C(-25,-1.1,3)*A(0,1.7,0),17,12,7,"forest")
        leaf(m,cf*C(7,-1,1)*A(0,1.5,0),18,12,10,"moss")
        leaf(m,cf*C(-1,-1,-2)*A(0,-1.6,0),14,10,8,"sage")
        roots(m,cf*C(-22,0,0),30,-90,"earthLight")
    end

    -- Moving an editing model does not move its authored respawn attributes.
    local delta=origin-root:GetAttribute("CourseOrigin")
    local spatialObjects=root:GetDescendants()
    table.insert(spatialObjects,root)
    for _,object in spatialObjects do
        for key,value in object:GetAttributes() do
            if key=="RespawnCFrame" then
                object:SetAttribute(key,C(delta)*value)
                ledger.translatedRespawns+=1
            elseif key=="CourseOrigin" then
                object:SetAttribute(key,value+delta)
                ledger.translatedOrigins+=1
            end
        end
    end
    for _,p in garden:GetDescendants() do
        if p:IsA("BasePart") then
            if p.CanCollide then
                local h=math.abs(p.CFrame.RightVector.Y)*p.Size.X/2+math.abs(p.CFrame.UpVector.Y)*p.Size.Y/2+math.abs(p.CFrame.LookVector.Y)*p.Size.Z/2
                assert(p.CFrame.Position.Y+h<=origin.Y+.701,"Scenery creates an elevated support: "..p:GetFullName())
                ledger.lowColliders+=1
            else
                assert(not p.CanTouch and not p.CanQuery)
                ledger.decorativeParts+=1
            end
            if p:IsA("WedgePart") and p.Name:find("FoldedLeaf",1,true) then p.TopSurface=Enum.SurfaceType.Studs end
        end
    end
    root:SetAttribute("CandidateId","SGV2_Density_D01")
    root:SetAttribute("Phase","Connected garden understory; native review pending")
    root:SetAttribute("RuntimeStatus","Density and moved-course respawn checks pending")
    root:SetAttribute("CandidateRequiresVerification",true)
    root:SetAttribute("DensityEvidence","docs/artifacts/stud-garden-v2/density-20261006")
    ledger.origin={origin.X,origin.Y,origin.Z}
    ledger.spatialAttributeDelta={delta.X,delta.Y,delta.Z}
    return ledger
end

