--!nonstrict
local Run, H, Players = game:GetService("RunService"), game:GetService("HttpService"), game:GetService("Players")
assert(Run:IsStudio() and Run:IsServer() and game.PlaceId == 85558151074819 and game.GameId == 10191126818 and game.CreatorId == 86069177)
assert(script:GetAttribute("OwnedMoonlitTest") == true and script:GetAttribute("RunRecovery") == true)
assert(#Players:GetPlayers() == 2 and Players:GetPlayerByUserId(-1) and Players:GetPlayerByUserId(-2))
local tools = game.ServerStorage.MoonlitPhase2Tools
local Control = require(tools.TrialControl)
local services = Control.Services()
local report = {startedAt = workspace:GetServerTimeNow(), state = "Starting", kind = "Existing Studio preset recovery; no direct arrival flags or UI changes", players = {}}
local ok, failure = xpcall(function()
	assert(services.RaceService.ApplyStudioAction("HoldLobby"))
	task.wait(.5)
	for _, id in {-2} do
		local player = assert(Players:GetPlayerByUserId(id))
		local accepted, reason = services.OnboardingService.SetStudioPreset(player, "Returning racer")
		assert(accepted, reason)
		table.insert(report.players, {userId = id, acceptedAt = workspace:GetServerTimeNow(), reason = reason})
	end
end, debug.traceback)
report.state, report.failure, report.endedAt = if ok then "Complete" else "Failed", if ok then nil else tostring(failure), workspace:GetServerTimeNow()
local value = Instance.new("StringValue")
value.Name, value.Value, value.Parent = "OriginalAPIRecoveryReport", H:JSONEncode(report), script
script:SetAttribute("State", report.state)
if not ok then warn(report.failure) end
