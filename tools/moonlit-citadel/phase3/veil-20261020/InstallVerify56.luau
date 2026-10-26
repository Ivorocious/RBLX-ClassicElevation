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
    local expectedModules = {
        ["ArtRepairPlan"] = "c1b5bdf4960708cebd6339364bb109cbd52f1b614aa5e6a21efaf865ddb494c5",
        ["AssetGeometry"] = "1eceaf674f2c5711ac911d9f76afe7c1bf71345f1f8fc20dc50dc6f89ac5097d",
        ["BaselineWorldPlan"] = "5962333e1d997cafd2d7a8c49486f29c7007d74b40f62ff9f85d93a54ccb9028",
        ["CliffFinishingPlan"] = "6bd70f3ba58fbed4ea4e4bbe79c4d9b234c09639d4cfde716cbd2439b79c05c1",
        ["Coverage"] = "a4c217ea6d2782ad45ccbbce7cdb6bb6b1a5e0c3e3454009528735974cb7dfb8",
        ["DecorativeClearance"] = "ced18f459bdfd90ae0c6fd28fdc7808daf8eef2df9db378d5786fc3561dd12c7",
        ["DepthPlan"] = "6d21591c6b6f7abed11a02163ff918e6594176a5c7a44b52db8aa90bb5d903a7",
        ["DetailGeometry"] = "c51378e14ae215333c409050519303a8c30db9a88523a11eb5b159ead6a2a4c2",
        ["DetailPlan"] = "2f47993772f29a19edda649048eebdc65dcfa7be7cd6084016c6bac9b8a11739",
        ["EnclosureGeometry"] = "5940a2f5b9dafb76cfddcc7741fb48eee7b3c9737ebfc03ce10e123be4d39883",
        ["EnclosureTerrainDataA"] = "0fa5a2e91bc2dcd35a751691378f8d507ef7adc678b6eca6767f4ca9ada25b24",
        ["EnclosureTerrainDataB"] = "f7896b4d0be2ce1230c53965d143051a1c6f9303cdade854278f399b6db7227b",
        ["EnvironmentPlan"] = "0eba645771f4140c28f1e5be03e4aea23a63aa61c60d05888c2a96e4ad75ec8e",
        ["ExpertRoutes"] = "0bb18932595c541ab0431546668bd3461d89e2d8df9f70215bec9f5b0be4307a",
        ["FortressGeometry"] = "d3dbc624340cc1beff36e63617af1899b299b3916b0f5e3a3b1668faa4f19b48",
        ["Layout"] = "769d4c0cab461c229cdeaec0ba9df1f6623b9c9a40d6c7c2dab20f459985872d",
        ["RouteBuilder"] = "56a619db914bfab2140a770103ad165b0b2232b502d20b645e4d6d666f652576",
        ["RouteHazardGoals"] = "75785b2d418169c43126e2651ff9b064c561e32a13b0d5e0103375db32e196d0",
        ["RouteHazardLayout"] = "f656e8ea5102d515f97dae868232b2f0167cab8ac8b5f89fe306469e91588962",
        ["RouteHazards"] = "3c34133de29c48cef4a6452e05c220915d204a80814cd174b4275f92cde4101c",
        ["Runtime"] = "2269a77062e1387f984bb2b974557f951aaadbf03007ead016d246ab8029c32d",
        ["SceneryRevisions"] = "15f90c7fd1a85fb195e91ea0ad88928c2db6bb6a78e367015b95ce64225e14a3",
        ["Source43WorldPlan"] = "58a32547e486954f8813567a0093260044a60be16e348d25d776a8a5be2b774b",
        ["Source48WorldPlan"] = "a1656e04500dc1800b967df72fe530cf47684fa5be499ed0489f6cda79674e71",
        ["Source49WorldPlan"] = "0d43d3086ab44fa511306adc3e02029d9fe69e5b207e349eb7419ace167fe7e6",
        ["SupportingObstacles"] = "5b5428429427b1c4c7aab3ba89fd722971662281934b69aafd7cae71c9cc0ea3",
        ["SurfaceSeparation"] = "cf0d7080f07a7d006c67614d62f72964483218a697f41c05c76ae73d81d1d57d",
        ["TowerGeometry"] = "0d4318babf420ed8be105502c7ebfb89cc3a7d60307a7a749bf6bd67dc5b08c3",
        ["VisualAssembly"] = "9b2e316de5ec26cd0a2895320d18608f996419a9711c68f3e6038cae75c964bb",
        ["Wayfinding"] = "ae59c948bb659f88bc6d269d57a3d4249b7a14ab28f143b7568fb8f5e6fdcbef",
        ["WindowFinishingPlan"] = "b0e021923c7e727784f0a098ed257b1fd51e431ee96008500e80043a7b182ad9",
        ["WoodlandPlacements"] = "f55890018c3abc6842d4a18eef60497fe765df27ad20787a718d5e4104065887",
        ["WorldAssembly"] = "b42a02435eca830fa6e79acc85bc6e5c5c8e1e26514e942a275989c7d33912cb",
        ["WorldPlan"] = "0303cd2c1448c6991673d39a89fa33811ea878c16693fc05c143d8a1dc769ee6",
        ["MoonlitCitadelAmbienceConfig"] = "f6e6a7b8af2456ad86acdf6f06174903733cc6b52e4f64848756f64628157fb2",
    }
    local packet = {records = {}}
    for name, expected in expectedModules do
        local module = if name == "MoonlitCitadelAmbienceConfig" then game.ReplicatedStorage.Config[name]
            else ss.CourseBuilders.MoonlitCitadelCourse[name]
        assert(hash(buffer.fromstring((module.Source:gsub("\r\n", "\n")))) == expected, name)
        table.insert(packet.records, name)
    end
    local candidate = rec:FindFirstChild("FinalCandidate56")
    if not candidate then
        candidate = ss.CourseBuilders.MoonlitCitadelCourse:Clone()
        candidate.Name, candidate.Parent = "FinalCandidate56", rec
    end
    assert(candidate.DepthPlan.Source == ss.CourseBuilders.MoonlitCitadelCourse.DepthPlan.Source)
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
        local first = oldVeil:FindFirstChildWhichIsA("ParticleEmitter", true)
        if not first or first.Orientation ~= Enum.ParticleOrientation.VelocityPerpendicular then
            assert(not rec[scope]:FindFirstChild("InitialVeil56"))
            oldVeil.Name, oldVeil.Parent = "InitialVeil56", rec[scope]
        end
        local veil = D.Apply(model)
        local emitters = 0
        for _, a in veil:GetChildren() do
            assert(a:IsA("Part") and a.Anchored and a.Transparency == 1)
            assert(not a.CanCollide and not a.CanTouch and not a.CanQuery)
            local e = assert(a:FindFirstChildOfClass("ParticleEmitter"))
            assert(e.Orientation == Enum.ParticleOrientation.VelocityPerpendicular)
            assert(e.EmissionDirection == Enum.NormalId.Top and math.abs(e.Speed.Max - .02) < .000001)
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
    if not rec:FindFirstChild("MoonlitCitadel") then
        ss.CourseBuilders.MoonlitCitadel:Clone().Parent = rec
    end
    local fixture = rec:FindFirstChild("AssemblyFixture56")
    local held = rec:FindFirstChild("OwnedFixtureCopies56")
    if not fixture then
        fixture = models[2]:Clone()
        fixture.Name, fixture.Parent = "AssemblyFixture56", rec
        held = Instance.new("Folder"); held.Name, held.Parent = "OwnedFixtureCopies56", rec
        fixture.Decoration.Phase3World.Parent = held
        fixture.Decoration.MoonlitDepthVeil.Parent = held
    end
    assert(held and not fixture.Decoration:FindFirstChild("Phase3World"))
    local assembly = candidate.WorldAssembly:Clone()
    assembly.Name, assembly.Parent = "WorldAssemblyVerified56", candidate
    require(assembly).Apply(fixture, L)
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
    return report
end, debug.traceback)
restoreEditor()
assert(ok, result)
return result
