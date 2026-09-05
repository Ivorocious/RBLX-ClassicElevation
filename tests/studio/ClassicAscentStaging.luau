--!strict

-- Run from a temporary server Script during a fresh Studio Play session.
local Staging = {}

function Staging.Run()
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	local Players = game:GetService("Players")
	local ServerScriptService = game:GetService("ServerScriptService")
	local ServerStorage = game:GetService("ServerStorage")
	assert(not ServerStorage:FindFirstChild("ClassicAscentStagingReport"), "Already run this session")

	local report = Instance.new("Folder")
	report.Name = "ClassicAscentStagingReport"
	report.Parent = ServerStorage
	report:SetAttribute("Status", "Running")
	local checks = {}

	local function check(condition: boolean, message: string)
		assert(condition, message)
		table.insert(checks, message)
		report:SetAttribute("Checks", game:GetService("HttpService"):JSONEncode(checks))
	end

	local function waitUntil(predicate: () -> boolean, timeout: number, message: string)
		local deadline = os.clock() + timeout

		while not predicate() and os.clock() < deadline do
			task.wait(0.05)
		end

		assert(predicate(), message)
	end

	local ok, failure = pcall(function()
		local services = ServerScriptService.Services
		local race = require(services.RaceService)
		waitUntil(function()
			return race.GetRaceState() == "Intermission"
		end, 15, "Start this test during a fresh Play session before Intermission ends")

		local player = Players:GetPlayers()[1]
		assert(player ~= nil, "One player is required")
		waitUntil(function()
			return player.Character ~= nil
		end, 5, "Player character required")

		local course = workspace:FindFirstChild("RaceCourse")
		assert(course ~= nil and course:IsA("Model"), "Active RaceCourse required")
		local startPart = course:FindFirstChild("Start")
		assert(startPart ~= nil and startPart:IsA("BasePart"), "RaceCourse.Start required")
		local startPen = course:FindFirstChild("StartPen")
		assert(startPen ~= nil, "RaceCourse.StartPen required")
		local startGate = startPen:FindFirstChild("StartGate")
		assert(startGate ~= nil and startGate:IsA("BasePart"), "StartPen.StartGate required")
		local gateVisuals = startPen:FindFirstChild("GateVisuals")
		assert(gateVisuals ~= nil, "StartPen.GateVisuals required")

		local visualParts: { BasePart } = {}

		for _, descendant in ipairs(gateVisuals:GetDescendants()) do
			if descendant:IsA("BasePart") then
				table.insert(visualParts, descendant)
			end
		end

		assert(#visualParts > 0, "At least one gate visual part required")

		local function getCharacterParts(): (Model, Humanoid, BasePart)
			local character = player.Character
			assert(character ~= nil, "Character required")
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")
			assert(humanoid ~= nil, "Humanoid required")
			assert(root ~= nil and root:IsA("BasePart"), "HumanoidRootPart required")
			return character, humanoid, root
		end

		local function isInsideStartBounds(root: BasePart): boolean
			local localPosition = startPart.CFrame:PointToObjectSpace(root.Position)

			return math.abs(localPosition.X) <= startPart.Size.X / 2 + 4
				and math.abs(localPosition.Z) <= startPart.Size.Z / 2 + 4
				and localPosition.Y >= -6
				and localPosition.Y <= 20
		end

		local character, humanoid, root = getCharacterParts()
		root:SetNetworkOwner(nil)
		waitUntil(function()
			return isInsideStartBounds(root)
		end, 3, "Queued player was not staged during Intermission")
		check(startGate.CanCollide, "Start gate is closed during Intermission")

		local visibleVisualCount = 0

		for _, visualPart in ipairs(visualParts) do
			if visualPart.Transparency < 1 then
				visibleVisualCount += 1
			end
		end

		check(visibleVisualCount > 0, "Authored gate visuals are visible while closed")

				local pushDeadline = os.clock() + 2
		while os.clock() < pushDeadline do
			humanoid:Move(startPart.CFrame.LookVector)
			task.wait(0.03)
		end
		humanoid:Move(Vector3.zero)
		check(startPart.CFrame:PointToObjectSpace(root.Position).Z > -startPart.Size.Z / 2, "Physical gate blocks forward movement before the race")
		local freeMovementTarget = startPart.CFrame * CFrame.new(5, 5, 5)
		character:PivotTo(freeMovementTarget)
		root.AssemblyLinearVelocity = Vector3.zero
		humanoid:Move(Vector3.zero)
		task.wait(0.75)
		check(
			(root.Position - freeMovementTarget.Position).Magnitude < 3,
			"Safe movement inside the start pen is retained"
		)

		character:PivotTo(startPart.CFrame * CFrame.new(startPart.Size.X, 5, 0))
		root.AssemblyLinearVelocity = Vector3.zero
		waitUntil(function()
			return isInsideStartBounds(root)
		end, 2, "Escaped staged player was not recovered")
		check(true, "Server fallback recovers a player who escapes the start pen")

		local oldCharacter = character
		humanoid.Health = 0
		waitUntil(function()
			return player.Character ~= nil and player.Character ~= oldCharacter
		end, 12, "Player did not respawn during staging")
		character, humanoid, root = getCharacterParts()
		root:SetNetworkOwner(nil)
		waitUntil(function()
			return isInsideStartBounds(root)
		end, 3, "Respawned queued player was not returned to staging")
		check(true, "Respawn during staging returns the player safely to the start pen")

		local transitionTarget = startPart.CFrame * CFrame.new(-5, 5, 5)
		character:PivotTo(transitionTarget)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		humanoid:Move(Vector3.zero)
		task.wait(0.4)
		local positionBeforeRace = root.Position

		waitUntil(function()
			return race.GetRaceState() == "Racing"
		end, 35, "Race did not start after staging")
		task.wait(0.25)
		check(not startGate.CanCollide, "Start gate opens when Racing begins")

		local allVisualsOpen = true

		for _, visualPart in ipairs(visualParts) do
			if visualPart.Transparency ~= 1 or visualPart.CanCollide then
				allVisualsOpen = false
				break
			end
		end

		check(allVisualsOpen, "Gate visuals hide and stop colliding when Racing begins")
		check(
			(root.Position - positionBeforeRace).Magnitude < 3,
			"Race transition does not teleport a healthy staged player"
		)
		root:SetNetworkOwnershipAuto()
	end)

	report:SetAttribute("Status", if ok then "Passed" else "Failed")

	if not ok then
		report:SetAttribute("Failure", tostring(failure))
	end
end

return Staging
