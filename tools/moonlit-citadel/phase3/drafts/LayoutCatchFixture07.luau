--!nonstrict
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local ExpertRoutes = require(script.Parent.ExpertRoutes)
local RouteHazardLayout = require(script.Parent.RouteHazardLayout)
local SupportingObstacles = require(script.Parent.SupportingObstacles)
local Layout = {Surfaces = {}, ArchSkins = {}, Transfers = {}, Wayfinding = {Forks = {}, Markers = {}}}

local function v(x, y, z) return Vector3.new(x, y, z) end
local function append(target, source)
	for _, node in source do table.insert(target, table.clone(node)) end
end

local function surface(group, name, position, size, role, frame)
	local path = "Obstacles/" .. group .. "/" .. name .. "/Contact"
	table.insert(Layout.Surfaces, {group = group, name = name, position = position, size = size, role = role or "WalkableSurface", frame = frame})
	return {name = name, path = path, kind = "Walk"}
end

local function flatDirection(a, b)
	return v(b.X - a.X, 0, b.Z - a.Z).Unit
end

local function edgeRadius(direction, size)
	return math.min(if math.abs(direction.X) > .001 then size.X / (2 * math.abs(direction.X)) else math.huge,
		if math.abs(direction.Z) > .001 then size.Z / (2 * math.abs(direction.Z)) else math.huge)
end

local function slopeFrame(point, direction)
	local unit = direction.Unit
	return CFrame.new(point) * CFrame.Angles(0, math.atan2(-unit.X, -unit.Z), 0) * CFrame.Angles(math.asin(unit.Y), 0, 0)
end

local function flatReserve(point, direction, size)
	local reserve = math.abs(direction.X) * size.X / 2 + math.abs(direction.Z) * size.Z / 2
	for _, data in Layout.Surfaces do
		local frame = data.frame or CFrame.new(data.position)
		if frame.UpVector.Y < .999 or math.abs(frame.Position.Y - point.Y) > .01 then continue end
		local localPoint = frame:PointToObjectSpace(point)
		if math.abs(localPoint.X) > data.size.X / 2 + .05 or math.abs(localPoint.Z) > data.size.Z / 2 + .05 then continue end
		local reach = (frame.Position - point):Dot(direction)
			+ math.abs(frame.RightVector:Dot(direction)) * data.size.X / 2
			+ math.abs(frame.LookVector:Dot(direction)) * data.size.Z / 2
		reserve = math.max(reserve, reach)
	end
	return reserve
end

