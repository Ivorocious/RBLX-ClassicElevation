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
    local library=require(script.Parent.AssetLibrary)
    local templates=library.Find("Kit04")
    assert(templates,"Missing approved Kit04")
    local revision=library.Find("Kit13")
    assert(revision,"Missing approved revision kit")
    local supplement=library.Find("Kit25")
    assert(supplement,"Missing critique kit25")
    local caveKit=library.Find("Kit26")
    local kit27=library.Find("Kit27")
    local kit28=library.Find("Kit28")
    local kit29=library.Find("Kit29")
    local kit30=library.Find("Kit30")
    local kit31=library.Find("Kit31")
    local origin=CFrame.new(vec(data.origin))
    local model=Instance.new("Model"); model.Name="Course_ShipwreckCove";model.WorldPivot=origin
    model:SetAttribute("ManualEditing",true);model:SetAttribute("ShipwreckBuild",data.build)
    model:SetAttribute("KitBuild",data.kitBuild);model:SetAttribute("PlacedVisualTriangles",data.resource.visualTriangles)
    local info=folder(model,"CourseInfo")
    for k,v in {CourseId="shipwreck_cove",DisplayName="Shipwreck Cove",RaceFormat="LapBased",LapCount=3,
        Enabled=true,Difficulty="Intermediate",CheckpointCount=#data.checkpoints-1,TargetNewPlayerTime=300,TargetPracticedTime=150,
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
                group.ModelStreamingMode=if p.asset=="SC_R_Horizon28" then Enum.ModelStreamingMode.Persistent else Enum.ModelStreamingMode.Atomic;group.Parent=decoration
            else group=folder(decoration,p.section) end
            groups[p.section]=group
        end
        local source=(kit31 and kit31:FindFirstChild(p.asset)) or (kit30 and kit30:FindFirstChild(p.asset)) or (kit29 and kit29:FindFirstChild(p.asset)) or (kit28 and kit28:FindFirstChild(p.asset)) or (kit27 and kit27:FindFirstChild(p.asset)) or (caveKit and caveKit:FindFirstChild(p.asset)) or supplement:FindFirstChild(p.asset) or revision:FindFirstChild(p.asset) or templates:FindFirstChild(p.asset);assert(source and source:IsA("MeshPart"),p.asset)
        local visual=source:Clone();visual.Name=p.name
        local a=kit[p.asset];local c=a.centerBlender;local s=vec(p.scale)
        visual.Size=vec(a.dimensionsRobloxXYZ)*s
        visual.CFrame=origin*CFrame.new(vec(p.p))*CFrame.Angles(0,math.rad(p.yaw),0)
            *CFrame.Angles(math.rad(p.pitch or 0),0,0)
            *CFrame.Angles(0,0,math.rad(p.roll or 0))
            *CFrame.new(c[1]*s.X,c[3]*s.Y,-c[2]*s.Z)*CFrame.Angles(0,math.pi,0)
        visual.Anchored=true;visual.CanCollide=p.solid==true;visual.CanTouch=false;visual.CanQuery=p.solid==true
        visual.TextureID="rbxassetid://106787734193978"
        visual.Color=Color3.new(1,1,1)
        if p.name=="SurgeWater" then
            visual.TextureID="";visual.Color=Color3.fromRGB(28,145,163)
        end
        -- Foam is part of the curled crest mesh; this anchor only carries tide sounds.
        if p.name=="SurgeFoam" then visual.Transparency=1 end
        if p.name=="SurgeWave" or p.name=="SurgeWater" then visual.Transparency=1 end
        if p.editGroup then visual:SetAttribute("EditGroup",p.editGroup) end
        if p.platformOwner then visual:SetAttribute("PlatformOwner",p.platformOwner) end
        if p.tint then visual.Color=Color3.fromRGB(p.tint[1],p.tint[2],p.tint[3]) end
        if p.ocean then
            visual.TextureID="";visual.Material=Enum.Material.SmoothPlastic
            visual.Transparency=p.opacity and (1-p.opacity) or 0
            visual.Reflectance=p.reflectance or .08
            visual:SetAttribute("OceanMotion",true)
            visual:SetAttribute("OceanAmplitude",p.ocean.amplitude)
            visual:SetAttribute("OceanPhase",p.ocean.phase)
            visual:SetAttribute("OceanPeriod",p.ocean.period)
        end
        if p.asset=="SC_R_Horizon28" then visual.TextureID="" end
        if p.name:match('^DistantPeak') then
            visual.TextureID="";visual.Color=Color3.fromRGB(151,185,193)
        end
        if p.asset=="SC_R_Stalactite28" then visual.TextureID="";visual.Color=Color3.fromRGB(166,159,142) end
        if p.paletteTint then
            local appearance=Instance.new("SurfaceAppearance")
            appearance.Name="PaletteTint"
            appearance.ColorMap=visual.TextureID
            appearance.Color=visual.Color
            appearance.Parent=visual
        end
        visual.DoubleSided=table.find({"vegetation","sail"},a.family)~=nil
        visual.CastShadow=not table.find({"water","foam","cue"},a.family)
        if p.name:match('^DistantPeak') or p.asset=='SC_R_Horizon28' then visual.CastShadow=false end
        visual:SetAttribute("Asset",p.asset);visual:SetAttribute("Triangles",a.triangles);visual.Parent=group
        if string.match(p.name,"^CaveLamp") then
            local light=Instance.new("PointLight");light.Name="WarmRefugeLight"
            light.Color=Color3.fromRGB(255,193,109);light.Brightness=.8;light.Range=21
            light.Shadows=false;light.Parent=visual
        end
    end
    local wreckSupports=folder(decoration,"WreckSupports28")
    for _,brace in data.braces or {} do
        local a,b=vec(brace.a),vec(brace.b)
        local beam=part(wreckSupports,brace.name,Vector3.new(.72,(b-a).Magnitude,.72),
            origin*CFrame.lookAt((a+b)/2,b)*CFrame.Angles(math.pi/2,0,0),false)
        beam.Transparency=0;beam.Color=Color3.fromRGB(98,65,44)
        beam.Material=Enum.Material.Wood;beam.CastShadow=true
    end
    for _,p in data.surfaces do
        local rotation=CFrame.Angles(0,math.rad(p.yaw),0)*CFrame.Angles(math.rad(p.pitch or 0),0,0)*CFrame.Angles(0,0,math.rad(p.roll or 0))
        local cf=origin*CFrame.new(vec(p.p))*rotation*CFrame.new(0,-p.size[2]/2,0)
        local col=part(walking,p.name,vec(p.size),cf,true)
        col:SetAttribute("Section",p.section)
    end
    require(script.Parent.SolidGround).Apply(model)
    local caveWalls=folder(obstacles,"CaveWallColliders")
    for i,wall in data.caveWalls or {} do
        local a,b=vec(wall.a),vec(wall.b)
        part(caveWalls,"Wall"..i,Vector3.new(1,26,(b-a).Magnitude+.7),origin*CFrame.lookAt((a+b)/2,b),true)
    end
    for i,p in data.checkpoints do
        local n=i-1
        local checkpointSizes={Vector3.new(24,6,20),Vector3.new(22,6,22),Vector3.new(22,6,20),Vector3.new(24,6,20)}
        local cp=part(if n==0 then model else checkpoints,if n==0 then "Start" else string.format("Checkpoint_%03d",n),
            if n==0 then Vector3.new(32,1,38) else checkpointSizes[n] or Vector3.new(20,6,18),origin*CFrame.new(vec(p)+Vector3.new(0,if n==0 then 0 else 3,0)),false,n>0)
        cp:SetAttribute("PlanningId","R"..n)
    end
    local finish=part(model,"Finish",Vector3.new(17.5,12,2),origin*CFrame.new(vec(data.gate)+Vector3.new(0,6,0)),false,false)
    finish:SetAttribute("RequireForwardCrossing",true)
    local pen=folder(model,"StartPen");folder(pen,"GateVisuals")
    part(pen,"StartGate",Vector3.new(35,16,1),origin*CFrame.new(vec(data.gate)+Vector3.new(0,8,0)),true)
    local floor=part(falls,"FallZone_Main",Vector3.new(480,2,430),origin*CFrame.new(0,-1,0),false,true)
    floor.CanQuery=true
    floor.Locked=true -- Keep the invisible reset plane out of normal viewport selection.
    for i,drop in {{-107,9,36},{-69,19,36},{-28,29,40}} do
        part(falls,"WreckBilge"..i,Vector3.new(drop[3],2,34),origin*CFrame.new(drop[1],drop[2],-104),false,true)
    end
    part(bounds,"CourseOrigin",Vector3.one,origin,false)
    for _,d in data.surges do
        local surge=part(hazards,d.name.."Bounds",vec(d.size),origin*CFrame.new(vec(d.center)),false)
        surge:SetAttribute("PlanningId","H02_"..d.name)
    end
    for _,s in data.signs do
        for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
            local board=part(markers,s.text..face.Name,Vector3.new(11.7,2.5,.12),origin*CFrame.new(vec(s.p))*CFrame.Angles(0,math.rad(s.yaw),0)*CFrame.new(0,0,if face==Enum.NormalId.Front then .18 else 1.18),false)
            board.Transparency=0;board.Color=Color3.fromRGB(113,67,35);board.CastShadow=false
            local gui=Instance.new("SurfaceGui");gui.Face=face;gui.CanvasSize=Vector2.new(640,120);gui.Parent=board
            local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
            label.Text=s.text.."\n"..s.sub;label.Font=Enum.Font.Antique;label.TextSize=36
            label.TextColor3=Color3.fromRGB(240,226,192);label.Parent=gui
        end
    end
    local turns=data.links
    local marked={}
    for _,pair in turns do
        local a,b=walking[pair[1]],walking[pair[2]]
        if data.arrowSurfaces and not table.find(data.arrowSurfaces,pair[1]) then continue end
        if not a or not b or marked[a] or a:GetAttribute("Section")=="S04_Entry" or a.Name:match("^Cave") then continue end
        if a.Size.X<2.5 or a.Size.Z<4 then continue end
        marked[a]=true
        local center=a.Position+Vector3.new(0,a.Size.Y/2+.12,0)
        local look=CFrame.lookAt(center,Vector3.new(b.Position.X,center.Y,b.Position.Z))
        local large=math.min(a.Size.X,a.Size.Z)>=8
        local length=if large then 5.4 else math.min(3.8,math.min(a.Size.X,a.Size.Z)*.82)
        local plaque=part(markers,"RouteArrow_"..a.Name,Vector3.new(length,.025,length*.74),look*CFrame.Angles(0,-math.pi/2,0),false)
        local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Top;gui.CanvasSize=Vector2.new(160,200);gui.LightInfluence=.35;gui.Parent=plaque
        for layer=1,2 do
            for _,shape in {{.5,.57,.18,.60,0},{.35,.30,.44,.18,-45},{.65,.30,.44,.18,45}} do
                local stroke=Instance.new("Frame");stroke.AnchorPoint=Vector2.new(.5,.5)
                stroke.Position=UDim2.fromScale(shape[1],shape[2]);stroke.Rotation=shape[5]
                local outline=if layer==1 then .09 else 0
                stroke.Size=UDim2.fromScale(shape[3]+outline,shape[4]+outline)
                stroke.BackgroundColor3=if layer==1 then Color3.fromRGB(255,236,190) else Color3.fromRGB(12,65,68)
                stroke.BorderSizePixel=0;stroke.ZIndex=layer;stroke.Parent=gui
            end
        end
    end
    for _,landing in walking:GetChildren() do
        local name=landing.Name
        if not string.match(name,"^Rib%d+") and not string.match(name,"^Spar%d+") then continue end
        local marker=part(markers,"ExpertLanding_"..name,Vector3.new(math.min(landing.Size.X,2),.08,math.min(landing.Size.Z,1.6)),landing.CFrame*CFrame.new(0,landing.Size.Y/2+.05,0),false)
        if landing:GetAttribute("Section")=="X01" then
            marker.Size=Vector3.new(1.3,.04,1.5)
            marker.CFrame=landing.CFrame*CFrame.new(0,landing.Size.Y/2+.025,0)
        end
        marker.Transparency=0;marker.Color=Color3.fromRGB(234,172,58);marker.CastShadow=false
    end
    local shortcutEnds={}
    for _,routeName in {"expert_ribs","expert_spars"} do
        local route=data.testRoutes[routeName]
        table.insert(shortcutEnds,{route[1],route[2]})
        table.insert(shortcutEnds,{route[#route-1],route[#route]})
    end
    for _,pair in shortcutEnds do
        local from,to=walking:FindFirstChild(pair[1]),walking:FindFirstChild(pair[2])
        if not from or not to then continue end
        local center=from.Position+Vector3.new(0,from.Size.Y/2+.18,0)
        local aim=CFrame.lookAt(center,Vector3.new(to.Position.X,center.Y,to.Position.Z))
        for _,side in {-1,1} do
            local cue=part(markers,"ShortcutDirection",Vector3.new(.38,.08,2.6),aim*CFrame.new(side*.8,0,-1)*CFrame.Angles(0,math.rad(side*40),0),false)
            cue.Transparency=0;cue.Color=Color3.fromRGB(250,181,46)
        end
        local rim=part(markers,"ShortcutDestination",Vector3.new(math.min(to.Size.X-1,8),.1,.5),to.CFrame*CFrame.new(0,to.Size.Y/2+.12,to.Size.Z/2-.5),false)
        rim.Transparency=0;rim.Color=Color3.fromRGB(250,181,46)
    end
    for _,name in {"SurgeEastRefuge","SurgeMiddleRefuge","SurgeWestRefuge"} do
        local landing=walking[name]
        for _,side in {-1,1} do
            local inlay=part(markers,"DryRefugeEdge",Vector3.new(.5,.1,landing.Size.Z-2),landing.CFrame*CFrame.new(side*(landing.Size.X/2-1),landing.Size.Y/2+.12,0),false)
            inlay.Transparency=0;inlay.Color=Color3.fromRGB(35,146,133)
        end
        local post=part(markers,"TideHighWaterPost",Vector3.new(.55,5,.55),landing.CFrame*CFrame.new(0,landing.Size.Y/2+2.5,-landing.Size.Z/2+1),false)
        post.Transparency=0;post.Color=Color3.fromRGB(93,60,35)
        local cap=part(markers,"DryRefugeBeacon",Vector3.new(.7,.6,.7),post.CFrame*CFrame.new(0,2.2,0),false)
        cap.Transparency=0;cap.Color=Color3.fromRGB(35,185,165)
    end
    for _,landing in walking:GetChildren() do
        if not string.match(landing.Name,"^S03_%d+") then continue end
        local rim=part(markers,"CliffLanding_"..landing.Name,Vector3.new(math.min(landing.Size.X-1,7),.07,.3),landing.CFrame*CFrame.new(0,landing.Size.Y/2+.05,landing.Size.Z/2-.45),false)
        rim.Transparency=0;rim.Color=Color3.fromRGB(36,106,100);rim.CastShadow=false
    end
    for i,p in data.checkpoints do
        local frame=origin*CFrame.new(p[1],p[2]+(if i==1 then 14.4 else 12),if i==1 then data.gate[3] else p[3]+(if i==4 then -8 else 8))
        for _,face in {Enum.NormalId.Front,Enum.NormalId.Back} do
            -- Separate faces sit outside both sides of the opaque cloth banner.
            local plaque=part(markers,"CheckpointLabel"..i..face.Name,Vector3.new(if i==1 then 17.6 else 11,if i==1 then 5.8 else 4.5,.1),frame*CFrame.new(0,0,if face==Enum.NormalId.Front then -.4 else .25),false)
            plaque.Transparency=1
            local gui=Instance.new("SurfaceGui");gui.Face=face;gui.CanvasSize=Vector2.new(600,180);gui.Parent=plaque
            local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
            label.Text=if i==1 then "SHIPWRECK COVE" else "CHECKPOINT\n"..tostring(i-1)
            label.Font=Enum.Font.Antique;label.TextScaled=true;label.TextColor3=Color3.fromRGB(255,233,169);label.Parent=gui
        end
        for _,side in {-1,1} do
            local stripe=part(markers,"CheckpointInlay",Vector3.new(.35,.15,14),origin*CFrame.new(vec(p)+Vector3.new(side*9,.13,0)),false)
            stripe.Transparency=0;stripe.Color=Color3.fromRGB(240,178,65);stripe.Material=Enum.Material.SmoothPlastic;stripe.CastShadow=false
        end
    end
    local hazardVisuals=folder(decoration,"Obstacles")
    local falling=folder(decoration,"Falling")
    for _,d in data.falling or {} do
        local asset=d.asset or (if d.kind=="stalactite" then "SC_R_Stalactite28" else "SC_R_Coconut27")
        local source=(kit28 and kit28:FindFirstChild(asset)) or (kit27 and kit27:FindFirstChild(asset))
        assert(source and source:IsA("MeshPart"),asset)
        local visual=source:Clone();visual.Name=d.name
        visual.Size*=d.visualScale or 1
        visual.CFrame=origin*CFrame.new(vec(d.top))*CFrame.Angles(0,math.pi,0)
        visual.Anchored=true;visual.CanCollide=false;visual.CanTouch=false;visual.CanQuery=false
        visual.Color=Color3.new(1,1,1)
        visual:SetAttribute("Asset",asset);visual:SetAttribute("Triangles",kit[asset].triangles)
        if d.kind=="stalactite" then visual.TextureID="";visual.Color=Color3.fromRGB(166,159,142) end
        visual.Parent=falling
    end
    for _,d in data.hazards do
        local bar
        if d.name=="DockRopeSweep" or string.match(d.name,"^RedCargo") then
            bar=templates.SC_CargoCrate:Clone();bar.Name=d.name;bar.Size=vec(d.size)
            bar.TextureID=""
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



