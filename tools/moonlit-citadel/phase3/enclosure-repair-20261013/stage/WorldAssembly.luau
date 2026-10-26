--!nonstrict
local WorldPlan = require(script.Parent.WorldPlan)
local Environment = require(script.Parent.EnvironmentPlan)
local MeshKit = require(script.Parent.Parent.MoonlitCitadel.MeshKit)
local Assembly = {}

local Palette = {
	Stone = Color3.fromRGB(155, 164, 175), StoneLight = Color3.fromRGB(193, 196, 195),
	StoneDark = Color3.fromRGB(109, 121, 140), Slate = Color3.fromRGB(63, 80, 109),
	SlateBand = Color3.fromRGB(90, 106, 132), Iron = Color3.fromRGB(72, 83, 102),
	Brass = Color3.fromRGB(174, 140, 83), Lead = Color3.fromRGB(79, 73, 64),
	Leaf = Color3.fromRGB(70, 99, 80), Flower = Color3.fromRGB(148, 143, 174),
	Grass = Color3.fromRGB(91, 129, 64), Earth = Color3.fromRGB(104, 86, 63),
	Rock = Color3.fromRGB(102, 111, 108), Wood = Color3.fromRGB(101, 77, 53),
	Foliage = Color3.fromRGB(70, 117, 67), Needles = Color3.fromRGB(62, 102, 73),
}
local QuietGlass = {Amber = Color3.fromRGB(172, 120, 61), AmberLight = Color3.fromRGB(210, 169, 108),
	AmberPale = Color3.fromRGB(227, 195, 140)}
local FocalGlass = {Amber = Color3.fromRGB(210, 145, 54), AmberLight = Color3.fromRGB(241, 190, 98),
	AmberPale = Color3.fromRGB(255, 223, 157)}

local function appearance(part, data)
	local source = part:GetAttribute("SourceMaterial") or part.Name:match("__(.+)$")
	if data.color then part.Color = data.color
	elseif Palette[source] then part.Color = Palette[source]
	elseif QuietGlass[source] then part.Color = QuietGlass[source] end
	if data.materialRole == "GrandStone" then
		local grand = {Stone = Color3.fromRGB(124,134,149), StoneLight = Color3.fromRGB(185,190,193),
			StoneDark = Color3.fromRGB(80,96,116), Slate = Color3.fromRGB(43,60,86)}
		if grand[source] then part.Color = grand[source] end
	end
	if source == "Rock" or source == "RockA" or source == "RockB" then part.Color, part.Material = Color3.fromRGB(100,112,116), Enum.Material.Rock
    elseif source == "Grass" then part.Color, part.Material = Color3.fromRGB(91,119,75), Enum.Material.Grass
	elseif source == "Earth" then part.Material = Enum.Material.Ground
	elseif source == "Rock" then part.Material = Enum.Material.Rock
	elseif source == "Wood" then part.Material = Enum.Material.Wood
	elseif data.material then part.Material = Enum.Material[data.material]
	elseif source == "Slate" or source == "SlateBand" or source == "Leaf" or source == "Flower" then
		part.Material = Enum.Material.SmoothPlastic
	elseif source == "Iron" or source == "Brass" or source == "Lead" then part.Material = Enum.Material.Metal
	elseif source == "StoneLight" then part.Material = Enum.Material.SmoothPlastic
	elseif source and source:find("Stone", 1, true) then part.Material = Enum.Material.Concrete
	elseif QuietGlass[source] then part.Material = Enum.Material.SmoothPlastic end
	if data.asset == "MC_LanternCore" then
		part.Color, part.Material, part.CastShadow = Color3.fromRGB(244, 179, 85), Enum.Material.Neon, false
	elseif data.asset == "MC_WindowGlass" and data.materialRole == "MainKeepWindow" then
		part.Color, part.Material, part.CastShadow = FocalGlass[source] or Color3.fromRGB(241, 190, 98), Enum.Material.Neon, false
	end
end

local function place(parent, data, frame, library)
	local template = library:FindFirstChild(data.asset)
	assert(template and template:IsA("Model"), "Missing verified world edit unit: " .. data.asset)
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
	model:SetAttribute("VisualSource", if data.library == "ER01" then "MC_P3_ENCLOSURE_REPAIR_ER01" elseif data.library == "TL01" then "MC_P3_TOWER_LANDSCAPE_TL01" elseif data.library == "AR01" then "MC_P3_ART_REPAIR_AR01" else "MC_P3_REWORK_KIT_RW01")
	model.Parent = parent
	return model
end

