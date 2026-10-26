-- Run only as a temporary normal server Script in a disposable Studio Play session.
-- Insert it under ServerScriptService after Rojo sync. It uses the already-running
-- RaceService, CheckpointService, RespawnService, and CourseHazardService. The
-- generated probes live under the runtime course clone and are removed on exit.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local servicesFolder = game:GetService("ServerScriptService"):WaitForChild("Services")
local RaceService = require(servicesFolder:WaitForChild("RaceService"))
local PlayerRaceService = require(servicesFolder:WaitForChild("PlayerRaceService"))
local CourseService = require(servicesFolder:WaitForChild("CourseService"))
local CheckpointService = require(servicesFolder:WaitForChild("CheckpointService"))
local RespawnService = require(servicesFolder:WaitForChild("RespawnService"))
local CourseHazardService = require(servicesFolder:WaitForChild("CourseHazardService"))
local RaceConstants = require(game:GetService("ReplicatedStorage").Shared.RaceConstants)

local records = {}
local fixtureFolder
local fixture
local spinner
local swing
local course
local player
local character
local humanoid
local root
local bodyPart
local savedPivot
local savedStatus
local savedRecoveryUntil
local savedAutoRotate
local savedPlatformStand
local savedRequiresNeck
local savedPartStates = {}
local savedJointStates = {}
local ownerSnapshots
local wallSnapshots

local function vectorClose(left, right, epsilon)
	return (left - right).Magnitude <= epsilon
end

local function cframeClose(left, right, epsilon)
	return vectorClose(left.Position, right.Position, epsilon)
		and vectorClose(left.RightVector, right.RightVector, epsilon)
		and vectorClose(left.UpVector, right.UpVector, epsilon)
		and vectorClose(left.LookVector, right.LookVector, epsilon)
end

local function vectorText(value)
	return string.format("(%.3f, %.3f, %.3f)", value.X, value.Y, value.Z)
end

local function addRecord(name, data)
	data.name = name
	table.insert(records, data)
end

local function isDirectVisibleBodyPart(item)
	return item:IsA("BasePart")
		and item.Parent == character
		and item ~= root
		and item.Transparency < 1
end

local function overlapParts(hazardPart)
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = { character }
	return Workspace:GetPartsInPart(hazardPart, overlap)
end

local function overlapNames(parts)
	local names = {}
	for _, item in ipairs(parts) do
		table.insert(names, item.Name)
	end
	table.sort(names)
	return names
end

local function containsPart(parts, wanted)
	for _, item in ipairs(parts) do
		if item == wanted then
			return true
		end
	end
	return false
end

local function visibleBodyNames(parts)
	local names = {}
	for _, item in ipairs(parts) do
		if isDirectVisibleBodyPart(item) then
			table.insert(names, item.Name)
		end
	end
	table.sort(names)
	return names
end

local function snapshotParts(container)
	local snapshots = {}
	if container == nil then
		return snapshots
	end

	for _, item in ipairs(container:GetDescendants()) do
		if item:IsA("BasePart") then
			table.insert(snapshots, {
				part = item,
				name = item:GetFullName(),
				parent = item.Parent,
				cframe = item.CFrame,
				moving = item:GetAttribute("KitMotion") ~= nil,
				size = item.Size,
				anchored = item.Anchored,
				canCollide = item.CanCollide,
				canTouch = item.CanTouch,
				canQuery = item.CanQuery,
				transparency = item.Transparency,
			})
		end
	end

	table.sort(snapshots, function(left, right)
		return left.name < right.name
	end)
	return snapshots
end

local function changedSnapshots(snapshots)
	local changed = {}
	for _, snapshot in ipairs(snapshots or {}) do
		local item = snapshot.part
		local unchanged = item.Parent == snapshot.parent
			and (snapshot.moving or cframeClose(item.CFrame, snapshot.cframe, 0.001))
			and vectorClose(item.Size, snapshot.size, 0.001)
			and item.Anchored == snapshot.anchored
			and item.CanCollide == snapshot.canCollide
			and item.CanTouch == snapshot.canTouch
			and item.CanQuery == snapshot.canQuery
			and math.abs(item.Transparency - snapshot.transparency) <= 0.001
		if not unchanged then
			table.insert(changed, snapshot.name)
		end
	end
	return changed
