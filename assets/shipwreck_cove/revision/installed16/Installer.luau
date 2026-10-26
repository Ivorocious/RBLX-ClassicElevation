--!strict
local Installer = {}
local function vec(p) return Vector3.new(p[1],p[2],p[3]) end
local function folder(parent,name)
    local f=Instance.new("Folder"); f.Name=name; f.Parent=parent; return f
end
local function part(parent,name,size,cf,collide,touch)
    local p=Instance.new("Part"); p.Name=name;p.Size=size;p.CFrame=cf
    p.Anchored=true;p.Transparency=1;p.CanCollide=collide;p.CanTouch=touch or false;p.CanQuery=collide
    p.CastShadow=false
    p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;return p
end
function Installer.Install()
    assert(game.PlaceId==85558151074819 and game.CreatorId==86069177,"Wrong experience")
    assert(not workspace:FindFirstChild("Course_ShipwreckCove"),"Archive owned candidate before rebuilding")
    local data=require(script.Parent.Layout)
    local kit=require(script.Parent.Kit)
    local templates=game.ServerStorage:FindFirstChild("__ShipwreckCove_NormalizedKit04")
    assert(templates,"Missing approved Kit04")
    local revision=game.ServerStorage:FindFirstChild("__ShipwreckCove_RevisionKit08")
    assert(revision,"Missing approved revision kit")
    local origin=CFrame.new(vec(data.origin))
    local model=Instance.new("Model"); model.Name="Course_ShipwreckCove";model.WorldPivot=origin
    model:SetAttribute("ManualEditing",true);model:SetAttribute("ShipwreckBuild",data.build)
    model:SetAttribute("KitBuild",data.kitBuild);model:SetAttribute("PlacedVisualTriangles",data.resource.visualTriangles)
    local info=folder(model,"CourseInfo")
    for k,v in {CourseId="shipwreck_cove",DisplayName="Shipwreck Cove",RaceFormat="LapBased",LapCount=3,
        Enabled=true,Difficulty="Intermediate",CheckpointCount=4,TargetNewPlayerTime=300,TargetPracticedTime=150,
        DesignedRacerCapacity=20,TimingValidated=false} do info:SetAttribute(k,v) end
    local decoration=folder(model,"Decoration");local obstacles=folder(model,"Obstacles")
    local walking=folder(obstacles,"WalkingSurfaces");local hazards=folder(obstacles,"ShipwreckHazards")
    local markers=folder(model,"RouteMarkers");local checkpoints=folder(model,"Checkpoints")
    local bounds=folder(model,"Bounds");local falls=folder(model,"FallZones")
    local groups={}
    for _,p in data.placements do
        local group=groups[p.section]
        if not group then
            if string.sub(p.section,1,13)=="DistantIsland" then
                group=Instance.new("Model");group.Name=p.section
                group.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;group.Parent=decoration
            else group=folder(decoration,p.section) end
            groups[p.section]=group
        end
        local source=revision:FindFirstChild(p.asset) or templates:FindFirstChild(p.asset);assert(source and source:IsA("MeshPart"),p.asset)
        local visual=source:Clone();visual.Name=p.name
        local a=kit[p.asset];local c=a.centerBlender;local s=vec(p.scale)
        visual.Size=vec(a.dimensionsRobloxXYZ)*s
        visual.CFrame=origin*CFrame.new(vec(p.p))*CFrame.Angles(0,math.rad(p.yaw),0)
            *CFrame.Angles(math.rad(p.pitch or 0),0,0)
            *CFrame.new(c[1]*s.X,c[3]*s.Y,-c[2]*s.Z)*CFrame.Angles(0,math.pi,0)
        visual.Anchored=true;visual.CanCollide=false;visual.CanTouch=false;visual.CanQuery=false
        visual.TextureID="rbxassetid://106787734193978"
        if p.tint then visual.Color=Color3.fromRGB(p.tint[1],p.tint[2],p.tint[3]) end
        visual.DoubleSided=table.find({"vegetation","sail"},a.family)~=nil
        visual.CastShadow=not table.find({"water","foam","cue"},a.family)
        visual:SetAttribute("Asset",p.asset);visual:SetAttribute("Triangles",a.triangles);visual.Parent=group
    end
    for _,p in data.surfaces do
        local cf=origin*CFrame.new(vec(p.p)-Vector3.new(0,p.size[2]/2,0))*CFrame.Angles(0,math.rad(p.yaw),math.rad(p.roll or 0))
        local col=part(walking,p.name,vec(p.size),cf,true)
        col:SetAttribute("Section",p.section)
    end
    for i,p in data.checkpoints do
        local n=i-1
        local checkpointSizes={Vector3.new(24,6,20),Vector3.new(22,6,22),Vector3.new(22,6,20),Vector3.new(24,6,20)}
        local cp=part(if n==0 then model else checkpoints,if n==0 then "Start" else string.format("Checkpoint_%03d",n),
            if n==0 then Vector3.new(32,1,38) else checkpointSizes[n],origin*CFrame.new(vec(p)+Vector3.new(0,if n==0 then 0 else 3,0)),false,n>0)
        cp:SetAttribute("PlanningId","R"..n)
    end
    local finish=part(model,"Finish",Vector3.new(17.5,12,2),origin*CFrame.new(vec(data.gate)+Vector3.new(0,6,0)),false,false)
    finish:SetAttribute("RequireForwardCrossing",true)
    local pen=folder(model,"StartPen");folder(pen,"GateVisuals")
    part(pen,"StartGate",Vector3.new(35,16,1),origin*CFrame.new(vec(data.gate)+Vector3.new(0,8,0)),true)
    local floor=part(falls,"FallZone_Main",Vector3.new(480,2,430),origin*CFrame.new(0,-1,0),false,true)
    floor.CanQuery=true
    for i,drop in {{-107,9,36},{-69,19,36},{-28,29,40}} do
        part(falls,"WreckBilge"..i,Vector3.new(drop[3],2,34),origin*CFrame.new(drop[1],drop[2],-104),false,true)
    end
    part(bounds,"CourseOrigin",Vector3.one,origin,false)
    local surge=part(hazards,"SurgeBounds",vec(data.surge.size),origin*CFrame.new(vec(data.surge.center)),false)
    surge:SetAttribute("PlanningId","H02")
    for _,s in data.signs do
        local board=part(markers,s.text,Vector3.new(11.7,2.5,.12),origin*CFrame.new(vec(s.p))*CFrame.Angles(0,math.rad(s.yaw),0)*CFrame.new(0,0,1.18),false)
        board.Transparency=0;board.Color=Color3.fromRGB(113,67,35);board.CastShadow=false
        for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
            local gui=Instance.new("SurfaceGui");gui.Face=face;gui.CanvasSize=Vector2.new(640,120);gui.Parent=board
            local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
            label.Text=s.text.."\n"..s.sub;label.Font=Enum.Font.Antique;label.TextSize=30
            label.TextColor3=Color3.fromRGB(240,226,192);label.Parent=gui
        end
    end
    local turns=data.links
    for _,pair in turns do
        local a,b=walking[pair[1]],walking[pair[2]]
        if a.Size.X<5 or a.Size.Z<4 then continue end
        local center=a.Position+Vector3.new(0,a.Size.Y/2+.12,0)
        local look=CFrame.lookAt(center,Vector3.new(b.Position.X,center.Y,b.Position.Z))
        for _,side in {-1,1} do
            local arrow=part(markers,"RouteChevron",Vector3.new(.22,.06,1.7),look*CFrame.new(side*.55,0,.45)*CFrame.Angles(0,math.rad(side*45),0),false)
            arrow.Transparency=0;arrow.Color=Color3.fromRGB(255,220,130);arrow.CastShadow=false
        end
    end
    for i,p in data.checkpoints do
        local frame=origin*CFrame.new(p[1],p[2]+(if i==1 then 14.4 else 12),if i==1 then data.gate[3] else p[3]+8)
        local plaque=part(markers,"CheckpointLabel"..i,Vector3.new(if i==1 then 17.6 else 11,if i==1 then 5.8 else 4.5,.1),frame*CFrame.new(0,0,.3),false)
        plaque.Transparency=1
        for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
            local gui=Instance.new("SurfaceGui");gui.Face=face;gui.CanvasSize=Vector2.new(600,180);gui.Parent=plaque
            local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
            label.Text=if i==1 then "SHIPWRECK COVE\nTHREE LAPS" else "CHECKPOINT\n"..tostring(i-1)
            label.Font=Enum.Font.Antique;label.TextScaled=true;label.TextColor3=Color3.fromRGB(255,233,169);label.Parent=gui
        end
        for _,side in {-1,1} do
            local stripe=part(markers,"CheckpointInlay",Vector3.new(.35,.15,14),origin*CFrame.new(vec(p)+Vector3.new(side*9,.13,0)),false)
            stripe.Transparency=0;stripe.Color=Color3.fromRGB(240,178,65);stripe.Material=Enum.Material.SmoothPlastic;stripe.CastShadow=false
        end
    end
    local hazardVisuals=folder(decoration,"Obstacles")
    for _,d in data.hazards do
        local bar
        if d.name=="DockRopeSweep" then
            bar=templates.SC_CargoCrate:Clone();bar.Name=d.name;bar.Size=vec(d.size)
            bar.TextureID="rbxassetid://106787734193978"
            bar.CFrame=origin*CFrame.new(vec(d.p));bar.Anchored=true
            bar.CanCollide=false;bar.CanTouch=false;bar.CanQuery=false;bar.Parent=hazardVisuals
        else
            bar=part(hazardVisuals,d.name,vec(d.size),origin*CFrame.new(vec(d.p)),false)
        end
        bar.Transparency=0;bar.Color=Color3.fromRGB(217,67,41);bar.Material=Enum.Material.SmoothPlastic
        bar:SetAttribute("HazardKind",d.kind);bar.CastShadow=false
    end
    model.Parent=workspace
    return model
end
return Installer
