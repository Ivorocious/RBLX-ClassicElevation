--!nonstrict
local SupportingObstacles = {}
local FOOTPRINT, INSET = 1, 1.05
local function v(x, y, z) return Vector3.new(x, y, z) end
local function path(floor) return "Obstacles/" .. floor.group .. "/" .. floor.name .. "/Contact" end
local function frame(floor) return floor.frame or CFrame.new(floor.position) end
local function fit(floor, offset)
	return v(math.clamp(offset.X, -floor.size.X / 2 + INSET, floor.size.X / 2 - INSET), offset.Y,
		math.clamp(offset.Z, -floor.size.Z / 2 + INSET, floor.size.Z / 2 - INSET))
end

function SupportingObstacles.Apply(Layout)
	assert(not Layout.SupportingObstacleData, "Phase3 obstacle tuning already applied")
	local floors, changed, originalFrames = {}, {}, {}
	for _, floor in Layout.Surfaces do floors[path(floor)] = floor end
	local function update(group, name, size, position)
		local key = "Obstacles/" .. group .. "/" .. name .. "/Contact"
		local floor = assert(floors[key], "Phase3 precision floor missing: " .. key)
		originalFrames[key], changed[key] = frame(floor), true
		floor.size = size
		if position then
			local delta = position - floor.position
			floor.position = position
			if floor.frame then floor.frame = CFrame.new(delta) * floor.frame end
		end
		return floor
	end
	local shift = floors["Obstacles/ArchExpert/InnerTakeoff/Contact"].position - v(-57, 28, -78)
	local prep = floors["Obstacles/ArchExpert/InnerTakeoff/Contact"]
	local cp01 = assert(floors["Obstacles/SharedArches/CP01Terrace/Contact"], "Phase3 first decision terrace missing")
	local rise = update("ArchExpert", "RiseCorbel", v(4, 1, 9), shift + v(-57, 32, -57))
	local turn = update("ArchExpert", "WrapTurn", v(9, 1, 12))
	local beam = update("ArchExpert", "HurdleBeam", v(3.2, 1, 48), shift + v(-54.5, 40, -20))
	local perch = update("ArchExpert", "TurnPerch", v(4, 1, 10), shift + v(-48, 44, 10))
	local rail = update("ArchExpert", "FinalRiseRail", v(3.6, 1, 32), shift + v(-42, 48, 31))
	local merge = assert(floors["Obstacles/ArchNormal/ArchMerge/Contact"], "Phase3 arch rejoin missing")
	for band = 1, 3 do
		update("Gallery", "ExpertBefore" .. band, v(4, 1, 8))
		update("Gallery", "ExpertCrossing" .. band, v(3, 1, 8))
		update("Gallery", "ExpertAfter" .. band, v(4, 1, 6))
	end
	update("GalleryExpertApproach", "EntryRail", v(4, 1, 22))
	for band = 2, 3 do update("GalleryExpertApproach", "BetweenBandRail" .. band, v(3, 1, 15)) end
	update("GalleryExpertExit", "ExitRail", v(3, 1, 17))
	for _, suffix in {"", "Mirror"} do
		for index, size in {v(4.2, 1, 7), v(3.8, 1, 6), v(3.8, 1, 6), v(5.2, 1, 7), v(4.2, 1, 8)} do
			local floor = floors["Obstacles/UpperBrace" .. suffix .. "/BraceStep" .. index .. "/Contact"]
			local move = if index == 4 then 1.5 elseif index == 5 then 3.25 else 0
			local point = if move > 0 then floor.position + v(if suffix == "" then move else -move, 0, 0) else nil
			update("UpperBrace" .. suffix, "BraceStep" .. index, size, point)
		end
		local exitBeam = floors["Obstacles/UpperExpertExit" .. suffix .. "/OuterExitBeam/Contact"]
		update("UpperExpertExit" .. suffix, "OuterExitBeam", v(4.2, 1, 20), exitBeam.position + v(if suffix == "" then -1 else 1, 0, 0))
		update("UpperExpertExit" .. suffix, "ExitCorbel", v(6, 1, 8))
		update("UpperExpertExit" .. suffix, "ReturnCorbel", v(6, 1, 8))
	end
	local arch, transfers = {}, {}
	local function at(floor, point, kind, family)
		local offset = frame(floor):PointToObjectSpace(point)
		assert(math.abs(offset.X) + FOOTPRINT <= floor.size.X / 2 + .001
			and math.abs(offset.Z) + FOOTPRINT <= floor.size.Z / 2 + .001, "Expert feet footprint escapes " .. path(floor))
		return {name = floor.name, path = path(floor), offset = offset, kind = kind or "Walk",
			requiredJump = if kind == "Jump" then true else nil, obstacleFamily = family}
	end
	local function walk(floor, point) table.insert(arch, at(floor, point)) end
	local function jump(from, to, start, stop, family)
		local distance = v(stop.X - start.X, 0, stop.Z - start.Z).Magnitude
		local riseStuds = stop.Y - start.Y
		local speed = math.sqrt(2 * 196.2 * 7.2)
		local discriminant = speed * speed - 2 * 196.2 * riseStuds
		assert(discriminant > 0, "Expert rise exceeds ordinary jump")
		local reach = 16 * (speed + math.sqrt(discriminant)) / 196.2
		assert(reach - distance >= .45, "Expert flight lacks .45-stud ideal reach margin")
		table.insert(arch, at(from, start, "Walk", family))
		local arrival = at(to, stop, "Jump", family)
		arrival.gapStuds, arrival.riseStuds = math.max(0, distance - 2 * INSET), riseStuds
		table.insert(arch, arrival)
		table.insert(transfers, {group = "ExpertPhase3", name = "ArchCommit_" .. #transfers + 1,
			from = path(from), to = path(to), fromPoint = start, toPoint = stop, kind = "Jump", requiredJump = true,
			flightStuds = distance, gapStuds = arrival.gapStuds, riseStuds = riseStuds,
			idealReachMargin = reach - distance, obstacleFamily = family})
	end
	local function point(x, y, z) return shift + v(x, y, z) end
	walk(prep, prep.position)
	jump(cp01, rise, point(-57.05, 28, -67.05), point(-57, 32, -60.45), "ExpertRisingCorbel")
	jump(rise, turn, point(-56.05, 32, -57), point(-50.5, 36, -57.95), "ExpertDirectionalLanding")
	walk(turn, point(-51, 36, -57.95))
	walk(turn, point(-51, 36, -50.05))
	jump(turn, beam, point(-51, 36, -48.05), point(-54.5, 40, -42.95), "ExpertRailEntry")
	for _, z in {-32, -11} do jump(beam, beam, point(-54.5, 40, z - 3.8), point(-54.5, 40, z + 3.8), "ExpertBeamHurdle") end
	jump(beam, perch, point(-53.95, 40, 1.95), point(-48.85, 44, 6.05), "ExpertCornerTransfer")
	jump(perch, rail, point(-47.15, 44, 13.95), point(-42, 48, 16.05), "ExpertDirectionalLanding")
	jump(rail, rail, point(-42, 48, 30.2), point(-42, 48, 37.8), "ExpertBeamHurdle")
	jump(rail, merge, point(-42, 48, 45.95), merge.position + v(0, 0, -merge.size.Z / 2 + INSET), "ExpertSharedMerge")
	walk(merge, merge.position)
	local kept = {}
	for _, transfer in Layout.Transfers do
		if string.find(transfer.from or "", "/ArchExpert/", 1, true) then continue end
		for _, entry in {{"from", "fromPoint"}, {"to", "toPoint"}} do
			local key, pointKey = transfer[entry[1]], entry[2]
			if changed[key] and transfer[pointKey] then
				local offset = originalFrames[key]:PointToObjectSpace(transfer[pointKey])
				transfer[pointKey] = frame(floors[key]):PointToWorldSpace(fit(floors[key], offset))
			end
		end
		if transfer.fromPoint and transfer.toPoint then
			transfer.flightStuds = v(transfer.toPoint.X - transfer.fromPoint.X, 0, transfer.toPoint.Z - transfer.fromPoint.Z).Magnitude
			transfer.riseStuds = transfer.toPoint.Y - transfer.fromPoint.Y
		end
		table.insert(kept, transfer)
	end
	for _, transfer in transfers do table.insert(kept, transfer) end
	Layout.Transfers = kept
	Layout.SupportingObstacleData = {floors = floors, changed = changed, archRoute = arch, footprintHalfStuds = FOOTPRINT}
	Layout.BranchCosts.Arches.expert = "Six four-stud commitments, 3.2/3.6-stud rails, directional corbels and three 2.8-stud hurdle tops; rejoins before the shared cloister."
	Layout.BranchCosts.Lanterns.expert = "Three 3-stud timed landings, raised offset exits and narrow hurdle rails through the centre of each swing."
	Layout.BranchCosts.UpperLift.expert = "Five narrow raised landings and short directional transfers into later boarding/earlier exit, retaining the upper lift."
	return Layout.SupportingObstacleData
