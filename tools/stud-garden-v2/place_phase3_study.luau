assert(game.PlaceId == 85558151074819, "Wrong place")
assert(not game:GetService("RunService"):IsRunning(), "Requires Edit mode")
local http = game:GetService("HttpService")
local spec = http:JSONDecode([====[__SPEC__]====])
local fingerprint = (function()
__FINGERPRINT__
end)()
local original = workspace.Course_StudGardenV2
assert(fingerprint(original).hash == "d17688b8", "R305 changed; inspect before proceeding")
local rootName = "SGV2_Phase3_Study_" .. spec.id
assert(not workspace:FindFirstChild(rootName), "Study already exists")
local raw = game.ServerStorage["SGV2_Phase3_Raw_" .. spec.id]
local witnesses, sources = {}, {}
for _, object in raw:GetDescendants() do
    assert(not object:IsA("LuaSourceContainer"), "Imported scripts are forbidden")
    if object:IsA("BasePart") then
        assert(object:IsA("MeshPart"), "Unexpected imported part type")
        if object.Name:sub(1,3) == "Cal" then
            witnesses[object.Name] = object
        else
            assert(spec.meshes[object.Name], "Unknown imported mesh")
            table.insert(sources, object)
        end
    end
end
assert(#sources == spec.meshCount, "Missing imported mesh")
assert(witnesses.CalO and witnesses.CalX and witnesses.CalY and witnesses.CalZ, "Missing witnesses")
local origin = witnesses.CalO.Position
local x = witnesses.CalX.Position - origin
local y = witnesses.CalY.Position - origin
local z = witnesses.CalZ.Position - origin
local unit = (x.Magnitude + y.Magnitude + z.Magnitude) / 72
for _, v in {x,y,z} do assert(math.abs(v.Magnitude/unit-24)<.003, "Uneven import scale") end
assert(x.Unit:Cross(y.Unit):Dot(z.Unit)>.99999, "Mirrored import")
assert(math.abs(x.Unit:Dot(y.Unit))<.00001 and math.abs(x.Unit:Dot(z.Unit))<.00001, "Skewed import")
local importedFrame = CFrame.fromMatrix(origin,x.Unit,y.Unit,z.Unit)
local target = CFrame.new(9900,80,3500)
local region = spec.region
local study = Instance.new("Model")
study.Name = rootName
study:SetAttribute("CandidateId",spec.candidate)
study:SetAttribute("SourceAssetId",spec.assetId)
study:SetAttribute("SourceFbxSha256",spec.fbxSha256)
study:SetAttribute("SourceTriangles",spec.triangles)
study:SetAttribute("ImportedUnitsPerStud",unit)
study:SetAttribute("GameplayValidated",false)
study:SetAttribute("Purpose","Static representative-area import study; no runtime integration")
local art = Instance.new("Folder")
art.Name = "Art"
art.Parent = study
local maxBoundError = 0
for _, source in sources do
    local row = spec.meshes[source.Name]
    local part = source:Clone()
    local localFrame = importedFrame:ToObjectSpace(source.CFrame)
    part.Size = source.Size/unit
    local nativeFrame = CFrame.new(localFrame.Position/unit)*localFrame.Rotation
    local h = part.Size/2
    local radius = Vector3.new(
        math.abs(nativeFrame.XVector.X)*h.X+math.abs(nativeFrame.YVector.X)*h.Y+math.abs(nativeFrame.ZVector.X)*h.Z,
        math.abs(nativeFrame.XVector.Y)*h.X+math.abs(nativeFrame.YVector.Y)*h.Y+math.abs(nativeFrame.ZVector.Y)*h.Z,
        math.abs(nativeFrame.XVector.Z)*h.X+math.abs(nativeFrame.YVector.Z)*h.Y+math.abs(nativeFrame.ZVector.Z)*h.Z)
    local lo,hi = nativeFrame.Position-radius,nativeFrame.Position+radius
    maxBoundError = math.max(maxBoundError,(lo-Vector3.new(unpack(row.bounds[1]))).Magnitude,
        (hi-Vector3.new(unpack(row.bounds[2]))).Magnitude)
    part.CFrame = target*nativeFrame
    part.Color = Color3.fromHex(row.hex)
    part.Material = Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = false
    part.CanTouch = false
    part.CanQuery = false
    part.DoubleSided = false
    part:SetAttribute("Role","Phase3 scenery study")
    part.Parent = art
end
assert(maxBoundError < .02, "Import geometry bounds differ")
local context = Instance.new("Folder")
context.Name = "R305Context"
context.Parent = study
local nativeOrigin = Vector3.new(9200,80,3500)
local copied, colliders = 0, 0
local studded = {}
for _, path in spec.studdedSourceParts do studded[path] = true end
for _, source in original:GetDescendants() do
    assert(not source:IsA("LuaSourceContainer"), "Source course contains scripts")
    if source:IsA("BasePart") then
        local p = source.Position-nativeOrigin
        if p.X>=region[1] and p.X<=region[2] and p.Z>=region[3] and p.Z<=region[4] then
            local path = source:GetFullName():sub(#original:GetFullName()+2)
            local parent = context
            local segments = string.split(path,".")
            for i=1,#segments-1 do
                local folder = parent:FindFirstChild(segments[i])
                if not folder then folder=Instance.new("Folder");folder.Name=segments[i];folder.Parent=parent end
                parent = folder
            end
            local copy = source:Clone()
            copy.CFrame = CFrame.new(target.Position-nativeOrigin)*copy.CFrame
            if studded[path] then copy.TopSurface=Enum.SurfaceType.Smooth end
            copy:SetAttribute("SourceR305Path",path)
            copy.Parent = parent
            copied += 1
            if copy.CanCollide then colliders += 1 end
        end
    end
end
local ground = Instance.new("Part")
ground.Name = "StudyGround"
ground.Anchored = true
ground.Size = Vector3.new(region[2]-region[1],1.5,region[4]-region[3])
ground.CFrame = target*CFrame.new((region[1]+region[2])/2,-3.55,(region[3]+region[4])/2)
ground.Color = Color3.fromHex("74A73B")
ground.Material = Enum.Material.SmoothPlastic
ground.CanTouch = false
ground.TopSurface = Enum.SurfaceType.Smooth
ground.BottomSurface = Enum.SurfaceType.Smooth
ground.Parent = study
local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude
overlapParams.FilterDescendantsInstances = {workspace.Terrain}
local boundsCf, boundsSize = study:GetBoundingBox()
assert(#workspace:GetPartBoundsInBox(boundsCf,boundsSize+Vector3.new(6,6,6),overlapParams)==0,
    "Study location is occupied")
study.PrimaryPart = ground
study.Parent = workspace
assert(fingerprint(original).hash=="d17688b8", "R305 preservation failed")
return http:JSONEncode({candidate=spec.candidate,path=study:GetFullName(),assetId=spec.assetId,
    importedMeshes=#sources,contextParts=copied,contextColliders=colliders,groundColliders=1,
    unitsPerStud=unit,maxBoundError=maxBoundError,fingerprint=fingerprint(study),
    sourceCourse=fingerprint(original),camera={workspace.CurrentCamera.CFrame:GetComponents()}})