end

local function createKillPart(name, size, cframe, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = true
	part.CanQuery = true
	part.CastShadow = false
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = 0.45
	part:SetAttribute("HazardType", "Kill")
	part:SetAttribute("C09TestFixture", true)
	part.Parent = fixtureFolder
	return part
end

local function createAttachmentProbe(className, name)
	local container = Instance.new(className)
	container.Name = name
	container:SetAttribute("C09TestAttachment", true)
	if container:IsA("Tool") then
		container.CanBeDropped = false
		container.RequiresHandle = true
	end
	container.Parent = character

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1.25, 1.25, 1.25)
	handle.CFrame = fixture.CFrame
	handle.Anchored = true
	handle.CanCollide = false
	handle.CanTouch = true
	handle.CanQuery = true
	handle.Color = Color3.fromRGB(255, 230, 80)
	handle.Material = Enum.Material.Neon
	handle:SetAttribute("C09TestAttachment", true)
	handle.Parent = container
	return container, handle
end

local function clearAttachmentProbes()
	if character == nil then
		return
	end
	for _, item in ipairs(character:GetChildren()) do
		if item:GetAttribute("C09TestAttachment") == true then
			item:Destroy()
		end
	end
end

local function moveFixtureAway()
	if fixture ~= nil and fixture.Parent ~= nil then
		fixture.CFrame = CFrame.new(fixture.CFrame.Position + Vector3.new(0, 80, 0))
	end
end

local function translateSavedLayout(targetPosition)
	local delta = targetPosition - savedPivot.Position
	for part, state in pairs(savedPartStates) do
		if part.Parent ~= nil then
			part.CFrame = state.cframe + delta
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function translateCharacter(delta)
	for part in pairs(savedPartStates) do
		if part.Parent ~= nil then
			part.CFrame += delta
			part.AssemblyLinearVelocity = Vector3.zero
			part.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

local function placeStandardAt(position)
	moveFixtureAway()
	translateSavedLayout(position)
	character:SetAttribute("RecoveryUntil", nil)
	task.wait(0.05)
end

local function placeBodyAt(position)
	placeStandardAt(position)
	translateCharacter(position - bodyPart.Position)
end

local function waitForRecoveryCooldown()
	moveFixtureAway()
	task.wait(1.7)
	character:SetAttribute("RecoveryUntil", nil)
end

local function waitForRecovery(before, timeout)
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		local recoveryUntil = character:GetAttribute("RecoveryUntil")
		if typeof(recoveryUntil) == "number" and recoveryUntil > before then
			return true, recoveryUntil
		end
		task.wait(0.05)
	end
	return false, character:GetAttribute("RecoveryUntil")
end

local function waitForNoRecovery(before, timeout)
	local deadline = os.clock() + timeout
	while os.clock() < deadline do
		local recoveryUntil = character:GetAttribute("RecoveryUntil")
		if typeof(recoveryUntil) == "number" and recoveryUntil > before then
			return false, recoveryUntil
		end
		task.wait(0.05)
	end
	return true, character:GetAttribute("RecoveryUntil")
end

local function assertCheckpointRecovery(name, hazardPart, initialNames, timeout, before)
	local destination = assert(CheckpointService.GetCheckpointRespawnCFrame(player), "No real checkpoint destination")
	local recoveryBefore = before or character:GetAttribute("RecoveryUntil") or 0
	local recovered, recoveryUntil = waitForRecovery(recoveryBefore, timeout or 1)
	local checkpointError = (root.Position - destination.Position).Magnitude
	addRecord(name, {
		hazard = hazardPart:GetFullName(),
		initialOverlap = initialNames,
		recovered = recovered,
		recoveryUntil = recoveryUntil,
		checkpointError = checkpointError,
	})
	assert(recovered, name .. " did not recover the real racer")
	assert(checkpointError < 0.1, name .. " did not use the real checkpoint destination")
end

