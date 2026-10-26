--!nonstrict

local Integration = {}
local BOUNDS_OFFSET = Vector3.new(-15, 80, 0)
local BOUNDS_SIZE = Vector3.new(490, 230, 420)
local FALL_Y_OFFSET = -23
local FALL_ZONES = {
	BelowPlayableRoute = {point = Vector3.new(-15, -25, 0), size = Vector3.new(502, 4, 432)},
	OutsideWest = {point = Vector3.new(-262, 80, 0), size = Vector3.new(4, 230, 432)},
	OutsideEast = {point = Vector3.new(232, 80, 0), size = Vector3.new(4, 230, 432)},
	OutsideNorth = {point = Vector3.new(-15, 80, -212), size = Vector3.new(502, 230, 4)},
	OutsideSouth = {point = Vector3.new(-15, 80, 212), size = Vector3.new(502, 230, 4)},
}

local function resolve(root, path)
	local found = root
	for name in string.gmatch(path, "[^/]+") do found = found and found:FindFirstChild(name) end
	assert(found and found:IsA("BasePart"), "Missing part " .. path)
	return found
end

local function sameVector(left, right)
	return typeof(left) == "Vector3" and (left - right).Magnitude < .02
end

local function guardCourse(course)
	assert(course:IsA("Model") and course:GetAttribute("CourseId") == "moonlit_citadel"
		and course:GetAttribute("MoonlitCourse") == true, "Explicit Moonlit course required")
end

local function insideBounds(point, center, size, padding)
	local delta, half = point - center, size / 2 - Vector3.one * (padding or 0)
	return math.abs(delta.X) <= half.X and math.abs(delta.Y) <= half.Y and math.abs(delta.Z) <= half.Z
end

local function guardCorners(part, center, size, padding)
	for _, x in {-1, 1} do
		for _, y in {-1, 1} do
			for _, z in {-1, 1} do
				local corner = part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2)
				assert(insideBounds(corner, center, size, padding), "Course bounds cut through " .. part:GetFullName())
			end
		end
	end
end

