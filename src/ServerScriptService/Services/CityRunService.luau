--!strict

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local RaceConstants = require(game.ReplicatedStorage.Shared.RaceConstants)

local CityRunService = {}
local services: any
local connection: RBXScriptConnection? = nil
local bound: Model? = nil
local controller: any = nil
local epoch = 0

function CityRunService.Init(context)
	services = context.Services
end

function CityRunService.Start()
	if connection then return end
	connection = RunService.Heartbeat:Connect(function()
		local course = services.CourseService.GetActiveCourse()
		if course ~= bound then
			if controller then controller.Stop(); controller = nil end
			bound = course
			if course and course:GetAttribute("CityRunRevision") then
				local Runtime = require(ServerStorage.CourseBuilders.CityRun.Runtime)
				controller = Runtime.Create(course, services.RespawnService.RecoverPlayer, function(player)
					return services.RaceService.IsRaceActive()
						and services.PlayerRaceService.IsOfficialRacer(player)
						and services.PlayerRaceService.GetPlayerStatus(player) == RaceConstants.PlayerRaceStatus.Racing
				end)
				epoch = workspace:GetServerTimeNow()
			end
		end
		if controller then controller.Step(workspace:GetServerTimeNow()-epoch, true) end
	end)
end

return CityRunService
