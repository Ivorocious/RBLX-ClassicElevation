return function(root,Kit,Tools,Route,spec)
    local origin=root:GetPivot().Position
    local frame=CFrame.new(origin)
    local V=Vector3.new
    local route=root.ClosingRoute
    assert(route and not root:FindFirstChild("ClosingScenery"),"Requires the current calibration")
    local ledger={removedStudBatches={},toolReplacements={},geometryActions={},hazards={}}
    local function path(name)
        local object=root
        for key in name:gmatch("[^.]+") do object=assert(object:FindFirstChild(key),name) end
        return object
    end
    for _,row in spec.removeStudBatches do
        local old=assert(root.Phase3Art:FindFirstChild(row.name))
        assert(old:IsA("MeshPart") and old.Name:sub(1,13)=="F03__surface_","Only obsolete surface-stud batches may be removed")
        old:Destroy()
        table.insert(ledger.removedStudBatches,row)
    end
    for _,row in {
        {"Obstacles.G1_SeedShop.TrowelClimb","Trowel",1,false},
        {"Obstacles.G1_SeedShop.ForkCrossing","Fork",1,false},
        {"Obstacles.G2_ToolGardenExit.StoredTrowel","Trowel",.82,true},
        {"Obstacles.G2_ToolGardenExit.StoredFork","Fork",.82,true},
        {"Obstacles.G5_HarvestFestival.HarvestFork","Fork",.9,false},
        {"Obstacles.G5_HarvestFestival.LastTrowel","Trowel",1,false},
    } do
        local old=path(row[1])
        local cf=old:GetPivot()
        if row[4] then cf=cf*CFrame.new(0,0,9.5*row[3])*CFrame.Angles(0,math.pi,0) end
        local model=Tools.build(nil,old.Name,cf,row[2])
        Kit.scale(model,row[3])
        for _,p in model:GetChildren() do
            if p:IsA("BasePart") and p.Name=="ToolDisplayStand" then
                local top=p.CFrame.Position.Y+p.Size.Y/2
                p.Size=V(p.Size.X,top-origin.Y+2.8,p.Size.Z)
                p.CFrame=CFrame.new(p.CFrame.Position.X,(top+origin.Y-2.8)/2,p.CFrame.Position.Z)*p.CFrame.Rotation
            end
        end
        for _,z in {14.3,18,21.2} do Kit.stud(model,cf*V(0,.43*row[3],z*row[3]),"honey",.45*row[3]) end
        model.Parent=old.Parent;old:Destroy()
        table.insert(ledger.toolReplacements,{path=row[1],reversed=row[4],scale=row[3]})
    end
    local crop=path("Obstacles.G2_CropGarden")
    crop.PlantedContext.ExpertChoice:Destroy()
    for _,name in {"PlayableObjects","PlantedContext","StudyMarkers"} do
        local model=crop:FindFirstChild(name)
        if model and model:IsA("Model") then model.WorldPivot=frame*CFrame.new(-102,0,-65) end
    end
    local oldMerge=crop.PlayableObjects.MergeRefuge
    local merge=Kit.model(nil,"MergeRefuge",frame*CFrame.new(-162,8,-126))
    Kit.box(merge,"Earth",frame,V(-162,2.6,-126),V(36,10.8,30),"soil","Blocker")
    Kit.box(merge,"GrassCap",frame,V(-162,8.12,-126),V(36,.24,30),"grass","Refuge")
    for _,z in {-138,-114} do for _,x in {-175,-169,-163,-157,-151} do Kit.stud(merge,frame*V(x,8.24,z),"grass",.68) end end
    merge.Parent=oldMerge.Parent;oldMerge:Destroy()
    local cp4=root.Checkpoints.Checkpoint_004
    cp4.CFrame=frame*CFrame.new(-162,11.24,-126)
    cp4.Size=V(34,6,28)
    cp4:SetAttribute("RespawnCFrame",frame*CFrame.new(-165,13.24,-128))
    cp4:SetAttribute("RespawnAreaSize",V(21,0,17))
    cp4:SetAttribute("Circulation","20 respawn positions in west pocket; east and south passage each exceed 8 studs outside 3-stud-wide body footprints")
    for _,name in {"BambooTurn","BambooSouth","BambooReturn","BambooNorth"} do
        Kit.scale(crop.PlayableObjects[name],if name=="BambooTurn" or name=="BambooSouth" then .97 else .93)
    end
    for _,stake in crop.PlayableObjects.ExpertStakes:GetChildren() do
        if stake:IsA("Model") then
            local cap=stake.Cap
            cap.Size=V(1.8,.8,6.3)
            cap.Color=Kit.colors.gold
            local stem=stake.Timber
            stem.Size=V(1.6,stem.Size.Y,1.6)
            stake:SetAttribute("LandingWidth",1.8)
            stake:SetAttribute("LandingLength",6.3)
        end
    end
    local vine=path("Obstacles.G4_LowerVine")
    vine.ExpertVineChoice:Destroy()
    for i=1,4 do Kit.scale(vine["OpeningLeaf_"..i],.98) end
    for i=1,6 do Kit.scale(vine["BroadTurnLeaf_"..i],.94) end
    for i=1,5 do
        local old=vine["ExpertTendril_"..i]
        local leaf=Route.racingLeaf(nil,old.Name,old:GetPivot(),2.3,11.3)
        leaf.Parent=vine;old:Destroy()
    end
    for _,m in vine:GetChildren() do
        if m:IsA("Model") and (m.Name:sub(1,12)=="OpeningLeaf_" or m.Name:sub(1,14)=="BroadTurnLeaf_" or m.Name:sub(1,9)=="ExitLeaf_") then
            for _,p in m:GetDescendants() do
                if p:IsA("BasePart") then
                    if p.Name:sub(1,10)=="BladeFacet" then p.Color=if p.Name:find("_3_") or p.Name:find("_6_") then Kit.colors.lime else Color3.fromRGB(188,209,108)
                    elseif p.Name=="Midrib" or p.Name=="Vein" then p.Color=Kit.colors.cream end
                end
            end
        end
    end
    for _,p in path("Obstacles.G3_CandyGrove"):GetDescendants() do
        if p:IsA("BasePart") and p.Name:sub(1,14)=="RootCrownFacet" then p.Color=Color3.fromRGB(255,190,190) end
    end
    local checkpointDirections={
        {V(1,0,0),V(0,0,-1)},{V(0,0,1),V(0,0,-1)},{V(0,0,1),V(-1,0,0)},
        {V(0,0,1),V(0,0,-1)},{V(-1,0,0),V(1,0,0)},{V(-1,0,0),V(1,0,1)},
        {V(-1,0,0),V(0,0,1)},{V(1,0,0),V(-1,0,1)},{V(-1,0,-.3),V(1,0,1)},
    }
    route.CheckpointGate_01:Destroy()
    for i,directions in checkpointDirections do
        local trigger=root.Checkpoints[string.format("Checkpoint_%03d",i)]
        local old=root.Decoration:FindFirstChild(string.format("VisibleCheckpoint_%02d",i))
        if old then old:Destroy() end
        Route.checkpoint(route,trigger,i,trigger.CFrame.Position.Y-3,origin,directions[1],directions[2])
    end
    Kit.arrow(route,frame*V(-149,8.36,-135),V(0,0,-1),3.5,"cream")
    route.ForkReturnBoundary:Destroy()
    Route.separator(route,"ForkReturnBoundary",frame*CFrame.new(-104,-2.8,64),70,26)
    Route.separator(route,"EarlyToolFinishBoundary",frame*CFrame.new(-32,-2.8,125)*CFrame.Angles(0,math.pi/2,0),70,26)
    local fence=Kit.model(route,"StartFencing",frame)
    for _,line in {{-160,144,0,52},{-145,118,math.pi/2,30},{-145,170,math.pi/2,30}} do
        local cf=frame*CFrame.new(line[1],4.24,line[2])*CFrame.Angles(0,line[3],0)
        for _,y in {1.4,3.4} do Kit.box(fence,"StartRail",cf,V(0,y,0),V(.7,.6,line[4]),"honey","Blocker") end
        for i=0,math.floor(line[4]/7) do
            local z=-line[4]/2+i*line[4]/math.floor(line[4]/7)
            Kit.box(fence,"StartPost",cf,V(0,2.55,z),V(1.1,5.1,1.1),"timber","Blocker")
            Kit.stud(fence,cf*V(0,5.1,z),"honey",.62)
        end
    end
    local shop=path("Obstacles.G1_SeedShop.SeedShopLandmark")
    shop:PivotTo(shop:GetPivot()+V(0,7.04,0))
    local plinth=Kit.model(route,"RaisedSeedShopFloor",frame)
    Kit.box(plinth,"ShopFoundation",frame,V(-106,.7,182),V(30,7.08,17),"timber","Blocker")
    Kit.box(plinth,"ShopFloor",frame,V(-106,4.15,182),V(30,.18,17),"honey","Blocker")
    Kit.box(plinth,"StockFront",frame,V(-106,8.9,172.9),V(30,9.3,.8),"leaf","Blocker")
    local shopFront=Kit.box(plinth,"SuppliesFrontage",frame,V(-106,10.2,172.42),V(22,3.7,.18),"cream")
    Kit.label(shopFront,"SEEDS  &  SUPPLIES","dark")
    route.G1_SeedBenchThorns:Destroy()
    local function hurdle(name,cf,width,height)
        local m=Route.killHurdle(route,name,cf,width,height)
        table.insert(ledger.hazards,{name=name,kind="Kill",height=height,width=width})
        return m
    end
    hurdle("G1_CommonDeckThorns",frame*CFrame.new(-78,6.24,144)*CFrame.Angles(0,math.pi/2,0),48.4,1.7)
    hurdle("G1_SeedBenchThorns",frame*CFrame.new(-91,7.4,52)*CFrame.Angles(0,math.pi/2,0),18.4,2.1)
    hurdle("G2_BambooSouthThorns",crop.PlayableObjects.BambooSouth:GetPivot()+V(0,.4,0),17.8,2.25)
    hurdle("G2_BambooNorthThorns",crop.PlayableObjects.BambooNorth:GetPivot()+V(0,.4,0),17,2.25)
    for _,i in {1,4} do
        local m=path("Obstacles.G3_CandyGrove.GroveRoot_"..i)
        hurdle("G3_SporeRoot_"..i,m:GetPivot()+V(0,.4,0),14.5,1.2)
    end
    for _,i in {2,4} do
        local m=vine["BroadTurnLeaf_"..i]
        hurdle("G4_ThornLeaf_"..i,m:GetPivot()+V(0,.25,0),15.2,1.8)
    end
    hurdle("G5_FirstWagonThorns",frame*CFrame.new(70,8.24,111)*CFrame.Angles(0,math.pi/2,0),20.4,2.3)
    hurdle("G5_HarvestTableThorns",frame*CFrame.new(49,8.5,151)*CFrame.Angles(0,math.pi/2,0),22.4,2.35)
    for _,row in {
        {-90,6.35,132,V(1,0,0)},{-90,6.35,157,V(1,0,0)},
        {-61,4.34,22,V(0,0,-1)},{-53,7.35,-83,V(0,0,-1)},
        {-88,7.5,-94,V(-1,0,1)},{-89,7.5,-102,V(-1,0,-1)},
        {145,11.38,21,V(0,0,1)},{137,11.38,11,V(-1,0,0)},
        {128,8.35,-138,V(1,0,1)},{30,10.86,26,V(-1,0,1)},
        {35,8.36,87,V(1,0,1)},{150,8.36,126,V(0,0,1)},
        {129,8.99,153,V(-1,0,0)},{25,6.98,147,V(0,0,-1)},
    } do Kit.arrow(route,frame*V(row[1],row[2],row[3]),row[4],2.8,"cream") end
    for _,row in {
        {"StakesChoice",-91,12,-107,-90,"EXPERT\nPRECISION STAKES","gold"},
        {"MainCropChoice",-95,11.8,-84,-90,"MAIN ROUTE\nBAMBOO LOOP","cream"},
        {"TendrilChoice",135,15.3,1,-45,"EXPERT\nNARROW TENDRILS","gold"},
        {"MainVineChoice",155,15.3,23,135,"MAIN ROUTE\nAROUND THE STALK","cream"},
        {"MainThornNotice",-85,10.5,117,-90,"RED THORNS\nJUMP OVER","cream"},
    } do
        local cf=frame*CFrame.new(row[2],row[3],row[4])*CFrame.Angles(0,math.rad(row[5]),0)
        if row[1]=="StakesChoice" or row[1]=="MainCropChoice" then
            cf=CFrame.lookAt(frame*V(row[2],row[3],row[4]),frame*V(-89,row[3],-97))
        elseif row[1]=="TendrilChoice" or row[1]=="MainVineChoice" then
            cf=CFrame.lookAt(frame*V(row[2],row[3],row[4]),frame*V(144,row[3],15))
        end
        local p=Kit.box(route,row[1],cf,V(0,0,0),V(8,3.6,.5),row[7])
        Kit.label(p,row[6],"dark")
        Kit.label(p,row[6],"dark",Enum.NormalId.Back)
        Kit.box(route,row[1].."Post",cf,V(0,-2.6,0),V(.7,3.6,.7),"timber","Blocker")
    end
    local commonPath=root.RouteMarkers.G2_CommonExit
    for _,p in commonPath:GetChildren() do p:Destroy() end
    for index,p in {
        {-153,8.24,-126},{-149,8.24,-136},{-147,8.4,-153},{-137,8.4,-148},
        {-130,8.3,-146},{-125,8.3,-149.94},{-120,8.4,-146},{-109,8.2,-146},
        {-99,8.2,-146},{-89,9.5,-146},{-82,8.3,-146},{-77,8.3,-149.94},
        {-70,8.4,-146},{-59,8.4,-146},{-45,8.9,-146},{-37,10,-146},{-27,8.24,-142},{-18,8.24,-139},
    } do
        local marker=Kit.part(commonPath,string.format("Point_%03d",index),frame*CFrame.new(unpack(p)),V(1,1,1),"cream","Marker")
        marker.Transparency=1;marker:SetAttribute("Order",index)
    end
    for _,name in {"BasketFloor","BasketDisplayStand"} do
        local basket=path("Obstacles.G5_HarvestFestival."..name)
        basket:PivotTo(basket:GetPivot()+V(0,0,-4))
    end
    for _,index in {26,27,28} do
        local marker=root.RouteMarkers.G5_Festival[string.format("Point_%03d",index)]
        marker.CFrame+=V(0,0,-4)
    end
    root:SetAttribute("CandidateId","SGV2_Closing_C05_Route")
    root:SetAttribute("Phase","Closing course rebuild; disabled; runtime verification pending")
    ledger.geometryActions={"Six formed tools, both G2 tools reversed around their placed extent", "Crop merge enlarged westward with separate 20-slot pocket", "Four main bamboo landings reduced by 3-7 percent", "Four opening leaves reduced 2 percent; six main vine leaves reduced 6 percent", "Four stake caps 1.8 by 6.3; five expert leaves 2.3 by 11.3", "Ten warned kill hurdles using existing HazardType pattern"}
    return ledger
end
