--!nonstrict
return function(port)
	assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local H, E, S = game.HttpService, game.EncodingService, game.SerializationService
	local beforeHttp = H.HttpEnabled
	local function hash(bytes)
		local value, pieces = E:ComputeBufferHash(bytes, Enum.HashAlgorithm.Sha256), {}
		for index = 0, buffer.len(value) - 1 do pieces[#pieces + 1] = string.format("%02x", buffer.readu8(value, index)) end
		return table.concat(pieces)
	end
	local function encode(value)
		local kind = typeof(value)
		if kind == "Vector3" then return {value.X, value.Y, value.Z} end
		if kind == "Color3" then return {value.R, value.G, value.B} end
		if kind == "CFrame" then return {value:GetComponents()} end
		if kind == "EnumItem" then return tostring(value) end
		if kind == "table" then local result = {}; for key, item in value do result[key] = encode(item) end; return result end
		return value
	end
	local course = assert(workspace:FindFirstChild("Course_MoonlitCitadel"))
	local library = assert(game.ServerStorage.CourseLibrary:FindFirstChild("Course_MoonlitCitadel"))
	local origin = course:GetAttribute("Origin")
	local report = {place = game.PlaceId, universe = game.GameId, creator = game.CreatorId, sources = {}, files = {}, protected = {}}
	local camera = workspace.CurrentCamera
	report.camera = {cf = encode(camera.CFrame), focus = encode(camera.Focus), cameraType = camera.CameraType.Name, fieldOfView = camera.FieldOfView}
	report.lighting = {}
	for _, key in {"ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom", "ExposureCompensation", "FogColor", "FogStart", "FogEnd", "GlobalShadows", "EnvironmentDiffuseScale", "EnvironmentSpecularScale"} do
		report.lighting[key] = encode(game.Lighting[key])
	end
	report.sky = {}
	for _, child in game.Lighting:GetChildren() do
		if child:IsA("Sky") then
			local row = {name = child.Name, properties = {}}
			for _, key in {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "MoonTextureId", "SunTextureId", "MoonAngularSize", "SunAngularSize", "StarCount", "CelestialBodiesShown", "SkyboxOrientation"} do row.properties[key] = encode(child[key]) end
			table.insert(report.sky, row)
		end
	end
	for _, child in game.ServerStorage.CourseLibrary:GetChildren() do
		if child ~= library then report.protected[child:GetFullName()] = #child:GetDescendants() end
	end
	report.protected[workspace.MoonlitCitadelPhase1_BL02:GetFullName()] = #workspace.MoonlitCitadelPhase1_BL02:GetDescendants()
	local layout = {origin = encode(origin), attrs = encode(course:GetAttributes()), parts = {}, libraryAttrs = encode(library:GetAttributes())}
	for index, item in course:GetDescendants() do
		if item:IsA("BasePart") then
			local row = {path = item:GetFullName():sub(#course:GetFullName() + 2), class = item.ClassName, size = encode(item.Size),
				cf = encode(CFrame.new(-origin) * item.CFrame), color = encode(item.Color), material = item.Material.Name,
				collide = item.CanCollide, query = item.CanQuery, touch = item.CanTouch, transparency = item.Transparency, attrs = encode(item:GetAttributes())}
			if item:IsA("MeshPart") then row.meshId, row.textureId = item.MeshId, item.TextureID end
			table.insert(layout.parts, row)
		end
		if index % 300 == 0 then task.wait() end
	end
	local function source(item)
		local text = item.Source:gsub("\r\n", "\n")
		table.insert(report.sources, {instancePath = item:GetFullName():gsub("%.", "/"), source = text, sha256 = hash(buffer.fromstring(text))})
	end
	for _, item in game.ServerStorage.CourseBuilders.MoonlitCitadelCourse:GetChildren() do if item:IsA("ModuleScript") then source(item) end end
	for _, name in {"MoonlitCitadelCourseConfig", "MoonlitCitadelAssemblyConfig", "MoonlitCitadelConfig", "MoonlitCitadelAmbienceConfig"} do source(game.ReplicatedStorage.Config[name]) end
	source(game.ReplicatedStorage.Shared.MoonlitCitadelAmbienceGate)
	source(game.StarterPlayer.StarterPlayerScripts.ClassicAscentAmbience)
	local function post(name, bytes)
		local response = H:RequestAsync({Url = "http://127.0.0.1:" .. port .. "/" .. name, Method = "POST", Headers = {["Content-Type"] = "application/octet-stream"}, Body = buffer.tostring(bytes)})
		assert(response.Success, response.StatusCode .. ": " .. response.Body)
		local receipt = H:JSONDecode(response.Body)
		assert(receipt.sha256 == hash(bytes))
		table.insert(report.files, receipt)
	end
	local ok, failure = xpcall(function()
		H.HttpEnabled = true
		post("hardening_before_overlap_source35_models.rbxm", S:SerializeInstancesAsync({library, course}))
		post("hardening_before_overlap_source35_layout.json", buffer.fromstring(H:JSONEncode(layout)))
		post("hardening_before_overlap_source35_sources.json", buffer.fromstring(H:JSONEncode(report)))
	end, debug.traceback)
	H.HttpEnabled = beforeHttp
	return H:JSONEncode({ok = ok, failure = failure, files = report.files, sourceCount = #report.sources, partCount = #layout.parts,
		httpRestored = H.HttpEnabled == beforeHttp, protected = report.protected, camera = report.camera})
end
