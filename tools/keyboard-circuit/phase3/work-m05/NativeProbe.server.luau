local Storage = game:GetService("ServerStorage")
local root = Instance.new("Folder")
root.Name, root.Parent = "KCM05NativeProbe", Storage
local services = game.ServerScriptService.Services
local Course, Race, PlayerRace, Results, Respawn = require(services.CourseService), require(services.RaceService), require(services.PlayerRaceService), require(services.ResultsService), require(services.RespawnService)
local snapshot = Instance.new("BindableFunction")
snapshot.Name, snapshot.Parent = "Snapshot", root
snapshot.OnInvoke = function()
	local player = game.Players:GetPlayers()[1]
	local course = Course.GetActiveCourse()
	return {state=Race.GetRaceState(), official=player and PlayerRace.IsOfficialRacer(player), status=player and PlayerRace.GetPlayerStatus(player), raceId=Race.GetCurrentRaceId(), results=Results.GetCurrentRaceResult(), runtime=course and course:GetAttribute("KCCourseRuntimeActive"), failure=course and course:GetAttribute("KCCourseRuntimeFailure")}
end
local recover = Instance.new("BindableFunction")
recover.Name, recover.Parent = "Recover", root
recover.OnInvoke = function(reason)
	return Respawn.RecoverPlayer(game.Players:GetPlayers()[1], reason)
end
