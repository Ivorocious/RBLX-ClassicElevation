return function(Kit)
    local Route={}
    function Route.checkpoint(parent,trigger,index,top,origin,incoming,outgoing)
        local position=trigger.CFrame.Position
        local m=Kit.model(parent,"CheckpointGate_"..string.format("%02d",index),CFrame.new(position))
        m:SetAttribute("CheckpointIndex",index)
        m:SetAttribute("StatePresentation","Number identifies checkpoint; personal claimed state remains owned by existing HUD")
        local x,z=position.X,position.Z
        local axes=trigger.CFrame
        local sx=math.abs(axes.XVector.X)*trigger.Size.X+math.abs(axes.ZVector.X)*trigger.Size.Z
        local sz=math.abs(axes.XVector.Z)*trigger.Size.X+math.abs(axes.ZVector.Z)*trigger.Size.Z
        local cf=CFrame.new(x,top,z)
        for _,s in {-1,1} do
            Kit.box(m,"InsetSide",cf,Vector3.new(s*(sx/2-.6),.03,0),Vector3.new(.9,.06,sz-.5),"cream")
            Kit.box(m,"InsetEnd",cf,Vector3.new(0,.03,s*(sz/2-.6)),Vector3.new(sx-1,.06,.9),"cream")
        end
        local facing=Vector3.new(incoming.X,0,incoming.Z).Unit
        local side=Vector3.new(-facing.Z,0,facing.X)
        local width=math.abs(side.X)*sx+math.abs(side.Z)*sz
        local depth=math.abs(facing.X)*sx+math.abs(facing.Z)*sz
        -- The vine arrives diagonally past the near corner.
        local gateCenter=Vector3.new(x,top,z)+facing*(if index==8 then 0 else depth*.40)
        local gateFrame=CFrame.lookAt(gateCenter,gateCenter+facing)
        local supportDepth=top-origin.Y+2.8
        for _,s in {-1,1} do
            Kit.box(m,"NumberedGatePost",gateFrame,Vector3.new(s*(width/2+.6),7-supportDepth/2,0),Vector3.new(1.35,14+supportDepth,1.35),"teal","Blocker")
            Kit.box(m,"PostSock",gateFrame,Vector3.new(s*(width/2+.6),2,0),Vector3.new(1.65,4,1.65),"cream","Blocker")
            Kit.box(m,"GateCap",gateFrame,Vector3.new(s*(width/2+.6),14.6,0),Vector3.new(2.2,.8,2.2),"gold","Blocker")
        end
        Kit.box(m,"RaisedLintel",gateFrame,Vector3.new(0,14.2,0),Vector3.new(width+2.5,1.4,1.1),"teal","Blocker")
        -- Offset the two hazard-exit numbers from the earlier WAIT boards.
        local boardOffset=if index==3 or index==6 then 12 else 0
        local board=Kit.box(m,"CheckpointNumber",gateFrame,Vector3.new(boardOffset,17.6,0),Vector3.new(10,5,.45),"cream")
        for _,s in {-1,1} do
            Kit.box(m,"NumberBoardMount",gateFrame,Vector3.new(boardOffset+s*3,15.0,0),Vector3.new(.4,.8,.35),"teal")
        end
        Kit.label(board,string.format("%02d",index).."\nCHECKPOINT","dark")
        Kit.label(board,string.format("%02d",index).."\nCHECKPOINT","dark",Enum.NormalId.Back)
        Kit.arrow(m,Vector3.new(x,top+.12,z)+outgoing.Unit*(math.min(sx,sz)*.30),outgoing,3.4,"cream")
        return m
    end
    function Route.separator(parent,name,frame,length,height)
        local m=Kit.model(parent,name,frame)
        m:SetAttribute("Purpose","Screens adjacent later route; tall continuous wall prevents a cross-lane landing")
        Kit.box(m,"PlantedTimberBoundary",frame,Vector3.new(0,height/2,0),Vector3.new(length,height,1.7),"timber","Blocker")
        for i=0,math.floor(length/7) do
            local x=-length/2+i*length/math.floor(length/7)
            Kit.box(m,"TrellisUpright",frame,Vector3.new(x,height/2,0),Vector3.new(.7,height+1,2),"honey","Blocker")
        end
        for _,s in {-1,1} do
            for row=1,3 do
                local y=height*(.20+.25*(row-1))
                Kit.box(m,"GardenTrellisRail",frame,Vector3.new(0,y,s*1.04),Vector3.new(length,.4,.35),"honey")
            end
            for i=1,math.floor(length/12) do
                local x=(i-(math.floor(length/12)+1)/2)*12
                Kit.rod(m,"ClimbingStem",frame*Vector3.new(x,3,s*1.2),frame*Vector3.new(x+1,height-2,s*1.2),.22,"leaf")
                for row=1,2 do
                    local cf=frame*CFrame.new(x+(row%2-.5)*1.5,height*(.19+.29*row),s*1.4)*CFrame.Angles(s*math.pi/2,0,(if row%2==0 then .65 else -.65))
                    Kit.triangle(m,"ClimbingLeaf",cf*Vector3.new(-1.5,0,0),cf*Vector3.new(1.5,0,0),cf*Vector3.new(0,.12,-6),.2,if (i+row)%3==0 then "lime" else "leaf","Decoration")
                end
            end
        end
        return m
    end
    function Route.racingLeaf(parent,name,frame,width,length)
        local m=Kit.model(parent,name,frame)
        m:SetAttribute("AssetFamily","ExpertLeaf")
        m:SetAttribute("MovementIntent","Very narrow pointed landing; deliberate precision sequence; gameplay verification pending")
        local outline={{0,-.5},{.35,-.35},{.5,-.02},{.37,.3},{0,.5},{-.37,.3},{-.5,-.02},{-.35,-.35}}
        for i,a in outline do
            local b=outline[i%#outline+1]
            Kit.triangle(m,"BladeFacet_"..i,frame.Position,frame*Vector3.new(a[1]*width,0,a[2]*length),frame*Vector3.new(b[1]*width,0,b[2]*length),.5,if i%3==0 then "gold" else "lime","Walk")
        end
        Kit.box(m,"ExpertMidrib",frame,Vector3.new(0,.28,0),Vector3.new(.24,.07,length*.74),"gold")
        return m
    end
    function Route.killHurdle(parent,name,frame,width,height)
        local m=Kit.model(parent,name,frame)
        m:SetAttribute("PalettePattern","05_RedHurdles; existing CourseHazardService HazardType=Kill")
        local p=Kit.box(m,"RedThornCrossbar",frame,Vector3.new(0,height/2,0),Vector3.new(width,height,1.7),"coral","Hazard")
        p.CanCollide=true; p.CanQuery=true; p:SetAttribute("HazardType","Kill")
        for i=1,math.floor(width/2.7) do
            Kit.box(m,"WarningBand",frame,Vector3.new((i-(math.floor(width/2.7)+1)/2)*2.7,height+.045,0),Vector3.new(.75,.07,1.73),"cream")
        end
        for _,s in {-1,1} do
            Kit.box(m,"ThornPost",frame,Vector3.new(s*(width/2+.45),height*.55,0),Vector3.new(.7,height+1,.8),"dark","Blocker")
        end
        return m
    end
    return Route
end
