--!strict

local RunService = game:GetService("RunService")
local Runtime = require(game.ServerStorage.CourseBuilders.StudGarden.Runtime)
local RaceConstants = require(game.ReplicatedStorage.Shared.RaceConstants)

local Service = {}
local services: any
local heartbeat: RBXScriptConnection? = nil
local boundCourse: Model? = nil
local controller: any = nil

function Service.Init(context: any)
	services = context.Services
end

local function isEligible(player: Player): boolean
	return services.RaceService.IsRaceActive() == true
		and services.PlayerRaceService.IsOfficialRacer(player) == true
		and services.PlayerRaceService.GetPlayerStatus(player) == RaceConstants.PlayerRaceStatus.Racing
end

function Service.Start()
	if heartbeat ~= nil then
		return
	end
	assert(services ~= nil, "StudGardenService.Init must run before Start")
	heartbeat = RunService.Heartbeat:Connect(function()
		local course = services.CourseService.GetActiveCourse()
		local active = services.RaceService.IsRaceActive() == true
		local isStudGarden = course ~= nil and course:GetAttribute("CourseId") == "stud_garden_v2"
			and course:GetAttribute("SGV2Owned") == true
		local target = if isStudGarden and active then course else nil
		if target == boundCourse then
			return
		end
		if controller ~= nil then
			controller.Stop()
		end
		controller = nil
		boundCourse = target
		if target ~= nil then
			controller = Runtime.Start(target, isEligible, services.RespawnService.RecoverPlayer)
		end
	end)
end

function Service.Stop()
	if heartbeat ~= nil then
		heartbeat:Disconnect()
		heartbeat = nil
	end
	if controller ~= nil then
		controller.Stop()
		controller = nil
	end
	boundCourse = nil
end

function Service.GetDiagnostics(): any
	return if controller ~= nil then controller.Diagnostics() else {bound = false}
end

return Service
