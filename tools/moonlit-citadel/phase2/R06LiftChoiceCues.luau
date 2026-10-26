local function apply(port)
	assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local H, E, S = game.HttpService, game.EncodingService, game.SerializationService
	local previousHttp = H.HttpEnabled
	local function hash(bytes)
		local digest, hex = E:ComputeBufferHash(bytes, Enum.HashAlgorithm.Sha256), {}
		for index = 0, buffer.len(digest) - 1 do hex[#hex + 1] = string.format("%02x", buffer.readu8(digest, index)) end
		return table.concat(hex)
	end
	local function save(name, items)
		local bytes = S:SerializeInstancesAsync(items)
		local response = H:RequestAsync({Url = "http://127.0.0.1:" .. port .. "/MC_P2_R06_cues09_" .. name .. ".rbxm",
			Method = "POST", Headers = {["Content-Type"] = "application/octet-stream"}, Body = buffer.tostring(bytes)})
		assert(response.Success, response.StatusCode)
		local receipt = H:JSONDecode(response.Body)
		assert(receipt.sha256 == hash(bytes))
		return receipt
	end
	local library = game.ServerStorage.CourseLibrary
	local course, editing = library.Course_MoonlitCitadel, workspace.Course_MoonlitCitadel
	assert(course:GetAttribute("CandidateId") == "MC_P2_C01_R06" and editing:GetAttribute("CandidateId") == "MC_P2_C01_R06")
	assert(editing:GetAttribute("ManualEditing") == true and #library:GetChildren() == 7)
	local source = game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.Wayfinding.Source:gsub("\r\n", "\n")
	assert(hash(buffer.fromstring(source)) == "5b54d43ff12640ec2a10f6b48780620bee207022608521bd2cc4532fb37bc352", "Durable guidance source must sync first")
	local recovery = game.ServerStorage.MoonlitR06OriginalRecovery
	assert(not recovery:FindFirstChild("LandingChoiceCue09"), "Preserve previous cue application")
	local names = {}
	for _, prefix in {"E3_UpperLiftLandingNormalChoice", "E3_UpperLiftLandingExpertChoice1", "E3_UpperLiftLandingExpertChoice2"} do
		for _, suffix in {"Stem", "Left", "Right"} do names[#names + 1] = prefix .. suffix end
	end
	for _, model in {course, editing} do
		local old = model.Decoration.Wayfinding
		assert(old:GetAttribute("WayfindingVersion") == 8 and old:GetAttribute("BuildComplete") == true)
		for _, name in names do assert(not old:FindFirstChild(name), "Preserve existing guidance") end
		for _, item in old:GetDescendants() do
			if item:IsA("BasePart") then assert(not item.CanCollide and not item.CanQuery and not item.CanTouch and not item.CastShadow) end
		end
	end
	local six = {}
	for _, model in library:GetChildren() do if model ~= course then six[#six + 1] = model end end
	table.sort(six, function(a, b) return a.Name < b.Name end)
	local p1 = {workspace.MoonlitCitadelPhase1_BL02, game.ServerStorage.CourseAssetKits.MoonlitCitadel_BL02Library}
	local r05 = recovery.PreservedOwnerR05.Course_MoonlitCitadel
	local result = {candidate = "MC_P2_C01_R06",addedParts = 0,models = {},files = {},productionSourceSha256 = hash(buffer.fromstring(source))}
	local archive, activeOld, activeModel, added = nil, nil, nil, {}
	local ok, reason = xpcall(function()
		H.HttpEnabled = true
		result.sixBefore = save("before_six", six)
		result.p1Before = save("before_p1", p1)
		result.r05Before = save("before_r05", {r05})
		result.courseBefore = save("before_course", {course})
		result.editingBefore = save("before_editing", {editing})
		archive = Instance.new("Folder"); archive.Name = "LandingChoiceCue09"; archive.Parent = recovery
		local module = Instance.new("ModuleScript"); module.Name = "ExactWayfinding09"; module.Source = source; module.Parent = archive
		module:SetAttribute("OwnedMoonlitTest", true)
		local guidance = require(module)
		local layout = require(game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.Layout)
		for index, model in {course, editing} do
			local staging = Instance.new("Folder"); staging.Name = if index == 1 then "LibraryGuidanceReference" else "EditingGuidanceReference"; staging.Parent = archive
			local old = model.Decoration.Wayfinding
			activeOld, activeModel = old, model
			old.Parent = staging
			local full = guidance.Apply(model, layout)
			assert(full:GetAttribute("WayfindingVersion") == 9)
			for _, name in names do
				local item = assert(full:FindFirstChild(name), name)
				assert(item:IsA("Part") and item.Anchored and not item.CanCollide and not item.CanQuery and not item.CanTouch and not item.CastShadow)
				assert(#item:GetChildren() == 0 and item:GetAttribute("GuidanceKind"):match("^NativeArrow"))
			end
			full.Name = "FullVersion09Reference"; full.Parent = staging
			old.Parent = model.Decoration
			added = {}
			for _, name in names do local item = full[name]:Clone(); item.Parent = old; added[#added + 1] = item end
			old:SetAttribute("WayfindingVersion", 9)
			local counts = {parts = 0, meshes = 0, collide = 0, query = 0, touch = 0, guis = 0, lights = 0}
			for _, item in model:GetDescendants() do
				if item:IsA("BasePart") then
					counts.parts += 1; if item:IsA("MeshPart") then counts.meshes += 1 end
					if item.CanCollide then counts.collide += 1 end; if item.CanQuery then counts.query += 1 end; if item.CanTouch then counts.touch += 1 end
				elseif item:IsA("SurfaceGui") then counts.guis += 1 elseif item:IsA("Light") then counts.lights += 1 end
			end
			assert(counts.parts == 1747 and counts.meshes == 947 and counts.collide == 288 and counts.query == 387 and counts.touch == 83 and counts.guis == 13 and counts.lights == 3)
			result.models[#result.models + 1] = {path = model:GetFullName(),added = #added,counts = counts}
			result.addedParts += #added
			activeOld, activeModel, added = nil, nil, {}
			task.wait()
		end
		result.sixAfter = save("after_six", six); result.p1After = save("after_p1", p1); result.r05After = save("after_r05", {r05})
		assert(result.sixBefore.sha256 == result.sixAfter.sha256 and result.p1Before.sha256 == result.p1After.sha256 and result.r05Before.sha256 == result.r05After.sha256)
		result.courseAfter = save("after_course", {course}); result.editingAfter = save("after_editing", {editing})
		result.preservedSix, result.preservedP1, result.preservedR05 = true, true, true
	end, debug.traceback)
	if not ok and activeOld then
		local current = activeModel.Decoration:FindFirstChild("Wayfinding")
		if current and current ~= activeOld then current.Parent = archive end
		for _, item in added do item.Parent = archive end
		activeOld.Parent = activeModel.Decoration; activeOld:SetAttribute("WayfindingVersion", 8)
	end
	H.HttpEnabled = previousHttp
	result.ok, result.failure, result.httpRestored = ok, if ok then nil else tostring(reason), H.HttpEnabled == previousHttp
	return H:JSONEncode(result)
end
return apply
