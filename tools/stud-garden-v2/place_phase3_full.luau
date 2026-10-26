assert(game.PlaceId == 85558151074819, "Wrong place")
assert(not game:GetService("RunService"):IsRunning(), "Requires Edit mode")
local http = game:GetService("HttpService")
local spec = http:JSONDecode([====[__SPEC__]====])
local fingerprint = (function()
__FINGERPRINT__
end)()
local original = workspace.Course_StudGardenV2
assert(fingerprint(original).hash == "d17688b8", "R305 changed; inspect before proceeding")
assert(not workspace:FindFirstChild(spec.candidate), "Candidate already exists")
local raw = game.ServerStorage["SGV2_Phase3_Raw_" .. spec.id]
local witnesses, sources, seen = {}, {}, {}
for _, object in raw:GetDescendants() do
    assert(not object:IsA("LuaSourceContainer"), "Imported scripts are forbidden")
    if object:IsA("BasePart") then
        assert(object:IsA("MeshPart"), "Unexpected imported part type")
        if object.Name:sub(1,3) == "Cal" then witnesses[object.Name] = object
        else
            assert(spec.meshes[object.Name] and not seen[object.Name], "Unknown or duplicate mesh")
            seen[object.Name] = true
            table.insert(sources, object)
        end
    end
end
assert(#sources == spec.meshCount, "Missing imported mesh")
assert(witnesses.CalO and witnesses.CalX and witnesses.CalY and witnesses.CalZ, "Missing witnesses")
local origin = witnesses.CalO.Position
local x,y,z = witnesses.CalX.Position-origin,witnesses.CalY.Position-origin,witnesses.CalZ.Position-origin
local unit = (x.Magnitude+y.Magnitude+z.Magnitude)/72
for _,v in {x,y,z} do assert(math.abs(v.Magnitude/unit-24)<.003, "Uneven import scale") end
assert(x.Unit:Cross(y.Unit):Dot(z.Unit)>.99999, "Mirrored import")
assert(math.abs(x.Unit:Dot(y.Unit))<.00001 and math.abs(x.Unit:Dot(z.Unit))<.00001, "Skewed import")
local importedFrame = CFrame.fromMatrix(origin,x.Unit,y.Unit,z.Unit)
local target = CFrame.new(unpack(spec.target))
local delta = CFrame.new(target.Position-Vector3.new(9200,80,3500))
local candidate = original:Clone()
candidate.Name = spec.candidate
local clonedBaseline = fingerprint(candidate)
assert(clonedBaseline.hash == "d17688b8", "Source clone differs")
local hidden, studded = {}, {}
for _,r in spec.rootSkins do for _,p in r.hiddenSourcePaths do hidden[p]=true end end
for _,p in spec.studdedSourceParts do studded[p]=true end
local hiddenCount,reliefCount = 0,0
for _,object in {candidate,unpack(candidate:GetDescendants())} do
    assert(not object:IsA("LuaSourceContainer"), "Source course contains scripts")
    if object:IsA("BasePart") then
        local path=object:GetFullName():sub(#candidate:GetFullName()+2)
        object:SetAttribute("SourceR305Path",path)
        if hidden[path] then
            object:SetAttribute("SourceR305Transparency",object.Transparency)
            object.Transparency=1
            hiddenCount+=1
        end
        if studded[path] then object.TopSurface=Enum.SurfaceType.Smooth;reliefCount+=1 end
    end
    for key,value in object:GetAttributes() do
        if key=="RespawnCFrame" then object:SetAttribute(key,delta*value)
        elseif key=="CourseOrigin" then object:SetAttribute(key,value+delta.Position) end
    end
end
candidate:PivotTo(delta*original:GetPivot())
candidate:SetAttribute("CandidateId",spec.candidate)
candidate:SetAttribute("Phase","3 art candidate; static verification only")
candidate:SetAttribute("SourceCourseFingerprint","d17688b8")
candidate:SetAttribute("SourceAssetId",spec.assetId)
candidate:SetAttribute("SourceFbxSha256",spec.fbxSha256)
candidate:SetAttribute("SourceTriangles",spec.triangles)
candidate:SetAttribute("CollisionSha256",spec.collisionSha256)
candidate:SetAttribute("ImportedUnitsPerStud",unit)
candidate:SetAttribute("GameplayValidated",false)
candidate:SetAttribute("RuntimeStatus","Separate disabled art preview; no race integration")
local enabled=candidate.CourseInfo:GetAttribute("Enabled")
assert(enabled==false,"Expected disabled baseline")
local art=Instance.new("Folder");art.Name="Phase3Art";art.Parent=candidate
local maximumBoundError=0
for _,source in sources do
    local row=spec.meshes[source.Name]
    local part=source:Clone()
    local imported=importedFrame:ToObjectSpace(source.CFrame)
    part.Size=source.Size/unit
    local cf=CFrame.new(imported.Position/unit)*imported.Rotation
    local h=part.Size/2
    local radius=Vector3.new(math.abs(cf.XVector.X)*h.X+math.abs(cf.YVector.X)*h.Y+math.abs(cf.ZVector.X)*h.Z,
        math.abs(cf.XVector.Y)*h.X+math.abs(cf.YVector.Y)*h.Y+math.abs(cf.ZVector.Y)*h.Z,
        math.abs(cf.XVector.Z)*h.X+math.abs(cf.YVector.Z)*h.Y+math.abs(cf.ZVector.Z)*h.Z)
    maximumBoundError=math.max(maximumBoundError,(cf.Position-radius-Vector3.new(unpack(row.bounds[1]))).Magnitude,
        (cf.Position+radius-Vector3.new(unpack(row.bounds[2]))).Magnitude)
    part.CFrame=target*cf
    part.Color=Color3.fromHex(row.hex)
    part.Material=Enum.Material.SmoothPlastic
    part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.DoubleSided=false
    part:SetAttribute("Role","Phase3Visual")
    part.Parent=art
end
assert(maximumBoundError<.02,"Imported geometry bounds differ")
local collision=Instance.new("Folder");collision.Name="Phase3SceneryCollision";collision.Parent=candidate
local groups={}
for i,row in spec.colliders do
    local group=groups[row.group]
    if not group then group=Instance.new("Folder");group.Name=row.group;group.Parent=collision;groups[row.group]=group end
    local part=Instance.new("Part")
    part.Name=string.format("Solid_%04d",i)
    part.Size=Vector3.new(unpack(row.size))
    local p=Vector3.new(unpack(row.center))
    local cf=CFrame.new(p)
    if row.shape=="Cylinder" then
        part.Shape=Enum.PartType.Cylinder
        local axis=Vector3.new(unpack(row.normal))
        local up=if math.abs(axis.Y)>.99 then Vector3.zAxis else Vector3.yAxis
        up=(up-axis*axis:Dot(up)).Unit
        cf=CFrame.fromMatrix(p,axis,up,axis:Cross(up).Unit)
    else cf*=CFrame.Angles(0,-row.yaw,0) end
    part.CFrame=target*cf
    part.Anchored=true;part.CanCollide=true;part.CanQuery=true;part.CanTouch=false
    part.Transparency=1
    part.TopSurface=Enum.SurfaceType.Smooth;part.BottomSurface=Enum.SurfaceType.Smooth
    part:SetAttribute("Role","SceneryCollider")
    part:SetAttribute("SourcePiece",row.sourcePiece)
    part:SetAttribute("SourceKind",row.kind)
    part.Parent=group
end
local boundsCf,boundsSize=candidate:GetBoundingBox()
local params=OverlapParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances={workspace.Terrain}
assert(#workspace:GetPartBoundsInBox(boundsCf,boundsSize+Vector3.new(6,6,6),params)==0,"Candidate location occupied")
candidate.Parent=workspace
assert(fingerprint(original).hash=="d17688b8","R305 preservation failed")
local counts={parts=0,meshes=0,colliders=0,scripts=0}
for _,p in candidate:GetDescendants() do
    if p:IsA("BasePart") then counts.parts+=1;if p.CanCollide then counts.colliders+=1 end end
    if p:IsA("MeshPart") then counts.meshes+=1 end
    if p:IsA("LuaSourceContainer") then counts.scripts+=1 end
end
return http:JSONEncode({candidate=spec.candidate,path=candidate:GetFullName(),assetId=spec.assetId,
    target=spec.target,unitsPerStud=unit,maxBoundError=maximumBoundError,counts=counts,
    artMeshes=#sources,newColliders=#spec.colliders,hiddenUnderbodyParts=hiddenCount,
    smoothedStuddedParts=reliefCount,fingerprint=fingerprint(candidate),sourceCourse=fingerprint(original),
    sourceCloneBeforeChanges=clonedBaseline,enabled=enabled})
