local Test = {}
local Lighting = game:GetService("Lighting")
local player = game.Players.LocalPlayer
local configs = game.ReplicatedStorage.Config
local profile = require(configs.MoonlitCitadelAmbienceConfig)
local dev = game.ReplicatedStorage.Remotes:WaitForChild("StudioDevControl", 15)
local originalCamera, baseline
local report = {checks={}, rotations={}, assets={}, views={}}

local function check(condition, label)
	assert(condition, label)
	table.insert(report.checks, label)
end

local function request(payload)
	task.wait(.2)
	local result = dev:InvokeServer(payload)
	assert(result.ok, result.message)
	return result
end

local function waitFor(predicate, label)
	local deadline = os.clock() + 40
	repeat
		if predicate() then return end
		task.wait(.2)
	until os.clock() >= deadline
	error("Timed out: " .. label)
end

local function root()
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function sky()
	return assert(Lighting:FindFirstChildOfClass("Sky"))
end

local function same(actual, expected)
	return if typeof(expected) == "number" then math.abs(actual-expected) < .0001 else actual == expected
end

local function verify(object, values, label, skipOrientation)
	for key, value in values do
		if skipOrientation and key == "SkyboxOrientation" then continue end
		assert(same(object[key], value), label .. "." .. key .. " differs")
	end
end

local function snapshot(object, values)
	local result = {}
	for key in values do result[key] = object[key] end
	return result
end

local function verifyMoonlit()
	verify(Lighting, profile.Lighting, "Moonlit lighting")
	verify(sky(), profile.Sky, "Moonlit sky", true)
	verify(Lighting:FindFirstChildOfClass("Atmosphere"), profile.Atmosphere, "Moonlit atmosphere")
	check(Lighting.CourseColor.Enabled, "Moonlit ambience active")
	check(sky().SkyboxOrientation.X == 0 and sky().SkyboxOrientation.Z == 0, "Level sky rotation")
end

local function selectMap(id)
	request({action="Map", courseId=id})
	waitFor(function()
		local course = workspace:FindFirstChild("RaceCourse")
		return course and course:GetAttribute("CourseId") == id and request({action="State"}).state == "Racing"
	end, id .. " race")
	task.wait(1)
end

