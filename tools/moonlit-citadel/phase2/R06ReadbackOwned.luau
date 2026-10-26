local function readback(port, label, sourceMapName, sourceMapHash)
	assert(game.PlaceId == 0 and game.GameId == 0 and not game:GetService("RunService"):IsRunning(), "Owned fixture Edit only")
	assert(label:match("^%w+$"))
	assert(sourceMapName:match("^MC_P2_R06_frozen_source_map%w+%.json$") and sourceMapHash:match("^%x+$") and #sourceMapHash == 64)
	local H, S, E = game:GetService("HttpService"), game:GetService("SerializationService"), game:GetService("EncodingService")
	local oldHttp, result = H.HttpEnabled, {candidate = "MC_P2_C01_R06", sourceMatches = 0, failures = {}, files = {}}
	local function hash(bytes)
		local raw, hex = E:ComputeBufferHash(bytes, Enum.HashAlgorithm.Sha256), {}
		for index = 0, buffer.len(raw) - 1 do hex[#hex + 1] = string.format("%02x", buffer.readu8(raw, index)) end
		return table.concat(hex)
	end
	local function at(path)
		local item = game
		for name in path:gmatch("[^/]+") do item = item and item:FindFirstChild(name) end
		return item
	end
	local ok, reason = xpcall(function()
		H.HttpEnabled = true
		local base = "http://127.0.0.1:" .. port .. "/"
		local reply = H:RequestAsync({Url = base .. sourceMapName, Method = "GET"})
		assert(reply.Success and hash(buffer.fromstring(reply.Body)) == sourceMapHash)
		local packet = H:JSONDecode(reply.Body)
		for index, row in packet.sources do
			local item = at(row.instancePath)
			local source = item and item:IsA("LuaSourceContainer") and item.Source:gsub("^\239\187\191", ""):gsub("\r\n", "\n")
			if source and #source == row.bytes and hash(buffer.fromstring(source)) == row.normalizedSha256 then result.sourceMatches += 1
			else table.insert(result.failures, row.instancePath) end
			if index % 100 == 0 then task.wait() end
		end
		assert(result.sourceMatches == #packet.sources and #result.failures == 0, "Saved source agreement failed")
		local library = game.ServerStorage.CourseLibrary
		local course = library.Course_MoonlitCitadel
		assert(#library:GetChildren() == 7 and course:GetAttribute("CandidateId") == result.candidate)
		result.libraryEntries, result.courseDescendants, result.clock = #library:GetChildren(), #course:GetDescendants(), game.Lighting.ClockTime
		for _, row in {{name = "course", items = {course}}, {name = "library", items = {library}}} do
			local bytes = S:SerializeInstancesAsync(row.items)
			local posted = H:RequestAsync({Url = base .. "MC_P2_R06_owned_reopen" .. label .. "_" .. row.name .. ".rbxm", Method = "POST", Headers = {["Content-Type"] = "application/octet-stream"}, Body = buffer.tostring(bytes)})
			assert(posted.Success, posted.StatusCode)
			local receipt = H:JSONDecode(posted.Body)
			assert(receipt.sha256 == hash(bytes)); table.insert(result.files, receipt)
		end
	end, debug.traceback)
	H.HttpEnabled = oldHttp
	result.ok, result.failure, result.httpRestored = ok, if ok then nil else tostring(reason), H.HttpEnabled == oldHttp
	return H:JSONEncode(result)
end
return readback