function Integration.ApplyCoverage(course, origin)
	guardCourse(course)
	assert(typeof(origin) == "Vector3", "Course origin required")
	local bound = resolve(course, "Bounds/CourseBounds")
	local folder = course:FindFirstChild("FallZones")
	assert(folder and folder:IsA("Folder") and #folder:GetChildren() == 5, "Preserve the five original fall zones")
	for name in FALL_ZONES do
		local part = resolve(folder, name)
		assert(part:GetAttribute("MoonlitHazard") ~= true and part:GetAttribute("HazardType") == nil,
			"Fall coverage must remain separate from on-course contacts")
	end
	bound.CFrame, bound.Size = CFrame.new(origin + BOUNDS_OFFSET), BOUNDS_SIZE
	bound.Transparency, bound.CanCollide, bound.CanTouch, bound.CanQuery = 1, false, false, false
	course:SetAttribute("BoundsCenter", bound.Position)
	course:SetAttribute("BoundsSize", bound.Size)
	course:SetAttribute("FallY", origin.Y + FALL_Y_OFFSET)
	for name, data in FALL_ZONES do
		local part = resolve(folder, name)
		part.CFrame, part.Size = CFrame.new(origin + data.point), data.size
		part.Anchored, part.Transparency, part.CanCollide, part.CanTouch, part.CanQuery = true, 1, false, true, true
		part:SetAttribute("Role", "FallReset")
		assert(part:GetAttribute("MoonlitHazard") ~= true and part:GetAttribute("HazardType") == nil,
			"Fall coverage must remain separate from on-course contacts")
	end
end

function Integration.ValidateCourse(course, layout, origin, minimumPocketCapacity)
	guardCourse(course)
	local center, size = origin + BOUNDS_OFFSET, BOUNDS_SIZE
	assert(sameVector(course:GetAttribute("BoundsCenter"), center) and sameVector(course:GetAttribute("BoundsSize"), size), "Wrong recovery bounds")
	assert(course:GetAttribute("FallY") == origin.Y - 23, "Original sky-fall height changed")
	local bound = resolve(course, "Bounds/CourseBounds")
	assert(sameVector(bound.Position, center) and sameVector(bound.Size, size), "Bounds part and metadata disagree")
	local folder = course:FindFirstChild("FallZones")
	assert(folder and #folder:GetChildren() == 5, "Expected exactly five invisible fall zones")
	for name, data in FALL_ZONES do
		local part = resolve(folder, name)
		assert(sameVector(part.Position, origin + data.point) and sameVector(part.Size, data.size), "Wrong fall coverage: " .. name)
		assert(part.Transparency == 1 and part.CanTouch and not part.CanCollide
			and part:GetAttribute("Role") == "FallReset" and part:GetAttribute("MoonlitHazard") ~= true
			and part:GetAttribute("HazardType") == nil, "Fall/reset identity changed: " .. name)
	end
	assert(#course.Checkpoints:GetChildren() == 4, "Expected ordered CP01 through CP04")
	local report = {pockets = {}, cars = 0, lanterns = 0, checkedGameplayParts = 0, warnings = {}}
	local start, finish = resolve(course, "Start"), resolve(course, "Finish")
	assert(sameVector(start.Position, origin + layout.StartPoint + Vector3.new(0, 3, 0)), "Start trigger was not relocated")
	assert(sameVector(finish.Position, origin + layout.FinishPoint + Vector3.new(0, 3, 0)), "Finish trigger was not relocated")
	for index = 1, 4 do
		local data = layout[string.format("CP%02d", index)]
		local cp = resolve(course.Checkpoints, string.format("Checkpoint_%03d", index))
		assert(cp:GetAttribute("CheckpointIndex") == index and cp.CanTouch, "Checkpoint order/contact changed")
		assert(sameVector(cp.Position, origin + data.point + Vector3.new(0, 3, 0)), "Checkpoint trigger was not relocated")
		assert(cp:GetAttribute("RespawnPocketPath") == data.pocketSupport, "Checkpoint pocket link changed")
		local frame, area = cp:GetAttribute("RespawnCFrame"), cp:GetAttribute("RespawnAreaSize")
		assert(typeof(frame) == "CFrame" and sameVector(frame.Position, origin + data.pocket + Vector3.new(0, 4, 0)), "Respawn was not relocated")
		assert(typeof(area) == "Vector3" and area.X >= 6 and area.Z >= 6, "Respawn area missing")
		local pocket = resolve(course, data.pocketSupport)
		assert(pocket.Anchored and pocket.CanCollide and pocket.CanQuery and pocket.CFrame.UpVector.Y > .999,
			"Respawn pocket must be a level supported floor")
		assert(sameVector(pocket.CFrame:PointToWorldSpace(Vector3.new(0, pocket.Size.Y / 2, 0)), origin + data.pocket),
			"Respawn pocket floor was not relocated")
		local columns, rows = 1 + math.floor((area.X - 3) / 4.5), 1 + math.floor((area.Z - 3) / 4.5)
		local capacity = columns * rows
		for slot = 0, capacity - 1 do
			local point = frame:PointToWorldSpace(Vector3.new((slot % columns - (columns - 1) / 2) * 4.5, 0,
				(math.floor(slot / columns) - (rows - 1) / 2) * 4.5))
			local localPoint = pocket.CFrame:PointToObjectSpace(point)
			assert(math.abs(localPoint.X) + 1.5 <= pocket.Size.X / 2 and math.abs(localPoint.Z) + 1.5 <= pocket.Size.Z / 2,
				"Respawn slot lacks physical support at CP" .. index)
			assert(insideBounds(point, center, size, 2), "Respawn is outside recovery bounds")
		end
		table.insert(report.pockets, {index = index, capacity = capacity, columns = columns, rows = rows})
		if capacity < 20 then table.insert(report.warnings, "CP" .. index .. " pocket has " .. capacity .. " positions, below 20") end
		if minimumPocketCapacity then assert(capacity >= minimumPocketCapacity, "CP" .. index .. " pocket capacity is too small") end
	end
	for _, name in {"Arch", "Upper"} do
		local links = layout.ReturnRoutes[name]
		for _, key in {"launchPath", "shelfPath", "rejoinPath"} do resolve(course, links[key]) end
		for _, node in layout.GetCatchRoute(name) do resolve(course, node.path) end
	end
	for _, part in course:GetDescendants() do
		if part:IsA("BasePart") and (part:GetAttribute("MCWalkable") == true
			or part:GetAttribute("MoonlitHazard") == true or part:GetAttribute("Role") == "MovingDeck"
			or part:GetAttribute("Role") == "RaceTrigger") then
			guardCorners(part, center, size, 2)
			report.checkedGameplayParts += 1
		end
	end
	for _, car in course.Obstacles.MovingCars:GetChildren() do
		assert(car:IsA("Model") and sameVector(car:GetAttribute("Travel"), Vector3.new(0, 34, 0)), "Accepted lift travel changed")
		assert(car:GetAttribute("CycleSeconds") == 14 and car:GetAttribute("DwellSeconds") == 2, "Accepted lift timing changed")
		local stage, bay = car:GetAttribute("Stage"), car:GetAttribute("Bay")
		assert(layout.LiftOrigins[stage] and (bay == 1 or bay == 2), "Lift stage/bay missing")
		assert(sameVector(car:GetPivot().Position, origin + layout.LiftOrigins[stage] + Vector3.new(if bay == 1 then -9 else 9, 0, 0)), "Lift relocation disagrees with route")
		assert(car:GetAttribute("PhaseSeconds") == (if bay == 1 then 0 else 7), "Accepted second-bay offset changed")
		report.cars += 1
	end
	for _, data in layout.Lanterns do
		local model = course.Obstacles.SwingLanterns:FindFirstChild(data.name)
		assert(model and sameVector(model:GetAttribute("PivotPosition"), origin + data.pivot), "Lantern pivot was not relocated")
		local rest = model:GetAttribute("RestCFrame")
		assert(typeof(rest) == "CFrame" and (rest.Position - model:GetPivot().Position).Magnitude < .02, "Lantern rest was not relocated")
		assert(model:GetAttribute("CycleSeconds") == 6 and model:GetAttribute("SwingAngleDegrees") == 32, "Accepted swing timing/angle changed")
		report.lanterns += 1
	end
	assert(report.cars == 4 and report.lanterns == 3, "Accepted mechanism count changed")
	return report
end

-- Call inside Runtime's existing heartbeat, using its eligible racer list and requestRecovery function.
function Integration.CheckSkyFall(course, racers, requestRecovery, attempted)
	local fallY = course:GetAttribute("FallY")
	assert(typeof(fallY) == "number" and fallY == fallY, "Course FallY required")
	for _, racer in racers do
		if racer.root.Position.Y <= fallY then
			requestRecovery(racer.player, "BelowPlayableRoute", false, attempted)
		end
	end
end

return Integration
