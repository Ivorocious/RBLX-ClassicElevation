--!strict
local Patch = {}

function Patch.Apply(imported: Model)
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning(), "Intended experience in Edit mode required")
	local course = workspace.Course_CityRun
	assert(course:GetAttribute("ReviewBuildId") == "C09_03", "Restore the original courtyard before installing the park")
	assert(not course.Decoration:FindFirstChild("CourtyardPark"), "Park already installed")
	local data = require(script.Parent.C09ParkManifest)
	local archive = game.ServerStorage.CityRun_C09_Archive
	local markers, count = {}, 0
	for _, part in imported:GetDescendants() do
		assert(not part:IsA("LuaSourceContainer"), "Unexpected asset script")
		if not part:IsA("BasePart") then continue end
		assert(data.meshes[part.Name], "Unexpected park mesh")
		count += 1
		for _, key in {"Origin", "Right", "Up", "Forward"} do
			if string.find(part.Name, "Marker" .. key .. "__", 1, true) then markers[key] = part end
		end
	end
	local expected = 0
	for _ in data.meshes do expected += 1 end
	assert(count == expected, "Incomplete park asset")
	for _, key in {"Origin", "Right", "Up", "Forward"} do assert(markers[key], "Missing park marker") end
	local tiles = course.Decoration.CourtyardLife.CourtyardLife__Stone__00
	assert(not tiles.CanCollide and tiles.Size.Y < 1, "Unexpected old courtyard tiles")
	assert(course.Decoration.Ground.Ground__Stone__00.Transparency == 0, "Original ground must remain visible")
	local park = Instance.new("Folder")
	park.Name, park.Parent = "CourtyardPark", course.Decoration
	local groups = {}
	for name, definition in data.components do
		if definition.section == "Calibration" then continue end
		local model = Instance.new("Model")
		model.Name, model.Parent = string.sub(name, 6), park
		model:SetAttribute("EditableUnit", true)
		groups[name] = model
	end
	imported:ScaleTo(imported:GetScale() * 10 / (markers.Right.Position - markers.Origin.Position).Magnitude)
	local frame = CFrame.fromMatrix(markers.Origin.Position,
		(markers.Right.Position - markers.Origin.Position).Unit,
		(markers.Up.Position - markers.Origin.Position).Unit,
		(markers.Origin.Position - markers.Forward.Position).Unit)
	for _, part in imported:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		local definition = data.meshes[part.Name]
		part.CFrame = CFrame.new(3500, 0, 0) * frame:ToObjectSpace(part.CFrame)
		local color = data.colors[definition.material]
		part.Color = Color3.new(color[1], color[2], color[3])
		part.Material = if definition.material == "Turf" then Enum.Material.Grass
			elseif definition.material == "Cream" then Enum.Material.Concrete
			elseif string.sub(definition.material, 1, 4) == "Wood" then Enum.Material.Wood
			else Enum.Material.SmoothPlastic
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, true
		if part:IsA("MeshPart") then part.TextureID = "" end
		part.Parent = groups[definition.component] or archive
	end
	for _, model in groups do model.WorldPivot = model:GetBoundingBox() end
	tiles.Parent = archive
	for _, model in workspace:GetChildren() do
		if model.Name == "01_CloserFloorDepthFade" and model:IsA("Model") then
			local layer = model:FindFirstChild("Layer_01_Near_Clear")
			if layer and layer:IsA("BasePart") and layer.Size.X > 200 then
				model.Name, model.Parent = "OwnerCourtyardFade", archive
			end
		end
	end
	imported.Parent = archive
	course:SetAttribute("ReviewBuildId", "C09_04_Park")
	course:SetAttribute("VisualReviewPassed", false)
	return {meshes=count - 4, editableGroups=13, descendants=#course:GetDescendants(), groundUnchanged=true}
end

return Patch
