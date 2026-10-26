--!strict
local StandardCourse = {}

StandardCourse.CourseId = "keyboard_circuit"
StandardCourse.Revision = "KC_P3_M05_01"
StandardCourse.CheckpointOrder = {"R1", "CP1", "R2", "CP2", "R3", "CP3", "R4", "F01"}

local function folder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing then
		assert(existing:IsA("Folder"), name .. " must be a Folder")
		return existing
	end
	local result = Instance.new("Folder")
	result.Name, result.Parent = name, parent
	return result
end

local function marker(parent: Instance, name: string, frame: CFrame, size: Vector3, touch: boolean): Part
	local result = Instance.new("Part")
	result.Name, result.CFrame, result.Size = name, frame, size
	result.Anchored, result.Transparency = true, 1
	result.CanCollide, result.CanTouch, result.CanQuery, result.CastShadow = false, touch, false, false
	result.Parent = parent
	return result
end

local function recoveryContact(pads: Instance, id: string): BasePart
	local pad = assert(pads:FindFirstChild(id), "Missing recovery pad " .. id)
	local contact = assert(pad:FindFirstChild("BankContact"), "Missing recovery contact " .. id)
	assert(contact:IsA("BasePart") and contact.Anchored, "Recovery contact must be permanent: " .. id)
	assert(typeof(contact:GetAttribute("SpawnCFrame")) == "CFrame", "Missing safe spawn pose " .. id)
	return contact
end

local function respawnArea(contact: BasePart, spawn: CFrame): Vector3
	local position = contact.CFrame:PointToObjectSpace(spawn.Position)
	local function extent(direction: Vector3): number
		local localDirection = contact.CFrame:VectorToObjectSpace(direction)
		local halfSize = math.abs(localDirection.X) * contact.Size.X / 2 + math.abs(localDirection.Z) * contact.Size.Z / 2
		return math.max(0, 2 * (halfSize - math.abs(position:Dot(localDirection)) - 1.5))
	end
	return Vector3.new(extent(spawn.RightVector), 0, extent(spawn.LookVector))
end

local function bindRecovery(part: BasePart, contact: BasePart, id: string)
	local spawn = contact:GetAttribute("SpawnCFrame") :: CFrame
	part:SetAttribute("RecoveryGate", id)
	part:SetAttribute("RespawnCFrame", spawn)
	part:SetAttribute("RespawnAreaSize", respawnArea(contact, spawn))
end

local function routeBounds(roots: {Instance}, origin: Vector3): (Vector3, Vector3)
	local minimum, maximum = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, root in roots do
		for _, item in root:GetDescendants() do
			if not item:IsA("BasePart") or not (item.CanCollide or item:GetAttribute("KCSupport") or item:GetAttribute("Role") == "Lethal") then continue end
			local frame, half = item.CFrame, item.Size / 2
			local right, up, look = frame.RightVector, frame.UpVector, frame.LookVector
			local reach = Vector3.new(
				math.abs(right.X) * half.X + math.abs(up.X) * half.Y + math.abs(look.X) * half.Z,
				math.abs(right.Y) * half.X + math.abs(up.Y) * half.Y + math.abs(look.Y) * half.Z,
				math.abs(right.Z) * half.X + math.abs(up.Z) * half.Y + math.abs(look.Z) * half.Z
			)
			local low, high = frame.Position - reach, frame.Position + reach
			minimum = Vector3.new(math.min(minimum.X, low.X), math.min(minimum.Y, low.Y), math.min(minimum.Z, low.Z))
			maximum = Vector3.new(math.max(maximum.X, high.X), math.max(maximum.Y, high.Y), math.max(maximum.Z, high.Z))
		end
	end
	assert(minimum.X < maximum.X, "Course has no gameplay geometry")
	-- Keep the full mechanism travel inside the recovery boundary without counting distant artwork.
	minimum = Vector3.new(minimum.X - 48, origin.Y - 20, minimum.Z - 48)
	maximum += Vector3.new(48, 48, 48)
	return minimum, maximum
end

