return function(root, Kit)
    assert(root:GetAttribute("CandidateId") == "SGV2_StudStyle_S01", "S01 candidate required")
    local V, C = Vector3.new, CFrame.new
    local garden = root.StudGardenCompositions
    local function parts(model, name)
        local result = {}
        for _, p in model:GetDescendants() do
            if p:IsA("BasePart") and (not name or p.Name == name) then table.insert(result,p) end
        end
        return result
    end
    local function box(model,name,position,size,color,solid)
        local p=Kit.box(model,name,model:GetPivot(),position,size,color,if solid then "Blocker" else "Decoration")
        if size.X>=3 and size.Z>=3 then p.TopSurface=Enum.SurfaceType.Studs end
        return p
    end
    local function move(p,frame,position,size)
        p.CFrame=frame*C(position)
        p.Size=size
    end
    local function verticalCylinder(p,frame,position,height,width,depth)
        p.Shape=Enum.PartType.Cylinder
        p.CFrame=frame*C(position)*CFrame.Angles(0,0,math.pi/2)
        p.Size=V(height,width,depth)
        p.TopSurface=Enum.SurfaceType.Smooth
    end
    local potNames={TaperedFoot=true,PlanterLower=true,PlanterUpper=true,StuddedSoil=true,ThickRim=true,JoinedPotRib=true}
    for _,name in {"CentralNurseryPlanter","FinishGoldenSeed"} do
        local m=garden[name];local cf=m:GetPivot()
        for _,p in parts(m) do
            local localCf=cf:ToObjectSpace(p.CFrame)
            if potNames[p.Name] then
                p.CFrame=cf*C(localCf.Position*V(1,.105,1))*localCf.Rotation
                p.Size*=V(1,.105,1)
            elseif p.Name=="SubstantialJoinedStalk" then
                local a=cf:PointToObjectSpace(p.CFrame.Position-p.CFrame.RightVector*p.Size.X/2)
                local b=cf:PointToObjectSpace(p.CFrame.Position+p.CFrame.RightVector*p.Size.X/2)
                a=V(a.X,3,a.Z);b-=V(0,13,0)
                local axis=(b-a).Unit;local up=V(0,0,1):Cross(axis).Unit
                p.CFrame=cf*CFrame.fromMatrix((a+b)/2,axis,up,axis:Cross(up));p.Size=V((b-a).Magnitude,p.Size.Y,p.Size.Z)
            elseif name=="CentralNurseryPlanter" and (p.Name=="BroadSteppedLeaf" or p.Name=="JoinedLeafRib" or p.Name=="SquareStud") then
                p.CFrame-=V(0,13,0)
            elseif name=="FinishGoldenSeed" and localCf.Y>18 then
                p.CFrame-=V(0,19,0)
            end
        end
    end
    do
        local m=garden.EntryWateringCan;local cf=m:GetPivot()
        verticalCylinder(m.CanBody,cf,V(0,11,0),20,18,17)
        verticalCylinder(m.CanShoulder,cf,V(0,21,0),2,19,18)
        verticalCylinder(m.CanTop,cf,V(0,22.15,0),.5,17,16)
        move(m.DarkFillOpening,cf,V(-2,22.43,1),V(6,.15,6))
        for _,p in parts(m,"CanRaisedBand") do
            local pos=cf:PointToObjectSpace(p.CFrame.Position)
            verticalCylinder(p,cf,V(0,if pos.X<0 then 3 else 18,0),.6,18.5,17.5)
        end
        for _,p in parts(m) do
            if p.Name:find("Handle",1,true) or p.Name=="SquareStud" then p.CFrame-=V(0,4,0) end
        end
        local rose=m.SpoutRose
        for i=-1,1 do
            for j=-1,1 do
                local p=Kit.box(m,"RoseWaterHole",rose.CFrame,V(rose.Size.X/2+.015,i*1.6,j*1.6),V(.04,.7,.7),"dark")
                p.CastShadow=false
            end
        end
        box(m,"CanMakerBadge",V(0,12,-8.7),V(6,5,.25),"honey")
    end
    do
        local m=garden.GiantTurnipHarvest;local cf=m:GetPivot()
        for _,p in parts(m) do
            if p.Name=="TurnipBody" then p.Shape=Enum.PartType.Ball;p.Size*=V(1.1,.86,1.1)
            elseif p.Name=="TurnipRoot" then p.Shape=Enum.PartType.Ball;p.Size*=V(.65,1.4,.65)
            elseif p.Name=="TurnipShoulder" then
                local pos=cf:PointToObjectSpace(p.CFrame.Position);local s=p.Size.X/12
                verticalCylinder(p,cf,pos-V(0,2*s,0),4*s,13*s,13*s)
            elseif p.Name=="LeafCrown" or p.Name=="BroadSteppedLeaf" or p.Name=="JoinedLeafRib" or p.Name=="SquareStud" then p.CFrame-=V(0,2,0) end
        end
    end
    do
        local m=garden.CandyMushroomBed;local cf=m:GetPivot()
        for _,p in parts(m) do
            local pos=cf:PointToObjectSpace(p.CFrame.Position)
            if p.Name=="MushroomStem" then verticalCylinder(p,cf,pos,p.Size.Y,7,7)
            elseif p.Name=="SquareGilledCap" or p.Name=="SteppedCandyCap" or p.Name=="SteppedCandyCrown" then
                verticalCylinder(p,cf,pos,p.Size.Y,p.Size.X,p.Size.Z)
            end
        end
    end
    for _,name in {"GiantBeanPodCradle","FinishGoldenSeed"} do
        local m=garden[name]
        for _,p in parts(m) do
            if p.Name=="PodBody" or p.Name=="PodShoulder" or p.Name=="PodHeel" then p.Shape=Enum.PartType.Ball
            elseif p.Name=="PodRaisedSeed" then p.Shape=Enum.PartType.Ball;p.Size=V(p.Size.X,p.Size.Y,2.2)
            elseif p.Name=="PodTip" then p.Shape=Enum.PartType.Ball end
        end
    end
    do
        local m=garden.HarvestGlasshouse;local cf=m:GetPivot()
        for _,p in parts(m) do
            local lc=cf:ToObjectSpace(p.CFrame)
            p.CFrame=cf*C(lc.Position*V(1,.66,1))*lc.Rotation
            p.Size*=V(1,.66,1)
            if p.Name=="FrontWindowBay" then
                p.CFrame+=cf.LookVector*-3.6;p.Color=Color3.fromRGB(103,178,169)
                if math.abs(lc.X)<1 then p.Color=Kit.colors.dark end
            elseif p.Name=="BroadSteppedLeaf" or p.Name=="JoinedLeafRib" then p.CFrame+=cf.LookVector*-2.9 end
        end
        box(m,"DoorSlab",V(0,8,-5.8),V(7.7,13,1.1),"teal",true)
        box(m,"DoorInset",V(0,10,-6.39),V(5.5,6,.15),"aqua")
        box(m,"DoorHandle",V(2.6,6,-6.7),V(.6,1.7,.55),"honey")
        box(m,"DoorLintel",V(0,16.2,-7),V(9,1.2,4.4),"honey")
        for _,x in {-4.4,4.4} do box(m,"DeepDoorJamb",V(x,8.3,-7),V(.8,15.4,4.4),"cream") end
        for _,x in {-20,-10,10,20} do
            box(m,"DeepWindowSill",V(x,5.8,-6.9),V(8.5,.65,4),"honey")
            box(m,"InteriorPot",V(x,7,-5.1),V(4,2,3.3),"terra")
            Kit.leaf(m,"WindowFern",cf*C(x,8,-5.2)*CFrame.Angles(math.rad(-65),0,0),7,4,"grass")
        end
        local sign=box(m,"NurserySign",V(0,23.5,-11.65),V(19,3.7,.4),"teal")
        Kit.label(sign,"SEED HOUSE","cream")
    end
    do
        local m=root.CreativeGardenBoundaries.ForkToolCaddy;local cf=m:GetPivot()
        for _,p in parts(m) do
            if p.Name~="ToolRestBelowRoute" then
                local lc=cf:ToObjectSpace(p.CFrame)
                p.CFrame=cf*C(lc.Position*V(1,.72,1))*lc.Rotation;p.Size*=V(1,.72,1)
            end
        end
        for _,p in parts(m,"SteppedBladeShoulder") do
            local pos=cf:PointToObjectSpace(p.CFrame.Position)
            p.Size=V(3.6,p.Size.Y+2,.8)
            local a,b,c=V(pos.X-5.4,pos.Y-1.22,0),V(pos.X+5.4,pos.Y-1.22,0),V(pos.X,pos.Y+3,0)
            Kit.triangle(m,"SlopedSpadeShoulder",cf*a,cf*b,cf*c,.78,"steel","Blocker")
        end
        for _,p in parts(m,"ForgedSpadeBlade") do
            local pos=cf:PointToObjectSpace(p.CFrame.Position)
            for _,side in {-1,1} do
                local trim=box(m,"RolledBladeEdge",V(pos.X+side*5.2,pos.Y,.45),V(.3,p.Size.Y,.22),"steelLight")
                trim.CastShadow=false
            end
        end
    end
    for _,name in {"ForkRosemaryClump","MarketRhubarbClump"} do
        local m=root.CreativeGardenBoundaries[name];local cf=m:GetPivot()
        for _,p in parts(m) do
            local lc=cf:ToObjectSpace(p.CFrame)
            local scale=if name=="ForkRosemaryClump" then .8 else .78
            p.CFrame=cf*C(lc.Position*V(1,scale,1))*lc.Rotation;p.Size*=V(1,scale,1)
            if p.Name=="LeafShoulder" or p.Name=="RhubarbShoulder" then
                local pos=cf:PointToObjectSpace(p.CFrame.Position);local width=p.Size.X+2
                Kit.triangle(m,"PointedLivingLeaf",cf*V(pos.X-width/2,pos.Y-1,0),cf*V(pos.X+width/2,pos.Y-1,0),cf*V(pos.X+1,pos.Y+6,0),p.Size.Z,"grass","Decoration")
            end
        end
    end
    garden:SetAttribute("ArtRevision","S02")
    root:SetAttribute("CandidateId","SGV2_StudStyle_S02")
    return {revision="S02",lowerPlantedBases=2,reshapedCompositions=6,recessedGlasshouse=true}
end
