--!nonstrict
return function(port, packetHash)
	assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local H, E, S = game.HttpService, game.EncodingService, game.SerializationService
	local function hash(bytes)
		local value, pieces = E:ComputeBufferHash(bytes, Enum.HashAlgorithm.Sha256), {}
		for index = 0, buffer.len(value) - 1 do pieces[#pieces + 1] = string.format("%02x", buffer.readu8(value, index)) end
		return table.concat(pieces)
	end
	local function at(path, create)
		local item = game
		for name in path:gmatch("[^/]+") do
			local child = item:FindFirstChild(name)
			if not child and create then child = Instance.new("Folder"); child.Name, child.Parent = name, item end
			item = assert(child, path)
		end
		return item
	end
	local recovery = assert(game.ServerStorage:FindFirstChild("MoonlitR07OriginalRecovery"))
	local library = game.ServerStorage.CourseLibrary
	local oldLibrary = assert(library:FindFirstChild("Course_MoonlitCitadel"))
	local oldEditable = assert(workspace:FindFirstChild("Course_MoonlitCitadel"))
	assert(oldLibrary:GetAttribute("CandidateId") == "MC_P2_C01_R07" and oldEditable:GetAttribute("CandidateId") == "MC_P2_C01_R07")
	local beforeHttp, beforeDay = H.HttpEnabled, game.Lighting.ClockTime
	local report = {candidate = "MC_P2_C01_R07", sourcePacketHash = packetHash, published = false, sources = {}, files = {}}
	local base = "http://127.0.0.1:" .. port .. "/"
	local function save(name, items)
		local bytes = S:SerializeInstancesAsync(items)
		local response = H:RequestAsync({Url = base .. "MC_P2_R07_" .. name .. ".rbxm", Method = "POST",
			Headers = {["Content-Type"] = "application/octet-stream"}, Body = buffer.tostring(bytes)})
		assert(response.Success, response.StatusCode)
		local receipt = H:JSONDecode(response.Body)
		assert(receipt.sha256 == hash(bytes))
		report.files[#report.files + 1] = receipt
	end
	local preserved = {}
	for _, item in library:GetChildren() do if item ~= oldLibrary then preserved[item] = #item:GetDescendants() end end
	local p1 = workspace.MoonlitCitadelPhase1_BL02
	local p1Count = #p1:GetDescendants()
	local stage, course, editable
	local ok, failure = xpcall(function()
		H.HttpEnabled = true
		local response = H:RequestAsync({Url = base .. "MC_P2_R07_install02.json", Method = "GET"})
		assert(response.Success and hash(buffer.fromstring(response.Body)) == packetHash)
		local packet = H:JSONDecode(response.Body)
		assert(packet.candidate == report.candidate and packet.place == game.PlaceId and packet.universe == game.GameId and packet.creator == game.CreatorId)
		save("before_R07_geometry01", {oldLibrary, oldEditable})
		for _, row in packet.sources do
			assert(hash(buffer.fromstring(row.source)) == row.sha256)
			local parentPath, name = row.instancePath:match("^(.*)/([^/]+)$")
			local parent = at(parentPath)
			local item = parent:FindFirstChild(name)
			if not item then item = Instance.new("ModuleScript"); item.Name, item.Parent = name, parent end
			assert(item:IsA("ModuleScript"))
			item.Source = row.source
			report.sources[#report.sources + 1] = {path = row.instancePath, sha256 = hash(buffer.fromstring(item.Source:gsub("\r\n", "\n")))}
			assert(report.sources[#report.sources].sha256 == row.sha256)
		end
		stage = game.ServerStorage.CourseBuilders.MoonlitCitadelCourse:Clone()
		stage.Name, stage.Parent = "MoonlitR07Build02", game.ServerStorage.CourseBuilders
		for _, data in {{"MoonlitCitadelCourseConfig", "R07Config"}, {"MoonlitCitadelAssemblyConfig", "R07AssemblyConfig"}} do
			local copy = game.ReplicatedStorage.Config[data[1]]:Clone()
			copy.Name, copy.Parent = data[2], stage
		end
		for _, item in stage:GetChildren() do
			if item:IsA("ModuleScript") and item.Name ~= "R07Config" and item.Name ~= "R07AssemblyConfig" then
				item.Source = item.Source:gsub("game%.ReplicatedStorage%.Config%.MoonlitCitadelCourseConfig", "script.Parent.R07Config")
					:gsub("game%.ReplicatedStorage%.Config%.MoonlitCitadelAssemblyConfig", "script.Parent.R07AssemblyConfig")
			end
		end
		course = require(stage.RouteBuilder).Build()
		assert(course:GetAttribute("CandidateId") == report.candidate and course:GetAttribute("FallY") == 277)
		assert(#course.Checkpoints:GetChildren() == 4 and #course.Obstacles.RouteHazards:GetChildren() == 21)
		local floors, red, arrows, signs, parts, meshes, colliders = 0, 0, {}, 0, 0, 0, 0
		for index, item in course:GetDescendants() do
			if item:IsA("BasePart") then
				parts += 1; if item:IsA("MeshPart") then meshes += 1 end; if item.CanCollide then colliders += 1 end
				if item:GetAttribute("MCWalkable") then floors += 1 end
				if item:GetAttribute("MoonlitHazard") then red += 1; assert(item:GetAttribute("Role") == "VisibleRouteHazard") end
				if item:GetAttribute("ArrowId") then arrows[item:GetAttribute("ArrowId")] = true end
				if item:GetAttribute("GuidanceKind") == "DecisionSign" then signs += 1 end
			end
			if index % 1000 == 0 then task.wait() end
		end
		local arrowCount = 0; for _ in arrows do arrowCount += 1 end
		assert(red == 21 and arrowCount == 7 and signs == 3)
		report.resources = {instances = #course:GetDescendants(), floors = floors, routeHazards = red, arrows = arrowCount, signs = signs,
			parts = parts, meshes = meshes, colliders = colliders}
		local archive = Instance.new("Folder"); archive.Name, archive.Parent = "PreservedR07FirstBuild", recovery
		oldLibrary.Name, oldEditable.Name = "R07FirstLibraryCourse", "R07FirstEditableCourse"
		oldLibrary.Parent, oldEditable.Parent = archive, archive
		course.Parent = library
		editable = course:Clone(); editable:SetAttribute("ManualEditing", true); editable.Parent = workspace
		assert(#library:GetChildren() == 7)
		for item, count in preserved do assert(item.Parent == library and #item:GetDescendants() == count) end
		assert(#p1:GetDescendants() == p1Count and game.Lighting.ClockTime == beforeDay)
		save("installed_course02", {course})
		report.libraryPath, report.editablePath = course:GetFullName(), editable:GetFullName()
		report.otherCoursesPreserved, report.phase1Preserved = true, true
		stage.Parent = recovery
	end, debug.traceback)
	if not ok and course and course.Parent == library then
		course.Parent = recovery
		if editable then editable.Parent = recovery end
		oldLibrary.Name, oldEditable.Name = "Course_MoonlitCitadel", "Course_MoonlitCitadel"
		oldLibrary.Parent, oldEditable.Parent = library, workspace
		report.geometryRollback = true
	end
	H.HttpEnabled = beforeHttp
	report.ok, report.failure, report.httpRestored, report.daylightPreserved = ok, if ok then nil else failure, H.HttpEnabled == beforeHttp, game.Lighting.ClockTime == beforeDay
	return H:JSONEncode(report)
end
