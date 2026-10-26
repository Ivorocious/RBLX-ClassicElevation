--!nonstrict
return function(action, sourceHash)
	assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local recovery = game.ServerStorage.MoonlitP3ReworkRecovery
	local lighting, camera = game.Lighting, workspace.CurrentCamera
	local name = "ArtRepairNightPreview40"
	local snapshot = recovery:FindFirstChild(name)
	if action == "Restore" then
		assert(snapshot and snapshot:GetAttribute("Active") == true)
		for key, value in snapshot:GetAttributes() do
			local property = key:match("^Lighting_(.+)$")
			if property then lighting[property] = value end
		end
		for _, entry in snapshot:GetChildren() do
			if entry:IsA("Folder") then
				if entry.Name == "HiddenPhase1Objects" then
					for _, reference in entry:GetChildren() do reference.Value.LocalTransparencyModifier = reference:GetAttribute("Original") end
					continue
				end
				local object = entry.Object.Value
				if entry:GetAttribute("Created") then object.Parent = snapshot
				else for key, value in entry:GetAttributes() do if key ~= "Created" then object[key] = value end end end
			end
		end
		camera.CFrame, camera.Focus = snapshot:GetAttribute("CameraCF"), snapshot:GetAttribute("CameraFocus")
		camera.CameraType = Enum.CameraType[snapshot:GetAttribute("CameraType")]
		camera.FieldOfView = snapshot:GetAttribute("CameraFov")
		snapshot:SetAttribute("Active", false)
		return "Night preview restored its lighting, sky, effects and camera"
	end
	assert(action == "Apply" and not snapshot, "Keep the earlier preview snapshot")
	assert(workspace.Course_MoonlitCitadel:GetAttribute("SourcePacketHash") == sourceHash)
	snapshot = Instance.new("Folder")
	snapshot.Name, snapshot.Parent = name, recovery
	snapshot:SetAttribute("Active", true)
	snapshot:SetAttribute("SourceHash", sourceHash)
	snapshot:SetAttribute("CameraCF", camera.CFrame)
	snapshot:SetAttribute("CameraFocus", camera.Focus)
	snapshot:SetAttribute("CameraType", camera.CameraType.Name)
	snapshot:SetAttribute("CameraFov", camera.FieldOfView)
	local copy = Instance.new("ModuleScript"); copy.Source = [==[--!nonstrict
return table.freeze({
	CourseId = "moonlit_citadel", ActivationDistance = 750, UseCourseBounds = true,
	HideWorkspaceRoots = {"MoonlitCitadelPhase1_C01", "MoonlitCitadelPhase1_BL01", "MoonlitCitadelPhase1_BL02"}, RequiredCourseAttribute = "MoonlitNightAmbience",
	Lighting = {ClockTime = 21.3, GeographicLatitude = 20, Brightness = 2.2, ExposureCompensation = .65,
		GlobalShadows = true, ShadowSoftness = .3, EnvironmentDiffuseScale = .85, EnvironmentSpecularScale = .4,
		Ambient = Color3.fromRGB(145, 153, 171), OutdoorAmbient = Color3.fromRGB(132, 146, 169)},
	ColorCorrection = {Brightness = .035, Contrast = .015, Saturation = -.045, TintColor = Color3.fromRGB(232, 240, 255)},
		Atmosphere = {Density = .15, Offset = .10, Haze = .55, Glare = 0,
		Color = Color3.fromRGB(107, 123, 148), Decay = Color3.fromRGB(65, 78, 101)},
	Sky = {SkyboxBk = "rbxassetid://119591637361429", SkyboxDn = "rbxassetid://81233894808962",
		SkyboxFt = "rbxassetid://136920684348219", SkyboxLf = "rbxassetid://99622089516191",
		SkyboxRt = "rbxassetid://95853984087799", SkyboxUp = "rbxassetid://126102685877031",
		CelestialBodiesShown = true, StarCount = 1000, SunAngularSize = 0, MoonAngularSize = 11,
		MoonTextureId = "rbxasset://sky/moon.jpg"},
	Effects = {BloomEffect = {Enabled = true, Intensity = .10, Size = 20, Threshold = 1.4}, SunRaysEffect = {Enabled = false}},
})
]==]
	copy.Name, copy.Parent = "PreviewConfig", snapshot
	local config = require(copy)
	for key, value in config.Lighting do snapshot:SetAttribute("Lighting_" .. key, lighting[key]); lighting[key] = value end
	local function apply(className, properties, forceNew)
		local object = if forceNew then nil else lighting:FindFirstChildOfClass(className)
		local created = object == nil
		if created then object = Instance.new(className); object.Name, object.Parent = "MoonlitReworkPreview" .. className, lighting end
		local entry, reference = Instance.new("Folder"), Instance.new("ObjectValue")
		entry.Name, entry.Parent = className, snapshot
		entry:SetAttribute("Created", created)
		reference.Name, reference.Value, reference.Parent = "Object", object, entry
		for key, value in properties do
			if not created then entry:SetAttribute(key, object[key]) end
			object[key] = value
		end
		return object
	end
	apply("Sky", config.Sky)
	apply("Atmosphere", config.Atmosphere)
	local correction = apply("ColorCorrectionEffect", config.ColorCorrection, true)
	correction.Enabled = true
	for className, properties in config.Effects do apply(className, properties) end
	local hidden = Instance.new("Folder")
	hidden.Name, hidden.Parent = "HiddenPhase1Objects", snapshot
	local serial = 0
	for _, rootName in config.HideWorkspaceRoots do
		local root = workspace:FindFirstChild(rootName)
		if root then for _, object in root:GetDescendants() do
			if object:IsA("BasePart") then
				serial += 1
				local reference = Instance.new("ObjectValue")
				reference.Name, reference.Value, reference.Parent = tostring(serial), object, hidden
				reference:SetAttribute("Original", object.LocalTransparencyModifier)
				object.LocalTransparencyModifier = 1
			end
		end end
	end
	return "Edit preview uses the proposed Moonlit night profile; runtime lifecycle is tested separately"
end
