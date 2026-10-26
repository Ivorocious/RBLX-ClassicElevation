--!nonstrict
local Environment = {}
local v = Vector3.new
local BaseY = -30
local AssetCosts = {MC_P3_Rework_GroundPlinth = {1, 28}, MC_P3_Rework_RockCluster = {1, 156},
	MC_P3_Rework_FernCluster = {2, 934}, MC_P3_Cypress = {3, 320}, MC_PierStone = {2, 380},
	MC_LanternCage = {2, 1220}, MC_LanternCore = {1, 60}, MC_P3_PlantPocket = {5, 824}}
local AssetBounds = {
	MC_P3_Rework_GroundPlinth = {v(0, -1.54, 0), v(32, 3.32, 24)},
	MC_P3_Rework_RockCluster = {v(-.225857, 1.4, -.567572), v(8.848619, 2.8, 5.238718)},
	MC_P3_Rework_FernCluster = {v(0, .88, 0), v(2.658286, 1.76, 2.658286)},
	MC_LanternCage = {v(0, 0, 0), v(4, 6, 4)},
	MC_LanternCore = {v(0, 0, 0), v(2, 3, 2)},
	MC_P3_PlantPocket = {v(0, 1.55, 0), v(8, 3.1, 5.01)},
	MC_P3_Cypress = {v(0, 6.84, -.11), v(4.62, 13.68, 4.62)},
	MC_PierStone = {v(0, 30, 0), v(5.2, 60, 5.8)},
}
local Colors = {Shared = Color3.fromRGB(246, 240, 214), Normal = Color3.fromRGB(242, 225, 155),
	Expert = Color3.fromRGB(205, 167, 244), Return = Color3.fromRGB(224, 225, 231)}

Environment.Profile = table.freeze({
	CourseId = "moonlit_citadel", ActivationDistance = 750, UseCourseBounds = true,
	HideWorkspaceRoots = {"MoonlitCitadelPhase1_C01", "MoonlitCitadelPhase1_BL01", "MoonlitCitadelPhase1_BL02"}, RequiredCourseAttribute = "MoonlitNightAmbience",
	Lighting = {ClockTime = 19.2, GeographicLatitude = 20, Brightness = 2.2, ExposureCompensation = .65,
		GlobalShadows = true, ShadowSoftness = .3, EnvironmentDiffuseScale = .85, EnvironmentSpecularScale = .4,
		Ambient = Color3.fromRGB(145, 153, 171), OutdoorAmbient = Color3.fromRGB(132, 146, 169)},
	ColorCorrection = {Brightness = .035, Contrast = .015, Saturation = -.045, TintColor = Color3.fromRGB(232, 240, 255)},
		Atmosphere = {Density = .025, Offset = .10, Haze = .55, Glare = 0,
		Color = Color3.fromRGB(107, 123, 148), Decay = Color3.fromRGB(65, 78, 101)},
	Sky = {SkyboxBk = "rbxassetid://119591637361429", SkyboxDn = "rbxassetid://81233894808962",
		SkyboxFt = "rbxassetid://136920684348219", SkyboxLf = "rbxassetid://99622089516191",
		SkyboxRt = "rbxassetid://95853984087799", SkyboxUp = "rbxassetid://126102685877031",
		CelestialBodiesShown = true, StarCount = 1000, SunAngularSize = 0, MoonAngularSize = 11,
		MoonTextureId = "rbxasset://sky/moon.jpg"},
	Effects = {BloomEffect = {Enabled = true, Intensity = .10, Size = 20, Threshold = 1.4}, SunRaysEffect = {Enabled = false}},
})

local function frame(point, yaw)
	return CFrame.new(point) * CFrame.Angles(0, yaw or 0, 0)
end

