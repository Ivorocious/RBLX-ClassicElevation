--!nonstrict
return function(port)
	assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local H, before = game.HttpService, game.HttpService.HttpEnabled
	local report = {}
	local ok, failure = xpcall(function()
		H.HttpEnabled = true
		local response = H:RequestAsync({Url = "http://127.0.0.1:" .. port .. "/rw10_art_manifest.json", Method = "GET"})
		assert(response.Success, response.StatusCode)
		local bytes = game.EncodingService:ComputeBufferHash(buffer.fromstring(response.Body), Enum.HashAlgorithm.Sha256)
		local hex = {}; for i = 0, buffer.len(bytes) - 1 do hex[#hex + 1] = string.format("%02x", buffer.readu8(bytes, i)) end
		assert(table.concat(hex) == "6d689ad89622cc00712b41656dd5f62272140b7aa5fb2047cf0c6711850ac06d")
		local manifest = H:JSONDecode(response.Body)
		assert(manifest.candidate == "MC_P3_REWORK_KIT_RW01" and manifest.part_count == 9)
		local destination = game.ServerStorage.CourseAssetKits
		assert(not destination:FindFirstChild("MoonlitCitadel_P3Rework_RW01Library"), "Preserve existing library")
		local loaded = game.InsertService:LoadAsset(72902160709807)
		local expected, found = {}, {}
		for _, row in manifest.export_parts do expected[row.name] = row end
		local count, maxError = 0, 0
		for _, p in loaded:GetDescendants() do
			assert(not p:IsA("LuaSourceContainer"), "Imported scripts are not permitted")
			if not p:IsA("BasePart") then continue end
			assert(p:IsA("MeshPart") and expected[p.Name], "Unexpected imported part " .. p.Name)
			local delta = (p.Size - Vector3.new(table.unpack(expected[p.Name].roblox_size))).Magnitude
			assert(delta < .003, "Imported size mismatch " .. p.Name .. ":" .. delta)
			maxError = math.max(maxError, delta); count += 1; assert(not found[p.Name]); found[p.Name] = p
		end
		assert(count == 9)
		local library = destination.MoonlitCitadel_P3World_C01Library:Clone()
		library.Name = "MoonlitCitadel_P3Rework_RW01Library"
		for _, row in manifest.export_parts do
			local unit = library:FindFirstChild(row.asset)
			if not unit then unit = Instance.new("Model"); unit.Name, unit.Parent = row.asset, library; unit.WorldPivot = CFrame.identity end
			local p = found[row.name]:Clone()
			p.Size, p.CFrame = Vector3.new(table.unpack(row.roblox_size)), CFrame.new(Vector3.new(table.unpack(row.roblox_center)))
			p.Color = Color3.fromRGB(table.unpack(row.rgb))
			p.Material = if row.material:find("Stone", 1, true) then Enum.Material.Limestone else Enum.Material.SmoothPlastic
			p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 0
			p.CastShadow = not (row.material == "Arrow" or row.material == "Mount" or row.material == "Leaf" or row.material == "Flower")
			p:SetAttribute("Role", "Decoration"); p:SetAttribute("SourceAsset", row.asset); p:SetAttribute("SourceMaterial", row.material); p:SetAttribute("SourceTriangles", row.triangles)
			p.Parent = unit
		end
		library.WorldPivot = CFrame.identity
		library:SetAttribute("ReworkImportVerified", true); library:SetAttribute("ImportVerified", true)
		library:SetAttribute("ReworkAssetId", "72902160709807"); library:SetAttribute("ReworkSourceSHA256", "c5fbf73691013f9aec1f7be1a6abb8529e4b28ac5d6f8d08a2fc777ff06cac28")
		loaded.Name = "MoonlitCitadel_P3Rework_RW01Import"
		local imports = game.ServerStorage:FindFirstChild("AssetImports") or Instance.new("Folder"); imports.Name, imports.Parent = "AssetImports", game.ServerStorage
		loaded.Parent, library.Parent = imports, destination
		local native = game.SerializationService:SerializeInstancesAsync({library})
		local saved = H:RequestAsync({Url = "http://127.0.0.1:" .. port .. "/rw10_art_library.rbxm", Method = "POST", Headers = {["Content-Type"] = "application/octet-stream"}, Body = buffer.tostring(native)})
		assert(saved.Success, saved.StatusCode)
		report = {parts = count, maxSizeError = maxError, assetId = "72902160709807", library = library:GetFullName(), receipt = H:JSONDecode(saved.Body)}
	end, debug.traceback)
	H.HttpEnabled = before
	report.ok, report.failure, report.httpRestored = ok, failure, H.HttpEnabled == before
	return H:JSONEncode(report)
end
