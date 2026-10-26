local function inventory(root, port, label)
	assert(game:GetService("RunService"):IsStudio() and game.PlaceId == 0 and game.GameId == 0)
	local H, E = game:GetService("HttpService"), game:GetService("EncodingService")
	local function components(frame) return {frame:GetComponents()} end
	local function relative(item)
		local names = {}
		while item ~= root do names[#names + 1] = item.Name; item = assert(item.Parent) end
		local result = {}; for i = #names, 1, -1 do result[#result + 1] = names[i] end
		return table.concat(result, "/")
	end
	local report = {candidate = root:GetAttribute("CandidateId"), rootPath = root:GetFullName(), records = {}}
	local instances = root:GetDescendants(); table.insert(instances, 1, root)
	for index, item in instances do
		if item:IsA("PVInstance") then
			local row = {path = relative(item), class = item.ClassName, effective = components(item:GetPivot())}
			if item:IsA("Model") then
				row.worldPivot = components(item.WorldPivot)
				row.primaryPart = item.PrimaryPart and relative(item.PrimaryPart)
			else row.frame = components(item.CFrame); row.pivotOffset = components(item.PivotOffset) end
			table.insert(report.records, row)
		end
		if index % 1000 == 0 then task.wait() end
	end
	table.sort(report.records, function(a, b) return a.path < b.path end)
	local before = H.HttpEnabled
	local ok, result = xpcall(function()
		H.HttpEnabled = true
		local raw = H:JSONEncode(report)
		local reply = H:RequestAsync({Url = "http://127.0.0.1:" .. port .. "/MC_P2_R06_pivots_" .. label .. ".json", Method = "POST",
			Headers = {["Content-Type"] = "application/json"}, Body = raw})
		assert(reply.Success, reply.StatusCode)
		return H:JSONDecode(reply.Body)
	end, debug.traceback)
	H.HttpEnabled = before
	assert(ok, result)
	return H:JSONEncode({receipt = result, records = #report.records, restoredHttp = H.HttpEnabled == before})
end
return inventory
