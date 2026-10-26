--!nonstrict
local Baseline = require(script.Parent.BaselineWorldPlan)
local Geometry = require(script.Parent.AssetGeometry)
local World = {}
local v = Vector3.new
World.BaseY = -30
World.Limits = {units = 350, meshParts = 900, triangles = 420000}
World.LibraryName = "MoonlitCitadel_P3ArtRepair_AR01Library"

local function frame(point, yaw)
	return CFrame.new(point) * CFrame.Angles(0, yaw or 0, 0)
end

local function pathOf(data)
	return "Obstacles/" .. data.group .. "/" .. data.name .. "/Contact"
end

local function extents(layout, groups)
	local low, high = v(math.huge, math.huge, math.huge), v(-math.huge, -math.huge, -math.huge)
	for _, data in layout.Surfaces do
		local selected = false
		for _, prefix in groups do if string.sub(data.group, 1, #prefix) == prefix then selected = true; break end end
		if not selected then continue end
		local cf, half = data.frame or CFrame.new(data.position), data.size / 2
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local radius = v(math.abs(r.X) * half.X + math.abs(u.X) * half.Y + math.abs(l.X) * half.Z,
			math.abs(r.Y) * half.X + math.abs(u.Y) * half.Y + math.abs(l.Y) * half.Z,
			math.abs(r.Z) * half.X + math.abs(u.Z) * half.Y + math.abs(l.Z) * half.Z)
		low = v(math.min(low.X, data.position.X - radius.X), math.min(low.Y, data.position.Y - radius.Y), math.min(low.Z, data.position.Z - radius.Z))
		high = v(math.max(high.X, data.position.X + radius.X), math.max(high.Y, data.position.Y + radius.Y), math.max(high.Z, data.position.Z + radius.Z))
	end
	assert(low.X < math.huge, "No accepted route in architectural district")
	return low, high
end

function World.Get(layout, options)
	options = options or {}
	local baseline = Baseline.Get(layout)
	local plan, names, rows, floors = {}, {}, {}, {}
	local counts = {units = 0, meshParts = 0, triangles = 0, districts = {}, plantingMounts = {}, assemblies = {},
		retired = {}, representative = options.representative == true, occupiedGeometryRequired = true}
	for _, data in layout.Surfaces do floors[pathOf(data)] = data end
	local function row(name, cf, size)
		table.insert(rows, {path = name, frame = {cf:GetComponents()}, size = {size.X, size.Y, size.Z},
			anchored = true, collide = false, query = false, touch = false, transparency = 0})
	end
	local function add(district, name, asset, cf, scale, role, existing)
		scale = scale or Vector3.one
		assert(not names[name], "Duplicate connected architecture placement " .. name)
		names[name] = true
		local meta, library = Geometry[asset], "AR01"
		if not meta then
			local old = assert(Baseline.Assets[asset], "Unknown verified art " .. asset)
			meta = {parts = old[1], triangles = old[2], center = old[3], size = old[4]}
			library = if string.sub(asset, 1, 6) == "MC_P3_" then "P3" else "BL02"
		end
		table.insert(plan, {district = district, name = name, asset = asset, localCF = cf, scale = scale,
			library = library, materialRole = role or "StoneStructure", existingArt = existing == true})
		counts.units += 1; counts.meshParts += meta.parts; counts.triangles += meta.triangles
		counts.districts[district] = (counts.districts[district] or 0) + 1
		if not existing then
			if meta.occupied then
				for index, box in meta.occupied do
					row(name .. "/Occupied" .. index, cf * CFrame.new((box.low + box.high) / 2 * scale), (box.high - box.low) * scale)
				end
			else row(name, cf * CFrame.new(meta.center * scale), meta.size * scale) end
		end
		return cf
	end
	local function mass(district, name, low, high)
		assert(high.X > low.X and high.Y > low.Y and high.Z > low.Z, "Empty architectural mass " .. name)
		local meta = Geometry.MC_AR_MasonryMass
		return add(district, name, "MC_AR_MasonryMass", CFrame.new((low.X + high.X) / 2, low.Y, (low.Z + high.Z) / 2),
			v((high.X - low.X) / meta.size.X, (high.Y - low.Y) / meta.size.Y, (high.Z - low.Z) / meta.size.Z))
	end
	local function window(district, name, cf, scale, role)
		for _, asset in {"MC_WindowFrame", "MC_WindowTracery", "MC_WindowGlass"} do add(district, name .. asset, asset, cf, Vector3.one * scale, role) end
	end
	local function cell(district, name, cf, foundationBase, widthScale)
		local s = v(widthScale or 1, 1, 1)
		local height = cf.Position.Y - foundationBase
		assert(height > 0 and height / (46 * s.X) < 3.3, "Use a broad terrace body instead of an overextended post")
		add(district, name .. "Foundation", "MC_AR_FoundationBay46", cf + v(0, -height, 0), v(s.X, height / 40, 1))
		add(district, name .. "EnclosedBody", "MC_AR_GalleryBody46", cf, s)
		add(district, name .. "SeatedRoof", "MC_AR_GalleryRoof46", cf * CFrame.new(0, 26, 0), s, "SlateRoof")
		table.insert(counts.assemblies, {name = name, frame = cf, width = 46 * s.X, bodyHeight = 26,
			foundationBase = foundationBase, front = "+localZ", rear = "-22localZ", roofSeatY = 26})
		local exteriorCount = if district == "LanternPendulums" or district == "GalleryMachineJunction" then 2
			elseif district == "StoneArchClimb" or district == "CounterweightAscent" and name ~= "RearMechanismHouse" then 1 else 0
		local glassScale = math.min(.70, height * .52 / 58)
		for index = 1, exteriorCount do
			local x = if exteriorCount == 2 then (if index == 1 then -.23 else .23) * 46 * s.X else 0
			window(district, name .. "QuietFoundationLancet" .. index,
				cf * CFrame.new(x, -height * .52 - 57.98 * glassScale / 2, -23.6) * CFrame.Angles(0, math.pi, 0),
				glassScale, "SecondaryWindow")
		end
		return cf
	end
	local function tower(district, name, cf, scale, baseHeight)
		baseHeight = baseHeight or 24
		assert(baseHeight <= 48, "A turret must rest on a real intermediate storey")
		add(district, name .. "ButtressedBase", "MC_AR_TowerBase", cf, v(1, baseHeight / 24, 1))
		local top = cf * CFrame.new(0, baseHeight, 0)
		add(district, name .. "Stone", "MC_TurretStone", top, Vector3.one * scale)
		add(district, name .. "Amber", "MC_TurretAmber", top, Vector3.one * scale, "QuietAccent")
		add(district, name .. "Spire", "MC_SlateSpire", top * CFrame.new(0, 28 * scale, 0), Vector3.one * scale, "SlateRoof")
	end

	-- Keep its coherent existing lower body; replace the unrelated upper scenery and all long posts.
	for _, data in baseline do
		local keep = data.district == "Keep" and string.sub(data.name, 1, 8) == "KeepTier"
		local mainWindow = data.district == "Keep" and string.sub(data.name, 1, 16) == "KeepLancet2Face1"
		local contactTrim = data.district == "TerraceFoundations" and string.sub(data.name, 1, 12) == "ContactFasci"
		if keep or mainWindow or contactTrim then
			add(data.district, data.name, data.asset, data.localCF, data.scale, if mainWindow then "MainKeepWindow" else "StoneStructure", true)
		else table.insert(counts.retired, data.name) end
	end

	local finish = layout.FinishPoint
	local cx, cz = finish.X, finish.Z
	for side = -1, 1, 2 do
		for index, height in {55, 89} do
			window("Keep", "KeepQuietSide" .. side .. "Tier" .. index,
				frame(v(cx + side * 40.5, height, cz), side * math.pi / 2), .30, "SecondaryWindow")
		end
	end
	for index, x in {cx - 14, cx + 14} do
		window("Keep", "KeepQuietRear" .. index, frame(v(x, 61, cz - 20.5), math.pi), .28, "SecondaryWindow")
	end
	local _, galleryHigh = extents(layout, {"Gallery", "GalleryNormal"})
	local galleryFront = galleryHigh.Z + 18
	local galleryWidth = math.max(46, (layout.Lanterns[#layout.Lanterns].point.X - layout.Lanterns[1].point.X) / (#layout.Lanterns - 1))
	local galleryScale = galleryWidth / 46
	local galleryFrames = {}
	for band, lantern in layout.Lanterns do
		local floor = assert(floors["Obstacles/Gallery/NormalWaitBefore" .. band .. "/Contact"])
		local cf = frame(v(lantern.point.X, floor.position.Y - 4, galleryFront), math.pi)
		galleryFrames[band] = cf
		if not options.representative or band == 2 then
			cell("LanternPendulums", "Gallery" .. band, cf, World.BaseY, galleryScale)
			window("LanternPendulums", "GalleryInteriorQuietLancet" .. band, cf * CFrame.new(0, 2, -19.7), .34, "SecondaryWindow")
			window("LanternPendulums", "GalleryQuietLancet" .. band, cf * CFrame.new(0, 2, -23.3) * CFrame.Angles(0, math.pi, 0), .34, "SecondaryWindow")
			for side = -1, 1, 2 do
				add("LanternPendulums", "GalleryMoonBanner" .. band .. side, "MC_Banner", cf * CFrame.new(side * 17.5 * galleryScale, 19, .65), Vector3.one * 1.0, "AttachedDetail")
				local shelf = "Gallery" .. band .. "PlanterShelf" .. side
				add("LanternPendulums", shelf, "MC_AR_MasonryMass", cf * CFrame.new(side * 16 * galleryScale, 2.8, 1.4),
					v(7.6 / 25, 1.2 / 24, 6 / 13), "StoneLedge")
				table.insert(counts.plantingMounts, {name = "Gallery" .. band .. (if side < 0 then "Left" else "Right"),
					frame = cf * CFrame.new(side * 16 * galleryScale, 4, 1.4), district = "LanternPendulums", supportName = shelf})
			end
		end
	end

	-- A lower roofed wing joins the keep to the outer gallery without enclosing its race line.
	local wingTop = 38
	mass("GalleryKeepJunction", "JunctionWestReturn", v(cx - 28, World.BaseY, cz + 18), v(cx - 16, wingTop, galleryFront))
	mass("GalleryKeepJunction", "JunctionEastReturn", v(cx + 32, World.BaseY, cz + 18), v(cx + 44, wingTop, galleryFront))
	local roofMeta = Geometry.MC_AR_GalleryRoof46
	local wingLength = galleryFront - (cz + 18)
	add("GalleryKeepJunction", "JunctionClosedRoof", "MC_AR_GalleryRoof46", frame(v(cx + 8, wingTop, cz + 18), math.pi),
		v(72 / roofMeta.size.X, 1, wingLength / 22), "SlateRoof")

	-- The east approach stays open from Y137 upward; the roof storey is assembled from real joined solids.
	local bottom, top = 125.8, finish.Y - 2.2
	mass("KeepRoof", "RoofDrumWestReturn", v(cx - 38, bottom, cz - 18), v(cx - 30, top, cz + 18))
	mass("KeepRoof", "RoofDrumSouthReturn", v(cx - 38, bottom, cz + 10), v(cx + 38, top, cz + 18))
	mass("KeepRoof", "RoofDrumNorthWestReturn", v(cx - 38, bottom, cz - 18), v(cx + 20, top, cz - 10))
	mass("KeepRoof", "EastApproachLowSill", v(cx + 20, bottom, cz - 18), v(cx + 38, 136.8, cz - 10))
	mass("KeepRoof", "RoofDrumEastSouthReturn", v(cx + 30, bottom, cz - 4), v(cx + 38, top, cz + 18))
	mass("KeepRoof", "EastApproachPortalFoot", v(cx + 30, bottom, cz - 18), v(cx + 38, 136.8, cz - 4))
	counts.approachPortal = {low = v(cx + 20, 137, cz - 38), high = v(cx + 51, 168, cz - 4),
		reason = "Accepted CrownApproach contact, free jump, follow camera and receiving-lip sight"}
	local crown = assert(floors["Obstacles/Crown/CrownTerrace/Contact"])
	mass("KeepRoof", "CrownUnderfloorSeat", finish - v(crown.size.X / 2, 5, crown.size.Z / 2),
		finish + v(crown.size.X / 2, -2.2, crown.size.Z / 2))
	mass("CrownArrival", "SouthScreenSeatedCurb", finish + v(-20, -3.4, 14), finish + v(20, -.4, 23))
	mass("CrownArrival", "WestScreenSeatedCurb", finish + v(-27, -3.4, -16), finish + v(-18, -.4, 23))
	add("CrownArrival", "CrownSouthJoinedScreen", "MC_P3_CrownScreen", frame(finish + v(0, -.4, 20)), v(1.5, 1, 1))
	add("CrownArrival", "CrownWestJoinedScreen", "MC_P3_CrownScreen", frame(finish + v(-23, -.4, 3.5), -math.pi / 2), v(39 / 24, 1, 1))
	mass("CrownArrival", "CrownEmblemStoneMount", finish + v(-5.2, -.4, 20), finish + v(5.2, 12.2, 21.8))
	counts.crownEmblem = "Existing accepted Decoration/CrownEmblem stays exact; new stone mount supports it without a duplicate emblem"
	for side = -1, 1, 2 do tower("CrownArrival", "CrownCorner" .. side, frame(finish + v(side * 26, -24.2, 18)), .42) end
	window("KeepRoof", "KeepRoofQuietWestWindow", frame(v(cx - 38.2, 126.6, cz + 1), -math.pi / 2), .28, "SecondaryWindow")

	if not options.representative then
		local start = layout.StartPoint
		local gateCF = cell("GateCourt", "GateEntryChamber", frame(start + v(0, -6, 28), math.pi), World.BaseY)
		for side = -1, 1, 2 do
			tower("GateCourt", "GateButtressedTower" .. side, frame(v(start.X + side * 28, World.BaseY, gateCF.Position.Z + 8), math.pi), .65, 48)
			add("GateCourt", "GateMoonBanner" .. side, "MC_Banner", gateCF * CFrame.new(side * 17.5, 19, .65), Vector3.one * 1.2, "AttachedDetail")
		end
		window("GateCourt", "GateRearQuietLancet", gateCF * CFrame.new(0, 1.5, -23.3) * CFrame.Angles(0, math.pi, 0), .34, "SecondaryWindow")

		local westLow, westHigh = extents(layout, {"ArchNormal"})
		local westFront = westLow.X - 40
		for bay = 1, 3 do
			local z = westLow.Z + 23 + (bay - 1) * 46
			local nearest, distance = nil, math.huge
			for _, floor in layout.Surfaces do
				if floor.group ~= "ArchNormal" or floor.role ~= "FlatTurn" then continue end
				local delta = math.abs(floor.position.Z - z)
				if delta < distance then nearest, distance = floor, delta end
			end
			assert(nearest, "The west cloister must follow the accepted Arch Normal landings")
			local cf = cell("StoneArchClimb", "WestEnclosedCloister" .. bay,
				frame(v(westFront, nearest.position.Y - 6, z), math.pi / 2), World.BaseY)
			window("StoneArchClimb", "WestQuietLancet" .. bay, cf * CFrame.new(0, 2, -23.3) * CFrame.Angles(0, math.pi, 0), .34, "SecondaryWindow")
			add("StoneArchClimb", "WestAttachedIvy" .. bay, "MC_Ivy", cf * CFrame.new(-18, 7, .65), Vector3.one * 1.3, "AttachedDetail")
		end
		local westEnd = westLow.Z + 3 * 46
		local gateLeft = start.X - 27
		mass("GateWestJunction", "WestLowCourtyardBody", v(westFront - 22, World.BaseY, westEnd), v(westFront, -6, start.Z + 28))
		add("GateWestJunction", "WestLowCourtyardClosedRoof", "MC_AR_GalleryRoof46",
			frame(v(westFront, -6, (westEnd + start.Z + 28) / 2), math.pi / 2),
			v((start.Z + 28 - westEnd) / roofMeta.size.X, 1, 1), "SlateRoof")
		mass("GateWestJunction", "GateLowCourtyardReturn", v(westFront, World.BaseY, start.Z + 6), v(gateLeft, -6, start.Z + 28))
		add("GateWestJunction", "GateLowCourtyardClosedRoof", "MC_AR_GalleryRoof46",
			frame(v((westFront + gateLeft) / 2, -6, start.Z + 6), math.pi),
			v((gateLeft - westFront) / roofMeta.size.X, 1, 1), "SlateRoof")

		local machineLow, machineHigh = extents(layout, {"UpperNormalApproach", "MachineryApproach"})
		local machineFront = machineHigh.X + 18
		local machineSouthBase = layout.CP03.point.Y - 6
		for bay = 1, 6 do
			local z = machineLow.Z + 23 + (bay - 1) * 46
			local base = if bay <= 3 then layout.CP04.point.Y - 6 else machineSouthBase
			local cf = cell("CounterweightAscent", "MachineEnclosedGallery" .. bay,
				frame(v(machineFront, base, z), -math.pi / 2), World.BaseY)
			if bay == 2 or bay == 5 then
				add("CounterweightAscent", "MachineMoonBanner" .. bay, "MC_Banner", cf * CFrame.new(17.5, 19, .65), Vector3.one * 1.1, "AttachedDetail")
			end
		end
		local last = galleryFrames[3]
		for bay = 4, 5 do
			local cf = frame(v(last.Position.X + (bay - 3) * galleryWidth, last.Position.Y + (bay - 3) * 2, galleryFront), math.pi)
			cell("GalleryMachineJunction", "JoinedServiceGallery" .. bay, cf, World.BaseY, galleryScale)
		end
		local tail = last.Position.X + 2 * galleryWidth + galleryWidth / 2
		if tail < machineFront + 2 then
			mass("GalleryMachineJunction", "ClosedCornerReturn", v(tail, World.BaseY, galleryFront),
				v(machineFront + 2, machineSouthBase + 26, galleryFront + 22))
			add("GalleryMachineJunction", "CornerSeatedRoof", "MC_AR_GalleryRoof46",
				frame(v((tail + machineFront + 2) / 2, machineSouthBase + 26, galleryFront), math.pi),
				v((machineFront + 2 - tail) / roofMeta.size.X, 1, 1), "SlateRoof")
		end
		local rear = cell("CounterweightAscent", "RearMechanismHouse",
			frame(v(layout.LiftOrigins.Upper.X, layout.LiftOrigins.Upper.Y + 26, layout.LiftOrigins.Upper.Z - 52)), World.BaseY, 1.30)
		window("CounterweightAscent", "RearMechanismQuietLancet", rear * CFrame.new(0, 2, -19.7), .40, "SecondaryWindow")
	end

	counts.fullMapPending = options.representative == true
	counts.proposalRows = rows
	if options.clearance and options.config then
		local volumes = options.clearance.Prepare(layout, options.config)
		counts.clearance = options.clearance.CheckParts(rows, volumes)
	end
	assert(counts.units <= World.Limits.units and counts.meshParts <= World.Limits.meshParts and counts.triangles <= World.Limits.triangles, "Connected art budget exceeded")
	return plan, counts
end

World.AssetGeometry = Geometry
return World
