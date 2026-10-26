return function(Kit)
    local Scenery={}
    local V=Vector3.new
    local function chain(parent,name,points,radius,color,role)
        for i=1,#points-1 do
            local direction=(points[i+1]-points[i]).Unit
            Kit.rod(parent,name..i,points[i]-direction*.22,points[i+1]+direction*.22,radius*(1-(i-1)*.045),color,role)
        end
    end
    local function bloom(parent,frame,radius,color,inner)
        for i=1,6 do
            local a,b=(i-1)*math.pi/3,i*math.pi/3
            local p1=V(math.cos(a)*radius*.24,-1,math.sin(a)*radius*.24)
            local p2=V(math.cos(b)*radius*.24,-1,math.sin(b)*radius*.24)
            local p3=V(math.cos(b)*radius,2.7,math.sin(b)*radius)
            local p4=V(math.cos(a)*radius,2.7,math.sin(a)*radius)
            Kit.quad(parent,"FlowerCupPetal_"..i,frame,p1,p2,p3,p4,.75,if i%2==0 then inner else color,"Decoration")
            Kit.rod(parent,"FlowerRolledRim",frame*p3,frame*p4,.5,color)
            Kit.stud(parent,frame*((p3+p4)/2+V(0,.6,0)),inner,.62)
        end
        Kit.part(parent,"PollenGlobe",frame*CFrame.new(0,.5,0),V(5,5,5),"gold",nil,"Ball")
        for i=1,5 do
            local angle=i*math.pi*.4
            local a=frame*V(math.cos(angle)*2,.5,math.sin(angle)*2)
            local b=frame*V(math.cos(angle)*2.5,5.5,math.sin(angle)*2.5)
            Kit.rod(parent,"PollenFilament",a,b,.16,"cream")
            Kit.part(parent,"PollenBead",CFrame.new(b),V(1.2,1.2,1.2),"pinkLight",nil,"Ball")
        end
    end
    function Scenery.grove(parent,name,frame,height,lean)
        local m=Kit.model(parent,name,frame)
        m:SetAttribute("AssetFamily","StrangeBotanicalCanopy")
        local function p(x,y,z)return frame*V(x,y,z)end
        chain(m,"SegmentedStem",{p(0,0,0),p(0,19,0),p(lean*.30,28,3),p(lean*.75,height-7,6),p(lean,height,9)},2.15,"pinkDark","Blocker")
        bloom(m,frame*CFrame.new(lean,height,9)*CFrame.Angles(.08,.3,-.12),12.3,"pink","aqua")
        chain(m,"ForkedStem",{p(0,17,0),p(-5,27,-1),p(-9,height-8,-4)},1.35,"pink","Blocker")
        bloom(m,frame*CFrame.new(-9,height-8,-4)*CFrame.Angles(-.1,.8,.17),7.7,"aqua","pinkLight")
        for i=1,3 do
            local a=i*2.094
            chain(m,"LowRoot",{p(0,-1,0),p(math.cos(a)*7,-1.2,math.sin(a)*7),p(math.cos(a+.15)*13,-1.6,math.sin(a+.15)*13)},1.3,"pinkDark","Blocker")
        end
        for i=1,3 do
            local cf=frame*CFrame.new(lean+math.cos(i*2)*8,height-1,9+math.sin(i*2)*8)
            Kit.rod(m,"HangingPodStem",cf*V(0,0,0),cf*V(0,-7.6,0),.25,"pinkDark")
            for j=1,3 do
                Kit.part(m,"HangingSeedPod",cf*CFrame.new(0,-7-j*1.7,0),V(2.6,2.6,2.6),if j==2 then "aqua" else "pinkLight",nil,"Ball")
            end
        end
        return m
    end
    function Scenery.beanstalk(parent,frame)
        local m=Kit.model(parent,"GreatTwistingBeanstalk",frame)
        m:SetAttribute("AssetFamily","DominantTwistingBeanstalk")
        m:SetAttribute("IntendedHeight",108)
        m:SetAttribute("CanopyRule","First broad scenery leaf above 30 studs; main and expert leaves remain separate supported objects")
        for strand=1,3 do
            local previous
            for i=0,18 do
                local t=i/18
                local angle=t*math.pi*2.05+strand*math.pi*2/3
                local point=frame*V(math.sin(angle)*6,108*t,math.cos(angle)*6)
                if previous then
                    local direction=(point-previous).Unit
                    Kit.rod(m,"TwistedStem_"..strand.."_"..i,previous-direction*.55,point+direction*.55,5.4-t*2.7,if strand==1 then "grass" elseif strand==2 then "leaf" else "lime","Blocker")
                end
                previous=point
            end
        end
        for i=1,7 do
            local a=i*math.pi*2/7
            local points={frame*V(math.cos(a)*4,-.5,math.sin(a)*4),frame*V(math.cos(a)*16,-1.15,math.sin(a)*16),frame*V(math.cos(a+.1)*29,-1.7,math.sin(a+.1)*29)}
            chain(m,"GroundedRoot",points,1.45,"leaf","Blocker")
        end
        for i=1,10 do
            local a=math.rad(-120+i*137.5)
            local radial=V(math.sin(a),0,math.cos(a))
            local height=29+i*7.2
            local base=V(radial.X*7,height,radial.Z*7)
            local tip=V(radial.X*14,height+2.5,radial.Z*14)
            Kit.rod(m,"LeafPetiole_"..i,frame*base,frame*tip,1.2,"leaf")
            local leafFrame=CFrame.lookAt(frame*tip,frame*(tip+radial))*CFrame.Angles(math.rad(-9),0,math.rad((i%3-1)*8))
            Kit.leaf(m,"GiantCanopyLeaf_"..i,leafFrame,if i<7 then 31 else 25,if i<7 then 22 else 18,if i%3==0 then "grass" else "leaf")
            for _,r in {.27,.57} do Kit.stud(m,leafFrame*V(0,1.0,-(if i<7 then 31 else 25)*r),"lime",1.25) end
            if i%2==0 then
                local pod=frame*(tip+radial*5+V(0,-3,0))
                Kit.rod(m,"BeanPodStem",frame*tip,pod,.45,"leaf")
                Kit.rod(m,"BeanPodShell",pod,pod-V(0,13,0),2.5,"grass")
                for j=1,4 do
                    Kit.part(m,"VisiblePea",CFrame.new(pod+radial*1.7-V(0,j*2.7,0)),V(3.5,3.5,3.5),"lime",nil,"Ball")
                end
                Kit.rod(m,"BeanPodSeam",pod+radial*2.8,pod+radial*2.8-V(0,13,0),.18,"cream")
            end
        end
        for i=1,3 do
            local previous
            for j=0,9 do
                local a=j*.34
                local point=frame*V(10+math.cos(a)*8,41+i*13+math.sin(a)*7,-7-i*2)
                if previous then Kit.rod(m,"CurledTendril",previous,point,.5,"lime") end
                previous=point
            end
        end
        return m
    end
    function Scenery.bambooBoundary(parent,frame)
        local m=Kit.model(parent,"BambooBranchBoundary",frame)
        Kit.box(m,"DensePlantedScreen",frame,V(0,10.5,0),V(38,26,1.6),"leaf","Blocker")
        for i=1,12 do
            local x=(i-6.5)*3.25
            local h=27+(i%3)*2.5
            Kit.rod(m,"TallBamboo",frame*V(x,-2.8,0),frame*V(x,h,0),.83,if i%2==0 then "grass" else "lime","Blocker")
            for y=4,h-2,6 do
                Kit.rod(m,"BambooNode",frame*V(x,y-.2,0),frame*V(x,y+.2,0),.96,"leaf")
            end
            if i%3==0 then
                for _,s in {-1,1} do Kit.leaf(m,"BambooCrownLeaf",frame*CFrame.new(x,h-1,0)*CFrame.Angles(-.45,s*.9,0),8,3.2,"grass") end
            end
        end
        return m
    end
    function Scenery.crate(parent,name,frame,width,depth,height,color)
        local m=Kit.model(parent,name,frame)
        Kit.box(m,"CrateFloor",frame,V(0,.3,0),V(width,.6,depth),"timber","Blocker")
        for _,s in {-1,1} do
            for _,r in {.22,.64} do
                Kit.box(m,"SideSlat",frame,V(s*(width/2-.2),height*r,0),V(.4,height*.29,depth),color or "honey","Blocker")
                Kit.box(m,"EndSlat",frame,V(0,height*r,s*(depth/2-.2)),V(width,height*.29,.4),color or "honey","Blocker")
            end
            for _,z in {-1,1} do Kit.box(m,"CornerPost",frame,V(s*(width/2-.35),height/2,z*(depth/2-.35)),V(.7,height,.7),"timber","Blocker") end
        end
        return m
    end
    function Scenery.produce(parent,frame,kind,count)
        for i=1,count do
            local x=((i-1)%3-1)*1.35
            local z=(math.floor((i-1)/3)-.5)*1.3
            local color=if kind=="Apple" then "coral" elseif kind=="Pumpkin" then "orange" else "lime"
            local diameter=if kind=="Pumpkin" then 2.6 else 1.5
            local pos=frame*V(x,diameter*.5,z)
            Kit.part(parent,kind,CFrame.new(pos),V(diameter,diameter,diameter),color,nil,"Ball")
            Kit.rod(parent,"ProduceStem",pos+V(0,diameter*.4,0),pos+V(.15,diameter*.7,0),.12,"leaf")
        end
    end
    function Scenery.wagon(root,name,model,origin)
        local frame=model:GetPivot()
        local m=Kit.model(root,name,frame)
        local westExit=model.Name=="LongHarvestWagon"
        local wheelY=origin.Y+1.6-frame.Position.Y
        for _,old in model:GetDescendants() do
            if old:IsA("BasePart") and (old.Name=="Wheel" or old.Name=="WheelHub" or old.Name=="DisplayWheelStand" or old.Name=="SideRail" or old.Name=="Upright") then old:Destroy() end
        end
        for _,z in {-9,9} do
            Kit.rod(m,"Axle",frame*V(-12,wheelY,z),frame*V(12,wheelY,z),.6,"edge","Blocker")
            Kit.box(m,"AxleBolster",frame,V(0,wheelY+1.0,z),V(5,2.8,3.6),"edge","Blocker")
            for _,s in {-1,1} do
                Kit.rod(m,"LargeWagonTire",frame*V(s*11-.8,wheelY,z),frame*V(s*11+.8,wheelY,z),4.4,"soil","Blocker")
                Kit.rod(m,"WheelWoodDisc",frame*V(s*12-.16,wheelY,z),frame*V(s*12+.16,wheelY,z),3.6,"honey")
                Kit.rod(m,"WheelHub",frame*V(s*12-.35,wheelY,z),frame*V(s*12+.35,wheelY,z),.9,"edge")
                for i=1,6 do
                    local a=i*math.pi/3
                    Kit.rod(m,"WheelSpoke",frame*V(s*12.2,wheelY,z),frame*V(s*12.2,wheelY+math.cos(a)*3.5,z+math.sin(a)*3.5),.19,"timber")
                end
            end
        end
        for _,s in {-1,1} do
            local exitSide=westExit and s==1
            for _,y in {6.2,7.55} do
                Kit.box(m,"CargoSideSlat",frame,V(s*10.75,y,if exitSide then 1.5 else -1),V(.75,.9,if exitSide then 9 else 15),"honey","Blocker")
            end
            for _,z in (if exitSide then {0,6} else {-8,0,6}) do
                Kit.box(m,"CargoUpright",frame,V(s*10.75,6.8,z),V(.85,4.2,.85),"timber","Blocker")
            end
        end
        for i,z in {-5,3} do
            local cf=frame*CFrame.new(if westExit then -7.8 else 7.8,5.4,z)
            local box=Scenery.crate(m,"HarvestCargo_"..i,cf,4.2,5,3,"honey")
            Scenery.produce(box,cf*CFrame.new(0,1.7,0),if i==1 then "Apple" else "Pumpkin",6)
        end
        Kit.box(m,"UndercarriageBeam",frame,V(0,2.6,0),V(2.2,4.8,25),"timber","Blocker")
        return m
    end
    function Scenery.wheelbarrow(parent,frame)
        local m=Kit.model(parent,"LoadedMarketWheelbarrow",frame)
        Kit.box(m,"TrayFloor",frame,V(0,5,0),V(10,1,15),"steel","Blocker")
        for _,s in {-1,1} do
            Kit.quad(m,"ScoopedTubWall",frame,V(s*5,5,7),V(s*5,5,-7),V(s*8.5,10,-10),V(s*8.5,10,9),.8,"teal","Blocker")
            Kit.rod(m,"RolledTubRim",frame*V(s*8.5,10,-10),frame*V(s*8.5,10,9),.55,"steelLight","Blocker")
            Kit.rod(m,"LongBarrowHandle",frame*V(s*5,4,-5),frame*V(s*6,7,22),.85,"timber","Blocker")
            Kit.rod(m,"BarrowGrip",frame*V(s*6,7,18),frame*V(s*6,7,23),1.1,"honey","Blocker")
            Kit.rod(m,"ParkingLeg",frame*V(s*4,0,7),frame*V(s*5,5,4),.7,"edge","Blocker")
        end
        Kit.quad(m,"TubFront",frame,V(-5,5,-7),V(5,5,-7),V(8.5,10,-10),V(-8.5,10,-10),.8,"teal","Blocker")
        Kit.quad(m,"TubBack",frame,V(-5,5,7),V(5,5,7),V(8.5,10,9),V(-8.5,10,9),.8,"teal","Blocker")
        Kit.rod(m,"BarrowAxle",frame*V(-3,3.6,-11),frame*V(3,3.6,-11),.55,"edge","Blocker")
        Kit.rod(m,"SingleTire",frame*V(-1.1,3.6,-11),frame*V(1.1,3.6,-11),3.6,"soil","Blocker")
        Kit.rod(m,"WheelHub",frame*V(-1.2,3.6,-11),frame*V(1.2,3.6,-11),1.15,"honey")
        for _,p in {{-3,6,-4},{3,6,-3},{0,7,2},{-3,6.4,5}} do
            local pos=frame*V(unpack(p))
            Kit.part(m,"HarvestPumpkin",CFrame.new(pos),V(5,5,5),"orange",nil,"Ball")
            Kit.rod(m,"PumpkinStem",pos+V(0,2,0),pos+V(.3,3.5,0),.35,"leaf")
        end
        return m
    end
    function Scenery.stall(parent,name,frame,width,color,text)
        local m=Kit.model(parent,name,frame)
        Kit.box(m,"StallFloor",frame,V(0,.4,0),V(width,1,13),"honey","Blocker")
        Kit.box(m,"Plinth",frame,V(0,-2.4,0),V(width,4.8,13),"timber","Blocker")
        for _,s in {-1,1} do
            for _,z in {-1,1} do Kit.box(m,"CanopyPost",frame,V(s*(width/2-.65),7,z*5.3),V(1.1,14,1.1),"timber","Blocker") end
        end
        local count=math.ceil(width/3.5)
        for i=1,count do
            local x=(i-(count+1)/2)*width/count
            for _,s in {-1,1} do
                Kit.box(m,"PitchedAwningStripe",frame,V(x,15,s*3.4),V(width/count+.02,.55,7.8),if i%2==0 then "cream" else color,nil,CFrame.Angles(-s*.22,0,0))
            end
            Kit.box(m,"ScallopedValance",frame,V(x,13.2,-7.3),V(width/count+.03,1.7,.5),if i%2==0 then "cream" else color)
        end
        Kit.box(m,"CounterBody",frame,V(0,3.8,-4.2),V(width-2,6.8,4),color,"Blocker")
        Kit.box(m,"CounterTop",frame,V(0,7.3,-4.2),V(width-1,.6,4.4),"honey","Blocker")
        local board=Kit.box(m,"ProduceSign",frame,V(0,10,-6.5),V(width-4,3,.45),"cream")
        Kit.label(board,text,"dark")
        for i=1,3 do
            local cf=frame*CFrame.new((i-2)*(width-3)/3,7.6,-4.2)
            local crate=Scenery.crate(m,"ProduceBasket_"..i,cf,(width-4)/3,3,1.7,"honey")
            Scenery.produce(crate,cf*CFrame.new(0,.7,0),if i==2 then "Apple" else "Pumpkin",3)
        end
        return m
    end
    return Scenery
end
