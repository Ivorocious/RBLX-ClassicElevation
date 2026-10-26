-- Run only as a temporary server Script in a disposable Studio Play session.
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local services = game.ServerScriptService.Services
local RaceService = require(services.RaceService)
local PlayerRaceService = require(services.PlayerRaceService)
local CourseService = require(services.CourseService)
local CheckpointService = require(services.CheckpointService)
local records = {}
local root, saved, anchored

local ok, failure = xpcall(function()
	assert(game.PlaceId == 85558151074819 and game:GetService("RunService"):IsRunning())
	local deadline = os.clock() + 40
	repeat task.wait(.1) until RaceService.IsRaceActive() or os.clock() > deadline
	assert(RaceService.IsRaceActive(), "Normal race did not start")
	local player = assert(Players:GetPlayers()[1])
	assert(PlayerRaceService.IsOfficialRacer(player) and PlayerRaceService.GetPlayerStatus(player) == "Racing")
	local course = CourseService.GetActiveCourse()
	assert(course:GetAttribute("CityRunRevision") == "C08")
	local character = assert(player.Character)
	root = character.HumanoidRootPart
	saved, anchored = character:GetPivot(), root.Anchored
	root.Anchored = true
	local traps = course.Obstacles.OwnerKillStrips:GetChildren()
	table.sort(traps, function(a, b) return a.Position.Z > b.Position.Z end)
	assert(#traps == 3, "Expected the three owner strips")
	for index, trap in traps do
		task.wait(1.7)
		local destination = CheckpointService.GetCheckpointRespawnCFrame(player)
		assert(destination, "No real checkpoint destination")
		local before = character:GetAttribute("RecoveryUntil") or 0
		character:PivotTo(trap.CFrame)
		local untilAt = os.clock() + 1.5
		repeat task.wait(.05) until (character:GetAttribute("RecoveryUntil") or 0) > before or os.clock() > untilAt
		local errorDistance = (root.Position - destination.Position).Magnitude
		local recovered = (character:GetAttribute("RecoveryUntil") or 0) > before and errorDistance < .05
		table.insert(records, {strip=index, position=tostring(trap.Position), recovered=recovered, checkpointError=errorDistance})
		assert(recovered, "Owner strip " .. index .. " did not recover the real racer")
	end
end, debug.traceback)
if root and root.Parent then
	root.Parent:PivotTo(saved)
	root.Anchored = anchored
	root.AssemblyLinearVelocity = Vector3.zero
end
script:SetAttribute("Result", HttpService:JSONEncode({passed=ok, records=records, failure=if ok then nil else failure,
	method="Normal running server services and actual official racer; no isolated race dependencies"}))
print("[CityRunOwnerContacts] " .. script:GetAttribute("Result"))