function Test.Begin()
	assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient())
	local camera = workspace.CurrentCamera
	originalCamera = {CFrame=camera.CFrame, Focus=camera.Focus, CameraType=camera.CameraType, FieldOfView=camera.FieldOfView}
	request({action="OnboardingPreset", preset="Returning avatar"})
	waitFor(function() return player:GetAttribute("OnboardingReady") == true and root() ~= nil end, "onboarding")
	request({action="HoldLobby"})
	task.wait(1)
	baseline = {Lighting=snapshot(Lighting, profile.Lighting), Sky=snapshot(sky(), profile.Sky),
		Atmosphere=snapshot(Lighting:FindFirstChildOfClass("Atmosphere"), profile.Atmosphere), Effects={}}
	for class, values in profile.Effects do
		local object = Lighting:FindFirstChildOfClass(class)
		baseline.Effects[class] = if object then snapshot(object, values) else false
	end
	selectMap("moonlit_citadel")
	verifyMoonlit()
	check(workspace.RaceCourse:GetAttribute("SourceRevision") == 57 and workspace.RaceCourse:GetAttribute("BuildRevision") == 51,
		"Actual accepted Source57 Build51 course loaded")
	local assets = {}
	for _, key in {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"} do
		table.insert(assets, profile.Sky[key])
	end
	game:GetService("ContentProvider"):PreloadAsync(assets, function(id, status) report.assets[id] = status.Name end)
	for _, id in assets do check(report.assets[id] == "Success", "Image delivered " .. id) end
	request({action="UnlimitedTime", enabled=true})
	return {checks=report.checks, assets=report.assets}
end

function Test.Measure(seconds)
	verifyMoonlit()
	local first, started = sky().SkyboxOrientation.Y, os.clock()
	local moon, clock = Lighting:GetMoonDirection(), Lighting.ClockTime
	task.wait(seconds or 5)
	local elapsed = os.clock()-started
	local last = sky().SkyboxOrientation.Y
	local delta = (last-first)%360
	check(math.abs(delta - elapsed*profile.SkyRotationDegreesPerSecond) < .06, "Measured configured rotation speed")
	check((Lighting:GetMoonDirection()-moon).Magnitude < .000001 and Lighting.ClockTime == clock, "Moon and night lighting stay fixed")
	local result = {seconds=elapsed, firstYaw=first, lastYaw=last, delta=delta, degreesPerSecond=delta/elapsed}
	table.insert(report.rotations, result)
	return result
end

function Test.View(name, previousArt)
	local camera = workspace.CurrentCamera
	local views = {
		gate={Vector3.new(3854,316,2762),Vector3.new(3890,355,2650)},
		middle={Vector3.new(3918,367,2645),Vector3.new(4040,410,2548)},
		crown={Vector3.new(3994,470,2590),Vector3.new(3975,478,2510)},
		north={Vector3.new(6000,600,2600),Vector3.new(6000,600,2500)},
		east={Vector3.new(6000,600,2600),Vector3.new(6100,600,2600)},
		south={Vector3.new(6000,600,2600),Vector3.new(6000,600,2700)},
		west={Vector3.new(6000,600,2600),Vector3.new(5900,600,2600)},
		zenith={Vector3.new(6000,600,2600),Vector3.new(6000,700,2600),Vector3.zAxis},
		nadir={Vector3.new(6000,600,2600),Vector3.new(6000,500,2600),Vector3.zAxis},
	}
	local view = assert(views[name], "Unknown view")
	local values = profile.Sky
	if previousArt then
		values = {SkyboxBk="rbxassetid://119591637361429",SkyboxDn="rbxassetid://81233894808962",
			SkyboxFt="rbxassetid://136920684348219",SkyboxLf="rbxassetid://99622089516191",
			SkyboxRt="rbxassetid://95853984087799",SkyboxUp="rbxassetid://126102685877031",StarCount=1000,SkyboxOrientation=Vector3.zero}
	end
	for key, value in values do sky()[key] = value end
	if name=="gate" or name=="middle" or name=="crown" then
		local part = if name=="middle" then workspace.RaceCourse.Checkpoints.Checkpoint_002 else workspace.RaceCourse.Start
		if name=="crown" then part=workspace.RaceCourse.Checkpoints.Checkpoint_004 end
		player.Character:PivotTo(part.CFrame + Vector3.new(0,part.Size.Y/2+4,0))
	end
	root().Anchored = true
	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = 70
	camera.CFrame = CFrame.lookAt(view[1],view[2],view[3] or Vector3.yAxis)
	camera.Focus = CFrame.new(view[2])
	task.wait(.7)
	local row={view=name,previousArt=previousArt==true,clock=Lighting.ClockTime,yaw=sky().SkyboxOrientation.Y,
		camera={camera.CFrame:GetComponents()},front=sky().SkyboxFt}
	table.insert(report.views,row)
	return row
end

function Test.Respawn()
	verifyMoonlit()
	local old = player.Character
	root().Anchored = false
	request({action="Respawn"})
	waitFor(function() return player.Character ~= old and root() ~= nil end, "replacement character")
	task.wait(1)
	verifyMoonlit()
	check(player.Character:FindFirstChildOfClass("Humanoid").Health > 0, "Respawn remains alive on Moonlit")
	return Test.Measure(2)
end

local function verifyRestored(label)
	verify(Lighting, baseline.Lighting, label .. " lighting")
	verify(sky(), baseline.Sky, label .. " sky including orientation")
	verify(Lighting:FindFirstChildOfClass("Atmosphere"), baseline.Atmosphere, label .. " atmosphere")
	check(not Lighting.CourseColor.Enabled, label .. " course color disabled")
	for class, values in baseline.Effects do
		local object = Lighting:FindFirstChildOfClass(class)
		if values then verify(object, values, label .. " " .. class)
		else assert(object == nil, "Temporary effect remains " .. class) end
	end
	local orientation = sky().SkyboxOrientation
	task.wait(2)
	check(sky().SkyboxOrientation == orientation, label .. " rotation stopped")
	check(true, label .. " complete original appearance restored")
end

function Test.LeaveAndOtherCourse()
	root().Anchored = false
	request({action="Teleport",destination="Lobby"})
	task.wait(1)
	verifyRestored("Moonlit to lobby")
	selectMap("stud_garden_v2")
	local garden=require(configs.StudGardenAmbienceConfig)
	verify(Lighting,garden.Lighting,"Stud Garden lighting")
	verify(sky(),garden.Sky,"Stud Garden sky")
	local orientation=sky().SkyboxOrientation
	task.wait(2)
	check(sky().SkyboxOrientation == orientation,"Stud Garden sky does not rotate")
	check(true,"Stud Garden keeps its own ambience")
	request({action="Teleport",destination="Lobby"})
	task.wait(1)
	verifyRestored("Other course to lobby")
	for key,value in originalCamera do workspace.CurrentCamera[key]=value end
	return report
end

function Test.Report()
	return report
end

return Test
