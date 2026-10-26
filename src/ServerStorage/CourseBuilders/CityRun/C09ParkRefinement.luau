--!strict
local Patch = {}

function Patch.Apply(imported: Model)
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning(), "Intended experience in Edit mode required")
	local course = workspace.Course_CityRun
	assert(course:GetAttribute("ReviewBuildId") == "C09_04_Park", "C09 park required")
	local building = course.Decoration.CourtStairBase
	assert((building.CourtStairBase__Brick__00.Position - Vector3.new(3313, 11.5, 80)).Magnitude < .01, "Courtyard frontage moved")
	local data = require(script.Parent.C09ParkRefinementManifest)
	local archive = game.ServerStorage.CityRun_C09_Archive
	local markers, count = {}, 0
	for _, part in imported:GetDescendants() do
		assert(not part:IsA("LuaSourceContainer"), "Unexpected asset script")
		if not part:IsA("BasePart") then continue end
		assert(data.meshes[part.Name], "Unexpected refinement mesh")
		count += 1
		for _, key in {"Origin", "Right", "Up", "Forward"} do
			if string.find(part.Name, "Marker" .. key .. "__", 1, true) then markers[key] = part end
		end
	end
	local expected = 0
	for _ in data.meshes do expected += 1 end
	assert(count == expected, "Incomplete refinement asset")
	for _, key in {"Origin", "Right", "Up", "Forward"} do assert(markers[key], "Missing marker") end
	local detail = Instance.new("Folder")
	detail.Name, detail.Parent = "Details", course.Decoration.CourtyardPark
	local frontage = Instance.new("Folder")
	frontage.Name, frontage.Parent = "ParkFrontage", building
	local groups = {}
	for name, definition in data.components do
		if definition.section == "Calibration" then continue end
		local model = Instance.new("Model")
		model.Name = string.gsub(name, "^[^_]+_", "")
		model.Parent = if definition.section == "Frontage" then frontage else detail
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
		part.Material = if definition.material == "Cream" then Enum.Material.Concrete
			elseif definition.material == "Terracotta" then Enum.Material.Brick
			elseif definition.material == "Iron" then Enum.Material.Metal else Enum.Material.SmoothPlastic
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, true
		if part:IsA("MeshPart") then part.TextureID = "" end
		part.Parent = groups[definition.component] or archive
	end
	for _, model in groups do model.WorldPivot = model:GetBoundingBox() end
	local signs = course.Decoration.BranchDirections2
	local savedSigns = signs:Clone()
	savedSigns.Name, savedSigns.Parent = "BranchDirections2BeforeBoardResize", archive
	for _, label in {"MAIN", "EXPERT"} do
		local panel = signs["Board_" .. label]:FindFirstChildWhichIsA("BasePart")
		local center = panel.CFrame
		for _, model in signs:GetChildren() do
			if model.Name == "Board_" .. label or string.find(model.Name, "Lettering_" .. label .. "_", 1, true) == 1
				or string.find(model.Name, "Arrow_" .. label .. "_", 1, true) == 1 then
				for _, part in model:GetDescendants() do
					if not part:IsA("BasePart") then continue end
					local relative = center:ToObjectSpace(part.CFrame)
					part.CFrame = center * CFrame.new(relative.Position * .8) * relative.Rotation
					part.Size *= .8
				end
				model.WorldPivot = model:GetBoundingBox()
			end
		end
	end
	imported.Parent = archive
	course:SetAttribute("ReviewBuildId", "C09_05_Park")
	course:SetAttribute("VisualReviewPassed", false)
	return {meshes=count - 4, descendants=#course:GetDescendants(), boardScale=.8}
end

return Patch
