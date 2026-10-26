--!nonstrict
local Clearance = {}
local prepared = setmetatable({}, {__mode = "k"})
local Up = Vector3.yAxis
local BodyHeight = 6.5
local AirborneHeight = 14.5
local Margin = .12

local function axes(frame)
	return {frame.RightVector, frame.UpVector, -frame.LookVector}
end

local function box(frame, size, reason)
	local directions, half = axes(frame), size / 2
	local radius = Vector3.new(
		math.abs(directions[1].X) * half.X + math.abs(directions[2].X) * half.Y + math.abs(directions[3].X) * half.Z,
		math.abs(directions[1].Y) * half.X + math.abs(directions[2].Y) * half.Y + math.abs(directions[3].Y) * half.Z,
		math.abs(directions[1].Z) * half.X + math.abs(directions[2].Z) * half.Y + math.abs(directions[3].Z) * half.Z)
	return {frame = frame, half = {half.X, half.Y, half.Z}, axes = directions, low = frame.Position - radius,
		high = frame.Position + radius, reason = reason}
end

local function boundsOverlap(a, b)
	return a.low.X <= b.high.X and a.high.X >= b.low.X and a.low.Y <= b.high.Y and a.high.Y >= b.low.Y
		and a.low.Z <= b.high.Z and a.high.Z >= b.low.Z
end

local function boxesOverlap(a, b)
	if not boundsOverlap(a, b) then return false end
	local delta = b.frame.Position - a.frame.Position
	local function separates(axis)
		if axis.Magnitude < .00001 then return false end
		local radius = 0
		for index = 1, 3 do
			radius += math.abs(axis:Dot(a.axes[index])) * a.half[index]
				+ math.abs(axis:Dot(b.axes[index])) * b.half[index]
		end
		return math.abs(delta:Dot(axis)) > radius + .00001
	end
	for index = 1, 3 do
		if separates(a.axes[index]) or separates(b.axes[index]) then return false end
	end
	for _, aAxis in a.axes do
		for _, bAxis in b.axes do if separates(aAxis:Cross(bAxis)) then return false end end
	end
	return true
end

local function feet(surfaces, node)
	local surface = surfaces[node.path]
	if not surface then return nil end
	local frame = surface.frame or CFrame.new(surface.position)
	return frame:PointToWorldSpace(node.offset or Vector3.zero)
end

local function horizontalBox(a, b, width, lowY, highY, reason)
	local delta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	if delta.Magnitude < .05 then return nil end
	local center = Vector3.new((a.X + b.X) / 2, (lowY + highY) / 2, (a.Z + b.Z) / 2)
	return box(CFrame.lookAt(center, center + delta), Vector3.new(width, highY - lowY, delta.Magnitude + 2), reason)
end

local function sightline(a, b, reason)
	local delta = b - a
	if delta.Magnitude < .05 then return nil end
	return box(CFrame.lookAt((a + b) / 2, b), Vector3.new(3, .7, delta.Magnitude), reason)
end

