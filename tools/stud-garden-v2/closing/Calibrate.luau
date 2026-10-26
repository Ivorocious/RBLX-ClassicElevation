return function(root,Kit,Tools,Route)
    local origin=root:GetPivot().Position
    local frame=CFrame.new(origin)
    local obstacles=root.Obstacles.G1_SeedShop
    assert(not root:FindFirstChild("ClosingRoute"),"Calibration already installed")
    local old=obstacles.TrowelClimb
    local new=Tools.build(nil,"TrowelClimb",old:GetPivot(),"Trowel")
    local route=Kit.model(nil,"ClosingRoute",frame)
    Route.checkpoint(route,root.Checkpoints.Checkpoint_001,1,origin.Y+7.3,origin,Vector3.xAxis,-Vector3.zAxis)
    Route.separator(route,"ForkReturnBoundary",frame*CFrame.new(-104, -2.8,64),70,26)
    Route.killHurdle(route,"G1_SeedBenchThorns",frame*CFrame.new(-91,7.4,51)*CFrame.Angles(0,math.pi/2,0),17,2.1)
    local warning=Kit.box(route,"G1ThornWarning",frame,Vector3.new(-103,10.5,61.8),Vector3.new(6,3,.5),"cream",nil,CFrame.Angles(0,-math.pi/2,0))
    Kit.label(warning,"RED THORNS\nJUMP","coral")
    new.Parent=obstacles
    old:Destroy()
    route.Parent=root
    root.Decoration.VisibleCheckpoint_01:Destroy()
    local delta=origin-root:GetAttribute("CourseOrigin")
    local translated=0
    for _,object in {root,unpack(root:GetDescendants())} do
        for key,value in object:GetAttributes() do
            if key=="RespawnCFrame" then object:SetAttribute(key,CFrame.new(delta)*value);translated+=1
            elseif key=="CourseOrigin" then object:SetAttribute(key,value+delta) end
        end
    end
    root:SetAttribute("CandidateId","SGV2_Closing_C01_Sample")
    root:SetAttribute("Phase","Closing calibration; disabled; static checks pending")
    return {translatedRespawns=translated,toolParts=#new:GetDescendants(),routeObjects=#route:GetDescendants()}
end
