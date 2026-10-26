assert(game.RunService:IsStudio() and game.RunService:IsServer() and game.PlaceId == 85558151074819)
local service = require(game.ServerScriptService.Services.EggRushService)
local course = assert(workspace:FindFirstChild("RaceCourse"))
local template = game.ServerStorage.CourseLibrary.Course_EggRush
assert(course:GetAttribute("CourseId") == "egg_rush_circuit")
local report = {ok = false, candidateId = course:GetAttribute("CandidateId"), parts = 0, mechanisms = 0, profilesBefore = {}, profilesAfter = {},
	mode = if service.GetDiagnostics().bound then "StopAndReadback" else "ReadbackAfterPriorStop", maximumPositionError = 0, maximumRotationError = 0}
local receipt = Instance.new("StringValue")
receipt.Name, receipt.Parent = "EggRushRuntimeStopReceipt", game.ServerStorage
local function profiles()
	local values = {}
	for _, player in game.Players:GetPlayers() do
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then table.insert(values, {userId = player.UserId, walk = humanoid.WalkSpeed, jump = humanoid.JumpHeight, usePower = humanoid.UseJumpPower}) end
	end
	return values
end
local ok, failure = xpcall(function()
	report.profilesBefore = profiles()
	service.Stop()
	game.RunService.Heartbeat:Wait()
	local diagnostics = service.GetDiagnostics()
	assert(not diagnostics.bound and diagnostics.movementProfiles == 0)
	for _, model in course.Obstacles.Mechanisms:GetChildren() do
		local expected = assert(template.Obstacles.Mechanisms:FindFirstChild(model.Name))
		assert((model:GetPivot().Position - expected:GetPivot().Position).Magnitude < .001)
		for _, key in {"ERState", "EROpen", "ERBoarding", "ERExit"} do assert(model:GetAttribute(key) == expected:GetAttribute(key), key) end
		for _, part in model:GetDescendants() do
			if not part:IsA("BasePart") then continue end
			local names, ancestor = {}, part
			while ancestor ~= model do table.insert(names, 1, ancestor.Name); ancestor = ancestor.Parent end
			local original = expected
			for _, name in names do original = assert(original:FindFirstChild(name), name) end
			local positionError = (part.Position - original.Position).Magnitude
			local rotationError = (part.CFrame.RightVector - original.CFrame.RightVector).Magnitude
				+ (part.CFrame.UpVector - original.CFrame.UpVector).Magnitude + (part.CFrame.LookVector - original.CFrame.LookVector).Magnitude
			report.maximumPositionError = math.max(report.maximumPositionError, positionError)
			report.maximumRotationError = math.max(report.maximumRotationError, rotationError)
			assert(positionError < .001 and rotationError < .00001)
			assert(part.Transparency == original.Transparency and part.AssemblyLinearVelocity.Magnitude < .001 and part.AssemblyAngularVelocity.Magnitude < .001)
			report.parts += 1
		end
		report.mechanisms += 1
	end
	assert(report.mechanisms == 13)
	for _, part in course.Decoration:GetDescendants() do
		if part:IsA("Sound") and part.Name == "WarningSound" then assert(not part.IsPlaying) end
	end
	report.profilesAfter = profiles()
	report.bound, report.movementProfiles, report.ok = diagnostics.bound, diagnostics.movementProfiles, true
end, debug.traceback)
if not ok then report.failure = failure end
receipt.Value = game.HttpService:JSONEncode(report)
