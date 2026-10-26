assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient())
local player = game.Players.LocalPlayer
local candidate = workspace.KeyboardCircuit_P2_C01
local Probe = assert(shared.KCP2TraversalProbe)
local Fixture = {records = {}, active = false}
local function feedback()
	for _, folder in player.PlayerGui:GetChildren() do
		local identity, diagnostic = folder:FindFirstChild("Candidate"), folder:FindFirstChild("Diagnostics")
		if identity and identity:IsA("ObjectValue") and identity.Value == candidate and diagnostic then return diagnostic:Invoke() end
	end
end
local function waitFor(predicate, seconds)
	local began = os.clock()
	repeat if predicate() then return true, os.clock() - began end; task.wait(.03) until os.clock() - began > seconds
	return false, os.clock() - began
end
local function mechanism(id)
	for _, item in candidate.Districts:GetDescendants() do
		if item:IsA("Model") and item:GetAttribute("MechanismId") == id then return item end
	end
	error("Missing mechanism " .. id)
end
local function start(name, callback)
	assert(not Fixture.active)
	local record = {case = name, userId = player.UserId, active = true}
	table.insert(Fixture.records, record)
	Fixture.active = true
	task.spawn(function()
		local ok, err = xpcall(function() callback(record) end, debug.traceback)
		record.error = if ok then nil else tostring(err)
		if not ok then record.passed = false end
		record.active, Fixture.active = false, false
	end)
	return {started = true, case = name, userId = player.UserId}
end
function Fixture.Read() return {userId = player.UserId, feedback = feedback(), progress = shared.KCP2LifecycleClient.Read()} end
function Fixture.ArmFallaway(delay)
	return start("two-client-fallaway-follower", function(record)
		local unit = mechanism("H03")
		local entry = unit.EntryBank.BankContact
		record.setup = Probe.Place(entry, entry.Position + entry.CFrame.LookVector * (if delay == 0 then -3 else 3))
		record.ready = true
		assert(waitFor(function() return candidate:GetAttribute("KCP2FixtureFallawayStart") ~= nil end, 30), "Coordinator did not start")
		local at = candidate:GetAttribute("KCP2FixtureFallawayStart") + delay
		assert(waitFor(function() return workspace:GetServerTimeNow() >= at end, 4))
		record.delay, record.departedAt = delay, workspace:GetServerTimeNow()
		record.admission = unit.Lane1Row1:GetAttribute("AdmissionOpen")
		record.beforeRecoveries = player:GetAttribute("KCPhase2Recoveries")
		local previous = entry
		record.steps = {}
		for _, bank in {unit.Lane1Row1, unit.Lane1Row2, unit.Lane1Row3, unit.ExitBank} do
			local target = bank.BankContact
			local passed = Probe.Cross("H03 follower " .. bank.Name, previous, target)
			table.insert(record.steps, {bank = bank.Name, passed = passed, at = workspace:GetServerTimeNow()})
			assert(passed, "Fallaway follower failed " .. bank.Name)
			previous = target
		end
		record.finishedAt, record.afterRecoveries = workspace:GetServerTimeNow(), player:GetAttribute("KCPhase2Recoveries")
		record.passed = record.admission == true and record.afterRecoveries == record.beforeRecoveries
		record.boundary = "Two actual avatars use the same fallaway lane, with a deliberate delayed follower. Staged entry only; continuous ordinary jumps through all rows and exit."
	end)
end
function Fixture.ArmShuttle(delay, side, expectReset)
	return start(if expectReset then "two-client-moving-shuttle-restart" else "two-client-shuttle", function(record)
		local unit = mechanism("H06")
		local entry, ride, exit = unit.EntryBank.BankContact, unit.RideableBank.BankContact, unit.ExitBank.BankContact
		record.setup = Probe.Place(entry, entry.Position + entry.CFrame.LookVector * side)
		record.ready = true
		assert(waitFor(function() return candidate:GetAttribute("KCP2FixtureShuttleStart") ~= nil end, 30))
		local at = candidate:GetAttribute("KCP2FixtureShuttleStart") + delay
		assert(waitFor(function() return workspace:GetServerTimeNow() >= at end, 4))
		record.delay, record.departedAt = delay, workspace:GetServerTimeNow()
		record.boardingWindow = unit:GetAttribute("BoardingWindow")
		record.beforeRecoveries = player:GetAttribute("KCPhase2Recoveries")
		record.beforeRun = candidate:GetAttribute("KCPhase2RunId")
		record.beforeRecoveryGate = shared.KCP2LifecycleClient.Read().server.recoveryGate
		local function cross(label, from, to)
			local direction = Vector3.new(to.Position.X - from.Position.X, 0, to.Position.Z - from.Position.Z).Unit
			local lateral = entry.CFrame.LookVector * side
			return Probe.Move(label .. " takeoff", Probe.Edge(from, direction, .9) + lateral, false, from, 4, .5)
				and Probe.Move(label .. " jump", Probe.Edge(to, -direction, .9) + lateral, true, to, 3, .8)
				and Probe.Move(label .. " settle", to.Position + lateral, false, to, 4, .7)
		end
		record.boarded = cross("H06 pair board", entry, ride)
		assert(record.boarded, "Two-client boarding failed")
		local root = player.Character.HumanoidRootPart
		local began, sampled, first = os.clock(), 0, root.Position
		record.samples = {}
		while not unit:GetAttribute("ExitWindow") and os.clock() - began < 12 do
			if expectReset and candidate:GetAttribute("KCPhase2RunId") ~= record.beforeRun then record.resetSeen = true; break end
			if os.clock() - sampled >= .1 then
				sampled = os.clock()
				local relative = ride.CFrame:PointToObjectSpace(root.Position)
				table.insert(record.samples, {at = workspace:GetServerTimeNow(), state = unit:GetAttribute("CycleState"), travel = unit.Slider.CurrentPosition,
					root = {root.Position.X, root.Position.Y, root.Position.Z}, relative = {relative.X, relative.Y, relative.Z}})
			end
			task.wait(.03)
		end
		record.carriedDistance = (root.Position - first).Magnitude
		if expectReset then
			task.wait(.4)
			record.after = shared.KCP2LifecycleClient.Read()
			local pad = candidate.RecoveryPads[record.beforeRecoveryGate].BankContact
			record.passed = record.resetSeen == true and record.after.support == pad:GetFullName()
				and record.after.recoveries > record.beforeRecoveries and record.after.server.recoveryGate == record.beforeRecoveryGate
				and record.after.runId == record.beforeRun + 1
			record.boundary = "Two avatars genuinely board and are carried before an actual server Restart. No client positioning after boarding; checkpoint recovery and restarted feedback are observed."
			return
		end
		record.exitWindow = unit:GetAttribute("ExitWindow")
		record.exited = record.exitWindow and cross("H06 pair exit", ride, exit)
		record.finishedAt, record.afterRecoveries = workspace:GetServerTimeNow(), player:GetAttribute("KCPhase2Recoveries")
		record.passed = record.boardingWindow == true and record.boarded and record.exited and record.carriedDistance > 20 and record.afterRecoveries == record.beforeRecoveries
		record.boundary = "Two actual clients board the same physical shuttle with separated standing positions and a delayed follower; no teleport during carrying or exit."
	end)
end
shared.KCP2MultiplayerProbe = Fixture
return {installed = true, functions = {"Read", "ArmFallaway", "ArmShuttle"}}
