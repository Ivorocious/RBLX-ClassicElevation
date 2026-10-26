--!strict
local Refinement = {}

function Refinement.Apply(imported: Model)
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
	local course = workspace.Course_CityRun
	assert(course:GetAttribute("ReviewBuildId") == "C10_01" and #course:GetDescendants() == 4434,
		"C10_01 changed; inspect before applying the review refinement")
	local data = require(script.Parent.C10RefinementManifest)
	local markers, count, expected = {}, 0, 0
	for _ in data.meshes do expected += 1 end
	for _, part in imported:GetDescendants() do
		assert(not part:IsA("LuaSourceContainer"), "Unexpected imported script")
		if not part:IsA("BasePart") then continue end
		assert(data.meshes[part.Name], "Unexpected refinement mesh")
		count += 1
		for _, key in { "Origin", "Right", "Up", "Forward" } do
			if string.find(part.Name, "Marker" .. key .. "__", 1, true) then markers[key] = part end
		end
	end
	assert(count == expected, "Incomplete refinement asset")
	for _, key in { "Origin", "Right", "Up", "Forward" } do assert(markers[key], "Missing marker") end
	local banner = course.Decoration.FinishBanner
	local board = banner.FinishBanner__Coral__00
	assert((board.Position - Vector3.new(3695.0034, 142.0004, 232.0012)).Magnitude < .02
		and math.abs(board.Size.X - 30) < .01, "Finish banner changed since review")
	local archive = game.ServerStorage.CityRun_C10_Archive
	assert(not archive:FindFirstChild("ReviewRefinementArchive"), "Refinement is already installed")
	local saved = Instance.new("Folder")
	saved.Name, saved.Parent = "ReviewRefinementArchive", archive
	local originalBanner = banner
	banner = originalBanner:Clone()
	originalBanner.Parent = saved
	banner.Parent = course.Decoration
	board = banner.FinishBanner__Coral__00
	board.Size = Vector3.new(26, 2.4, board.Size.Z)
	board.Position = Vector3.new(board.Position.X, 146, board.Position.Z)
	local lettering = banner.FinishBanner__White__00
	lettering.Size *= .8
	lettering.Position = Vector3.new(lettering.Position.X, 146.06, lettering.Position.Z)
	local posts = banner.FinishBanner__Teal__00
	posts.Size = Vector3.new(posts.Size.X * 24 / 28, 14, posts.Size.Z)
	posts.Position = Vector3.new(posts.Position.X, 139, posts.Position.Z)
	banner.WorldPivot = banner:GetBoundingBox()
	local arrival = course.Decoration.C10Streets.CityC10_Depot_WestArrival
	arrival:PivotTo(arrival:GetPivot() + Vector3.new(-8, 0, 0))
	course.RouteMarkers.C10Directions.StationCrumble_EntrySign.Parent = saved
	local arrow = course.RouteMarkers.C10Directions.RouteArrow_StationLastTurn:Clone()
	arrow.Name = "RouteArrow_FinalApproach"
	arrow:PivotTo(CFrame.new(3695, 132.18, 218) * CFrame.Angles(0, math.pi, 0))
	arrow.Parent = course.RouteMarkers.C10Directions
	imported:ScaleTo(imported:GetScale() * 10 / (markers.Right.Position - markers.Origin.Position).Magnitude)
	local frame = CFrame.fromMatrix(markers.Origin.Position,
		(markers.Right.Position - markers.Origin.Position).Unit,
		(markers.Up.Position - markers.Origin.Position).Unit,
		(markers.Origin.Position - markers.Forward.Position).Unit)
	local scenery = Instance.new("Folder")
	scenery.Name, scenery.Parent = "C10Refinements", course.Decoration
	local groups = {}
	for name, definition in data.components do
		if definition.section == "Calibration" then continue end
		local model = Instance.new("Model")
		model.Name = name
		model.Parent = if definition.section == "Wayfinding" then course.RouteMarkers.C10Directions else scenery
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
		part.Material = if mesh.material == "Brick" then Enum.Material.Brick
			elseif mesh.material == "Iron" or mesh.material == "Rail" then Enum.Material.Metal
			elseif mesh.material == "WoodDark" then Enum.Material.WoodPlanks
			elseif mesh.material == "Cream" or mesh.material == "Plaster" or mesh.material == "Stone" then Enum.Material.Concrete
			else Enum.Material.SmoothPlastic
		part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, true
		if part:IsA("MeshPart") then part.TextureID = "" end
		part.Parent = groups[mesh.component] or saved
	end
	for _, model in groups do model.WorldPivot = model:GetBoundingBox() end
	groups.Depot_ArrivalGantry:PivotTo(groups.Depot_ArrivalGantry:GetPivot() + Vector3.new(0, 0, -24))
	groups.Depot_TransferGantry:PivotTo(groups.Depot_TransferGantry:GetPivot() + Vector3.new(0, 0, -6))
	imported.Parent = saved
	course:SetAttribute("ReviewBuildId", "C10_02")
	course:SetAttribute("VisualReviewPassed", false)
	return { build = "C10_02", descendants = #course:GetDescendants(), newMeshes = count - 4 }
end

return Refinement
