-- Applies only the representative cave; archives replaced instances for owner recovery.
assert(game.PlaceId==85558151074819 and game.CreatorId==86069177)
assert(not game:GetService('RunService'):IsRunning(),'Edit mode required')
local ss=game.ServerStorage
local course=workspace.Course_ShipwreckCove
assert(course:GetAttribute('ShipwreckBuild')=='SC_MAP_25','Expected owner baseline SC_MAP_25')
assert(not ss:FindFirstChild('__ShipwreckOwnerBefore26'),'Already installed')
local backup=course:Clone();backup.Name='__ShipwreckOwnerBefore26';backup.Parent=ss
local archive=Instance.new('Folder');archive.Name='__ShipwreckCave26Replaced';archive.Parent=ss
local source=ss.CourseBuilders.ShipwreckCove:Clone();source.Name='__ShipwreckCave26Sources';source.Parent=ss
local data=require(source.Layout);local kit=require(source.Kit)
assert(data.build=='SC_CAVE_26')
local templates={ss.__ShipwreckCove_Kit26,ss.__ShipwreckCove_Kit25,ss.__ShipwreckCove_RevisionKit13,ss.__ShipwreckCove_NormalizedKit04}
local origin=course.Bounds.CourseOrigin.CFrame
local function vec(p)return Vector3.new(p[1],p[2],p[3])end
local oldNames={}
for _,p in course.Obstacles.WalkingSurfaces:GetChildren() do
    if p:GetAttribute('Section')=='S04_Entry' then oldNames[p.Name]=true;p.Parent=archive end
end
for _,name in {'S04','S04_Entry'} do
    course.Decoration[name].Parent=archive
    local group=Instance.new('Folder');group.Name=name;group.Parent=course.Decoration
end
for _,p in data.placements do
    if p.section~='S04' and p.section~='S04_Entry' then continue end
    local template
    for _,f in templates do template=f:FindFirstChild(p.asset) if template then break end end
    assert(template,p.asset)
    local visual=template:Clone();visual.Name=p.name
    local a=kit[p.asset];local c=a.centerBlender;local scale=vec(p.scale)
    visual.Size=vec(a.dimensionsRobloxXYZ)*scale
    visual.CFrame=origin*CFrame.new(vec(p.p))*CFrame.Angles(0,math.rad(p.yaw),0)
        *CFrame.new(c[1]*scale.X,c[3]*scale.Y,-c[2]*scale.Z)*CFrame.Angles(0,math.pi,0)
    visual.Anchored=true;visual.CanCollide=false;visual.CanTouch=false;visual.CanQuery=false
    visual.DoubleSided=false;visual.CastShadow=true;visual.Color=Color3.new(1,1,1)
    visual.TextureID='rbxassetid://106787734193978'
    visual:SetAttribute('Asset',p.asset);visual:SetAttribute('Triangles',a.triangles)
    visual.Parent=course.Decoration[p.section]
    if string.match(p.name,'^CaveLamp26') then
        local light=Instance.new('PointLight');light.Name='WarmRefugeLight';light.Color=Color3.fromRGB(255,193,109)
        light.Brightness=.8;light.Range=21;light.Shadows=false;light.Parent=visual
    end
end
local walking=course.Obstacles.WalkingSurfaces
for _,p in data.surfaces do
    if p.section~='S04_Entry' then continue end
    local col=Instance.new('Part');col.Name=p.name;col.Size=vec(p.size)
    col.CFrame=origin*CFrame.new(vec(p.p)-Vector3.new(0,p.size[2]/2,0))*CFrame.Angles(0,math.rad(p.yaw),0)
    col.Transparency=1;col.Anchored=true;col.CanCollide=true;col.CanQuery=true;col.CanTouch=false;col.CastShadow=false
    col:SetAttribute('Section',p.section);col.Parent=walking
end
-- Only old cave chevrons are replaced; all other route cues retain their owner state.
for _,marker in course.RouteMarkers:GetChildren() do
    if marker.Name=='RouteChevron' then
        for name in oldNames do
            local old=archive:FindFirstChild(name)
            if old and (marker.Position-(old.Position+Vector3.new(0,old.Size.Y/2,0))).Magnitude<4 then
                marker.Parent=archive;break
            end
        end
    end
end
for _,pair in data.links do
    if not string.match(pair[1],'^Cave26Stone') then continue end
    local a,b=walking[pair[1]],walking[pair[2]]
    local center=a.Position+Vector3.new(0,a.Size.Y/2+.12,0)
    local cf=CFrame.lookAt(center,Vector3.new(b.Position.X,center.Y,b.Position.Z))
    for _,side in {-1,1} do
        local p=Instance.new('Part');p.Name='Cave26Chevron';p.Size=Vector3.new(.22,.06,1.7)
        p.CFrame=cf*CFrame.new(side*.55,0,.45)*CFrame.Angles(0,math.rad(side*45),0)
        p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
        p.Color=Color3.fromRGB(36,106,100);p.Parent=course.RouteMarkers
    end
end
local walls=Instance.new('Folder');walls.Name='CaveWallColliders';walls.Parent=course.Obstacles
for i,w in data.caveWalls do
    local a,b=vec(w.a),vec(w.b)
    local p=Instance.new('Part');p.Name='Wall'..i;p.Size=Vector3.new(1,26,(b-a).Magnitude+.7)
    p.CFrame=origin*CFrame.lookAt((a+b)/2,b);p.Anchored=true;p.Transparency=1
    p.CanCollide=true;p.CanQuery=true;p.CanTouch=false;p.CastShadow=false;p.Parent=walls
end
for _,p in data.placements do
    if p.name~='BeachPalm4' and p.name~='BeachPalm5' then continue end
    local visual=course.Decoration:FindFirstChild(p.name,true)
    local a=kit[p.asset];local q=a.centerBlender;local scale=vec(p.scale)
    visual.CFrame=origin*CFrame.new(vec(p.p))*CFrame.Angles(0,math.rad(p.yaw),0)
        *CFrame.new(q[1]*scale.X,q[3]*scale.Y,-q[2]*scale.Z)*CFrame.Angles(0,math.pi,0)
end
course:SetAttribute('ShipwreckBuild','SC_CAVE_26')
course:SetAttribute('KitBuild','SC_CAVE_KIT_26')
course:SetAttribute('PlacedVisualTriangles',data.resource.visualTriangles)
course:SetAttribute('OwnerReviewScope','Representative cave only; remaining critique pending')
return {build='SC_CAVE_26',backup=backup:GetFullName(),replaced=#archive:GetDescendants(),parts=#course:GetDescendants()}
