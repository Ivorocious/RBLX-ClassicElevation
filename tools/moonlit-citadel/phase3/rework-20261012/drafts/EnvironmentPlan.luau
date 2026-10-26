--!nonstrict
local Environment = {}
local v = Vector3.new
local BaseY = -30
local AssetCosts = {MC_P3_Rework_GroundPlinth = {1, 28}, MC_P3_Rework_RockCluster = {1, 156},
	MC_P3_Rework_FernCluster = {2, 934}, MC_P3_Cypress = {3, 320}, MC_PierStone = {2, 380},
	MC_LanternCage = {2, 1220}, MC_LanternCore = {1, 60}}
local Colors = {Shared = Color3.fromRGB(246, 240, 214), Normal = Color3.fromRGB(242, 225, 155),
	Expert = Color3.fromRGB(205, 167, 244), Return = Color3.fromRGB(224, 225, 231)}

Environment.Profile = table.freeze({
	CourseId = "moonlit_citadel", ActivationDistance = 750, UseCourseBounds = true,
	HideWorkspaceRoots = {"MoonlitCitadelPhase1_BL02"}, RequiredCourseAttribute = "MoonlitNightAmbience",
	Lighting = {ClockTime = .15, GeographicLatitude = 20, Brightness = 2, ExposureCompensation = .15,
		GlobalShadows = true, ShadowSoftness = .3, EnvironmentDiffuseScale = .55, EnvironmentSpecularScale = .3,
		Ambient = Color3.fromRGB(98, 110, 138), OutdoorAmbient = Color3.fromRGB(91, 106, 135)},
	ColorCorrection = {Brightness = .025, Contrast = .06, Saturation = -.06, TintColor = Color3.fromRGB(232, 240, 255)},
	Atmosphere = {Density = .18, Offset = .12, Haze = .55, Glare = 0,
		Color = Color3.fromRGB(153, 179, 216), Decay = Color3.fromRGB(69, 85, 119)},
	Sky = {SkyboxBk = "rbxassetid://95388513621786", SkyboxDn = "rbxassetid://129280327532717",
		SkyboxFt = "rbxassetid://79093202273058", SkyboxLf = "rbxassetid://127522939165486",
		SkyboxRt = "rbxassetid://102282829810148", SkyboxUp = "rbxassetid://89358793225976",
		CelestialBodiesShown = true, StarCount = 0, SunAngularSize = 0, MoonAngularSize = 9},
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

function Environment.Get(layout)
	local plan, lamps, meshes, triangles = {}, {}, 0, 0
	local function add(district, name, asset, point, scale, yaw)
		local cost = assert(AssetCosts[asset]); meshes += cost[1]; triangles += cost[2]
		table.insert(plan, {district = district, name = name, asset = asset, localCF = frame(point, yaw),
			scale = scale or Vector3.one, library = if string.sub(asset, 1, 6) == "MC_P3_" then "P3" else "BL02"})
	end
	local function lamp(name, point)
		add("OuterLanterns", name .. "CarvedFoot", "MC_PierStone", point, v(.52, 4.5 / 60, .52))
		local center = point + v(0, 5.95, 0)
		add("OuterLanterns", name .. "IronCage", "MC_LanternCage", center, Vector3.one * .42)
		add("OuterLanterns", name .. "AmberCore", "MC_LanternCore", center, Vector3.one * .42)
		table.insert(lamps, {name = name, localPosition = center, brightness = .4, range = 18, shadows = false})
	end
	local low, high = extents(layout)
	local center = v((low.X + high.X) / 2, BaseY, (low.Z + high.Z) / 2)
	local width, depth = high.X - low.X + 72, high.Z - low.Z + 72
	add("GroundFoundations", "CitadelGround", "MC_P3_Rework_GroundPlinth", center, v(width / 32, 1, depth / 24))
	add("GroundFoundations", "RaisedKeepGround", "MC_P3_Rework_GroundPlinth",
		v(layout.FinishPoint.X, BaseY + .30, layout.FinishPoint.Z), v(3.15, 1.4, 3.6))
	local pockets = {
		v(low.X - 10, BaseY + .12, low.Z + 28), v(low.X - 9, BaseY + .12, high.Z - 30),
		v(high.X + 10, BaseY + .12, low.Z + 36), v(high.X + 10, BaseY + .12, high.Z - 30),
		v(low.X + 35, BaseY + .12, high.Z + 10), v(high.X - 35, BaseY + .12, high.Z + 10),
		v(low.X + 30, BaseY + .12, low.Z - 10), v(high.X - 30, BaseY + .12, low.Z - 10),
	}
	for index, point in pockets do
		local s = if index % 2 == 0 then .90 else 1.12
		add("OuterPlanting", "OuterRockPocket" .. index, "MC_P3_Rework_RockCluster", point, Vector3.one * s, index * .73)
		add("OuterPlanting", "OuterFernPocket" .. index, "MC_P3_Rework_FernCluster", point + v(-2, 1.2, -1), Vector3.one * 1.1, index * .6)
		if index == 1 or index == 4 or index == 5 or index == 8 then
			add("OuterPlanting", "OuterCypress" .. index, "MC_P3_Cypress", point + v(2, .2, 2), Vector3.one * .85)
			lamp("OuterGuideLamp" .. index, point + v(5, 0, 0))
		end
	end
	assert(#lamps == 4, "Use only four low outer lights in addition to course guidance lights")
	return plan, {units = #plan, meshParts = meshes, triangles = triangles, lamps = lamps, maxNewLights = 4,
		groundBaseY = BaseY, artCanCollide = false, artCanQuery = false, artCanTouch = false,
		clearance = "All terrain/rocks/plants remain below route; top of highest cypress is about-18 studs, first route0."}
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
	local direction = target - point
	direction -= up * direction:Dot(up)
	assert(direction.Magnitude > .1, "Arrow needs a real onward landing")
	direction = direction.Unit
	local cf = CFrame.fromMatrix(point + up * .025, direction:Cross(up).Unit, up, -direction)
	local localPoint = contact.CFrame:PointToObjectSpace(point)
	local right, forward = contact.CFrame:VectorToObjectSpace(cf.RightVector), contact.CFrame:VectorToObjectSpace(cf.LookVector)
	local freeX, freeZ = contact.Size.X / 2 - math.abs(localPoint.X) - .20, contact.Size.Z / 2 - math.abs(localPoint.Z) - .20
	local rx, rz = math.abs(right.X) * 2.1 + math.abs(forward.X) * 2.7,
		math.abs(right.Z) * 2.1 + math.abs(forward.Z) * 2.7
	local s = math.min(1, freeX / math.max(.01, rx), freeZ / math.max(.01, rz))
	assert(s >= .42, "Move marker onto a supported approach instead of squeezing it onto a lip")
	local scale = Vector3.one * s
	local mount = placeTemplate(folder, library, "MC_P3_Rework_ArrowMount", name .. "Mount", cf, scale)
	local arrow = placeTemplate(folder, library, "MC_P3_Rework_SolidArrow", name, cf + up * (.17 * s), scale)
	local count = 0
	for _, part in arrow:GetDescendants() do
		if not part:IsA("BasePart") then continue end
		count += 1
		part.Color, part.Material = assert(Colors[mode], "Unknown route mode"), Enum.Material.SmoothPlastic
		part:SetAttribute("GuidanceKind", "SolidMeshArrow")
		part:SetAttribute("SourceContact", contact:GetFullName())
		part:SetAttribute("ArrowForward", direction)
		part:SetAttribute("ArrowTarget", target)
	end
	assert(count == 1, "A route arrow must be a single solid mesh, never three separated strokes")
	for _, model in {mount, arrow} do model:SetAttribute("ArrowId", name); model:SetAttribute("RouteMode", mode) end
	return arrow, mount
end

return Environment
