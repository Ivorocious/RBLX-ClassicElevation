--!nonstrict
local Check = {}
local function xyz(point) return {point.X, point.Y, point.Z} end
local function count(values)
	local result = 0
	for _ in values do result += 1 end
	return result
end

function Check.Static(layout, sourceHash)
	assert(type(sourceHash) == "string" and #sourceHash == 64 and sourceHash:match("^%x+$"), "Literal final source SHA-256 required")
	local floors = {}
	for _, data in layout.Surfaces do
		local path = "Obstacles/" .. data.group .. "/" .. data.name .. "/Contact"
		assert(not floors[path], "Duplicate contact " .. path)
		floors[path] = data
	end
	local report = {sourceHash = sourceHash, evidence = "Source recipe geometry only", nativePhysicsProof = false,
		humanPacingProof = false, routes = {}, issues = {}, tightJumps = {}, contacts = #layout.Surfaces,
		distanceScope = "Fixed-support goal segments only; Ride resets to its fixed exit. Boarding/deck movement and ride displacement are excluded; this is not total travel or timing."}
	local function point(node)
		local floor = assert(floors[node.path], "No source support " .. tostring(node.path))
		local offset = node.offset or Vector3.zero
		assert(math.abs(offset.X) <= floor.size.X/2 + .01 and math.abs(offset.Z) <= floor.size.Z/2 + .01,
			"Foot goal leaves support " .. node.path)
		return (floor.frame or CFrame.new(floor.position)):PointToWorldSpace(offset)
	end
	local jumpVelocity = math.sqrt(2 * 196.2 * 7.2)
	for mask = 0, 7 do
		local choices, name = {}, ""
		for index = 1, 3 do
			choices[index] = bit32.band(mask, bit32.lshift(1, 3-index)) ~= 0
			name ..= if choices[index] then "E" else "N"
		end
		local route = layout.GetRoute(choices, {1, 2})
		local entry = {name = name, nodes = #route, fixedGoalHorizontalStuds = 0, jumpGoals = 0, orderedCheckpoints = {}, rides = {}, lanternBands = {}}
		local previous, previousNode, lastCheckpoint
		for index, node in route do
			if node.kind == "Ride" then
				local stage = assert(node.path:match("/MovingCars/(%a+)_Bay%d/Deck$"))
				assert(not entry.rides[stage], "Duplicate ride stage")
				assert(node.boardHeight and node.exitHeight and node.exitPath, "Incomplete ride")
				point({path = node.waitPath, offset = node.waitOffset})
				entry.rides[stage] = {path = node.path, boardHeight = node.boardHeight, exitHeight = node.exitHeight}
				previous = point({path = node.exitPath, offset = node.exitOffset})
			else
				assert(node.kind == "Walk" or node.kind == "Jump", "Unknown node kind")
				local target = point(node)
				if previous then
					local distance = Vector3.new(target.X-previous.X, 0, target.Z-previous.Z).Magnitude
					entry.fixedGoalHorizontalStuds += distance
					if node.kind == "Jump" then
						local rise = target.Y-previous.Y
						local discriminant = jumpVelocity*jumpVelocity - 2*196.2*rise
						local reach = if discriminant >= 0 then 16*(jumpVelocity + math.sqrt(discriminant))/196.2 else 0
						local check = {route = name, index = index, fromIndex = index-1, fromPath = previousNode and previousNode.path,
							toPath = node.path, name = node.name, flightStuds = distance, riseStuds = rise, theoreticalMargin = reach-distance,
							from = xyz(previous), to = xyz(target), family = node.obstacleFamily}
						if reach < distance then table.insert(report.issues, check) end
						if reach-distance < 1.25 then table.insert(report.tightJumps, check) end
					end
				end
				previous = target
			end
			if node.kind == "Jump" then entry.jumpGoals += 1 end
			if node.lanternBand then entry.lanternBands[node.lanternBand] = true end
			if node.checkpoint and node.checkpoint ~= lastCheckpoint then
				assert(node.checkpoint == #entry.orderedCheckpoints+1, "Source checkpoint order changed")
				table.insert(entry.orderedCheckpoints, node.checkpoint); lastCheckpoint = node.checkpoint
			end
			previousNode = node
		end
		assert(#entry.orderedCheckpoints == 4 and entry.rides.Lower and entry.rides.Upper, "Route omits shared requirements")
		assert(entry.lanternBands[1] and entry.lanternBands[2] and entry.lanternBands[3], "Route omits a moving band")
		assert(route[#route].finish == true, "Route lacks crown finish")
		table.insert(report.routes, entry)
	end
	table.sort(report.tightJumps, function(a, b) return a.theoreticalMargin < b.theoreticalMargin end)
	report.ok = #report.issues == 0
	return report
end

function Check.Resources(course, meshTriangles, baselineCounts)
	assert(course and course:IsA("Model"), "Actual integrated course model required")
	meshTriangles = meshTriangles or {}
	local report = {candidate = course:GetAttribute("CandidateId"), course = course:GetFullName(),
		scope = "Actual placed course inventory; known imported triangles exclude native primitives, collision hulls and renderer LOD",
		counts = {baseParts = 0, meshParts = 0, colliders = 0, touchParts = 0, queryParts = 0, lights = 0,
			enabledLights = 0, shadowedLights = 0, visibleShadowCasters = 0, knownPlacedTriangles = 0},
		meshIds = {}, unknownTriangleIds = {}, colliderRoles = {}, cameraAffectedChoices = {
			"Normal west tower wraps", "Expert inner arches", "Normal lantern entries/exits", "Expert three-stud gallery contacts",
			"CP04 Normal corner and rear approach", "Expert outward brace wait and early exit in both bays", "Both catch returns", "Final crown arrival"},
		cameraProof = "Lead must inspect forward, reverse and landing views in daylight and final night",
		performanceProof = false, deviceProof = false, multiplayerThroughputProof = false}
	for _, item in course:GetDescendants() do
		local counts = report.counts
		if item:IsA("BasePart") then
			counts.baseParts += 1
			if item.CanCollide then
				counts.colliders += 1
				local role = tostring(item:GetAttribute("Role") or "Unlabelled")
				report.colliderRoles[role] = (report.colliderRoles[role] or 0)+1
			end
			if item.CanTouch then counts.touchParts += 1 end
			if item.CanQuery then counts.queryParts += 1 end
			if item.CastShadow and item.Transparency < 1 then counts.visibleShadowCasters += 1 end
		end
		if item:IsA("MeshPart") then
			counts.meshParts += 1
			local id = item.MeshId
			report.meshIds[id] = (report.meshIds[id] or 0)+1
			local triangles = meshTriangles[id]
			if type(triangles) == "number" then counts.knownPlacedTriangles += triangles
			else report.unknownTriangleIds[id] = (report.unknownTriangleIds[id] or 0)+1 end
		elseif item:IsA("Light") then
			counts.lights += 1
			if item.Enabled then counts.enabledLights += 1 end
			if item.Shadows then counts.shadowedLights += 1 end
		end
	end
	report.counts.uniqueMeshIds = count(report.meshIds)
	report.triangleMappingComplete = count(report.unknownTriangleIds) == 0
	if baselineCounts then
		report.delta = {}
		for name, value in report.counts do
			if type(baselineCounts[name]) == "number" then report.delta[name] = value-baselineCounts[name] end
		end
	end
	return report
end

return Check