local function ribbon(group, points, width, gap, archRise, landingWidth, endpointNodes)
	local route = {}
	local landingSize = v(landingWidth or width + 2, 1, landingWidth or width + 2)
	local landings, turnReserves = {}, {}
	for index, point in points do
		landings[index] = if endpointNodes and endpointNodes[index] then table.clone(endpointNodes[index])
			else surface(group, "Landing_" .. (index - 1), point, landingSize)
		if index > 1 and index < #points then
			local incoming, outgoing = -flatDirection(points[index - 1], point), flatDirection(point, points[index + 1])
			local cosine = math.clamp(incoming:Dot(outgoing), -1, 1)
			turnReserves[index] = width / (2 * math.sqrt(math.max(.0025, (1 - cosine) / 2))) + .15
		else turnReserves[index] = 0 end
	end
	table.insert(route, landings[1])
	for index = 1, #points - 1 do
		local a, b = points[index], points[index + 1]
		local direction = flatDirection(a, b)
		local totalLength = Vector3.new(b.X - a.X, 0, b.Z - a.Z).Magnitude
		local startTrim = math.max(flatReserve(a, direction, landingSize), turnReserves[index])
		local endTrim = math.max(flatReserve(b, -direction, landingSize), turnReserves[index + 1])
		local available = totalLength - startTrim - endTrim
		local rise = math.abs(b.Y - a.Y)
		if rise == 0 and available < 4 then
			local frame = slopeFrame((a + b) / 2, b - a)
			table.insert(route, surface(group, "FlatJoin_" .. index, (a + b) / 2, v(width, 1, totalLength + .08), "WalkableSurface", frame))
			table.insert(route, landings[index + 1])
			continue
		end
		assert(available >= rise / .8, group .. " span " .. index .. " has insufficient run outside flat landings: "
			.. tostring(available) .. " (length " .. tostring(totalLength) .. ", trims " .. tostring(startTrim) .. "/" .. tostring(endTrim) .. ")")
		local actualGap = math.min(gap, math.max(0, available - math.max(4, rise / .8)))
		local start, stop = a + direction * startTrim, b - direction * (endTrim + actualGap)
		local horizontalLength = available - actualGap
		local curveRise = math.min(archRise, math.max(0, (horizontalLength * .75 - rise) / math.pi))
		local departure
		if endpointNodes and endpointNodes[index] then
			departure = table.clone(landings[index])
			for _, data in Layout.Surfaces do
				if departure.path == "Obstacles/" .. data.group .. "/" .. data.name .. "/Contact" then
					departure.offset = (data.frame or CFrame.new(data.position)):PointToObjectSpace(a + direction * (startTrim - 1.05))
					break
				end
			end
		else
			departure = surface(group, "Departure_" .. index, a + direction * startTrim / 2, v(width, 1, startTrim + .08),
				"FlatTurn", slopeFrame(a + direction * startTrim / 2, direction))
		end
		table.insert(route, departure)
		local count = math.max(1, math.ceil((stop - start).Magnitude / (if curveRise == 0 then 12 else 5)))
		for step = 1, count do
			local t0, t1 = (step - 1) / count, step / count
			local pa = start:Lerp(stop, t0) + v(0, math.sin(t0 * math.pi) * curveRise, 0)
			local pb = start:Lerp(stop, t1) + v(0, math.sin(t1 * math.pi) * curveRise, 0)
			local length = (pb - pa).Magnitude
			local node = surface(group, "Tread_" .. index .. "_" .. step, (pa + pb) / 2,
				v(width, 1, length + .08), "WalkableSurface", slopeFrame((pa + pb) / 2, pb - pa))
			if step == count and actualGap > 0 then node.offset = v(0, 0, -length / 2 + 1.05) end
			table.insert(route, node)
		end
		local approach
		if endpointNodes and endpointNodes[index + 1] then
			approach = table.clone(landings[index + 1])
			for _, data in Layout.Surfaces do
				if approach.path == "Obstacles/" .. data.group .. "/" .. data.name .. "/Contact" then
					approach.offset = (data.frame or CFrame.new(data.position)):PointToObjectSpace(b - direction * (endTrim - 1.05))
					break
				end
			end
		else
			approach = surface(group, "LandingApproach_" .. index, b - direction * endTrim / 2, v(width, 1, endTrim + .08),
				"FlatTurn", slopeFrame(b - direction * endTrim / 2, direction))
		end
		if actualGap > 0 then
			local transfer = table.clone(approach)
			transfer.kind = "Jump"
			if not (endpointNodes and endpointNodes[index + 1]) then transfer.offset = v(0, 0, endTrim / 2 - 1.05) end
			transfer.gapStuds = actualGap
			table.insert(route, transfer)
		end
		table.insert(route, approach)
		table.insert(route, landings[index + 1])
		if archRise > 0 then
			table.insert(Layout.ArchSkins, {group = group, name = "ArchSupport_" .. index, a = start, b = stop, width = width})
		end
	end
	return route
end


local function contactData(node)
	for _, data in Layout.Surfaces do
		if node.path == "Obstacles/" .. data.group .. "/" .. data.name .. "/Contact" then return data end
	end
	error("Missing route contact " .. node.path)
end

local function atLip(node, direction, inset)
	local data = contactData(node)
	local frame = data.frame or CFrame.new(data.position)
	local localDirection = frame:VectorToObjectSpace(direction)
	local copy = table.clone(node)
	copy.offset = localDirection * (edgeRadius(localDirection, data.size) - (inset or .65))
	return copy
end

local function transfer(route, from, to, direction, gap, group, name, addRed)
	local departure, arrival = atLip(from, direction), atLip(to, -direction)
	arrival.kind, arrival.gapStuds, arrival.requiredJump = "Jump", gap, true
	arrival.riseStuds = contactData(to).position.Y - contactData(from).position.Y
	table.insert(route, departure)
	table.insert(route, arrival)
	table.insert(route, table.clone(to))
	local a, b = contactData(from), contactData(to)
	local af, bf = a.frame or CFrame.new(a.position), b.frame or CFrame.new(b.position)
	local start = af:PointToWorldSpace(departure.offset)
	local finish = bf:PointToWorldSpace(arrival.offset)
	table.insert(Layout.Transfers, {group = group, name = name, from = departure.path, to = arrival.path,
		fromPoint = start, toPoint = finish, gapStuds = gap, riseStuds = arrival.riseStuds})
