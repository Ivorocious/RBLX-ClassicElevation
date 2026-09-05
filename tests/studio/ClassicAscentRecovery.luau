--!strict

-- Temporary server Script entry point for the next solo race after the traversal test.
local Recovery = {}

function Recovery.Run()
	assert(game:GetService("RunService"):IsStudio(), "Studio only")
	local storage = game:GetService("ServerStorage")
	assert(not storage:FindFirstChild("ClassicAscentRecoveryReport"), "Already run this session")
	local report = Instance.new("Folder")
	report.Name = "ClassicAscentRecoveryReport"
	report.Parent = storage
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
		local courses = require(services.CourseService)
		local deadline = os.clock() + 50
		while not race.IsRaceActive() and os.clock() < deadline do task.wait(0.1) end
		assert(race.IsRaceActive(), "Race required")
		local player = game:GetService("Players"):GetPlayers()[1]
		assert(player and player.Character, "Character required")
		local character = player.Character
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
		root:SetNetworkOwner(nil)
		local record = results.GetCurrentRaceResult()
		assert(record and #record.activeRacers == 1, "Fresh solo race required")
		local row = record.activeRacers[1]
		check(row.nextCheckpointIndex == 1 and row.falls == 0, "Next round resets checkpoint progress and falls")
		local course = workspace.RaceCourse
		local function pivot(cf: CFrame)
			root.AssemblyLinearVelocity = Vector3.zero
			character:PivotTo(cf)
			task.wait(0.6)
		end
		for index = 1, 8 do
			pivot(course.Checkpoints[string.format("Checkpoint_%03d", index)].CFrame + Vector3.new(0, 4, 0))
		end
		check(row.nextCheckpointIndex == 9 and #row.checkpointSplits == 8, "Next round records each checkpoint once")
		local checkpoint = course.Checkpoints.Checkpoint_008
		pivot(course.FallZones.Recovery_056.CFrame)
		check(row.falls == 1 and (root.Position - checkpoint.Position).Magnitude < 10, "Elevated local fall returns to latest checkpoint")
		check(root.CFrame.LookVector:Dot(checkpoint.CFrame.LookVector) > 0.95, "Respawn faces outgoing leg")
		task.wait(1.6)
		local nested = Instance.new("Folder")
		nested.Name = "TestNestedZones"
		nested.Parent = course.FallZones
		local zone = course.FallZones.Recovery_056:Clone()
		zone.Name = "ArbitraryRecoveryName"
		zone.CFrame = CFrame.new(checkpoint.Position + Vector3.new(0, -15, 70))
		zone.Size = Vector3.new(10, 3, 10)
		zone.Parent = nested
		check(#courses.GetFallZones() == course.CourseInfo:GetAttribute("RouteTransitions") + 2, "Nested arbitrarily named zone discovered")
		respawn.BindActiveCourse()
		respawn.BindActiveCourse()
		pivot(zone.CFrame)
		check(row.falls == 2 and (root.Position - checkpoint.Position).Magnitude < 10, "Nested zone recovers once after rebind")
		task.wait(1.6)
		pivot(course.FallZones.FallZone_Main.CFrame)
		check(row.falls == 3 and (root.Position - checkpoint.Position).Magnitude < 10, "General catch or Y fallback recovers once")
		check(race.IsRaceActive(), "Remaining official racer keeps round active")
		root:SetNetworkOwnershipAuto()
	end)
	report:SetAttribute("Status", if ok then "Passed" else "Failed")
	if not ok then report:SetAttribute("Failure", tostring(failure)) end
end

return Recovery