function Assembly.Apply(course, layout, options)
	assert(course and course:IsA("Model") and layout, "Provide the authored course and final layout")
	assert(not course:FindFirstChild("Phase3World", true), "Preserve the existing world before replacing scenery")
	local origin = course:GetAttribute("Origin")
	assert(typeof(origin) == "Vector3", "Course Origin is missing")
	local kits = game.ServerStorage.CourseAssetKits
	local libraries = {P3 = kits.MoonlitCitadel_P3Rework_RW01Library,
		AR01 = kits.MoonlitCitadel_P3ArtRepair_AR01Library,
		TL01 = kits.MoonlitCitadel_TowerLandscape_TL01Library,
        ER01 = kits.MoonlitCitadel_Enclosure_ER01Library}
	for _, library in libraries do assert(library:GetAttribute("ImportVerified") == true, "Verify world library before assembly") end
	assert(libraries.AR01:GetAttribute("ArtRepairImportVerified") == true)
	assert(libraries.TL01:GetAttribute("TowerLandscapeImportVerified") == true)
    assert(libraries.ER01:GetAttribute("EnclosureImportVerified") == true)
    assert(libraries.ER01:GetAttribute("AxisVerified") == true, "Verify native vertices before assembly")
	local plan, planned = WorldPlan.Get(layout, options)
	local outer, outerPlanned = Environment.Get(layout, planned.plantingMounts, planned.assemblies)
	for _, data in outer do table.insert(plan, data) end
	planned.units += outerPlanned.units
	planned.meshParts += outerPlanned.meshParts
	planned.triangles += outerPlanned.triangles
	assert(planned.units <= WorldPlan.Limits.units and planned.meshParts <= WorldPlan.Limits.meshParts
		and planned.triangles <= WorldPlan.Limits.triangles, "Combined architecture and environment budget exceeded")
	assert((options and options.representative or not outerPlanned.plantingMountsMissing)
		and #outerPlanned.omittedPlanting == 0 and #outerPlanned.groundedPockets == #planned.plantingMounts,
		"Seat the planned planting on actual architecture")
	local world = Instance.new("Folder")
	world.Name, world.Parent = "Phase3World", assert(course:FindFirstChild("Decoration"))
	local folders, meshes = {}, 0
	for index, data in plan do
		local parent = folders[data.district]
		if not parent then parent = Instance.new("Folder"); parent.Name, parent.Parent = data.district, world; folders[data.district] = parent end
		local placementFrame = CFrame.new(origin) * data.localCF
		local model = if libraries[data.library] then place(parent, data, placementFrame, libraries[data.library])
			else MeshKit.Place(parent, data.name, data.asset, placementFrame, data.scale)
		model:SetAttribute("District", data.district)
		model:SetAttribute("CourseLocalFrame", data.localCF)
		model:SetAttribute("AuthorScale", data.scale)
		model:SetAttribute("MaterialRole", data.materialRole or "WorldArt")
		if data.supportPath then model:SetAttribute("SupportedContact", data.supportPath) end
		for _, part in model:GetDescendants() do
			if part:IsA("MeshPart") then meshes += 1 end
			if part:IsA("BasePart") then
				appearance(part, data)
				assert(part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch, "Scenery changed gameplay contact")
			end
		end
		if index % 24 == 0 then task.wait() end
	end
	assert(meshes == planned.meshParts, "Actual world part count differs from its manifest")
	local lights = {
		{"MoonlitWarmGate", "Gate", "GateCourt", .65, 24}, {"MoonlitWarmCP01", "SharedArches", "CP01Terrace", .70, 24},
		{"MoonlitWarmCP02", "Gallery", "CP02Terrace", .75, 26}, {"MoonlitWarmCP03", "Lifts", "CP03Terrace", 1.0, 32},
		{"MoonlitWarmCP04", "Lifts", "CP04Terrace", 1.05, 32}, {"MoonlitWarmCrown", "Crown", "CrownTerrace", .85, 26},
	}
	for _, data in lights do
		local contact = course.Obstacles[data[2]][data[3]].Contact
		local light = contact:FindFirstChild(data[1])
		assert(not light or light:IsA("PointLight") and light:GetAttribute("MoonlitWorldLight") == true, "Preserve original mechanism lights")
		if not light then light = Instance.new("PointLight"); light.Name, light.Parent = data[1], contact end
		light.Color, light.Brightness, light.Range = Color3.fromRGB(255, 188, 75), data[4], data[5]
		light.Shadows, light.Enabled = false, true
		light:SetAttribute("MoonlitWorldLight", true)
	end
	for _, data in outerPlanned.lamps do
		local core = assert(world.OuterLanterns:FindFirstChild(data.name .. "AmberCore"))
		local light = Instance.new("PointLight")
		light.Name, light.Color = data.name, Color3.fromRGB(255, 188, 75)
		light.Brightness, light.Range, light.Shadows, light.Enabled = data.brightness, data.range, false, true
		light:SetAttribute("MoonlitWorldLight", true)
		light.Parent = assert(core:FindFirstChildWhichIsA("BasePart", true))
	end
	world:SetAttribute("PlanUnits", planned.units)
	world:SetAttribute("MeshParts", meshes)
	world:SetAttribute("PlacedTriangles", planned.triangles)
	world:SetAttribute("NewLights", #lights + #outerPlanned.lamps)
	world:SetAttribute("OuterUnits", outerPlanned.units)
	world:SetAttribute("TerrainBaseY", outerPlanned.groundBaseY)
	world:SetAttribute("GroundBaseY", WorldPlan.BaseY)
	world:SetAttribute("ArtRepairCandidate", "ER01")
	course:SetAttribute("Phase3WorldApplied", true)
	return world, planned
end

return Assembly
