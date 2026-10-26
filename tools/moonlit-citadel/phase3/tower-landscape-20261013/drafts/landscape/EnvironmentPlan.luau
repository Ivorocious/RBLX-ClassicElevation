--!nonstrict
local Environment = {}
local v = Vector3.new
local BaseY = -30
local AssetCosts = {MC_P3_Rework_GroundPlinth = {1, 28}, MC_P3_Rework_RockCluster = {1, 156},
	MC_P3_Rework_FernCluster = {2, 934}, MC_P3_Cypress = {3, 320}, MC_PierStone = {2, 380},
	MC_LanternCage = {2, 1220}, MC_LanternCore = {1, 60}, MC_P3_PlantPocket = {5, 824}}
AssetCosts.MC_P3_Rural_Mound = {3, 494}
AssetCosts.MC_P3_Rural_BroadleafClump = {2, 684}
AssetCosts.MC_P3_Rural_EvergreenGrove = {2, 1044}
AssetCosts.MC_P3_Rural_HeatherFern = {2, 360}
local AssetBounds = {
	MC_P3_Rural_Mound = {v(0, -4, 0), v(64, 20, 52)},
	MC_P3_Rural_BroadleafClump = {v(-.5, 14, 1.024758), v(32.548702, 32, 25.158234)},
	MC_P3_Rural_EvergreenGrove = {v(.15, 16, 1), v(30.300001, 36, 27.412678)},
	MC_P3_Rural_HeatherFern = {v(0, 1.275, .75), v(18, 3.05, 10.5)},
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
	local plan, lamps, names, meshes, triangles = {}, {}, {}, 0, 0
	local proposalRows = {}
	local reserves, omissions, plantedMounts, mounds, groves = {}, {}, {}, {}, {}
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
	local function bounds(asset, cf, scale)
		local meta = assert(AssetBounds[asset], "Measured rural asset bounds missing")
		local center, half = cf:PointToWorldSpace(meta[1] * scale), meta[2] * scale / 2
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		return center, v(math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
			math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
			math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z)
	end
	local function clash(asset, cf, scale)
		local center, half = bounds(asset, cf, scale)
		for _, reserve in reserves do
			local delta = center - reserve.center
			if math.abs(delta.X) < half.X + reserve.half.X and math.abs(delta.Y) < half.Y + reserve.half.Y
				and math.abs(delta.Z) < half.Z + reserve.half.Z then return reserve.name end
		end
		return nil
	end
	local function add(district, name, asset, cf, scale, color, material)
		assert(not names[name], "Duplicate countryside art " .. name)
		names[name] = true
		scale = scale or Vector3.one
		assert(not clash(asset, cf, scale), "Countryside art enters accepted route space: " .. name)
		local cost = assert(AssetCosts[asset]); meshes += cost[1]; triangles += cost[2]
		table.insert(plan, {district = district, name = name, asset = asset, localCF = cf, scale = scale,
			library = if string.find(asset, "MC_P3_Rural_", 1, true) == 1 then "TL01"
				elseif string.sub(asset, 1, 6) == "MC_P3_" then "P3" else "BL02",
			color = color, material = material, materialRole = "Countryside"})
		local meta = AssetBounds[asset]
		table.insert(proposalRows, {path = "Landscape/" .. name .. "/FullAsset", frame = {(cf * CFrame.new(meta[1] * scale)):GetComponents()},
			size = {meta[2].X * scale.X, meta[2].Y * scale.Y, meta[2].Z * scale.Z}, anchored = true,
			collide = false, query = false, touch = false, transparency = 0})
	end
	local function mound(name, point, scale, outer)
		local cf = frame(point)
		local center, half = bounds("MC_P3_Rural_Mound", cf, scale)
		local low, high = center - half, center + half
		if outer then
			assert(high.X < -274 or low.X > 244 or high.Z < -224 or low.Z > 224,
				"High countryside hill crosses the actual502x432 fall footprint: " .. name)
		else assert(high.Y <= -29.19, "Inner meadow must remain below reset/court level") end
		add("RollingCountryside", name, "MC_P3_Rural_Mound", cf, scale)
		mounds[name] = {name = name, frame = cf, scale = scale, low = low, high = high, outer = outer}
	end
	mound("CountrysideIslandRoot", v(-15, -37.4, 0), v(11, 1.2, 12.8))
	mound("GateMeadow", v(-144, -36.4, 178), v(1.9, 1.2, 3.0))
	mound("WestValley", v(-210, -37, -18), v(2.8, 1.3, 2.6))
	mound("ArchNorthMeadow", v(-162, -36.4, -111), v(1.45, 1.2, 1.4))
	mound("CloisterMeadow", v(-90, -36.4, 26), v(1.6, 1.2, 1.45))
	mound("GalleryLowMeadow", v(21, -36.4, 116), v(2.8, 1.2, 4.2))
	mound("MachineryLowMeadow", v(174, -37, -65), v(2.8, 1.3, 2.5))
	mound("RearMeadow", v(63, -36.4, -183), v(2.55, 1.2, 2.55))
	mound("KeepApseMeadow", v(-8, -36.4, -40), v(1.65, 1.2, 1.9))
	mound("WestHighHill", v(-321, -12, 37), v(1.4, 3, 2.05), true)
	mound("NorthWestShoulder", v(-293, -14, -154), v(.55, 2.7, 1.2), true)
	mound("SouthGateHill", v(-157, -12, 272), v(1.9, 3, 1.4), true)
	mound("SouthEastHill", v(-4, -12, 274), v(2.1, 3, 1.45), true)
	mound("EastHighHill", v(290, -12, -49), v(1.4, 3, 2.65), true)
	mound("NorthHighHill", v(76, -12, -272), v(2.4, 3, 1.4), true)

	-- Sample the authored20-sided,6-ring grass surface instead of floating roots above a smooth approximation.
	local function triangleHeight(px, pz, a, b, c)
		local denominator = (b.Z - c.Z) * (a.X - c.X) + (c.X - b.X) * (a.Z - c.Z)
		local u = ((b.Z - c.Z) * (px - c.X) + (c.X - b.X) * (pz - c.Z)) / denominator
		local w = ((c.Z - a.Z) * (px - c.X) + (a.X - c.X) * (pz - c.Z)) / denominator
		local t = 1 - u - w
		if u >= -.00001 and w >= -.00001 and t >= -.00001 then return u * a.Y + w * b.Y + t * c.Y end
		return nil
	end
	local function grassPoint(moundName, u, w)
		local record = assert(mounds[moundName])
		local x, z, height = u * 31.2, w * 25.35, nil
		local function point(level, side)
			local radius, theta = level / 6, side * math.pi * 2 / 20
			return v(math.cos(theta) * 31.2 * radius, 6 * (1 - radius * radius) ^ 2, math.sin(theta) * 25.35 * radius)
		end
		for side = 0, 19 do
			height = triangleHeight(x, z, v(0, 6, 0), point(1, side), point(1, side + 1))
			if height then break end
			for level = 1, 5 do
				local a, b, c, d = point(level, side), point(level, side + 1), point(level + 1, side), point(level + 1, side + 1)
				height = triangleHeight(x, z, a, c, d) or triangleHeight(x, z, a, d, b)
				if height then break end
			end
			if height then break end
		end
		assert(height, "Plant root is outside the actual grass cap")
		return record.frame:PointToWorldSpace(v(x * record.scale.X, height * record.scale.Y, z * record.scale.Z))
	end
	for index, data in {
		{"WestHighHill", "MC_P3_Rural_EvergreenGrove", 0, 0, 1.6, 3},
		{"WestHighHill", "MC_P3_Rural_BroadleafClump", 0, -.48, 1.3, 3},
		{"WestHighHill", "MC_P3_Rural_BroadleafClump", 0, .48, 1.45, 3.7},
		{"SouthGateHill", "MC_P3_Rural_BroadleafClump", 0, 0, 1.4, 3},
		{"SouthGateHill", "MC_P3_Rural_EvergreenGrove", .48, 0, 1.2, 4.1},
		{"SouthEastHill", "MC_P3_Rural_BroadleafClump", 0, 0, 1.6, 3},
		{"SouthEastHill", "MC_P3_Rural_BroadleafClump", .48, 0, 1.2, 3},
		{"EastHighHill", "MC_P3_Rural_EvergreenGrove", 0, 0, 1.6, 3},
		{"EastHighHill", "MC_P3_Rural_BroadleafClump", 0, .55, 1.4, 3},
		{"NorthHighHill", "MC_P3_Rural_EvergreenGrove", 0, 0, 1.45, 3},
		{"NorthHighHill", "MC_P3_Rural_BroadleafClump", .55, 0, 1.2, 3},
	} do
		local point = grassPoint(data[1], data[3], data[4]) - v(0, data[6], 0)
		local scale = Vector3.one * data[5]
		local cf = frame(point, index * .71)
		add("RuralGroves", "CountryGrove" .. index, data[2], cf, scale)
		local crowns, trunks
		if data[2] == "MC_P3_Rural_BroadleafClump" then
			crowns = {{v(-8, 16, -3), v(18, 12, 18)}, {v(7, 22, 1), v(18, 16, 20)}, {v(-1, 18, 6), v(16, 14, 16)}}
			trunks = {{v(-8, 7.25, -3), v(1.8, 18.5, 1.7)}, {v(7, 10.25, 1), v(1.8, 24.5, 1.7)}, {v(-1, 8.375, 6), v(1.8, 20.75, 1.7)}}
		else
			crowns = {{v(-9, 14, -7), v(12, 20, 12)}, {v(8, 19, 6), v(14.6, 30, 14.6)}, {v(-5, 16.5, 9), v(12, 25, 12)}}
			trunks = {{v(-9, 10, -7), v(1.6, 24, 1.5)}, {v(8, 15, 6), v(1.6, 34, 1.5)}, {v(-5, 12.5, 9), v(1.6, 29, 1.5)}}
		end
		for kind, records in {Canopy = crowns, Trunk = trunks} do
			for tree, box in records do
				local size = box[2] * scale
				table.insert(proposalRows, {path = "Landscape/CountryGrove" .. index .. "/" .. kind .. tree,
					frame = {(cf * CFrame.new(box[1] * scale)):GetComponents()}, size = {size.X, size.Y, size.Z},
					anchored = true, collide = false, query = false, touch = false, transparency = 0})
			end
		end
		local center, half = bounds(data[2], cf, scale)
		table.insert(groves, {name = "CountryGrove" .. index, mound = data[1], center = center, half = half,
			canopyTop = center.Y + half.Y, trees = 3})
	end
	for index, data in {
		{"GateMeadow", -.48, .18}, {"WestValley", .30, .35}, {"ArchNorthMeadow", -.42, .18},
		{"CloisterMeadow", -.45, .25}, {"GalleryLowMeadow", .35, .42},
		{"MachineryLowMeadow", .30, -.42}, {"KeepApseMeadow", -.42, -.36},
	} do
		local point = grassPoint(data[1], data[2], data[3])
		add("MeadowPlanting", "HeatherFernDrift" .. index, "MC_P3_Rural_HeatherFern", frame(point, index * .89), Vector3.one * 1.05)
	end
	for _, body in architectureBodies or {} do
		local point = (body.frame * CFrame.new(0, 0, -11)).Position
		local sy = 22 / 3.32
		add("GroundFoundations", body.name .. "SeatedBedrock", "MC_P3_Rework_GroundPlinth",
			CFrame.new(point.X, BaseY + .02 - .12 * sy, point.Z) * body.frame.Rotation,
			v((body.width * 48 / 46 + 16) / 32, sy, 44 / 24), Color3.fromRGB(102, 111, 108), "Rock")
	end
	local function lamp(name, point)
		add("OuterLanterns", name .. "CarvedFoot", "MC_PierStone", frame(point), v(.64, 4.5 / 60, .64))
		local center = point + v(0, 5.95, 0)
		add("OuterLanterns", name .. "IronCage", "MC_LanternCage", frame(center), Vector3.one * .42)
		add("OuterLanterns", name .. "AmberCore", "MC_LanternCore", frame(center), Vector3.one * .42)
		table.insert(lamps, {name = name, localPosition = center, brightness = .5, range = 22, shadows = false})
	end
	lamp("GateHeatherGuideLamp", grassPoint("GateMeadow", -.48, .18) + v(7, .02, 0))
	lamp("WestCloisterGuideLamp", grassPoint("WestValley", .30, .35) + v(7, .02, 0))
	lamp("GalleryGardenGuideLamp", grassPoint("GalleryLowMeadow", .35, .42) + v(7, .02, 0))
	lamp("MachineryCourtGuideLamp", grassPoint("MachineryLowMeadow", .30, -.42) + v(7, .02, 0))
	for index, mount in architectureMounts or {} do
		assert(index <= 10 and mount.name and typeof(mount.frame) == "CFrame" and mount.supportName)
		local basinScale, fernScale = Vector3.one * .65, Vector3.one * .8
		local blocked = clash("MC_P3_PlantPocket", mount.frame, basinScale)
			or clash("MC_P3_Rework_FernCluster", mount.frame * CFrame.new(0, .624, 0), fernScale)
		if blocked then table.insert(omissions, {name = mount.name, blocked = blocked}); continue end
		add("RoutePlanting", mount.name .. "CarvedBasin", "MC_P3_PlantPocket", mount.frame, basinScale)
		add("RoutePlanting", mount.name .. "Fern", "MC_P3_Rework_FernCluster", mount.frame * CFrame.new(0, .624, 0), fernScale)
		table.insert(plantedMounts, {name = mount.name, frame = mount.frame, supportName = mount.supportName})
	end
	assert(#lamps == 4 and meshes <= 180 and triangles <= 65000, "Rural environment exceeds its replacement budget")
	return plan, {units = #plan, meshParts = meshes, triangles = triangles, lamps = lamps, maxNewLights = 4,
		groundBaseY = BaseY, highestInnerGrass = -29.2, highestOuterGrass = 6, artCanCollide = false,
		artCanQuery = false, artCanTouch = false, groundedPockets = plantedMounts,
		plantingMountsMissing = architectureMounts == nil or #architectureMounts < 6, omittedPlanting = omissions,
		mounds = mounds, groves = groves, ruralTreeCount = 33, proposalRows = proposalRows,
		clearance = "Inner meadow peaks below original reset; higher hills wholly outside502x432 fall footprint; full canopy bounds reserve course space."}
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
