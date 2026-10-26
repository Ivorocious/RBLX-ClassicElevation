--!nonstrict
return function(action, sourceHash)
	assert(game.RunService:IsStudio() and not game.RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local recovery = game.ServerStorage.MoonlitP3ReworkRecovery.DetailPass20261014
	local lighting, camera = game.Lighting, workspace.CurrentCamera
	local name = "DetailNightPreview53"
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
	local copy = game.ReplicatedStorage.Config.MoonlitCitadelAmbienceConfig:Clone()
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
