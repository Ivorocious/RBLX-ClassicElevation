-- Run as a temporary normal server Script in a disposable Studio Play session.
local services = game.ServerScriptService.Services
local CourseService = require(services.CourseService)
local CheckpointService = require(services.CheckpointService)
local PlayerRaceService = require(services.PlayerRaceService)
local HazardConfig = require(game:GetService("ReplicatedStorage").Config.HazardConfig)
local records = {}
local player = game.Players:GetPlayers()[1]
local character = player and player.Character
local root = character and character:FindFirstChild("HumanoidRootPart")
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local savedPivot = character and character:GetPivot()
local savedAnchored = root and root.Anchored

local function awaitCondition(predicate, seconds, message)
	local deadline = os.clock() + seconds
	repeat task.wait(.025) until predicate() or os.clock() > deadline
	assert(predicate(), message)
end

local function hazard(course, name)
	return assert(course.Obstacles.C10Obstacles[name]:FindFirstChildWhichIsA("BasePart", true))
end

local ok, failure = xpcall(function()
	assert(game.PlaceId == 85558151074819 and game:GetService("RunService"):IsRunning())
	assert(root and humanoid and PlayerRaceService.GetPlayerStatus(player) == "Racing")
	local course = assert(CourseService.GetActiveCourse())
	assert(course:GetAttribute("CityRunRevision") == "C10")
	for index = CheckpointService.GetLatestCheckpointIndex(player) + 1, 3 do
		CheckpointService.SkipCheckpointForStudio(player)
		awaitCondition(function() return CheckpointService.GetLatestCheckpointIndex(player) >= index end, 3,
			"Checkpoint setup did not register normally")
	end
	local destination = CheckpointService.GetCheckpointRespawnCFrame(player)
	root.Anchored = true
	for _, name in { "Hurdle_DistrictRoofs_00_01", "Spinner_DistrictRoofs_02_01" } do
		task.wait(1.8)
		local part = hazard(course, name)
		local before = character:GetAttribute("RecoveryUntil") or 0
		character:PivotTo(CFrame.new(part.Position + Vector3.new(0, 2, 0)))
		awaitCondition(function() return (character:GetAttribute("RecoveryUntil") or 0) > before end, 2,
			name .. " did not recover the racer")
		local distance = (root.Position - destination.Position).Magnitude
		assert(distance < .1, "Hazard recovery missed CP03")
		table.insert(records, { name = name, recovered = true, checkpoint = 3, destinationError = distance })
	end
	local spinner = hazard(course, "Spinner_DistrictRoofs_02_01")
	local first = spinner.CFrame.RightVector
	task.wait(.5)
	local angle = math.deg(math.acos(math.clamp(first:Dot(spinner.CFrame.RightVector), -1, 1)))
	assert(angle > 10 and angle < 40, "Imported spinner did not advance at its configured pace")
	table.insert(records, { name = "SpinnerMotion", degreesInHalfSecond = angle })
	local tile = hazard(course, "StationCrumble_Row01_Lane2")
	local side = hazard(course, "StationCrumble_Row01_Lane1")
	local originalColor = tile.Color
	local originalCFrame = tile.CFrame
	root.Anchored = false
	root:SetNetworkOwner(nil)
	character:PivotTo(CFrame.new(tile.Position + Vector3.new(0, tile.Size.Y / 2 + humanoid.HipHeight + root.Size.Y / 2 + .3, 0)))
	root.AssemblyLinearVelocity = Vector3.zero
	awaitCondition(function() return tile:GetAttribute("HazardPhase") == "Warning" end, 2, "Tile touch did not warn")
	local warningCFrame = tile.CFrame
	task.wait(.1)
	assert(
		(tile.Position - warningCFrame.Position).Magnitude > .01 and tile.Color == originalColor,
		"Tile warning should shake without changing its authored color"
	)
	local warnedAt = workspace:GetServerTimeNow()
	local scheduledWarning = tile:GetAttribute("NextPhaseAt") - warnedAt
	root.Anchored = true
	character:PivotTo(destination)
	awaitCondition(function() return tile:GetAttribute("HazardPhase") == "Falling" end, 2, "Tile did not begin falling")
	awaitCondition(function()
		return tile.Position.Y < originalCFrame.Position.Y - HazardConfig.Crumble.FallDistance * .5
	end, 2, "Tile did not visibly fall")
	awaitCondition(function() return tile:GetAttribute("HazardPhase") == "Gone" end, 2, "Tile did not complete its fall")
	local fallenAt = workspace:GetServerTimeNow()
	assert(not tile.CanCollide and not tile.CanTouch and tile.Transparency == 0)
	for _, visual in tile:GetDescendants() do
		if visual:IsA("BasePart") then assert(visual.Transparency < 1 and not visual.CanCollide and not visual.CanTouch) end
	end
	assert(side:GetAttribute("HazardPhase") == "Solid" and side.CanCollide, "Untouched lane also collapsed")
	local raycast = RaycastParams.new()
	raycast.FilterType = Enum.RaycastFilterType.Include
	raycast.FilterDescendantsInstances = { course }
	raycast.RespectCanCollide = true
	local hiddenFloor = workspace:Raycast(tile.Position + Vector3.new(0, 2, 0), Vector3.new(0, -12, 0), raycast)
	assert(hiddenFloor == nil, "An invisible or support floor remains under a gone tile")
	awaitCondition(function() return tile:GetAttribute("HazardPhase") == "Solid" end, 3, "Tile did not restore")
	assert(tile.CanCollide and tile.CanTouch and tile.Transparency == 0 and tile.Color == originalColor)
	table.insert(records, { name = "CrumbleCycle", remainingWarningSeconds = scheduledWarning,
		observedWarningSeconds = fallenAt - warnedAt, observedGoneSeconds = workspace:GetServerTimeNow() - fallenAt,
		adjacentLaneStayedSolid = true, hiddenFloorWithin12Studs = false, restored = true })
end, debug.traceback)

if root and root.Parent then
	character:PivotTo(savedPivot)
	root.Anchored = savedAnchored
	root.AssemblyLinearVelocity = Vector3.zero
	if not root.Anchored then root:SetNetworkOwnershipAuto() end
end
script:SetAttribute("Result", game.HttpService:JSONEncode({ passed = ok, records = records,
	failure = if ok then nil else failure,
	method = "Actual imported C10 hazards, normal server services and real racer; checkpoint skips only set up the probe",
	limitation = "Does not establish full human traversal, multiplayer timing, touch controls or performance" }))
