--!nonstrict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Case = {}
local report

function Case.Debug() return report end

function Case.Start(services)
	assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 0 and game.GameId == 0)
	assert(not report, "One controlled shared-flow proof per module")
	report = {candidate="MC_P2_FLOW_SEED",source="Controlled placements through actual shared services; not ordinary route traversal",steps={},players={},state="Starting"}
	task.spawn(function()
		local staged, connection = {}, nil
		local previousRaceId
		local ok, reason = xpcall(function()
			local racers = Players:GetPlayers()
			assert(#racers == 2, "Two actual clients required")
			local function await(test, seconds, label)
				local deadline=os.clock()+seconds
				repeat if test() then return end;task.wait(.05) until os.clock()>=deadline
				error("Timed out "..label)
			end
			local function snapshot(label)
				local rows={}
				for _,player in racers do table.insert(rows,{userId=player.UserId,status=services.PlayerRaceService.GetPlayerStatus(player),checkpoint=services.CheckpointService.GetLatestCheckpointIndex(player),progress=player:GetAttribute("MCPhase2Progress")}) end
				table.insert(report.steps,{label=label,raceId=services.RaceService.GetCurrentRaceId(),raceState=services.RaceService.GetRaceState(),players=rows})
			end
			await(function() for _,p in racers do if not p:GetAttribute("OnboardingReady") then return false end end;return true end,20,"onboarding")
			connection=RunService.Heartbeat:Connect(function()
				local course=services.CourseService.GetActiveCourse()
				local start=course and course:FindFirstChild("Start")
				if not start then return end
				for _,p in racers do
					local root=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					local status=services.PlayerRaceService.GetPlayerStatus(p)
					local freshRacing=previousRaceId~=nil and services.RaceService.GetCurrentRaceId()~=previousRaceId
						and status=="Racing" and (services.RaceService.GetElapsedRaceTime() or math.huge)<=.5
					if root and (status=="Queued" or freshRacing) then
						local point=start.CFrame:PointToObjectSpace(root.Position)
						if math.abs(point.X)<start.Size.X/2+4 and math.abs(point.Z)<start.Size.Z/2+4 and math.abs(point.Y)<12 then staged[p]=if status=="Queued" then "QueuedAtStart" else "FirstRacingSampleAtStart" end
					end
				end
			end)
			assert(services.CourseService.SelectCourseForStudio("moonlit_citadel"))
			services.RaceService.SetInspectionUnlimitedTime(true)
			previousRaceId=services.RaceService.GetCurrentRaceId()
			assert(services.RaceService.ApplyStudioAction("RestartRace"))
			await(function() return services.RaceService.GetCurrentRaceId()~=previousRaceId and services.RaceService.IsRaceActive() and services.PlayerRaceService.IsOfficialRacer(racers[1]) and services.PlayerRaceService.IsOfficialRacer(racers[2]) end,30,"official race start")
			local course=services.CourseService.GetActiveCourse()
			assert(course:GetAttribute("CandidateId")=="MC_P2_FLOW_SEED")
			await(function() return staged[racers[1]] and staged[racers[2]] end,1,"actual start entry observation")
			for _,p in racers do table.insert(report.steps,{label="Start entry observation",userId=p.UserId,evidence=staged[p]}) end
			snapshot("Official staged entry")
			local function place(player, frame)
				local character=assert(player.Character)
				for _,part in character:GetDescendants() do if part:IsA("BasePart") then part.AssemblyLinearVelocity,part.AssemblyAngularVelocity=Vector3.zero,Vector3.zero end end
				character:PivotTo(frame)
			end
			place(racers[1],course.Finish.CFrame)
			task.wait(.4)
			assert(services.PlayerRaceService.GetPlayerStatus(racers[1])=="Racing" and services.CheckpointService.GetLatestCheckpointIndex(racers[1])==0,"Unordered finish accepted")
			snapshot("Unordered finish rejected")
			for index=1,4 do
				for _,p in racers do place(p,course.Checkpoints[string.format("Checkpoint_%03d",index)].CFrame) end
				await(function() for _,p in racers do if services.CheckpointService.GetLatestCheckpointIndex(p)~=index then return false end end;return true end,3,"checkpoint "..index)
				snapshot("Checkpoint "..index)
				if index==2 then
					place(racers[2],course.FallZones.FlowTestFall.CFrame)
					await(function() return services.ResultsService.GetCurrentRaceResult().activeRacers[2]~=nil and racers[2].Character:GetAttribute("RecoveryUntil")~=nil end,4,"fall recovery")
					assert(services.CheckpointService.GetLatestCheckpointIndex(racers[2])==2)
					snapshot("Fall resumes CP02")
					task.wait(1.6)
				end
			end
			for _,p in racers do place(p,course.Finish.CFrame) end
			await(function() for _,p in racers do if services.PlayerRaceService.GetPlayerStatus(p)~="Finished" then return false end end;return true end,4,"ordered finish")
			snapshot("One-lap finish")
			local result=services.ResultsService.GetCurrentRaceResult()
			assert(result.raceFormat=="PointToPoint" and #result.placements==2)
			for _,entry in result.placements do
				assert(entry.requiredLaps==1 and #entry.checkpointSplits==4)
				for i,split in entry.checkpointSplits do assert(split.checkpointIndex==i and split.lap==1) end
				table.insert(report.players,{userId=entry.userId,falls=entry.falls,finishTime=entry.finishTime,requiredLaps=entry.requiredLaps,splits=entry.checkpointSplits})
			end
			assert(services.RaceService.ApplyStudioAction("HoldLobby"))
			await(function() if services.RaceService.IsRaceActive() then return false end;for _,p in racers do if services.PlayerRaceService.GetPlayerStatus(p)~="Lobby" then return false end end;return true end,30,"lobby exit")
			snapshot("Lobby exit")
			report.state,report.complete="Passed",true
		end,debug.traceback)
		if connection then connection:Disconnect() end
		if not ok then report.state,report.failure="Failed",tostring(reason) end
	end)
	return {state=report.state}
end

return Case
