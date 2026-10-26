--!nonstrict
return function(Layout, route)
	local floors, byPath = {}, {}
	for _, floor in Layout.Surfaces do floors["Obstacles/" .. floor.group .. "/" .. floor.name .. "/Contact"] = floor end
	for _, hazard in Layout.RouteHazards or {} do
		local entries = byPath[hazard.surfacePath] or {}
		table.insert(entries, hazard)
		byPath[hazard.surfacePath] = entries
	end
	local result, inserted = {}, {}
	local function goal(node, floor, hazard, hazardOffset, jump)
		local basis = floor.frame or CFrame.new(floor.position)
		local offset = basis:PointToObjectSpace(hazard.frame:PointToWorldSpace(hazardOffset))
		assert(math.abs(offset.X) + 1.05 <= floor.size.X / 2 + .001
			and math.abs(offset.Z) + 1.05 <= floor.size.Z / 2 + .001, "Red obstacle goal lacks foot support " .. hazard.name)
		local copy = table.clone(node)
		copy.offset, copy.kind, copy.requiredJump = offset, if jump then "Jump" else "Walk", jump == true
		copy.hazardName, copy.hazardEnriched = hazard.name, true
		copy.obstacleFamily = hazard.kind
		copy.gapStuds, copy.riseStuds, copy.flightStuds = nil, if jump then 0 else nil, if jump then hazard.approachStuds * 2 else nil
		table.insert(result, copy)
	end
	for _, node in route do
		local entries = byPath[node.path]
		if not entries or node.kind ~= "Walk" or node.offset or node.hazardEnriched then
			table.insert(result, table.clone(node))
			continue
		end
		if inserted[node.path] then continue end
		inserted[node.path] = true
		local floor = assert(floors[node.path])
		for _, hazard in entries do
			local x = if hazard.kind == "CrenelWeave" then -hazard.side * (hazard.size.X - hazard.openingWidth) / 2 else 0
			local distance, direction = hazard.approachStuds, hazard.direction
			goal(node, floor, hazard, Vector3.new(x, 0, -direction * distance), false)
			goal(node, floor, hazard, Vector3.new(x, 0, direction * distance),
				hazard.kind == "Hurdle" or hazard.kind == "TallHurdle" or hazard.kind == "FloorBand")
		end
	end
	return result
end
