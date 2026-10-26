--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local Check = require(script.Parent.CapacityCheck)
local Cases = {}
local OWNED = "MCPhase2CapacityOwned"
local bodyNames = {Head = true, HumanoidRootPart = true, UpperTorso = true, LowerTorso = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true}
local function xyz(value) return {value.X, value.Y, value.Z} end

local function fixtureOnly()
	assert(RunService:IsStudio() and RunService:IsServer() and RunService:IsRunning(), "Studio Play server required")
	assert(game.PlaceId == 0 and game.GameId == 0, "Capacity cases require the owned unpublished fixture")
end

local function resolve(root, path)
	local current = root
	for name in path:gmatch("[^/]+") do
		current = current and current:FindFirstChild(name)
		if not current then return nil end
	end
	return current
end

local function bounds(character)
	local root = assert(character:FindFirstChild("HumanoidRootPart"))
	local low, high = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in character:GetChildren() do
		if not part:IsA("BasePart") or not bodyNames[part.Name] then continue end
		for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
			local point = root.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x, y, z) / 2))
			low = Vector3.new(math.min(low.X, point.X), math.min(low.Y, point.Y), math.min(low.Z, point.Z))
			high = Vector3.new(math.max(high.X, point.X), math.max(high.Y, point.Y), math.max(high.Z, point.Z))
		end end end
	end
	return low, high
end

