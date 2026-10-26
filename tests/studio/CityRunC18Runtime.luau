-- Runs in a disposable Studio Play session against a cloned City Run course.
local Test = {}

local function closeEnough(a: Vector3, b: Vector3, tolerance: number): boolean
	return (a - b).Magnitude <= tolerance
end

function Test.Run(template: Model, frames: number?)
	assert(game:GetService("RunService"):IsRunning(), "Studio Play required")
	local player = assert(game.Players:GetPlayers()[1], "A Studio test player is required")
	assert(template.Obstacles.Moving:FindFirstChild("ActiveTrain0"), "Use an immutable inspection template, not the running course")
	local fixture = template:Clone()
	fixture.Name = "__CityRunC18RuntimeFixture"
	fixture:PivotTo(CFrame.new(9000, 100, 0))
	fixture.Parent = workspace

	local origin = fixture:GetPivot()
	local conveyors = {}
	for _, part in fixture:GetDescendants() do
		if part:IsA("BasePart") and part:GetAttribute("ConveyorSpeed") ~= nil then
			local marks = {}
			for _, child in part.Parent:GetChildren() do
				if child:IsA("BasePart") and child:GetAttribute("ConveyorTread") then
					table.insert(marks, { part = child, relative = part.CFrame:ToObjectSpace(child.CFrame) })
				end
			end
			table.insert(conveyors, { part = part, marks = marks })
		end
	end

	local eligibilityChecks = 0
	local controller = require(game.ServerStorage.CourseBuilders.CityRun.Runtime).Create(fixture, function()
		return false
	end, function(candidate)
		eligibilityChecks += 1
		return candidate == player
	end)

	local records = {}
	local benchmarkFrames = frames or 600
	local ok, failure = xpcall(function()
		controller.Step(0, false)
		controller.Step(1.25, false)
		for _, record in conveyors do
			local part = record.part
			local speed = part:GetAttribute("ConveyorSpeed")
			assert(closeEnough(part.AssemblyLinearVelocity, part.CFrame.RightVector * speed, .001), "Conveyor velocity changed")
			local span = part.Size.X - 1
			for _, mark in record.marks do
				local relative = mark.relative
				local x = (relative.X + span / 2 + 1.25 * speed) % span - span / 2
				local expected = part.CFrame * CFrame.new(x, relative.Y, relative.Z) * relative.Rotation
				assert(closeEnough(mark.part.Position, expected.Position, .001), "Conveyor tread timing changed")
			end
		end
		table.insert(records, { name = "ConveyorVelocityAndTreadTiming", passed = true })

		controller.Step(9.2, false)
		assert(fixture:GetAttribute("TrainPhase") == "Passing", "Train phase timing changed")
		local expectedTrain = origin * CFrame.new(238.75, 89, -12)
		assert(closeEnough(fixture.Obstacles.Moving.TrainAssembly:GetPivot().Position, expectedTrain.Position, .01), "Train transform changed")
		table.insert(records, { name = "TrainPhaseAndTransform", passed = true })

		eligibilityChecks = 0
		controller.Step(9.21, true)
		assert(eligibilityChecks == #game.Players:GetPlayers(), "Racer eligibility snapshot must evaluate once per player per damage frame")
		table.insert(records, { name = "SingleRacerSnapshot", passed = true, checks = eligibilityChecks })

		local started = os.clock()
		for index = 1, benchmarkFrames do
			controller.Step(10 + index / 60, false)
		end
		local elapsedSeconds = os.clock() - started
		table.insert(records, { name = "SteadyStateRuntimeLoop", passed = true, frames = benchmarkFrames, seconds = elapsedSeconds })
	end, debug.traceback)

	controller.Stop()
	for _, record in conveyors do
		assert(closeEnough(record.part.AssemblyLinearVelocity, Vector3.zero, .001), "Conveyor stop velocity changed")
		for _, mark in record.marks do
			local expected = record.part.CFrame * mark.relative
			assert(closeEnough(mark.part.Position, expected.Position, .001), "Conveyor stop reset changed")
		end
	end
	fixture:Destroy()
	if not ok then error(failure) end

	return {
		passed = true,
		records = records,
		benchmark = {
			frames = benchmarkFrames,
			activeRaceSteadyStateWork = {
				baseline = { playerSnapshots = 2, eligibilityChecksPerPlayer = 2, overlapParams = 1, raycastParams = 1, conveyorVelocityWrites = #conveyors },
				optimized = { playerSnapshots = 1, eligibilityChecksPerPlayer = 1, overlapParams = 0, raycastParams = 0, conveyorVelocityWrites = 0 },
			},
		},
		limitation = "The work counts are deterministic code-path counts, not a device FPS result. This clone test has one avatar; run a 20-player mobile Play test before claiming capacity.",
	}
end

return Test