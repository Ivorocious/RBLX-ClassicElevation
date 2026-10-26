--!nonstrict
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local ExpertRoutes = require(script.Parent.ExpertRoutes)
local SupportingObstacles = require(script.Parent.SupportingObstacles)
local RouteHazardLayout = require(script.Parent.RouteHazardLayout)
local Layout = {Surfaces = {}, ArchSkins = {}, Transfers = {}, RouteBlockers = {}, Wayfinding = {Forks = {}, Markers = {}}}
local v = Vector3.new
local contacts = {}

local function append(target, source)
	for _, node in source do table.insert(target, table.clone(node)) end
end

local function surface(group, name, position, size, role, frame)
	local path = "Obstacles/" .. group .. "/" .. name .. "/Contact"
	assert(not contacts[path], "Duplicate Moonlit contact: " .. path)
	local record = {group = group, name = name, position = position, size = size,
		role = role or "WalkableSurface", frame = frame}
	table.insert(Layout.Surfaces, record)
	contacts[path] = record
	return {name = name, path = path, kind = "Walk"}
end

local function flatDirection(a, b)
	local delta = v(b.X - a.X, 0, b.Z - a.Z)
	assert(delta.Magnitude > .01, "Route span requires horizontal travel")
	return delta.Unit
end

local function frameAt(point, direction)
	local unit = direction.Unit
	return CFrame.new(point) * CFrame.Angles(0, math.atan2(-unit.X, -unit.Z), 0)
		* CFrame.Angles(math.asin(unit.Y), 0, 0)
end

local function edgeRadius(direction, size)
	return math.min(if math.abs(direction.X) > .001 then size.X / (2 * math.abs(direction.X)) else math.huge,
		if math.abs(direction.Z) > .001 then size.Z / (2 * math.abs(direction.Z)) else math.huge)
end

local function lip(node, direction)
	local item = assert(contacts[node.path])
	local frame = item.frame or CFrame.new(item.position)
	local localDirection = frame:VectorToObjectSpace(direction)
	local copy = table.clone(node)
	local radius = math.min(if math.abs(localDirection.X) > .001 then (item.size.X / 2 - 1.05) / math.abs(localDirection.X) else math.huge,
		if math.abs(localDirection.Z) > .001 then (item.size.Z / 2 - 1.05) / math.abs(localDirection.Z) else math.huge)
	copy.offset = localDirection * math.max(0, radius)
	return copy, frame:PointToWorldSpace(copy.offset)
end

