--!nonstrict
local RunService, Http = game:GetService("RunService"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 0 and game.GameId == 0)
assert(require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig).CandidateId == "MC_P2_C01_R06")
local tools = game.ReplicatedStorage.MoonlitPhase2Tools
local Control = require(game.ServerStorage.MoonlitPhase2Tools.TrialControl)
local services = Control.Services()
local previous
while script.Parent and tools.Parent do
	local command = tools:GetAttribute("R06Command")
	if command and command ~= previous then
		previous = command
		local ok, result = xpcall(function()
			local request = Http:JSONDecode(command)
			if request.action == "Restart" then return Control.Restart() end
			assert(request.action == "Debug", "Unknown owned diagnostic command")
			return {race = services.RaceService.GetRaceState(), raceId = services.RaceService.GetCurrentRaceId(),
				diagnostics = services.MoonlitCitadelService.GetDiagnostics()}
		end, debug.traceback)
		tools:SetAttribute("R06CommandResult", Http:JSONEncode({command = command, ok = ok, result = result}))
	end
	task.wait(.1)
end
