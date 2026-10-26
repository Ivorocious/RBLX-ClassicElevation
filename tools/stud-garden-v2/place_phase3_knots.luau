assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning(), "Requires intended Edit place")
local http = game:GetService("HttpService")
local spec = http:JSONDecode([====[__SPEC__]====])
local fingerprint = (function()
__FINGERPRINT__
end)()
local original = workspace.Course_StudGardenV2
local previous = workspace.SGV2_Phase3_F03
assert(fingerprint(original).hash == "d17688b8" and fingerprint(previous).hash == "470ecc4d", "Preserved source changed")
assert(not workspace:FindFirstChild(spec.candidate), "Candidate already exists")
local raw = game.ServerStorage.SGV2_Phase3_Raw_F04
local sources, witnesses = {}, {}
for _, p in raw:GetDescendants() do
    assert(not p:IsA("LuaSourceContainer"), "Unexpected imported script")
    if p:IsA("BasePart") then
        assert(p:IsA("MeshPart"), "Unexpected imported part type")
        if p.Name:sub(1, 3) == "Cal" then witnesses[p.Name] = p
        else assert(not sources[p.Name], "Duplicate imported mesh"); sources[p.Name] = p end
    end
end
local o = witnesses.CalO.Position
local x, y, z = witnesses.CalX.Position-o, witnesses.CalY.Position-o, witnesses.CalZ.Position-o
local units = (x.Magnitude+y.Magnitude+z.Magnitude)/72
assert(x.Unit:Cross(y.Unit):Dot(z.Unit) > .99999, "Mirrored import")
for _, axis in {x,y,z} do assert(math.abs(axis.Magnitude/units-24)<.003, "Uneven import scale") end
assert(math.abs(x.Unit:Dot(y.Unit))<.00001 and math.abs(x.Unit:Dot(z.Unit))<.00001, "Skewed import")
local importedFrame = CFrame.fromMatrix(o,x.Unit,y.Unit,z.Unit)
local target = CFrame.new(unpack(spec.target))
local delta = CFrame.new(target.Position-Vector3.new(10900,80,3500))
local candidate = previous:Clone()
candidate.Name = spec.candidate
assert(fingerprint(candidate).hash == "470ecc4d", "Clone differs before changes")
for _, object in {candidate,unpack(candidate:GetDescendants())} do
    for key,value in object:GetAttributes() do
        if key == "RespawnCFrame" then object:SetAttribute(key,delta*value)
        elseif key == "CourseOrigin" then object:SetAttribute(key,value+delta.Position) end
    end
end
candidate:PivotTo(delta*previous:GetPivot())
candidate:SetAttribute("CandidateId",spec.candidate)
candidate:SetAttribute("ParentCandidateFingerprint","470ecc4d")
candidate:SetAttribute("KnotAssetId",spec.assetId)
candidate:SetAttribute("KnotFbxSha256",spec.fbxSha256)
candidate:SetAttribute("SourceTriangles",469312+spec.addedTriangles)
local folder = Instance.new("Folder")
folder.Name = "Phase3KnotCorrection"
folder.Parent = candidate
local changed, added, maximumBoundError = {}, {}, 0
for index,row in spec.meshes do
    local source = assert(sources[row.name],"Missing imported knot")
    local part = game:GetService("AssetService"):CreateMeshPartAsync(source.MeshContent, {
        CollisionFidelity = Enum.CollisionFidelity.Hull,
        RenderFidelity = Enum.RenderFidelity.Precise,
    })
    part.Name = row.name
    part.Size = source.Size/units
    local imported = importedFrame:ToObjectSpace(source.CFrame)
    local cf = CFrame.new(imported.Position/units)*imported.Rotation
    local h = part.Size/2
    local radius = Vector3.new(math.abs(cf.XVector.X)*h.X+math.abs(cf.YVector.X)*h.Y+math.abs(cf.ZVector.X)*h.Z,
        math.abs(cf.XVector.Y)*h.X+math.abs(cf.YVector.Y)*h.Y+math.abs(cf.ZVector.Y)*h.Z,
        math.abs(cf.XVector.Z)*h.X+math.abs(cf.YVector.Z)*h.Y+math.abs(cf.ZVector.Z)*h.Z)
    maximumBoundError = math.max(maximumBoundError,(cf.Position-radius-Vector3.new(unpack(row.exportBoundsRoblox[1]))).Magnitude,
        (cf.Position+radius-Vector3.new(unpack(row.exportBoundsRoblox[2]))).Magnitude)
    part.CFrame = target*cf
    part.Color = Color3.new(unpack(row.color))
    part.Material = Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = true
    part.CanQuery = true
    part.CanTouch = false
    part.DoubleSided = false
    part:SetAttribute("Role","Blocker")
    part:SetAttribute("ReplacementSourcePath",row.sourcePath)
    part:SetAttribute("CorrectionIndex",index)
    part.Parent = folder
    local oldPosition = Vector3.new(row.sourceCf[1],row.sourceCf[2],row.sourceCf[3])+target.Position-Vector3.new(9200,80,3500)
    local old, matches = nil, 0
    for _, p in candidate:GetDescendants() do
        if p:IsA("BasePart") and p:GetAttribute("SourceR305Path")==row.sourcePath and (p.Position-oldPosition).Magnitude<.01 then
            old=p; matches+=1
        end
    end
    assert(matches==1 and old:IsA("Part") and old.Shape==Enum.PartType.Cylinder,"Source cylinder not unique")
    old:SetAttribute("F04ReplacementMesh",row.name)
    old.Transparency=1
    old.CanCollide=false; old.CanQuery=false; old.CanTouch=false
    table.insert(changed,{path=row.sourcePath,position={old.Position.X,old.Position.Y,old.Position.Z},replacement=row.name})
    table.insert(added,{name=part.Name,meshId=part.MeshId,collisionFidelity=part.CollisionFidelity.Name,size={part.Size.X,part.Size.Y,part.Size.Z}})
end
assert(maximumBoundError<.01 and #added==9 and #changed==9,"Knot import differs")
assert(candidate.CourseInfo:GetAttribute("Enabled")==false,"Expected disabled preview")
local box,size=candidate:GetBoundingBox()
local params=OverlapParams.new()
params.FilterType=Enum.RaycastFilterType.Exclude
params.FilterDescendantsInstances={workspace.Terrain}
assert(#workspace:GetPartBoundsInBox(box,size+Vector3.new(6,6,6),params)==0,"Destination occupied")
candidate.Parent=workspace
assert(fingerprint(original).hash=="d17688b8" and fingerprint(previous).hash=="470ecc4d","Preservation failed")
local counts={parts=0,meshes=0,colliders=0,scripts=0}
for _,p in candidate:GetDescendants() do
    if p:IsA("BasePart") then counts.parts+=1; if p.CanCollide then counts.colliders+=1 end end
    if p:IsA("MeshPart") then counts.meshes+=1 end
    if p:IsA("LuaSourceContainer") then counts.scripts+=1 end
end
return http:JSONEncode({candidate=spec.candidate,assetId=spec.assetId,fingerprint=fingerprint(candidate),
    previous=fingerprint(previous),original=fingerprint(original),target=spec.target,unitsPerStud=units,
    maxBoundError=maximumBoundError,changedCylinders=changed,addedKnots=added,counts=counts,
    enabled=candidate.CourseInfo:GetAttribute("Enabled"),running=game:GetService("RunService"):IsRunning()})
