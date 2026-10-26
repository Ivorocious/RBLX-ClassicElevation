assert(game.PlaceId==85558151074819 and game.CreatorId==86069177)
assert(not game:GetService('RunService'):IsRunning())
local ss=game.ServerStorage
local archive=ss.Archive.ShipwreckCove
assert(archive:FindFirstChild('Before_SC33_OwnerEdits'),'Backup required')
local source=ss.CourseBuilders.ShipwreckCove:Clone()
source.Name='SC33_Sources';source.Parent=archive.SourceSnapshots
local data=require(source.Layout);assert(data.build=='SC_MAP_33')
local kit=require(source.Kit)
local current=workspace.Course_ShipwreckCove
local origin=CFrame.new(Vector3.new(unpack(data.origin)))
local function v(p)return Vector3.new(unpack(p))end
local function transform(p)
    local c=kit[p.asset].centerBlender;local s=v(p.scale)
    return origin*CFrame.new(v(p.p))*CFrame.Angles(0,math.rad(p.yaw),0)
        *CFrame.Angles(math.rad(p.pitch or 0),0,0)*CFrame.Angles(0,0,math.rad(p.roll or 0))
        *CFrame.new(c[1]*s.X,c[3]*s.Y,-c[2]*s.Z)*CFrame.Angles(0,math.pi,0)
end
local function visual(p)
    local template
    for _,name in {'Kit31','Kit30','Kit29','Kit28','Kit27','Kit26','Kit25','Kit13','Kit04'} do
        local f=ss.AssetLibraries.ShipwreckCove:FindFirstChild(name)
        if f and f:FindFirstChild(p.asset) then template=f[p.asset];break end
    end
    assert(template,p.asset)
    local mesh=template:Clone();mesh.Name=p.name;mesh.CFrame=transform(p)
    mesh.Size=v(kit[p.asset].dimensionsRobloxXYZ)*v(p.scale)
    mesh.Anchored=true;mesh.CanCollide=false;mesh.CanTouch=false;mesh.CanQuery=false
    mesh.TextureID='rbxassetid://106787734193978';mesh.Color=Color3.new(1,1,1)
    mesh:SetAttribute('Asset',p.asset);mesh:SetAttribute('Triangles',kit[p.asset].triangles)
    return mesh
end
local removed=Instance.new('Folder');removed.Name='SC33_ReplacedWreckTimbers';removed.Parent=archive.Milestones
for _,p in current.Decoration.X01:GetChildren() do p.Parent=removed end
local byName={};for _,s in data.surfaces do byName[s.name]=s end
local count=0
for _,p in data.placements do
    if p.section=='X01' then
        local mesh=visual(p)
        local s=byName[p.name]
        if s then
            local piece=current.EditablePlatforms:FindFirstChild(p.name,true);assert(piece,p.name)
            local col=piece.PrimaryPart;assert(col)
            for _,child in piece:GetChildren() do if child:IsA('MeshPart') then child.Parent=removed end end
            mesh:SetAttribute('AuthoringParent','Decoration/X01');mesh.Parent=piece
            local rot=CFrame.Angles(0,math.rad(s.yaw),0)*CFrame.Angles(math.rad(s.pitch or 0),0,0)*CFrame.Angles(0,0,math.rad(s.roll or 0))
            col.CFrame=origin*CFrame.new(v(s.p))*rot*CFrame.new(0,-s.size[2]/2,0);col.Size=v(s.size)
            local marker=piece:FindFirstChild('ExpertLanding_'..p.name)
            if marker then
                marker.Size=Vector3.new(1.3,.04,1.5)
                marker.CFrame=origin*CFrame.new(v(s.p))*rot*CFrame.new(0,.025,0)
            end
            count+=1
        else mesh.Parent=current.Decoration.X01 end
    end
end
local mountains=0
for _,p in data.placements do
    if p.asset=='SC_R_Horizon28' then
        local mesh=current.Decoration:FindFirstChild(p.name,true)
        if mesh then mesh.CFrame=transform(p);mountains+=1 end
    end
end
local trunks,rocks=0,0
for _,p in current:GetDescendants() do
    if p:IsA('MeshPart') and (p:GetAttribute('Asset')=='SC_R_PalmTrunk29' or p.Name:match('^LampShelf26_')) then
        p.CanCollide=true;p.CanQuery=true;p.CanTouch=false
        p:SetAttribute('EditingHint','This visible mesh is solid; move it directly to adjust its collision.')
        if p:GetAttribute('Asset')=='SC_R_PalmTrunk29' then trunks+=1 else rocks+=1 end
    end
end
require(source.Authoring).Organize(current)
current:SetAttribute('ShipwreckBuild',data.build);current:SetAttribute('ReviewBuild','SC33_CANDIDATE_01')
current:SetAttribute('PlacedVisualTriangles',data.resource.visualTriangles)
return {build='SC33_CANDIDATE_01',piles=count,mountains=mountains,solidTrunks=trunks,solidLanternRocks=rocks,camera=tostring(workspace.CurrentCamera.CameraType)}
