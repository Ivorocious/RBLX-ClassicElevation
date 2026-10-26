--!strict
local Depot = {}

function Depot.Apply(imported: Model)
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
	local course = workspace.Course_CityRun
	assert(course:GetAttribute("ReviewBuildId") == "C10_02" and #course:GetDescendants() == 4414,
		"The owner-edited course changed; inspect it before installing C11")
	assert(not game.ServerStorage:FindFirstChild("CityRun_C11_Archive"), "C11 already started")
	local data = require(script.Parent.C11DepotManifest)
	local markers, count, expected, names = {}, 0, 0, {}
	for _ in data.meshes do expected += 1 end
	for _, part in imported:GetDescendants() do
		assert(not part:IsA("LuaSourceContainer"), "Unexpected imported script")
		if not part:IsA("BasePart") then continue end
		assert(data.meshes[part.Name] and not names[part.Name], "Unexpected or duplicate depot mesh")
		names[part.Name] = true
		count += 1
		for _, key in { "Origin", "Right", "Up", "Forward" } do
			if string.find(part.Name, "Marker" .. key .. "__", 1, true) then markers[key] = part end
		end
	end
	assert(count == expected, "Incomplete depot asset")
	for _, key in { "Origin", "Right", "Up", "Forward" } do assert(markers[key], "Missing marker") end
	imported:ScaleTo(imported:GetScale() * 10 / (markers.Right.Position - markers.Origin.Position).Magnitude)
	local frame = CFrame.fromMatrix(markers.Origin.Position,
		(markers.Right.Position - markers.Origin.Position).Unit,
		(markers.Up.Position - markers.Origin.Position).Unit,
		(markers.Origin.Position - markers.Forward.Position).Unit)
	local archive = Instance.new("Folder")
	archive.Name, archive.Parent = "CityRun_C11_Archive", game.ServerStorage
	local oldVisuals = Instance.new("Folder")
	oldVisuals.Name, oldVisuals.Parent = "ReplacedDepotVisuals", archive
	local moving = course.Obstacles.Moving
	for _, name in { "ActiveTrain0", "ActiveTrain1", "ActiveTrain2", "TrainBarrier" } do
		moving[name].Parent = oldVisuals
	end
	for _, name in { "SidingSupports", "DepotLife" } do
		local model = course.Decoration:FindFirstChild(name)
		assert(model, "Missing original depot component")
		local saved = Instance.new("Folder")
		saved.Name, saved.Parent = name, oldVisuals
		for _, part in model:GetDescendants() do
			if part:IsA("MeshPart") then
				assert(not part.CanCollide, "Preserve unexpected owner collision")
				part.Parent = saved
			end
		end
	end
	for i = 0, 4 do
		local name = string.format("StationaryTrains_00_%02d", i)
		local model = course.Obstacles.WalkingSurfaces[name]
		local saved = Instance.new("Folder")
		saved.Name, saved.Parent = name, oldVisuals
		for _, part in model:GetChildren() do
			if part:IsA("MeshPart") then
				assert(not part.CanCollide, "Preserve unexpected parked train collision")
				part.Parent = saved
			end
		end
	end
	for _, name in { "Depot_RoofVent1", "Depot_RoofVent2", "Depot_RoofVent3" } do
		local model = course.Decoration.C10Streets:FindFirstChild(name)
		if model then model.Parent = oldVisuals end
	end
	local scenery = Instance.new("Folder")
	scenery.Name, scenery.Parent = "C11Depot", course.Decoration
	local groups = {}
	for name, definition in data.components do
		if definition.section == "Calibration" then continue end
		local model = Instance.new("Model")
		model.Name = name
		model.Parent = if definition.section == "Moving" then moving else scenery
		model:SetAttribute("EditableUnit", true)
		model:SetAttribute("Section", definition.section)
		groups[name] = model
	end
	for _, part in imported:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		local mesh = data.meshes[part.Name]
		local color = data.colors[mesh.material]
		part.CFrame = CFrame.new(3500, 0, 0) * frame:ToObjectSpace(part.CFrame)
		part.Color = Color3.new(color[1], color[2], color[3])
		part.Material = if mesh.material == "Light" or mesh.material == "Red" then Enum.Material.Neon
			elseif mesh.material == "Iron" or mesh.material == "Rail" then Enum.Material.Metal
			elseif mesh.material == "Brick" then Enum.Material.Brick
			elseif mesh.material == "WoodDark" or mesh.material == "Wood" then Enum.Material.WoodPlanks
			elseif mesh.material == "Stone" then Enum.Material.Concrete
			else Enum.Material.SmoothPlastic
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, true
		if part:IsA("MeshPart") then part.TextureID = "" end
		part.Parent = groups[mesh.component] or oldVisuals
	end
	for name, model in groups do
		local pivot = data.components[name].pivot
		model.WorldPivot = if pivot then CFrame.new(pivot[1], pivot[2], pivot[3]) else model:GetBoundingBox()
	end
	local gate = course.Obstacles.TrainEntryGate
	gate.CanCollide, gate.CanTouch, gate.CanQuery = false, false, false
	gate:SetAttribute("WarningOnly", true)
	imported.Parent = archive
	course:SetAttribute("ReviewBuildId", "C11_01")
	course:SetAttribute("CityRunRevision", "C11")
	course:SetAttribute("VisualReviewPassed", false)
	for _, key in { "GroundingScore", "ReadabilityScore", "VariationScore", "CompositionScore" } do
		course:SetAttribute(key, nil)
	end
	return { build = "C11_01", newMeshes = count-4, descendants = #course:GetDescendants() }
end

return Depot
