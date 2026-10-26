--!nonstrict
local WorldPlan = require(script.Parent.WorldPlan)
local Environment = require(script.Parent.EnvironmentPlan)
local MeshKit = require(script.Parent.Parent.MoonlitCitadel.MeshKit)
local Assembly = {}
local LibraryName = "MoonlitCitadel_P3Rework_RW01Library"

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
	end
	model.WorldPivot = frame
	model:SetAttribute("MCEditUnit", data.asset)
	model:SetAttribute("VisualSource", "MC_P3_REWORK_KIT_RW01")
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
	local outer, outerPlanned = Environment.Get(layout)
	for _, data in outer do table.insert(plan, data) end
	planned.units += outerPlanned.units; planned.meshParts += outerPlanned.meshParts; planned.triangles += outerPlanned.triangles
	assert(planned.units <= WorldPlan.Limits.units and planned.meshParts <= WorldPlan.Limits.meshParts and planned.triangles <= WorldPlan.Limits.triangles)
	local world = Instance.new("Folder")
	world.Name = "Phase3World"
	world.Parent = assert(course:FindFirstChild("Decoration"), "Course Decoration is missing")
	local folders, meshes = {}, 0
	for index, data in plan do
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
				if data.asset == "MC_WindowGlass" or data.asset == "MC_LanternCore" or data.asset == "MC_TurretAmber" then part.Material = Enum.Material.Neon; part.CastShadow = false end
				assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch, "World art changed gameplay contact")
			end
		end
		if index % 24 == 0 then task.wait() end
	end
	assert(meshes == planned.meshParts and meshes <= WorldPlan.Limits.meshParts, "Actual world import part count differs from manifest")
	world:SetAttribute("PlanUnits", planned.units)
	world:SetAttribute("MeshParts", meshes)
	world:SetAttribute("PlacedTriangles", planned.triangles)
	local lights = {
		{"MoonlitWarmGate", "Gate", "GateCourt", .65, 24},
		{"MoonlitWarmCP01", "SharedArches", "CP01Terrace", .70, 24},
		{"MoonlitWarmCP02", "Gallery", "CP02Terrace", .75, 26},
		{"MoonlitWarmCP03", "Lifts", "CP03Terrace", .70, 24},
		{"MoonlitWarmCP04", "Lifts", "CP04Terrace", .75, 24},
		{"MoonlitWarmCrown", "Crown", "CrownTerrace", .85, 26},
	}
	for _, data in lights do
		local contact = course.Obstacles[data[2]][data[3]].Contact
		assert(contact:IsA("BasePart") and contact:GetAttribute("MCWalkable") == true)
		assert(not contact:FindFirstChild(data[1]), "World light already exists")
		local light = Instance.new("PointLight")
		light.Name, light.Color = data[1], Color3.fromRGB(255, 188, 75)
		light.Brightness, light.Range, light.Shadows = data[4], data[5], false
		light.Enabled = true
		light:SetAttribute("MoonlitWorldLight", true)
		light.Parent = contact
	end
	for _, data in outerPlanned.lamps do
		local core = assert(world.OuterLanterns:FindFirstChild(data.name .. "AmberCore"))
		local source = assert(core:FindFirstChildWhichIsA("BasePart", true))
		local light = Instance.new("PointLight")
		light.Name, light.Color = data.name, Color3.fromRGB(255, 188, 75)
		light.Brightness, light.Range, light.Shadows, light.Enabled = data.brightness, data.range, false, true
		light:SetAttribute("MoonlitWorldLight", true)
		light.Parent = source
	end
	world:SetAttribute("NewLights", #lights + #outerPlanned.lamps)
	world:SetAttribute("OuterUnits", outerPlanned.units)
	world:SetAttribute("TerrainBaseY", outerPlanned.groundBaseY)
	world:SetAttribute("GroundBaseY", WorldPlan.BaseY)
	world.Parent = assert(course:FindFirstChild("Decoration"), "Course Decoration is missing")
	course:SetAttribute("Phase3WorldApplied", true)
	return world, planned
end

return Assembly
