assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning(),"Requires intended Edit place")
local http=game:GetService("HttpService")
local spec=http:JSONDecode([====[__SPEC__]====])
local fingerprint=(function()
__FINGERPRINT__
end)()
local root=workspace[spec.candidate]
local original=workspace.Course_StudGardenV2
local delta=Vector3.new(unpack(spec.target))-Vector3.new(9200,80,3500)
local sourceByPath,hidden,studded={},{},{}
for _,r in spec.rootSkins do for _,path in r.hiddenSourcePaths do hidden[path]=true end end
for _,path in spec.studdedSourceParts do studded[path]=true end
for _,p in original:GetDescendants() do
    if p:IsA("BasePart") then
        local path=p:GetFullName():sub(#original:GetFullName()+2)
        sourceByPath[path]=sourceByPath[path] or {}
        table.insert(sourceByPath[path],p)
    end
end
local counts={parts=0,meshes=0,colliders=0,scripts=0,sourceParts=0,artMeshes=0,newColliders=0}
local meshIds,materials={},{}
local mismatches={}
local maxPositionError,maxRotationError,maxSizeError=0,0,0
local used={}
for _,p in root:GetDescendants() do
    if p:IsA("LuaSourceContainer") then counts.scripts+=1 end
    if not p:IsA("BasePart") then continue end
    counts.parts+=1
    materials[p.Material.Name]=true
    if p.CanCollide then counts.colliders+=1 end
    if p:IsA("MeshPart") then counts.meshes+=1;meshIds[p.MeshId]=true end
    local path=p:GetAttribute("SourceR305Path")
    if path then
        counts.sourceParts+=1
        local best,distance=nil,math.huge
        for _,s in sourceByPath[path] or {} do
            local d=(p.Position-delta-s.Position).Magnitude
            if not used[s] and d<distance then best=s;distance=d end
        end
        assert(best,"Missing or duplicate source path")
        used[best]=true
        maxPositionError=math.max(maxPositionError,distance)
        maxSizeError=math.max(maxSizeError,(p.Size-best.Size).Magnitude)
        maxRotationError=math.max(maxRotationError,(p.CFrame.XVector-best.CFrame.XVector).Magnitude,
            (p.CFrame.YVector-best.CFrame.YVector).Magnitude,(p.CFrame.ZVector-best.CFrame.ZVector).Magnitude)
        local bad=p.ClassName~=best.ClassName or p.CanCollide~=best.CanCollide or p.CanQuery~=best.CanQuery
            or p.CanTouch~=best.CanTouch or p.Material~=best.Material or p.Color~=best.Color or p.Anchored~=best.Anchored
            or p:GetAttribute("Role")~=best:GetAttribute("Role")
            or p.Transparency~=(if hidden[path] then 1 else best.Transparency)
            or p.TopSurface~=(if studded[path] then Enum.SurfaceType.Smooth else best.TopSurface)
        if p:IsA("MeshPart") then bad=bad or p.MeshId~=best.MeshId or p.TextureID~=best.TextureID end
        if p:IsA("Part") then bad=bad or p.Shape~=best.Shape end
        if bad then table.insert(mismatches,path) end
    elseif p:IsDescendantOf(root.Phase3Art) then
        counts.artMeshes+=1
        assert(p:IsA("MeshPart") and p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p.DoubleSided,"Invalid art settings")
        assert(p.Color==Color3.fromHex(spec.meshes[p.Name].hex),"Palette differs")
    elseif p:IsDescendantOf(root.Phase3SceneryCollision) then counts.newColliders+=1
    else table.insert(mismatches,"Unexpected part: "..p:GetFullName()) end
end
local collisionErrors={}
local colliderMaxPosition,colliderMaxSize,colliderMaxAxis=0,0,0
for i,row in spec.colliders do
    local p=root.Phase3SceneryCollision[row.group][string.format("Solid_%04d",i)]
    local position=Vector3.new(unpack(row.center))+Vector3.new(unpack(spec.target))
    colliderMaxPosition=math.max(colliderMaxPosition,(p.Position-position).Magnitude)
    colliderMaxSize=math.max(colliderMaxSize,(p.Size-Vector3.new(unpack(row.size))).Magnitude)
    assert(p.CanCollide and p.CanQuery and not p.CanTouch and p.Anchored and p.Transparency==1,"Invalid collider settings")
    if row.shape=="Cylinder" then
        colliderMaxAxis=math.max(colliderMaxAxis,(p.CFrame.XVector-Vector3.new(unpack(row.normal))).Magnitude)
        if p.Shape~=Enum.PartType.Cylinder then table.insert(collisionErrors,p.Name) end
    else
        local cf=CFrame.Angles(0,-row.yaw,0)
        colliderMaxAxis=math.max(colliderMaxAxis,(p.CFrame.XVector-cf.XVector).Magnitude)
        if p.Shape~=Enum.PartType.Block then table.insert(collisionErrors,p.Name) end
    end
end
local params=OverlapParams.new()
params.FilterType=Enum.RaycastFilterType.Include
params.FilterDescendantsInstances={root.Phase3SceneryCollision}
local plots={}
for _,p in {root.Start,unpack(root.Checkpoints:GetChildren())} do
    local respawn=p:GetAttribute("RespawnCFrame")
    local area=p:GetAttribute("RespawnAreaSize")
    local box=respawn*CFrame.new(0,2.2,0)
    local hits=workspace:GetPartBoundsInBox(box,Vector3.new(area.X,10,area.Z),params)
    local paths={}
    for _,hit in hits do table.insert(paths,hit:GetFullName()) end
    table.insert(plots,{plot=p.Name,hits=paths})
end
local function countKeys(t)local n=0 for _ in t do n+=1 end return n end
return http:JSONEncode({candidate=spec.candidate,fingerprint=fingerprint(root),original=fingerprint(original),
    counts=counts,uniqueMeshAssets=countKeys(meshIds),materialCount=countKeys(materials),
    sourcePropertyMismatches=mismatches,sourceMaximumErrors={position=maxPositionError,size=maxSizeError,rotation=maxRotationError},
    collisionMaximumErrors={position=colliderMaxPosition,size=colliderMaxSize,axis=colliderMaxAxis},
    collisionShapeErrors=collisionErrors,recoveryAreaNewSceneryOverlaps=plots,
    enabled=root.CourseInfo:GetAttribute("Enabled"),running=game:GetService("RunService"):IsRunning(),
    limits="Read-only native construction checks; no avatar movement, running hazards, checkpoint events, camera sweep, crowd or FPS proof."})
