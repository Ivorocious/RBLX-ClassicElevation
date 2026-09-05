--!strict

-- Run from a temporary server Script during Studio Play, never in a published server.
local Smoke = {}

function Smoke.Run()
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	local ServerStorage = game:GetService("ServerStorage")
	assert(not ServerStorage:FindFirstChild("ClassicAscentTestReport"), "Already run this session")
	local report = Instance.new("Folder")
	report.Name = "ClassicAscentTestReport"
	report.Parent = ServerStorage
	report:SetAttribute("Status", "Running")
	local checks = {}
	local function check(condition: boolean, message: string)
		assert(condition, message)
		table.insert(checks, message)
		report:SetAttribute("Checks", game:GetService("HttpService"):JSONEncode(checks))
	end
	local ok, failure = pcall(function()
		local services = game:GetService("ServerScriptService").Services
		local race = require(services.RaceService)
		local results = require(services.ResultsService)
		local respawn = require(services.RespawnService)
		local deadline = os.clock() + 40
		while not race.IsRaceActive() and os.clock() < deadline do task.wait(0.1) end
		check(race.IsRaceActive(), "Official race started")
		local player = game:GetService("Players"):GetPlayers()[1]
		assert(player and player.Character, "Player character required")
		local character = player.Character
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
		local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid
		root:SetNetworkOwner(nil)
		local course = workspace.RaceCourse
		local record = results.GetCurrentRaceResult()
		assert(record and #record.activeRacers == 1, "Solo test requires one official racer")
		local row = record.activeRacers[1]
		local function pivot(target: CFrame)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			character:PivotTo(target)
			task.wait(0.5)
		end
		pivot(course.Checkpoints.Checkpoint_002.CFrame + Vector3.new(0, 4, 0))
		check(row.nextCheckpointIndex == 1, "Out-of-order checkpoint rejected")
		pivot(course.Finish.CFrame + Vector3.new(0, 4, 0))
		check(row.finishTime == nil and race.IsRaceActive(), "Early finish rejected without shortening race")
		respawn.BindActiveCourse()
		respawn.BindActiveCourse()
		pivot(course.FallZones.Recovery_006.CFrame)
		check(row.falls == 1, "Local zone records one fall after repeated rebind")
		check((root.Position - course.Start.Position).Magnitude < 15, "Fall before checkpoint returns to Start")
		local route = {}
		for _, instance in ipairs(course:GetDescendants()) do
			if instance:IsA("BasePart") and instance:GetAttribute("RouteIndex") then table.insert(route, instance) end
		end
		table.sort(route, function(a, b) return a:GetAttribute("RouteIndex") < b:GetAttribute("RouteIndex") end)
		check(#route == course.CourseInfo:GetAttribute("RouteTransitions"), "All declared route transitions discovered")
		local function walk(target: Vector3, timeout: number)
			local untilTime = os.clock() + timeout
			repeat
				local delta = target - root.Position
				local horizontal = Vector3.new(delta.X, 0, delta.Z)
				if horizontal.Magnitude < 0.75 then
					humanoid:Move(Vector3.zero)
					if humanoid.FloorMaterial ~= Enum.Material.Air then return end
				else
					humanoid:Move(horizontal.Unit)
				end
				task.wait(0.03)
			until os.clock() >= untilTime
			humanoid:Move(Vector3.zero)
			error("Movement timeout at route " .. tostring(report:GetAttribute("RouteIndex")))
		end
		pivot(course.Start.CFrame + Vector3.new(0, 4, 0))
		local previous = course.Start
		local traversalStart = os.clock()
		for index, target in ipairs(route) do
			report:SetAttribute("RouteIndex", index)
			local delta = target.Position - previous.Position
			local direction = Vector3.new(delta.X, 0, delta.Z).Unit
			local localDirection = previous.CFrame:VectorToObjectSpace(direction)
			local edgeDistance = math.min(
				previous.Size.X / 2 / math.max(math.abs(localDirection.X), 0.0001),
				previous.Size.Z / 2 / math.max(math.abs(localDirection.Z), 0.0001)
			)
			walk(previous.Position + direction * (edgeDistance - 1.5), 3)
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			walk(target.Position, 4)
			assert(row.falls == 1, "Unexpected fall on route " .. index)
			previous = target
		end
		report:SetAttribute("RobotTraversalSeconds", os.clock() - traversalStart)
		check(row.finishTime ~= nil and #record.placements == 1, "Full physical traversal finishes officially")
		check(#row.checkpointSplits == 19, "All nineteen checkpoint splits recorded")
		local finishTime = row.finishTime
		task.wait(1.2)
		check(not race.IsRaceActive(), "Solo race ends early after final finish")
		check(row.finishTime == finishTime, "Official finish time stays locked")
		root:SetNetworkOwnershipAuto()
	end)
	report:SetAttribute("Status", if ok then "Passed" else "Failed")
	if not ok then report:SetAttribute("Failure", tostring(failure)) end
end

return Smoke
