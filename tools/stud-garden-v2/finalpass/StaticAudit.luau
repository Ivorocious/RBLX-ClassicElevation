return function(root,Geometry,Motion)
    local out={candidate=root:GetAttribute("CandidateId"),slots=0,moving={},giantParts=0,giantPhysicsParts=0,scriptCount=0,unanchored=0}
    local slots={}
    for _,cp in root.Checkpoints:GetChildren() do
        local f,area=cp:GetAttribute("RespawnCFrame"),cp:GetAttribute("RespawnAreaSize")
        assert(typeof(f)=="CFrame" and typeof(area)=="Vector3")
        local cols=math.max(1,1+math.floor((area.X-3)/4.5))
        local rows=math.max(1,1+math.floor((area.Z-3)/4.5))
        for i=0,math.min(20,cols*rows)-1 do
            local x=(i%cols-(cols-1)/2)*4.5
            local z=(math.floor(i/cols)-(rows-1)/2)*4.5
            table.insert(slots,{name=cp.Name..":"..i,cf=f*CFrame.new(x,-.7,z)})
        end
    end
    out.slots=#slots
    for _,p in root:GetDescendants() do
        if p:IsA("LuaSourceContainer") then out.scriptCount+=1 end
        if p:IsA("BasePart") and not p.Anchored then out.unanchored+=1 end
    end
    for _,p in root.GardenGiants:GetDescendants() do
        if p:IsA("BasePart") then
            out.giantParts+=1
            if p.CanCollide or p.CanTouch or p.CanQuery then out.giantPhysicsParts+=1 end
        end
    end
    assert(out.scriptCount==0 and out.unanchored==0 and out.giantPhysicsParts==0)
    local saved={}
    for _,p in root:GetDescendants() do
        if p:IsA("BasePart") and (p:GetAttribute("KitMotion") or p:GetAttribute("MotionFollows")) then saved[p]=p.CFrame end
    end
    local controller=assert(Motion.Create(root))
    local ok,err=xpcall(function()
        for _,p in root:GetDescendants() do
            local kind=p:GetAttribute("KitMotion")
            if not p:IsA("BasePart") or not kind then continue end
            local record={path=p:GetFullName(),kind=kind,samples=361,slotIntersections=0,refugeIntersections=0,followers=0}
            local axis=({X=Vector3.xAxis,Y=Vector3.yAxis,Z=Vector3.zAxis})[p:GetAttribute("MotionAxis")]
            for n=0,360 do
                local a=n*math.pi/180
                local cf=if kind=="Slide" then p.CFrame*CFrame.new(axis*math.sin(a)*p:GetAttribute("MotionDistance"))
                    else p.CFrame*CFrame.fromAxisAngle(axis,if kind=="Spin" then a else math.sin(a)*math.rad(p:GetAttribute("MotionAngle")))
                for _,slot in slots do
                    if Geometry.BoxesIntersect(cf,p.Size,slot.cf,Vector3.new(4.5,6,3.5)) then record.slotIntersections+=1 end
                end
                for _,h in {root.H1_Sprinkler,root.H2_Fruit} do for _,z in {-21,21} do
                    if Geometry.BoxesIntersect(cf,p.Size,h:GetPivot()*CFrame.new(0,3.3,z),Vector3.new(4.5,6,3.5)) then record.refugeIntersections+=1 end
                end end
            end
            for _,f in p.Parent:GetChildren() do if f:GetAttribute("MotionFollows")==p.Name then record.followers+=1 end end
            assert(record.slotIntersections==0 and record.refugeIntersections==0)
            table.insert(out.moving,record)
        end
        for _=1,197 do controller.Step(1/60,nil,function()error("Unexpected contact callback")end) end
        out.moved=0;out.followersAligned=0
        for p,start in saved do
            if p:GetAttribute("KitMotion") and (p.CFrame.Position-start.Position).Magnitude+(p.CFrame.RightVector-start.RightVector).Magnitude>.1 then out.moved+=1 end
            if p:GetAttribute("MotionFollows") then
                local bar=p.Parent[p:GetAttribute("MotionFollows")]
                local expected=bar.CFrame*saved[bar]:ToObjectSpace(start)
                assert((expected.Position-p.Position).Magnitude<.001 and (expected.RightVector-p.CFrame.RightVector).Magnitude<.001)
                out.followersAligned+=1
            end
        end
        assert(out.moved==3 and out.followersAligned==18,"Expected three moved bars and eighteen aligned stripes")
    end,debug.traceback)
    controller.Reset()
    out.reset=true
    for p,start in saved do assert((p.CFrame.Position-start.Position).Magnitude<.001 and (p.CFrame.RightVector-start.RightVector).Magnitude<.001) end
    assert(ok,err)
    return out
end
