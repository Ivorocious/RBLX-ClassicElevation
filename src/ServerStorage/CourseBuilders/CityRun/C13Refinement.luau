--!strict
local Patch = {}

function Patch.Apply(imported: Model)
	assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
	local course = workspace.Course_CityRun
	assert(course:GetAttribute("ReviewBuildId")=="C13_01" and course:GetAttribute("C12CheckpointMigration"))
	local manifest=script.Parent.C13Manifest:Clone()
	local data=require(manifest) manifest:Destroy()
	assert(data.revision=="C13_02")
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

    local archive=game.ServerStorage.CityRun_C13_Archive
    local oldVisuals=Instance.new("Folder") oldVisuals.Name="C13_01_Visuals" oldVisuals.Parent=archive
    course.Decoration.C13Terminal.Parent=oldVisuals
    local moving=course.Obstacles.Moving
    -- These existing Blender skins keep their exact geometry; only terminal masonry is recolored.
    for _, modelName in {"CP07","CP08"} do
        local model=course.Obstacles.WalkingSurfaces:FindFirstChild(modelName)
        if model then
            for _, part in model:GetChildren() do
                if part:IsA("MeshPart") and not part.CanCollide and (string.find(part.Name,"__Brick__",1,true) or string.find(part.Name,"__Plaster__",1,true)) then
                    local copy=part:Clone();part.Parent=oldVisuals;copy.Parent=model
                    copy.Color=Color3.fromRGB(201,196,168);copy.Material=Enum.Material.SmoothPlastic
                end
            end
        end
    end
	local scenery=Instance.new("Folder") scenery.Name,scenery.Parent="C13Terminal",course.Decoration
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
		if part:IsA("MeshPart") then part.TextureID=""; part.DoubleSided=mesh.material=="TerminalGlass" or data.components[mesh.component].section=="Lettering" end
		part:SetAttribute("SourceTriangles",mesh.triangles)
		part.Parent=groups[mesh.component] or oldVisuals
	end
	for name,model in groups do
		local pivot=data.components[name].pivot
		model.WorldPivot=if pivot then CFrame.new(pivot[1],pivot[2],pivot[3]) else model:GetBoundingBox()
	end
	imported.Parent=archive
    course:SetAttribute("ReviewBuildId","C13_02") course:SetAttribute("CityRunRevision","C13")
    course:SetAttribute("VisualReviewPassed",false)
    for _, key in {"GroundingScore","ReadabilityScore","VariationScore","CompositionScore","RewardScore"} do course:SetAttribute(key,nil) end
	return {build="C13_02",newMeshes=count-4,descendants=#course:GetDescendants()}
end
return Patch