end

function SupportingObstacles.EnrichRoute(Layout, source)
	local data = assert(Layout.SupportingObstacleData, "Apply Phase3 obstacle tuning before route generation")
	local route, archInserted, archBlock = {}, false, false
	for _, original in source do
		local isArch = string.find(original.path or "", "/ArchExpert/", 1, true) ~= nil
		if isArch then
			if not archInserted then for _, node in data.archRoute do table.insert(route, table.clone(node)) end end
			archInserted, archBlock = true, true
			continue
		end
		if archBlock and original.path == "Obstacles/ArchNormal/ArchMerge/Contact" then continue end
		archBlock = false
		local node = table.clone(original)
		if data.changed[node.path] and node.offset then node.offset = fit(data.floors[node.path], node.offset) end
		table.insert(route, node)
	end
	local hazards = {}
	for _, hazard in Layout.RouteHazards do
		if hazard.difficulty == "Expert" then continue end
		local entries = hazards[hazard.surfacePath] or {}
		table.insert(entries, hazard)
		hazards[hazard.surfacePath] = entries
	end
	local result, inserted = {}, {}
	for _, node in route do
		local entries = hazards[node.path]
		if not entries or node.kind ~= "Walk" or node.offset then table.insert(result, node); continue end
		if inserted[node.path] then continue end
		inserted[node.path] = true
		local floor = data.floors[node.path]
		for _, hazard in entries do
			local position = frame(floor):PointToObjectSpace(hazard.frame.Position)
			local x = if hazard.kind == "WeaveGate" then -hazard.side * (floor.size.X - hazard.openingWidth) / 2 else 0
			for index, offset in {v(x, 0, position.Z + 3.6), v(x, 0, position.Z - 3.6)} do
				local goal = table.clone(node)
				goal.offset = offset
				goal.kind = if hazard.kind == "Hurdle" and index == 2 then "Jump" else "Walk"
				goal.requiredJump = if goal.kind == "Jump" then true else nil
				goal.obstacleFamily, goal.hazardName = if hazard.kind == "Hurdle" then "05_RedHurdles" else "NormalWeave", hazard.name
				goal.gapStuds, goal.riseStuds = nil, if goal.kind == "Jump" then 0 else nil
				table.insert(result, goal)
			end
		end
	end
	return result
end

function SupportingObstacles.SupportMargins(Layout, route)
	local data, records = assert(Layout.SupportingObstacleData), {}
	for index, node in route do
		if not data.changed[node.path] and not string.find(node.path or "", "/ArchExpert/", 1, true)
			and node.obstacleFamily ~= "ExpertSharedMerge" and node.obstacleFamily ~= "ExpertRisingCorbel" then continue end
		if not node.offset then continue end
		local floor = data.floors[node.path]
		table.insert(records, {index = index, path = node.path, kind = node.kind, offset = node.offset,
			xMargin = floor.size.X / 2 - math.abs(node.offset.X) - FOOTPRINT,
			zMargin = floor.size.Z / 2 - math.abs(node.offset.Z) - FOOTPRINT})
	end
	return records
end

return SupportingObstacles
