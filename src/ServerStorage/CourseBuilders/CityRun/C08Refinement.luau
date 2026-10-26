--!strict
local Refinement = {}

function Refinement.Apply(imported: Model)
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
	local course = workspace.Course_CityRun
	assert(course:GetAttribute("ReviewBuildId") == "C08_02_GoldenHour", "Refinement already applied or wrong base")
	local data = require(script.Parent.C08RefinementManifest)
	local markers, count = {}, 0
	for _, part in imported:GetDescendants() do
		assert(not part:IsA("LuaSourceContainer"), "Unexpected asset script")
		if part:IsA("BasePart") then
			assert(data.meshes[part.Name], "Unexpected mesh " .. part.Name)
			count += 1
			for _, key in {"Origin", "Right", "Up", "Forward"} do
				if string.find(part.Name, "Marker" .. key .. "__", 1, true) then markers[key] = part end
			end
		end
	end
	local expected = 0
	for _ in data.meshes do expected += 1 end
	assert(count == expected, "Incomplete refinement")
	for _, key in {"Origin", "Right", "Up", "Forward"} do assert(markers[key]) end
	imported:ScaleTo(imported:GetScale() * 10 / (markers.Right.Position - markers.Origin.Position).Magnitude)
	local frame = CFrame.fromMatrix(markers.Origin.Position, (markers.Right.Position-markers.Origin.Position).Unit,
		(markers.Up.Position-markers.Origin.Position).Unit, (markers.Origin.Position-markers.Forward.Position).Unit)
	local origin = CFrame.new(3500, 0, 0)
	local archive = Instance.new("Folder")
	archive.Name, archive.Parent = "C08_02_Visuals", game.ServerStorage.CityRun_C08_ReplacedGeneratedParts
	local depth = Instance.new("Folder")
	depth.Name, depth.Parent = "CityDepth", course.Decoration
	local groups = {}
	for name, definition in data.components do
		if definition.section == "Calibration" then continue end
		local group
		if string.sub(name, 1, 16) == "EditableSurface_" then
			group = assert(course.Obstacles.WalkingSurfaces:FindFirstChild(string.sub(name, 17)))
			for _, old in group:GetChildren() do if old:IsA("MeshPart") then old.Parent = archive end end
		else
			local old = course.Decoration:FindFirstChild(name)
			if old then old.Parent = archive end
			group = Instance.new("Model")
			group.Name = name
			group.WorldPivot = origin * CFrame.new(table.unpack(definition.pivot))
			group:SetAttribute("Section", definition.section)
			group:SetAttribute("EditableUnit", true)
			group.Parent = if string.sub(name, 1, 4) == "City" then depth else course.Decoration
		end
		groups[name] = group
	end
	for _, part in imported:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		local definition = data.meshes[part.Name]
		local mat = definition.material
		part.CFrame = origin * frame:ToObjectSpace(part.CFrame)
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, true
		local c = data.colors[mat]
		part.Color = Color3.new(c[1],c[2],c[3])
		part.Material = if mat == "Brick" or mat == "Terracotta" then Enum.Material.Brick
			elseif mat == "Cream" or mat == "Stone" or mat == "Plaster" then Enum.Material.Concrete
			elseif mat == "Rail" or mat == "Iron" then Enum.Material.Metal
			elseif string.sub(mat,1,4) == "Wood" then Enum.Material.WoodPlanks
			elseif mat == "Roof" then Enum.Material.Asphalt else Enum.Material.SmoothPlastic
		if part:IsA("MeshPart") then part.TextureID = "" end
		part.Parent = groups[definition.component] or archive
	end
	local offsets = {{-10.4,7.5},{-10.4,7.5},{10.4,7.5},{-10.4,7.5},{-10.4,7.5},
		{10.4,-7.5},{10.4,-7.5},{-10.4,-7.5},{-10.4,7.5}}
	for _, model in course.RouteMarkers.CheckpointSigns:GetChildren() do
		local index = tonumber(string.match(model.Name, "%d+"))
		local cp = model.CheckpointTrigger.Value
		local p = cp.Position + Vector3.new(offsets[index][1], 8.1, offsets[index][2])
		model.NumberedBeacon.CFrame = CFrame.new(p) * cp.CFrame.Rotation
		model.NumberedBeacon.Size = Vector3.new(4.4,5.2,4.4)
		model.BeaconCap.CFrame = CFrame.new(p + Vector3.new(0,2.8,0))
		model.BeaconCap.Size = Vector3.new(4.8,.25,4.8)
		model.Post.CFrame = CFrame.new(p - Vector3.new(0,5.3,0))
		model.Post.Size = Vector3.new(.45,5.6,.45)
	end
	imported.Parent = archive
	course:SetAttribute("ReviewBuildId", "C08_03_GoldenHour")
	course:SetAttribute("VisualReviewPassed", false)
	return {meshes=count, cityDepthModels=#depth:GetChildren(), descendants=#course:GetDescendants()}
end

return Refinement
