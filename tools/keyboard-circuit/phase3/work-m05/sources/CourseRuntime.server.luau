--!strict
local RunService = game:GetService("RunService")
if not RunService:IsServer() then return end
local course = script.Parent
if not course:IsA("Model") or course:GetAttribute("SharedCourseEnabled") ~= true then return end

local services = game:GetService("ServerScriptService"):WaitForChild("Services")
local CourseService = require(services:WaitForChild("CourseService"))
local RaceService = require(services:WaitForChild("RaceService"))
local PlayerRaceService = require(services:WaitForChild("PlayerRaceService"))
local RespawnService = require(services:WaitForChild("RespawnService"))
local RaceConstants = require(game:GetService("ReplicatedStorage").Shared.RaceConstants)
local MechanismRuntime = require(course:WaitForChild("SourceSnapshot"):WaitForChild("MechanismRuntime"))

local controller: any = nil
local raceId: string? = nil
local heartbeat: RBXScriptConnection? = nil
local destroying: RBXScriptConnection? = nil
local ancestry: RBXScriptConnection? = nil
local stopped = false
local failedRaceId: string? = nil

local function eligible(player: Player): boolean
	local character = player.Character
	return not stopped and CourseService.GetActiveCourse() == course and RaceService.IsRaceActive()
		and PlayerRaceService.IsOfficialRacer(player)
		and PlayerRaceService.GetPlayerStatus(player) == RaceConstants.PlayerRaceStatus.Racing
		and character ~= nil and (character:GetAttribute("RecoveryUntil") or 0) <= workspace:GetServerTimeNow()
end

local function recover(player: Player, reason: string): boolean
	if not eligible(player) then return false end
	return RespawnService.RecoverPlayer(player, reason)
end

local function stopMechanisms()
	if controller then controller.Stop(); controller = nil end
	raceId = nil
	course:SetAttribute("KCCourseRuntimeActive", false)
end

local function stop()
	if stopped then return end
	stopped = true
	if heartbeat then heartbeat:Disconnect(); heartbeat = nil end
	if destroying then destroying:Disconnect(); destroying = nil end
	if ancestry then ancestry:Disconnect(); ancestry = nil end
	stopMechanisms()
end

local function step()
	local active = course:IsDescendantOf(workspace) and CourseService.GetActiveCourse() == course and RaceService.IsRaceActive()
	local currentId = if active then RaceService.GetCurrentRaceId() else nil
	if not active or currentId == "" then
		if controller then stopMechanisms() end
		failedRaceId = nil
		return
	end
	if controller and raceId == currentId then
		if not controller.IsActive() then
			local failure = controller.Diagnostics().failure
			stopMechanisms()
			failedRaceId = currentId
			course:SetAttribute("KCCourseRuntimeFailure", failure or "Mechanisms stopped before the race ended")
		end
		return
	end
	if failedRaceId == currentId then return end
	stopMechanisms()
	local success, result = pcall(MechanismRuntime.Start, course, eligible, recover)
	if not success then
		failedRaceId = currentId
		course:SetAttribute("KCCourseRuntimeFailure", tostring(result))
		warn("Keyboard Circuit mechanisms could not start: " .. tostring(result))
		return
	end
	controller, raceId = result, currentId
	course:SetAttribute("KCCourseRuntimeFailure", nil)
	course:SetAttribute("KCCourseRuntimeActive", true)
end

course:SetAttribute("KCCourseRuntimeActive", false)
heartbeat = RunService.Heartbeat:Connect(step)
destroying = course.Destroying:Connect(stop)
ancestry = course.AncestryChanged:Connect(function()
	if not course:IsDescendantOf(workspace) then stop() end
end)
