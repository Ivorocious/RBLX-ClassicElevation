--!nonstrict
return function()
	assert(game.RunService:IsStudio() and game.RunService:IsServer() and game.RunService:IsRunning())
	assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
	local library = game.ServerStorage.CourseLibrary.Course_MoonlitCitadel
	local recovery = game.ServerStorage.MoonlitP3ReworkRecovery
	assert(not recovery:FindFirstChild("OwnedRuntimeStopProbe21"))
	local root = Instance.new("Model")
	root.Name = "OwnedRuntimeStopProbe21"
	for key, value in library:GetAttributes() do root:SetAttribute(key, value) end
	root:SetAttribute("OwnedMoonlitTest", true)
	local obstacles = Instance.new("Folder")
	obstacles.Name, obstacles.Parent = "Obstacles", root
	for _, name in {"MovingCars", "SwingLanterns"} do library.Obstacles[name]:Clone().Parent = obstacles end
	for _, name in {"LowerMechanism", "UpperMechanism"} do
		local group = Instance.new("Folder")
		group.Name, group.Parent = name, obstacles
		for _, object in library.Obstacles[name]:GetChildren() do
			if object.Name:match("^OutboardWeight") then object:Clone().Parent = group end
		end
	end
	for _, car in obstacles.MovingCars:GetChildren() do
		local stage, bay = car.Name:match("^(%a+)_Bay(%d)$")
		car.Counterweight.Value = obstacles[stage .. "Mechanism"]["OutboardWeight" .. bay]
	end
	local parts, attributes = {}, {}
	for _, object in root:GetDescendants() do
		if object:IsA("BasePart") then parts[object] = {cf = object.CFrame, velocity = object.AssemblyLinearVelocity} end
	end
	for _, car in obstacles.MovingCars:GetChildren() do
		attributes[car] = {}
		for _, name in {"MoonlitPhase", "MoonlitBoarding", "MoonlitPassengers", "MoonlitNextPhaseAt"} do
			table.insert(attributes[car], {name = name, value = car:GetAttribute(name)})
		end
	end
	root.Parent = workspace
	local Runtime = require(game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.Runtime)
	local controller
	local report = {scope = "Copied native movers; no racer eligibility, route or Main binding claim", sourceHash = library:GetAttribute("SourcePacketHash"), mismatches = {}}
	local function compare()
		for part, saved in parts do
			local cf = part.CFrame
			if (cf.Position - saved.cf.Position).Magnitude > .001 or (cf.LookVector - saved.cf.LookVector).Magnitude > .001
				or (cf.UpVector - saved.cf.UpVector).Magnitude > .001 or (part.AssemblyLinearVelocity - saved.velocity).Magnitude > .001 then
				table.insert(report.mismatches, part:GetFullName())
			end
		end
		for object, rows in attributes do
			for _, row in rows do
				if object:GetAttribute(row.name) ~= row.value then table.insert(report.mismatches, object.Name .. "/" .. row.name) end
			end
		end
		local soundCount = 0
		for _, object in root:GetDescendants() do if object:IsA("Sound") and object.Name == "MoonlitCourseCue" then soundCount += 1 end end
		assert(soundCount == 0, "Runtime sounds survived Stop")
	end
	local ok, failure = xpcall(function()
		controller = Runtime.Start(root, function() return false end, function() error("Ineligible probe requested recovery") end)
		local duplicate = pcall(Runtime.Start, root, function() return false end, function() return false end)
		report.duplicateBindingRejected = not duplicate
		assert(not duplicate, "Duplicate binding was accepted")
		task.wait(3.4)
		report.active = controller.Diagnostics()
		assert(report.active.stats.frames > 0 and report.active.bound and #report.active.sounds == 7)
		controller.Stop()
		compare()
		local frames = controller.Diagnostics().stats.frames
		task.wait(.4)
		report.heartbeatDisconnected = controller.Diagnostics().stats.frames == frames
		assert(report.heartbeatDisconnected and #report.mismatches == 0, "Runtime did not restore the copied rig")
		controller = Runtime.Start(root, function() return false end, function() return false end)
		task.wait(.4)
		report.rebound = controller.Diagnostics().bound and controller.Diagnostics().stats.frames > 0
		controller.Stop()
		compare()
		assert(report.rebound and #report.mismatches == 0, "Runtime did not rebind and restore")
		report.ok = true
	end, debug.traceback)
	if controller then controller.Stop() end
	root.Parent = recovery
	if not ok then report.ok, report.failure = false, failure end
	return game.HttpService:JSONEncode(report)
end
