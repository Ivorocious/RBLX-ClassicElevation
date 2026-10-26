--!nonstrict
local Check = {}
local Up = Vector3.yAxis

local function box(id, frame, size)
	return {id = id, frame = frame, size = size,
		axes = {frame.RightVector, frame.UpVector, -frame.LookVector}, half = {size.X / 2, size.Y / 2, size.Z / 2}}
end

local function overlaps(a, b)
	local delta = b.frame.Position - a.frame.Position
	local function separated(axis)
		if axis.Magnitude < .00001 then return false end
		local radius = 0
		for i = 1, 3 do
			radius += math.abs(axis:Dot(a.axes[i])) * a.half[i] + math.abs(axis:Dot(b.axes[i])) * b.half[i]
		end
		return math.abs(delta:Dot(axis)) >= radius - .001
	end
	for i = 1, 3 do if separated(a.axes[i]) or separated(b.axes[i]) then return false end end
	for _, aa in a.axes do for _, ba in b.axes do if separated(aa:Cross(ba)) then return false end end end
	return true
end

local function strip(id, a, b, width, low, high)
	local delta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	if delta.Magnitude < .05 then return nil end
	local center = Vector3.new((a.X + b.X) / 2, (low + high) / 2, (a.Z + b.Z) / 2)
	return box(id, CFrame.lookAt(center, center + delta), Vector3.new(width, high - low, delta.Magnitude + 2))
end

local function view(id, a, b)
	if (b - a).Magnitude < .05 then return nil end
	return box(id, CFrame.lookAt((a + b) / 2, b), Vector3.new(1, .7, (b - a).Magnitude))
end

local function pathOf(surface)
	return "Obstacles/" .. surface.group .. "/" .. surface.name .. "/Contact"
end

local function expandedBounds(id, frame, size, margin)
	local radius = Vector3.zero
	for i, axis in {frame.RightVector, frame.UpVector, -frame.LookVector} do
		local extent = if i == 1 then size.X / 2 elseif i == 2 then size.Y / 2 else size.Z / 2
		radius += Vector3.new(math.abs(axis.X), math.abs(axis.Y), math.abs(axis.Z)) * extent
	end
	return box(id, CFrame.new(frame.Position), (radius + Vector3.one * margin) * 2)
end

