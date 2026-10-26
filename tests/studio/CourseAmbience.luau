local Test = {}

function Test.RunClient()
	local run = game:GetService("RunService")
	assert(run:IsStudio() and run:IsClient(), "Studio client required")
	local lighting = game:GetService("Lighting")
	local player = game.Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart", 15)
	assert(root, "Character did not load")
	local originalFrame, originalAnchored = root.CFrame, root.Anchored
	local city = require(game.ReplicatedStorage.Config.CityRunAmbienceConfig)
	local shipwreck = require(game.ReplicatedStorage.Config.ShipwreckAmbienceConfig)
	local garden = require(game.ReplicatedStorage.Config.StudGardenAmbienceConfig)
	local existing = workspace:WaitForChild("RaceCourse", 15)
	assert(existing, "Start a course before running the ambience check")
	local fixture = Instance.new("Model")
	fixture.Name = "RaceCourse"
	local info = Instance.new("Folder")
	info.Name, info.Parent = "CourseInfo", fixture
	local start = Instance.new("Part")
	start.Name, start.Anchored, start.CanCollide, start.Transparency = "Start", true, false, 1
	start.Parent = fixture
	local checks = {}
	local function matches(actual, expected, label)
		local same = if typeof(expected) == "number" then math.abs(actual - expected) < 0.0001 else actual == expected
		assert(same, label .. " differs")
	end
	local function snapshot(object, properties)
		local result = {}
		for key in properties do result[key] = object[key] end
		return result
	end
	local function verify(object, properties, label)
		for key, value in properties do matches(object[key], value, label .. "." .. key) end
	end
	local function activate(config)
		info:SetAttribute("CourseId", config.CourseId)
		start.Position = player.Character.HumanoidRootPart.Position
		fixture.Parent = workspace
		task.wait(0.75)
		verify(lighting, config.Lighting, config.CourseId)
		verify(lighting:FindFirstChildOfClass("Sky"), config.Sky, config.CourseId .. " sky")
		verify(lighting:FindFirstChildOfClass("Atmosphere"), config.Atmosphere, config.CourseId .. " atmosphere")
		verify(lighting.CourseColor, config.ColorCorrection, config.CourseId .. " color")
		for class, properties in config.Effects or {} do
			verify(lighting:FindFirstChildOfClass(class), properties, config.CourseId .. " " .. class)
		end
		assert(lighting.CourseColor.Enabled)
		table.insert(checks, config.CourseId)
	end
	local ok, result = xpcall(function()
		root.Anchored = true
		if existing then existing.Name = "__AmbienceSavedCourse" end
		task.wait(0.75)
		local allProperties = {Lighting={}, Sky={}, Atmosphere={}}
		for _, config in {city, shipwreck, garden} do
			for group, properties in allProperties do
				for key in config[group] do properties[key] = true end
			end
		end
		local baseline = {
			Lighting = snapshot(lighting, allProperties.Lighting),
			Sky = snapshot(lighting:FindFirstChildOfClass("Sky"), allProperties.Sky),
			Atmosphere = snapshot(lighting:FindFirstChildOfClass("Atmosphere"), allProperties.Atmosphere),
		}
		local effects = {}
		for class, properties in shipwreck.Effects do
			local object = lighting:FindFirstChildOfClass(class)
			effects[class] = if object then snapshot(object, properties) else false
		end
		local function effectsRestored(label)
			for class, properties in effects do
				local object = lighting:FindFirstChildOfClass(class)
				if properties then verify(object, properties, label .. " " .. class)
				else assert(object == nil, "Created effect was not removed: " .. class) end
			end
		end
		local function restored(label)
			verify(lighting, baseline.Lighting, label)
			verify(lighting:FindFirstChildOfClass("Sky"), baseline.Sky, label .. " sky")
			verify(lighting:FindFirstChildOfClass("Atmosphere"), baseline.Atmosphere, label .. " atmosphere")
			assert(not lighting.CourseColor.Enabled, "Course color remained enabled")
			effectsRestored(label)
			table.insert(checks, label)
		end
		restored("initial lobby")
		activate(city)
		activate(shipwreck)
		activate(city)
		effectsRestored("Shipwreck to City Run")
		activate(garden)
		local assets, loaded = {}, {}
		for _, property in {"SkyboxFt", "SkyboxBk", "SkyboxLf", "SkyboxRt", "SkyboxUp", "SkyboxDn"} do
			table.insert(assets, garden.Sky[property])
		end
		game:GetService("ContentProvider"):PreloadAsync({lighting:FindFirstChildOfClass("Sky")}, function(id, status)
			loaded[id] = status.Name
		end)
		for _, id in assets do assert(loaded[id] == "Success", "Sky image did not load: " .. id) end
		table.insert(checks, "six garden images loaded")
		activate(shipwreck)
		activate(garden)
		effectsRestored("Shipwreck to Stud Garden")
		start.Position = root.Position + Vector3.new(garden.ActivationDistance + 50, 0, 0)
		task.wait(0.75)
		restored("leave Stud Garden range")
		activate(garden)
		for _, name in {"GrandArcade", "Lobby"} do
			local area = workspace:FindFirstChild(name)
			assert(area and area:IsA("Model"), "Missing exclusion area: " .. name)
			root.CFrame = area:GetBoundingBox()
			start.Position = root.Position
			task.wait(0.75)
			restored("Stud Garden excluded in " .. name)
			root.CFrame = originalFrame
			activate(garden)
		end
		activate(shipwreck)
		start.Position = player.Character.HumanoidRootPart.Position + Vector3.new(shipwreck.ActivationDistance + 50, 0, 0)
		task.wait(0.75)
		restored("leave Shipwreck range")
		activate(city)
		start.Position = player.Character.HumanoidRootPart.Position + Vector3.new(city.ActivationDistance + 50, 0, 0)
		task.wait(0.75)
		restored("leave map range")
		activate(shipwreck)
		info:SetAttribute("CourseId", "__unconfigured_map")
		task.wait(0.75)
		restored("unconfigured map")
		activate(shipwreck)
		fixture.Parent = nil
		task.wait(0.75)
		restored("course unloaded")
		return {passed=true, checks=checks, gardenAssets=loaded}
	end, debug.traceback)
	fixture:Destroy()
	if existing then existing.Name = "RaceCourse" end
	root.CFrame, root.Anchored = originalFrame, originalAnchored
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	task.wait(0.75)
	assert(ok, result)
	return result
end

return Test
