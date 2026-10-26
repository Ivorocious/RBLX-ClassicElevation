--!strict
local Patch = {}

function Patch.Apply(imported: Model)
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
	local course = workspace.Course_CityRun
	assert(course:GetAttribute("ReviewBuildId")=="C12_01" and course:GetAttribute("C12CheckpointMigration"))
	local manifest=script.Parent.C12Manifest:Clone()
	local data=require(manifest) manifest:Destroy()
	assert(data.revision=="C12_02")
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

	local archive=game.ServerStorage.CityRun_C12_Archive
	assert(not archive:FindFirstChild("C12_01_Visuals"))
	local oldVisuals=Instance.new("Folder") oldVisuals.Name,oldVisuals.Parent="C12_01_Visuals",archive
	local moving=course.Obstacles.Moving
	for i=0,2 do moving["ActiveTrain"..i].Parent=oldVisuals end
	course.Decoration.C12Terminal.Parent=oldVisuals
	local scenery=Instance.new("Folder") scenery.Name,scenery.Parent="C12Terminal",course.Decoration
	local groups={}
	for name,definition in data.components do
		if definition.section=="Calibration" then continue end
		local model=Instance.new("Model") model.Name=name
		model.Parent=if definition.section=="Moving" then moving else scenery
		model:SetAttribute("EditableUnit",true) model:SetAttribute("Section",definition.section)
		groups[name]=model
	end
	for _,part in imported:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		local mesh=data.meshes[part.Name] local color=data.colors[mesh.material]
		part.CFrame=CFrame.new(3500,0,0)*frame:ToObjectSpace(part.CFrame)
		part.Color=Color3.new(color[1],color[2],color[3])
		part.Material=if mesh.material=="Light" or mesh.material=="Red" then Enum.Material.Neon
			elseif mesh.material=="Iron" or mesh.material=="Rail" or mesh.material=="Copper" or mesh.material=="CopperLight" or mesh.material=="Gold" then Enum.Material.Metal
			else Enum.Material.SmoothPlastic
		part.Anchored,part.CanCollide,part.CanTouch,part.CanQuery=true,false,false,true
		if part:IsA("MeshPart") then part.TextureID=""; part.DoubleSided=mesh.material=="TerminalGlass" end
		part:SetAttribute("SourceTriangles",mesh.triangles)
		part.Parent=groups[mesh.component] or oldVisuals
	end
	for name,model in groups do
		local pivot=data.components[name].pivot
		model.WorldPivot=if pivot then CFrame.new(pivot[1],pivot[2],pivot[3]) else model:GetBoundingBox()
	end
	imported.Parent=archive
	local arrow=course.RouteMarkers.C10Directions.RouteArrow_FinalApproach
	arrow:Clone().Parent=oldVisuals
	arrow:PivotTo(arrow:GetPivot()*CFrame.Angles(0,math.pi,0))
	course:SetAttribute("ReviewBuildId","C12_02") course:SetAttribute("CityRunRevision","C12")
	course:SetAttribute("VisualReviewPassed",false)
	for _,key in {"GroundingScore","ReadabilityScore","VariationScore","CompositionScore"} do course:SetAttribute(key,nil) end
	return {build="C12_02",newMeshes=count-4,descendants=#course:GetDescendants()}
end
return Patch
