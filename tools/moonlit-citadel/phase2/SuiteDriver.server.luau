--!nonstrict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 0 and game.GameId == 0, "Owned native fixture only")
local tools = game.ReplicatedStorage:WaitForChild("MoonlitPhase2Tools")
local Control = require(game.ServerStorage.MoonlitPhase2Tools.TrialControl)
local function waitFor(predicate, seconds, message)
	local deadline = os.clock() + seconds
	repeat if predicate() then return end; task.wait(.1) until os.clock() >= deadline
	error(message)
end
local ok, reason = xpcall(function()
	local services = Control.Services()
	waitFor(services.RaceService.IsStudioHoldingLobby, 60, "Shared lobby startup timed out")
	assert(services.RaceService.ApplyStudioAction("HoldLobby"))
	waitFor(function() return #Players:GetPlayers() == 2 end, 90, "Two native clients did not arrive")
	local presets = {}
	for _, player in Players:GetPlayers() do
		waitFor(function()
			local accepted, message = services.OnboardingService.SetStudioPreset(player, "Returning racer")
			if accepted then table.insert(presets, {userId=player.UserId, message=message}) end
			return accepted
		end, 30, "Temporary Studio arrival preset did not become available")
	end
	local routes = Control.PrepareRoutes()
	waitFor(function()
		for _, player in Players:GetPlayers() do if player:GetAttribute("ArrivalPhase") ~= "Ready" then return false end end
		return true
	end, 90, "Actual shared arrival did not become ready")
	-- Let the real client arrival transition release its movement controls.
	task.wait(10)
	tools:SetAttribute("NativeSuiteReady", true)
	tools:SetAttribute("NativeSuiteSetup", HttpService:JSONEncode({presets=presets, routes=routes, at=workspace:GetServerTimeNow()}))
	task.wait(3)
	tools:SetAttribute("NativeSuiteRestart", HttpService:JSONEncode(Control.Restart()))
end, debug.traceback)
if not ok then tools:SetAttribute("NativeSuiteFailure", tostring(reason)); warn(reason) end