local function grid(rectangle, width, depth, gap)
	local columns = math.max(0, math.floor((rectangle.width + gap) / (width + gap)))
	local rows = math.max(0, math.floor((rectangle.depth + gap) / (depth + gap)))
	local slots = {}
	for row = 1, rows do for column = 1, columns do
		table.insert(slots, Vector3.new(rectangle.centerX + (column - (columns + 1) / 2) * (width + gap), 0,
			rectangle.centerZ + (row - (rows + 1) / 2) * (depth + gap)))
	end end
	return {columns = columns, rows = rows, slots = slots, capacity = #slots}
end

local function rectangle(part, edgeMargin, laneDepth)
	assert(part:IsA("BasePart") and part.CanCollide and part.CanQuery, "Standing contact must collide and be queryable")
	assert(part.CFrame.UpVector:Dot(Vector3.yAxis) > .999999, "Capacity cases require a level standing contact")
	local minX, maxX = -part.Size.X / 2, part.Size.X / 2
	local minZ, maxZ = -part.Size.Z / 2, part.Size.Z / 2
	local rails = {}
	if laneDepth then
		for _, rail in part.Parent:GetChildren() do
			if not rail:IsA("BasePart") or not rail.CanCollide or not rail.Name:match("^SideRail") then continue end
			local low, high = math.huge, -math.huge
			for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
				local point = part.CFrame:PointToObjectSpace(rail.CFrame:PointToWorldSpace(rail.Size * Vector3.new(x, y, z) / 2))
				low, high = math.min(low, point.X), math.max(high, point.X)
			end end end
			local center = part.CFrame:PointToObjectSpace(rail.Position).X
			if center < 0 then minX = math.max(minX, high) else maxX = math.min(maxX, low) end
			table.insert(rails, {path = rail:GetFullName(), innerX = if center < 0 then high else low})
		end
		assert(#rails == 2, "Measure both actual SideRails before deck planning")
		minZ, maxZ = minZ + laneDepth, maxZ - laneDepth
	end
	minX, maxX, minZ, maxZ = minX + edgeMargin, maxX - edgeMargin, minZ + edgeMargin, maxZ - edgeMargin
	assert(maxX > minX and maxZ > minZ, "No usable standing rectangle")
	return {width = maxX - minX, depth = maxZ - minZ, centerX = (minX + maxX) / 2, centerZ = (minZ + maxZ) / 2,
		minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ, edgeMargin = edgeMargin,
		boardingLaneDepth = laneDepth or 0, exitingLaneDepth = laneDepth or 0, rails = rails}
end

local function normalWaitDefinitions()
	local definitions = {}
	for band = 1, 3 do for _, side in {"Before", "After"} do
		table.insert(definitions, {name = "NormalWait" .. side .. band,
			paths = {"Obstacles/Gallery/NormalWait" .. side .. band .. "/Contact"}, broad20 = true,
			note = "This single wait must support twenty static bodies with recorded corner/headroom clearance; passing connections and actual arrivals require separate evidence"})
	end end
	return definitions
end

function Cases.Preview(options)
	options = options or {}
	local preview = {candidate = Config.CandidateId, actual20ClientsProven = false, clearanceProven = false,
		source = if options.course then "Actual contact dimensions and static grid preview" else "Declared single-pad case definitions", cases = {}}
	for _, definition in normalWaitDefinitions() do
		local item = {name = definition.name, path = definition.paths[1], broad20GoalRequired = true, requestedStaticBodies = 20}
		if options.course then
			local support = resolve(options.course, item.path)
			if support then
				item.actualSize = xyz(support.Size)
				if options.bodyWidth and options.bodyDepth then
					assert(options.bodyWidth > 0 and options.bodyDepth > 0, "Supply positive measured body dimensions")
					local rect = rectangle(support, options.edgeMargin or .375)
					local plan = grid(rect, options.bodyWidth, options.bodyDepth, options.passingGap or .75)
					item.columns, item.rows, item.staticGridSlots = plan.columns, plan.rows, plan.capacity
				end
			else item.missingSupport = true end
		end
		table.insert(preview.cases, item)
	end
	return preview
end

function Cases.Cleanup(folder)
	fixtureOnly()
	if typeof(folder) == "string" then folder = Workspace:FindFirstChild(folder) end
	assert(folder and folder:IsA("Folder") and folder.Parent == Workspace and folder:GetAttribute(OWNED) == true
		and folder:GetAttribute("CreatedBy") == "CapacityCases", "Only this tool's owned mannequin folder may be removed")
	folder:Destroy()
end

function Cases.Snapshot(services, options)
	fixtureOnly()
	options = options or {}
	local course = assert(services.CourseService.GetActiveCourse(), "No actual active course")
	assert(course:GetAttribute("CourseId") == Config.CourseId and course:GetAttribute("CandidateId") == Config.CandidateId, "Wrong active candidate")
	assert(services.MoonlitCitadelService and services.MoonlitCitadelService.GetDiagnostics().bound == false,
		"The lead must stop MoonlitCitadelService before measuring authored stationary poses")
	local template = options.template
	if not template then
		for _, player in Players:GetPlayers() do
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then template = player.Character; break end
		end
	end
	local templatePlayer = assert(template and Players:GetPlayerFromCharacter(template), "Supply a current actual Player.Character")
	local humanoid = assert(template:FindFirstChildOfClass("Humanoid"))
	assert(humanoid.RigType == Enum.HumanoidRigType.R15 and humanoid.Health > 0, "Living actual R15 template required")
	local templateRoot = assert(template:FindFirstChild("HumanoidRootPart"))
	local measured = Check.AvatarDimensions(template)
	local low, high = bounds(template)
	local size, bodyCenter = high - low, (high + low) / 2
	local gap, margin, laneDepth = options.passingGap or .75, options.edgeMargin or .375, options.laneDepth or 1.5
	local headroomMargin = options.headroomMargin or .25
	assert(gap >= .75 and margin >= 0 and laneDepth >= 1.5, "Keep at least .75 spacing and two 1.5-stud deck access lanes")
	assert(headroomMargin >= 0, "Headroom margin cannot be negative")
	local definitions = {
		{name = "StartCourt", paths = {"Obstacles/Gate/GateCourt/Contact"}, broad20 = true},
		{name = "FinishCourt", paths = {"Obstacles/Crown/CrownTerrace/Contact"}, broad20 = true},
		{name = "CP01Terrace", paths = {"Obstacles/SharedArches/CP01Terrace/Contact"}, broad20 = true},
		{name = "CP02Terrace", paths = {"Obstacles/Gallery/CP02Terrace/Contact"}, broad20 = true},
		{name = "CP03Terrace", paths = {"Obstacles/Lifts/CP03Terrace/Contact"}, broad20 = true},
		{name = "CP04Terrace", paths = {"Obstacles/Lifts/CP04Terrace/Contact"}, broad20 = true},
		{name = "UpperRearWait", paths = {"Obstacles/Lifts/UpperRearBoarding/Contact"}, broad20 = true},
		{name = "UpperMerge", paths = {"Obstacles/Lifts/SharedUpperExit/Contact"}, broad20 = true},
	}
	for index = 1, 4 do table.insert(definitions, {name = "CP0" .. index .. "Pocket", paths = {"Obstacles/RecoveryPockets/CP0" .. index .. "Pocket/Contact"}, broad20 = false, note = "Side recovery pocket; does not claim full-group staging"}) end
	for _, definition in normalWaitDefinitions() do table.insert(definitions, definition) end
	for band = 1, 3 do
		table.insert(definitions, {name = "NormalWaitPair" .. band,
			paths = {"Obstacles/Gallery/NormalWaitBefore" .. band .. "/Contact", "Obstacles/Gallery/NormalWaitAfter" .. band .. "/Contact"},
			broad20 = false, explicitOnly = true, splitPlanning = true,
			note = "Explicit split-pair planning only; racers on opposite sides of a hazard do not establish a full arriving-group wait"})
		for _, side in {"Before", "After"} do
			table.insert(definitions, {name = "Expert" .. side .. band, paths = {"Obstacles/Gallery/Expert" .. side .. band .. "/Contact"}, broad20 = false,
				note = "Limited Expert perch. Twenty racers need separate waiting/queue space; this case does not establish that queue or its connection"})
		end
	end
	for _, stage in {"Lower", "Upper"} do
		table.insert(definitions, {name = stage .. "Decks", stage = stage, paths = {"Obstacles/MovingCars/" .. stage .. "_Bay1/Deck", "Obstacles/MovingCars/" .. stage .. "_Bay2/Deck"}, broad20 = false,
			note = "Static bay slots and two planned waves; no actual boarding or twenty-client claim"})
	end
	local selected = {}
	if options.caseNames then
		for _, name in options.caseNames do selected[name] = true end
		for name in selected do
			local known = false
			for _, definition in definitions do if definition.name == name then known = true end end
			assert(known, "Unknown capacity case " .. name)
		end
	end
	local folder = Instance.new("Folder")
	folder.Name = "MoonlitCapacity_" .. HttpService:GenerateGUID(false)
	folder:SetAttribute(OWNED, true)
	folder:SetAttribute("CreatedBy", "CapacityCases")
	folder:SetAttribute("CandidateId", Config.CandidateId)
	folder.Parent = Workspace
	local actors = {}
	local report = {candidate = Config.CandidateId, course = course:GetFullName(), templateUserId = templatePlayer.UserId,
		templateDimensions = measured, templateBounds = {low = xyz(low), high = xyz(high)}, passingGap = gap,
		createdStaticMannequins = 20, actualPlayerCharactersCloned = 1, actualClientsObserved = #Players:GetPlayers(),
		actual20ClientsProven = false, actualBoardingProven = false, cases = {},
		evidenceKind = "Static anchored copies of the current actual R15 body pose; not multiplayer, arrival, movement or timing evidence",
		ownedFolderName = folder.Name, notes = "Accessories/copied scripts are removed only from owned clones. Actual character collision flags, body geometry and source scripts are preserved."}
	local function parkActors()
		for index, actor in actors do actor:PivotTo(CFrame.new(course:GetPivot().Position + Vector3.new(index * 10, -10000, 0))) end
	end
	local function run()
		for index = 1, 20 do
			local originalArchivable = template.Archivable
			template.Archivable = true
			local ok, actor = pcall(function() return template:Clone() end)
			template.Archivable = originalArchivable
			assert(ok and actor, "Actual character clone failed")
			actor.Name = string.format("CapacityActor_%02d", index)
			actor:SetAttribute(OWNED, true)
			for _, item in actor:GetDescendants() do
				if item:IsA("LuaSourceContainer") or item:IsA("Accessory") or item:IsA("Tool") or item:IsA("Animator") then item:Destroy()
				elseif item:IsA("BasePart") then item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false end
			end
			actor:FindFirstChildOfClass("Humanoid").EvaluateStateMachine = false
			actor:FindFirstChildOfClass("Humanoid").DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			actor.Parent = folder
			table.insert(actors, actor)
		end
		parkActors()
		local exclusions = table.clone(actors)
		for _, player in Players:GetPlayers() do if player.Character then table.insert(exclusions, player.Character) end end
		local ray = RaycastParams.new()
		ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Exclude, exclusions, true
		ray.CollisionGroup = templateRoot.CollisionGroup
		local query = OverlapParams.new()
		query.FilterType, query.FilterDescendantsInstances, query.RespectCanCollide = Enum.RaycastFilterType.Exclude, exclusions, true
		query.CollisionGroup = templateRoot.CollisionGroup
		local function measureActor(actor, support, rect)
			local root = actor.HumanoidRootPart
			local result = {actor = actor.Name, support = support:GetFullName(), corners = {}, headroom = {}, obstacles = {}, fullCornerClearance = true}
			local requiredHeight = size.Y + headroomMargin
			local topFrame = support.CFrame * CFrame.new(0, support.Size.Y / 2, 0)
			for _, x in {low.X, high.X} do for _, z in {low.Z, high.Z} do
				local corner = root.CFrame:PointToWorldSpace(Vector3.new(x, 0, z))
				local hit = Workspace:Raycast(corner, Vector3.new(0, low.Y - 1, 0), ray)
				local localPoint = topFrame:PointToObjectSpace(corner)
				local inside = localPoint.X >= rect.minX - .001 and localPoint.X <= rect.maxX + .001 and localPoint.Z >= rect.minZ - .001 and localPoint.Z <= rect.maxZ + .001
				local coplanarWalkable = hit ~= nil and support.Name ~= "Deck"
					and hit.Instance:IsDescendantOf(course) and hit.Instance:GetAttribute("MCWalkable") == true
					and math.abs(topFrame:PointToObjectSpace(hit.Position).Y) <= .05
				local valid = inside and hit ~= nil and (hit.Instance == support or coplanarWalkable) and hit.Normal.Y > .999
				table.insert(result.corners, {position = xyz(corner), support = hit and hit.Instance:GetFullName(),
					supportPoint = hit and xyz(hit.Position), coplanarWalkable = coplanarWalkable,
					supported = valid, insideUsableRectangle = inside})
				result.fullCornerClearance = result.fullCornerClearance and valid
				local origin = topFrame:PointToWorldSpace(Vector3.new(localPoint.X, .03, localPoint.Z))
				local overhead = Workspace:Raycast(origin, Vector3.yAxis * requiredHeight, ray)
				table.insert(result.headroom, {position = xyz(origin), required = requiredHeight, clearToRequiredHeight = overhead == nil,
					available = overhead and overhead.Distance, blocker = overhead and overhead.Instance:GetFullName()})
				if overhead then result.fullCornerClearance = false end
			end end
			local boxFrame = root.CFrame * CFrame.new(bodyCenter) + Vector3.yAxis * headroomMargin / 2
			for _, obstacle in Workspace:GetPartBoundsInBox(boxFrame, Vector3.new(math.max(.05, size.X - .04), math.max(.05, size.Y + headroomMargin - .04), math.max(.05, size.Z - .04)), query) do
				if obstacle ~= support then table.insert(result.obstacles, obstacle:GetFullName()); result.fullCornerClearance = false end
			end
			return result
		end
		local function placeWave(targets, count)
			parkActors()
			local placed, checks, rejected, full = {}, {}, {}, true
			local indices = {}
			for index = 1, #targets do indices[index] = 1 end
			while #placed < count do
				local advanced = false
				for index, target in targets do
					if #placed >= count then break end
					local point = target.plan.slots[indices[index]]
					if not point then continue end
					indices[index] += 1
					local actor = actors[#placed + 1]
					local frame = target.support.CFrame * CFrame.new(0, target.support.Size.Y / 2, 0)
					local desiredRoot = frame * CFrame.new(point.X - bodyCenter.X, -low.Y, point.Z - bodyCenter.Z)
					actor:PivotTo(desiredRoot * actor.HumanoidRootPart.CFrame:Inverse() * actor:GetPivot())
					local checked = measureActor(actor, target.support, target.rectangle)
					advanced = true
					if not checked.fullCornerClearance then
						table.insert(rejected, checked)
						continue
					end
					table.insert(placed, actor)
					table.insert(checks, checked)
					full = full and checked.fullCornerClearance
				end
				if not advanced then break end
			end
			local occupancy = Check.Occupancy(course, placed)
			full = full and #occupancy.overlaps == 0 and #placed == count
			return {requested = count, occupiedStaticMannequins = #placed, unallocated = count - #placed, fullCornerClearance = full,
				worldChecks = checks, rejectedGridSlots = rejected, occupancy = occupancy, standingPhysicsProven = false,
				allocationPolicy = "Declared grid in fixed order; retain every rejected position and allocate only measured clear positions",
				queryPolicy = "worldChecks exclude all actual player characters and owned clones; the existing raw Occupancy report may also see unlisted actual characters"}
		end
		for _, definition in definitions do
			if options.caseNames and not selected[definition.name] then continue end
			if definition.explicitOnly and not selected[definition.name] then continue end
			local case = {name = definition.name, broad20GoalRequired = definition.broad20, splitPlanningOnly = definition.splitPlanning == true,
				note = definition.note, targets = {}, requestedArrival = if definition.broad20 or definition.stage then 20 else nil}
			table.insert(report.cases, case)
			local targets = {}
			for _, path in definition.paths do
				local support = resolve(course, path)
				if not support then case.failure = "Missing actual support " .. path; break end
				local rect = rectangle(support, margin, if definition.stage then laneDepth else nil)
				local plan = grid(rect, size.X, size.Z, gap)
				table.insert(targets, {support = support, rectangle = rect, plan = plan})
				table.insert(case.targets, {path = path, rectangle = rect, columns = plan.columns, rows = plan.rows, staticSlots = plan.capacity})
			end
			if case.failure then case.full20StaticGoalMet = false; continue end
			local capacity = 0
			for _, target in targets do capacity += target.plan.capacity end
			case.totalStaticSlots = capacity
			if definition.stage then
				local firstCount = math.min(20, capacity)
				case.wave1 = placeWave(targets, firstCount)
				case.wave2 = placeWave(targets, math.max(0, 20 - firstCount))
				local allSlotsChecked = firstCount == capacity and case.wave1.fullCornerClearance
				if allSlotsChecked and case.wave2.fullCornerClearance then
					local bays = {}
					for _, target in targets do table.insert(bays, {name = target.support.Parent.Name, usableWidth = target.rectangle.width, usableDepth = target.rectangle.depth, measuredClearance = true}) end
					case.twoOpportunities = Check.TwoOpportunities(bays, {bodyWidth = size.X, bodyDepth = size.Z, arrivalCount = 20, passingGap = gap})
				else
					case.twoOpportunityFailure = "Not every usable grid slot and both planned waves have confirmed full corner/headroom/world clearance"
				end
				case.full20StaticGoalMet = case.twoOpportunities ~= nil and case.twoOpportunities.staticGoalMet
			elseif definition.broad20 then
				case.occupancy20 = placeWave(targets, 20)
				case.full20StaticGoalMet = case.occupancy20.fullCornerClearance
				if not case.full20StaticGoalMet then
					case.failure = if case.occupancy20.unallocated > 0 then tostring(case.occupancy20.unallocated) .. " actors do not fit this measured grid"
						else "A standing corner, headroom, world-clearance or footprint-overlap check failed"
				end
			elseif definition.splitPlanning then
				case.splitOccupancy20 = placeWave(targets, 20)
				case.split20StandingPlanMet = case.splitOccupancy20.fullCornerClearance
				case.full20StaticGoalMet = false
				case.arrivingGroupGoalProven = false
				if not case.split20StandingPlanMet then case.failure = "Split planning clearance or available grid slots are insufficient" end
			else
				local requested = math.min(20, capacity)
				case.localCapacityLimit = capacity
				case.requestedLocalBodies = requested
				case.localOccupancy = placeWave(targets, requested)
				case.localClearancePassed = case.localOccupancy.fullCornerClearance
				case.full20StaticGoalMet = false
				case.capacityLimitNote = tostring(capacity) .. " measured local slots; no full-group waiting requirement is assigned to this space"
				if not case.localClearancePassed then case.failure = "Local standing corner, headroom, world-clearance or footprint-overlap check failed" end
			end
		end
	end
	local ok, failure = xpcall(run, debug.traceback)
	if not ok then Cases.Cleanup(folder); error(failure) end
	if options.KeepForView == true then
		report.cleanup = "Kept only this tool's owned clones; remove through CapacityCases.Cleanup(report.ownedFolderName)"
	else
		Cases.Cleanup(folder)
		report.cleanup = "Owned clones removed"
	end
	report.summary = {}
	for _, case in report.cases do table.insert(report.summary, {name = case.name, staticSlots = case.totalStaticSlots,
		full20StaticGoalMet = case.full20StaticGoalMet, broad20GoalRequired = case.broad20GoalRequired,
		splitPlanningOnly = case.splitPlanningOnly, split20StandingPlanMet = case.split20StandingPlanMet,
		localCapacityLimit = case.localCapacityLimit, localClearancePassed = case.localClearancePassed, capacityLimitNote = case.capacityLimitNote,
		failure = case.failure or case.twoOpportunityFailure}) end
	return report
end

return Cases
