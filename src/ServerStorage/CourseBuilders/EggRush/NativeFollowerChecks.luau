--!nonstrict
local Check = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local busy = false
local CASES = {
	{ name = "ShellworksClose", section = "Shellworks", delay = .45 },
	{ name = "IncubatorClose", section = "Incubator", delay = .45 },
	{ name = "IncubatorSplit", section = "Incubator", followerSection = "IncubatorAlternate", delay = .45 },
	{ name = "ShellworksLate", section = "Shellworks", delay = 6 },
}
local PARKING_POCKETS = {
	Shell_ForkWait = true, Shell_MiddleWait = true, Shell_ExitWait = true,
	Tray_BoardPocket = true, Tray_ReceivePocket = true, CP3_Pocket = true,
}
local function vector(p) return { p.X, p.Y, p.Z } end
local function stringReceipt(parent, name)
	local value = Instance.new("StringValue")
	value.Name, value.Parent = name, parent
	return value
end

function Check.Run(services, command)
	assert(RunService:IsStudio() and RunService:IsServer(), "Studio server follower checks only")
	assert(not busy, "Follower checks already running")
	command = command or {}
	local selected = {}
	for _, case in ipairs(CASES) do
		if command.case == nil or command.case == case.name then table.insert(selected, case) end
	end
	assert(#selected > 0, "Unknown follower case")
	busy = true
	local parent = ServerStorage:FindFirstChild("EggRushNativeFollowerReceipts")
	if not parent then parent = Instance.new("Folder"); parent.Name = "EggRushNativeFollowerReceipts"; parent.Parent = ServerStorage end
	local folder = Instance.new("Folder")
	folder.Name = Http:GenerateGUID(false); folder.Parent = parent
	local stored = stringReceipt(folder, "Report")
	local report = { ok = false, cases = {}, limits = {
		"Two actual Players using scripted server-owned native traversal; isolated sections with listed CP2 inspection writes and initial placement teleports",
		"Existing avatar collision settings are unchanged; avatars may overlap if the game collision groups permit it",
		"Two-person mechanism opportunity evidence only; no 20-racer capacity, crowd space, passing, human control, device or FPS proof",
		"Warning receipts record server states, visible lamp properties and avatar positions; no line-of-sight, human recognition or audio-audibility proof",
		"Each script walks sideways on wide fixed pockets to leave their landing centers clear; this is active queue positioning, not center-only autopilot or crowd-capacity proof",
		"Receipts exist in this Play session; export their JSON before stopping Studio",
	} }
	local started, observer = os.clock(), nil
	local function persist() stored.Value = Http:JSONEncode(report) end
	folder:SetAttribute("State", "Running"); persist()
	local ok, failure = xpcall(function()
		local players = Players:GetPlayers()
		assert(#players == 2, "Start the prepared two-actual-player native session")
		table.sort(players, function(a, b) return a.UserId < b.UserId end)
		local course = assert(services.CourseService.GetActiveCourse(), "Missing prepared course")
		local raceId = services.RaceService.GetCurrentRaceId()
		assert(course:GetAttribute("CourseId") == "egg_rush_circuit" and course:GetAttribute("EROwned") == true, "Wrong owned course")
		assert(services.RaceService.IsRaceActive() and raceId ~= "", "Prepare a fresh official race")
		local runtime = services.EggRushService.GetDiagnostics()
		assert(runtime.bound and runtime.raceId == raceId and runtime.movementProfiles == 2, "Both Egg Rush movement profiles must be bound")
		assert(math.abs(workspace.Gravity - 196.2) < .01, "Wrong actual gravity")
		report.candidateId, report.raceId, report.gravity = course:GetAttribute("CandidateId"), raceId, workspace.Gravity
		local traversal = require(script.Parent.NativeTraversal)
		local function raceValid()
			return services.CourseService.GetActiveCourse() == course and services.RaceService.IsRaceActive()
				and services.RaceService.GetCurrentRaceId() == raceId
		end
		local function falls(player)
			return assert(services.ResultsService.GetPlayerResult(player), "Missing official result").falls or 0
		end
		local function eligible(player)
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			return player.Parent == Players and services.PlayerRaceService.IsOfficialRacer(player)
				and services.PlayerRaceService.GetPlayerStatus(player) == "Racing" and humanoid and humanoid.Health > 0
				and humanoid.WalkSpeed == 16 and not humanoid.UseJumpPower and math.abs(humanoid.JumpHeight - 7.2) < .01
		end
		for caseIndex, definition in ipairs(selected) do
			assert(raceValid(), "Race changed between follower cases")
			local case = { name = definition.name, section = definition.section, followerSection = definition.followerSection, line = "Normal", followerDelay = definition.delay,
				deadlineSeconds = 45, ok = false, participants = {}, warnings = {}, setups = {} }
			table.insert(report.cases, case)
			local caseStored = stringReceipt(folder, string.format("Case%d_%s", caseIndex, definition.name))
			local function persistCase() caseStored.Value = Http:JSONEncode(case); persist() end
			persistCase()
			local caseStarted, cancelled, done = os.clock(), false, { false, false }
			local deadline = caseStarted + 45
			local beforeFalls, characters, roots, playerStored = {}, {}, {}, {}
			for index, player in ipairs(players) do
				assert(eligible(player), "Both participants must be eligible official racers at16/7.2")
				characters[index] = player.Character; roots[index] = characters[index].HumanoidRootPart
				local humanoid = characters[index]:FindFirstChildOfClass("Humanoid")
				beforeFalls[index] = falls(player)
				local participant = { role = if index == 1 then "Leader" else "Follower", userId = player.UserId, name = player.Name,
					section = if index == 2 and definition.followerSection then definition.followerSection else definition.section,
					profile = { walk = humanoid.WalkSpeed, jump = humanoid.JumpHeight, usePower = humanoid.UseJumpPower }, collisionParts = {}, parking = {} }
				for _, part in ipairs(characters[index]:GetChildren()) do
					if part:IsA("BasePart") then table.insert(participant.collisionParts, { name = part.Name, group = part.CollisionGroup, canCollide = part.CanCollide }) end
				end
				case.participants[index] = participant
				playerStored[index] = stringReceipt(folder, string.format("Case%d_Player%d", caseIndex, index))
				playerStored[index].Value = Http:JSONEncode(participant)
				assert(services.CheckpointService.SetInspectionCheckpointForStudio(player, 2), "CP2 inspection setup failed")
				table.insert(case.setups, { kind = "InspectionCheckpoint", userId = player.UserId, checkpoint = 2,
					clock = services.EggRushService.GetDiagnostics().elapsed, seconds = os.clock() - caseStarted })
			end
			local function guard(index)
				return not cancelled and os.clock() < deadline and raceValid() and eligible(players[index])
					and players[index].Character == characters[index] and falls(players[index]) == beforeFalls[index]
			end
			local function park(index, point, control)
				local part = point.part
				if not PARKING_POCKETS[part.Name] then return end
				assert(part.Anchored and part.CanCollide and part.Size.X >= 14 and part.Size.Z >= 8
					and typeof(part:GetAttribute("ERTop")) == "Vector3" and part.CFrame.UpVector:Dot(Vector3.yAxis) > .9999,
					"Parking requires an authored wide fixed pocket")
				local ancestor = part
				while ancestor and ancestor ~= course do
					assert(ancestor:GetAttribute("ERMechanism") == nil, "Parking cannot move within a mechanism")
					ancestor = ancestor.Parent
				end
				local root = roots[index]
				local humanoid = characters[index]:FindFirstChildOfClass("Humanoid")
				local initial, began = root.Position, os.clock()
				local target = part.CFrame:PointToWorldSpace(Vector3.new(if index == 1 then -3 else 3, part.Size.Y / 2, 0))
				local receipt = { part = part:GetFullName(), startPosition = vector(initial), target = vector(target),
					startClock = services.EggRushService.GetDiagnostics().elapsed, method = "Ordinary sideways walking on this fixed pocket" }
				table.insert(case.participants[index].parking, receipt)
				local function supported()
					assert(guard(index), "Parking participant changed or deadline reached")
					local support = control.Standing()
					local localPosition = part.CFrame:PointToObjectSpace(root.Position)
					receipt.support = support and support:GetFullName()
					receipt.floor = tostring(humanoid.FloorMaterial)
					assert(support == part and humanoid.FloorMaterial ~= Enum.Material.Air, "Parking lost actual fixed-pocket support")
					assert(math.abs(localPosition.X) <= part.Size.X / 2 - .6 and math.abs(localPosition.Z) <= part.Size.Z / 2 - .6,
						"Parking left the fixed pocket's safe footprint")
				end
				repeat
					supported()
					local delta = target - root.Position
					local flat = Vector3.new(delta.X, 0, delta.Z)
					if flat.Magnitude <= .2 then break end
					assert(os.clock() - began < .8, "Sideways parking did not reach its fixed-pocket position")
					control.SetMovement(flat.Unit)
					RunService.Heartbeat:Wait()
				until false
				control.SetMovement(Vector3.zero)
				RunService.Heartbeat:Wait(); supported()
				receipt.seconds, receipt.endPosition = os.clock() - began, vector(root.Position)
				receipt.displacement, receipt.endClock = vector(root.Position - initial), services.EggRushService.GetDiagnostics().elapsed
				persistCase()
			end
			local mechanisms = {}
			if definition.section == "Incubator" then mechanisms = { course.Obstacles.Mechanisms.SidewaysTray }
			else for i = 1, 4 do table.insert(mechanisms, course.Obstacles.Mechanisms["ShellLip" .. i]) end end
			local lastStates = {}
			local function observe()
				for _, model in ipairs(mechanisms) do
					local state = model:GetAttribute("ERState")
					if state == lastStates[model] then continue end
					lastStates[model] = state
					local warning = assert(model.Warning.Value, "Missing actual warning lamp")
					local color = warning.Color
					table.insert(case.warnings, { model = model.Name, state = state, clock = services.EggRushService.GetDiagnostics().elapsed,
						seconds = os.clock() - caseStarted, warningPart = warning:GetFullName(), transparency = warning.Transparency,
						color = { color.R, color.G, color.B }, positions = { vector(roots[1].Position), vector(roots[2].Position) } })
				end
			end
			observe(); observer = RunService.Heartbeat:Connect(observe)
			local launchTime
			for index, player in ipairs(players) do
				task.spawn(function()
					local participant = case.participants[index]
					local childOk, childFailure = xpcall(function()
						assert(guard(index), "Participant no longer eligible before start")
						assert((characters[index]:GetAttribute("RecoveryUntil") or 0) <= workspace:GetServerTimeNow(), "Start remains recovery-immune")
						local points = traversal.Points(course, "Normal", participant.section)
						local part = points[1].part
						local humanoid = characters[index]:FindFirstChildOfClass("Humanoid")
						local initial = part.Position + part.CFrame.UpVector * part.Size.Y / 2 + Vector3.new(0, humanoid.HipHeight + roots[index].Size.Y / 2 + .15, 0)
						participant.started = os.clock() - caseStarted
						participant.startClock = services.EggRushService.GetDiagnostics().elapsed
						table.insert(case.setups, { kind = "NativeTraversalInitialPlacement", userId = player.UserId, part = part:GetFullName(),
							position = vector(initial), clock = participant.startClock, seconds = participant.started })
						persistCase()
						participant.traversal = traversal.Run(course, player, points, { placeAtStart = true, guard = function() return guard(index) end,
							afterLanding = function(_, point, _, control)
								assert(guard(index), "Participant changed or deadline reached after landing")
								park(index, point, control)
							end }, function(stepIndex)
							if stepIndex ~= 1 then return end
							while index == 2 and (not launchTime or os.clock() - launchTime < definition.delay) do
								assert(guard(index), "Follower release cancelled or participant changed")
								RunService.Heartbeat:Wait()
							end
							assert(guard(index), "Participant changed before first movement")
							if index == 1 then launchTime = os.clock() else participant.actualFollowerDelay = os.clock() - launchTime end
							participant.released = os.clock() - caseStarted
							participant.releaseClock = services.EggRushService.GetDiagnostics().elapsed
							persistCase()
						end)
						assert(participant.traversal.ok, participant.traversal.failure)
						assert(falls(player) == beforeFalls[index], "Participant recovered during section")
						local expected = if definition.section == "Incubator" then 3 else 2
						assert(services.CheckpointService.GetLatestCheckpointIndex(player) == expected, "Wrong actual final checkpoint")
						if definition.section == "Incubator" then
							local carries = participant.traversal.trayCarries
							assert(#carries == 1 and carries[1].supportedThroughout and math.abs(carries[1].expectedDistance - 21) < .01, "Full supported21stud carry missing")
						end
					end, debug.traceback)
					participant.ok, participant.failure = childOk, if childOk then nil else childFailure
					participant.finished = os.clock() - caseStarted
					participant.additionalFalls = falls(player) - beforeFalls[index]
					participant.latestCheckpoint = services.CheckpointService.GetLatestCheckpointIndex(player)
					playerStored[index].Value = Http:JSONEncode(participant)
					done[index] = true; persistCase()
				end)
			end
			while not (done[1] and done[2]) and os.clock() < deadline do RunService.Heartbeat:Wait() end
			if not (done[1] and done[2]) then
				cancelled = true; case.timedOut = true
				local cleanupDeadline = os.clock() + 3
				while not (done[1] and done[2]) and os.clock() < cleanupDeadline do RunService.Heartbeat:Wait() end
			end
			observer:Disconnect(); observer = nil
			case.seconds = os.clock() - caseStarted
			case.ok = done[1] and done[2] and not case.timedOut
			for index, participant in ipairs(case.participants) do
				participant.additionalFalls = falls(players[index]) - beforeFalls[index]
				case.ok = case.ok and participant.ok == true and participant.additionalFalls == 0
				playerStored[index].Value = Http:JSONEncode(participant)
			end
			persistCase()
			assert(done[1] and done[2], "Traversal did not cooperatively stop; stop this native test before another run")
		end
		report.ok = true
		for _, case in ipairs(report.cases) do if not case.ok then report.ok = false end end
	end, debug.traceback)
	if observer then observer:Disconnect() end
	if not ok then report.ok = false; report.failure = failure end
	report.seconds, report.receiptPath, report.requiresFreshPrepare = os.clock() - started, folder:GetFullName(), true
	stored.Value = Http:JSONEncode(report)
	folder:SetAttribute("State", if report.ok then "Complete" else "Failed")
	busy = false
	return report
end
return Check
