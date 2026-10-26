-- Temporary normal server Script in a disposable Studio Play session.
local services = game.ServerScriptService.Services
local CourseService = require(services.CourseService)
local CheckpointService = require(services.CheckpointService)
local PlayerRaceService = require(services.PlayerRaceService)
local tuning = require(game.ReplicatedStorage.Config.CityRunTuning).hazards.cars
local records = {}
local player = game.Players:GetPlayers()[1]
local character = player and player.Character
local root = character and character:FindFirstChild("HumanoidRootPart")
local saved = character and character:GetPivot()
local anchored = root and root.Anchored
local course
local function visibleCarBefore(x)
	for index = 0, 2 do
		local car = course.Obstacles.Moving["Car" .. index]
		local mesh = car:FindFirstChildWhichIsA("BasePart", true)
		if mesh and mesh.Transparency == 0 and car:GetPivot().X < x then return car end
	end
	return nil
end
local ok, failure = xpcall(function()
	assert(game.PlaceId == 85558151074819 and game:GetService("RunService"):IsRunning())
	assert(character and root and PlayerRaceService.GetPlayerStatus(player) == "Racing")
	course = CourseService.GetActiveCourse()
	assert(course:GetAttribute("ReviewBuildId") == "C09_05_Park")
	if CheckpointService.GetLatestCheckpointIndex(player) == 0 then
		CheckpointService.SkipCheckpointForStudio(player)
		local deadline = os.clock() + 3
		repeat task.wait(.05) until CheckpointService.GetLatestCheckpointIndex(player) >= 1 or os.clock() > deadline
	end
	assert(CheckpointService.GetLatestCheckpointIndex(player) == 1, "CP01 must register normally")
	root.Anchored = true
	character:PivotTo(CFrame.new(3260, 15.4, 171))
	local deadline = os.clock() + 9
	local car
	repeat car = visibleCarBefore(3200); task.wait(.05) until car or os.clock() > deadline
	assert(car, "No approaching car")
	game:GetService("RunService").Heartbeat:Wait()
	local startTime, startPosition = workspace:GetServerTimeNow(), car:GetPivot().Position
	task.wait(.5)
	game:GetService("RunService").Heartbeat:Wait()
	local elapsed = workspace:GetServerTimeNow() - startTime
	local speed = (car:GetPivot().Position - startPosition).Magnitude / elapsed
	table.insert(records, {name="MeasuredCarSpeed", studsPerSecond=speed, expected=56, passed=math.abs(speed-56)<2})
	assert(math.abs(speed - 56) < 2, "Car speed differs from tuning")
	local before = character:GetAttribute("RecoveryUntil") or 0
	deadline = os.clock() + 4
	repeat task.wait(.05) until car:GetPivot().X > 3280 or os.clock() > deadline
	local safe = (character:GetAttribute("RecoveryUntil") or 0) <= before
	table.insert(records, {name="BesideCarLaneSafe", safe=safe, rootPosition=tostring(root.Position)})
	assert(safe, "Car recovered a racer clear of its lane")
	task.wait(1.7)
	local destination = CheckpointService.GetCheckpointRespawnCFrame(player)
	before = character:GetAttribute("RecoveryUntil") or 0
	character:PivotTo(CFrame.new(3260, 15.4, 164))
	deadline = os.clock() + 8
	repeat task.wait(.05) until (character:GetAttribute("RecoveryUntil") or 0) > before or os.clock() > deadline
	local recovered = (character:GetAttribute("RecoveryUntil") or 0) > before
	local errorDistance = (root.Position - destination.Position).Magnitude
	table.insert(records, {name="CarContactToCP01", recovered=recovered, checkpointError=errorDistance})
	assert(recovered and errorDistance < .1, "Car contact did not recover to CP01")
	table.insert(records, {name="ConfiguredClearGap", shortestSpawnInterval=math.min(table.unpack(tuning.intervals)),
		vehicleOccupancySeconds=tuning.size[1]/tuning.speed,
		minimumClearSeconds=math.min(table.unpack(tuning.intervals))-tuning.size[1]/tuning.speed,
		method="Configuration calculation at a fixed crossing line; not a human crossing-time test"})
end, debug.traceback)
if root and root.Parent then
	character:PivotTo(saved)
	root.Anchored = anchored
	root.AssemblyLinearVelocity = Vector3.zero
end
script:SetAttribute("Result", game.HttpService:JSONEncode({passed=ok, records=records, failure=if ok then nil else failure,
	method="Normal server-driven traffic, actual official racer, and normal CP01 registration"}))
print("[CityRunC09Traffic] " .. script:GetAttribute("Result"))
