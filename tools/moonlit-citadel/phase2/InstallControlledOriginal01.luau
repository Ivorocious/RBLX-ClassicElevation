return function(port)
	local Run, H, E = game:GetService("RunService"), game:GetService("HttpService"), game:GetService("EncodingService")
	assert(Run:IsStudio() and not Run:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	assert(type(port) == "number" and port % 1 == 0 and port > 0 and port < 65536)
	assert(require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig).CandidateId == "MC_P2_C01_R06")
	assert(game.ServerStorage.CourseLibrary.Course_MoonlitCitadel:GetAttribute("CandidateId") == "MC_P2_C01_R06")
	local allowed = {
		["ReplicatedStorage/MoonlitPhase2Tools/R06ControlledArrival"] = "ModuleScript",
		["ReplicatedStorage/MoonlitPhase2Tools/BoundaryCases"] = "ModuleScript",
		["ServerStorage/MoonlitPhase2Tools/BoundaryCases"] = "ModuleScript",
		["ReplicatedStorage/MoonlitPhase2Tools/PrivateResetCase"] = "ModuleScript",
		["ServerStorage/MoonlitPhase2Tools/PrivateResetCase"] = "ModuleScript",
		["ReplicatedStorage/MoonlitPhase2Tools/ContactCases"] = "ModuleScript",
		["ServerStorage/MoonlitPhase2Tools/ContactCases"] = "ModuleScript",
		["ReplicatedStorage/MoonlitPhase2Tools/ClientProbe"] = "ModuleScript",
		["ReplicatedStorage/MoonlitPhase2Tools/ClientSuite"] = "ModuleScript",
		["ServerScriptService/R06RuntimeBootstrap"] = "Script",
		["StarterPlayer/StarterPlayerScripts/R06RuntimeBootstrap"] = "LocalScript",
		["ServerScriptService/R06NewRed"] = "Script",
		["StarterPlayer/StarterPlayerScripts/R06NewRed"] = "LocalScript",
		["ServerScriptService/R06ContactDriver"] = "Script",
		["StarterPlayer/StarterPlayerScripts/R06ContactDriver"] = "LocalScript",
		["ServerStorage/MoonlitPhase2Tools/ContactCasesArmed09"] = "ModuleScript",
		["ReplicatedStorage/MoonlitPhase2Tools/ContactCasesArmed09"] = "ModuleScript",
	}
	local function at(path)
		local item = game
		for name in path:gmatch("[^/]+") do item = item and item:FindFirstChild(name) end
		return item
	end
	local function hash(raw)
		local bytes, parts = E:ComputeBufferHash(buffer.fromstring(raw), Enum.HashAlgorithm.Sha256), {}
		for index = 0, buffer.len(bytes) - 1 do parts[#parts + 1] = string.format("%02x", buffer.readu8(bytes, index)) end
		return table.concat(parts)
	end
	local beforeHttp, beforeLight = H.HttpEnabled, game.Lighting.ClockTime
	assert(beforeHttp == false)
	local report = {candidate = "MC_P2_C01_R06", disabledFirst = true, sources = {}, archived = {}, packets = {}}
	local ok, failure = xpcall(function()
		H.HttpEnabled = true
		local plans, seen = {}, {}
		local packets = {
			{"MC_P2_R06_controlled_original06.json", "3d611ff4184221c5765a2cb8577b1e5312ddfaf84cb4cbafe784fbfb42bd61ae", 10},
			{"MC_P2_R06_contact_original10.json", "e91c7e294cb38b6a6b70696c12dff96771fb12b07815467e3a64859e8b7d6267", 3},
		}
		for _, binding in packets do
			local response = H:RequestAsync({Url = "http://127.0.0.1:" .. port .. "/" .. binding[1], Method = "GET"})
			assert(response.Success and hash(response.Body) == binding[2])
			local packet = H:JSONDecode(response.Body)
			assert(packet.candidate == report.candidate and #packet.sources == binding[3])
			if packet.dependencies then
				assert(packet.dependencies.tools04PacketSha256 == "4340fbb5f8ce12fdbb3ebe1ab5f7ae716da66e0b89cae432e37e3d6f9093d6bc")
				for _, dependency in packet.dependencies.tools04Sources do
					local existing = assert(at(dependency.instancePath))
					assert(hash(existing.Source:gsub("\r\n", "\n"):gsub("\r", "\n")) == dependency.sha256)
				end
			end
			for _, row in packet.sources do
				assert(type(row.source) == "string" and #row.source < 200000 and hash(row.source) == row.sha256)
				local targets = row.targets
				if not targets then
					targets = {}
					for _, path in row.instancePaths or {row.instancePath} do
						targets[#targets + 1] = {instancePath = path, className = row.className}
					end
				end
				for _, target in targets do
					local path, className = target.instancePath, target.className
					assert(allowed[path] == className and not seen[path]); seen[path] = true
					local parentPath, name = path:match("^(.*)/([^/]+)$")
					local parent = assert(at(parentPath))
					local prior = parent:FindFirstChild(name)
					assert(not prior or (prior.ClassName == className and prior:GetAttribute("OwnedMoonlitTest") == true), "Unowned existing target " .. path)
					assert(not prior or not prior:IsA("BaseScript") or prior.Disabled, "Active previous diagnostic " .. path)
					plans[#plans + 1] = {path = path, parent = parent, name = name, className = className, source = row.source, sha256 = row.sha256, prior = prior}
				end
			end
			report.packets[#report.packets + 1] = {name = binding[1], sha256 = binding[2]}
		end
		assert(#plans == 17)
		local recovery = assert(game.ServerStorage:FindFirstChild("MoonlitR06OriginalRecovery"))
		assert(not recovery:FindFirstChild("ControlledNative01"), "Preserve earlier installation")
		local archive = Instance.new("Folder"); archive.Name = "ControlledNative01"; archive:SetAttribute("OwnedMoonlitTest", true); archive.Parent = recovery
		for index, plan in plans do
			if plan.prior then
				report.archived[#report.archived + 1] = {path = plan.path, sha256 = hash(plan.prior.Source)}
				local slot = Instance.new("Folder"); slot.Name = string.format("Previous_%02d", index); slot:SetAttribute("OriginalPath", plan.path); slot.Parent = archive
				plan.prior.Parent = slot
			end
			local value = Instance.new(plan.className); value.Name = plan.name; value.Source = plan.source
			value:SetAttribute("OwnedMoonlitTest", true); value:SetAttribute("CreatedBy", "MoonlitR06ControlledOriginal01")
			if value:IsA("BaseScript") then
				value.Disabled = true
				if plan.name == "R06NewRed" then value:SetAttribute("RunNewRedController", false) end
				if plan.name == "R06ContactDriver" then value:SetAttribute("RunContactDriver", false) end
			end
			value.Parent = plan.parent
			assert(hash(value.Source) == plan.sha256 and (not value:IsA("BaseScript") or value.Disabled))
			report.sources[#report.sources + 1] = {path = plan.path, className = value.ClassName, sha256 = plan.sha256, disabled = value:IsA("BaseScript") and value.Disabled or nil}
		end
		report.archivePath = archive:GetFullName()
	end, debug.traceback)
	H.HttpEnabled = beforeHttp
	report.ok, report.failure = ok, if ok then nil else tostring(failure)
	report.httpRestored, report.lightPreserved = H.HttpEnabled == beforeHttp, game.Lighting.ClockTime == beforeLight
	return H:JSONEncode(report)
end
