--!strict

-- Run from a temporary server Script during Studio Play, never in a published server.
local Hazards = {}

local function waitUntil(predicate: () -> boolean, timeout: number, failureMessage: string)
	local deadline = os.clock() + timeout

	while not predicate() and os.clock() < deadline do
		task.wait(0.05)
	end

	assert(predicate(), failureMessage)
end

function Hazards.Run()
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	local HttpService = game:GetService("HttpService")
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	local ServerStorage = game:GetService("ServerStorage")
	local Workspace = game:GetService("Workspace")
	assert(not ServerStorage:FindFirstChild("ClassicAscentHazardReport"), "Already run this session")

	local HazardConfig = require(ReplicatedStorage.Config.HazardConfig)
	local report = Instance.new("Folder")
	report.Name = "ClassicAscentHazardReport"
	report.Parent = ServerStorage
	report:SetAttribute("Status", "Running")
	local checks = {}

	local function check(condition: boolean, message: string)
		assert(condition, message)
		table.insert(checks, message)
		report:SetAttribute("Checks", HttpService:JSONEncode(checks))
	end

	local ok, failure = pcall(function()
		local services = ServerScriptService.Services
		local courseHazards = require(services.CourseHazardService)
		local race = require(services.RaceService)
		local results = require(services.ResultsService)

		waitUntil(race.IsRaceActive, 50, "Official race did not start")
		local player = Players:GetPlayers()[1]
		assert(player ~= nil and player.Character ~= nil, "One player character is required")
		local course = Workspace:FindFirstChild("RaceCourse")
		assert(course ~= nil and course:IsA("Model"), "Active RaceCourse is required")

		local hazardsByType: { [string]: BasePart } = {}

		for _, descendant in ipairs(course:GetDescendants()) do
			if descendant:IsA("BasePart") then
				local hazardType = descendant:GetAttribute(HazardConfig.AttributeNames.HazardType)

				if typeof(hazardType) == "string" and hazardsByType[hazardType] == nil then
					hazardsByType[hazardType] = descendant
				end
			end
		end

		local killPart = hazardsByType[HazardConfig.HazardTypes.Kill]
		local fallingRock = hazardsByType[HazardConfig.HazardTypes.FallingRock]
		local crumble = hazardsByType[HazardConfig.HazardTypes.Crumble]
		assert(killPart ~= nil, "Kill hazard is required")
		assert(fallingRock ~= nil, "FallingRock hazard is required")
		assert(crumble ~= nil, "Crumble hazard is required")

		courseHazards.BindActiveCourse()
		courseHazards.BindActiveCourse()

		local record = results.GetCurrentRaceResult()
		assert(record ~= nil and #record.activeRacers == 1, "Solo official race is required")
		local row = record.activeRacers[1]
		local firstCheckpoint = course:FindFirstChild("Checkpoint_001", true)
		assert(firstCheckpoint ~= nil and firstCheckpoint:IsA("BasePart"), "Checkpoint_001 is required")

		local function getCharacter(): (Model, Humanoid, BasePart)
			local character = player.Character
			assert(character ~= nil, "Player character is missing")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")
			assert(humanoid ~= nil, "Player Humanoid is missing")
			assert(root ~= nil and root:IsA("BasePart"), "Player HumanoidRootPart is missing")
			return character, humanoid, root
		end

		local function pivotTo(target: CFrame)
			local character, _humanoid, root = getCharacter()
			root:SetNetworkOwner(nil)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			character:PivotTo(target)
		end

		local function waitForHazardRecovery(expectedFalls: number): (Model, Humanoid, BasePart)
			waitUntil(function()
				return row.falls == expectedFalls
			end, 3, "Hazard recovery did not record exactly one fall")
			return getCharacter()
		end

		pivotTo(firstCheckpoint.CFrame + Vector3.new(0, 4, 0))
		waitUntil(function()
			return row.nextCheckpointIndex >= 2
		end, 2, "Checkpoint_001 did not register")

		local fallsBeforeKill = row.falls
		local characterBeforeKill = player.Character :: Model
		pivotTo(killPart.CFrame)
		local recoveredCharacter, recoveredHumanoid, respawnedRoot = waitForHazardRecovery(fallsBeforeKill + 1)
		check(recoveredCharacter == characterBeforeKill, "Static kill preserves the current character")
		check(recoveredHumanoid.Health > 0, "Static kill recovery keeps the humanoid alive")
		check(
			(respawnedRoot.Position - firstCheckpoint.Position).Magnitude < 12,
			"Static kill returns the racer to the latest checkpoint"
		)
		task.wait(1.7)
		check(row.falls == fallsBeforeKill + 1, "Static kill records one fall after repeated binding")

		local warning = fallingRock.Parent and fallingRock.Parent:FindFirstChild("Warning")
		assert(warning ~= nil and warning:IsA("BasePart"), "FallingRock warning part is required")
		waitUntil(function()
			local nextPhaseAt = fallingRock:GetAttribute(HazardConfig.AttributeNames.NextPhaseAt)

			return fallingRock:GetAttribute(HazardConfig.AttributeNames.HazardPhase)
				== HazardConfig.Phases.Warning
				and typeof(nextPhaseAt) == "number"
				and nextPhaseAt > Workspace:GetServerTimeNow()
		end, 12, "FallingRock did not enter Warning")
		check(
			warning.Transparency < 1
				and (fallingRock:GetAttribute(HazardConfig.AttributeNames.NextPhaseAt) :: number)
					> Workspace:GetServerTimeNow(),
			"FallingRock exposes its visible warning and next phase time"
		)
		waitUntil(function()
			return fallingRock:GetAttribute(HazardConfig.AttributeNames.HazardPhase)
				== HazardConfig.Phases.Falling
		end, 3, "FallingRock did not become active")

		local fallsBeforeRock = row.falls
		local characterBeforeRock, humanoidBeforeRock = getCharacter()
		local hitDeadline = os.clock() + HazardConfig.FallingRock.FallDuration

		while row.falls == fallsBeforeRock and os.clock() < hitDeadline do
			pivotTo(fallingRock.CFrame)
			task.wait(0.03)
		end

		local recoveredRockCharacter, recoveredRockHumanoid = waitForHazardRecovery(fallsBeforeRock + 1)
		check(recoveredRockCharacter == characterBeforeRock, "Active FallingRock preserves the current character")
		check(recoveredRockHumanoid == humanoidBeforeRock and humanoidBeforeRock.Health > 0, "Active FallingRock recovers without killing")

		local originalCanCollide = crumble.CanCollide
		local originalColor = crumble.Color
		local originalMaterial = crumble.Material
		local originalTransparencies: { [BasePart]: number } = {
			[crumble] = crumble.Transparency,
		}
		local detailCollision: { [BasePart]: boolean } = {}

		for _, descendant in ipairs(crumble:GetDescendants()) do
			if descendant:IsA("BasePart") then
				originalTransparencies[descendant] = descendant.Transparency
				detailCollision[descendant] = descendant.CanCollide
			end
		end

		pivotTo(crumble.CFrame)
		waitUntil(function()
			return crumble:GetAttribute(HazardConfig.AttributeNames.HazardPhase)
				== HazardConfig.Phases.Warning
		end, 2, "Crumble did not enter Warning")
		check(
			crumble.Color ~= originalColor or crumble.Material ~= originalMaterial,
			"Crumble gives a readable warning before opening"
		)
		waitUntil(function()
			return crumble:GetAttribute(HazardConfig.AttributeNames.HazardPhase) == HazardConfig.Phases.Gone
		end, 2, "Crumble did not open")
		local allVisualsHidden = true
		local detailCollisionPreserved = true

		for visual in pairs(originalTransparencies) do
			if visual.Transparency ~= HazardConfig.Crumble.GoneTransparency then
				allVisualsHidden = false
				break
			end
		end

		for detail, canCollide in pairs(detailCollision) do
			if detail.CanCollide ~= canCollide then
				detailCollisionPreserved = false
				break
			end
		end

		check(
			not crumble.CanCollide and allVisualsHidden and detailCollisionPreserved,
			"Crumble opens without changing detail-part collision"
		)
		waitUntil(function()
			return crumble:GetAttribute(HazardConfig.AttributeNames.HazardPhase) == HazardConfig.Phases.Solid
		end, 4, "Crumble did not restore")
		local allVisualsRestored = true

		for visual, transparency in pairs(originalTransparencies) do
			if visual.Transparency ~= transparency then
				allVisualsRestored = false
				break
			end
		end

		check(
			crumble.CanCollide == originalCanCollide and allVisualsRestored,
			"Crumble restores collision and authored visual transparencies"
		)
	end)

	report:SetAttribute("Status", if ok then "Passed" else "Failed")

	if not ok then
		report:SetAttribute("Failure", tostring(failure))
	end
end

return Hazards
