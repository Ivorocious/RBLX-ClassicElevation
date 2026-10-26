--!strict

local ServerStorage = game:GetService("ServerStorage")
local Installer = {}

local function vec(p): Vector3
	return Vector3.new(p[1], p[2], p[3])
end

local function folder(parent: Instance, name: string): Folder
	local item = Instance.new("Folder")
	item.Name, item.Parent = name, parent
	return item
end

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, collide: boolean): Part
	local item = Instance.new("Part")
	item.Name, item.Size, item.CFrame = name, size, cf
	item.Anchored, item.Transparency = true, 1
	item.CanCollide, item.CanTouch, item.CanQuery = collide, false, collide
	item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

function Installer.Install(importName: string?, targetName: string?, collisionPreview: boolean?)
	assert(game.PlaceId == 85558151074819, "City Run installer requires Project Classic Elevation")
	local data = require(script.Parent.Manifest)
	local name = targetName or "Course_CityRun"
	assert(not workspace:FindFirstChild(name), "Preserve the existing City Run before installing a revision")
	local origin = CFrame.new(vec(data.origin))
	local model = Instance.new("Model")
	model.Name, model.WorldPivot = name, origin
	model:SetAttribute("CityRunRevision", data.revision)
	model:SetAttribute("ManualEditing", true)
	model:SetAttribute("VisualReviewPassed", false)
	local info = folder(model, "CourseInfo")
	for key, value in { CourseId = "city_run", DisplayName = "City Run", RaceFormat = "PointToPoint",
		LapCount = 1, Enabled = true, Difficulty = "Intermediate", CheckpointCount = 9,
		TargetNewPlayerTime = 330, TargetPracticedTime = 210, DesignedRacerCapacity = 20, TimingValidated = false } do
		info:SetAttribute(key, value)
	end
	local obstacles = folder(model, "Obstacles")
	local decoration = folder(model, "Decoration")
	local checkpoints = folder(model, "Checkpoints")
	local bounds = folder(model, "Bounds")
	local fallZones = folder(model, "FallZones")
	folder(model, "RouteMarkers")
	local moving = folder(obstacles, "Moving")
	local surfaces = folder(obstacles, "WalkingSurfaces")
	local groups = {}
	for componentName, definition in data.components do
		if definition.section == "Calibration" then continue end
		local group = Instance.new("Model")
		group.Name = componentName
		group.WorldPivot = origin * CFrame.new(vec(definition.pivot))
		group:SetAttribute("Section", definition.section)
		group.Parent = if definition.section == "Moving" then moving else decoration
		groups[componentName] = group
	end
	if not collisionPreview then
		local source = importName and ServerStorage:FindFirstChild(importName)
		assert(source and source:IsA("Model"), "Insert the approved Blender model into ServerStorage first")
		local imported = source:Clone()
		imported.Name, imported.Parent = "ImportCalibration", model
		local markers = {}
		for _, item in imported:GetDescendants() do
			assert(not item:IsA("LuaSourceContainer"), "Unexpected script in City Run asset")
			if item:IsA("BasePart") then
				for _, key in { "Origin", "Right", "Up", "Forward" } do
					if string.find(item.Name, "Marker" .. key .. "__", 1, true) then markers[key] = item end
				end
			end
		end
		for _, key in { "Origin", "Right", "Up", "Forward" } do assert(markers[key], "Missing import marker " .. key) end
		imported:ScaleTo(imported:GetScale() * 10 / (markers.Right.Position - markers.Origin.Position).Magnitude)
		local sourceFrame = CFrame.fromMatrix(markers.Origin.Position,
			(markers.Right.Position - markers.Origin.Position).Unit,
			(markers.Up.Position - markers.Origin.Position).Unit,
			(markers.Origin.Position - markers.Forward.Position).Unit)
		for _, item in imported:GetDescendants() do
			if not item:IsA("BasePart") then continue end
			item.CFrame = origin * sourceFrame:ToObjectSpace(item.CFrame)
			item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
			local componentName, materialName = string.match(item.Name, "^(.-)__([^_]+)__")
			local color = data.colors[materialName]
			assert(color, "Unrecognized imported material: " .. item.Name)
			item.Color = Color3.new(color[1], color[2], color[3])
			item.Material = if materialName == "Red" or materialName == "Light" then Enum.Material.Neon
				elseif materialName == "Brick" or materialName == "Terracotta" then Enum.Material.Brick
				elseif materialName == "Stone" or materialName == "Cream" or materialName == "Plaster" then Enum.Material.Concrete
				elseif string.sub(materialName, 1, 4) == "Wood" then Enum.Material.WoodPlanks
				elseif materialName == "Iron" or materialName == "Rail" then Enum.Material.Metal
				elseif materialName == "Roof" then Enum.Material.Asphalt
				else Enum.Material.SmoothPlastic
			if item:IsA("MeshPart") then
				item.TextureID = ""
				item.RenderFidelity = Enum.RenderFidelity.Automatic
				if materialName == "Glass" then item.Reflectance = .12 end
			end
			if string.sub(componentName, 1, 6) == "Marker" then
				item.Transparency, item.Parent = 1, bounds
			else
				assert(groups[componentName], "Unknown imported component: " .. componentName)
				item.Parent = groups[componentName]
			end
		end
	end
	for _, definition in data.surfaces do
		local p = vec(definition.p)
		local item = part(surfaces, definition.name, vec(definition.size), origin * CFrame.new(p - Vector3.new(0, .5, 0)), true)
		item:SetAttribute("Section", definition.section)
		item:SetAttribute("RouteStyle", definition.style)
		if collisionPreview then
			item.Transparency = 0
			item.Color = if string.sub(definition.name, 1, 1) == "X" then Color3.fromRGB(235, 160, 35) else Color3.fromRGB(86, 150, 165)
		end
	end
	for _, definition in data.guards do
		part(groups[definition.owner] or bounds, definition.name, vec(definition.size), origin * CFrame.new(vec(definition.p)), true)
	end
	for index, p in data.checkpoints do
		local cp = index - 1
		local point = vec(p)
		local destination = if cp == 6 or cp == 7 or cp == 8 or cp == 9 then point + Vector3.zAxis else point - Vector3.zAxis
		local marker = part(if cp == 0 then model else checkpoints,
			if cp == 0 then "Start" else string.format("Checkpoint_%03d", cp),
			if cp == 0 then Vector3.new(28, 1, 32) else Vector3.new(24, 1, 20),
			origin * CFrame.lookAt(point, destination), false)
		marker.CanTouch, marker.CanQuery = true, true
		marker:SetAttribute("PlanningId", string.format("CP%02d", cp))
	end
	local finish = part(model, "Finish", Vector3.new(26, 9, 3), origin * CFrame.new(vec(data.finish) + Vector3.new(0, 4.5, 0)), false)
	finish.CanTouch, finish.CanQuery = true, true
	local root = part(bounds, "CourseOrigin", Vector3.one, origin, false)
	model.PrimaryPart = root
	local mainFall = part(fallZones, "FallZone_Main", Vector3.new(1100, 2, 920), origin * CFrame.new(30, 2, -20), false)
	mainFall.CanTouch, mainFall.CanQuery = true, true
	local startPen = folder(model, "StartPen")
	part(startPen, "StartGate", Vector3.new(29, 16, 1), origin * CFrame.new(-170, 16, 237), true)
	folder(startPen, "GateVisuals")
	-- Entry closes without a moving physical bar sweeping or trapping a committed racer.
	part(obstacles, "TrainEntryGate", Vector3.new(13, 18, 1), origin * CFrame.new(205, 91, -26), false)
	local audio = folder(obstacles, "Audio")
	for soundName, p in { CrossingBell = {205, 90, -28}, TrafficEngine = {-170, 14, 164}, SwingAir = {0, 88, -244} } do
		local emitter = part(audio, soundName, Vector3.one, origin * CFrame.new(vec(p)), false)
		local sound = Instance.new("Sound")
		sound.Name, sound.Looped, sound.Volume = soundName, true, .3
		sound.RollOffMinDistance, sound.RollOffMaxDistance = 12, 105
		sound.Parent = emitter
	end
	model.Parent = workspace
	return model
end

return Installer
