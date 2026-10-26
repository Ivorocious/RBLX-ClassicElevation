--!strict
local Patch = {}

local function folder(parent: Instance, name: string): Folder
	local item = Instance.new("Folder")
	item.Name, item.Parent = name, parent
	return item
end

function Patch.Apply(imported: Model)
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning(), "Intended experience in Edit mode required")
	local course = workspace.Course_CityRun
	local data = require(script.Parent.C10Manifest)
	assert(course:GetAttribute("ReviewBuildId") == data.expectedOwnerBuild, "Owner-edited C09 required")
	assert(#course:GetDescendants() == 3961, "Course changed since the C10 backup; inspect before applying")
	assert(not game.ServerStorage:FindFirstChild("CityRun_C10_Archive"), "C10 is already installed")
	local walking = course.Obstacles.WalkingSurfaces
	for _, name in data.replacements do
		local model = assert(walking:FindFirstChild(name), "Missing original station platform " .. name)
		local collider = model:FindFirstChild(name)
		assert(collider and collider:IsA("BasePart") and math.abs(collider.Position.X - 3830) < .01,
			"Station platforms changed; refresh the overlay")
	end
	local markers, count = {}, 0
	for _, part in imported:GetDescendants() do
		assert(not part:IsA("LuaSourceContainer"), "Unexpected asset script")
		if not part:IsA("BasePart") then continue end
		assert(data.meshes[part.Name], "Unexpected C10 mesh " .. part.Name)
		count += 1
		for _, key in { "Origin", "Right", "Up", "Forward" } do
			if string.find(part.Name, "Marker" .. key .. "__", 1, true) then markers[key] = part end
		end
	end
	local expected = 0
	for _ in data.meshes do expected += 1 end
	assert(count == expected, "Incomplete C10 asset")
	for _, key in { "Origin", "Right", "Up", "Forward" } do assert(markers[key], "Missing calibration marker") end
	imported:ScaleTo(imported:GetScale() * 10 / (markers.Right.Position - markers.Origin.Position).Magnitude)
	local sourceFrame = CFrame.fromMatrix(markers.Origin.Position,
		(markers.Right.Position - markers.Origin.Position).Unit,
		(markers.Up.Position - markers.Origin.Position).Unit,
		(markers.Origin.Position - markers.Forward.Position).Unit)

	local archive = folder(game.ServerStorage, "CityRun_C10_Archive")
	local replacements = folder(archive, "StationPlatformsBeforeCrumble")
	for _, name in data.replacements do walking[name].Parent = replacements end
	local gameplay = folder(course.Obstacles, "C10Obstacles")
	local scenery = folder(course.Decoration, "C10Streets")
	local directions = folder(course.RouteMarkers, "C10Directions")
	local groups, crumbleParts = {}, {}
	local groupCount = 0
	for name, definition in data.components do
		if definition.section == "Calibration" then continue end
		local model = Instance.new("Model")
		model.Name = name
		model.Parent = if definition.role == "Kill" or definition.role == "Crumble" then gameplay
			elseif definition.section == "Wayfinding" then directions else scenery
		model:SetAttribute("EditableUnit", true)
		model:SetAttribute("Section", definition.section)
		model:SetAttribute("C10Role", definition.role)
		groups[name] = model
		groupCount += 1
	end
	for _, part in imported:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		local mesh = data.meshes[part.Name]
		local definition = data.components[mesh.component]
		part.CFrame = CFrame.new(3500, 0, 0) * sourceFrame:ToObjectSpace(part.CFrame)
		local color = data.colors[mesh.material]
		part.Color = Color3.new(color[1], color[2], color[3])
		part.Material = if mesh.material == "Danger" then Enum.Material.Neon
			elseif mesh.material == "Brick" or mesh.material == "Terracotta" then Enum.Material.Brick
			elseif mesh.material == "Roof" then Enum.Material.Asphalt
			elseif mesh.material == "Iron" or mesh.material == "Rail" then Enum.Material.Metal
			elseif mesh.material == "Plaster" or mesh.material == "Cream" or mesh.material == "Stone"
				or mesh.material == "Sage" or mesh.material == "Ochre" or mesh.material == "Powder" then Enum.Material.Concrete
			else Enum.Material.SmoothPlastic
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, true
		if part:IsA("MeshPart") then part.TextureID = "" end
		part.Parent = groups[mesh.component] or archive
		if definition.role == "Kill" then
			part:SetAttribute("HazardType", "Kill")
			part.CanTouch = true
			for key, value in definition.attrs do part:SetAttribute(key, value) end
		elseif definition.role == "Crumble" and mesh.material == "Crumble" then
			part:SetAttribute("HazardType", "Crumble")
			part.CanTouch, part.CanCollide = true, true
			for key, value in definition.attrs do part:SetAttribute(key, value) end
			crumbleParts[mesh.component] = part
		end
	end
	for name, part in crumbleParts do
		-- The existing crumble service hides descendant visuals with the physical tile.
		for _, visual in groups[name]:GetChildren() do
			if visual ~= part and visual:IsA("BasePart") then visual.Parent = part end
		end
	end
	for _, model in groups do model.WorldPivot = model:GetBoundingBox() end
	imported.Parent = archive
	course:SetAttribute("CityRunRevision", "C10")
	course:SetAttribute("ReviewBuildId", "C10_01")
	course:SetAttribute("VisualReviewPassed", false)
	course:SetAttribute("EditableSurfaceCount", #walking:GetChildren())
	return { meshes = count - 4, groups = groupCount, descendants = #course:GetDescendants(), archivedPlatforms = #data.replacements }
end

return Patch
