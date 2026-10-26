assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(), "Actual Studio client required")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local player = Players.LocalPlayer
local candidate = assert(workspace:FindFirstChild("KeyboardCircuit_P2_C01"))
local Probe = assert(shared.KCP2TraversalProbe, "Install TraversalProbe.client.luau first")
local Fixture = {records = {}, active = false}
local ray = RaycastParams.new()
ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {candidate}, true
local function parts()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	assert(root and root:IsA("BasePart") and humanoid and humanoid.Health > 0 and not root.Anchored
		and player:GetAttribute("OnboardingReady") ~= false, "Unlocked living test avatar required")
	return character, root, humanoid
end
local function read()
	local encoded = candidate:GetAttribute("KCPhase2ServerDiagnostics")
	local ok, diagnostic = pcall(function() return Http:JSONDecode(encoded) end)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hit = root and workspace:Raycast(root.Position, Vector3.new(0, -7, 0), ray)
	return {
		at = workspace:GetServerTimeNow(), candidate = player:GetAttribute("KCPhase2Candidate"),
		lap = player:GetAttribute("KCPhase2Lap"), completedLaps = player:GetAttribute("KCPhase2CompletedLaps"),
		nextGate = player:GetAttribute("KCPhase2NextGate"), finished = player:GetAttribute("KCPhase2Finished"),
		recoveries = player:GetAttribute("KCPhase2Recoveries"), runId = candidate:GetAttribute("KCPhase2RunId"),
		server = if ok then diagnostic.participants[tostring(player.UserId)] else nil,
		realServer = ok and diagnostic.realServer, sessionActive = ok and diagnostic.active, support = hit and hit.Instance:GetFullName(),
		anchored = root and root.Anchored, alive = humanoid ~= nil and humanoid.Health > 0,
	}
end
local function await(predicate, seconds)
	local deadline = os.clock() + seconds
	repeat if predicate() then return true end; RunService.Heartbeat:Wait() until os.clock() >= deadline
	return predicate()
end
local function unchanged(before, after)
	return before.lap == after.lap and before.completedLaps == after.completedLaps
		and before.nextGate == after.nextGate and before.finished == after.finished
end
local function feedback()
	for _, folder in player.PlayerGui:GetChildren() do
		local identity = folder:FindFirstChild("Candidate")
		local diagnostic = folder:FindFirstChild("Diagnostics")
		if folder.Name == "KeyboardCircuitAudition" and identity and identity:IsA("ObjectValue")
			and identity.Value == candidate and diagnostic and diagnostic:IsA("BindableFunction") then
			return diagnostic:Invoke()
		end
	end
	return nil
end
local function start(name, callback)
	assert(not Fixture.active, "Finish this helper's current case before starting another")
	local record = {case = name, active = true, beganAt = workspace:GetServerTimeNow()}
	table.insert(Fixture.records, record)
	Fixture.active = true
	task.spawn(function()
		local ok, err = xpcall(function() callback(record) end, debug.traceback)
		record.error = if ok then nil else tostring(err)
		if not ok then record.passed = false end
		record.active, Fixture.active = false, false
		record.finishedAt = workspace:GetServerTimeNow()
	end)
	return {started = true, case = name, boundary = "Native result is pending in shared.KCP2LifecycleClient.records"}
end
local function walkGate(id, direction)
	parts()
	local gate = assert(candidate.Gates:FindFirstChild(id))
	local bank = assert(candidate.CheckpointBays:FindFirstChild(id))
	local contact = assert(bank:FindFirstChild("BankContact"), "Preserved bank contact required")
	local before = read()
	local side = if direction == "reverse" then -1 else 1
	local approach = gate.CFrame:PointToWorldSpace(Vector3.new(0, 0, 8 * side))
	local exit = gate.CFrame:PointToWorldSpace(Vector3.new(0, 0, -8 * side))
	Probe.Place(contact, approach)
	local approached = Probe.Move(id .. " gate approach", approach, false, contact, 3, .65)
	local staged = read()
	assert(unchanged(before, staged), "Gate setup unexpectedly changed progress")
	local crossed = approached and Probe.Move(id .. " " .. direction .. " crossing", exit, false, contact, 3, .65)
	task.wait(.3)
	return {gate = id, direction = direction, approached = approached, crossed = crossed, before = before, after = read()}
