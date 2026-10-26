assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning(), "Expected intended Edit place")
local http = game:GetService("HttpService")
local spec = http:JSONDecode([====[__SPEC__]====])
local raw = assert(game.ServerStorage:FindFirstChild("SGV2_Botanical_Raw_R01"))
local sources, witnesses = {}, {}
for _, part in raw:GetDescendants() do
    assert(not part:IsA("LuaSourceContainer"), "Unexpected imported script")
    if part:IsA("BasePart") then
        assert(part:IsA("MeshPart"), "Unexpected imported part")
        if part.Name:sub(1, 3) == "Cal" then witnesses[part.Name] = part
        else assert(not sources[part.Name], "Duplicate mesh"); sources[part.Name] = part end
    end
end
local o = witnesses.CalO.Position
local x, y, z = witnesses.CalX.Position-o, witnesses.CalY.Position-o, witnesses.CalZ.Position-o
local units = (x.Magnitude+y.Magnitude+z.Magnitude)/72
assert(x.Unit:Cross(y.Unit):Dot(z.Unit) > .99999, "Mirrored import")
for _, axis in {x,y,z} do assert(math.abs(axis.Magnitude/units-24)<.003, "Uneven scale") end
assert(math.abs(x.Unit:Dot(y.Unit))<.00001 and math.abs(x.Unit:Dot(z.Unit))<.00001, "Skewed import")
local importedFrame = CFrame.fromMatrix(o,x.Unit,y.Unit,z.Unit)
local target = workspace.SGV2_Phase3_F04:GetPivot()
local output = Instance.new("Model")
output.Name = "BotanicalRefinement"
output.WorldPivot = target
local maxError, ledger = 0, {}
local priorHttp = http.HttpEnabled
local ok, result = xpcall(function()
    for _, row in spec.meshes do
        local source = assert(sources[row.name], "Missing " .. row.name)
        local part = source:Clone()
        for _, child in part:GetChildren() do child:Destroy() end
        part.Size = source.Size/units
        local imported = importedFrame:ToObjectSpace(source.CFrame)
        local cf = CFrame.new(imported.Position/units)*imported.Rotation
        local half = part.Size/2
        local radius = Vector3.new(math.abs(cf.XVector.X)*half.X+math.abs(cf.YVector.X)*half.Y+math.abs(cf.ZVector.X)*half.Z,
            math.abs(cf.XVector.Y)*half.X+math.abs(cf.YVector.Y)*half.Y+math.abs(cf.ZVector.Y)*half.Z,
            math.abs(cf.XVector.Z)*half.X+math.abs(cf.YVector.Z)*half.Y+math.abs(cf.ZVector.Z)*half.Z)
        maxError = math.max(maxError,(cf.Position-radius-Vector3.new(unpack(row.exportBoundsRoblox[1]))).Magnitude,
            (cf.Position+radius-Vector3.new(unpack(row.exportBoundsRoblox[2]))).Magnitude)
        part.CFrame = target*cf
        part.Color = Color3.fromHex(row.hex:sub(2))
        part.Material = Enum.Material.SmoothPlastic
        part.Anchored = true
        part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
        part.DoubleSided = false
        part:SetAttribute("Role", "Decoration")
        part:SetAttribute("BotanicalAssetId", "93948039720913")
        part.Parent = output
        table.insert(ledger, {name=part.Name,meshId=part.MeshId,meshContent=tostring(part.MeshContent)})
    end
    assert(#ledger==147 and maxError<.01, "Import inventory or bounds differ")
    http.HttpEnabled = true
    local serializer = game:GetService("SerializationService")
    local bytes = buffer.tostring(serializer:SerializeInstancesAsync({output}))
    local url = "http://127.0.0.1:8768/botanical-art-r01.rbxm"
    local response = http:RequestAsync({Url=url,Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=bytes})
    assert(response.Success, response.Body)
    assert(http:GetAsync(url,true)==bytes, "Archive readback differs")
    local roots = serializer:DeserializeInstancesAsync(buffer.fromstring(bytes))
    assert(#roots==1 and #roots[1]:GetChildren()==147)
    for _, part in roots[1]:GetChildren() do
        local original = assert(output:FindFirstChild(part.Name))
        assert(part.MeshContent==original.MeshContent and part.MeshId==original.MeshId, "Mesh source roundtrip differs")
        assert((part.CFrame.Position-original.Position).Magnitude<.001)
    end
    roots[1]:Destroy()
    return {receipt=http:JSONDecode(response.Body),units=units,maxBoundError=maxError,meshes=ledger}
end,debug.traceback)
output:Destroy()
http.HttpEnabled = priorHttp
assert(ok,result)
return result
