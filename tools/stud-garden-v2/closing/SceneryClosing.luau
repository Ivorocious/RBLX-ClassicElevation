return function(root,Kit,Scenery)
    local origin=root:GetPivot().Position
    local frame=CFrame.new(origin)
    local V=Vector3.new
    assert(not root:FindFirstChild("ClosingScenery"),"Scenery already applied")
    local folder=Kit.model(root,"ClosingScenery",frame)
    local grove=root.Obstacles.G3_CandyGrove
    local canopy={
        {"CandyBlossom_1",48,-156,40,5},{"CandyBlossom_2",166,-88,44,-5},
        {"CandyBlossom_3",107,-83,46,4},{"CandyBlossom_4",11,-111,37,7},
    }
    for _,row in canopy do
        local old=grove[row[1]]
        Scenery.grove(folder,"GroveBloom_"..row[1],frame*CFrame.new(row[2],-2.8,row[3]),row[4],row[5])
        old:Destroy()
    end
    root.Obstacles.G4_LowerVine.LowerVineLandmark:Destroy()
    Scenery.beanstalk(folder,frame*CFrame.new(108,-2.8,43))
    Scenery.bambooBoundary(folder,frame*CFrame.new(-122,0,-96))
    local planted=root.Obstacles.G2_CropGarden.PlantedContext
    local potCarrots=root.Obstacles.G2_CropGarden.PlayableObjects.PotRim_A.CenterCarrot
    local potBerries=root.Obstacles.G2_CropGarden.PlayableObjects.PotRim_B.CenterBerry
    Kit.scale(potCarrots,1.8)
    Kit.scale(potBerries,2.1)
    local cropChanges={
        {"BerryBank",2.2,-23,1,-7},{"BunnyCarrot",2.1,-21,3.2,18},
        {"Bunny",1.9,-21,3.2,27},{"PetBank",1.5,-22,3,26},
        {"EntrySunflowers",1.6,-13,2,15},{"LayeredBamboo_1",1.35,-12,-1,6},
        {"LayeredBamboo_2",1.35,-13,-1,-21},{"LayeredBamboo_3",1.3,-104,-1,11},
    }
    for _,row in cropChanges do
        local model=assert(planted:FindFirstChild(row[1]),row[1])
        Kit.scale(model,row[2])
        model:PivotTo(frame*CFrame.new(row[3],row[4],row[5])*model:GetPivot().Rotation)
    end
    local cropScene=Kit.model(folder,"CultivatedCropRows",frame)
    for row=1,3 do
        local z=-38-row*10
        Kit.box(cropScene,"DarkCultivatedBed",frame,V(-30,-.3,z),V(20,4.6,6.5),"soil","Blocker")
        for _,s in {-1,1} do Kit.box(cropScene,"CropRowTimber",frame,V(-30,1.3,z+s*3.4),V(21,1,.65),"honey","Blocker") end
        for i=1,4 do
            local carrot=planted.BunnyCarrot:Clone()
            carrot.Name="CarrotRow_"..row.."_"..i
            Kit.scale(carrot,.65)
            carrot:PivotTo(frame*CFrame.new(-40+i*4.6,2.0,z)*CFrame.Angles(0,(row+i)*.6,0))
            carrot.Parent=cropScene
        end
    end
    local pen=Kit.model(folder,"PetGardenFrontage",frame)
    for _,row in {{-10,27,0,18},{-23,38,math.pi/2,24}} do
        local cf=frame*CFrame.new(row[1],3.2,row[2])*CFrame.Angles(0,row[3],0)
        for _,y in {1.1,3.1} do Kit.box(pen,"PetRail",cf,V(0,y,0),V(.5,.4,row[4]),"honey","Blocker") end
        for _,z in {-row[4]/2,0,row[4]/2} do Kit.box(pen,"PetPost",cf,V(0,2,z),V(.8,4,.8),"timber","Blocker") end
    end
    local market=root.Obstacles.G5_HarvestFestival
    for index,name in {"FirstHarvestWagon","SecondHarvestWagon","LongHarvestWagon"} do Scenery.wagon(folder,"LoadedWagon_"..index,market[name],origin) end
    market.FestivalLandmark:Destroy()
    Scenery.stall(folder,"PumpkinStall",frame*CFrame.new(63,4.5,184),22,"terra","PUMPKINS")
    Scenery.stall(folder,"AppleStall",frame*CFrame.new(88,4.5,184),22,"teal","ORCHARD PICKS")
    Scenery.stall(folder,"FlowerStall",frame*CFrame.new(113,4.5,184),22,"grass","GARDEN HARVEST")
    Scenery.wheelbarrow(folder,frame*CFrame.new(178,-2.8,171)*CFrame.Angles(0,math.rad(-25),0))
    for i,row in {{52,177},{136,180},{171,184}} do
        local cf=frame*CFrame.new(row[1],-2.8,row[2])*CFrame.Angles(0,i*.2,0)
        local crate=Scenery.crate(folder,"MarketStock_"..i,cf,8,8,7,"honey")
        Scenery.produce(crate,cf*CFrame.new(0,5,0),if i==2 then "Apple" else "Pumpkin",9)
    end
    local bunting=Kit.model(folder,"MarketGarlands",frame)
    for _,row in {{57,129,176,24},{145,164,177,22},{-26,0,173,22}} do
        local start,finish,z,height=row[1],row[2],row[3],row[4]
        for _,x in {start,finish} do Kit.box(bunting,"BuntingMast",frame,V(x,height/2-1.4,z),V(.8,height+2.8,.8),"timber","Blocker") end
        local previous
        local count=math.floor((finish-start)/4)
        for i=0,count do
            local t=i/count
            local y=height-3*math.sin(t*math.pi)
            local p=V(start+(finish-start)*t,y,z)
            if previous then
                Kit.rod(bunting,"BuntingCord",frame*previous,frame*p,.12,"timber")
                local middle=(previous+p)/2
                Kit.triangle(bunting,"FestivalPennant",frame*(middle+V(-1.5,0,0)),frame*(middle+V(1.5,0,0)),frame*(middle-V(0,2.8,0)),.13,({"coral","gold","teal","grass"})[i%4+1],"Decoration")
            end
            previous=p
        end
    end
    root:SetAttribute("CandidateId","SGV2_Closing_C05")
    root:SetAttribute("LegacyPhase3SourceTriangles",root:GetAttribute("SourceTriangles"))
    root:SetAttribute("SourceTriangles",nil)
    root:SetAttribute("RetainedPhase3MeshTriangles",443892)
    root:SetAttribute("TriangleCountScope","Retained Phase3 meshes only; older kit meshes and native primitive tessellation excluded")
    root:SetAttribute("Phase","Closing candidate; static design checks in progress; runtime approval outstanding")
    root:SetAttribute("ClosingArtSource","NativeKit, ToolFamily, RoutePresentation, RouteClosing, GardenScenery, SceneryClosing; recoverable Luau and native model")
    root:SetAttribute("GameplayValidated",false)
    return {newSceneryObjects=#folder:GetDescendants(),districts={"Cultivated crop rows and enlarged pet/plant groups","Eight alien flower cups on four branching plants","108-stud triple twisting beanstalk with ten broad canopy leaves","Three loaded wagons, three produce stalls and a loaded wheelbarrow"}}
end
