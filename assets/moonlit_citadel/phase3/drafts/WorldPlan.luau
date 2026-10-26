--!nonstrict
local WorldPlan = {}
local BaseY = -30
local Limits = {units = 180, meshParts = 400, triangles = 260000}
local Assets = {
	MC_KeepShell = {3, 4488}, MC_WindowFrame = {3, 3852}, MC_WindowTracery = {1, 1312}, MC_WindowGlass = {3, 216},
	MC_TurretStone = {3, 3212}, MC_TurretAmber = {1, 352}, MC_SlateSpire = {3, 860},
	MC_PierStone = {2, 380}, MC_Banner = {2, 712}, MC_Ivy = {1, 304},
	MC_P3_GatewayStone = {3, 2852}, MC_P3_GalleryArcadeStone = {2, 2104}, MC_P3_VaultRibs = {2, 1276},
	MC_P3_FlyingButtress = {2, 1604}, MC_P3_TerraceFascia = {3, 536}, MC_P3_Parapet = {3, 2016},
	MC_P3_SlateGable = {3, 272}, MC_P3_CrownScreen = {4, 3980},
	MC_P3_PlantPocket = {5, 824}, MC_P3_Cypress = {3, 320},
}

local function v(x, y, z) return Vector3.new(x, y, z) end
local function frame(point, yaw) return CFrame.new(point) * CFrame.Angles(0, yaw or 0, 0) end
local function finite(number) return number == number and math.abs(number) < math.huge end
local function pathOf(data) return "Obstacles/" .. data.group .. "/" .. data.name .. "/Contact" end

local function flatBounds(data)
	local cf = data.frame or CFrame.new(data.position)
	local radius = v(math.abs(cf.RightVector.X), 0, math.abs(cf.RightVector.Z)) * data.size.X / 2
		+ v(math.abs(cf.LookVector.X), 0, math.abs(cf.LookVector.Z)) * data.size.Z / 2
	return cf.Position, radius
end

