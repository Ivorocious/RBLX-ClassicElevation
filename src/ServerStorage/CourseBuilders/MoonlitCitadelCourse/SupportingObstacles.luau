--!nonstrict
local RouteHazardGoals = require(script.Parent.RouteHazardGoals)
local SupportingObstacles = {}

function SupportingObstacles.Apply(Layout)
	assert(not Layout.SupportingObstacleData, "Obstacle support records already initialized")
	local floors = {}
	for _, floor in Layout.Surfaces do
		local path = "Obstacles/" .. floor.group .. "/" .. floor.name .. "/Contact"
		assert(not floors[path], "Duplicate contact " .. path)
		floors[path] = floor
	end
	-- Geometry and transfers come from their author; this module never repairs them by moving floors.
	Layout.SupportingObstacleData = {floors = floors, changed = {}, footprintHalfStuds = 1}
	return Layout.SupportingObstacleData
end

function SupportingObstacles.EnrichRoute(Layout, source)
	assert(Layout.SupportingObstacleData, "Initialize obstacle support records first")
	return RouteHazardGoals(Layout, source)
end

function SupportingObstacles.SupportMargins(Layout, route)
	local floors, records = assert(Layout.SupportingObstacleData).floors, {}
	for index, node in route do
		local floor = floors[node.path]
		if not floor or node.kind == "Ride" then continue end
		local offset = node.offset or Vector3.zero
		table.insert(records, {index = index, path = node.path, kind = node.kind, offset = offset,
			xMargin = floor.size.X / 2 - math.abs(offset.X) - 1,
			zMargin = floor.size.Z / 2 - math.abs(offset.Z) - 1})
	end
	return records
end

return SupportingObstacles
