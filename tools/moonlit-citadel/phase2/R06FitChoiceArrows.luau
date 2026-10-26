local function apply(port)
	assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local H, E, S = game.HttpService, game.EncodingService, game.SerializationService
	local beforeHttp = H.HttpEnabled
	local function hash(bytes)
		local b, out = E:ComputeBufferHash(bytes, Enum.HashAlgorithm.Sha256), {}
		for i = 0, buffer.len(b) - 1 do out[#out + 1] = string.format('%02x', buffer.readu8(b, i)) end
		return table.concat(out)
	end
	local function save(name, roots)
		local bytes = S:SerializeInstancesAsync(roots)
		local response = H:RequestAsync({Url = 'http://127.0.0.1:' .. port .. '/MC_P2_R06_guidance11_' .. name .. '.rbxm', Method = 'POST',
			Headers = {['Content-Type'] = 'application/octet-stream'}, Body = buffer.tostring(bytes)})
		assert(response.Success, response.StatusCode)
		local receipt = H:JSONDecode(response.Body); assert(receipt.sha256 == hash(bytes)); return receipt
	end
	local production = game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.Wayfinding
	local oldSource = production.Source:gsub('\r\n', '\n')
	assert(hash(buffer.fromstring(oldSource)) == 'e0936f1fe499f79fed8a736d72ab2f18060b9ec439f5293abeb12d9a9c80c16e')
	local recovery = game.ServerStorage.MoonlitR06OriginalRecovery
	assert(not recovery:FindFirstChild('ChoiceArrowFit11'))
	local records, folders, result = {}, {}, {candidate = 'MC_P2_C01_R06', moved = 0}
	local ok, reason = xpcall(function()
		H.HttpEnabled = true
		local raw = H:GetAsync('http://127.0.0.1:' .. port .. '/MC_P2_R06_guidance11.json')
		assert(hash(buffer.fromstring(raw)) == '00057fc6c9f866fd494b67329cb27bac2c0800075a602ec7b6d7be33ea82349e')
		local packet = H:JSONDecode(raw)
		assert(packet.priorNormalizedSha256 == hash(buffer.fromstring(oldSource)) and packet.normalizedSha256 == hash(buffer.fromstring(packet.source)))
		local models = {game.ServerStorage.CourseLibrary.Course_MoonlitCitadel, workspace.Course_MoonlitCitadel}
		for _, model in models do
			assert(model:GetAttribute('CandidateId') == result.candidate and model.Decoration.Wayfinding:GetAttribute('WayfindingVersion') == 10)
			for _, prefix in {'E2_LanternNormalCommit', 'E2_LanternExpertCommit1'} do for _, suffix in {'Stem', 'Left', 'Right'} do
				local item = model.Decoration.Wayfinding[prefix .. suffix]
				assert(item:IsA('Part') and item:GetAttribute('ArrowId') == prefix and item:GetAttribute('GuidanceKind') == 'NativeArrow' .. suffix)
				assert(item.Anchored and not item.CanCollide and not item.CanQuery and not item.CanTouch and not item.CastShadow)
			end end
		end
		result.courseBefore = save('before_course', {models[1]}); result.editingBefore = save('before_editing', {models[2]})
		local archive = Instance.new('Folder'); archive.Name = 'ChoiceArrowFit11'; archive.Parent = recovery
		local oldModule = production:Clone(); oldModule.Name = 'Wayfinding10SourceBeforeFit'; oldModule.Parent = archive
		for index, model in models do
			local saved = Instance.new('Folder'); saved.Name = if index == 1 then 'LibraryChoiceArrows10' else 'EditingChoiceArrows10'; saved.Parent = archive
			local folder = model.Decoration.Wayfinding; folders[#folders + 1] = folder
			for _, prefix in {'E2_LanternNormalCommit', 'E2_LanternExpertCommit1'} do for _, suffix in {'Stem', 'Left', 'Right'} do
				local item = folder[prefix .. suffix]
				local copy = item:Clone(); copy.Parent = saved
				records[#records + 1] = {item = item, frame = item.CFrame, target = item:GetAttribute('ArrowTarget')}
				local shift = item:GetAttribute('ArrowForward') * .4
				item.CFrame += shift
				item:SetAttribute('ArrowTarget', item:GetAttribute('ArrowTarget') + shift)
				result.moved += 1
			end end
			folder:SetAttribute('WayfindingVersion', 11)
		end
		production.Source = packet.source
		assert(result.moved == 12)
		result.courseAfter = save('after_course', {models[1]}); result.editingAfter = save('after_editing', {models[2]})
		result.sourceSha256 = packet.normalizedSha256
	end, debug.traceback)
	if not ok then
		for _, row in records do row.item.CFrame = row.frame; row.item:SetAttribute('ArrowTarget', row.target) end
		for _, folder in folders do folder:SetAttribute('WayfindingVersion', 10) end
		production.Source = oldSource
	end
	H.HttpEnabled = beforeHttp
	result.ok, result.failure, result.httpRestored = ok, if ok then nil else tostring(reason), H.HttpEnabled == beforeHttp
	return H:JSONEncode(result)
end
return apply
