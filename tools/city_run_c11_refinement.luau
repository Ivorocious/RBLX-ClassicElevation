--!strict
local Refinement = {}
function Refinement.Apply(imported: Model)
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
	local course = workspace.Course_CityRun
	assert(course:GetAttribute("ReviewBuildId") == "C11_01")
	local manifest = game.ServerStorage.CourseBuilders.CityRun.C11DepotManifest:Clone()
	local data = require(manifest)
	manifest:Destroy()
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
	assert(data.revision == "C11_02")
	local archive = game.ServerStorage.CityRun_C11_Archive
	assert(not archive:FindFirstChild("C11_01_Depot"))
	local oldVisuals = Instance.new("Folder")
	oldVisuals.Name, oldVisuals.Parent = "C11_01_Depot", archive
	local moving = course.Obstacles.Moving
	for _, name in {"ActiveTrain0","ActiveTrain1","ActiveTrain2","TrainBarrier","TrainBarrierExit"} do moving[name].Parent = oldVisuals end
	course.Decoration.C11Depot.Parent = oldVisuals
	local scenery = Instance.new("Folder")
	scenery.Name, scenery.Parent = "C11Depot", course.Decoration
	local groups = {}
	for name, definition in data.components do
		if definition.section == "Calibration" then continue end
		local model = Instance.new("Model")
		model.Name = name
		local parkedIndex = string.match(name, "^Depot_Parked(%d)$")
		model.Parent = if parkedIndex then course.Obstacles.WalkingSurfaces[string.format("StationaryTrains_00_%02d", tonumber(parkedIndex))]
			elseif definition.section == "Moving" then moving else scenery
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
	imported.Parent = oldVisuals
	course:SetAttribute("ReviewBuildId", "C11_02")
	course:SetAttribute("VisualReviewPassed", false)
	return {build="C11_02", newMeshes=count-4, descendants=#course:GetDescendants()}
end
return Refinement