function WorldPlan.Get(layout)
	assert(layout.Surfaces and layout.FinishPoint and layout.StartPoint, "Provide the final connected Moonlit layout")
	local plan, names, rejectedSupports = {}, {}, {}
	local counts = {units = 0, meshParts = 0, triangles = 0, districts = {}}
	local surfaces = {}
	for _, data in layout.Surfaces do surfaces[pathOf(data)] = data end
	local function add(district, name, asset, localCF, scale, supportPath)
		scale = scale or Vector3.one
		assert(Assets[asset], "Unknown world edit unit: " .. asset)
		assert(not names[name], "Duplicate world placement: " .. name)
		for _, component in {localCF:GetComponents()} do assert(finite(component), name .. " has a nonfinite frame") end
		for _, component in {scale.X, scale.Y, scale.Z} do assert(finite(component) and component > 0 and component < 8, name .. " has invalid scale") end
		names[name] = true
		table.insert(plan, {district = district, name = name, asset = asset, localCF = localCF, scale = scale,
			library = if string.sub(asset, 1, 6) == "MC_P3_" then "P3" else "BL02", supportPath = supportPath})
		counts.units += 1
		counts.meshParts += Assets[asset][1]
		counts.triangles += Assets[asset][2]
		counts.districts[district] = (counts.districts[district] or 0) + 1
	end
	local function windows(district, name, point, scale, yaw)
		for _, asset in {"MC_WindowFrame", "MC_WindowTracery", "MC_WindowGlass"} do
			add(district, name .. "_" .. asset, asset, frame(point, yaw), Vector3.one * scale)
		end
	end
	local function pillar(district, name, point, top, width, supportPath)
		local height = top - BaseY
		assert(height > 0 and height < 210, name .. " has an invalid grounded height")
		add(district, name, "MC_PierStone", frame(v(point.X, BaseY, point.Z)), v(width or .65, height / 60, width or .65), supportPath)
	end
	local function turret(district, name, point, scale, yaw)
		for _, asset in {"MC_TurretStone", "MC_TurretAmber"} do
			add(district, name .. "_" .. asset, asset, frame(point, yaw), Vector3.one * scale)
		end
		add(district, name .. "_Spire", "MC_SlateSpire", frame(point + v(0, 28 * scale, 0), yaw), Vector3.one * scale)
	end
	local function planted(district, name, point, tree)
		pillar(district, name .. "_GroundPlinth", point, point.Y, 1.5)
		add(district, name .. "_CarvedCapital", "MC_P3_TerraceFascia", frame(point), v(8 / 24, .2, 2.4))
		add(district, name .. "_Basin", "MC_P3_PlantPocket", frame(point))
		if tree then add(district, name .. "_Cypress", "MC_P3_Cypress", frame(point + v(0, 1, 0)), Vector3.one * .75) end
	end
	local function lowerRouteClash(point, top, width, ownPath)
		for path, other in surfaces do
			if path == ownPath or other.position.Y >= top + .05 then continue end
			local center, radius = flatBounds(other)
			if math.abs(point.X - center.X) < radius.X + width * 2.6 + 2
				and math.abs(point.Z - center.Z) < radius.Z + width * 2.9 + 2
				and other.position.Y + 18.2 > BaseY then return path end
		end
		return nil
	end
	local function support(district, name, path, count, fascia)
		local data = surfaces[path]
		assert(data, "Missing supported contact: " .. path)
		local cf = data.frame or CFrame.new(data.position)
		if cf.UpVector.Y < .999 then return end
		local top = data.position.Y - data.size.Y - .06
		for index = 1, count do
			local offset = if count == 1 then 0 else (if index == 1 then -1 else 1) * math.min(10, data.size.X * .28)
			local point = cf:PointToWorldSpace(v(offset, 0, 0))
			local clash = lowerRouteClash(point, top, .55, path)
			if clash then table.insert(rejectedSupports, {name = name .. index, lowerPath = clash})
			else pillar(district, name .. index, point, top, .55, path) end
		end
		if fascia then
			local edge = data.size.Z / 2 - 1.1
			if name == "CheckpointGround1_" then edge = -edge end
			add(district, name .. "_UnderEdge", "MC_P3_TerraceFascia",
				cf * CFrame.new(0, -data.size.Y - .08, edge), v(data.size.X / 24, .8, .8), path)
		end
	end

	local keep = layout.FinishPoint + v(0, -150, 2)
	local faces = {
		{name = "South", point = keep + v(0, 0, 40.02), yaw = 0},
		{name = "East", point = keep + v(40.02, 0, 0), yaw = math.pi / 2},
		{name = "North", point = keep + v(0, 0, -40.02), yaw = math.pi},
		{name = "West", point = keep + v(-40.02, 0, 0), yaw = -math.pi / 2},
	}
	for _, face in faces do
		for tier, base in {BaseY, 49.2} do
			local point = v(face.point.X, base, face.point.Z)
			add("Keep", face.name .. "Masonry" .. tier, "MC_KeepShell", frame(point, face.yaw), Vector3.one * 1.2)
			if tier == 2 or face.name == "South" or face.name == "North" then
				windows("Keep", face.name .. "Window" .. tier, point + frame(Vector3.zero, face.yaw):VectorToWorldSpace(v(0, 0, .15)), 1.2, face.yaw)
			end
		end
		for bay, x in {-25, 0, 25} do
			local bayFrame = frame(v(face.point.X, 128.4, face.point.Z), face.yaw) * CFrame.new(x, 0, 0)
			add("Keep", face.name .. "OpenLoggia" .. bay, "MC_P3_GalleryArcadeStone", bayFrame, Vector3.one * 1.04)
		end
		add("Keep", face.name .. "TopCornice", "MC_P3_TerraceFascia", frame(v(face.point.X, 128.4, face.point.Z), face.yaw), v(80.04 / 24, .75, 1))
	end
	for index, offset in {v(-36, 0, -36), v(36, 0, -36), v(-36, 0, 36), v(36, 0, 36)} do
		pillar("Keep", "KeepGroundPier" .. index, keep + offset, 147.8, .70)
	end
	for index, offset in {v(-42, 128.4, 42), v(42, 128.4, 42)} do
		turret("Keep", "CrownFrontTower" .. index, keep + offset, .65)
	end
	for index, z in {-76, 6} do
		add("Keep", "KeepFlyingSupport" .. index, "MC_P3_FlyingButtress", frame(v(keep.X - 44, BaseY, z), -math.pi / 2), Vector3.one * 1.2)
	end
	add("Keep", "KeepSouthBanner", "MC_Banner", frame(keep + v(-25, 101, 42)), Vector3.one * 1.1)
	add("Keep", "KeepSouthIvy", "MC_Ivy", frame(keep + v(31, 105, 42)), Vector3.one * 1.2)

	local start = layout.StartPoint
	add("GateCourt", "GateCourtBackdrop", "MC_P3_GatewayStone", frame(start + v(-80, 0, 0), math.pi / 2), Vector3.one * 1.05)
	add("GateCourt", "GateCourtSideGate", "MC_P3_GatewayStone", frame(start + v(-32, 0, 0), math.pi / 2), Vector3.one * .85)
	for index, offset in {v(-80, 0, -12.45), v(-80, 0, 12.45), v(-32, 0, -10.1), v(-32, 0, 10.1)} do
		pillar("GateCourt", "GateJambFoundation" .. index, start + offset, 0, .75)
	end
	for index, offset in {v(-84, 0, -31), v(-84, 0, 31)} do
		pillar("GateCourt", "GateTowerFoot" .. index, start + offset, 0, .9)
		turret("GateCourt", "GateTower" .. index, start + offset, .65)
	end
	for index, x in {-166, -142} do
		pillar("GateCourt", "CourtWallFoundation" .. index, v(x, 0, 186), 0, .8)
		add("GateCourt", "CourtOuterWall" .. index, "MC_P3_Parapet", frame(v(x, 0, 186)))
	end
	planted("GateCourt", "GateGreenPocket", start + v(47, 0, -2), true)
	add("GateCourt", "GateBanner", "MC_Banner", frame(start + v(-84, 14, 34)), Vector3.one * .9)

	for index, z in {-62, 5, 76} do
		local point = v(-246, 16, z)
		add("WestArcades", "WestOpenArcade" .. index, "MC_P3_GalleryArcadeStone", frame(point, math.pi / 2), Vector3.one * 1.5)
		for side, distance in {-18, 18} do
			pillar("WestArcades", "WestJamb" .. index .. "_" .. side, point + v(0, 0, distance), 16, .72)
		end
		if index == 2 then
			add("WestArcades", "WestBlueBanner", "MC_Banner", frame(point + v(3, 25, 21), math.pi / 2))
			add("WestArcades", "WestIvy", "MC_Ivy", frame(point + v(3, 0, -21), math.pi / 2), Vector3.one * 1.3)
		end
	end
	add("WestArcades", "WestOuterButtress", "MC_P3_FlyingButtress", frame(v(-247, BaseY, 116)), Vector3.one * 1.4)

	for index, x in {-112, -76, -40} do
		local point = v(x, 52, 194)
		add("SouthCloister", "CloisterOpenBay" .. index, "MC_P3_GalleryArcadeStone", frame(point, math.pi), Vector3.one * 1.5)
		for side, distance in {-18, 18} do
			pillar("SouthCloister", "CloisterJamb" .. index .. "_" .. side, point + v(distance, 0, 0), 52, .75)
		end
		add("SouthCloister", "CloisterVault" .. index, "MC_P3_VaultRibs", frame(v(x, 72.5, 194)), Vector3.one * 1.5)
		add("SouthCloister", "CloisterSlateRoof" .. index, "MC_P3_SlateGable", frame(v(x, 84.6, 194)), Vector3.one * 1.5)
	end
	planted("SouthCloister", "CloisterGreenPocket", v(-24, 52, 189), false)

	for band = 1, 3 do
		local point = v(-44 + 44 + (band - 1) * 46, BaseY, 144)
		for tier, base in {BaseY, 22.8} do
			add("LanternGallery", "LanternWall" .. band .. "_" .. tier, "MC_KeepShell",
				frame(v(point.X, base, point.Z), math.pi), Vector3.one * .8)
		end
		windows("LanternGallery", "LanternWindow" .. band, v(point.X, 22.8, 143.7), .8, math.pi)
	end
	add("LanternGallery", "LanternHallIvy", "MC_Ivy", frame(v(23, 49, 142), math.pi), Vector3.one * 1.1)

	for index, z in {-114, -10, 112} do
		local point = v(if index == 3 then 238 else 212, 72, z)
		pillar("EastWallWalk", "EastWallFoot" .. index, point, 72, .9)
		add("EastWallWalk", "EastUnderCornice" .. index, "MC_P3_TerraceFascia", frame(point, -math.pi / 2))
		add("EastWallWalk", "EastCrenels" .. index, "MC_P3_Parapet", frame(point, -math.pi / 2))
	end
	for index, point in {v(56, 106, -58), v(164, 106, -90)} do
		pillar("Machinery", "MachineTowerFoot" .. index, point, 106, .9)
		turret("Machinery", "MachineTower" .. index, point, .65)
		add("Machinery", "MachineBanner" .. index, "MC_Banner", frame(point + v(0, -11, 4.3)), Vector3.one * .85)
	end
	local finish = layout.FinishPoint
	add("Crown", "CrownNorthLancets", "MC_P3_CrownScreen", frame(finish + v(0, 0, -29)))
	add("Crown", "CrownEastLancets", "MC_P3_CrownScreen", frame(finish + v(40, 0, 0), -math.pi / 2))
	add("Crown", "CrownIvy", "MC_Ivy", frame(finish + v(31, -16, 3)), Vector3.one * .8)

	for index = 1, 4 do
		local cp = layout[string.format("CP%02d", index)]
		support("TerraceSupports", "CheckpointGround" .. index .. "_", cp.support, 2, true)
	end
	for index, path in {"Obstacles/Gate/GateCourt/Contact", "Obstacles/ArchNormal/ArchMerge/Contact",
		"Obstacles/MachineryApproach/GalleryMergeBay/Contact", "Obstacles/Crown/CrownTerrace/Contact"} do
		support("TerraceSupports", "LandingGround" .. index .. "_", path, 2, index < 4)
	end
	counts.rejectedSupports = rejectedSupports
	assert(counts.units <= Limits.units and counts.meshParts <= Limits.meshParts and counts.triangles <= Limits.triangles,
		"World kit placement budget exceeded: " .. tostring(counts.meshParts) .. " parts / " .. tostring(counts.triangles) .. " triangles")
	return plan, counts
end

WorldPlan.BaseY, WorldPlan.Limits = BaseY, table.freeze(Limits)
return WorldPlan
