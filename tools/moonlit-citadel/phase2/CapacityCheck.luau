--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local Check = {}
local bodyNames = {Head = true, HumanoidRootPart = true, UpperTorso = true, LowerTorso = true,
	LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true,
	LeftUpperLeg = true, LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
	Torso = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true}
local function xyz(v) return {v.X, v.Y, v.Z} end

function Check.AvatarDimensions(character)
	local root = assert(character:FindFirstChild("HumanoidRootPart"), "Actor requires an actual root")
	local low, high = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	local bodyParts, accessories = 0, 0
	for _, item in character:GetDescendants() do
		if item:IsA("Accessory") then accessories += 1 end
		if item:IsA("BasePart") and item.Parent == character and bodyNames[item.Name] then
			bodyParts += 1
			for _, x in {-1, 1} do for _, y in {-1, 1} do for _, z in {-1, 1} do
				local p = root.CFrame:PointToObjectSpace(item.CFrame:PointToWorldSpace(item.Size * Vector3.new(x, y, z) / 2))
				low = Vector3.new(math.min(low.X, p.X), math.min(low.Y, p.Y), math.min(low.Z, p.Z))
				high = Vector3.new(math.max(high.X, p.X), math.max(high.Y, p.Y), math.max(high.Z, p.Z))
			end end end
		end
	end
	assert(bodyParts > 0, "No supported R15/R6 body parts")
	return {bodySize = xyz(high - low), bodyParts = bodyParts, accessories = accessories,
		wholeModelSize = xyz(character:GetExtentsSize()), accessoryBoundsExcluded = true}
end

function Check.Occupancy(course, actors)
	assert(RunService:IsStudio(), "Studio evidence tool only")
	assert(course:GetAttribute("CandidateId") == Config.CandidateId, "Wrong course candidate")
	local result = {candidate = Config.CandidateId, realClients = 0, staticMannequins = 0, actors = {}, overlaps = {},
		claim = "Observed standing footprints; not race arrival, boarding or 20-client performance proof"}
	local footprints = {}
	for _, actor in actors do
		local player = Players:GetPlayerFromCharacter(actor)
		local root = assert(actor:FindFirstChild("HumanoidRootPart"), "Actor has no root")
		local humanoid = assert(actor:FindFirstChildOfClass("Humanoid"), "Actor has no Humanoid")
		local dims = Check.AvatarDimensions(actor)
		if player then result.realClients += 1 else result.staticMannequins += 1 end
		local params = RaycastParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, actors
		params.RespectCanCollide = true
		local leg = actor:FindFirstChild("Left Leg")
		local r6 = if humanoid.RigType == Enum.HumanoidRigType.R6 and leg then leg.Size.Y else 0
		local depth = humanoid.HipHeight + r6 + root.Size.Y / 2 + 1
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -depth, 0), params)
		local support = hit and hit.Instance
		local half = Vector3.new(dims.bodySize[1], dims.bodySize[2], dims.bodySize[3]) / 2
		local cornersSupported = support ~= nil and support:IsDescendantOf(course)
		local cornerHits = {}
		for _, x in {-half.X, half.X} do for _, z in {-half.Z, half.Z} do
			local corner = root.CFrame:PointToWorldSpace(Vector3.new(x, 0, z))
			local cornerHit = workspace:Raycast(corner, Vector3.new(0, -depth, 0), params)
			local supported = cornerHit ~= nil and cornerHit.Instance:IsDescendantOf(course)
				and cornerHit.Normal.Y >= math.cos(math.rad(45.5))
				and hit ~= nil and math.abs(cornerHit.Position.Y - hit.Position.Y) <= 1.5
			cornersSupported = cornersSupported and supported
			table.insert(cornerHits, {position = xyz(corner), supported = supported, support = cornerHit and cornerHit.Instance:GetFullName()})
		end end
		local query = OverlapParams.new()
		query.FilterType, query.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, actors
		query.RespectCanCollide = true
		local obstacles = {}
		for _, part in workspace:GetPartBoundsInBox(root.CFrame, Vector3.new(half.X * 2, math.max(2, half.Y * 2 - 1), half.Z * 2), query) do
			if part ~= support then table.insert(obstacles, part:GetFullName()) end
		end
		table.insert(result.actors, {name = actor.Name, kind = if player then "actual-client" else "static-mannequin",
			userId = player and player.UserId, position = xyz(root.Position), dimensions = dims,
			support = support and support:GetFullName(), grounded = humanoid.FloorMaterial ~= Enum.Material.Air,
			cornersSupported = cornersSupported, corners = cornerHits, obstacles = obstacles})
		table.insert(footprints, {root = root, half = half, name = actor.Name})
	end
	for i, a in footprints do for j = i + 1, #footprints do
		local b = footprints[j]
		local direction = Vector3.new(b.root.Position.X - a.root.Position.X, 0, b.root.Position.Z - a.root.Position.Z)
		local function extent(item)
			if direction.Magnitude < 0.01 then return math.max(item.half.X, item.half.Z) end
			return math.abs(item.root.CFrame.RightVector:Dot(direction.Unit)) * item.half.X
				+ math.abs(item.root.CFrame.LookVector:Dot(direction.Unit)) * item.half.Z
		end
		if direction.Magnitude < extent(a) + extent(b) and math.abs(a.root.Position.Y - b.root.Position.Y) < a.half.Y + b.half.Y then
			table.insert(result.overlaps, {a = a.name, b = b.name, centerDistance = direction.Magnitude})
		end
	end end
	return result
end

function Check.TwoOpportunities(bays, options)
	options = options or {}
	local bodyWidth = assert(options.bodyWidth, "Supply measured body footprint width")
	local bodyDepth = assert(options.bodyDepth, "Supply measured body footprint depth")
	local passingGap = options.passingGap or 0.75
	local report = {arrivalCount = options.arrivalCount or 20, opportunities = 2, bays = {}, totalPerOpportunity = 0,
		evidenceKind = "Static planning from explicitly measured usable deck rectangles",
		actualBoardingProven = false, actual20ClientsProven = false}
	for _, bay in bays do
		assert(bay.usableWidth > 0 and bay.usableDepth > 0 and bay.measuredClearance == true,
			"Measure a clear usable rectangle excluding rails, weights, access and headroom first")
		local columns = math.floor((bay.usableWidth + passingGap) / (bodyWidth + passingGap))
		local rows = math.floor((bay.usableDepth + passingGap) / (bodyDepth + passingGap))
		local slots = columns * rows
		table.insert(report.bays, {name = bay.name, columns = columns, rows = rows, staticSlots = slots,
			usableWidth = bay.usableWidth, usableDepth = bay.usableDepth})
		report.totalPerOpportunity += slots
	end
	report.totalTwoOpportunities = report.totalPerOpportunity * 2
	report.staticGoalMet = report.totalTwoOpportunities >= report.arrivalCount
	report.waves = {math.min(report.arrivalCount, report.totalPerOpportunity), math.max(0, report.arrivalCount - report.totalPerOpportunity)}
	return report
end

return Check
