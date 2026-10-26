--!nonstrict
local WorldPlan = {}
local v = Vector3.new
local BaseY = -30
local Limits = {units = 350, meshParts = 900, triangles = 420000}
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
	MC_P3_Rework_GroundPlinth = {1, 28, v(0, -.9, 0), v(32, 1.8, 24)},
	MC_LanternCage = {2, 1220, v(0, 0, 0), v(4, 6, 4)},
	MC_LanternCore = {1, 60, v(0, 0, 0), v(2, 3, 2)},
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
		return true, cf
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
	local function groupFrame(name, initial, units, outward)
		for step = 0, 20 do
			local cf = initial + (outward or Vector3.zero) * step * 2
			local safe = true
			for _, unit in units do
				local pose = cf * unit.offset
				if clash(unit.asset, pose, unit.scale) then safe = false; break end
			end
			if safe then
				if step > 0 then table.insert(counts.relocated, {name = name, studs = step * 2, wholeStructure = true}) end
				return cf
			end
		end
		error("Move grounded structure as a whole before installation: " .. name)
	end
	local function turret(district, name, point, scale, yaw, outward)
		local height = point.Y - BaseY
		local stemWidth = if district == "Keep" or district == "CrownArrival" then scale * 1.48
			else math.max(scale * 1.48, math.min(1.9, height / 75))
		local units = {
			{asset = "MC_TurretStone", offset = CFrame.identity, scale = Vector3.one * scale, suffix = "Stone"},
			{asset = "MC_TurretAmber", offset = CFrame.identity, scale = Vector3.one * scale, suffix = "Amber"},
			{asset = "MC_SlateSpire", offset = CFrame.new(0, 28 * scale, 0), scale = Vector3.one * scale, suffix = "Spire"},
			{asset = "MC_PierStone", offset = CFrame.new(0, -height, 0), scale = v(stemWidth, height / 60, stemWidth), suffix = "GroundedTowerStem"},
			{asset = "MC_P3_Rework_GroundPlinth", offset = CFrame.new(0, -height, 0), scale = v(stemWidth * .34, 2, stemWidth * .45), suffix = "CarvedFooting"},
		}
		local cf = groupFrame(name, frame(point, yaw), units, outward)
		for _, unit in units do add(district, name .. unit.suffix, unit.asset, cf * unit.offset, unit.scale) end
	end
	local function arcade(district, name, point, scale, yaw, outward, roof)
		local height = point.Y - BaseY
		local units = {{asset = "MC_P3_GalleryArcadeStone", offset = CFrame.identity, scale = Vector3.one * scale, suffix = "OpenBay"}}
		for side = -1, 1, 2 do
			table.insert(units, {asset = "MC_PierStone", offset = CFrame.new(side * 11.1 * scale, -height, 0),
				scale = v(.88, height / 60, .88), suffix = "GroundedJamb" .. side})
		end
		if roof then table.insert(units, {asset = "MC_P3_SlateGable", offset = CFrame.new(0, 18.5 * scale, -6),
			scale = v(scale, .65, .55), suffix = "SlateCoping"}) end
		local cf = groupFrame(name, frame(point, yaw), units, outward)
		for _, unit in units do add(district, name .. unit.suffix, unit.asset, cf * unit.offset, unit.scale) end
		return cf
	end
	local function facade(district, name, point, yaw, wallScale, windowY, windowScale, outward)
		local units = {{asset = "MC_KeepShell", offset = CFrame.identity, scale = wallScale, suffix = "Masonry"}}
		local height, halfWidth, depth = 66 * wallScale.Y, 66.7 * wallScale.X / 2, 3.95 * wallScale.Z / 2
		for _, asset in {"MC_WindowFrame", "MC_WindowTracery", "MC_WindowGlass"} do
			table.insert(units, {asset = asset, offset = CFrame.new(0, windowY - BaseY, depth + .8), scale = Vector3.one * windowScale, suffix = asset})
			table.insert(units, {asset = asset, offset = CFrame.new(0, windowY - BaseY, -depth - .8) * CFrame.Angles(0, math.pi, 0), scale = Vector3.one * windowScale, suffix = "Reverse" .. asset})
		end
		for side = -1, 1, 2 do table.insert(units, {asset = "MC_PierStone", offset = CFrame.new(side * (halfWidth - 1.8), 0, 0),
			scale = v(1, height / 60, 1.45), suffix = "CarvedReturn" .. side}) end
		for index, y in {7, height} do table.insert(units, {asset = "MC_P3_TerraceFascia", offset = CFrame.new(0, y, 0),
			scale = v((halfWidth * 2 + 3) / 24, .45, 2.5), suffix = "CopingBand" .. index}) end
		table.insert(units, {asset = "MC_P3_Rework_GroundPlinth", offset = CFrame.identity,
			scale = v((halfWidth * 2 + 6) / 32, 2, .62), suffix = "SharedPlinth"})
		local cf = groupFrame(name, frame(point, yaw), units, outward)
		for _, unit in units do add(district, name .. unit.suffix, unit.asset, cf * unit.offset, unit.scale) end
		return cf
	end
	local function crownScreen(name, point, yaw, scale, outward)
		local height = point.Y - BaseY
		local units = {{asset = "MC_P3_CrownScreen", offset = CFrame.identity, scale = scale, suffix = "Lancets"}}
		for side = -1, 1, 2 do table.insert(units, {asset = "MC_PierStone", offset = CFrame.new(side * 12 * scale.X, -height, 0),
			scale = v(.6, height / 60, .6), suffix = "GroundedScreenFoot" .. side}) end
		local cf = groupFrame(name, frame(point, yaw), units, outward)
		for _, unit in units do add("CrownArrival", name .. unit.suffix, unit.asset, cf * unit.offset, unit.scale) end
		return cf
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
		local supportSides = if data.size.X * data.size.Z < 300 then {1} else {-1, 1}
		for _, side in supportSides do
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
				local width = if #supportSides == 1 then .82 else .66
				local pierScale = v(width, (bottom - BaseY) / 28, width)
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
		local fasciaSides = if #supportSides == 1 then {-1} else {-1, 1}
		if data.role == "FlatTurn" and (data.group == "UpperNormalApproach" or data.group == "CrownApproach") then fasciaSides = {} end
		for _, side in fasciaSides do
			add("TerraceFoundations", "ContactFascia" .. index .. "_" .. side, "MC_P3_TerraceFascia",
				cf * CFrame.new(0, -data.size.Y - .18, side * (data.size.Z / 2 - 1.15)), v(data.size.X / 24, .45, .7), path)
		end
	end
	for index, data in layout.Surfaces do
		if data.role == "StartCapacity" or data.role == "FinishCapacity" or data.role == "FixedWaitingArea"
			or data.role == "FlatTurn" or data.role == "SafeRefuge" then
			supportedTerrace(data, index)
		end
	end

	local start = layout.StartPoint
	local gateBack = start + v(0, 0, 28)
	local gateUnits = {{asset = "MC_P3_GatewayStone", offset = CFrame.identity, scale = v(1.15, 1.2, 1.15), suffix = "PointedEntry"}}
	for side = -1, 1, 2 do table.insert(gateUnits, {asset = "MC_PierStone", offset = CFrame.new(side * 11.85 * 1.15, BaseY, 0),
		scale = v(.9, -BaseY / 60, .9), suffix = "GroundedEntryJamb" .. side}) end
	local gateCF = groupFrame("GateCourtEntry", frame(gateBack, math.pi), gateUnits, v(0, 0, 1))
	for _, unit in gateUnits do add("GateCourt", "GateCourt" .. unit.suffix, unit.asset, gateCF * unit.offset, unit.scale) end
	for side = -1, 1, 2 do
		local point = gateCF.Position + v(side * 18, 0, 0)
		turret("GateCourt", "GateCourtTower" .. side, point, .62, math.pi, v(0, 0, 1))
		add("GateCourt", "GateCourtHangingBanner" .. side, "MC_Banner", frame(point + v(side * 5, 15, -2), math.pi), Vector3.one)
	end

	-- Each signature gets close art on its outside edge, with different silhouettes.
	local westLow, westHigh = groupBounds({"ArchNormal"})
	local westX = westLow.X - 13
	for bay = 1, 3 do
		local z = westLow.Z + (westHigh.Z - westLow.Z) * (bay - .5) / 3
		local point = v(westX, 24 + (bay - 1) * 6, z)
		local bayCF = arcade("StoneArchClimb", "WestGothicBay" .. bay, point, 1.2, math.pi / 2, v(-1, 0, 0))
		if bay ~= 2 then
			facade("StoneArchClimb", "WestWindowBay" .. bay, v(bayCF.Position.X - 3, BaseY, z), math.pi / 2,
				v(.44, 1.15, .8), point.Y - 22, .68, v(-1, 0, 0))
		end
		add("StoneArchClimb", "WestIvy" .. bay, "MC_Ivy", bayCF * CFrame.new(-13, -6, 1), Vector3.one * 1.6)
		if bay == 2 then add("StoneArchClimb", "WestMoonBanner", "MC_Banner", bayCF * CFrame.new(13, 16, 1), Vector3.one * 1.2) end
	end
	turret("StoneArchClimb", "WestHighCorner", v(westX - 2, 40, westHigh.Z + 12), .58, math.pi / 2, v(-1, 0, 0))

	local galleryLow, galleryHigh = groupBounds({"GalleryNormal", "Gallery"})
	local hallZ = galleryHigh.Z + 12
	for bay = 1, 3 do
		local x = galleryLow.X + (galleryHigh.X - galleryLow.X) * (bay - .5) / 3
		local point = v(x, BaseY, hallZ)
		local floor = 52 + (bay - 1) * 4
		local bayCF = arcade("LanternPendulums", "LanternGallery" .. bay, v(x, floor, hallZ - 1), 1.15, math.pi, v(0, 0, 1), true)
		facade("LanternPendulums", "LanternAmberBay" .. bay, v(x, BaseY, bayCF.Position.Z + 2), math.pi,
			v(.6, 1.45, .9), floor - 27, .75, v(0, 0, 1))
		add("LanternPendulums", "LanternBanner" .. bay, "MC_Banner", bayCF * CFrame.new(-13, 13, 1), Vector3.one * 1.3)
	end

	local machineLow, machineHigh = groupBounds({"UpperNormal", "MachineryApproach"})
	for index, z in {machineLow.Z + 8, (machineLow.Z + machineHigh.Z) / 2, machineHigh.Z - 8} do
		local point = v(machineHigh.X + 13, 74 + index * 7, z)
		local bayCF = arcade("CounterweightAscent", "EastMachineGallery" .. index, point, 1.10, -math.pi / 2, v(1, 0, 0))
		add("CounterweightAscent", "EastCornice" .. index, "MC_P3_TerraceFascia", bayCF, Vector3.one * 1.1)
		add("CounterweightAscent", "EastBanner" .. index, "MC_Banner", bayCF * CFrame.new(11, 13, 2), Vector3.one * 1.3)
	end
	local liftLow, liftHigh = groupBounds({"UpperNormal", "UpperBrace", "UpperExpert", "Lifts"})
	for index, x in {liftLow.X - 16, liftHigh.X + 16} do
		local point = v(x, 105, layout.LiftOrigins.Upper.Z - 32)
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
		add("Keep", "KeepTopCornice" .. index, "MC_P3_TerraceFascia", frame(v(keep.X, 126, keep.Z) + face.offset, face.yaw),
			v((if index == 2 or index == 4 then 36.7 else 76) / 24, .7, 1), nil, face.out)
	end
	for index, offset in {v(-31, 0, -18), v(31, 0, -18), v(-31, 0, 18), v(31, 0, 18)} do
		if index <= 2 then pier("Keep", "KeepGroundButtress" .. index, keep + offset, 126, 1.2) end
	end
	for index, offset in {v(-31, 126, 18), v(31, 126, 18)} do
		turret("Keep", "KeepCrownTower" .. index, keep + offset, .54, 0, v(0, 0, 1))
	end
	add("Keep", "KeepMoonBanner", "MC_Banner", frame(keep + v(-24, 100, 18)), Vector3.one * 1.4, nil, v(0, 0, 1))
	add("Keep", "KeepIvy", "MC_Ivy", frame(keep + v(27, 92, 18)), Vector3.one * 1.4, nil, v(0, 0, 1))
	local crownPath = "Obstacles/Crown/CrownTerrace/Contact"
	local emblemFrame
	for index, data in {{offset = v(0, 0, 18), yaw = 0, scale = v(1.5, 1, 1), out = v(0, 0, 1)},
		{offset = v(-23, 0, 0), yaw = -math.pi / 2, scale = v(1.15, 1, 1), out = v(-1, 0, 0)}} do
		local cf = crownScreen("CrownScreen" .. index, finish + data.offset, data.yaw, data.scale, data.out)
		if index == 1 then emblemFrame = cf * CFrame.new(0, 6, -.25) end
	end
	add("CrownArrival", "CrownReverseEmblem", "MC_CrownEmblem", emblemFrame * CFrame.new(0, 0, 1.85) * CFrame.Angles(0, math.pi, 0), Vector3.one)
	local focus = finish + v(0, 0, 20)
	add("CrownArrival", "CrownEmblemCarvedMount", "MC_PierStone", frame(focus + v(0, 2.2, .4)), v(1.8, .17, .26), nil, v(0, 0, 1))
	add("CrownArrival", "CrownEmblemCoping", "MC_P3_TerraceFascia", frame(focus + v(0, 12.6, .4)), v(.5, .18, .75), nil, v(0, 0, 1))
	for side = -1, 1, 2 do
		local point = finish + v(side * 23, 0, 12)
		add("CrownArrival", "CrownLanternFoot" .. side, "MC_PierStone", frame(point), v(.5, .07, .5), nil, v(side, 0, 1).Unit)
		add("CrownArrival", "CrownLanternCage" .. side, "MC_LanternCage", frame(point + v(0, 5.6, 0)), Vector3.one * .55, nil, v(side, 0, 1).Unit)
		add("CrownArrival", "CrownLanternCore" .. side, "MC_LanternCore", frame(point + v(0, 5.6, 0)), Vector3.one * .55, nil, v(side, 0, 1).Unit)
		add("CrownArrival", "CrownFinishBanner" .. side, "MC_Banner", frame(finish + v(side * 22, 11, 13)), Vector3.one * .8, nil, v(side, 0, 1).Unit)
	end
	add("CrownArrival", "CrownIvy", "MC_Ivy", frame(finish + v(-22.4, -9, -9), -math.pi / 2), Vector3.one * 1.2, nil, v(-1, 0, 0))
	for side = -1, 1, 2 do
		local point = finish + v(side * 24, 0, 12)
		turret("CrownArrival", "CrownFinial" .. side, point, .38, 0, v(side, 0, 1).Unit)
	end
	counts.environment = "EnvironmentPlan.Get adds restrained outer rocks/plants and mounted lamps"
	assert(counts.units <= Limits.units and counts.meshParts <= Limits.meshParts and counts.triangles <= Limits.triangles,
		"World placement budget exceeded")
	return plan, counts
end

WorldPlan.BaseY, WorldPlan.Limits, WorldPlan.Assets = BaseY, table.freeze(Limits), table.freeze(Assets)
return WorldPlan
