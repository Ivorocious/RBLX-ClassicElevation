local function run(port, label, packetHash)
	assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
	assert(game.PlaceId == 0 and game.GameId == 0, "Build only in the owned unpublished fixture")
	assert(label:match("^%w+$") and type(port) == "number")
	local H, S, E = game:GetService("HttpService"), game:GetService("SerializationService"), game:GetService("EncodingService")
	local function hash(bytes)
		local value, hex = E:ComputeBufferHash(bytes, Enum.HashAlgorithm.Sha256), {}
		for index = 0, buffer.len(value) - 1 do hex[#hex + 1] = string.format("%02x", buffer.readu8(value, index)) end
		return table.concat(hex)
	end
	local oldHttp, result = H.HttpEnabled, {candidate = "MC_P2_C01_R06", label = label, packetHash = packetHash}
	local ok, reason = xpcall(function()
		H.HttpEnabled = true
		local url = "http://127.0.0.1:" .. port .. "/"
		local reply = H:RequestAsync({Url = url .. "MC_P2_R06_draft" .. label .. ".json", Method = "GET"})
		assert(reply.Success and hash(buffer.fromstring(reply.Body)) == packetHash, "Stale draft packet")
		local packet = H:JSONDecode(reply.Body)
		assert(packet.candidate == result.candidate)
		local function folder(parent, name)
			local item = Instance.new("Folder"); item.Name, item.Parent = name, parent; return item
		end
		local name = "MoonlitR06Draft_" .. label
		assert(not game.ServerStorage:FindFirstChild(name), "Keep prior prototype snapshots")
		local snapshot = folder(game.ServerStorage, name)
		snapshot:SetAttribute("OwnedMoonlitTest", true)
		local config = folder(snapshot, "Config")
		local builders = folder(snapshot, "Builders")
		local courseBuilder = folder(builders, "MoonlitCitadelCourse")
		local kit = folder(builders, "MoonlitCitadel")
		for _, row in packet.sources do
			local parent = if row.name:match("Config$") then config elseif row.name == "MeshKit" then kit else courseBuilder
			local item = Instance.new("ModuleScript"); item.Name, item.Parent = row.name, parent
			local source = row.source
			for external, internal in {MoonlitCitadelCourseConfig = "CourseConfig", MoonlitCitadelAssemblyConfig = "AssemblyConfig", MoonlitCitadelConfig = "KitConfig"} do
				source = source:gsub("require%(game.ReplicatedStorage.Config." .. external .. "%)", "require(script.Parent.Parent.Parent.Config." .. internal .. ")")
			end
			item.Source = source
			item:SetAttribute("DurableInputFile", row.file); item:SetAttribute("DurableInputSha256", row.sha256)
		end
		local course = require(courseBuilder.RouteBuilder).Build()
		assert(course:GetAttribute("CandidateId") == result.candidate)
		course.Parent = snapshot
		local bytes = S:SerializeInstancesAsync({course})
		local posted = H:RequestAsync({Url = url .. "MC_P2_C01_R06_native_draft" .. label .. ".rbxm", Method = "POST", Headers = {["Content-Type"] = "application/octet-stream"}, Body = buffer.tostring(bytes)})
		assert(posted.Success, posted.StatusCode)
		result.native = H:JSONDecode(posted.Body)
		assert(result.native.sha256 == hash(bytes))
		result.coursePath, result.descendants = course:GetFullName(), #course:GetDescendants()
		result.attributes = {}
		for key, value in course:GetAttributes() do
			result.attributes[key] = if typeof(value) == "Vector3" then {value.X, value.Y, value.Z} else value
		end
		local counts = {parts = 0, meshParts = 0, colliders = 0, queryParts = 0, touchParts = 0, lights = 0, surfaceGuis = 0}
		for _, item in course:GetDescendants() do
			if item:IsA("BasePart") then
				counts.parts += 1
				if item:IsA("MeshPart") then counts.meshParts += 1 end
				if item.CanCollide then counts.colliders += 1 end
				if item.CanQuery then counts.queryParts += 1 end
				if item.CanTouch then counts.touchParts += 1 end
			elseif item:IsA("Light") then counts.lights += 1 elseif item:IsA("SurfaceGui") then counts.surfaceGuis += 1 end
		end
		result.counts = counts
	end, debug.traceback)
	H.HttpEnabled = oldHttp
	result.ok, result.failure, result.httpRestored = ok, if ok then nil else tostring(reason), H.HttpEnabled == oldHttp
	return H:JSONEncode(result)
end
return run