end
function Fixture.PrepareArrival()
	local remote = assert(game.ReplicatedStorage.Remotes:FindFirstChild("StudioDevControl"))
	return remote:InvokeServer({action = "OnboardingPreset", preset = "Returning avatar"})
end
function Fixture.Read() return read() end
function Fixture.NegativeGates()
	return start("wrong-reverse-teleport-gates", function(record)
		assert(read().nextGate == "CP1" and read().completedLaps == 0, "Fresh actual Begin required")
		record.cases = {}
		for _, specification in {{"CP2", "forward"}, {"CP1", "reverse"}} do
			local result = walkGate(specification[1], specification[2])
			result.passed = result.crossed and unchanged(result.before, result.after)
			table.insert(record.cases, result)
		end
		local gate, contact = candidate.Gates.CP1, candidate.CheckpointBays.CP1.BankContact
		local from = gate.CFrame:PointToWorldSpace(Vector3.new(-10, 0, 10))
		local to = gate.CFrame:PointToWorldSpace(Vector3.new(10, 0, -10))
		Probe.Place(contact, from)
		assert(Probe.Move("CP1 teleport rejection approach", from, false, contact, 3, .65), "Supported teleport setup required")
		local before = read()
		local character, root = parts()
		local target = Vector3.new(to.X, root.Position.Y, to.Z)
		local distance = (target - root.Position).Magnitude
		assert(distance > 24, "Teleport must exceed ForwardGate's maximum travel cap")
		character:PivotTo(CFrame.lookAt(target, target + gate.CFrame.LookVector))
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		task.wait(.5)
		local after = read()
		table.insert(record.cases, {gate = "CP1", direction = "teleport", distance = distance, before = before, after = after,
			passed = unchanged(before, after) and after.support == contact:GetFullName()})
		record.passed = true
		for _, result in record.cases do if not result.passed then record.passed = false end end
		record.boundary = "Gate-local staged setup; real walks for wrong/reverse crossings and one deliberate >24-stud jump for teleport rejection"
	end)
end
function Fixture.ThreeLaps()
	return start("three-ordered-gate-laps", function(record)
		assert(read().nextGate == "CP1" and read().lap == 1 and read().completedLaps == 0, "Fresh actual Begin required")
		record.gates, record.passed = {}, true
		local deadline = os.clock() + 90
		for lap = 1, 3 do
			for _, id in {"CP1", "CP2", "CP3", "F01", "F00"} do
				assert(os.clock() < deadline, "Three-lap fixture exceeded its 90-second bound")
				local result = walkGate(id, "forward")
				local expected = ({CP1 = "CP2", CP2 = "CP3", CP3 = "F01", F01 = "F00", F00 = "CP1"})[id]
				result.passed = result.crossed and await(function()
					local current = read()
					return if id == "F00" and lap == 3 then current.finished == true and current.completedLaps == 3
						else current.nextGate == expected and current.completedLaps == (if id == "F00" then lap else lap - 1)
				end, 1.5)
				result.after = read()
				table.insert(record.gates, result)
				if not result.passed then record.passed = false; return end
			end
		end
		record.final = read()
		record.boundary = "Fifteen real avatar gate crossings with staged positioning between bays; proves ordered lap state, not continuous course traversal or race duration"
	end)
