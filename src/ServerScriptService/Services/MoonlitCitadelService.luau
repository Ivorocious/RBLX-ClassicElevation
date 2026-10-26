--!strict

local RunService = game:GetService("RunService")
local Runtime = require(game.ServerStorage.CourseBuilders.MoonlitCitadelCourse.Runtime)
local RaceConstants = require(game.ReplicatedStorage.Shared.RaceConstants)

local Service = {}
local services: any
local heartbeat: RBXScriptConnection? = nil
local boundCourse: Model? = nil
local boundRaceId = ""
local controller: any = nil

function Service.Init(context: any)
	services = context.Services
end

local function isEligible(player: Player): boolean
	return services.RaceService.IsRaceActive() == true
		and services.CourseService.GetActiveCourse() == boundCourse
		and services.RaceService.GetCurrentRaceId() == boundRaceId
		and services.PlayerRaceService.IsOfficialRacer(player) == true
		and services.PlayerRaceService.GetPlayerStatus(player) == RaceConstants.PlayerRaceStatus.Racing
end

local function clearBinding()
	if controller ~= nil then controller.Stop() end
	controller = nil
	boundCourse, boundRaceId = nil, ""
end

function Service.Start()
	if heartbeat ~= nil then return end
	assert(services ~= nil, "MoonlitCitadelService.Init must run before Start")
	heartbeat = RunService.Heartbeat:Connect(function()
		local course = services.CourseService.GetActiveCourse()
		local active = services.RaceService.IsRaceActive() == true
		local isMoonlit = course ~= nil and course:GetAttribute("CourseId") == "moonlit_citadel"
			and course:GetAttribute("MoonlitCourse") == true
		local target = if isMoonlit and active then course else nil
		local raceId = if target ~= nil then services.RaceService.GetCurrentRaceId() else ""
		if target == boundCourse and raceId == boundRaceId then return end
		clearBinding()
		if target ~= nil then
			boundCourse, boundRaceId = target, raceId
			controller = Runtime.Start(target, isEligible, services.RespawnService.RecoverPlayer)
		end
	end)
end

function Service.Stop()
	if heartbeat ~= nil then heartbeat:Disconnect(); heartbeat = nil end
	clearBinding()
end

function Service.GetDiagnostics(): any
	if controller == nil then return { bound = false } end
	local report = controller.Diagnostics()
	report.raceId = boundRaceId
	return report
end

return Service
