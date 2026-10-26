--!nonstrict
return function(port, packetHash)
	assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local H, E = game.HttpService, game.EncodingService
	local sourceHash = "6d33c1f88b23bd0e2840a5ecec163fe09d581a087f8c0c76b52e2ba50c5dca8a"
	local priorHash = "6d3c7b0f55ad121a23d33d1478c26caeb893d844018de9f8c841b0ee88b34f4f"
	local function hash(text)
		local digest, pieces = E:ComputeBufferHash(buffer.fromstring(text), Enum.HashAlgorithm.Sha256), {}
		for index = 0, buffer.len(digest)-1 do pieces[#pieces+1] = string.format("%02x", buffer.readu8(digest,index)) end
		return table.concat(pieces)
	end
	local function resolve(path)
		local value = game
		for name in path:gmatch("[^/]+") do value = assert(value:FindFirstChild(name), path) end
		return value
	end
	assert(workspace.Course_MoonlitCitadel:GetAttribute("SourcePacketHash") == sourceHash)
	local recovery = game.ServerStorage.MoonlitP3ReworkRecovery
	assert(not recovery:FindFirstChild("TestDriversBefore12"))
	local beforeHttp = H.HttpEnabled
	local report = {candidate = "MC_P3_REWORK_R03", sourceHash = sourceHash, sources = {}}
	local ok, failure = xpcall(function()
		H.HttpEnabled = true
		local raw = H:GetAsync("http://127.0.0.1:" .. port .. "/rw10_test_drivers_r03.json")
		assert(hash(raw) == packetHash)
		local packet = H:JSONDecode(raw)
		assert(packet.candidate == report.candidate and packet.sourceHash == sourceHash and #packet.sources == 5)
		for _, row in packet.sources do assert(hash(row.source) == row.sha256) end
		for _, root in {game.ServerStorage, game.ReplicatedStorage} do
			local old = assert(root:FindFirstChild("MoonlitPhase3Tools"))
			assert(old:GetAttribute("OwnedMoonlitTest") and old:GetAttribute("SourceHash") == priorHash)
		end
		local archive = Instance.new("Folder"); archive.Name, archive.Parent = "TestDriversBefore12", recovery
		for _, root in {game.ServerStorage, game.ReplicatedStorage} do
			local old = root.MoonlitPhase3Tools
			old.Name, old.Parent = root.Name .. "Tools", archive
			local folder = Instance.new("Folder"); folder.Name, folder.Parent = "MoonlitPhase3Tools", root
			folder:SetAttribute("OwnedMoonlitTest", true); folder:SetAttribute("SourceHash", sourceHash)
		end
		for _, row in packet.sources do
			local parentPath, name = row.instancePath:match("^(.*)/([^/]+)$")
			local parent = resolve(parentPath)
			local item = parent:FindFirstChild(name)
			if item then
				assert(item:GetAttribute("OwnedMoonlitTest") == true)
				local copy = item:Clone(); copy.Name = name .. "Before12"; copy.Parent = archive
				if copy:IsA("BaseScript") then copy.Enabled = false; copy:SetAttribute("RunNativeCommands", false) end
			else item = Instance.new(row.class); item.Name, item.Parent = name, parent end
			assert(item.ClassName == row.class)
			item.Source = row.source
			item:SetAttribute("OwnedMoonlitTest", true)
			if item:IsA("BaseScript") then item:SetAttribute("RunNativeCommands", true); item.Enabled = true end
			assert(hash(item.Source:gsub("\r\n", "\n")) == row.sha256)
			table.insert(report.sources, {path = row.instancePath, sha256 = row.sha256})
		end
	end, debug.traceback)
	H.HttpEnabled = beforeHttp
	report.ok, report.failure, report.httpRestored = ok, if ok then nil else failure, H.HttpEnabled == beforeHttp
	return H:JSONEncode(report)
end
