assert(false, "Backup export requires separate approval for the local HTTP receiver; use InstallVerify56 for local-only installation")
local ss = game:GetService("ServerStorage")
local H = game:GetService("HttpService")
local rec = ss.MoonlitP3ReworkRecovery.VeilCorrection20261020
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818)
assert(not game:GetService("RunService"):IsRunning())
local expectedHash = "995134fe3e5e6e895c3a48b51e5a360509b6b6d8a90ed27a604eec414e01e31b"
local oldHttp = H.HttpEnabled
local editor = H:JSONDecode(rec.EditorBefore.Value)
local function restoreEditor()
    H.HttpEnabled = oldHttp
    workspace.CurrentCamera.CFrame = CFrame.new(table.unpack(editor.camera))
    workspace.CurrentCamera.Focus = CFrame.new(table.unpack(editor.focus))
    workspace.CurrentCamera.FieldOfView = editor.fov
end
local function hash(b)
    local digest = game:GetService("EncodingService"):ComputeBufferHash(b, Enum.HashAlgorithm.Sha256)
    local out = {}
    for i = 0, buffer.len(digest) - 1 do out[#out + 1] = string.format("%02x", buffer.readu8(digest, i)) end
    return table.concat(out)
end
local function post(name, data)
    local b = if typeof(data) == "buffer" then data else buffer.fromstring(data)
    local response = H:RequestAsync({Url = "http://127.0.0.1:56151/" .. name,
        Method = "POST", Body = buffer.tostring(b), Headers = {["Content-Type"] = "application/octet-stream"}})
    assert(response.Success, response.Body)
    local receipt = H:JSONDecode(response.Body)
    assert(receipt.bytes == buffer.len(b) and receipt.sha256 == hash(b))
    return receipt
end
local function parts(root)
    local result = {}
    for _, p in root:GetDescendants() do
        if not p:IsA("BasePart") then continue end
        result[p:GetFullName():sub(#root:GetFullName() + 2)] = {
            cf = {p.CFrame:GetComponents()}, size = {p.Size.X, p.Size.Y, p.Size.Z},
            color = {p.Color.R, p.Color.G, p.Color.B}, material = p.Material.Name,
            transparency = p.Transparency, anchored = p.Anchored, collide = p.CanCollide,
            touch = p.CanTouch, query = p.CanQuery, shadow = p.CastShadow,
            mesh = if p:IsA("MeshPart") then p.MeshId else ""}
    end
    return result
end
local function equal(a, b)
    if type(a) ~= "table" then return a == b end
    if type(b) ~= "table" then return false end
    for k, v in a do if not equal(v, b[k]) then return false end end
    for k in b do if a[k] == nil then return false end end
    return true
end
local function near(a, b)
    if type(a) == "number" and type(b) == "number" then return math.abs(a - b) <= .0005 end
    if type(a) ~= "table" then return a == b end
    if type(b) ~= "table" then return false end
    for k, v in a do if not near(v, b[k]) then return false end end
    for k in b do if a[k] == nil then return false end end
    return true
end
local ok, result = xpcall(function()
    H.HttpEnabled = true
    local raw = H:GetAsync("http://127.0.0.1:56151/repair_veil56_packet.json")
    assert(hash(buffer.fromstring(raw)) == expectedHash)
    local packet = H:JSONDecode(raw)
    assert(packet.sourceRevision == 56 and packet.buildRevision == 50)
    for _, row in packet.records do
        local module = if row.name == "MoonlitCitadelAmbienceConfig" then game.ReplicatedStorage.Config[row.name]
            else ss.CourseBuilders.MoonlitCitadelCourse[row.name]
        assert(module.Source:gsub("\r\n", "\n") == row.source, row.name)
    end
    assert(not rec:FindFirstChild("FinalCandidate56"))
    local candidate = ss.CourseBuilders.MoonlitCitadelCourse:Clone()
    candidate.Name, candidate.Parent = "FinalCandidate56", rec
    local D, W = require(candidate.DepthPlan), require(candidate.WorldPlan)
    local L, E = require(candidate.Layout), require(candidate.EnvironmentPlan)
    local plan, counts = W.Get(L)
    local outer, outerCounts = E.Get(L, counts.plantingMounts, counts.assemblies)
    assert(#plan + #outer == 315 and counts.meshParts + outerCounts.meshParts == 869)
    assert(counts.triangles + outerCounts.triangles == 271658)
    local chunkList = rec.BeforeParts55:GetChildren()
    table.sort(chunkList, function(a, b) return a.Name < b.Name end)
    local chunks = {}
    for _, s in chunkList do table.insert(chunks, s.Value) end
    local beforeRaw = table.concat(chunks)
    local before = H:JSONDecode(beforeRaw)
    local models = {workspace.Course_MoonlitCitadel, ss.CourseLibrary.Course_MoonlitCitadel}
    local reports = {}
    for index, model in models do
        local scope = if index == 1 then "Editable" else "Stored"
        local oldVeil = assert(model.Decoration:FindFirstChild("MoonlitDepthVeil"))
        oldVeil.Name, oldVeil.Parent = "InitialVeil56", rec[scope]
        local veil = D.Apply(model)
        local emitters = 0
        for _, a in veil:GetChildren() do
            assert(a:IsA("Part") and a.Anchored and a.Transparency == 1)
            assert(not a.CanCollide and not a.CanTouch and not a.CanQuery)
            local e = assert(a:FindFirstChildOfClass("ParticleEmitter"))
            assert(e.Orientation == Enum.ParticleOrientation.VelocityPerpendicular)
            assert(e.EmissionDirection == Enum.NormalId.Top and e.Speed.Max == .02)
            local maxY = a.Position.Y - model:GetAttribute("Origin").Y + a.Size.Y / 2 + e.Speed.Max * e.Lifetime.Max
            assert(maxY <= -28.019, "Mist reaches the route")
            e:Emit(8)
            emitters += 1
        end
        assert(emitters == 12)
        local current = parts(model)
        local stable, removed, oldNames = 0, 0, {}
        local ravinePrefix = "Decoration.Phase3World.JoinedRavineRidges.MC_EC_InnerRavine."
        for _, row in before[index].parts do
            oldNames[row.path] = true
            if row.path:sub(1, #ravinePrefix) == ravinePrefix then removed += 1; continue end
            local expected = table.clone(row); expected.path = nil
            assert(equal(expected, current[row.path]), row.path)
            stable += 1
        end
        local added = 0
        for path in current do
            if oldNames[path] then continue end
            local veilPrefix = "Decoration.MoonlitDepthVeil."
            assert(path:sub(1, #ravinePrefix) == ravinePrefix or path:sub(1, #veilPrefix) == veilPrefix, path)
            added += 1
        end
        assert(stable == 1760 and removed == 2 and added == 15)
        local original = ss.MoonlitP3ReworkRecovery.Repair20261019.OriginalWorlds54[scope].Phase3World.JoinedRavineRidges.MC_EC_InnerRavine
        local restored = model.Decoration.Phase3World.JoinedRavineRidges.MC_EC_InnerRavine
        assert(equal(parts(original), parts(restored)), "Original floor is not exact")
        model:SetAttribute("SourceRevision", 56); model:SetAttribute("BuildRevision", 50)
        model:SetAttribute("CandidateId", "MC_P3_VEIL_20261020")
        model:SetAttribute("SourcePacketHash", expectedHash)
        model:SetAttribute("DepthVeilApplied", true)
        model.Decoration.Phase3World:SetAttribute("ArtRepairCandidate", W.Candidate)
        model.Decoration.Phase3World:SetAttribute("DetailCandidate", W.Candidate)
        table.insert(reports, {path = model:GetFullName(), stableParts = stable,
            replacedChasmParts = removed, restoredFloorParts = 3, mistAnchors = 12,
            expectedAddedParts = added, originalFloorExact = true, allOtherGeometryExact = true})
    end
    local fixture = models[2]:Clone()
    fixture.Name, fixture.Parent = "AssemblyFixture56", rec
    local held = Instance.new("Folder"); held.Name, held.Parent = "OwnedFixtureCopies56", rec
    fixture.Decoration.Phase3World.Parent = held
    fixture.Decoration.MoonlitDepthVeil.Parent = held
    require(candidate.WorldAssembly).Apply(fixture, L)
    assert(near(parts(models[2].Decoration.Phase3World), parts(fixture.Decoration.Phase3World)), "Fresh scenery differs")
    assert(near(parts(models[2].Decoration.MoonlitDepthVeil), parts(fixture.Decoration.MoonlitDepthVeil)), "Fresh veil differs")
    fixture:Destroy(); held:Destroy()
    local report = {pass = true, source = 56, build = 50, packetSHA256 = expectedHash,
        models = reports, packetModules = #packet.records, scenery = {units = 315, meshes = 869, triangles = 271658},
        freshAssemblyMatches = true, freshAssemblyNumericTolerance = .0005, floorRemovalSuperseded = true,
        ambienceSourceMatchesPacket = true, editorRestorationSeparatelyChecked = true,
        proofLimit = "Focused local visual preview and exact geometry/source checks; no full traversal or new panel scores."}
    local proof = Instance.new("StringValue"); proof.Name, proof.Value, proof.Parent = "FinalProof56", H:JSONEncode(report), rec
    rec:SetAttribute("FinalPacketSHA256", expectedHash)
    local S, files = game:GetService("SerializationService"), {}
    table.insert(files, post("repair_veil56_models.rbxm", S:SerializeInstancesAsync(models)))
    table.insert(files, post("repair_veil56_modules.rbxm", S:SerializeInstancesAsync({ss.CourseBuilders.MoonlitCitadelCourse, game.ReplicatedStorage.Config.MoonlitCitadelAmbienceConfig})))
    table.insert(files, post("repair_veil56_recovery.rbxm", S:SerializeInstancesAsync({rec})))
    table.insert(files, post("repair_veil56_native_audit.json", H:JSONEncode(report)))
    table.insert(files, post("repair_veil56_before_parts.json", beforeRaw))
    local receipt = {source = 56, build = 50, packetSHA256 = expectedHash, files = files, noPublish = true, noWholePlaceSave = true}
    local final = post("repair_veil56_receipt.json", H:JSONEncode(receipt))
    return {report = report, receipt = final}
end, debug.traceback)
restoreEditor()
assert(ok, result)
return result