function Check.Run(layout, occupied, options)
	options, occupied = options or {}, occupied or {}
	local findings, volumes, surfaces, floors, bodies, adjacency, seen = {}, {}, {}, {}, {}, {}, {}
	local counts = {surfaces = #layout.Surfaces, occupied = #occupied, standing = 0, route = 0, mechanism = 0}
	local function finding(kind, first, second, message)
		local key = kind .. "|" .. first .. "|" .. second
		if seen[key] then return end
		seen[key] = true
		table.insert(findings, {kind = kind, first = first, second = second, message = message})
	end
	local function insert(volume, category)
		if volume then table.insert(volumes, volume); counts[category] += 1 end
	end
	for _, surface in layout.Surfaces do
		local path = pathOf(surface)
		local frame = surface.frame or CFrame.new(surface.position)
		surfaces[path] = surface
		floors[path] = box(path, frame * CFrame.new(0, -surface.size.Y / 2, 0), surface.size)
		local low, high = Vector3.one * math.huge, Vector3.one * -math.huge
		for _, x in {-surface.size.X / 2, surface.size.X / 2} do
			for _, z in {-surface.size.Z / 2, surface.size.Z / 2} do
				local p = frame:PointToWorldSpace(Vector3.new(x, 0, z))
				low = Vector3.new(math.min(low.X, p.X), math.min(low.Y, p.Y), math.min(low.Z, p.Z))
				high = Vector3.new(math.max(high.X, p.X), math.max(high.Y, p.Y), math.max(high.Z, p.Z))
			end
		end
		low, high = low - Vector3.new(1, -.05, 1), high + Vector3.new(1, 7, 1)
		bodies[path] = box("Standing:" .. path, CFrame.new((low + high) / 2), high - low)
		insert(bodies[path], "standing")
	end
	local function point(node)
		local surface = surfaces[node.path]
		if not surface then return nil end
		return (surface.frame or CFrame.new(surface.position)):PointToWorldSpace(node.offset or Vector3.zero)
	end
	local routeEdges = {}
	local function addRoute(route)
		for i = 2, #route do
			local previous, node = route[i - 1], route[i]
			adjacency[previous.path .. ">" .. node.path], adjacency[node.path .. ">" .. previous.path] = true, true
			local a, b = point(previous), point(node)
			if not a or not b or node.drop or node.kind == "Ride" or previous.kind == "Ride" then continue end
			local delta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
			if delta.Magnitude < .2 then continue end
			local key = previous.path .. tostring(previous.offset) .. ">" .. node.path .. tostring(node.offset)
			if routeEdges[key] then continue end
			routeEdges[key] = true
			local jump = node.kind == "Jump"
			local id = (if jump then "Jump:" else "Walk:") .. key
			insert(strip(id, a, b, 6.5, math.min(a.Y, b.Y) + .05,
				math.max(a.Y, b.Y) + (if jump then 15 else 7)), "route")
			for directionIndex, ends in {{a, b}, {b, a}} do
				local start, finish = ends[1], ends[2]
				local direction = Vector3.new(finish.X - start.X, 0, finish.Z - start.Z).Unit
				local rearStart, rearFinish = start - direction * 11, finish - direction * 11
				local cameraId = "Camera" .. directionIndex .. ":" .. id
				insert(strip(cameraId, rearStart, rearFinish, 8, math.min(a.Y, b.Y) + 3,
					math.max(a.Y, b.Y) + (if jump then 18.2 else 11)), "route")
				for _, shoulder in {-2, 0, 2} do
					insert(view("View" .. directionIndex .. ":" .. shoulder .. ":" .. id,
						rearStart + Up * 7 + direction:Cross(Up) * shoulder, finish + Up * .7), "route")
				end
			end
		end
	end
	for mask = 0, 7 do
		local choices = {bit32.band(mask, 1) ~= 0, bit32.band(mask, 2) ~= 0, bit32.band(mask, 4) ~= 0}
		addRoute(layout.GetRoute(choices, {1, 2}))
		if choices[3] then addRoute(layout.GetRoute(choices, {2, 1})) end
	end
	if layout.GetCatchRoute then addRoute(layout.GetCatchRoute("Arch")); addRoute(layout.GetCatchRoute("Upper")) end
	for path, body in bodies do
		for otherPath, floor in floors do
			if path == otherPath or adjacency[path .. ">" .. otherPath] then continue end
			local first, second = surfaces[path], surfaces[otherPath]
			if first.group == "RecoveryPockets" or second.group == "RecoveryPockets" then continue end
			if second.position.Y <= first.position.Y + .35 then continue end
			if overlaps(body, floor) then
				finding("RouteBody", path, otherPath, "Nonadjacent floor intrudes into supported standing/headroom volume")
			end
		end
	end
	for _, lantern in layout.Lanterns or {} do
		for degrees = -32, 32, 2 do
			local frame = CFrame.new(lantern.pivot) * CFrame.fromAxisAngle(lantern.axis, math.rad(degrees))
				* CFrame.new(lantern.point - lantern.pivot)
			insert(expandedBounds("Lantern:" .. lantern.name .. ":" .. degrees, frame, Vector3.new(4, 7, 4), 2), "mechanism")
		end
	end
	for stage, origin in layout.LiftOrigins or {} do
		for bay, x in {-9, 9} do
			insert(box("Lift:" .. stage .. ":Bay" .. bay, CFrame.new(origin + Vector3.new(x, 24.725, 0)),
				Vector3.new(18, 54.95, 16)), "mechanism")
			local weightX = if bay == 1 then -27 else 27
			insert(box("Weight:" .. stage .. ":Bay" .. bay, CFrame.new(origin + Vector3.new(weightX, 22, 0)),
				Vector3.new(8, 46, 6.5)), "mechanism")
		end
	end
	for _, data in occupied do
		assert(type(data.id) == "string" and typeof(data.frame) == "CFrame" and typeof(data.size) == "Vector3",
			"Occupied proxy needs id, course-local frame and size")
		local solid = box(data.id, data.frame, data.size)
		if data.walkableTop then
			local support = assert(surfaces[data.supportPath], "Top skin needs its actual supported contact")
			local frame = support.frame or CFrame.new(support.position)
			for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
				local p = frame:PointToObjectSpace(data.frame:PointToWorldSpace(data.size * Vector3.new(x, y, z) / 2))
				if p.Y >= -.1 and (math.abs(p.X) > support.size.X / 2 + .35
					or math.abs(p.Z) > support.size.Z / 2 + .35 or p.Y > .1) then
					finding("MisleadingSkin", data.id, data.supportPath, "Visible top exceeds supported footprint/height tolerance")
				end
			end end end
		end
		if not data.walkableTop then
			for _, volume in volumes do
				if data.allowVolumes and data.allowVolumes[volume.id] then continue end
				if overlaps(solid, volume) then
					finding("WorldIntrusion", data.id, volume.id, "Occupied art intersects protected route/view/mechanism space")
				end
			end
		end
	end
	local report = {geometryPass = #findings == 0, worldRepresented = #occupied > 0, counts = counts, findings = findings,
		limits = "Geometry screen only; hollow occupied proxies and full world coverage required; native movement/views/shortcuts remain separate"}
	if options.returnVolumes then report.volumes = volumes end
	return report
end

return Check
