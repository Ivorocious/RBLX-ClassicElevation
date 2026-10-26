--!nonstrict
assert(game.PlaceId == 0 and game.GameId == 0 and game.RunService:IsStudio() and game.RunService:IsServer())
local H = game.HttpService
local tools = game.ReplicatedStorage.MoonlitPhase2Tools
local Control = require(game.ServerStorage.MoonlitPhase2Tools.TrialControl)
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
assert(Config.CandidateId == "MC_P2_C01_R05")
local function waitFor(test, seconds, label)
 local deadline = os.clock() + seconds
 repeat if test() then return end task.wait(.1) until os.clock() >= deadline
 error(label)
end
local ok, err = xpcall(function()
 local services = Control.Services()
 assert(services.RaceService.ApplyStudioAction("HoldLobby"))
 services.RaceService.SetInspectionUnlimitedTime(true)
 require(game.ServerStorage.MoonlitPhase2Tools.ServerProbe).Start(services, {diagnostics=services.MoonlitCitadelService.GetDiagnostics})
 local routes = Control.PrepareRoutes()
 waitFor(function() return #game.Players:GetPlayers() == 1 end, 20, "One native client required")
 local player = game.Players:GetPlayers()[1]
 waitFor(function() return services.OnboardingService.SetStudioPreset(player, "Returning racer") end, 30, "Returning-racer preset")
 waitFor(function() return player:GetAttribute("ArrivalPhase") == "Ready" and player:GetAttribute("ArrivalOpen") == false end, 60, "Actual arrival transition")
 task.wait(10)
 tools:SetAttribute("R05ProofSetup", H:JSONEncode({candidate=Config.CandidateId,actualPlayers=1,userId=player.UserId,routes=routes,method="Actual server Script in live VM; existing shared inspection services"}))
 tools:SetAttribute("R05ProofReady", true)
 task.wait(3)
 tools:SetAttribute("R05ProofRestart", H:JSONEncode(Control.Restart()))
end, debug.traceback)
if not ok then tools:SetAttribute("R05ProofFailure", tostring(err)) end
