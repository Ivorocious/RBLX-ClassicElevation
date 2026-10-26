local function install(port, packetHash)
	local RunService = game:GetService("RunService")
	local H, E = game:GetService("HttpService"), game:GetService("EncodingService")
	assert(RunService:IsStudio() and RunService:IsRunning() and RunService:IsServer())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local course = assert(workspace:FindFirstChild("RaceCourse"))
	assert(course:GetAttribute("CandidateId") == "MC_P2_C01_R06")
	local owner = assert(game.Players:GetPlayerByUserId(86069177))
	assert(owner.Name == "ThisisIvorrovI" and owner:HasAppearanceLoaded())
	local function at(path)
		local value = game
		for name in path:gmatch("[^/]+") do value = value and value:FindFirstChild(name) end
		return value
	end
	local function hash(source)
		local bytes = E:ComputeBufferHash(buffer.fromstring(source), Enum.HashAlgorithm.Sha256)
		local parts = {}
		for i = 0, buffer.len(bytes) - 1 do table.insert(parts, string.format("%02x", buffer.readu8(bytes, i))) end
		return table.concat(parts)
	end
	local beforeHttp = H.HttpEnabled
	local report = {candidate = "MC_P2_C01_R06", packetHash = packetHash, sources = {}, disabledFirst = true}
	local ok, failure = xpcall(function()
		H.HttpEnabled = true
		local response = H:RequestAsync({Url = "http://127.0.0.1:" .. port .. "/MC_P2_R06_route_commands03.json", Method = "GET"})
		assert(response.Success and hash(response.Body) == packetHash)
		local packet = H:JSONDecode(response.Body)
		assert(packet.candidate == report.candidate and packet.originalPlaceId == game.PlaceId
			and packet.originalGameId == game.GameId and packet.originalCreatorId == game.CreatorId
			and packet.installDisabled == true and packet.activateOnlyAfterOrdinaryExport == true and #packet.scripts == 5)
		local allowed = {
			["ServerScriptService/R06RouteCommandServer"] = "Script",
			["Players/ThisisIvorrovI/PlayerGui/R06RouteCommandClient"] = "LocalScript",
			["ReplicatedStorage/MoonlitPhase2Tools/R06CatchRouteRunner"] = "ModuleScript",
			["ServerStorage/MoonlitPhase2Tools/R06NoJumpRepresentative"] = "ModuleScript",
			["ReplicatedStorage/MoonlitPhase2Tools/R06NoJumpRepresentative"] = "ModuleScript",
		}
		local seen = {}
		for _, row in packet.scripts do
			assert(allowed[row.target] == row.className and not seen[row.target]); seen[row.target] = true
			assert(#row.source < 200000 and hash(row.source) == row.normalizedSha256)
			assert(not at(row.target), "Preserve existing " .. row.target)
			local parent = row.target:match("^(.*)/[^/]+$")
			assert(at(parent), "Actual native parent absent: " .. parent)
		end
		for _, row in packet.scripts do
			local parent, name = row.target:match("^(.*)/([^/]+)$")
			local value = Instance.new(row.className)
			value.Name = name
			value.Source = row.source
			value:SetAttribute("OwnedMoonlitTest", true)
			if value:IsA("BaseScript") then value.Disabled = true; value:SetAttribute("RunRouteCommands", false) end
			value.Parent = at(parent)
			local actual = hash(value.Source:gsub("\r\n", "\n"):gsub("\r", "\n"))
			assert(actual == row.normalizedSha256)
			table.insert(report.sources, {path = row.target, className = row.className, sha256 = actual,
				disabled = value:IsA("BaseScript") and value.Disabled or nil})
		end
	end, debug.traceback)
	H.HttpEnabled = beforeHttp
	report.ok, report.failure, report.httpRestored = ok, if ok then nil else tostring(failure), H.HttpEnabled == beforeHttp
	return H:JSONEncode(report)
end
return install
