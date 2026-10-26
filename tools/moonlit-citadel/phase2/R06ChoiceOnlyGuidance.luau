local function apply(port)
	assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local H, E, S = game.HttpService, game.EncodingService, game.SerializationService
	local previousHttp = H.HttpEnabled
	local function hash(bytes)
		local digest, hex = E:ComputeBufferHash(bytes, Enum.HashAlgorithm.Sha256), {}
		for index = 0, buffer.len(digest) - 1 do hex[#hex + 1] = string.format('%02x', buffer.readu8(digest, index)) end
		return table.concat(hex)
	end
	local function save(name, items)
		local bytes = S:SerializeInstancesAsync(items)
		local response = H:RequestAsync({Url = 'http://127.0.0.1:' .. port .. '/MC_P2_R06_guidance10_' .. name .. '.rbxm',
			Method = 'POST', Headers = {['Content-Type'] = 'application/octet-stream'}, Body = buffer.tostring(bytes)})
		assert(response.Success, response.StatusCode)
		local receipt = H:JSONDecode(response.Body)
		assert(receipt.sha256 == hash(bytes))
		return receipt
	end
	local function protectedRoots(model)
		local roots = {}
		for _, item in model:GetChildren() do
			if item.Name == 'Decoration' then
				for _, child in item:GetChildren() do if child.Name ~= 'Wayfinding' then roots[#roots + 1] = child end end
			else roots[#roots + 1] = item end
		end
		table.sort(roots, function(a, b) return a:GetFullName() < b:GetFullName() end)
		return roots
	end
	local library = game.ServerStorage.CourseLibrary
	local course, editing = library.Course_MoonlitCitadel, workspace.Course_MoonlitCitadel
	assert(course:GetAttribute('CandidateId') == 'MC_P2_C01_R06' and editing:GetAttribute('CandidateId') == 'MC_P2_C01_R06')
	assert(editing:GetAttribute('ManualEditing') == true and #library:GetChildren() == 7)
	local production = game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.Wayfinding
	local oldSource = production.Source:gsub('\r\n', '\n')
	assert(hash(buffer.fromstring(oldSource)) == '5b54d43ff12640ec2a10f6b48780620bee207022608521bd2cc4532fb37bc352')
	local recovery = game.ServerStorage.MoonlitR06OriginalRecovery
	assert(not recovery:FindFirstChild('ChoiceOnlyGuidance10'))
	local six = {}
	for _, model in library:GetChildren() do if model ~= course then six[#six + 1] = model end end
	table.sort(six, function(a, b) return a.Name < b.Name end)
	local p1 = {workspace.MoonlitCitadelPhase1_BL02, game.ServerStorage.CourseAssetKits.MoonlitCitadel_BL02Library}
	local r05 = recovery.PreservedOwnerR05.Course_MoonlitCitadel
	local result = {candidate = 'MC_P2_C01_R06', models = {}}
	local records, archive = {}, nil
	local ok, reason = xpcall(function()
		H.HttpEnabled = true
		local raw = H:GetAsync('http://127.0.0.1:' .. port .. '/MC_P2_R06_guidance10.json')
		assert(hash(buffer.fromstring(raw)) == '5ea48f978a15ea0cb04e9b7654e0a7a35c4ad388ac2e9b97a15ccc4c100965a2')
		local packet = H:JSONDecode(raw)
		assert(packet.candidate == result.candidate and packet.priorNormalizedSha256 == hash(buffer.fromstring(oldSource)))
		assert(packet.normalizedSha256 == hash(buffer.fromstring(packet.source)))
		for _, model in {course, editing} do
			local old = model.Decoration.Wayfinding
			assert(old:GetAttribute('WayfindingVersion') == 9 and old:GetAttribute('BuildComplete') == true)
			for _, item in old:GetDescendants() do
				if item:IsA('BasePart') then assert(item.Anchored and not item.CanCollide and not item.CanQuery and not item.CanTouch and not item.CastShadow) end
			end
		end
		result.sixBefore = save('before_six', six)
		result.p1Before = save('before_p1', p1)
		result.r05Before = save('before_r05', {r05})
		result.courseBefore = save('before_course', {course})
		result.editingBefore = save('before_editing', {editing})
		result.protectedBefore = save('before_protected', protectedRoots(course))
		archive = Instance.new('Folder'); archive.Name = 'ChoiceOnlyGuidance10'; archive.Parent = recovery
		local priorSource = production:Clone(); priorSource.Name = 'Wayfinding09SourceBeforeReduction'; priorSource.Parent = archive
		production.Source = packet.source
		local exact = Instance.new('ModuleScript'); exact.Name = 'ExactWayfinding10'; exact.Source = packet.source
		exact:SetAttribute('OwnedMoonlitTest', true); exact.Parent = archive
		local guidance = require(exact)
		local layout = require(game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.Layout)
		for index, model in {course, editing} do
			local staging = Instance.new('Folder'); staging.Name = if index == 1 then 'LibraryGuidance09' else 'EditingGuidance09'; staging.Parent = archive
			local old = model.Decoration.Wayfinding
			local record = {model = model, old = old}; records[#records + 1] = record
			old.Parent = staging
			local new = guidance.Apply(model, layout); record.new = new
			assert(new:GetAttribute('WayfindingVersion') == 10 and new:GetAttribute('BuildComplete') == true)
			local arrows, boards, captions, trimCorners = {}, 0, 0, 0
			for _, item in new:GetDescendants() do
				if not item:IsA('BasePart') then continue end
				assert(item.Anchored and not item.CanCollide and not item.CanQuery and not item.CanTouch and not item.CastShadow)
				local kind = item:GetAttribute('GuidanceKind')
				if kind == 'NativeArrowStem' then arrows[#arrows + 1] = item:GetAttribute('ArrowId') end
				if kind == 'DecisionSign' then boards += 1 end
				if kind == 'DifficultyCaption' then captions += 1 end
				if kind == 'LandingTrim' or kind == 'ExpertCommitment' then
					local path = item:GetAttribute('SourceContact')
					local contact = game
					for token in path:gmatch('[^.]+') do contact = assert(contact:FindFirstChild(token), path) end
					for _, x in {-1, 1} do for _, z in {-1, 1} do
						local corner = contact.CFrame:PointToObjectSpace(item.CFrame:PointToWorldSpace(Vector3.new(x * item.Size.X / 2, 0, z * item.Size.Z / 2)))
						assert(math.abs(corner.X) <= contact.Size.X / 2 - .115 and math.abs(corner.Z) <= contact.Size.Z / 2 - .115, item.Name .. ' exceeds supported footprint')
						trimCorners += 1
					end end
				end
			end
			table.sort(arrows)
			assert(#arrows == 7 and boards == 3 and captions == 0 and trimCorners == 292)
			local counts = {parts = 0, meshes = 0, collide = 0, query = 0, touch = 0, guis = 0, lights = 0}
			for _, item in model:GetDescendants() do
				if item:IsA('BasePart') then
					counts.parts += 1; if item:IsA('MeshPart') then counts.meshes += 1 end
					if item.CanCollide then counts.collide += 1 end; if item.CanQuery then counts.query += 1 end; if item.CanTouch then counts.touch += 1 end
				elseif item:IsA('SurfaceGui') then counts.guis += 1 elseif item:IsA('Light') then counts.lights += 1 end
			end
			assert(counts.parts == 1503 and counts.meshes == 947 and counts.collide == 288 and counts.query == 387 and counts.touch == 83 and counts.guis == 6 and counts.lights == 3)
			result.models[#result.models + 1] = {path = model:GetFullName(), counts = counts, arrows = arrows, boards = boards, captions = captions, supportedTrimCorners = trimCorners}
			task.wait()
		end
		result.protectedAfter = save('after_protected', protectedRoots(course))
		assert(result.protectedBefore.sha256 == result.protectedAfter.sha256, 'Course outside guidance changed')
		result.sixAfter = save('after_six', six); result.p1After = save('after_p1', p1); result.r05After = save('after_r05', {r05})
		assert(result.sixBefore.sha256 == result.sixAfter.sha256 and result.p1Before.sha256 == result.p1After.sha256 and result.r05Before.sha256 == result.r05After.sha256)
		result.courseAfter = save('after_course', {course}); result.editingAfter = save('after_editing', {editing})
		result.sourceSha256 = packet.normalizedSha256
		result.preservedPhysics, result.preservedSix, result.preservedP1, result.preservedR05 = true, true, true, true
	end, debug.traceback)
	if not ok then
		for _, record in records do
			local current = record.model.Decoration:FindFirstChild('Wayfinding')
			if current and current ~= record.old then current.Parent = archive end
			record.old.Parent = record.model.Decoration
		end
		production.Source = oldSource
	end
	H.HttpEnabled = previousHttp
	result.ok, result.failure, result.httpRestored = ok, if ok then nil else tostring(reason), H.HttpEnabled == previousHttp
	return H:JSONEncode(result)
end
return apply