local function alignPlacement(course: Model)
	local bay = course.CheckpointBays.F00
	local contact = bay.BankContact
	local top = bay:GetAttribute("TopPosition")
	local heading = course.Gates.F00:GetAttribute("ForwardDirection")
	assert(typeof(top) == "Vector3" and typeof(heading) == "Vector3", "Missing authored start frame")
	local authored = CFrame.fromMatrix(top, heading, Vector3.yAxis)
	local actual = contact.CFrame * CFrame.new(0, .575, 0)
	local change = actual * authored:Inverse()
	local points = {Origin=true, TopPosition=true, EntryPosition=true, ExitPosition=true, PrecisionStartPosition=true, PrecisionMergePosition=true}
	local frames = {EncounterFrame=true, RestPivot=true, MotionPivot=true, SpawnCFrame=true, MountFrame=true}
	local directions = {ForwardDirection=true, MotionAxis=true}
	local items = course:GetDescendants()
	table.insert(items, course)
	-- Studio moves parts without moving world positions stored in attributes.
	for _, item in items do
		for name, value in item:GetAttributes() do
			if points[name] and typeof(value) == "Vector3" then item:SetAttribute(name, change:PointToWorldSpace(value))
			elseif frames[name] and typeof(value) == "CFrame" then item:SetAttribute(name, change * value)
			elseif directions[name] and typeof(value) == "Vector3" then item:SetAttribute(name, change:VectorToWorldSpace(value)) end
		end
		if item:IsA("Vector3Value") then item.Value = change:PointToWorldSpace(item.Value) end
	end
	course:SetAttribute("PlacementMetadataAligned", true)
end

