return function(Kit)
    local Tools={}
    function Tools.build(parent,name,frame,kind)
        local m=Kit.model(parent,name,frame)
        m:SetAttribute("AssetFamily","ClosingForged"..kind)
        m:SetAttribute("Mount","Blade points -Z, open D grip +Z; formed bowl uses visible solid facets")
        local function b(n,p,s,c,r,rot) return Kit.box(m,n,frame,Vector3.new(unpack(p)),Vector3.new(unpack(s)),c,r,rot) end
        local function rod(n,a,d,r,c,role,rz) return Kit.rod(m,n,frame*Vector3.new(unpack(a)),frame*Vector3.new(unpack(d)),r,c,role,rz) end
        if kind=="Trowel" then
            local rows={{4,5.1,-.55},{0,8.8,-.7},{-9,9.2,-.45},{-16,5.8,.35},{-22,.25,1.15}}
            for row=1,#rows-1 do
                local a,d=rows[row],rows[row+1]
                local function at(r,t) return Vector3.new(r[2]*t,r[3]+(math.abs(t)^2)*2.65,r[1]) end
                for band=1,4 do
                    local t1,t2=(band-3)*.5,(band-2)*.5
                    Kit.quad(m,"BowlPanel"..row.."_"..band,frame,at(a,t1),at(a,t2),at(d,t2),at(d,t1),.85,if band==1 or band==4 then "steel" else "steelLight","Walk")
                end
                for _,s in {-1,1} do Kit.rod(m,"RolledCuttingLip",frame*at(a,s),frame*at(d,s),.42,"edge","Walk") end
            end
            rod("EmbossedSpine",{0,-.9,3},{0,-.2,-14},.38,"edge")
        else
            b("ForgedShoulder",{0,.05,-3},{22,2.3,5.5},"edge","Walk")
            for index=-1,1 do
                local x=index*8
                local rows={{-5.5,2.5,.1},{-12.5,2.35,.05},{-18,1.65,.8},{-23,.32,2.1}}
                for i=1,#rows-1 do
                    local a,d=rows[i],rows[i+1]
                    Kit.quad(m,"ForgedTine"..index.."_"..i,frame,Vector3.new(x-a[2],a[3],a[1]),Vector3.new(x+a[2],a[3],a[1]),Vector3.new(x+d[2],d[3],d[1]),Vector3.new(x-d[2],d[3],d[1]),1.5,"steel","Walk")
                    rod("TineCrest",{x,a[3]+.8,a[1]},{x,d[3]+.8,d[1]},.2,"steelLight")
                end
            end
            for _,s in {-1,1} do rod("ShoulderRoll",{s*10,.3,-4},{s*4,-.2,6},.85,"edge","Walk") end
        end
        Kit.quad(m,"ForgedSocketFlare",frame,Vector3.new(-5,-.3,2),Vector3.new(5,-.3,2),Vector3.new(3,-.9,11),Vector3.new(-3,-.9,11),1.5,"edge","Walk")
        b("PressedSocketCore",{0,-1.15,9},{4,3.6,6},"edge","Walk")
        b("AshShaftCore",{0,-1.25,17.1},{6,3.3,13.2},"honey","Walk")
        for _,s in {-1,1} do
            rod("SocketRound",{s*2,-1.15,6},{s*2,-1.15,12},1.8,"edge","Walk")
            rod("AshShaftRound",{s*3,-1.25,10.5},{s*3,-1.25,23.7},1.65,"honey","Walk")
        end
        for _,z in {10.9,12.1,22.8} do b("Ferrule",{0,-1.25,z},{9.4,3.65,.45},"edge","Walk") end
        for _,s in {-1,1} do
            rod("GripFlare",{s*2.8,-1.2,22},{s*4.8,-1.2,25},1.5,"timber","Walk")
            rod("GripSide",{s*4.8,-1.2,25},{s*4.8,-1.2,29.6},1.5,"honey","Walk")
            Kit.part(m,"GripCorner",frame*CFrame.new(s*4.8,-1.2,29.6),Vector3.new(3,3,3),"honey","Walk","Ball")
            Kit.part(m,"SocketRivet",frame*CFrame.new(s*2.5,.45,9.8),Vector3.new(.9,.45,.9),"steelLight")
        end
        rod("GripCrossbar",{-4.8,-1.2,29.6},{4.8,-1.2,29.6},1.5,"honey","Walk")
        for _,x in {-2.8,-1.4,0,1.4,2.8} do rod("GripGroove",{x,-1.2,29.6-.04},{x+.08,-1.2,29.6-.04},1.52,"timber") end
        for _,z in {-6,17} do
            local top=frame*Vector3.new(0,-2.7,z)
            local bottom=Vector3.new(top.X,frame.Position.Y-8,top.Z)
            Kit.part(m,"ToolDisplayStand",CFrame.new((top+bottom)/2)*frame.Rotation,Vector3.new(5,(top-bottom).Magnitude,2),"timber","Blocker")
        end
        return m
    end
    return Tools
end
