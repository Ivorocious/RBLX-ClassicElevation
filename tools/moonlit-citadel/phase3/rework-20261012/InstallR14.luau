--!nonstrict
return function(port, packetHash)
	assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local H, E, S = game.HttpService, game.EncodingService, game.SerializationService
	local base = "http://127.0.0.1:" .. port .. "/"
	local function hash(bytes)
		local value, pieces = E:ComputeBufferHash(bytes, Enum.HashAlgorithm.Sha256), {}
		for index = 0, buffer.len(value) - 1 do pieces[#pieces + 1] = string.format("%02x", buffer.readu8(value, index)) end
		return table.concat(pieces)
	end
	local function resolve(root, path)
		local item = root
		for name in path:gmatch("[^/]+") do item = assert(item:FindFirstChild(name), path) end
		return item
	end
	local function get(name)
		local response = H:RequestAsync({Url = base .. name, Method = "GET"})
		assert(response.Success, response.StatusCode .. ": " .. response.Body)
		return response.Body
	end
	local function save(name, items)
		local bytes = S:SerializeInstancesAsync(items)
		local response = H:RequestAsync({Url = base .. name, Method = "POST", Headers = {["Content-Type"] = "application/octet-stream"}, Body = buffer.tostring(bytes)})
		assert(response.Success, response.StatusCode .. ": " .. response.Body)
		local receipt = H:JSONDecode(response.Body)
		assert(receipt.sha256 == hash(bytes))
		return receipt
	end
	local library = game.ServerStorage.CourseLibrary
	local oldLibrary, oldEditable = assert(library:FindFirstChild("Course_MoonlitCitadel")), assert(workspace:FindFirstChild("Course_MoonlitCitadel"))
	assert(oldLibrary:GetAttribute("SourceRevision") == 23 and oldEditable:GetAttribute("SourceRevision") == 23
		and oldLibrary:GetAttribute("BuildRevision") == 19 and oldEditable:GetAttribute("BuildRevision") == 19)
	assert(oldLibrary:GetAttribute("SourcePacketHash") == "dea352e07c0990bfe8ee56c0563675073318d5bba0f3367c4c81255ae63b3ba1" and oldEditable:GetAttribute("SourcePacketHash") == "dea352e07c0990bfe8ee56c0563675073318d5bba0f3367c4c81255ae63b3ba1")
	local beforeHttp, beforeDay = H.HttpEnabled, game.Lighting.ClockTime
	local camera = workspace.CurrentCamera
	local beforeCamera, beforeFocus, beforeType, beforeFov = camera.CFrame, camera.Focus, camera.CameraType, camera.FieldOfView
	local preserved = {}
	for _, course in library:GetChildren() do if course ~= oldLibrary then preserved[course] = #course:GetDescendants() end end
	local p1, p1Count = workspace.MoonlitCitadelPhase1_BL02, #workspace.MoonlitCitadelPhase1_BL02:GetDescendants()
	local recovery = game.ServerStorage:FindFirstChild("MoonlitP3ReworkRecovery")
	if not recovery then recovery = Instance.new("Folder"); recovery.Name, recovery.Parent = "MoonlitP3ReworkRecovery", game.ServerStorage end
	local report, stage, course, editable, archive = {candidate = "MC_P3_REWORK_R04", sourceHash = packetHash, files = {}, sources = {}, published = false}
	local ok, failure = xpcall(function()
		H.HttpEnabled = true
		local owner = H:JSONDecode(get("rw10_final_r13_layout.json"))
		local origin = oldEditable:GetAttribute("Origin")
		for index, row in owner.parts do
			local part = resolve(oldEditable, row.path:gsub("%.", "/"))
			assert(part.ClassName == row.class and (part.Size - Vector3.new(table.unpack(row.size))).Magnitude < .001, "Owner shape changed: " .. row.path)
			local cf = CFrame.new(origin) * CFrame.new(table.unpack(row.cf))
			assert((part.CFrame.Position - cf.Position).Magnitude < .002 and part.CFrame.LookVector:Dot(cf.LookVector) > .999999
				and part.CFrame.UpVector:Dot(cf.UpVector) > .999999, "Owner placement changed: " .. row.path)
			assert(part.CanCollide == row.collide and part.CanQuery == row.query and part.CanTouch == row.touch
				and part.Transparency == row.transparency and part.Material.Name == row.material, "Owner contact changed: " .. row.path)
			if part:IsA("MeshPart") then assert(part.MeshId == row.meshId and part.TextureID == row.textureId) end
			if index % 300 == 0 then task.wait() end
		end
		local raw = get("rw10_install_r14.json")
		assert(hash(buffer.fromstring(raw)) == packetHash)
		local packet = H:JSONDecode(raw)
		assert(packet.candidate == report.candidate and packet.place == game.PlaceId and packet.universe == game.GameId and packet.creator == game.CreatorId)
		for _, row in packet.sources do
			assert(hash(buffer.fromstring(row.source)) == row.sha256)
			local parentPath, name = row.instancePath:match("^(.*)/([^/]+)$")
			assert(parentPath == "ServerStorage/CourseBuilders/MoonlitCitadelCourse" or parentPath == "ReplicatedStorage/Config")
			local parent = resolve(game, parentPath)
			local item = parent:FindFirstChild(name)
			if not item then item = Instance.new("ModuleScript"); item.Name, item.Parent = name, parent end
			assert(item:IsA("ModuleScript"))
			item.Source = row.source
			assert(hash(buffer.fromstring(item.Source:gsub("\r\n", "\n"))) == row.sha256)
			table.insert(report.sources, {path = row.instancePath, sha256 = row.sha256})
		end
		stage = game.ServerStorage.CourseBuilders.MoonlitCitadelCourse:Clone()
		stage.Name, stage.Parent = "MoonlitReworkBuild24_" .. H:GenerateGUID(false):gsub("%-", ""), game.ServerStorage.CourseBuilders
		for _, data in {{"MoonlitCitadelCourseConfig", "P3Config"}, {"MoonlitCitadelAssemblyConfig", "P3AssemblyConfig"}} do
			local copy = game.ReplicatedStorage.Config[data[1]]:Clone(); copy.Name, copy.Parent = data[2], stage
		end
		for _, item in stage:GetChildren() do
			if item:IsA("ModuleScript") and item.Name ~= "P3Config" and item.Name ~= "P3AssemblyConfig" then
				item.Source = item.Source:gsub("game%.ReplicatedStorage%.Config%.MoonlitCitadelCourseConfig", "script.Parent.P3Config")
					:gsub("game%.ReplicatedStorage%.Config%.MoonlitCitadelAssemblyConfig", "script.Parent.P3AssemblyConfig")
			end
		end
		course = require(stage.RouteBuilder).Build(stage)
		assert(course:GetAttribute("CandidateId") == report.candidate and course:GetAttribute("FallY") == 277)
		assert(not course:FindFirstChild("UpperBoardingWall", true) and not course:FindFirstChild("RouteBlockers", true))
		assert(#course.Checkpoints:GetChildren() == 4 and #course.Obstacles.RouteHazards:GetChildren() == 36)
		local parts, meshes, colliders, floors, red, signs, arrows, lights = 0, 0, 0, 0, 0, 0, 0, 0
		for index, item in course:GetDescendants() do
			if item:IsA("BasePart") then
				parts += 1; if item:IsA("MeshPart") then meshes += 1 end; if item.CanCollide then colliders += 1 end
				if item:GetAttribute("MCWalkable") then floors += 1 end
				if item:GetAttribute("MoonlitHazard") then red += 1; assert(item:GetAttribute("Role") == "VisibleRouteHazard" or item:GetAttribute("Role") == "SwingHazard") end
				if item:GetAttribute("GuidanceKind") == "SolidMeshArrow" then arrows += 1 end
				if item:GetAttribute("GuidanceKind") == "DecisionSign" then signs += 1 end
			elseif item:IsA("Light") then lights += 1; assert(not item.Shadows) end
			if index % 500 == 0 then task.wait() end
		end
		assert(floors == 131 and signs == 3 and arrows == 15)
		local world = course.Decoration.Phase3World
		assert(world:GetAttribute("MeshParts") <= 900 and world:GetAttribute("NewLights") == 10 and lights == 13)
		course:SetAttribute("SourceRevision", packet.sourceRevision); course:SetAttribute("BuildRevision", packet.buildRevision)
		course:SetAttribute("SourcePacketHash", packetHash); course:SetAttribute("OwnerAcceptance", "Pending")
		table.insert(report.files, save("rw10_built_r14.rbxm", {course}))
		assert(not recovery:FindFirstChild("BeforeHeadroomArchClosureSource23Build19"), "Preserve the earlier recovery")
		archive = Instance.new("Folder"); archive.Name, archive.Parent = "BeforeHeadroomArchClosureSource23Build19", recovery
		oldLibrary.Name, oldEditable.Name = "PriorLibraryCourse", "PriorEditableCourse"
		oldLibrary.Parent, oldEditable.Parent = archive, archive
		course.Parent = library
		editable = course:Clone(); editable:SetAttribute("ManualEditing", true); editable.Parent = workspace
		for item, count in preserved do assert(item.Parent == library and #item:GetDescendants() == count) end
		assert(#library:GetChildren() == 7 and #p1:GetDescendants() == p1Count and game.Lighting.ClockTime == beforeDay)
		assert(camera.CFrame == beforeCamera and camera.Focus == beforeFocus and camera.CameraType == beforeType and camera.FieldOfView == beforeFov)
		stage.Parent = recovery
		report.resources = {instances = #course:GetDescendants(), parts = parts, meshes = meshes, colliders = colliders, floors = floors, redParts = red, arrows = arrows, signs = signs, lights = lights}
		report.paths = {library = course:GetFullName(), editable = editable:GetFullName(), recovery = archive:GetFullName()}
		report.otherCoursesPreserved, report.phase1Preserved, report.cameraPreserved = true, true, true
	end, debug.traceback)
	if not ok then
		if course and course.Parent == library then course.Parent = recovery end
		if editable then editable.Parent = recovery end
		if archive then
			oldLibrary.Name, oldEditable.Name = "Course_MoonlitCitadel", "Course_MoonlitCitadel"
			oldLibrary.Parent, oldEditable.Parent = library, workspace
			report.geometryRollback = true
		end
		if stage then stage.Parent = recovery end
	end
	H.HttpEnabled = beforeHttp
	report.ok, report.failure, report.httpRestored, report.daylightPreserved = ok, if ok then nil else failure, H.HttpEnabled == beforeHttp, game.Lighting.ClockTime == beforeDay
	return H:JSONEncode(report)
end