end

local normalCausewayGroups = {
	SouthCloister = true, Gate = true, SharedArches = true, ArchNormal = true, MachineryApproach = true,
	UpperNormalApproach = true, CrownApproach = true,
}

local function normalCauseway(group)
	return normalCausewayGroups[group] or string.find(group, "GalleryNormal", 1, true) ~= nil
end

local function causewayRibbon(group, points, width, gap, landingWidth, endpointNodes)
	local route, landings = {}, {}
	local landingSize = v(landingWidth or width + 2, 1, landingWidth or width + 2)
	for index, point in points do
		local thisSize = if index % 3 == 0 then v(math.max(18, landingSize.X), 1, math.max(18, landingSize.Z)) else landingSize
		landings[index] = if endpointNodes and endpointNodes[index] then table.clone(endpointNodes[index])
			else surface(group, "Landing_" .. (index - 1), point, thisSize,
				if index % 3 == 0 then "SafeRefuge" else "WalkableSurface")
	end
	table.insert(route, landings[1])
	for span = 1, #points - 1 do
		local a, b = points[span], points[span + 1]
		local direction = flatDirection(a, b)
		local firstData, lastData = contactData(landings[span]), contactData(landings[span + 1])
		local firstFrame, lastFrame = firstData.frame or CFrame.new(firstData.position), lastData.frame or CFrame.new(lastData.position)
		local startTrim = edgeRadius(firstFrame:VectorToObjectSpace(direction), firstData.size)
		local endTrim = edgeRadius(lastFrame:VectorToObjectSpace(-direction), lastData.size)
		local available = v(b.X - a.X, 0, b.Z - a.Z).Magnitude - startTrim - endTrim
		if available < 13 then
			local start, finish = a + direction * startTrim, b - direction * endTrim
			if available > 0 then
				local center = (start + finish) / 2
				table.insert(route, surface(group, "Causeway_" .. span .. "_1", center,
					v(width, 1, (finish - start).Magnitude + .16), "WalkableSurface", slopeFrame(center, finish - start)))
			end
			table.insert(route, table.clone(landings[span + 1]))
			continue
		end
		local actualGap = if span % 3 == 1 then 4.5 elseif span % 3 == 2 then 5.5 else 6
		local jumps = math.max(1, math.floor(available / 21.5))
		local risePerJump = math.abs(b.Y - a.Y) / jumps
		if risePerJump >= 3 then actualGap = math.min(actualGap, 4.5) elseif risePerJump >= 2 then actualGap = math.min(actualGap, 5) end
		local floorLength = (available - jumps * actualGap) / jumps
		local slabs = {}
		for step = 1, jumps do
			local run = startTrim + (step - 1) * (floorLength + actualGap)
			local side = v(-direction.Z, 0, direction.X)
			local stagger = if step % 2 == 0 then 1.2 elseif step > 1 then -1.2 else 0
			local point = a + direction * (run + floorLength / 2) + side * stagger + v(0, (b.Y - a.Y) * (step - 1) / jumps, 0)
			local treadWidth = if step % 3 == 0 then math.max(8, width - 2) else width
			slabs[step] = surface(group, "Causeway_" .. span .. "_" .. step, point,
				v(treadWidth, 1, floorLength + .08), "WalkableSurface", slopeFrame(point, direction))
		end
		local entry = table.clone(slabs[1])
		entry.offset = v(0, 0, floorLength / 2 - .65)
		table.insert(route, entry)
		table.insert(route, table.clone(slabs[1]))
		for step = 1, jumps do
			local nextNode = if step == jumps then landings[span + 1] else slabs[step + 1]
			transfer(route, slabs[step], nextNode, direction, actualGap, group,
				"CausewayTransfer_" .. span .. "_" .. step, false)
		end
		if group == "SharedArches" or group == "ArchNormal" then
			table.insert(Layout.ArchSkins, {group = group, name = "ArchSupport_" .. span,
				a = a + direction * startTrim, b = b - direction * endTrim, width = width})
		end
	end
	return route
end

local function brokenRibbon(group, points, width, gap, landingWidth, endpointNodes)
	assert(normalCauseway(group), "Use explicit contacts for Expert routes")
	return causewayRibbon(group, points, width, gap, landingWidth, endpointNodes)
