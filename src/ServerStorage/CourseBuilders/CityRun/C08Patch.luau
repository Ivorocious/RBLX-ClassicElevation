--!strict
local Patch = {}

local function folder(parent, name)
	local result = Instance.new("Folder")
	result.Name, result.Parent = name, parent
	return result
end

local function visual(parent, name, size, cf, color)
	local item = Instance.new("Part")
	item.Name, item.Size, item.CFrame, item.Color = name, size, cf, color
	item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, true
	item.Material = Enum.Material.SmoothPlastic
	item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

function Patch.Apply(imported: Model)
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning(), "Intended experience in Edit mode required")
	local course = workspace.Course_CityRun
	assert(course:GetAttribute("CityRunRevision") == "C07", "C08 overlay requires the preserved C07 course")
	local data = require(script.Parent.C08Manifest)
	local origin = CFrame.new(3500, 0, 0)
	local markers, meshCount = {}, 0
	for _, item in imported:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Unexpected asset script")
		if item:IsA("BasePart") then
			meshCount += 1
			assert(data.meshes[item.Name], "Unexpected asset mesh " .. item.Name)
			for _, key in {"Origin", "Right", "Up", "Forward"} do
				if string.find(item.Name, "Marker" .. key .. "__", 1, true) then markers[key] = item end
			end
		end
	end
	local expected = 0
	for _ in data.meshes do expected += 1 end
	assert(meshCount == expected, "Incomplete overlay")
	for _, key in {"Origin", "Right", "Up", "Forward"} do assert(markers[key], "Missing calibration marker") end
	local archive = folder(game.ServerStorage, "CityRun_C08_ReplacedGeneratedParts")
	imported:ScaleTo(imported:GetScale() * 10 / (markers.Right.Position - markers.Origin.Position).Magnitude)
	local sourceFrame = CFrame.fromMatrix(markers.Origin.Position,
		(markers.Right.Position - markers.Origin.Position).Unit,
		(markers.Up.Position - markers.Origin.Position).Unit,
		(markers.Origin.Position - markers.Forward.Position).Unit)
	local scenery = folder(course.Decoration, "MarketEditableProps")
	local backdrop = folder(course.Decoration, "MarketBackdrop")
	local groups = {}
	local usedComponents = {}
	for _, definition in data.meshes do usedComponents[definition.component] = true end
	for name, definition in data.components do
		if definition.section == "Calibration" or not usedComponents[name] then continue end
		local model = Instance.new("Model")
		model.Name = name
		model.WorldPivot = origin * CFrame.new(table.unpack(definition.pivot))
		model:SetAttribute("Section", definition.section)
		model:SetAttribute("EditableUnit", true)
		model.Parent = if string.sub(name, 1, 16) == "EditableSurface_" or string.sub(name, 1, 7) == "Siding_"
			then course.Obstacles.WalkingSurfaces elseif string.sub(name, 1, 15) == "MarketBackdrop_" then backdrop else scenery
		groups[name] = model
	end
	local oldLife = course.Decoration.MarketLife
	local ownerCollisions = {}
	for _, part in oldLife:GetChildren() do
		if part:IsA("BasePart") then
			local material = string.match(part.Name, "__([^_]+)__")
			if material then ownerCollisions[material] = part.CanCollide end
		end
	end
	for _, item in imported:GetDescendants() do
		if not item:IsA("BasePart") then continue end
		item.CFrame = origin * sourceFrame:ToObjectSpace(item.CFrame)
		item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, true
		local definition = data.meshes[item.Name]
		local comp, mat = definition.component, definition.material
		local c = data.colors[mat]
		item.Color = Color3.new(c[1], c[2], c[3])
		item.Material = if mat == "Light" or mat == "Red" then Enum.Material.Neon
			elseif mat == "Brick" or mat == "Terracotta" then Enum.Material.Brick
			elseif mat == "Stone" or mat == "Cream" or mat == "Plaster" then Enum.Material.Concrete
			elseif string.sub(mat, 1, 4) == "Wood" then Enum.Material.WoodPlanks
			elseif mat == "Iron" or mat == "Rail" then Enum.Material.Metal
			elseif mat == "Roof" then Enum.Material.Asphalt else Enum.Material.SmoothPlastic
		if item:IsA("MeshPart") then item.TextureID = "" end
		if string.sub(comp, 1, 6) == "Marker" then
			item.Parent = archive
		else
			item.Parent = groups[comp]
			if groups[comp].Parent == scenery then
				item.CanCollide = ownerCollisions[mat] == true
				-- Carry the owner's raised teal trim into the separated market pieces.
				if mat == "Teal" then item.CFrame += Vector3.new(0, .47149086, 0) end
			end
		end
	end
	for _, surface in data.surfaces do
		local collider = course.Obstacles.WalkingSurfaces:FindFirstChild(surface.name)
		assert(collider and collider:IsA("BasePart"), "Missing original platform " .. surface.name)
		local name = if surface.style == "train" then "Siding_" .. surface.name else "EditableSurface_" .. surface.name
		local group = groups[name]
		assert(group, "Missing editable surface " .. name)
		group.Name, collider.Parent = surface.name, group
		group.PrimaryPart = collider
		group:SetAttribute("EditingHint", "Move this whole model to move the platform and collision together")
	end
	for _, item in course.Decoration:GetChildren() do
		if string.sub(item.Name, 1, 6) == "Route_" or string.sub(item.Name, 1, 7) == "Siding_" or item == oldLife then
			item.Parent = archive
		end
	end
	local owner = folder(course, "OwnerEdits")
	local walls = folder(owner, "InvisibleWalls")
	local hazards = folder(course.Obstacles, "OwnerKillStrips")
	local preserved = 0
	for _, item in workspace:GetChildren() do
		if item:IsA("BasePart") and (item.Position - Vector3.new(3330, 10, 230)).Magnitude < 180 then
			if item:GetAttribute("HazardType") == "Kill" then item.Parent = hazards
			elseif item.Transparency == 1 and item.CanCollide then item.Parent = walls
			elseif item.Name == "Part" and #item:GetDescendants() == 0 then item.Parent = owner
			else continue end
			preserved += 1
		elseif item:IsA("Model") and (item.Name == "market stall" or item.Name == "02_HorizonDepthFade") then
			item.Parent = owner
			preserved += 1
		end
	end
	local signFolder = folder(course.RouteMarkers, "CheckpointSigns")
	local green, cream, ink = Color3.fromRGB(15, 166, 132), Color3.fromRGB(255, 246, 214), Color3.fromRGB(24, 47, 52)
	for _, cp in course.Checkpoints:GetChildren() do
		if not cp:IsA("BasePart") then continue end
		local index = tonumber(string.match(cp.Name, "%d+"))
		local model = Instance.new("Model")
		model.Name, model.Parent = string.format("Checkpoint_%02d_Sign", index), signFolder
		model.WorldPivot = cp.CFrame
		local y = .22
		for _, side in {-1, 1} do
			visual(model, "FloorBorder", Vector3.new(cp.Size.X - .8, .14, .7), cp.CFrame * CFrame.new(0, y, side * (cp.Size.Z / 2 - .6)), green)
			visual(model, "FloorBorder", Vector3.new(.7, .14, cp.Size.Z - .8), cp.CFrame * CFrame.new(side * (cp.Size.X / 2 - .6), y, 0), green)
		end
		local signCF = cp.CFrame * CFrame.new(cp.Size.X / 2 - 1.6, 9, 0)
		visual(model, "Post", Vector3.new(.5, 8, .5), signCF * CFrame.new(0, -5, 0), ink)
		local panel = visual(model, "NumberedBeacon", Vector3.new(5.6, 6, 5.6), signCF, green)
		for _, face in {Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right} do
			local gui = Instance.new("SurfaceGui")
			gui.Name, gui.Face, gui.CanvasSize, gui.Parent = "CheckpointLabel", face, Vector2.new(336, 360), panel
			gui.LightInfluence = 0
			for _, definition in {{"Heading", "CHECKPOINT", .04, .23, 33}, {"Number", string.format("%02d", index), .22, .72, 168}} do
				local label = Instance.new("TextLabel")
				label.Name, label.BackgroundTransparency = definition[1], 1
				label.Position, label.Size = UDim2.fromScale(0, definition[3]), UDim2.fromScale(1, definition[4])
				label.Font, label.TextColor3, label.TextSize = Enum.Font.GothamBold, cream, definition[5]
				label.Text, label.Parent = definition[2], gui
			end
		end
		visual(model, "BeaconCap", Vector3.new(6, .25, 6), signCF * CFrame.new(0, 3.2, 0), cream)
		local reference = Instance.new("ObjectValue")
		reference.Name, reference.Value, reference.Parent = "CheckpointTrigger", cp, model
	end
	course:SetAttribute("CityRunRevision", "C08")
	course:SetAttribute("ReviewBuildId", "C08_02_GoldenHour")
	course:SetAttribute("VisualReviewPassed", false)
	course:SetAttribute("EditableSurfaceCount", #data.surfaces)
	imported.Parent = archive
	return {meshes=meshCount, surfaces=#data.surfaces, preservedOwnerRoots=preserved, invisibleWalls=#walls:GetChildren(), killStrips=#hazards:GetChildren()}
end

return Patch