function Clearance.Prepare(layout)
	local corridors, surfaces, seen = {}, {}, {}
	for _, surface in layout.Surfaces do
		local path = "Obstacles/" .. surface.group .. "/" .. surface.name .. "/Contact"
		surfaces[path] = surface
		local frame = surface.frame or CFrame.new(surface.position)
		-- Protect the complete supported footprint, including side waits and recovery pockets.
		local low, high = Vector3.one * math.huge, Vector3.one * -math.huge
		for _, x in {-surface.size.X / 2, surface.size.X / 2} do
			for _, z in {-surface.size.Z / 2, surface.size.Z / 2} do
				local point = frame:PointToWorldSpace(Vector3.new(x, 0, z))
				low = Vector3.new(math.min(low.X, point.X), math.min(low.Y, point.Y), math.min(low.Z, point.Z))
				high = Vector3.new(math.max(high.X, point.X), math.max(high.Y, point.Y), math.max(high.Z, point.Z))
			end
		end
		low, high = low - Vector3.new(1, 0, 1), high + Vector3.new(1, BodyHeight, 1)
		table.insert(corridors, box(CFrame.new((low + high) / 2), high - low, "Standing " .. path))
	end
	local function addRoute(route)
		for index = 2, #route do
			local previous, node = route[index - 1], route[index]
			local a, b = feet(surfaces, previous), feet(surfaces, node)
			if not a or not b or node.drop then continue end
			local delta = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
			if delta.Magnitude < .2 then continue end
			local key = previous.path .. tostring(previous.offset) .. ">" .. node.path .. tostring(node.offset)
			if seen[key] then continue end
			seen[key] = true
			local jump = node.kind == "Jump"
			local reason = (if jump then "Jump " else "Walk ") .. previous.path .. ">" .. node.path
			table.insert(corridors, horizontalBox(a, b, 6.5, math.min(a.Y, b.Y) + .05,
				math.max(a.Y, b.Y) + (if jump then AirborneHeight else BodyHeight), reason))
			local direction = delta.Unit
			local rearA, rearB = a - direction * 11, b - direction * 11
			table.insert(corridors, horizontalBox(rearA, rearB, 8, math.min(a.Y, b.Y) + 3,
				math.max(a.Y, b.Y) + (if jump then 18.2 else 11), "Camera " .. reason))
			-- A broad camera box does not prove a clear view to the receiving lip.
			for _, shoulder in {-2, 0, 2} do
				local right = direction:Cross(Up)
				local camera = rearA + Up * 7 + right * shoulder
				table.insert(corridors, sightline(camera, b + Up * .7, "Landing sightline " .. reason))
			end
		end
	end
	for mask = 0, 7 do
		local choices = {bit32.band(mask, 1) ~= 0, bit32.band(mask, 2) ~= 0, bit32.band(mask, 4) ~= 0}
		addRoute(layout.GetRoute(choices, {1, 2}))
		if choices[3] then addRoute(layout.GetRoute(choices, {2, 1})) end
	end
	if layout.GetCatchRoute then
		addRoute(layout.GetCatchRoute("Arch"))
		addRoute(layout.GetCatchRoute("Upper"))
	end
	prepared[layout] = corridors
	return #corridors
end

local function archBoxes(frame, scale)
	local result = {}
	-- Forty tight segment boxes enclose the authored annular Stone/StoneLight strips.
	-- Empty space under the arch is not treated as a single solid mesh bounding box.
	for index = 0, 39 do
		local low, high = Vector3.new(math.huge, math.huge, -2.12), Vector3.new(-math.huge, -math.huge, 2.12)
		for _, profile in {{12, 17}, {10, 14.5}, {11.75, 16.8}, {11.27, 16.2}} do
			for _, sample in {index, index + 1} do
				local angle = math.pi * sample / 40
				local x, y = -profile[1] * math.cos(angle), profile[2] * math.sin(angle)
				low = Vector3.new(math.min(low.X, x), math.min(low.Y, y), low.Z)
				high = Vector3.new(math.max(high.X, x), math.max(high.Y, y), high.Z)
			end
		end
		low, high = (low - Vector3.one * Margin) * scale, (high + Vector3.one * Margin) * scale
		table.insert(result, box(frame * CFrame.new((low + high) / 2), high - low, "Arch segment " .. index))
	end
	return result
end

function Clearance.Suggest(layout, arch)
	local corridors = prepared[layout]
	if not corridors then Clearance.Prepare(layout); corridors = prepared[layout] end
	local delta = Vector3.new(arch.b.X - arch.a.X, 0, arch.b.Z - arch.a.Z)
	assert(delta.Magnitude > .1 and arch.width > 0, "Arch needs a nonzero span and width")
	local midpoint = (arch.a + arch.b) / 2
	local yaw = CFrame.Angles(0, math.atan2(-delta.Z, delta.X), 0)
	local crownY = math.min(arch.a.Y, arch.b.Y) - 1.35
	local firstReason
	for _, heightScale in {1, .75, .55} do
		local scale = Vector3.new(delta.Magnitude / 24, heightScale, arch.width / 4)
		local frame = CFrame.new(midpoint.X, crownY - 17 * heightScale, midpoint.Z) * yaw
		local pieces = archBoxes(frame, scale)
		local blocked
		for _, corridor in corridors do
			for _, piece in pieces do
				if boxesOverlap(piece, corridor) then blocked = corridor.reason; break end
			end
			if blocked then break end
		end
		if not blocked then
			return {frame = frame, scale = scale}, if heightScale == 1 then "Full-height arch below its span"
				else "Shortened to " .. tostring(heightScale) .. "; crown anchored below span; original conflict: " .. tostring(firstReason)
		end
		firstReason = firstReason or blocked
	end
	return nil, "Omit decorative arch: " .. tostring(firstReason)
end

return Clearance