end

local function checkpoint(group, name, point, size, index, pocket)
	local node = surface(group, name .. "Terrace", point, size, "FixedWaitingArea")
	node.checkpoint = index
	Layout[name] = {point = point, pocket = pocket, size = size, support = node.path}
	return node
end

local gate = surface("Gate", "GateCourt", v(-144, 0, 146), v(44, 2, 36), "StartCapacity")
local cp01 = checkpoint("SharedArches", "CP01", v(-144, 28, -112), v(32, 2, 24), 1, v(-144, 28, -112))
local cp02 = checkpoint("Gallery", "CP02", v(-44, 52, 104), v(32, 2, 24), 2, v(-65, 52, 101))
local cp03 = checkpoint("Lifts", "CP03", v(112, 72, -52), v(48, 2, 18), 3, v(112, 72, -37))
local cp04 = checkpoint("Lifts", "CP04", v(112, 106, -86), v(48, 2, 18), 4, v(112, 106, -86))
local upperExit = surface("Lifts", "SharedUpperExit", v(112, 140, -120), v(40, 2, 18), "FixedWaitingArea")
local normalUpperWait = surface("Lifts", "UpperRearBoarding", v(112, 106, -120), v(40, 2, 18), "FixedWaitingArea")
for index = 1, 4 do
 local name = string.format("CP%02d", index)
 local data = Layout[name]
 local depth = if index == 4 then 14 else 22
 data.pocketSupport = surface("RecoveryPockets", name .. "Pocket", data.pocket, v(30, 1, depth), "SafeRefuge").path
 data.respawnArea = v(30, 0, depth)
end
local sharedArchEntry = surface("SharedArches", "Landing_0", v(-128, 12, 64), v(18, 1, 18), "SafeRefuge")
local shared = {gate}
append(shared, brokenRibbon("Gate", {v(-144, 0, 146), v(-120, 0, 146), v(-120, 0, 174),
 v(-188, 0, 174), v(-188, 4, 112), v(-128, 8, 112), v(-128, 12, 64)}, 12, 5.5, 14, {[1] = gate, [7] = sharedArchEntry}))
append(shared, brokenRibbon("SharedArches", {v(-128, 12, 64), v(-188, 16, 46), v(-128, 20, 0),
 v(-188, 24, -46), v(-144, 28, -112)}, 11, 5.5, 14, {[1] = sharedArchEntry, [5] = cp01}))
table.insert(shared, cp01)
local archMerge = surface("ArchNormal", "ArchMerge", v(-114, 52, 28), v(28, 1, 24), "FixedWaitingArea")
local archNormal = brokenRibbon("ArchNormal", {v(-144, 28, -112), v(-184, 28, -150), v(-216, 32, -150),
 v(-216, 36, -16), v(-188, 39, -16), v(-188, 42, 84), v(-216, 44, 84), v(-216, 46, 140),
 v(-156, 48, 140), v(-156, 50, 28), v(-114, 52, 28)}, 11, 5.5, 14, {[1] = cp01, [11] = archMerge})
local cloister = brokenRibbon("SouthCloister", {v(-114, 52, 28), v(-114, 52, 140), v(-76, 52, 164),
 v(-44, 52, 140), v(-44, 52, 104)}, 12, 5.5, 14, {[1] = archMerge, [5] = cp02})
local lanternNormal, lanternExpert = {}, {}
local galleryFrame = CFrame.new(v(-44, 52, 104)) * CFrame.Angles(0, -math.pi / 2, 0)
Layout.GalleryFrame = galleryFrame
Layout.Lanterns = {}
local function galleryPoint(x, y, z) return galleryFrame:PointToWorldSpace(v(x, y, z)) end
local function gallerySurface(name, x, y, z, width, depth, role)
	return surface("Gallery", name, galleryPoint(x, y, z), v(width, 1, depth), role, galleryFrame * CFrame.new(x, y, z))
end

