--!nonstrict
local WorldPlan = require(script.Parent.WorldPlan)
local MeshKit = require(script.Parent.Parent.MoonlitCitadel.MeshKit)
local Assembly = {}
local LibraryName = "MoonlitCitadel_P3World_C01Library"

local function p3Place(parent, data, frame, library)
	local template = library:FindFirstChild(data.asset)
	assert(template and template:IsA("Model"), "Missing verified P3 edit unit: " .. data.asset)
	local model = template:Clone()
	model.Name = data.name
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		local localFrame = part.CFrame
		part.Size *= data.scale
		part.CFrame = frame * CFrame.new(localFrame.Position * data.scale) * localFrame.Rotation
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
		part.CastShadow = true
	end
	model.WorldPivot = frame
	model:SetAttribute("MCEditUnit", data.asset)
	model:SetAttribute("VisualSource", "MC_P3_WORLD_KIT_C01")
	model.Parent = parent
	return model
end

function Assembly.Apply(course, layout)
	assert(course and course:IsA("Model") and layout, "Provide the authored course and final layout")
	assert(not course:FindFirstChild("Phase3World", true), "Preserve the existing world; build a new candidate before replacing it")
	local origin = course:GetAttribute("Origin")
	assert(typeof(origin) == "Vector3", "Course Origin is missing")
	local library = game.ServerStorage.CourseAssetKits:FindFirstChild(LibraryName)
	assert(library and library:GetAttribute("ImportVerified") == true, "Verify the new P3 world library before assembly")
	local plan, planned = WorldPlan.Get(layout)
	local world = Instance.new("Folder")
	world.Name = "Phase3World"
	local folders, meshes = {}, 0
	for _, data in plan do
		local parent = folders[data.district]
		if not parent then
			parent = Instance.new("Folder")
			parent.Name, parent.Parent = data.district, world
			folders[data.district] = parent
		end
		local placementFrame = CFrame.new(origin) * data.localCF
		local model = if data.library == "P3" then p3Place(parent, data, placementFrame, library)
			else MeshKit.Place(parent, data.name, data.asset, placementFrame, data.scale)
		model:SetAttribute("District", data.district)
		model:SetAttribute("CourseLocalFrame", data.localCF)
		model:SetAttribute("AuthorScale", data.scale)
		if data.supportPath then model:SetAttribute("SupportedContact", data.supportPath) end
		for _, part in model:GetDescendants() do
			if part:IsA("MeshPart") then meshes += 1 end
			if part:IsA("BasePart") then
				assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch, "World art changed gameplay contact")
			end
		end
	end
	assert(meshes == planned.meshParts and meshes <= WorldPlan.Limits.meshParts, "Actual world import part count differs from manifest")
	world:SetAttribute("PlanUnits", planned.units)
	world:SetAttribute("MeshParts", meshes)
	world:SetAttribute("PlacedTriangles", planned.triangles)
	world:SetAttribute("NewLights", 0)
	world:SetAttribute("GroundBaseY", WorldPlan.BaseY)
	world.Parent = assert(course:FindFirstChild("Decoration"), "Course Decoration is missing")
	course:SetAttribute("Phase3WorldApplied", true)
	return world, planned
end

return Assembly
