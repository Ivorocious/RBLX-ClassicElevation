--!nonstrict
local WorldPlan = {}
local v = Vector3.new
local BaseY = -30
local Limits = {units = 220, meshParts = 560, triangles = 320000}
local Assets = {
	MC_KeepShell = {3, 4488, v(0, 33, -.025), v(66.7, 66, 3.95)},
	MC_WindowFrame = {3, 3852, v(0, 28.99, -.03), v(24, 57.98, 2.74)},
	MC_WindowTracery = {1, 1312, v(0, 28.27, .36), v(18.95, 53.55, .5)},
	MC_WindowGlass = {3, 216, v(0, 28.47, -.17), v(19.25, 53.65, .18)},
	MC_TurretStone = {3, 3212, v(.14, 14, .14), v(7.28, 28, 7.28)},
	MC_TurretAmber = {1, 352, v(0, 19.77, 3.28), v(1.86, 10.49, .06)},
	MC_SlateSpire = {3, 860, v(0, 9, 0), v(8, 18, 8)},
	MC_PierStone = {2, 380, v(0, 30, 0), v(5.2, 60, 5.8)},
	MC_Banner = {2, 712, v(0, -5.01, -.02), v(3.8, 10.77, .46)},
	MC_Ivy = {1, 304, v(0, 5.22, -.02), v(2.44, 10.47, .28)},
	MC_BalustradeStone = {2, 440, v(0, 1.5, 0), v(18, 3, 1.02)},
	MC_BalustradeIron = {2, 1268, v(0, 1.76, 0), v(16.5, 2.38, .23)},
	MC_CrownEmblem = {2, 36, v(0, 2.4, .08), v(6.8, 4.8, .53)},
	MC_P3_GatewayStone = {3, 2852, v(0, 11.5, .3), v(27.4, 23, 5.04)},
	MC_P3_GalleryArcadeStone = {2, 2104, v(0, 9.33, .13), v(24, 18.66, 3.69)},
	MC_P3_VaultRibs = {2, 1276, v(0, 3.79, 0), v(23.36, 7.89, 16.78)},
	MC_P3_FlyingButtress = {2, 1604, v(9.47, 17, 0), v(18.94, 34, 3.88)},
	MC_P3_TerraceFascia = {3, 536, v(0, -3.9, -.31), v(24, 7.8, 2.03)},
	MC_P3_Parapet = {3, 2016, v(0, 1.79, 0), v(24, 3.59, 2)},
	MC_P3_SlateGable = {3, 272, v(0, 4.96, 0), v(24.4, 10.53, 18.3)},
	MC_P3_CrownScreen = {4, 3980, v(0, 6.4, -.1), v(24, 12.79, 1.74)},
	MC_P3_PlantPocket = {5, 824, v(0, 1.55, 0), v(8, 3.1, 5.01)},
	MC_P3_Cypress = {3, 320, v(0, 6.84, -.11), v(4.62, 13.68, 4.62)},
	MC_ExpertCorbel = {1, 44, v(0, -1.85, 0), v(5.8, 1.9, 5)},
	MC_P3_Rework_FoundationPier = {3, 948, v(0, 14, 0), v(7.6, 28, 7.8)},
}

local function frame(point, yaw)
	return CFrame.new(point) * CFrame.Angles(0, yaw or 0, 0)
end

local function bounds(cf, size)
	local half = size / 2
	local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
	return cf.Position, v(math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
		math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
		math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z)
end

local function pathOf(data)
	return "Obstacles/" .. data.group .. "/" .. data.name .. "/Contact"
end

