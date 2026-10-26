--!strict
local Patch = {}

local function folder(parent, name)
	local item = Instance.new("Folder")
	item.Name, item.Parent = name, parent
	return item
end

local function vec(values)
	return Vector3.new(values[1], values[2], values[3])
end

function Patch.Apply(imported: Model)
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning(), "Intended experience in Edit mode required")
	local course = workspace.Course_CityRun
	assert(course:GetAttribute("ReviewBuildId") == "C08_03_GoldenHour", "C09 requires the preserved owner-edited C08")
	assert(not game.ServerStorage:FindFirstChild("CityRun_C09_Archive"), "C09 archive already exists")
	local data = require(script.Parent.C09Manifest)
	local origin = CFrame.new(3500, 0, 0)
	local ownerBuilding = assert(workspace:FindFirstChild("CourtStairBase"), "Missing owner building")
	local brick = ownerBuilding:FindFirstChild("CourtStairBase__Brick__00")
	assert(brick and (brick.Size - Vector3.new(68.9791565, 34.0641937, 16.7403145)).Magnitude < .01, "Owner building changed; refresh overlay")
	assert((brick.Position - Vector3.new(3346.548828, 16.5319996, 111.2853546)).Magnitude < .01, "Owner building moved; refresh overlay")
	local oldRoots, sourceParts = {}, {}
	for _, name in { "BranchDirections2", "BranchDirections4", "BranchDirections8", "MarketCloseFronts", "MarketArch" } do
		local old = if name == "MarketArch" then course.Decoration.MarketEditableProps[name] else course.Decoration[name]
		oldRoots[name] = old
		for _, part in old:GetChildren() do
			if part:IsA("BasePart") then sourceParts[part.Name] = part end
		end
	end
	local markers, count = {}, 0
	for _, part in imported:GetDescendants() do
		assert(not part:IsA("LuaSourceContainer"), "Unexpected asset script")
		if part:IsA("BasePart") then
			local definition = assert(data.meshes[part.Name], "Unexpected mesh " .. part.Name)
			if definition.sourceMesh then assert(sourceParts[definition.sourceMesh], "Missing original editing source") end
			count += 1
			for _, key in { "Origin", "Right", "Up", "Forward" } do
				if string.find(part.Name, "Marker" .. key .. "__", 1, true) then markers[key] = part end
			end
		end
	end
	local expected = 0
	for _ in data.meshes do expected += 1 end
	assert(count == expected, "Incomplete C09 overlay")
	for _, key in { "Origin", "Right", "Up", "Forward" } do assert(markers[key], "Missing calibration marker") end
	local archive = folder(game.ServerStorage, "CityRun_C09_Archive")
	local replacements = folder(archive, "ReplacedMergedGeometry")
	local roots = {}
	for name, old in oldRoots do
		local root = Instance.new("Model")
		root.Name, root.WorldPivot = name, old:GetPivot()
		for key, value in old:GetAttributes() do root:SetAttribute(key, value) end
		root:SetAttribute("EditableUnit", true)
		root.Parent = old.Parent
		roots[name] = root
		old.Parent = replacements
	end
	local ownerDetails = folder(ownerBuilding, "EditableFacade")
	-- Retain the rejected depth geometry outside the active course for recovery.
	local depth = folder(archive, "CourtyardDepth")
	imported:ScaleTo(imported:GetScale() * 10 / (markers.Right.Position - markers.Origin.Position).Magnitude)
	local sourceFrame = CFrame.fromMatrix(markers.Origin.Position,
		(markers.Right.Position - markers.Origin.Position).Unit,
		(markers.Up.Position - markers.Origin.Position).Unit,
		(markers.Origin.Position - markers.Forward.Position).Unit)
	local groups = {}
	for name, definition in data.components do
		if definition.section == "Calibration" then continue end
		local parent, shortName = depth, name
		for sourceName, root in roots do
			if string.sub(name, 1, #sourceName + 1) == sourceName .. "_" then
				parent, shortName = root, string.sub(name, #sourceName + 2)
				break
			end
		end
		if string.sub(name, 1, 12) == "OwnerFacade_" then parent, shortName = ownerDetails, string.sub(name, 13) end
		local model = Instance.new("Model")
		model.Name, model.Parent = shortName, parent
		model:SetAttribute("EditableUnit", true)
		model:SetAttribute("Section", definition.section)
		groups[name] = model
	end
	for _, part in imported:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		local definition = data.meshes[part.Name]
		part.CFrame = origin * sourceFrame:ToObjectSpace(part.CFrame)
		if definition.sourceMesh then
			local old = sourceParts[definition.sourceMesh]
			local reference = data.sourceFrames[definition.sourceMesh]
			local relative = CFrame.new(table.unpack(reference.cf)):ToObjectSpace(part.CFrame)
			local ratio = old.Size / vec(reference.size)
			part.CFrame = old.CFrame * CFrame.new(relative.Position * ratio) * relative.Rotation
			part.Size *= ratio
			part.Color, part.Material, part.Transparency = old.Color, old.Material, old.Transparency
			part.CanCollide, part.CanTouch, part.CastShadow = old.CanCollide, old.CanTouch, old.CastShadow
		else
			local color = data.colors[definition.material]
			part.Color = Color3.new(color[1], color[2], color[3])
			part.Material = if definition.material == "Brick" or definition.material == "Terracotta" then Enum.Material.Brick
				elseif definition.material == "Plaster" or definition.material == "Cream" or definition.material == "Stone" then Enum.Material.Concrete
				elseif definition.material == "Roof" then Enum.Material.Asphalt else Enum.Material.SmoothPlastic
			part.CanCollide, part.CanTouch = false, false
		end
		part.Anchored, part.CanQuery = true, true
		if part:IsA("MeshPart") then part.TextureID = "" end
		part.Parent = groups[definition.component] or replacements
	end
	for _, model in groups do
		local cf = model:GetBoundingBox()
		model.WorldPivot = cf
	end
	ownerBuilding.Name, ownerBuilding.Parent = "OwnerCourtyardBuilding", course.OwnerEdits
	imported.Parent = replacements
	course:SetAttribute("CityRunRevision", "C09")
	course:SetAttribute("ReviewBuildId", "C09_03")
	course:SetAttribute("VisualReviewPassed", false)
	local editableGroups = 0
	for _, group in groups do if group:IsDescendantOf(course) then editableGroups += 1 end end
	return {meshes=count, editableGroups=editableGroups, descendants=#course:GetDescendants(), archive=archive:GetFullName()}
end

return Patch