end
function Fixture.RespawnSession(expectStopped)
	return start("respawn-" .. (if expectStopped then "stopped" else "active-session"), function(record)
		parts()
		assert(await(function() local current = read(); return current.server and current.server.nextGate == current.nextGate end, 1.5), "Current authoritative checkpoint required")
		record.before = read()
		assert(record.before.sessionActive == not expectStopped, "Stop or restart the actual Session before this case")
		local originalCharacter = player.Character
		local recovery = candidate.RecoveryPads:FindFirstChild(record.before.server.recoveryGate)
		assert(recovery, "Retained recovery bank required")
		task.spawn(function()
			local ok, response = pcall(function() return game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action = "Respawn"}) end)
			record.respawnResponse = if ok then response else {error = tostring(response)}
		end)
		local changed = await(function() return player.Character ~= nil and player.Character ~= originalCharacter and read().alive end, 12)
		if changed and not expectStopped then
			record.recovered = await(function()
				local current = read()
				local character = player.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				local hit = root and workspace:Raycast(root.Position, Vector3.new(0, -7, 0), ray)
				return current.candidate == candidate.Name and current.recoveries > record.before.recoveries
					and hit and (hit.Instance == recovery or hit.Instance:IsDescendantOf(recovery))
			end, 2)
		else task.wait(.8) end
		record.after, record.characterChanged = read(), changed
		record.passed = changed and unchanged(record.before, record.after)
			and (if expectStopped then record.after.candidate == nil and record.after.recoveries == record.before.recoveries and feedback() == nil else record.recovered == true)
		record.boundary = "Existing StudioDevControl respawn and actual Session recovery; stopped respawn must retain checkpoint without restoring candidate opt-in"
	end)
end
function Fixture.CrossExpected()
	local id = read().nextGate
	return start("one-expected-gate", function(record)
		record.result = walkGate(id, "forward")
		record.passed = record.result.crossed and not unchanged(record.result.before, record.result.after)
	end)
end
function Fixture.FallRecovery()
	return start("fall-to-current-checkpoint", function(record)
		assert(await(function() local current = read(); return current.server and current.server.nextGate == current.nextGate end, 1.5), "Current server checkpoint snapshot required")
		record.before = read()
		local id = record.before.server.recoveryGate
		local bank = assert(candidate.RecoveryPads:FindFirstChild(id))
		task.wait(.8)
		local character, root = parts()
		local origin = candidate:GetAttribute("Origin")
		character:PivotTo(CFrame.new(root.Position.X, origin.Y - 20, root.Position.Z))
		root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		record.passed = await(function()
			local current = read()
			local _, currentRoot = parts()
			local hit = workspace:Raycast(currentRoot.Position, Vector3.new(0, -7, 0), ray)
			return current.recoveries > record.before.recoveries and hit and (hit.Instance == bank or hit.Instance:IsDescendantOf(bank))
		end, 3)
		record.after, record.expectedRecovery = read(), id
		record.passed = record.passed and unchanged(record.before, record.after)
	end)
end
function Fixture.Readiness(respawnDuringLoading)
	return start("readiness" .. (if respawnDuringLoading then "-with-respawn" else ""), function(record)
		local originalCharacter = player.Character
		record.samples, record.loadingSamples = {}, 0
		local deadline = os.clock() + 16
		repeat
			local diagnostic = feedback()
			local readiness = diagnostic and diagnostic.readiness
			if readiness and readiness.state == "loading" then
				record.loadingSamples += 1
				if respawnDuringLoading and not record.respawnRequested then
					record.respawnRequested = true
					task.spawn(function()
						local ok, response = pcall(function() return game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action = "Respawn"}) end)
						record.respawnResponse = if ok then response else {error = tostring(response)}
					end)
				end
			end
			record.characterChanged = player.Character ~= originalCharacter
			if #record.samples < 128 then table.insert(record.samples, {state = read(), readiness = readiness, totals = diagnostic and diagnostic.totals}) end
			if readiness and (readiness.state == "ready" or readiness.state == "degraded")
				and (not respawnDuringLoading or record.respawnRequested and record.characterChanged) then record.resolved = readiness; break end
			task.wait(.05)
		until os.clock() >= deadline
		record.after = read()
		if respawnDuringLoading and not record.respawnRequested then
			record.status, record.reason = "unverified", "Actual loading window not observed; warm-cache readiness cannot prove loading respawn"
		else record.passed = record.resolved ~= nil and (not respawnDuringLoading or record.characterChanged) end
		record.boundary = "Actual candidate readiness/respawn observation; loaded clips, IsPlaying and human listening remain separate"
	end)
end
shared.KCP2LifecycleClient = Fixture
return {installed = true, functions = {"PrepareArrival", "Read", "NegativeGates", "ThreeLaps", "CrossExpected", "FallRecovery", "RespawnSession", "Readiness"},
	boundary = "Prepared client helper; installing functions runs no case and claims no native pass"}