function WorldPlan.Get(layout)
	assert(layout.Surfaces and layout.StartPoint and layout.FinishPoint, "Final layout required")
	local plan, names, surfaces, reserves = {}, {}, {}, {}
	local counts = {units = 0, meshParts = 0, triangles = 0, districts = {}, omittedTrim = {}, relocated = {}, triangleUpperBounds = true}
	for _, data in layout.Surfaces do
		local path = pathOf(data)
		surfaces[path] = data
		local center, half = bounds((data.frame or CFrame.new(data.position)) * CFrame.new(0, -data.size.Y / 2, 0), data.size)
		table.insert(reserves, {path = path, center = center + v(0, 4.55, 0), half = half + v(2.5, 4.85, 2.5)})
	end
	-- Moving platforms and pendulums need swept-space clearance as well as fixed-contact clearance.
	for _, lantern in layout.Lanterns or {} do
		local length = (lantern.pivot - lantern.point).Magnitude
		table.insert(reserves, {path = "MovingLantern/" .. lantern.name,
			center = lantern.pivot - v(0, length * .5, 0), half = v(length * .55 + 5, length * .5 + 5, length * .55 + 5)})
	end
	for stage, origin in layout.LiftOrigins or {} do
		table.insert(reserves, {path = "MovingLift/" .. stage, center = origin + v(0, 17, 0), half = v(28, 23, 10)})
	end
	local function clash(asset, cf, scale, ownPath)
		local meta = Assets[asset]
		local center, half = bounds(cf * CFrame.new(meta[3] * scale), meta[4] * scale)
		for _, reserve in reserves do
			if reserve.path == ownPath and center.Y + half.Y < surfaces[ownPath].position.Y - surfaces[ownPath].size.Y / 2 - .10 then continue end
			local delta = center - reserve.center
			if math.abs(delta.X) < half.X + reserve.half.X and math.abs(delta.Y) < half.Y + reserve.half.Y
				and math.abs(delta.Z) < half.Z + reserve.half.Z then return reserve.path end
		end
		return nil
	end
	local function add(district, name, asset, cf, scale, supportPath, outward)
		scale = scale or Vector3.one
		assert(Assets[asset] and not names[name], "Unknown/duplicate art placement " .. name)
		assert(scale.X > 0 and scale.Y > 0 and scale.Z > 0 and scale.Magnitude < 12, "Invalid art scale")
		local initial = cf
		local blocking = clash(asset, cf, scale, supportPath)
		if blocking and outward then
			for step = 1, 12 do
				cf = initial + outward * step * 2
				blocking = clash(asset, cf, scale, supportPath)
				if not blocking then table.insert(counts.relocated, {name = name, studs = step * 2}); break end
			end
		end
		if blocking and supportPath then
			table.insert(counts.omittedTrim, {name = name, lowerPath = blocking})
			return false
		end
		assert(not blocking, "Reposition world art before installing: " .. name .. " intersects " .. tostring(blocking))
		names[name] = true
		table.insert(plan, {district = district, name = name, asset = asset, localCF = cf, scale = scale,
			library = if string.sub(asset, 1, 6) == "MC_P3_" then "P3" else "BL02", supportPath = supportPath})
		counts.units += 1
		counts.meshParts += Assets[asset][1]
		counts.triangles += Assets[asset][2]
		counts.districts[district] = (counts.districts[district] or 0) + 1
		return true
	end
	local function windows(district, name, cf, scale, outward)
		for _, asset in {"MC_WindowFrame", "MC_WindowTracery", "MC_WindowGlass"} do
			add(district, name .. asset, asset, cf, if typeof(scale) == "Vector3" then scale else Vector3.one * scale, nil, outward)
		end
	end
	local function pier(district, name, point, top, width, supportPath, carved)
		if top <= BaseY + .5 then return end
		local asset = if carved then "MC_P3_Rework_FoundationPier" else "MC_PierStone"
		local nativeHeight = if carved then 28 else 60
		add(district, name, asset, CFrame.new(v(point.X, BaseY, point.Z)), v(width, (top - BaseY) / nativeHeight, width), supportPath)
	end
	local function turret(district, name, point, scale, yaw, outward)
		for _, asset in {"MC_TurretStone", "MC_TurretAmber"} do
			add(district, name .. asset, asset, frame(point, yaw), Vector3.one * scale, nil, outward)
		end
		add(district, name .. "Spire", "MC_SlateSpire", frame(point + v(0, 28 * scale, 0), yaw), Vector3.one * scale, nil, outward)
	end
	local function groupBounds(groups)
		local low, high = v(math.huge, math.huge, math.huge), v(-math.huge, -math.huge, -math.huge)
		local used = 0
		for _, data in layout.Surfaces do
			local selected = false
			for _, prefix in groups do if string.sub(data.group, 1, #prefix) == prefix then selected = true; break end end
			if not selected then continue end
			local center, half = bounds(data.frame or CFrame.new(data.position), data.size)
			low = v(math.min(low.X, center.X - half.X), math.min(low.Y, center.Y - half.Y), math.min(low.Z, center.Z - half.Z))
			high = v(math.max(high.X, center.X + half.X), math.max(high.Y, center.Y + half.Y), math.max(high.Z, center.Z + half.Z))
			used += 1
		end
		assert(used > 0, "World district has no route")
		return low, high
	end
	local function supportedTerrace(data, index)
		local cf, path = data.frame or CFrame.new(data.position), pathOf(data)
		if cf.UpVector.Y < .999 or math.min(data.size.X, data.size.Z) < 10 then return end
		local bottom = data.position.Y - data.size.Y - .18
		local foundationPoints = {}
		for side = -1, 1, 2 do
			local placed = false
			local candidates = {}
			for _, direction in {side, -side} do
				for _, x in {data.size.X * .27, data.size.X * .42, data.size.X / 2 + 6, data.size.X / 2 + 12} do
					for _, z in {0, data.size.Z * .35, -data.size.Z * .35, data.size.Z / 2 + 8, -data.size.Z / 2 - 8} do
						table.insert(candidates, v(direction * x, 0, z))
					end
				end
			end
			for _, offset in candidates do
				local point = cf:PointToWorldSpace(offset)
				if foundationPoints[1] and (point - foundationPoints[1]).Magnitude < 8 then continue end
				local pierCF = CFrame.new(v(point.X, BaseY, point.Z))
				local pierScale = v(.48, (bottom - BaseY) / 28, .48)
				local pierClash = clash("MC_P3_Rework_FoundationPier", pierCF, pierScale, path)
				if pierClash then continue end
				local outside = math.abs(offset.X) > data.size.X / 2 or math.abs(offset.Z) > data.size.Z / 2
				local corbelCF, corbelScale
				if outside then
					local anchor = cf:PointToWorldSpace(v(math.clamp(offset.X, -data.size.X * .35, data.size.X * .35),
						0, math.clamp(offset.Z, -data.size.Z * .35, data.size.Z * .35)))
					local difference = v(point.X - anchor.X, 0, point.Z - anchor.Z)
					corbelCF = CFrame.lookAt(v((point.X + anchor.X) / 2, bottom + .75, (point.Z + anchor.Z) / 2),
						v((point.X + anchor.X) / 2, bottom + .75, (point.Z + anchor.Z) / 2) + difference)
					corbelScale = v(.6, 1, difference.Magnitude / 5 + .35)
					local corbelClash = clash("MC_ExpertCorbel", corbelCF, corbelScale, path)
					if corbelClash then continue end
				end
				add("TerraceFoundations", "ContactFoundation" .. index .. "_" .. side, "MC_P3_Rework_FoundationPier", pierCF, pierScale, path)
				if outside then add("TerraceFoundations", "ContactCorbel" .. index .. "_" .. side, "MC_ExpertCorbel", corbelCF, corbelScale, path) end
				table.insert(foundationPoints, point)
				placed = true
				break
			end
			assert(placed, "Terrace needs a clear grounded support: " .. path)
		end
		for side = -1, 1, 2 do
			add("TerraceFoundations", "ContactFascia" .. index .. "_" .. side, "MC_P3_TerraceFascia",
				cf * CFrame.new(0, -data.size.Y - .18, side * (data.size.Z / 2 - 1.15)), v(data.size.X / 24, .45, .7), path)
		end
	end
	for index, data in layout.Surfaces do
		if data.role == "StartCapacity" or data.role == "FinishCapacity" or data.role == "FixedWaitingArea"
			or data.name == "CP01Terrace" or data.name == "CP02Terrace" or data.name == "CP03Terrace" or data.name == "CP04Terrace"
			or data.name == "Landing_0" or data.name == "Landing_3" or data.name == "Landing_5" then
			supportedTerrace(data, index)
		end
	end

	local start = layout.StartPoint
	local gateBack = start + v(0, 0, 48)
	add("GateCourt", "GateCourtPointedEntry", "MC_P3_GatewayStone", frame(gateBack, math.pi), v(1.15, 1.2, 1.15), nil, v(0, 0, 1))
	for side = -1, 1, 2 do
		local point = gateBack + v(side * 18, 0, 0)
		pier("GateCourt", "GateCourtFoot" .. side, point, 0, .85)
		turret("GateCourt", "GateCourtTower" .. side, point, .62, math.pi, v(0, 0, 1))
		add("GateCourt", "GateCourtHangingBanner" .. side, "MC_Banner", frame(point + v(side * 5, 15, -2), math.pi), Vector3.one)
	end

	-- Each signature gets close art on its outside edge, with different silhouettes.
	local westLow, westHigh = groupBounds({"ArchNormal"})
	local westX = westLow.X - 13
	for bay = 1, 3 do
		local z = westLow.Z + (westHigh.Z - westLow.Z) * (bay - .5) / 3
		local point = v(westX, 24 + (bay - 1) * 6, z)
		add("StoneArchClimb", "WestOpenGothicBay" .. bay, "MC_P3_GalleryArcadeStone", frame(point, math.pi / 2), Vector3.one * 1.2, nil, v(-1, 0, 0))
		for side = -1, 1, 2 do
			pier("StoneArchClimb", "WestGroundFoot" .. bay .. side, point + v(0, 0, side * 13.4), point.Y, .55)
		end
		if bay ~= 2 then
			add("StoneArchClimb", "WestWallMasonry" .. bay, "MC_KeepShell", frame(v(westX - 3, BaseY, z), math.pi / 2), v(.48, 1, .8), nil, v(-1, 0, 0))
			windows("StoneArchClimb", "WestLancet" .. bay, frame(v(westX - 1.4, BaseY + 8, z), math.pi / 2), .62, v(-1, 0, 0))
		end
		add("StoneArchClimb", "WestIvy" .. bay, "MC_Ivy", frame(point + v(1, -5, 13), math.pi / 2), Vector3.one * 1.2, nil, v(-1, 0, 0))
		if bay == 2 then add("StoneArchClimb", "WestMoonBanner", "MC_Banner", frame(point + v(1, 16, -13), math.pi / 2), Vector3.one * 1.2) end
	end
	turret("StoneArchClimb", "WestHighCorner", v(westX - 2, 40, westHigh.Z + 12), .58, math.pi / 2, v(-1, 0, 0))

	local galleryLow, galleryHigh = groupBounds({"GalleryNormal", "Gallery"})
	local hallZ = galleryHigh.Z + 12
	for bay = 1, 3 do
		local x = galleryLow.X + (galleryHigh.X - galleryLow.X) * (bay - .5) / 3
		local point = v(x, BaseY, hallZ)
		add("LanternPendulums", "LanternGroundedMasonry" .. bay, "MC_KeepShell", frame(point, math.pi), v(.6, 1.3, .9), nil, v(0, 0, 1))
		windows("LanternPendulums", "LanternAmberLancet" .. bay, frame(point + v(0, 22, -1.5), math.pi), .55, v(0, 0, 1))
		local floor = 52 + (bay - 1) * 4
		add("LanternPendulums", "LanternOpenBay" .. bay, "MC_P3_GalleryArcadeStone", frame(v(x, floor, hallZ - 1), math.pi), Vector3.one * 1.15, nil, v(0, 0, 1))
		add("LanternPendulums", "LanternSlateCoping" .. bay, "MC_P3_SlateGable", frame(v(x, floor + 23, hallZ + 5), math.pi), v(1.15, .65, .55), nil, v(0, 0, 1))
		for side = -1, 1, 2 do pier("LanternPendulums", "LanternBayFoot" .. bay .. side, v(x + side * 13, BaseY, hallZ), floor + 23, .48) end
		add("LanternPendulums", "LanternBanner" .. bay, "MC_Banner", frame(v(x + 13, floor + 10, hallZ - 2), math.pi), Vector3.one * 1.15, nil, v(0, 0, 1))
	end

	local machineLow, machineHigh = groupBounds({"UpperNormal", "MachineryApproach"})
	for index, z in {machineLow.Z + 8, (machineLow.Z + machineHigh.Z) / 2, machineHigh.Z - 8} do
		local point = v(machineHigh.X + 13, 74 + index * 7, z)
		pier("CounterweightAscent", "EastFoundation" .. index, point, point.Y, .80)
		add("CounterweightAscent", "EastOpenMachineBay" .. index, "MC_P3_GalleryArcadeStone", frame(point, -math.pi / 2), Vector3.one * 1.10, nil, v(1, 0, 0))
		add("CounterweightAscent", "EastCornice" .. index, "MC_P3_TerraceFascia", frame(point, -math.pi / 2), Vector3.one * 1.1, nil, v(1, 0, 0))
		add("CounterweightAscent", "EastBanner" .. index, "MC_Banner", frame(point + v(-2, 12, 10), -math.pi / 2), Vector3.one * 1.2, nil, v(1, 0, 0))
	end
	local liftLow, liftHigh = groupBounds({"UpperNormal", "UpperBrace", "UpperExpert", "Lifts"})
	for index, x in {liftLow.X - 16, liftHigh.X + 16} do
		local point = v(x, 105, layout.LiftOrigins.Upper.Z - 32)
		pier("CounterweightAscent", "LiftTowerFoundation" .. index, point, 105, .72)
		turret("CounterweightAscent", "LiftTwinTower" .. index, v(point.X, 105, point.Z), .70, 0, v(if index == 1 then -1 else 1, 0, -1).Unit)
	end

	local finish = layout.FinishPoint
	local keep = finish - v(0, 150, 0)
	for index, face in {
		{offset = v(0, 0, 18), yaw = 0, out = v(0, 0, 1)},
		{offset = v(38, 0, 0), yaw = math.pi / 2, out = v(1, 0, 0)},
		{offset = v(0, 0, -18), yaw = math.pi, out = v(0, 0, -1)},
		{offset = v(-38, 0, 0), yaw = -math.pi / 2, out = v(-1, 0, 0)},
	} do
		for tier, height in {BaseY, 42.6} do
			local faceScale = v(if index == 2 or index == 4 then .55 else 1.10, if tier == 2 then 1.26 else 1.10, 1.10)
			local point = v(keep.X, height, keep.Z) + face.offset
			add("Keep", "KeepTier" .. tier .. "Face" .. index, "MC_KeepShell", frame(point, face.yaw), faceScale, nil, face.out)
			if tier == 2 or index == 1 then windows("Keep", "KeepLancet" .. tier .. "Face" .. index, frame(point + face.out * .25, face.yaw), faceScale, face.out) end
		end
		add("Keep", "KeepTopCornice" .. index, "MC_P3_TerraceFascia", frame(v(keep.X, 126, keep.Z) + face.offset, face.yaw), v(76 / 24, .7, 1), nil, face.out)
	end
	for index, offset in {v(-31, 0, -18), v(31, 0, -18), v(-31, 0, 18), v(31, 0, 18)} do
		pier("Keep", "KeepGroundButtress" .. index, keep + offset, 126, .66)
	end
	for index, offset in {v(-31, 126, 18), v(31, 126, 18)} do
		turret("Keep", "KeepCrownTower" .. index, keep + offset, .54, 0, v(0, 0, 1))
	end
	add("Keep", "KeepMoonBanner", "MC_Banner", frame(keep + v(-24, 100, 18)), Vector3.one * 1.4, nil, v(0, 0, 1))
	add("Keep", "KeepIvy", "MC_Ivy", frame(keep + v(27, 92, 18)), Vector3.one * 1.4, nil, v(0, 0, 1))
	local crownPath = "Obstacles/Crown/CrownTerrace/Contact"
	for index, data in {{offset = v(0, 0, 18), yaw = 0, scale = v(1.5, 1, 1), out = v(0, 0, 1)},
		{offset = v(-23, 0, 0), yaw = -math.pi / 2, scale = v(1.15, 1, 1), out = v(-1, 0, 0)}} do
		add("CrownArrival", "CrownLancetScreen" .. index, "MC_P3_CrownScreen", frame(finish + data.offset, data.yaw), data.scale, nil, data.out)
	end
	add("CrownArrival", "CrownUprightEmblem", "MC_CrownEmblem", frame(finish + v(0, 6, 18)), Vector3.one * 1.15, nil, v(0, 0, 1))
	add("CrownArrival", "CrownIvy", "MC_Ivy", frame(finish + v(-22.4, -9, -9), -math.pi / 2), Vector3.one * 1.2, nil, v(-1, 0, 0))
	for side = -1, 1, 2 do
		local point = finish + v(side * 24, 0, 12)
		pier("CrownArrival", "CrownOuterFoot" .. side, point, finish.Y, .65)
		turret("CrownArrival", "CrownFinial" .. side, point, .38, 0, v(side, 0, 1).Unit)
	end
	counts.environment = "EnvironmentPlan.Get adds restrained outer rocks/plants and mounted lamps"
	assert(counts.units <= Limits.units and counts.meshParts <= Limits.meshParts and counts.triangles <= Limits.triangles,
		"World placement budget exceeded")
	return plan, counts
end

WorldPlan.BaseY, WorldPlan.Limits, WorldPlan.Assets = BaseY, table.freeze(Limits), table.freeze(Assets)
return WorldPlan