local function extents(layout, prefixes)
	local low, high = v(math.huge, math.huge, math.huge), v(-math.huge, -math.huge, -math.huge)
	for _, data in layout.Surfaces do
		local selected = prefixes == nil
		for _, prefix in prefixes or {} do
			if string.sub(data.group, 1, #prefix) == prefix then selected = true; break end
		end
		if not selected then continue end
		local cf, half = data.frame or CFrame.new(data.position), data.size / 2
		local r, l = cf.RightVector, cf.LookVector
		local radius = v(math.abs(r.X) * half.X + math.abs(l.X) * half.Z, half.Y,
			math.abs(r.Z) * half.X + math.abs(l.Z) * half.Z)
		low = v(math.min(low.X, data.position.X - radius.X), math.min(low.Y, data.position.Y - radius.Y), math.min(low.Z, data.position.Z - radius.Z))
		high = v(math.max(high.X, data.position.X + radius.X), math.max(high.Y, data.position.Y + radius.Y), math.max(high.Z, data.position.Z + radius.Z))
	end
	assert(low.X < math.huge, "Environment district needs final contacts")
	return low, high
end

function Environment.Get(layout, architectureMounts, architectureBodies)
	local plan, lamps, meshes, triangles, names = {}, {}, 0, 0, {}
	local reserves, omitted, plantedMounts = {}, {}, {}
	local rockColors = {Color3.fromRGB(102, 108, 117), Color3.fromRGB(83, 94, 108), Color3.fromRGB(116, 122, 128)}
	for _, data in layout.Surfaces do
		local cf, half = data.frame or CFrame.new(data.position), data.size / 2
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local radius = v(math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
			math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
			math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z)
		table.insert(reserves, {name = data.group .. "/" .. data.name,
			center = (cf * CFrame.new(0, -data.size.Y / 2, 0)).Position + v(0, 4.55, 0), half = radius + v(2.5, 4.85, 2.5)})
	end
	for _, lantern in layout.Lanterns or {} do
		local length = (lantern.pivot - lantern.point).Magnitude
		table.insert(reserves, {name = lantern.name, center = lantern.pivot - v(0, length * .5, 0),
			half = v(length * .55 + 5, length * .5 + 5, length * .55 + 5)})
	end
	for stage, origin in layout.LiftOrigins or {} do
		table.insert(reserves, {name = stage, center = origin + v(0, 17, 0), half = v(28, 23, 10)})
	end
	local function clash(asset, cf, scale)
		local meta = assert(AssetBounds[asset], "Measured environment bounds missing: " .. asset)
		local center, half = cf:PointToWorldSpace(meta[1] * scale), meta[2] * scale / 2
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		half = v(math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
			math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
			math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z)
		for _, reserve in reserves do
			local delta = center - reserve.center
			if math.abs(delta.X) < half.X + reserve.half.X and math.abs(delta.Y) < half.Y + reserve.half.Y
				and math.abs(delta.Z) < half.Z + reserve.half.Z then return reserve.name end
		end
		return nil
	end
	local function add(district, name, asset, cf, scale, color, material)
		assert(not names[name], "Duplicate environment name " .. name)
		names[name] = true
		scale = scale or Vector3.one
		local blocked = clash(asset, cf, scale)
		assert(not blocked, "Environment art touches protected space: " .. name .. " / " .. tostring(blocked))
		local cost = assert(AssetCosts[asset]); meshes += cost[1]; triangles += cost[2]
		table.insert(plan, {district = district, name = name, asset = asset, localCF = cf, scale = scale,
			library = if string.sub(asset, 1, 6) == "MC_P3_" then "P3" else "BL02",
			color = color, material = material, contrastGroup = if color then "RockFoundation" else nil})
	end
	local function terrain(name, point, size, top, yaw, shade)
		local sy = size.Y / 3.32
		add("GroundFoundations", name, "MC_P3_Rework_GroundPlinth", frame(v(point.X, top - .12 * sy, point.Z), yaw),
			v(size.X / 32, sy, size.Z / 24), rockColors[shade or 1], "Rock")
	end
	-- Structural ground remains below the original sky-fall trigger.
	for index, data in {
		{v(-178, 0, -24), v(110, 22, 206), 0}, {v(-144, 0, 136), v(98, 20, 86), -.04},
		{v(-8, 0, -30), v(100, 28, 82), .03}, {v(6, 0, 78), v(222, 22, 64), -.025},
		{v(150, 0, -52), v(112, 30, 240), .035}, {v(-140, 0, -122), v(72, 24, 72), .035},
		{v(-226, 0, -90), v(64, 22, 114), -.02}, {v(-82, 0, 16), v(76, 24, 76), -.035},
		{v(75, 0, -28), v(80, 28, 92), .04}, {v(76, 0, -158), v(108, 26, 60), -.025},
	} do terrain("CitadelRockBody" .. index, data[1], data[2], BaseY, data[3], index % 3 + 1) end
	for index, data in {
		{v(-184, 0, 46), v(118, 12, 156)}, {v(-144, 0, 141), v(108, 12, 91)},
		{v(-8, 0, -31), v(110, 14, 92)}, {v(8, 0, 81), v(228, 12, 74)},
		{v(151, 0, -55), v(126, 16, 252)}, {v(70, 0, -156), v(118, 14, 74)},
	} do terrain("LowerBedrockShelf" .. index, data[1], data[2], BaseY - 14 - index % 3, .04 * (index % 3 - 1), 2) end
	local skirts = {v(-240, 0, -134), v(-241, 0, -86), v(-239, 0, -36), v(-231, 0, 15), v(-228, 0, 68),
		v(-189, 0, 141), v(-158, 0, 176), v(-112, 0, 175), v(-77, 0, 108), v(-27, 0, 112),
		v(24, 0, 111), v(73, 0, 110), v(123, 0, 82), v(197, 0, 54), v(202, 0, 0),
		v(201, 0, -54), v(196, 0, -108), v(194, 0, -161), v(155, 0, -183), v(110, 0, -187),
		v(62, 0, -186), v(18, 0, -169), v(-122, 0, -154), v(-185, 0, -149)}
	for index, point in skirts do
		local sx = if index % 3 == 0 then 3.8 else 3.1
		add("RockEscarpment", "FracturedRockSkirt" .. index, "MC_P3_Rework_RockCluster",
			frame(point + v(0, BaseY - 20 - index % 3, 0), index * .61), v(sx, 5.4, sx * .88), rockColors[2], "Rock")
	end
	for _, body in architectureBodies or {} do
		local point = (body.frame * CFrame.new(0, 0, -11)).Position
		local sy = 22 / 3.32
		local cf = CFrame.new(point.X, BaseY + .02 - .12 * sy, point.Z) * body.frame.Rotation
		add("GroundFoundations", body.name .. "SeatedBedrock", "MC_P3_Rework_GroundPlinth", cf,
			v((body.width * 48 / 46 + 16) / 32, sy, 44 / 24), rockColors[2], "Rock")
	end
	local function lamp(name, point)
		add("OuterLanterns", name .. "CarvedFoot", "MC_PierStone", frame(point), v(.64, 4.5 / 60, .64))
		local center = point + v(0, 5.95, 0)
		add("OuterLanterns", name .. "IronCage", "MC_LanternCage", frame(center), Vector3.one * .42)
		add("OuterLanterns", name .. "AmberCore", "MC_LanternCore", frame(center), Vector3.one * .42)
		table.insert(lamps, {name = name, localPosition = center, brightness = .5, range = 22, shadows = false})
	end
	local gardens = {
		{name = "GateHeather", point = v(-168, BaseY, 163), lamp = true, tree = true},
		{name = "WestCloister", point = v(-214, BaseY, 32), lamp = true, tree = true},
		{name = "GalleryGarden", point = v(19, BaseY, 91), lamp = true},
		{name = "MachineryCourt", point = v(186, BaseY, -94), lamp = true, tree = true},
		{name = "KeepRockGarden", point = v(-37, BaseY, -54)},
	}
	for index, data in gardens do
		add("GroupedPlanting", data.name .. "WeatheredKnoll", "MC_P3_Rework_RockCluster", frame(data.point - v(0, .2, 0), index * .79),
			v(2.4, .95, 2.1), rockColors[3], "Rock")
		for patch, offset in {v(-7, .02, -2), v(1, .02, 5), v(6, .02, -3)} do
			add("GroupedPlanting", data.name .. "Fern" .. patch, "MC_P3_Rework_FernCluster",
				frame(data.point + offset, index + patch * .9), Vector3.one * (if patch == 2 then 1.25 else 1.05))
		end
		if data.tree then add("GroupedPlanting", data.name .. "Cypress", "MC_P3_Cypress", frame(data.point + v(-5, .02, 4)), Vector3.one * 1.05) end
		if data.lamp then lamp(data.name .. "GuideLamp", data.point + v(7, .02, 0)) end
	end
	for index, mount in architectureMounts or {} do
		assert(index <= 10 and mount.name and typeof(mount.frame) == "CFrame" and mount.supportName,
			"Provide a measured joined-architecture planting ledge")
		local basinScale, fernScale = Vector3.one * .65, Vector3.one * .8
		local blocked = clash("MC_P3_PlantPocket", mount.frame, basinScale)
			or clash("MC_P3_Rework_FernCluster", mount.frame * CFrame.new(0, .624, 0), fernScale)
		if blocked then
			table.insert(omitted, {name = mount.name, blocked = blocked, supportName = mount.supportName})
			continue
		end
		add("RoutePlanting", mount.name .. "CarvedBasin", "MC_P3_PlantPocket", mount.frame, basinScale)
		add("RoutePlanting", mount.name .. "Fern", "MC_P3_Rework_FernCluster", mount.frame * CFrame.new(0, .624, 0), fernScale)
		table.insert(plantedMounts, {name = mount.name, frame = mount.frame, supportName = mount.supportName})
	end
	assert(#lamps == 4 and meshes <= 180 and triangles <= 65000, "Environment exceeds its restrained art budget")
	return plan, {units = #plan, meshParts = meshes, triangles = triangles, lamps = lamps, maxNewLights = 4,
		groundBaseY = BaseY, highestRockTop = BaseY + 2.46, lowestRockBase = BaseY - 32,
		artCanCollide = false, artCanQuery = false, artCanTouch = false, groundedPockets = plantedMounts,
		plantingMountsMissing = architectureMounts == nil or #architectureMounts < 6, omittedPlanting = omitted,
		clearance = "All foundations/rocks sit below the original fall height; plants reserve fixed-contact, pendulum and lift space.",
		palette = {Leaf = Color3.fromRGB(71, 100, 81), Flower = Color3.fromRGB(148, 143, 174)}}
end

local function placeTemplate(folder, library, asset, name, cf, scale)
	local source = assert(library:FindFirstChild(asset), "Import verified new art " .. asset)
	local model = source:Clone()
	assert(model:IsA("Model"), "Art library requires an asset Model")
	model.Name = name
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		local localFrame = part.CFrame
		part.Size *= scale
		part.CFrame = cf * CFrame.new(localFrame.Position * scale) * localFrame.Rotation
		part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
		part.CastShadow = false
	end
	model.WorldPivot, model.Parent = cf, folder
	return model
end

function Environment.PlaceSolidArrow(folder, library, name, contact, point, target, mode)
 assert(library:GetAttribute("ReworkImportVerified") == true, "Verify RW01 upload/geometry before wayfinding")
 local up = contact.CFrame.UpVector
 local localPoint = contact.CFrame:PointToObjectSpace(point)
 local halfX, halfZ = contact.Size.X / 2 - .16, contact.Size.Z / 2 - .16
 local direction, cf, s
 for _ = 1, 8 do
  point = contact.CFrame:PointToWorldSpace(localPoint)
  direction = target - point
  direction -= up * direction:Dot(up)
  assert(direction.Magnitude > .1, "Arrow needs a real onward landing")
  direction = direction.Unit
  cf = CFrame.fromMatrix(point + up * .025, -direction:Cross(up).Unit, up, direction)
  local right = contact.CFrame:VectorToObjectSpace(cf.RightVector)
  local forward = contact.CFrame:VectorToObjectSpace(cf.LookVector)
  local rx = math.abs(right.X) * 2.1 + math.abs(forward.X) * 2.7
  local rz = math.abs(right.Z) * 2.1 + math.abs(forward.Z) * 2.7
  s = math.min(1.3, halfX / math.max(.01, rx), halfZ / math.max(.01, rz))
  assert(s >= .24, "Arrow requires a supported floor")
  local travelX, travelZ = math.max(0, halfX - rx * s), math.max(0, halfZ - rz * s)
  localPoint = Vector3.new(math.clamp(localPoint.X, -travelX, travelX), localPoint.Y,
   math.clamp(localPoint.Z, -travelZ, travelZ))
 end
 point = contact.CFrame:PointToWorldSpace(localPoint)
 direction = target - point
 direction -= up * direction:Dot(up)
 direction = direction.Unit
 cf = CFrame.fromMatrix(point + up * .025, -direction:Cross(up).Unit, up, direction)
 local scale = Vector3.one * s
 local mount = placeTemplate(folder, library, "MC_P3_Rework_ArrowMount", name .. "Mount", cf, scale)
 local arrow = placeTemplate(folder, library, "MC_P3_Rework_SolidArrow", name, cf + up * (.17 * s), scale)
 local arrowColors = {
  Shared = Color3.fromRGB(255, 246, 214),
  Normal = Color3.fromRGB(255, 226, 128),
  Expert = Color3.fromRGB(213, 162, 255),
  Return = Color3.fromRGB(179, 221, 255),
 }
 local count = 0
 for _, part in mount:GetDescendants() do
  if part:IsA("BasePart") then part.Color = Color3.fromRGB(12, 17, 27) end
 end
 for _, part in arrow:GetDescendants() do
  if not part:IsA("BasePart") then continue end
  count += 1
  part.Color, part.Material = assert(arrowColors[mode], "Unknown route mode"), Enum.Material.Neon
  part:SetAttribute("GuidanceKind", "SolidMeshArrow")
  part:SetAttribute("SourceContact", contact:GetFullName())
  part:SetAttribute("ArrowForward", direction)
  part:SetAttribute("ArrowTarget", target)
 end
 assert(count == 1, "A route arrow must be a single solid mesh")
 for _, model in {mount, arrow} do
  model:SetAttribute("ArrowId", name)
  model:SetAttribute("RouteMode", mode)
  model:SetAttribute("SourceContact", contact:GetFullName())
  model:SetAttribute("ArrowStyleVersion", 2)
 end
 return arrow, mount
end

return Environment
