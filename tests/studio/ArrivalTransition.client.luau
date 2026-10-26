-- Run through the real Play client; presets use temporary Studio profiles.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local player = game.Players.LocalPlayer
local remote = game.ReplicatedStorage.Remotes.ArrivalControl
local dev = game.ReplicatedStorage.Remotes.StudioDevControl
local checks = {}
local function check(condition, name)
	assert(condition, name)
	table.insert(checks, name)
end
local function waitFor(predicate, seconds)
	local deadline = os.clock() + (seconds or 35)
	repeat
		if predicate() then return end
		task.wait(.05)
	until os.clock() > deadline
	error("Arrival test timed out: " .. tostring(player:GetAttribute("ArrivalTransitionPhase")))
end
local function preset(name)
	task.wait(.5)
	check(dev:InvokeServer({action="OnboardingPreset",preset=name}).ok, "Preset: "..name)
end
local function transitionPhase(value)
	return player:GetAttribute("ArrivalTransitionPhase") == value
end
preset("First visit")
waitFor(function() return player:GetAttribute("ArrivalPhase") == "Choice" end)
task.wait(.5)
check(not remote:InvokeServer({action="Arrived",token="wrong-token"}).ok, "Early acknowledgement rejected")
check(not player:GetAttribute("OnboardingReady"), "Early acknowledgement cannot enter races")
preset("Slow lobby delivery")
waitFor(function() return transitionPhase("Overview") end)
check(not player:GetAttribute("OnboardingReady"), "Slow delivery holds race eligibility")
check(player.Character.HumanoidRootPart.Anchored, "Slow delivery holds character")
check(workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable, "Overview owns camera")
task.wait(.5)
check(not remote:InvokeServer({action="Arrived",token="wrong-token"}).ok, "Wrong delivery token rejected")
waitFor(function() return transitionPhase("Complete") end)
check(player:GetAttribute("OnboardingReady"), "Completed delivery releases race gate")
check(not player.Character.HumanoidRootPart.Anchored, "Completed delivery restores movement")
check(workspace.CurrentCamera.CameraType == Enum.CameraType.Custom, "Completed delivery restores player camera")
check(workspace.CurrentCamera.CameraSubject == player.Character.Humanoid, "Camera follows current character")
check(not player.PlayerGui.Arrival.LobbyEntrance.Visible, "Entrance overlay closes")
preset("Lobby delivery failure")
waitFor(function() return transitionPhase("Failed") end)
check(not player:GetAttribute("OnboardingReady") and player.Character.HumanoidRootPart.Anchored, "Delivery failure stays held")
check(player.PlayerGui.Arrival.LobbyEntrance.Retry.Visible, "Delivery failure exposes Retry")
preset("Returning avatar")
waitFor(function() return player:GetAttribute("ArrivalPhase") == "Ready" end)
check(not player.PlayerGui.Arrival.LobbyEntrance.Visible, "Preset change closes stale entrance")
check(workspace.CurrentCamera.CameraType == Enum.CameraType.Custom, "Preset change releases camera ownership")
preset("Slow lobby delivery")
waitFor(function() return transitionPhase("Overview") end)
preset("First visit")
waitFor(function() return player:GetAttribute("ArrivalPhase") == "Choice" end)
task.wait(10)
check(not player:GetAttribute("OnboardingReady"), "Cancelled entrance cannot release new visitor")
check(player.PlayerGui.Arrival.Starfield.Visible, "Cancelled entrance restores chooser")
check(workspace.CurrentCamera.CameraType == Enum.CameraType.Custom, "Cancelled entrance restores camera")
return {passed=#checks,checks=checks}
