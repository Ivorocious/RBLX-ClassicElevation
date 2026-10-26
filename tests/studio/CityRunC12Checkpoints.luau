-- Real avatar contacts on a copied course, with isolated race and results dependencies.
local Test = {}

function Test.Run(template: Model)
	assert(game.PlaceId == 85558151074819 and game:GetService("RunService"):IsRunning())
	local player = assert(game.Players:GetPlayers()[1])
	local character = assert(player.Character)
	local root = character.HumanoidRootPart
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local saved, anchored = character:GetPivot(), root.Anchored
	local fixture = template:Clone()
	fixture.Name = "__C12CheckpointFixture"
	fixture:PivotTo(CFrame.new(8000, 100, 0))
	fixture.Parent = workspace
	local current = fixture
	local source = game.ServerScriptService.Services.CheckpointService:Clone()
	source.Name, source.Parent = "__C12CheckpointService", game.ServerStorage
	local service = require(source)
	local raceId, active, eligible, status, format = "C12-0", true, true, "Racing", "PointToPoint"
	local splits, finishes, laps = 0, 0, 0
	local definitions = {}
	for index = 1, 7 do
		local p = fixture.Checkpoints[string.format("Checkpoint_%03d", index)]
		table.insert(definitions, {index=index, name=p.Name, part=p})
	end
	service.Init({Services={
		RaceService={IsRaceActive=function() return active end, GetCurrentRaceId=function() return raceId end,
			GetElapsedRaceTime=function() return os.clock() end},
		PlayerRaceService={IsOfficialRacer=function() return eligible end, GetPlayerStatus=function() return status end,
			SetPlayerStatus=function(_, nextStatus) status=nextStatus end},
		CourseService={GetActiveCourseModel=function() return current end,
			GetStartPart=function() return fixture.Start end, GetFinishPart=function() return fixture.Finish end,
			GetOrderedCheckpoints=function() return definitions end, GetRaceFormat=function() return format end,
			GetLapCount=function() return 2 end},
		ResultsService={UpdateCheckpointProgress=function() end,
			RecordCheckpointSplit=function() splits+=1 end,
			RecordFinish=function() finishes+=1; return {} end,
			RecordLapComplete=function() laps+=1 end},
	}})
	service.BindActiveCourse()
	local records = {}
	local function waitFor(predicate, seconds, message)
		local deadline = os.clock()+seconds
		repeat task.wait(.025) until predicate() or os.clock()>deadline
		assert(predicate(), message)
	end
	local function drop(p)
		root.Anchored = false
		root:SetNetworkOwner(nil)
		humanoid.Sit = false
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		character:PivotTo(p.CFrame+Vector3.new(0,5,0))
	end
	local function touch(p, expected)
		drop(p)
		waitFor(function() return service.GetLatestCheckpointIndex(player)==expected end, 2.5, p.Name .. " did not register")
	end
	local ok, failure = xpcall(function()
		local primary = fixture.Checkpoints.Checkpoint_003
		for attempt, branch in {primary, primary.AlternateTriggers.ExpertRoute} do
			raceId, status, splits, finishes = "C12-branch-" .. attempt, "Racing", 0, 0
			drop(definitions[2].part)
			task.wait(.55)
			assert(service.GetLatestCheckpointIndex(player)==0, "Out-of-order touch advanced progress")
			drop(fixture.Finish)
			task.wait(.55)
			assert(finishes==0, "Early finish was accepted")
			for index = 1, 7 do
				local p = if index==3 then branch else definitions[index].part
				touch(p, index)
				local expected = p.CFrame+Vector3.new(0,5,0)
				assert((service.GetCheckpointRespawnCFrame(player).Position-expected.Position).Magnitude<.01,
					"Checkpoint respawn does not match the touched route")
				if index==3 then
					local other = if branch==primary then primary.AlternateTriggers.ExpertRoute else primary
					drop(other)
					task.wait(.55)
					assert(splits==3 and service.GetLatestCheckpointIndex(player)==3, "Alternate counted twice")
					assert((service.GetCheckpointRespawnCFrame(player).Position-expected.Position).Magnitude<.01,
						"Duplicate alternate replaced the accepted respawn")
				end
			end
			drop(fixture.Finish)
			waitFor(function() return finishes==1 end, 2.5, "Finish did not register after all seven checkpoints")
			assert(splits==7 and status=="Finished")
			table.insert(records, {branch=branch.Name, orderedTouches=7, splits=splits, finishAccepted=true,
				outOfOrderRejected=true, earlyFinishRejected=true, duplicateAlternateRejected=true, respawnMatched=true})
		end
		raceId, status, eligible = "C12-ineligible", "Racing", false
		drop(definitions[1].part)
		task.wait(.55)
		assert(service.GetLatestCheckpointIndex(player)==0, "Non-racer checkpoint accepted")
		eligible, active = true, false
		drop(definitions[1].part)
		task.wait(.55)
		assert(service.GetLatestCheckpointIndex(player)==0, "Inactive checkpoint accepted")
		table.insert(records, {nonRacerRejected=true, inactiveRaceRejected=true})
		active, raceId, format, status, splits, finishes, laps = true, "C12-lap-reset", "LapBased", "Racing", 0, 0, 0
		for index = 1, 7 do touch(if index==3 then primary.AlternateTriggers.ExpertRoute else definitions[index].part, index) end
		drop(fixture.Finish)
		waitFor(function() return laps==1 end, 2.5, "Lap did not complete")
		assert(finishes==0 and service.GetLatestCheckpointIndex(player)==0)
		assert((service.GetCheckpointRespawnCFrame(player).Position-(fixture.Start.Position+Vector3.new(0,5,0))).Magnitude<.01,
			"Next lap retained the prior branch respawn")
		touch(definitions[1].part, 1)
		table.insert(records, {lapResetToStart=true, nextLapCheckpointAccepted=true})
	end, debug.traceback)
	current = nil
	service.BindActiveCourse()
	character:PivotTo(saved)
	root.Anchored = anchored
	root.AssemblyLinearVelocity = Vector3.zero
	if not root.Anchored then root:SetNetworkOwnershipAuto() end
	fixture:Destroy()
	source:Destroy()
	return {passed=ok, records=records, failure=if ok then nil else failure,
		method="Actual C12 checkpoint geometry and real avatar contacts; isolated race/results dependencies",
		limitation="Tests checkpoint behavior, not complete route traversal or multiplayer spacing"}
end

return Test
