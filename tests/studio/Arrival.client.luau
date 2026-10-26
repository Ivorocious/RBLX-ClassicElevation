-- Run in the actual Play client through MCP. All presets use temporary Studio data.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "Studio only")
local player = game.Players.LocalPlayer
local control = game.ReplicatedStorage.Remotes.ArrivalControl
local dev = game.ReplicatedStorage.Remotes.StudioDevControl
local checks = {}
local function check(condition, name)
	assert(condition, name)
	table.insert(checks, name)
end
local function state() return control:InvokeServer({action="State"}) end
local function request(payload)
	task.wait(0.45)
	return control:InvokeServer(payload)
end
local function waitPhase(phase)
	local deadline = os.clock() + 20
	repeat
		local result = state()
		if result.phase == phase then return result end
		task.wait(0.25)
	until os.clock() > deadline
	error("Timed out waiting for " .. phase)
end
local function preset(name, phase)
	task.wait(0.2)
	local response = dev:InvokeServer({action="OnboardingPreset",preset=name})
	check(response.ok, "Preset: " .. name)
	if phase then return waitPhase(phase) end
	return state()
end
local function save(mode, look, id)
	local result = request({action="Save",mode=mode,look=look,operationId=id})
	if result.ok and result.phase == "Entering" then return waitPhase("Ready") end
	return result
end
local look = {hair=2,skin=3,top=5,legs=7}
preset("First visit", "Choice")
check(player:GetAttribute("OnboardingReady") == false, "First visit is held outside races")
local avatar = save("Avatar", nil, "runtime-avatar-001")
check(avatar.ok and avatar.phase == "Ready" and avatar.profile.gold == 0, "Own avatar enters lobby without bonus")
check(not player.Character.HumanoidRootPart.Anchored, "Movement restored after arrival")
check(request({action="Edit"}).phase == "Choice", "Lobby customization reopens")
local invalid = save("Custom", {hair=2,skin=3,top=5,legs=7,gold=9999}, "runtime-invalid-001")
check(not invalid.ok and invalid.profile.gold == 0, "Injected currency is rejected")
local custom = save("Custom", look, "runtime-custom-001")
check(custom.ok and custom.profile.gold == 100 and custom.profile.bonusClaimed, "Later customization grants one bonus")
check(player.Character.Humanoid:GetAppliedDescription().HairAccessory == "63690008", "Hair applied on server")
request({action="Edit"})
local repeatSave = save("Custom", look, "runtime-custom-002")
check(repeatSave.ok and repeatSave.profile.gold == 100, "Second custom save grants no extra Gold")
task.wait(0.2)
check(dev:InvokeServer({action="Respawn"}).ok, "Respawn accepted")
task.wait(3)
check(player.Character.Humanoid:GetAppliedDescription().HairAccessory == "63690008", "Saved look reapplied after respawn")
preset("Save failure", "Choice")
local failed = save("Custom", look, "runtime-retry-001")
check(not failed.ok and failed.profile.gold == 0 and failed.phase == "Choice", "Failed save retains unclaimed state")
local retried = save("Custom", look, "runtime-retry-001")
check(retried.ok and retried.profile.gold == 100, "Same-operation retry saves once")
local returning = preset("Returning avatar", "Ready")
check(returning.profile.mode == "Avatar" and returning.profile.gold == 0, "Returning avatar bypasses chooser")
local racer = preset("Returning racer", "Ready")
check(racer.profile.mode == "Custom" and racer.profile.gold == 100, "Returning racer loads saved appearance")
preset("Bonus claimed", "Choice")
check(save("Custom", look, "runtime-claimed-001").profile.gold == 100, "Claimed preset cannot farm reward")
preset("Load failure", "LoadError")
local blocked = save("Avatar", nil, "runtime-loadfail-001")
check(not blocked.ok and not player:GetAttribute("OnboardingReady"), "Failed load blocks writes and race entry")
request({action="Retry"})
check(waitPhase("Choice").profile.gold == 0, "Load Retry recovers test profile")
local slow = preset("Slow loading")
check(slow.phase == "Loading" and not player:GetAttribute("OnboardingReady"), "Slow-loading preset remains held")
waitPhase("Choice")
preset("First visit", "Choice")
return {passed=#checks,checks=checks,finalState=state()}