local function jump(route, from, to, family, departureOffset, arrivalOffset)
	local a, b = contacts[from.path], contacts[to.path]
	local direction = flatDirection(a.position, b.position)
	local departure, start = lip(from, direction)
	local arrival, stop = lip(to, -direction)
	local aFrame, bFrame = a.frame or CFrame.new(a.position), b.frame or CFrame.new(b.position)
	if departureOffset then
		assert(math.abs(departureOffset.X) + 1.05 <= a.size.X / 2 + .001
			and math.abs(departureOffset.Z) + 1.05 <= a.size.Z / 2 + .001, family .. " takeoff lacks foot support")
		departure.offset, start = departureOffset, aFrame:PointToWorldSpace(departureOffset)
	end
	if arrivalOffset then
		assert(math.abs(arrivalOffset.X) + 1.05 <= b.size.X / 2 + .001
			and math.abs(arrivalOffset.Z) + 1.05 <= b.size.Z / 2 + .001, family .. " arrival lacks foot support")
		arrival.offset, stop = arrivalOffset, bFrame:PointToWorldSpace(arrivalOffset)
	end
	local gap = v(b.position.X - a.position.X, 0, b.position.Z - a.position.Z).Magnitude
		- edgeRadius(aFrame:VectorToObjectSpace(direction), a.size)
		- edgeRadius(bFrame:VectorToObjectSpace(-direction), b.size)
	local distance = v(stop.X - start.X, 0, stop.Z - start.Z).Magnitude
	local rise = stop.Y - start.Y
	local speed = math.sqrt(2 * Config.Gravity * Config.Movement.JumpHeight)
	local discriminant = speed * speed - 2 * Config.Gravity * rise
	assert(discriminant > 0, family .. " rises above ordinary jump height")
	local reach = Config.Movement.WalkSpeed * (speed + math.sqrt(discriminant)) / Config.Gravity
	assert(reach - distance >= .65, family .. " lacks Normal jump margin: " .. from.path .. " -> " .. to.path
		.. " flight=" .. distance .. " rise=" .. rise .. " margin=" .. (reach - distance))
	arrival.kind, arrival.requiredJump = "Jump", true
	arrival.gapStuds, arrival.riseStuds = gap, rise
	arrival.obstacleFamily = family
	table.insert(route, departure)
	table.insert(route, arrival)
	table.insert(route, table.clone(to))
	table.insert(Layout.Transfers, {group = a.group, name = "Transfer_" .. (#Layout.Transfers + 1),
		from = from.path, to = to.path, fromPoint = start, toPoint = stop,
		gapStuds = arrival.gapStuds, riseStuds = rise, flightStuds = distance,
		idealReachMargin = reach - distance, kind = "Jump", requiredJump = true, obstacleFamily = family})
end

-- Flat stones keep jump rises explicit; no curved bridge conceals an abrupt lip.
local function steppedRoute(group, points, width, landingWidth, endpoints, arches, overrides)
	local route, landings = {}, {}
	for index, point in points do
		landings[index] = if endpoints and endpoints[index] then endpoints[index]
			else surface(group, "Landing_" .. (index - 1), point, v(landingWidth, 1, landingWidth), "FlatTurn")
	end
	table.insert(route, table.clone(landings[1]))
	for span = 1, #points - 1 do
		local a, b = points[span], points[span + 1]
		local direction = flatDirection(a, b)
		local first, last = contacts[landings[span].path], contacts[landings[span + 1].path]
		local startTrim = edgeRadius((first.frame or CFrame.new(a)):VectorToObjectSpace(direction), first.size)
		local endTrim = edgeRadius((last.frame or CFrame.new(b)):VectorToObjectSpace(-direction), last.size)
		local length = v(b.X - a.X, 0, b.Z - a.Z).Magnitude
		local available = length - startTrim - endTrim
		local gap = if math.abs(b.Y - a.Y) > .01 then 4.5 elseif span % 2 == 0 then 5.5 else 5
		assert(available >= gap, group .. " span " .. span .. " overlaps its turn landings")
		if available <= 6 and math.abs(b.Y - a.Y) <= 2 then
			jump(route, landings[span], landings[span + 1], "NormalDirectionalTransfer")
		else
		local count = math.max(1, math.ceil((available - gap) / (17 + gap)), math.ceil(math.abs(b.Y - a.Y) / 2) - 1)
		local stoneLength = (available - (count + 1) * gap) / count
		assert(stoneLength >= 5, group .. " span " .. span .. " has a cramped landing")
		local previous = landings[span]
		for step = 1, count do
			local run = startTrim + gap + (step - 1) * (stoneLength + gap) + stoneLength / 2
			local point = a + direction * run + v(0, (b.Y - a.Y) * step / (count + 1), 0)
			local floorName = "Causeway_" .. span .. "_" .. step
			local height = overrides and overrides.heights and overrides.heights[floorName]
			if height then point = v(point.X, height, point.Z) end
			local floor = surface(group, floorName, point,
				v(width, 1, stoneLength), "WalkableSurface", frameAt(point, direction))
			if overrides and overrides.hurdleHeights then
				contacts[floor.path].hurdleCenterHeight = overrides.hurdleHeights[floorName]
			end
			jump(route, previous, floor, "NormalStaggeredStone")
			previous = floor
		end
		if not (overrides and overrides.deferFinalTransfer and span == #points - 1) then
			jump(route, previous, landings[span + 1], "NormalDirectionalTransfer")
		end
		if arches then
			table.insert(Layout.ArchSkins, {group = group, name = "ArchSupport_" .. span,
				a = a + direction * startTrim, b = b - direction * endTrim, width = width})
		end
		end
	end
	return route
end

local function checkpoint(group, name, point, size, index)
	local node = surface(group, name .. "Terrace", point, size, "FixedWaitingArea")
	node.checkpoint = index
	-- The checkpoint floor itself supports the capacity pocket without a second overlapping floor.
	Layout[name] = {point = point, pocket = point, size = size, support = node.path,
		pocketSupport = node.path, respawnArea = v(30, 0, 14)}
	return node
end

local gate = surface("Gate", "GateCourt", v(-144, 0, 146), v(44, 2, 36), "StartCapacity")
local cp01 = checkpoint("SharedArches", "CP01", v(-144, 28, -112), v(32, 2, 24), 1)
local cp02 = checkpoint("Gallery", "CP02", v(-80, 52, 28), v(32, 2, 24), 2)
local cp03 = checkpoint("Lifts", "CP03", v(112, 72, -52), v(48, 2, 18), 3)
local cp04 = checkpoint("Lifts", "CP04", v(112, 106, -86), v(48, 2, 18), 4)
local upperExit = surface("Lifts", "SharedUpperExit", v(112, 140, -162), v(40, 2, 18), "FixedWaitingArea")
local normalUpperWait = surface("Lifts", "UpperRearBoarding", v(112, 106, -162), v(28, 2, 18), "FixedWaitingArea")
Layout.LiftOrigins = {Lower = v(112, 72, -69), Upper = v(112, 106, -145)}

local sharedArchEntry = surface("SharedArches", "Landing_0", v(-128, 12, 64), v(14, 1, 14), "SafeRefuge")
local shared = steppedRoute("Gate", {v(-144, 0, 146), v(-170, 6, 94), v(-128, 12, 64)},
	12, 14, {[1] = gate, [3] = sharedArchEntry})
append(shared, steppedRoute("SharedArches", {v(-128, 12, 64), v(-174, 16, 46), v(-128, 20, 0),
	v(-174, 24, -46), v(-144, 28, -112)}, 10, 14, {[1] = sharedArchEntry, [5] = cp01}, true,
	{heights = {Causeway_4_2 = 18, Causeway_4_3 = 13}, hurdleHeights = {Causeway_4_3 = .6}, deferFinalTransfer = true}))
local sharedLastStone = table.clone(shared[#shared])

local archMerge = surface("ArchNormal", "ArchMerge", v(-122, 52, 44), v(18, 1, 18), "FixedWaitingArea")
local archNormal = steppedRoute("ArchNormal", {v(-144, 28, -112), v(-188, 32, -112), v(-188, 42, 4),
	v(-148, 46, 4), v(-122, 52, 44)}, 10, 14, {[1] = cp01, [5] = archMerge}, true)
local cloister = steppedRoute("SouthCloister", {v(-122, 52, 44), v(-80, 52, 28)},
	12, 14, {[1] = archMerge, [2] = cp02})

Layout.GalleryFrame = CFrame.new(v(-80, 52, 28)) * CFrame.Angles(0, -math.pi / 2, 0)
Layout.Lanterns = {}
Layout.GalleryBands = {{z = -44, y = 2}, {z = -98, y = 6}, {z = -152, y = 10}}
local function gp(x, y, z) return Layout.GalleryFrame:PointToWorldSpace(v(x, y, z)) end
local function gallerySurface(name, x, y, z, width, depth, role)
	return surface("Gallery", name, gp(x, y, z), v(width, 1, depth), role,
		Layout.GalleryFrame * CFrame.new(x, y, z))
end
local lanternNormal = {}
local previous, previousPoint = cp02, Layout.CP02.point
for band = 1, 3 do
	local z, y = Layout.GalleryBands[band].z, Layout.GalleryBands[band].y
	local before = gallerySurface("NormalWaitBefore" .. band, -26, y, z + 13, 12, 10, "SafeRefuge")
	local points = {previousPoint, gp(-26, y, z + 13)}
	append(lanternNormal, steppedRoute("GalleryNormalApproach" .. band, points, 10, 12,
		{[1] = previous, [#points] = before}))
	before.waitForLantern = band
	table.insert(lanternNormal, table.clone(before))
	local crossing = gallerySurface("NormalCrossing" .. band, -16, y, z, 8, 8, "TimedCrossing")
	local after = gallerySurface("NormalWaitAfter" .. band, -26, y, z - 13, 12, 10, "SafeRefuge")
	jump(lanternNormal, before, crossing, "NormalTimedLanternEntry")
	local arrival = lanternNormal[#lanternNormal - 1]
	arrival.lanternBand, arrival.lanternPath = band, "Obstacles/SwingLanterns/SwingBand" .. band
	jump(lanternNormal, crossing, after, "NormalTimedLanternExit")
	previous, previousPoint = after, gp(-26, y, z - 13)
	table.insert(Layout.Lanterns, {name = "SwingBand" .. band, point = gp(-3, y + 3, z),
		pivot = gp(-3, y + 29, z), axis = Layout.GalleryFrame:VectorToWorldSpace(Vector3.zAxis), phase = (band - 1) * 1.5})
end
local galleryExitNode = surface("MachineryApproach", "GalleryExit", v(112, 66, 28), v(18, 1, 18), "FixedWaitingArea")
append(lanternNormal, steppedRoute("GalleryNormalExit", {previousPoint, v(112, 66, 28)},
	10, 12, {[1] = previous, [2] = galleryExitNode}))

local machinery = steppedRoute("MachineryApproach", {v(112, 66, 28), v(164, 68, 28),
	v(164, 70, -52), v(112, 72, -52)}, 12, 14, {[1] = galleryExitNode, [4] = cp03})
local normalUpper = steppedRoute("UpperNormalApproach", {v(112, 106, -86), v(160, 106, -86),
	v(160, 106, -162), v(112, 106, -162)}, 10, 14, {[1] = cp04, [4] = normalUpperWait})
local finish = surface("Crown", "CrownTerrace", v(-8, 150, -30), v(36, 2, 28), "FinishCapacity")
finish.finish = true
local crown = steppedRoute("CrownApproach", {v(112, 140, -162), v(48, 144, -162),
	v(48, 146, -56), v(-8, 150, -30)}, 12, 14, {[1] = upperExit, [4] = finish})
Layout.StartPoint, Layout.FinishPoint = contacts[gate.path].position, contacts[finish.path].position
Layout.FinishGate = {point = v(-5, 150, -30), size = v(28, 12, 24), yaw = math.pi / 2}

-- Recovery descends to a local shelf, then returns outside the race line on a continuous ramp.
local function recoveryRamp(group, points, endpoints)
	local route = {}
	for index, point in points do
		local node = if endpoints and endpoints[index] then endpoints[index]
			else surface(group, "Landing_" .. index, point, v(9, 1, 9), "LocalRecovery")
		if index > 1 then
			local a, b = points[index - 1], point
			local direction, length = (b - a).Unit, (b - a).Magnitude
			local frame = frameAt((a + b) / 2, b - a)
			assert(math.abs(direction.Y) < .55, "Recovery ramp is too steep")
			local floor = surface(group, "Ramp_" .. index, (a + b) / 2, v(7, 1, length + .08), "LocalRecovery", frame)
			table.insert(route, floor)
		end
		table.insert(route, table.clone(node))
	end
	return route
end
local archShelf = surface("Recovery", "ArchCatch", v(-139, 12, -112), v(44, 1, 28), "SafeRefuge")
local archReturn = recoveryRamp("ArchCatchReturn", {v(-139, 12, -112), v(-224, 12, -112),
	v(-224, 17, -160), v(-144, 23, -160), v(-144, 28, -112)}, {[1] = archShelf, [5] = cp01})
local sharedClimbFirst
local previousSharedStep = sharedLastStone
for index, point in {v(-166, 17, -98), v(-180, 17.5, -111), v(-192, 22.5, -126.5), v(-172, 27, -132)} do
	local step = surface("SharedArches", "ClimbStep_" .. index, point, v(if index == 4 then 20 else 12, 1, 12), "WalkableSurface")
	sharedClimbFirst = sharedClimbFirst or step
	-- Stay beyond the cleared hurdle while turning toward the first climb stone.
	local departure = if index == 1 then v(-3.95, 0, -3.6) elseif index == 3 then v(-4.95, 0, -4.95) else nil
	local arrival = if index == 3 then v(4.95, 0, 4.95) else nil
	jump(shared, previousSharedStep, step, "SharedCheckpointClimb", departure, arrival)
	previousSharedStep = step
end
jump(shared, previousSharedStep, cp01, "SharedCheckpointArrival")
local upperShelf = surface("Recovery", "LiftCatch", v(152, 90, -108), v(32, 1, 26), "SafeRefuge")
local upperReturn = recoveryRamp("LiftCatchReturn", {v(152, 90, -108), v(174, 90, -108), v(174, 90, -34),
	v(70, 96, -34), v(70, 101, -66), v(112, 106, -86)}, {[1] = upperShelf, [6] = cp04})

local expertMergeNeedle = surface("ArchExpert", "MergeNeedle", v(-114, 51, 31), v(2.2, 1, 8), "ExpertPerch")
local expert = ExpertRoutes(Layout, surface, expertMergeNeedle, cp04, Layout.GalleryFrame, galleryExitNode, upperExit, cp03)
jump(expert.archExpert, expertMergeNeedle, archMerge, "ExpertSharedArchMerge")
local function ride(stage, bay, wait, exit, boardY, exitY, expertMode)
	local bayX = if bay == 1 then -9 else 9
	local rear = stage == "Upper"
	return {name = stage .. "RideBay" .. bay, kind = "Ride", path = "Obstacles/MovingCars/" .. stage .. "_Bay" .. bay .. "/Deck",
		waitPath = wait.path, waitOffset = v(bayX, 0, if rear then 8 else -8),
		board = v(0, 0, if rear then -4.5 else 4.5), exitPath = exit.path,
		exitTakeoff = v(0, 0, -4.5), exitOffset = v(bayX, 0, 8),
		boardHeight = Config.Origin.Y + boardY, exitHeight = Config.Origin.Y + exitY, direction = "Up",
		boardHeightTolerance = if expertMode then .9 else 1.5,
		bayPaths = {"Obstacles/MovingCars/" .. stage .. "_Bay1/Deck", "Obstacles/MovingCars/" .. stage .. "_Bay2/Deck"}}
end

function Layout.GetRoute(choices, bays)
	choices, bays = choices or {}, bays or {1, 2}
	local route = {}
	append(route, shared)
	append(route, if choices[1] then expert.archExpert else archNormal)
	append(route, cloister)
	table.insert(route, table.clone(cp02))
	append(route, if choices[2] then expert.lanternExpert else lanternNormal)
	if not choices[2] then append(route, machinery) end
	table.insert(route, ride("Lower", bays[1] or 1, cp03, cp04, 72, 104, false))
	table.insert(route, table.clone(cp04))
	append(route, if choices[3] then expert.expertBrace else normalUpper)
	table.insert(route, ride("Upper", bays[2] or 2, normalUpperWait, upperExit, 106, 138, choices[3]))
	table.insert(route, table.clone(upperExit))
	append(route, crown)
	return SupportingObstacles.EnrichRoute(Layout, route)
end

Layout.ReturnRoutes = {
	Arch = {launchPath = cp01.path, shelfPath = archShelf.path, rejoinPath = cp01.path},
	Upper = {launchPath = cp04.path, shelfPath = upperShelf.path, rejoinPath = cp04.path},
}
function Layout.GetCatchRoute(name)
	local route = {}
	local upper = name == "Upper" or name == "LiftCatch"
	assert(upper or name == "Arch" or name == "ArchCatch", "Unknown Moonlit catch")
	local launch, shelf, returns = if upper then cp04 else cp01, if upper then upperShelf else archShelf,
		if upper then upperReturn else archReturn
	local lipNode = table.clone(launch)
	lipNode.offset = v(if upper then 22.95 else 14.95, 0, if upper then -7.95 else 0)
	table.insert(route, lipNode)
	local drop = table.clone(shelf)
	drop.drop, drop.offset = true, v(if upper then -14.75 else 16, 0, if upper then 11.75 else 0)
	table.insert(route, drop)
	append(route, returns)
	return route
end

local function firstAfter(route, path)
	for _, node in route do if node.path ~= path then return node end end
	error("Missing fork commitment")
end
local archEntry = firstAfter(archNormal, cp01.path)
local lanternEntry = firstAfter(lanternNormal, cp02.path)
local upperEntry = firstAfter(normalUpper, cp04.path)
local expertArchEntry = firstAfter(expert.archExpert, cp01.path)
local expertLanternEntry = firstAfter(expert.lanternExpert, cp02.path)
Layout.BranchCosts = {
	Arches = {normal = "West stone arches with short rising gaps and corner landings.", expert = "Inner precision ascent with directional contacts and supported red obstacles."},
	Lanterns = {normal = "Wide outer refuges and the outer machinery loop after all three swings.", expert = "Narrow lane through all three swings, then a direct needle shortcut to the lower lift checkpoint."},
	UpperLift = {normal = "Visible east gap arc to rear boarding and the full upper lift ride.", expert = "West precision journey to rear boarding and the same full upper lift ride."},
}
Layout.Wayfinding.Forks = {
	{name = "E1_StoneArch", approachPath = cp01.path, normalPath = archEntry.path,
		normalOffset = archEntry.offset, expertPath = expertArchEntry.path, expertOffset = expertArchEntry.offset,
		demand = "NARROW TURNS / RED HURDLES"},
	{name = "E2_Lantern", approachPath = cp02.path, normalPath = lanternEntry.path,
		normalOffset = lanternEntry.offset, expertPath = expertLanternEntry.path, expertOffset = expertLanternEntry.offset,
		demand = "THREE SWINGS / LIFT SHORTCUT"},
	{name = "E3_UpperLift", approachPath = cp04.path, normalPath = upperEntry.path,
		normalOffset = upperEntry.offset, normalDeparturePath = upperEntry.path,
		expertPath = expert.braceFirstPath, demand = "WEST PRECISION / FULL LIFT"},
}
Layout.Wayfinding.Markers = {
	{name = "ArchMerge", path = archMerge.path, targetPath = cp02.path, kind = "Merge", mode = "Shared", label = "LANTERN GALLERY"},
	{name = "LowerBoard", path = cp03.path, targetPoint = Layout.LiftOrigins.Lower, kind = "Board", mode = "Shared", label = "LOWER LIFT / TWO BAYS"},
	{name = "UpperRearBoard", path = normalUpperWait.path, targetPoint = Layout.LiftOrigins.Upper, kind = "Board", mode = "Normal", label = "UPPER LIFT / BOTH ROUTES"},
	{name = "CrownMerge", path = upperExit.path, targetPath = crown[2].path, targetOffset = crown[2].offset, kind = "Merge", mode = "Shared", label = "CROWN / FINAL JUMPS"},
	{name = "SharedClimbEntry", path = sharedLastStone.path, targetPath = sharedClimbFirst.path, kind = "Turn", mode = "Shared", label = "CLIMB TO CP01"},
	{name = "ArchReturn", path = archShelf.path, targetPath = archReturn[2].path, kind = "Turn", mode = "Return", label = "RETURN TO CP01"},
	{name = "LiftReturn", path = upperShelf.path, targetPath = upperReturn[2].path, kind = "Turn", mode = "Return", label = "RETURN TO CP04"},
	{name = "GalleryMerge", path = galleryExitNode.path, targetPath = machinery[2].path, targetOffset = machinery[2].offset, kind = "Merge", mode = "Normal", label = "MACHINERY / CP03"},
}
SupportingObstacles.Apply(Layout)
RouteHazardLayout(Layout)
return Layout