local normalPrevious, normalPreviousWait = Layout.CP02.point, cp02
for band = 1, 3 do
	local z, y = -44 - (band - 1) * 46, 2 + (band - 1) * 4
	local side = -24
	local normalBefore = galleryPoint(side, y, z + 13)
	local normalWait = gallerySurface("NormalWaitBefore" .. band, side, y, z + 13, 14, 10, "SafeRefuge")
	if band == 1 then
		append(lanternNormal, brokenRibbon("GalleryNormalApproach1", {normalPrevious, galleryPoint(-44, 0, 0),
			galleryPoint(-44, y, z + 13), normalBefore}, 11, 5.5, 12,
			{[1] = cp02, [4] = normalWait}))
	else
		local firstBend = galleryPoint(-44, y - 2, z + 33)
		local secondBend = galleryPoint(-44, y - 2, z + 13)
		append(lanternNormal, brokenRibbon("GalleryNormalApproach" .. band, {normalPrevious, firstBend, secondBend, normalBefore}, 11, 5.5, 12,
			{[1] = normalPreviousWait, [4] = normalWait}))
	end
	normalWait.waitForLantern = band
	table.insert(lanternNormal, normalWait)
	local normalCross = gallerySurface("NormalCrossing" .. band, -12, y, z, 8, 8, "TimedCrossing")
	local normalAfter = gallerySurface("NormalWaitAfter" .. band, side, y, z - 13, 14, 10, "SafeRefuge")
	local direction = flatDirection(normalBefore, galleryPoint(-12, y, z))
	transfer(lanternNormal, normalWait, normalCross, direction, 4.7, "GalleryNormal", "Band" .. band .. "Entry", false)
	local jump = lanternNormal[#lanternNormal - 1]
	jump.lanternBand, jump.lanternPath = band, "Obstacles/SwingLanterns/SwingBand" .. band
	transfer(lanternNormal, normalCross, normalAfter, flatDirection(galleryPoint(-12, y, z), galleryPoint(side, y, z - 13)),
		4.7, "GalleryNormal", "Band" .. band .. "Exit", false)
	normalPrevious, normalPreviousWait = galleryPoint(side, y, z - 13), normalAfter

	table.insert(Layout.Lanterns, {name = "SwingBand" .. band, point = galleryPoint(0, y + 3, z),
		pivot = galleryPoint(0, y + 17, z), axis = galleryFrame:VectorToWorldSpace(Vector3.zAxis), phase = (band - 1) * 1.5})
end
local galleryExit = v(132, 66, 104)
local galleryExitNode = surface("MachineryApproach", "GalleryExit", galleryExit, v(12, 1, 24), "FixedWaitingArea")
append(lanternNormal, brokenRibbon("GalleryNormalExit", {normalPrevious, v(105, 62, 56), v(156, 64, 56), v(156, 66, 80), v(132, 66, 80), galleryExit},
 11, 5.5, 14, {[1] = normalPreviousWait, [6] = galleryExitNode}))
local archShift, liftShift = v(-72, 0, -34), v(36, 0, -69)
local function expertSurface(group, name, point, size, role, frame)
 local shift = if group == "ArchExpert" then archShift elseif group == "UpperBrace" or group == "UpperExpertExit" then liftShift else v(0, 0, 0)
 return surface(group, name, point + shift, size, role, if frame then CFrame.new(shift) * frame else nil)
end
local firstExpertTransfer = #Layout.Transfers + 1
local expert = ExpertRoutes(Layout, expertSurface, archMerge, cp04, galleryFrame, galleryExitNode, upperExit)
local function shiftGoals(route, shift)
 for _, node in route do
  if node.offset then
   local frame = contactData(node).frame or CFrame.new(contactData(node).position)
   node.offset += frame:VectorToObjectSpace(shift)
  end
 end
end
shiftGoals(expert.archExpert, archShift)
shiftGoals(expert.expertBrace, liftShift)
shiftGoals(expert.expertExit, liftShift)
local function expertPathShift(path)
 if string.find(path, "/ArchExpert/", 1, true) or path == archMerge.path then return archShift end
 if string.find(path, "/UpperBrace/", 1, true) or string.find(path, "/UpperExpertExit/", 1, true)
  or path == cp04.path or path == upperExit.path then return liftShift end
 return v(0, 0, 0)
end
for index = firstExpertTransfer, #Layout.Transfers do
 local item = Layout.Transfers[index]
 item.fromPoint += expertPathShift(item.from)
 item.toPoint += expertPathShift(item.to)
end
local archExpert, lanternExpert = expert.archExpert, expert.lanternExpert
local expertPrep = archExpert[1]
local expertBrace, earlyExit, expertExit = expert.expertBrace, expert.earlyExit, expert.expertExit
local galleryMergePath = expert.galleryMergePath
local galleryMergeBay = surface("MachineryApproach", "GalleryMergeBay", v(188, 66, 104), v(32, 1, 24), "FixedWaitingArea")
local machinery = brokenRibbon("MachineryApproach", {galleryExit, v(188, 66, 104), v(188, 66, 160), v(218, 68, 160),
 v(218, 68, 32), v(188, 70, 32), v(188, 70, -52), v(112, 72, -52)}, 12, 5.5, 14, {[1] = galleryExitNode, [2] = galleryMergeBay, [8] = cp03})
table.insert(machinery, cp03)
Layout.LiftOrigins = {Lower = v(112, 72, -69), Upper = v(112, 106, -103)}
local normalDeparture = surface("UpperNormalApproach", "GateTakeoff", v(142, 106, -68), v(8, 1, 12), "BranchApproach")
local normalTakeoff, normalArrival = table.clone(cp04), table.clone(normalDeparture)
normalTakeoff.offset, normalArrival.offset = v(22.35, 0, 7.65), v(-3.35, 0, -4.65)
normalArrival.kind, normalArrival.requiredJump, normalArrival.riseStuds = "Jump", true, 0
normalArrival.gapStuds = 5.84
local normalUpper = {normalTakeoff, normalArrival, table.clone(normalDeparture)}
table.insert(Layout.Transfers, {group = "UpperNormalApproach", name = "FrontCornerCommit", from = cp04.path, to = normalDeparture.path,
 fromPoint = v(134.35, 106, -78.35), toPoint = v(138.65, 106, -72.65), gapStuds = 5.84, riseStuds = 0, flightStuds = 7.14})
append(normalUpper, brokenRibbon("UpperNormalApproach", {v(142, 106, -68), v(188, 106, -68), v(188, 106, 44), v(160, 106, 44),
 v(160, 106, 72), v(219, 106, 72), v(219, 106, -144), v(154, 106, -144), v(154, 106, -120), v(112, 106, -120)},
 10, 5.5, 14, {[1] = normalDeparture, [10] = normalUpperWait}))
table.insert(normalUpper, normalUpperWait)
Layout.UpperFrontWall = {point = v(112, 111, -95.5), size = v(48, 10, 1.5)}
local finish = surface("Crown", "CrownTerrace", v(-8, 150, -30), v(36, 2, 28), "FinishCapacity")
local crown = brokenRibbon("CrownApproach", {v(112, 140, -120), v(112, 140, -154), v(8, 142, -154),
 v(8, 144, -110), v(-60, 146, -110), v(-60, 148, -30), v(-8, 150, -30)}, 12, 5.5, 14, {[1] = upperExit, [7] = finish})
finish.finish = true
table.insert(crown, finish)
Layout.StartPoint, Layout.FinishPoint = v(-144, 0, 146), v(-8, 150, -30)
local archShelf = surface("Recovery", "ArchCatch", v(-162, 12, -106), v(36, 1, 18), "SafeRefuge")
local archReturn = ribbon("ArchCatchReturn", {v(-178, 12, -106), v(-236, 12, -106), v(-236, 16, -164),
 v(-184, 20, -172), v(-144, 24, -150), v(-144, 28, -112)}, 7, 0, 0, 9, {[6] = cp01})
local upperShelf = surface("Recovery", "LiftCatch", v(112, 92, -88), v(60, 1, 12), "SafeRefuge")
local upperReturn = ribbon("LiftCatchReturn", {v(86, 92, -89.5), v(68, 92, -92), v(68, 102, -128),
 v(76, 102, -128), v(76, 104, -92), v(112, 106, -92)}, 7, 0, 0, 9, {[6] = cp04})

local function ride(stage, bay, wait, exit, boardY, exitY, expert)
	local path = "Obstacles/MovingCars/" .. stage .. "_Bay" .. bay .. "/Deck"
	local rearBoarding = stage == "Upper" and not expert
	local bayX = if bay == 1 then -9 else 9
	return {name = stage .. "RideBay" .. bay, kind = "Ride", path = path, waitPath = wait.path,
		waitOffset = if expert then v(if bay == 1 then 1 else -1, 0, -1.5) else v(bayX, 0, if rearBoarding then 8 else -8),
		board = v(if expert then (if bay == 1 then -4.5 else 4.5) else 0, 0, if expert then 4.8 elseif rearBoarding then -4.5 else 4.5), exitPath = exit.path,
		exitTakeoff = v(if expert then (if bay == 1 then -3 else 3) else 0, 0, if expert then 4.5 else -4.5),
		exitOffset = v(if expert then 0 else bayX, 0, if expert then -1.5 else 8),
		boardHeight = Config.Origin.Y + boardY, exitHeight = Config.Origin.Y + exitY, direction = "Up",
		boardHeightTolerance = if expert then .9 else 1.5,
		bayPaths = {"Obstacles/MovingCars/" .. stage .. "_Bay1/Deck", "Obstacles/MovingCars/" .. stage .. "_Bay2/Deck"}}
end

function Layout.GetRoute(choices, bays)
	choices, bays = choices or {}, bays or {1, 2}
	local route = {}
	append(route, shared)
	append(route, if choices[1] then archExpert else archNormal)
	append(route, cloister)
	table.insert(route, table.clone(cp02))
	append(route, if choices[2] then lanternExpert else lanternNormal)
	append(route, machinery)
	table.insert(route, ride("Lower", bays[1] or 1, machinery[#machinery], cp04, 72, 104, false))
	table.insert(route, table.clone(cp04))
	if choices[3] then
		append(route, expertBrace)
		-- The approved raised brace faces Bay 2; selecting Bay 1 uses its mirrored contact below.
		local bay = bays[2] or 2
		if bay == 1 then
			for index = #route - #expertBrace + 1, #route do
				route[index].path = string.gsub(route[index].path, "UpperBrace/", "UpperBraceMirror/")
				local offset = route[index].offset
				if offset then route[index].offset = v(-offset.X, offset.Y, offset.Z) end
			end
		end
		local wait = table.clone(route[#route])
		local exit = table.clone(earlyExit)
		if bay == 1 then exit.path = string.gsub(exit.path, "UpperBrace/", "UpperBraceMirror/") end
		table.insert(route, ride("Upper", bay, wait, exit, expert.boardY, expert.exitY, true))
		table.insert(route, exit)
		if bay == 1 then
			local mirrorExit = {}
			for _, node in expertExit do
				local copy = table.clone(node)
				copy.path = string.gsub(copy.path, "UpperExpertExit/", "UpperExpertExitMirror/")
				copy.path = string.gsub(copy.path, "UpperBrace/", "UpperBraceMirror/")
				if copy.offset then copy.offset = v(-copy.offset.X, copy.offset.Y, copy.offset.Z) end
				table.insert(mirrorExit, copy)
			end
			append(route, mirrorExit)
		else append(route, expertExit) end
	else
		append(route, normalUpper)
		table.insert(route, ride("Upper", bays[2] or 2, normalUpperWait, upperExit, 106, 138, false))
	end
	table.insert(route, table.clone(upperExit))
	append(route, crown)
	return SupportingObstacles.EnrichRoute(Layout, route)
end

-- Both bays have identical raised contacts; their outer return stays away from the weight channel.
local originals = table.clone(Layout.Surfaces)
for _, item in originals do
	if item.group == "UpperBrace" or item.group == "UpperExpertExit" then
		local copy = table.clone(item)
		copy.group = item.group .. "Mirror"
		copy.position = v(224 - item.position.X, item.position.Y, item.position.Z)
		if item.frame then
			local look = item.frame.LookVector
			copy.frame = slopeFrame(copy.position, v(-look.X, look.Y, look.Z))
		end
		table.insert(Layout.Surfaces, copy)
	end
end

Layout.RouteBlockers = {
 {name = "ArchInsideParapet", point = v(-145, 35, -43), size = v(1.5, 18, 74)},
 {name = "CrownInsideParapet", point = v(-22, 150, -70), size = v(1.5, 22, 60)},
}

Layout.ReturnRoutes = {
	Arch = {launchPath = cp01.path, shelfPath = archShelf.path, rejoinPath = shared[#shared].path},
	Upper = {launchPath = cp04.path, shelfPath = upperShelf.path, rejoinPath = cp04.path},
}

function Layout.GetCatchRoute(name)
	local route = {}
	if name == "Arch" or name == "ArchCatch" then
		table.insert(route, table.clone(cp01))
		local launch = {name = "ArchCatchLaunch", path = Layout.ReturnRoutes.Arch.launchPath, kind = "Walk", offset = v(-12.5, 0, 6)}
		local drop = table.clone(archShelf)
		drop.drop, drop.offset = true, v(-6, 0, 0)
		table.insert(route, launch)
		table.insert(route, drop)
		append(route, archReturn)
		table.insert(route, table.clone(shared[#shared]))
	elseif name == "Upper" or name == "LiftCatch" then
		table.insert(route, {name = "UpperCatchLaunch", path = cp04.path, kind = "Walk", offset = v(23.3, 0, -3.5)})
		local drop = table.clone(upperShelf)
		drop.drop, drop.offset = true, v(26, 0, -1.5)
		table.insert(route, drop)
		append(route, upperReturn)
		table.insert(route, table.clone(cp04))
	else error("Unknown Moonlit catch: " .. tostring(name)) end
	return route
end

local function firstJump(route)
	for _, node in route do if node.kind == "Jump" then return node end end
	error("Branch has no committed jump")
end
local normalLanternEntry, expertLanternEntry = firstJump(lanternNormal), firstJump(lanternExpert)
Layout.BranchCosts = {
	Arches = {normal = "West arcades with offset gap runs, outer tower wraps and passing terraces; both routes cross the south cloister.", expert = "Short inner route: four-stud rises, directional landings, 3.5-stud beams and three hurdle jumps."},
	Lanterns = {normal = "Open wall gallery with broad outer refuges, short offset transfers and all three timed lantern bands.", expert = "Three 3.5-stud timed crossings, raised offset exits and narrow rail hurdle jumps."},
	UpperLift = {normal = "Corner commitment into the east wall gallery, staggered gaps to rear boarding, then the full upper ride.", expert = "Five precise raised brace contacts, later boarding and earlier exit while retaining the upper ride."},
}
Layout.Wayfinding.Forks = {
	{name = "E1_StoneArch", approachPath = cp01.path, normalPath = "Obstacles/ArchNormal/Landing_1/Contact",
		expertPath = expertPrep.path, expertForwardPath = "Obstacles/ArchExpert/RiseCorbel/Contact", demand = "RISING TURNS / NARROW RAILS"},
	{name = "E2_Lantern", approachPath = cp02.path, normalPath = normalLanternEntry.path, normalOffset = normalLanternEntry.offset,
		expertPath = lanternExpert[1].path, expertOffset = nil, demand = "NARROW LANDINGS / TIMED SWINGS"},
	{name = "E3_UpperLift", approachPath = cp04.path, normalPath = "Obstacles/UpperNormalApproach/Landing_1/Contact",
		normalDeparturePath = normalDeparture.path,
		expertPaths = {expert.braceFirstPath,
			(string.gsub(expert.braceFirstPath, "UpperBrace/", "UpperBraceMirror/"))},
		demand = "RAISED BRACE / PRECISION EXIT"},
}
Layout.Wayfinding.Markers = {
	{name = "ArchMerge", path = cp02.path, targetPath = normalLanternEntry.path, targetOffset = normalLanternEntry.offset,
		kind = "Merge", mode = "Shared", label = "LANTERN GALLERY"},
	{name = "LowerBoard", path = cp03.path, targetPoint = Layout.LiftOrigins.Lower, kind = "Board", mode = "Shared", label = "LOWER LIFT / TWO BAYS"},
	{name = "UpperRearBoard", path = normalUpperWait.path, targetPoint = Layout.LiftOrigins.Upper, kind = "Board", mode = "Normal", label = "UPPER LIFT / NORMAL"},
	{name = "CrownMerge", path = upperExit.path, targetPath = crown[2].path, targetOffset = crown[2].offset, kind = "Merge", mode = "Shared", label = "CROWN / FINAL JUMPS"},
	{name = "ArchReturn", path = archShelf.path, targetPath = archReturn[1].path, kind = "Turn", mode = "Return", label = "RETURN TO CP01"},
	{name = "LiftReturn", path = upperShelf.path, targetPath = upperReturn[1].path, kind = "Turn", mode = "Return", label = "RETURN TO CP04"},
	{name = "GalleryMerge", path = galleryMergePath, targetPath = galleryExitNode.path, kind = "Merge", mode = "Shared", label = "MACHINERY / CP03"},
}
SupportingObstacles.Apply(Layout)
RouteHazardLayout(Layout)
return Layout
