--!strict
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and game.PlaceId == 0 and game.GameId == 0, "Unpublished Moonlit test place only")
local services: any = {}
for _, name in {"CourseService", "RaceService", "PlayerRaceService", "CheckpointService", "ResultsService", "RespawnService", "StagingService", "OnboardingService", "MoonlitCitadelService"} do
	services[name] = require(game.ServerScriptService.Services:WaitForChild(name))
end
local deadline = os.clock() + 30
repeat task.wait(.1) until services.RaceService.IsStudioHoldingLobby() or os.clock() >= deadline
assert(services.RaceService.IsStudioHoldingLobby(), "Shared race bootstrap did not enter Studio lobby")
require(game.ServerStorage.MoonlitPhase2Tools.ServerProbe).Start(services, {
	diagnostics = services.MoonlitCitadelService.GetDiagnostics,
})
