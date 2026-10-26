--!strict
local RunService, Players = game:GetService("RunService"), game:GetService("Players")
assert(RunService:IsStudio() and RunService:IsClient())
local player = Players.LocalPlayer
assert(player.UserId == -2, "Owned second test client required")
local candidate = assert(workspace:FindFirstChild("KeyboardCircuit_P2_C01"))
assert(candidate:GetAttribute("Phase2Only"))
local setup = assert(shared.KCP2TraversalProbe)
local Factory, Timing = assert(shared.KCP2I06EfficientTraversal), assert(shared.KCP2I06Timing)
local Motion = require(candidate.SourceSnapshot.Motion)
local domino = candidate.Districts.S04_ClickyRelay.H08_DominoKeyCascade
local departure = domino.ExitBank.BankContact
local connector = candidate.RouteLinks.H08_to_H01_1.BankContact
local arrival = candidate.Districts.S04_ClickyRelay.H01_ShiftWindows.EntryBank.BankContact
assert(not shared.KCP2I06Race.active and (not shared.KCP2GroundingJoin10 or not shared.KCP2GroundingJoin10.active))
local report = {active = true, passed = false, trials = {}, runId = candidate:GetAttribute("KCPhase2RunId"), iteration = candidate:GetAttribute("ConstructionIteration"),
	boundary = "Focused staged I05 connector tests using ordinary movement; no continuous lap or timing-target claim."}
shared.KCP2GroundingJoin10 = report
task.spawn(function()
	local driver
	local ok, failure = pcall(function()
		local values = Motion.Tuning("Domino")
		for key in values do local value = domino:GetAttribute("Timing_" .. key); if value ~= nil then values[key] = value end end
		for _, delay in {0, .2} do
			local trial = {delay = delay, at = workspace:GetServerTimeNow(), setupCalls = 0}
			table.insert(report.trials, trial)
			local began = os.clock()
			while not (domino.DominoPanel3:GetAttribute("AdmissionOpen") == true and Timing.Remaining("Domino", candidate:GetAttribute("KCElapsed"), 3, values) >= 2.8) do
				assert(os.clock() - began < 14, "Bounded clear-window wait")
				RunService.RenderStepped:Wait()
			end
			setup.Stop()
			setup.Place(departure)
			trial.setupCalls = 1
			if delay > 0 then task.wait(delay) end
			local recoveries = player:GetAttribute("KCPhase2Recoveries")
			local character = assert(player.Character)
			local humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
			local root = assert(character:FindFirstChild("HumanoidRootPart"))
			local function guard()
				assert(candidate.Parent and candidate:GetAttribute("KCPhase2RunId") == report.runId)
				assert(player.Character == character and humanoid.Health > 0 and not root.Anchored)
				assert(player:GetAttribute("KCPhase2Candidate") == candidate.Name and player:GetAttribute("KCPhase2Recoveries") == recoveries, "Authoritative recovery or participant change")
				assert(math.abs(humanoid.WalkSpeed - 16) < .001 and math.abs(humanoid.JumpHeight - 7.2) < .001 and not humanoid.UseJumpPower and math.abs(workspace.Gravity - 196.2) < .001)
			end
			driver = Factory.New(candidate, player, guard)
			trial.routeBeganAt, trial.routeBeganClock = workspace:GetServerTimeNow(), os.clock()
			assert(driver.Cross("Grounding10 connector", departure, connector))
			assert(driver.Cross("Grounding10 H01 arrival", connector, arrival))
			trial.elapsed, trial.passed, trial.recoveries = os.clock() - trial.routeBeganClock, true, player:GetAttribute("KCPhase2Recoveries") - recoveries
			trial.records = driver.Records()
			trial.cleanup = driver.Stop()
			assert(trial.cleanup.unbound and trial.cleanup.avatarCleared)
			driver = nil
		end
	end)
	if driver then
		local trial = report.trials[#report.trials]
		trial.records = driver.Records()
		local cleaned, cleanup = pcall(driver.Stop)
		trial.cleanup = if cleaned then cleanup else {error = tostring(cleanup)}
	end
	report.active, report.passed, report.error, report.finishedAt = false, ok, if ok then nil else tostring(failure), workspace:GetServerTimeNow()
end)
return {started = true, proof = report.boundary}