function StandardCourse.Apply(course: Model): Model
	if course:GetAttribute("SharedCourseRevision") == StandardCourse.Revision then return course end
	assert(course:GetAttribute("MapRevision") == "KC_MAP_M04_01", "Exact M04 course copy required")
	alignPlacement(course)
	local origin = course:GetAttribute("Origin")
	assert(typeof(origin) == "Vector3", "Course origin is missing")
	local pads = assert(course:FindFirstChild("RecoveryPads"), "M04 recovery pads are missing")
	local gates = assert(course:FindFirstChild("Gates"), "M04 route gates are missing")
	local bays = assert(course:FindFirstChild("CheckpointBays"), "M04 checkpoint banks are missing")
	local startBay = assert(bays:FindFirstChild("F00"), "M04 start bank is missing")
	local startContact = assert(startBay:FindFirstChild("BankContact"))
	local startGate = assert(gates:FindFirstChild("F00"))
	assert(startContact:IsA("BasePart") and startGate:IsA("BasePart"), "Start contacts must be BaseParts")
	local contacts: {[string]: BasePart} = {F00 = recoveryContact(pads, "F00")}
	for _, id in StandardCourse.CheckpointOrder do
		if id ~= "F01" then contacts[id] = recoveryContact(pads, id) end
	end
	if pads:FindFirstChild("F01") then
		contacts.F01 = recoveryContact(pads, "F01")
	else
		local bay = assert(bays:FindFirstChild("F01"), "M04 lap-return bank is missing")
		local gate = assert(gates:FindFirstChild("F01"), "M04 lap-return gate is missing")
		local host = assert(bay:FindFirstChild("BankContact"))
		local top = bay:GetAttribute("TopPosition")
		assert(host:IsA("BasePart") and host.Anchored and gate:IsA("BasePart") and typeof(top) == "Vector3", "Lap-return bank must be permanent")
		local pad = Instance.new("Model")
		pad.Name, pad.Parent = "F01", pads
		local contact = marker(pad, "BankContact", host.CFrame, host.Size, false)
		local position = (top :: Vector3) - gate.CFrame.LookVector * 8 + Vector3.new(0, 3.3, 0)
		contact:SetAttribute("SpawnCFrame", CFrame.lookAt(position, position + gate.CFrame.LookVector))
		contact:SetAttribute("Role", "SafeRefuge")
		contact:SetAttribute("RecoveryGate", "F01")
		pad:SetAttribute("Purpose", "Recovery on the existing final bank before the lap return")
		contacts.F01 = contact
	end
	local geometry: {Instance} = {}
	for _, name in {"Districts", "RouteLinks", "ExpertRoutes", "CheckpointBays"} do
		local root = assert(course:FindFirstChild(name), "Missing M04 geometry " .. name)
		table.insert(geometry, root)
	end
	local minimum, maximum = routeBounds(geometry, origin :: Vector3)
	local info = folder(course, "CourseInfo")
	for name, value in {
		CourseId = StandardCourse.CourseId, DisplayName = "Keyboard Circuit", RaceFormat = "LapBased", LapCount = 2,
		Enabled = true, Difficulty = "Normal / Expert", CheckpointCount = #StandardCourse.CheckpointOrder,
		TargetNewPlayerTime = course:GetAttribute("TargetRaceSecondsMax") or 360,
		TargetPracticedTime = course:GetAttribute("TargetRaceSecondsMin") or 240,
	} do info:SetAttribute(name, value) end
	local obstacles, checkpoints = folder(course, "Obstacles"), folder(course, "Checkpoints")
	local routeMarkers, decoration = folder(course, "RouteMarkers"), folder(course, "Decoration")
	local fallZones, bounds = folder(course, "FallZones"), folder(course, "Bounds")
	for _, root in geometry do root.Parent = obstacles end
	for _, name in {"Gates", "RouteEdges"} do
		local item = course:FindFirstChild(name)
		if item then item.Parent = routeMarkers end
	end
	for _, name in {"RoughSurroundings", "MapEnvironment"} do
		local item = course:FindFirstChild(name)
		if item then item.Parent = decoration end
	end
	pads.Parent = checkpoints
	local startPosition = startContact.CFrame.Position
	local startFrame = CFrame.lookAt(startPosition, startPosition + startGate.CFrame.LookVector)
	local start = marker(course, "Start", startFrame, Vector3.new(startContact.Size.Z, .2, startContact.Size.X), false)
	bindRecovery(start, contacts.F00, "F00")
	local spawn = marker(start, "Spawn", contacts.F00:GetAttribute("SpawnCFrame") :: CFrame, Vector3.one, false)
	spawn:SetAttribute("Purpose", "Authored checkpoint recovery pose")
	marker(start, "StartLine", startGate.CFrame, startGate.Size, false)
	for index, id in StandardCourse.CheckpointOrder do
		local contact = contacts[id]
		local trigger = marker(checkpoints, string.format("Checkpoint_%03d", index), contact.CFrame + Vector3.new(0, 3.5, 0), Vector3.new(contact.Size.X, 7, contact.Size.Z), true)
		trigger:SetAttribute("CheckpointIndex", index)
		bindRecovery(trigger, contact, id)
	end
	-- A lap closes after the existing F01-to-F00 return, using the shared forward-crossing finish.
	local finish = marker(course, "Finish", startGate.CFrame, startGate.Size, false)
	finish:SetAttribute("RequireForwardCrossing", true)
	finish:SetAttribute("LapReturnFrom", "F01")
	marker(finish, "FinishLine", startGate.CFrame, startGate.Size, false)
	local center, size = (minimum + maximum) / 2, maximum - minimum
	local volume = marker(bounds, "CourseBounds", CFrame.new(center), size, false)
	volume:SetAttribute("Purpose", "Gameplay footprint with mechanism travel and jump clearance")
	marker(fallZones, "FallZone_Main", CFrame.new(center.X, (origin :: Vector3).Y - 18, center.Z), Vector3.new(size.X + 8, 4, size.Z + 8), true)
	for _, boundary in {
		{name = "FallZone_West", center = Vector3.new(minimum.X - 2, center.Y, center.Z), size = Vector3.new(4, size.Y, size.Z + 8)},
		{name = "FallZone_East", center = Vector3.new(maximum.X + 2, center.Y, center.Z), size = Vector3.new(4, size.Y, size.Z + 8)},
		{name = "FallZone_North", center = Vector3.new(center.X, center.Y, minimum.Z - 2), size = Vector3.new(size.X + 8, size.Y, 4)},
		{name = "FallZone_South", center = Vector3.new(center.X, center.Y, maximum.Z + 2), size = Vector3.new(size.X + 8, size.Y, 4)},
	} do marker(fallZones, boundary.name, CFrame.new(boundary.center), boundary.size, true) end
	for _, item in course:GetDescendants() do
		if item:IsA("BasePart") and item:GetAttribute("Role") == "Lethal" then
			item:SetAttribute("HazardType", "Kill")
			item.CanTouch, item.CanQuery = true, true
		elseif item:IsA("BaseScript") then
			item.Disabled = true
		end
	end
	for _, name in {"Phase2Only", "Phase3MapOnly", "PrototypeOnly", "PrototypeRevision", "KCPhase2SessionEnabled", "KCPhase2PreviewEnabled", "KCPhase2Revision", "KCPhase2RunId"} do course:SetAttribute(name, nil) end
	course.Name = "Course_KeyboardCircuit"
	course:SetAttribute("CourseId", StandardCourse.CourseId)
	course:SetAttribute("ManualEditing", true)
	course:SetAttribute("SharedCourseEnabled", true)
	course:SetAttribute("SharedCourseRevision", StandardCourse.Revision)
	course:SetAttribute("CandidateRevision", StandardCourse.Revision)
	course:SetAttribute("MapRevision", "KC_MAP_M05_01")
	course:SetAttribute("ConstructionIteration", 5)
	course:SetAttribute("CheckpointCount", #StandardCourse.CheckpointOrder)
	course:SetAttribute("RequiredLaps", 2)
	return course
end

return StandardCourse
