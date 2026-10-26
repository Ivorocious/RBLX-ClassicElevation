assert(game.PlaceId==85558151074819 and not game:GetService("RunService"):IsRunning(),"Requires intended Edit place")
local http=game:GetService("HttpService")
local spec=http:JSONDecode([====[__SPEC__]====])
local fingerprint=(function()
__FINGERPRINT__
end)()
local root=workspace.SGV2_Phase3_F04
local parent=workspace.SGV2_Phase3_F03
local delta=Vector3.new(900,0,0)
local byPath={}
for _,p in parent:GetDescendants() do
    if p:IsA("BasePart") then
        local path=p:GetFullName():sub(#parent:GetFullName()+2)
        byPath[path]=byPath[path] or {}
        table.insert(byPath[path],p)
    end
end
local mismatches,used,meshIds,materials={},{},{},{}
local maximumErrors={position=0,size=0,axis=0}
local counts={parts=0,meshes=0,colliders=0,scripts=0,preservedParts=0,modifiedCylinderSettings=0,knotMeshes=0}
for _,p in root:GetDescendants() do
    if p:IsA("LuaSourceContainer") then counts.scripts+=1 end
    if not p:IsA("BasePart") then continue end
    counts.parts+=1
    materials[p.Material.Name]=true
    if p.CanCollide then counts.colliders+=1 end
    if p:IsA("MeshPart") then counts.meshes+=1;meshIds[p.MeshId]=true end
    if p:IsDescendantOf(root.Phase3KnotCorrection) then counts.knotMeshes+=1;continue end
    local path=p:GetFullName():sub(#root:GetFullName()+2)
    local old,distance=nil,math.huge
    for _,s in byPath[path] or {} do
        local d=(p.Position-delta-s.Position).Magnitude
        if not used[s] and d<distance then old=s;distance=d end
    end
    assert(old,"Missing preserved source "..path)
    used[old]=true
    counts.preservedParts+=1
    maximumErrors.position=math.max(maximumErrors.position,distance)
    maximumErrors.size=math.max(maximumErrors.size,(p.Size-old.Size).Magnitude)
    maximumErrors.axis=math.max(maximumErrors.axis,(p.CFrame.XVector-old.CFrame.XVector).Magnitude,
        (p.CFrame.YVector-old.CFrame.YVector).Magnitude,(p.CFrame.ZVector-old.CFrame.ZVector).Magnitude)
    local changed=p:GetAttribute("F04ReplacementMesh")~=nil
    if changed then counts.modifiedCylinderSettings+=1 end
    local bad=p.ClassName~=old.ClassName or p.Color~=old.Color or p.Material~=old.Material
        or p.TopSurface~=old.TopSurface or p.BottomSurface~=old.BottomSurface
        or p.Anchored~=old.Anchored or p:GetAttribute("Role")~=old:GetAttribute("Role")
    if changed then
        bad=bad or p.Transparency~=1 or p.CanCollide or p.CanQuery or p.CanTouch
    else
        bad=bad or p.Transparency~=old.Transparency or p.CanCollide~=old.CanCollide
            or p.CanQuery~=old.CanQuery or p.CanTouch~=old.CanTouch
    end
    if p:IsA("MeshPart") then bad=bad or p.MeshId~=old.MeshId or p.TextureID~=old.TextureID or p.CollisionFidelity~=old.CollisionFidelity end
    if p:IsA("Part") then bad=bad or p.Shape~=old.Shape end
    if bad then table.insert(mismatches,path) end
end
local rayResults={}
local totalRays,misses,maximumRayError=0,0,0
for _,row in spec.meshes do
    local part=root.Phase3KnotCorrection[row.name]
    assert(part.CollisionFidelity==Enum.CollisionFidelity.Hull and part.CanCollide and part.CanQuery and not part.CanTouch and part.Anchored and not part.DoubleSided,"Incorrect knot contact settings")
    local sourceCf=CFrame.new(unpack(row.sourceCf))+Vector3.new(unpack(spec.target))-Vector3.new(9200,80,3500)
    local points={}
    for _,v in row.localVertices do table.insert(points,sourceCf:PointToWorldSpace(Vector3.new(unpack(v)))) end
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances={part}
    local result={name=row.name,rays=0,misses=0,maximumError=0,failures={}}
    for i,face in row.faces do
        local a,b,c=points[face[1]+1],points[face[2]+1],points[face[3]+1]
        local normal=(b-a):Cross(c-a).Unit
        local expected=(a+b+c)/3
        local hit=workspace:Raycast(expected+normal*2,-normal*4,params)
        local err=if hit then (hit.Position-expected).Magnitude else 999
        result.rays+=1;totalRays+=1
        if not hit then result.misses+=1;misses+=1 end
        result.maximumError=math.max(result.maximumError,err)
        maximumRayError=math.max(maximumRayError,err)
        if err>.03 then table.insert(result.failures,{face=i,error=err}) end
    end
    table.insert(rayResults,result)
end
local overlap=OverlapParams.new()
overlap.FilterType=Enum.RaycastFilterType.Include
overlap.FilterDescendantsInstances={root.Phase3KnotCorrection,root.Phase3SceneryCollision}
local plots={}
for _,p in {root.Start,unpack(root.Checkpoints:GetChildren())} do
    local cf=p:GetAttribute("RespawnCFrame")
    local area=p:GetAttribute("RespawnAreaSize")
    local hits=workspace:GetPartBoundsInBox(cf*CFrame.new(0,2.2,0),Vector3.new(area.X,10,area.Z),overlap)
    local paths={}
    for _,hit in hits do table.insert(paths,hit:GetFullName()) end
    table.insert(plots,{plot=p.Name,hits=paths})
end
local function numberKeys(t)local n=0 for _ in t do n+=1 end return n end
return http:JSONEncode({candidate=root.Name,fingerprint=fingerprint(root),previous=fingerprint(parent),
    original=fingerprint(workspace.Course_StudGardenV2),counts=counts,uniqueMeshAssets=numberKeys(meshIds),
    materials=numberKeys(materials),sourcePropertyMismatches=mismatches,preservedMaximumErrors=maximumErrors,
    contactRays={total=totalRays,misses=misses,maximumError=maximumRayError,byMesh=rayResults},
    recoveryAreaOverlaps=plots,enabled=root.CourseInfo:GetAttribute("Enabled"),running=false,
    limits="Native fixed-shape raycasts and preservation checks; no avatar contact response, gameplay, moving camera, crowd or FPS proof."})
