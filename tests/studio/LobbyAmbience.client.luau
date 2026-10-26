-- Uses the real Studio map and teleport controls against the running client.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local player = game.Players.LocalPlayer
local lighting = game:GetService("Lighting")
local dev = game.ReplicatedStorage.Remotes.StudioDevControl
local shipwreck = require(game.ReplicatedStorage.Config.ShipwreckAmbienceConfig)
local checks = {}
local function check(condition, label)
	assert(condition, label)
	table.insert(checks, label)
end
local function request(payload)
	task.wait(.2)
	local result = dev:InvokeServer(payload)
	assert(result.ok, result.message)
	return result
end
local function waitFor(predicate)
	local deadline = os.clock()+35
	repeat if predicate() then return end; task.wait(.2) until os.clock()>deadline
	error("Lobby ambience test timed out")
end
request({action="OnboardingPreset",preset="Returning avatar"})
waitFor(function() return player:GetAttribute("OnboardingReady") end)
task.wait(.7)
local baseline = {clock=lighting.ClockTime,brightness=lighting.Brightness,sky=lighting:FindFirstChildOfClass("Sky").SkyboxFt}
request({action="Map",courseId="shipwreck_cove"})
waitFor(function() return dev:InvokeServer({action="State"}).state=="Racing" end)
local function verifyCourse()
	task.wait(.8)
	check(lighting.CourseColor.Enabled, "Shipwreck color activates on course")
	check(math.abs(lighting.ClockTime-shipwreck.Lighting.ClockTime)<.001, "Shipwreck lighting preserved")
	check(lighting:FindFirstChildOfClass("Sky").SkyboxFt==shipwreck.Sky.SkyboxFt, "Shipwreck sky preserved")
end
local function verifyLobby()
	task.wait(.8)
	local lobby = workspace:FindFirstChild("Lobby")
	check(lobby~=nil, "Lobby remains present")
	local count,hidden=0,0
	for _,item in lobby:GetDescendants() do
		if item:IsA("BasePart") then count+=1; if item.LocalTransparencyModifier==1 then hidden+=1 end end
	end
	check(count>1000 and hidden==0, "All replicated lobby parts remain visible")
	check(not lighting.CourseColor.Enabled, "Course color disabled in lobby")
	check(math.abs(lighting.ClockTime-baseline.clock)<.001 and lighting.Brightness==baseline.brightness, "Lobby lighting restored")
	check(lighting:FindFirstChildOfClass("Sky").SkyboxFt==baseline.sky, "Lobby sky restored")
	check((player.Character.HumanoidRootPart.Position-workspace.RaceCourse.Start.Position).Magnitude<shipwreck.ActivationDistance,
		"Lobby stays protected even inside old course radius")
end
verifyCourse()
request({action="Teleport",destination="Lobby"}); verifyLobby()
request({action="Teleport",destination="Start"}); verifyCourse()
request({action="Teleport",destination="Lobby"}); verifyLobby()
return {passed=#checks,checks=checks,map=dev:InvokeServer({action="State"}).selectedMap}
