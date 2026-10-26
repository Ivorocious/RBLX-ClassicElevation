-- Runs only in a disposable Studio Play session, with isolated race dependencies.
local Test = {}

function Test.Run(course: Model)
	assert(game:GetService("RunService"):IsRunning(), "Studio Play required")
	local player = game.Players:GetPlayers()[1]
	local character = assert(player.Character)
	local root = character.HumanoidRootPart
	local saved = character:GetPivot()
	local origin = course:GetPivot()
	local checkpoint = 1
	local eligible = true
	local recoveries, records = {}, {}
	local respawnModule = game.ServerScriptService.Services.RespawnService:Clone()
	respawnModule.Parent = game.ServerScriptService
	local respawn = require(respawnModule)
	local function destination()
		return course.Checkpoints[string.format("Checkpoint_%03d", checkpoint)].CFrame + Vector3.new(0, 4, 0)
	end
	respawn.Init({ Services = {
		RaceService = { IsRaceActive = function() return true end },
		CourseService = {},
		PlayerRaceService = { IsOfficialRacer = function() return eligible end, GetPlayerStatus = function() return "Racing" end },
		CheckpointService = { GetCheckpointRespawnCFrame = destination },
		ResultsService = { RecordFall = function() end },
	} })
	local controller = require(game.ServerStorage.CourseBuilders.CityRun.Runtime).Create(course, function(p, label)
		local recovered = respawn.RecoverPlayer(p, label)
		if recovered then table.insert(recoveries, label) end
		return recovered
	end, function(p) return eligible and p == player end)
	local function place(p)
		character:PivotTo(origin * CFrame.new(p))
		root.AssemblyLinearVelocity = Vector3.zero
	end
	local function contact(name, time, p, cp)
		task.wait(1.6)
		checkpoint = cp
		controller.Step(time-.01, false)
		place(p)
		local before = #recoveries
		controller.Step(time, true)
		table.insert(records, { name = name, recovered = #recoveries == before + 1,
			checkpointError = (root.Position-destination().Position).Magnitude, label = recoveries[#recoveries] })
	end
	local ok, failure = xpcall(function()
		controller.Step(0, false)
		contact("CarContactToCP01", 4.5, Vector3.new(-170,15,164), 1)
		local hazards = require(game.ReplicatedStorage.Config.CityRunTuning).hazards
		local lastContact = 4.5
		local standingHeight = character.Humanoid.HipHeight+root.Size.Y/2
		for _, d in hazards.balls do
			for _, routeZ in { -257, -231 } do
				local angle = -math.asin((routeZ-d.pivot[3])/d.length)
				local time = (math.asin(angle/d.amplitude)-d.phase)*d.period/(math.pi*2)
				while time <= lastContact+.1 do time += d.period end
				contact(d.name..(if routeZ==-257 then "Main" else "Expert").."ToCP04", time,
					Vector3.new(d.pivot[1],82+standingHeight,routeZ),4)
				lastContact = time
			end
		end
		local rail = hazards.train
		local cycle = rail.openTime+(rail.endX-rail.startX)/rail.speed
		local trainTime = 13.4
		while trainTime <= lastContact+.1 do trainTime += cycle end
		contact("TrainContactToCP06", trainTime, Vector3.new(205,85.6,-12), 6)
		eligible = false
		place(Vector3.new(205,85.6,-12))
		local before = #recoveries
		controller.Step(trainTime+.01, true)
		table.insert(records, { name = "NonRacerExcluded", passed = #recoveries == before })
		controller.Step(trainTime+.7, false)
		table.insert(records, { name = "TrainCleared", phase = course:GetAttribute("TrainPhase"), gateClosed = course.Obstacles.TrainEntryGate.CanCollide })
		local sounds = {}
		for _, emitter in course.Obstacles.Audio:GetChildren() do
			local sound = emitter:FindFirstChildOfClass("Sound")
			table.insert(sounds, { name = sound.Name, id = sound.SoundId, loaded = sound.IsLoaded, duration = sound.TimeLength })
		end
		table.insert(records, { name = "AudioLoading", sounds = sounds })
	end, debug.traceback)
	controller.Stop()
	character:PivotTo(saved)
	root.AssemblyLinearVelocity = Vector3.zero
	respawnModule:Destroy()
	if not ok then error(failure) end
	return { records = records, limitation = "Actual imported hazards and RespawnService with isolated race/checkpoint dependencies; full race, human timing and multiplayer are not verified." }
end

return Test