local function chooseBodyEdgeAxis()
	local away = bodyPart.Position - root.Position
	if away.Magnitude < 0.1 then
		away = bodyPart.CFrame.RightVector
	end
	away = away.Unit
	local choices = {
		{ worldAxis = bodyPart.CFrame.RightVector, localAxis = Vector3.new(1, 0, 0), extent = bodyPart.Size.X },
		{ worldAxis = bodyPart.CFrame.UpVector, localAxis = Vector3.new(0, 1, 0), extent = bodyPart.Size.Y },
		{ worldAxis = -bodyPart.CFrame.LookVector, localAxis = Vector3.new(0, 0, 1), extent = bodyPart.Size.Z },
	}
	local best = choices[1]
	for _, choice in ipairs(choices) do
		if math.abs(choice.worldAxis:Dot(away)) > math.abs(best.worldAxis:Dot(away)) then
			best = choice
		end
	end
	local sign = if best.worldAxis:Dot(away) >= 0 then 1 else -1
	local signedAxis = best.localAxis * sign
	return signedAxis, best.extent
end

local function runBodyEdgeCases()
	waitForRecoveryCooldown()
	clearAttachmentProbes()
	placeStandardAt(CFrame.new(course:GetPivot().Position + Vector3.new(0, 300, 0)).Position)
	local localAxis, extent = chooseBodyEdgeAxis()
	local insideBefore = character:GetAttribute("RecoveryUntil") or 0
	fixture.Size = bodyPart.Size
	fixture.CFrame = bodyPart.CFrame * CFrame.new(localAxis * extent * 0.7)
	local positiveParts = overlapParts(fixture)
	assert(containsPart(positiveParts, bodyPart), "Visible body edge fixture did not overlap the selected body part")
	assert(not containsPart(positiveParts, root), "Body edge probe also overlapped the invisible root")
	assert(#visibleBodyNames(positiveParts) >= 1, "Body edge probe had no visible body contact")
	assertCheckpointRecovery("VisibleBodyEdgeInside", fixture, overlapNames(positiveParts), 1, insideBefore)

	waitForRecoveryCooldown()
	clearAttachmentProbes()
	local basePosition = course:GetPivot().Position + Vector3.new(0, 300, 0)
	placeStandardAt(basePosition)
	local outsideBefore = character:GetAttribute("RecoveryUntil") or 0
	fixture.Size = bodyPart.Size
	fixture.CFrame = bodyPart.CFrame * CFrame.new(localAxis * (extent + 0.1))
	local negativeParts = overlapParts(fixture)
	assert(#visibleBodyNames(negativeParts) == 0, "0.1 outside probe still overlapped a visible body part")
	local safe, recoveryUntil = waitForNoRecovery(outsideBefore, 0.8)
	addRecord("VisibleBodyEdgeOutside_0_1", {
		hazard = fixture:GetFullName(),
		gap = 0.1,
		bodyPart = bodyPart.Name,
		initialOverlap = overlapNames(negativeParts),
		safe = safe,
		recoveryUntil = recoveryUntil,
	})
	assert(safe, "0.1 outside visible body probe recovered the racer")
end

local function runAttachmentCase(name, className)
	waitForRecoveryCooldown()
	clearAttachmentProbes()
	local basePosition = course:GetPivot().Position + Vector3.new(-30, 300, 0)
	placeStandardAt(basePosition)
	fixture.Size = Vector3.new(2, 2, 2)
	local before = character:GetAttribute("RecoveryUntil") or 0
	fixture.CFrame = CFrame.new(course:GetPivot().Position + Vector3.new(0, 300, 0))
	local container, handle = createAttachmentProbe(className, name .. "Probe")
	local parts = overlapParts(fixture)
	assert(containsPart(parts, handle), name .. " handle did not overlap the fixture")
	assert(#visibleBodyNames(parts) == 0, name .. " fixture overlapped a visible body part")
	assert(not containsPart(parts, root), name .. " fixture overlapped the root")
	local safe, recoveryUntil = waitForNoRecovery(before, 0.8)
	addRecord(name .. "OnlySafe", {
		hazard = fixture:GetFullName(),
		probe = handle:GetFullName(),
		initialOverlap = overlapNames(parts),
		safe = safe,
		recoveryUntil = recoveryUntil,
	})
	container:Destroy()
	assert(safe, name .. " only contact recovered the racer")
end

local function runInvisibleRootCase()
	waitForRecoveryCooldown()
	clearAttachmentProbes()
	local basePosition = course:GetPivot().Position + Vector3.new(-30, 300, 0)
	placeStandardAt(basePosition)
	fixture.Size = Vector3.new(2, 2, 2)
	local before = character:GetAttribute("RecoveryUntil") or 0
	fixture.CFrame = CFrame.new(course:GetPivot().Position + Vector3.new(0, 300, 0))
	local fixturePosition = fixture.Position
	root.CFrame = CFrame.new(fixturePosition)
	local originalTransparency = root.Transparency
	root.Transparency = 1
	local parts = overlapParts(fixture)
	assert(containsPart(parts, root), "Invisible root probe did not overlap the fixture")
	assert(#visibleBodyNames(parts) == 0, "Invisible root probe also overlapped a visible body part")
	local safe, recoveryUntil = waitForNoRecovery(before, 0.8)
	addRecord("InvisibleHumanoidRootOnlySafe", {
		hazard = fixture:GetFullName(),
		root = root:GetFullName(),
		rootTransparency = root.Transparency,
		initialOverlap = overlapNames(parts),
		safe = safe,
		recoveryUntil = recoveryUntil,
	})
	root.Transparency = originalTransparency
	assert(safe, "Invisible HumanoidRootPart contact recovered the racer")
end

local function runOwnerStaticCase(ownerPart)
	waitForRecoveryCooldown()
	clearAttachmentProbes()
	local before = character:GetAttribute("RecoveryUntil") or 0
	placeBodyAt(ownerPart.Position)
	local parts = overlapParts(ownerPart)
	assert(containsPart(parts, bodyPart), "Owner static representative did not overlap the selected visible body part")
	assert(#visibleBodyNames(parts) >= 1, "Owner static representative had no visible body contact")
	assertCheckpointRecovery("OwnerStaticVisibleBodyCenter", ownerPart, overlapNames(parts), 1, before)
end

local function runMovingSweepCase(name, movingPart)
	waitForRecoveryCooldown()
	clearAttachmentProbes()
	CourseHazardService.BindActiveCourse()
	local startCFrame = movingPart.CFrame
	local basePosition = course:GetPivot().Position + Vector3.new(0, 300, 0)
	placeStandardAt(basePosition)
	local before = character:GetAttribute("RecoveryUntil") or 0
	local targetPosition = (startCFrame * CFrame.new(0, 0, -3.25)).Position
	translateCharacter(targetPosition - bodyPart.Position)
	local initial = overlapParts(movingPart)
	assert(not containsPart(initial, bodyPart), name .. " was already overlapping before its motion")
	assert(not containsPart(initial, root), name .. " initial sweep probe overlapped the root")
	local initialNames = overlapNames(initial)
	assertCheckpointRecovery(name .. "SweptContact", movingPart, initialNames, 1.25, before)
end

local function stabilizeCharacter()
	savedPivot = character:GetPivot()
	savedStatus = PlayerRaceService.GetPlayerStatus(player)
	savedRecoveryUntil = character:GetAttribute("RecoveryUntil")
	savedAutoRotate = humanoid.AutoRotate
	savedPlatformStand = humanoid.PlatformStand
	savedRequiresNeck = humanoid.RequiresNeck
	humanoid.RequiresNeck = false
	for _, item in ipairs(character:GetDescendants()) do
		if item:IsA("BasePart") then
			savedPartStates[item] = {
				cframe = item.CFrame,
				anchored = item.Anchored,
				canCollide = item.CanCollide,
				canTouch = item.CanTouch,
				canQuery = item.CanQuery,
				transparency = item.Transparency,
				velocity = item.AssemblyLinearVelocity,
				angularVelocity = item.AssemblyAngularVelocity,
			}
			item.Anchored = true
		elseif item:IsA("Motor6D") then
			savedJointStates[item] = item.Enabled
			item.Enabled = false
		end
	end
	root.Anchored = true
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
end

local function restoreCharacter()
	if character == nil or character.Parent == nil then
		return
	end
	clearAttachmentProbes()
	for part, state in pairs(savedPartStates) do
		if part.Parent ~= nil then
			part.Anchored = true
			part.CFrame = state.cframe
		end
	end
	for joint, enabled in pairs(savedJointStates) do
		if joint.Parent ~= nil then
			joint.Enabled = enabled
		end
	end
	for part, state in pairs(savedPartStates) do
		if part.Parent ~= nil then
			part.Anchored = state.anchored
			part.CanCollide = state.canCollide
			part.CanTouch = state.canTouch
			part.CanQuery = state.canQuery
			part.Transparency = state.transparency
			part.AssemblyLinearVelocity = state.velocity
			part.AssemblyAngularVelocity = state.angularVelocity
		end
	end
	if savedAutoRotate ~= nil then
		humanoid.AutoRotate = savedAutoRotate
	end
	if savedPlatformStand ~= nil then
		humanoid.PlatformStand = savedPlatformStand
	end
	if savedRequiresNeck ~= nil then
		humanoid.RequiresNeck = savedRequiresNeck
	end
	character:SetAttribute("RecoveryUntil", savedRecoveryUntil)
end

local function cleanupRuntime()
	clearAttachmentProbes()
	if fixtureFolder ~= nil and fixtureFolder.Parent ~= nil then
		fixtureFolder:Destroy()
	end
	fixtureFolder = nil
	if course ~= nil and course.Parent ~= nil then
		CourseHazardService.BindActiveCourse()
	end
	restoreCharacter()
	if player ~= nil and savedStatus ~= nil and PlayerRaceService.GetPlayerStatus(player) ~= savedStatus then
		PlayerRaceService.SetPlayerStatus(player, savedStatus, "C09 contact test restore")
	end
end

local ok, failure = xpcall(function()
	assert(RunService:IsStudio() and RunService:IsRunning(), "Studio Play required")
	local deadline = os.clock() + 50
	repeat
		player = Players:GetPlayers()[1]
		task.wait(0.1)
	until player ~= nil
		and RaceService.IsRaceActive()
		and PlayerRaceService.IsOfficialRacer(player)
		and PlayerRaceService.GetPlayerStatus(player) == RaceConstants.PlayerRaceStatus.Racing
		or os.clock() > deadline
	assert(
		player
			and RaceService.IsRaceActive()
			and PlayerRaceService.IsOfficialRacer(player)
			and PlayerRaceService.GetPlayerStatus(player) == RaceConstants.PlayerRaceStatus.Racing,
		"Normal race did not start with an official racer"
	)

	course = assert(CourseService.GetActiveCourse(), "No active City Run course")
	assert(course:GetAttribute("CityRunRevision") == "C09", "C09 active course revision is required")
	character = assert(player.Character, "Official racer has no character")
	humanoid = assert(character:FindFirstChildOfClass("Humanoid"), "Racer has no Humanoid")
	root = assert(character:FindFirstChild("HumanoidRootPart"), "Racer has no HumanoidRootPart")
	assert(root:IsA("BasePart"), "HumanoidRootPart is not a BasePart")
	stabilizeCharacter()

	local candidates = {}
	for _, item in ipairs(character:GetChildren()) do
		if isDirectVisibleBodyPart(item) then
			table.insert(candidates, item)
		end
	end
	table.sort(candidates, function(left, right)
		return (left.Position - root.Position).Magnitude > (right.Position - root.Position).Magnitude
	end)
	bodyPart = assert(candidates[1], "Racer has no direct visible body part for contact probes")

	local obstacles = assert(course:FindFirstChild("Obstacles"), "Active course has no Obstacles folder")
	fixtureFolder = Instance.new("Folder")
	fixtureFolder.Name = "C09RuntimeContactFixtures"
	fixtureFolder.Parent = obstacles
	local base = course:GetPivot().Position + Vector3.new(0, 300, 0)
	fixture = createKillPart("VisibleBodyProbe", Vector3.new(2, 2, 2), CFrame.new(base), Color3.fromRGB(255, 80, 80))
	spinner = createKillPart("SpinnerSweepProbe", Vector3.new(10, 0.8, 0.8), CFrame.new(base + Vector3.new(60, 0, 0)), Color3.fromRGB(255, 140, 30))
	spinner:SetAttribute("KitMotion", "Spin")
	spinner:SetAttribute("MotionPeriod", 2)
	spinner:SetAttribute("MotionAxis", "Y")
	swing = createKillPart("SwingSweepProbe", Vector3.new(10, 0.8, 0.8), CFrame.new(base + Vector3.new(120, 0, 0)), Color3.fromRGB(255, 220, 40))
	swing:SetAttribute("KitMotion", "Swing")
	swing:SetAttribute("MotionPeriod", 2)
	swing:SetAttribute("MotionAngle", 90)
	swing:SetAttribute("MotionAxis", "Y")
	CourseHazardService.BindActiveCourse()

	local ownerFolder = assert(course:FindFirstChild("OwnerKillStrips", true), "OwnerKillStrips folder is missing")
	local ownerParts = {}
	for _, item in ipairs(ownerFolder:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("HazardType") == "Kill" then
			table.insert(ownerParts, item)
		end
	end
	table.sort(ownerParts, function(left, right)
		return left:GetFullName() < right:GetFullName()
	end)
	assert(#ownerParts == 15, "Expected 15 current owner Kill Parts after the latest owner edits")
	local spinnerCount, swingCount = 0, 0
	for _, item in ipairs(ownerParts) do
		if item:GetAttribute("KitMotion") == "Spin" then spinnerCount += 1 end
		if item:GetAttribute("KitMotion") == "Swing" then swingCount += 1 end
	end
	assert(spinnerCount == 2 and swingCount == 1, "Expected two owner spinners and one owner swingbar")
	ownerSnapshots = snapshotParts(ownerFolder)
	local ownerEdits = assert(course:FindFirstChild("OwnerEdits"), "OwnerEdits folder is missing")
	local invisibleWalls = assert(ownerEdits:FindFirstChild("InvisibleWalls"), "InvisibleWalls folder is missing")
	wallSnapshots = snapshotParts(invisibleWalls)
	assert(#wallSnapshots == 10, "Expected 10 current invisible-wall parts")
	local ownerStatic
	for _, item in ipairs(ownerParts) do
		if item:GetAttribute("KitMotion") == nil and item.CanQuery then
			if ownerStatic == nil
				or item.Position.Y > ownerStatic.Position.Y + 0.001
				or (math.abs(item.Position.Y - ownerStatic.Position.Y) <= 0.001 and item.Size.Magnitude > ownerStatic.Size.Magnitude)
			then
				ownerStatic = item
			end
		end
	end
	assert(ownerStatic, "No queryable static owner Kill Part was found")

	addRecord("Setup", {
		placeId = game.PlaceId,
		courseRevision = course:GetAttribute("CityRunRevision"),
		reviewBuildId = course:GetAttribute("ReviewBuildId"),
		ownerPartCount = #ownerParts,
		ownerSpinnerCount = spinnerCount,
		ownerSwingCount = swingCount,
		bodyPart = bodyPart.Name,
		bodyPartSize = vectorText(bodyPart.Size),
		fixtureBase = vectorText(base),
		checkpoint = CheckpointService.GetCheckpointRespawnCFrame(player) and "available" or "missing",
		method = "Normal running server services with runtime-only exact Part probes",
	})

	runBodyEdgeCases()
	runAttachmentCase("Accessory", "Accessory")
	runAttachmentCase("Tool", "Tool")
	runInvisibleRootCase()
	runOwnerStaticCase(ownerStatic)
	runMovingSweepCase("GeneratedSpinner", spinner)
	runMovingSweepCase("GeneratedSwing", swing)

	waitForRecoveryCooldown()
	clearAttachmentProbes()
	local bodyProbePosition = course:GetPivot().Position + Vector3.new(0, 300, 0)
	placeBodyAt(bodyProbePosition)
	fixture.Size = Vector3.new(2, 2, 2)
	local firstBefore = character:GetAttribute("RecoveryUntil") or 0
	fixture.CFrame = CFrame.new(bodyProbePosition)
	local bodyParts = overlapParts(fixture)
	assert(containsPart(bodyParts, bodyPart), "Cooldown probe did not overlap the selected visible body part")
	local destination = assert(CheckpointService.GetCheckpointRespawnCFrame(player), "No checkpoint for cooldown probe")
	local firstRecovered, firstUntil = waitForRecovery(firstBefore, 1)
	assert(firstRecovered, "Cooldown probe first contact did not recover")
	local firstRootPosition = root.Position
	moveFixtureAway()
	placeBodyAt(bodyProbePosition)
	character:SetAttribute("RecoveryUntil", firstUntil)
	local secondExpectedRootPosition = root.Position
	local secondBefore = character:GetAttribute("RecoveryUntil") or 0
	fixture.CFrame = CFrame.new(bodyProbePosition)
	local secondSafe, secondUntil = waitForNoRecovery(secondBefore, 0.65)
	local secondError = (root.Position - secondExpectedRootPosition).Magnitude
	addRecord("RecoveryCooldown", {
		firstRecovered = firstRecovered,
		firstRecoveryUntil = firstUntil,
		secondBlocked = secondSafe,
		secondRecoveryUntil = secondUntil,
		firstCheckpointError = (firstRootPosition - destination.Position).Magnitude,
		secondRootError = secondError,
	})
	assert(secondSafe, "Second hazard contact inside the recovery cooldown was accepted")

	waitForRecoveryCooldown()
	clearAttachmentProbes()
	placeBodyAt(bodyProbePosition)
	fixture.Size = Vector3.new(2, 2, 2)
	local inactiveBefore = character:GetAttribute("RecoveryUntil") or 0
	local previousStatus = PlayerRaceService.GetPlayerStatus(player)
	PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Spectating, "C09 inactive contact test")
	fixture.CFrame = CFrame.new(bodyProbePosition)
	local inactiveParts = overlapParts(fixture)
	assert(containsPart(inactiveParts, bodyPart), "Inactive racer probe did not overlap the visible body")
	local inactiveSafe, inactiveUntil = waitForNoRecovery(inactiveBefore, 0.8)
	addRecord("InactiveRacerExcluded", {
		previousStatus = previousStatus,
		statusDuringProbe = PlayerRaceService.GetPlayerStatus(player),
		initialOverlap = overlapNames(inactiveParts),
		safe = inactiveSafe,
		recoveryUntil = inactiveUntil,
	})
	PlayerRaceService.SetPlayerStatus(player, RaceConstants.PlayerRaceStatus.Racing, "C09 inactive contact test restore")
	assert(inactiveSafe, "Inactive racer contact recovered the player")
end, debug.traceback)

local cleanupOk, cleanupFailure = pcall(cleanupRuntime)
if not cleanupOk and ok then
	ok = false
	failure = cleanupFailure
elseif not cleanupOk then
	failure = tostring(failure) .. "\nCleanup: " .. tostring(cleanupFailure)
end

if ownerSnapshots ~= nil then
	local ownerChanged = changedSnapshots(ownerSnapshots)
	local wallsChanged = changedSnapshots(wallSnapshots)
	addRecord("GeometryPreserved", {
		ownerPartCount = #ownerSnapshots,
		ownerChanged = ownerChanged,
		invisibleWallPartCount = #wallSnapshots,
		invisibleWallsChanged = wallsChanged,
		passed = #ownerChanged == 0 and #wallsChanged == 0,
	})
	if #ownerChanged > 0 or #wallsChanged > 0 then
		ok = false
		failure = "Owner or invisible-wall geometry changed during C09 contact tests"
	end
end

script:SetAttribute("Result", HttpService:JSONEncode({
	passed = ok,
	records = records,
	failure = if ok then nil else failure,
	setup = "C09RuntimeContactFixtures are runtime-only Parts parented under the active course; cleanup rebinds production hazards before restoring the player's saved character layout.",
	limitations = "One real official racer, one representative static owner part, exact body/accessory/root filters, generated spinner and swing sweeps, owner and InvisibleWalls preservation. Full multiplayer, device physics, and human race timing remain outside this check.",
}))
print("[CityRunC09Contacts] " .. script:GetAttribute("Result"))
