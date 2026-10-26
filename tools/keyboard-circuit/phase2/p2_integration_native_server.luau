assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsServer(), "Actual Studio server required")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local candidate = assert(Workspace:FindFirstChild("KeyboardCircuit_P2_C01"), "Installed P2 candidate required")
local controls = assert(candidate:FindFirstChild("StudioProbeControls"), "Running snapshot Session required")
local Fixture = {records = {}}
local ray = RaycastParams.new()
ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {candidate}, true
local function player(userId) return assert(Players:GetPlayerByUserId(userId), "Current test player required") end
local function parts(owner)
	local character = owner.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	assert(root and root:IsA("BasePart") and humanoid, "Character root and Humanoid required")
	return character, root, humanoid
end
local function support(root)
	local hit = Workspace:Raycast(root.Position, Vector3.new(0, -7, 0), ray)
	return hit and hit.Instance
end
local function position(value) return {value.X, value.Y, value.Z} end
local function state() return controls.State:Invoke() end
local function read(owner)
	local _, root, humanoid = parts(owner)
	local hit = support(root)
	local current = state()
	return {
		at = Workspace:GetServerTimeNow(), realServer = current.realServer, active = current.active,
		runId = candidate:GetAttribute("KCPhase2RunId"), progress = current.participants[tostring(owner.UserId)],
		candidate = owner:GetAttribute("KCPhase2Candidate"), onboardingReady = owner:GetAttribute("OnboardingReady"),
		anchored = root.Anchored, health = humanoid.Health, root = position(root.Position),
		support = hit and hit:GetFullName(), recoveries = #current.recoveries, gates = #current.gates,
		runtime = current.runtime,
	}
end
local function save(record) table.insert(Fixture.records, record); return record end
local function await(predicate, seconds)
	local deadline = os.clock() + seconds
	repeat if predicate() then return true end; task.wait(.03) until os.clock() >= deadline
	return predicate()
end
local function action(name, owner)
	local signal = assert(controls:FindFirstChild(name), "Candidate control " .. name)
	signal:Fire(owner and owner.UserId)
end
function Fixture.Read(userId) return read(player(userId)) end
function Fixture.Action(name, userId)
	assert(table.find({"Begin", "Leave", "Stop", "Restart"}, name), "Known Session action required")
	action(name, userId and player(userId))
	return {requested = name, boundary = "Actual candidate Bindable; caller must inspect its resulting State"}
end
function Fixture.BeginPair(first, second)
	assert(first ~= second, "Two distinct clients required")
	for _, id in {first, second} do
		local owner = player(id)
		local _, root, humanoid = parts(owner)
		assert(not root.Anchored and humanoid.Health > 0 and owner:GetAttribute("OnboardingReady") ~= false, "Both clients must be ready and unlocked")
	end
	action("Begin", player(first)); action("Begin", player(second))
	return save({case = "simultaneous-start-request", clients = {first, second}, requiresTwoClients = true,
		boundary = "Two actual Begin requests without a deliberate wait; readiness must be sampled separately on each client"})
end
function Fixture.FreshBegin(userId)
	local owner = player(userId)
	local _, root = parts(owner)
	local hit = support(root)
	assert(hit and hit:IsDescendantOf(candidate.RecoveryPads), "Stage on an off-route recovery bank before Leave/Begin")
	local before = read(owner)
	action("Leave", owner)
	assert(await(function() return state().participants[tostring(userId)] == nil end, 1), "Leave did not clear participant")
	local left = read(owner)
	action("Begin", owner)
	local applied = await(function()
		local current = state().participants[tostring(userId)]
		return current and current.active and current.lap == 1 and current.completedLaps == 0 and current.nextGate == "CP1" and current.recoveryGate == "F00"
	end, 1.5)
	return save({case = "fresh-begin-after-leave", passed = applied and left.progress == nil and left.candidate == nil, before = before, left = left, after = read(owner)})
end
function Fixture.LockedBegin(userId, kind)
	assert(kind == "Anchor" or kind == "Readiness", "Use Anchor or Readiness")
	local owner = player(userId)
	local _, root, humanoid = parts(owner)
	assert(not root.Anchored and humanoid.Health > 0 and owner:GetAttribute("OnboardingReady") ~= false, "Run after existing arrival has released its own lock")
	local hit = support(root)
	assert(hit and hit:IsDescendantOf(candidate.RecoveryPads), "Use an off-route recovery bank to avoid automatic F00 enrollment")
	action("Leave", owner)
	assert(await(function() return state().participants[tostring(userId)] == nil end, 1), "Leave unavailable")
	local before = read(owner)
	local original = if kind == "Anchor" then root.Anchored else owner:GetAttribute("OnboardingReady")
	if kind == "Anchor" then root.Anchored = true else owner:SetAttribute("OnboardingReady", false) end
	local record = {case = "foreign-lock-rejection", lock = kind, before = before, boundary = "Temporary test-owned per-avatar lock only; no arrival service or control changes"}
	local ok, err = pcall(function()
		action("Begin", owner)
		task.wait(.2)
		record.after = read(owner)
		record.passed = record.after.progress == nil and record.after.candidate == before.candidate
			and (if kind == "Anchor" then root.Anchored else owner:GetAttribute("OnboardingReady") == false)
			and (root.Position - Vector3.new(table.unpack(before.root))).Magnitude < .25
	end)
	if kind == "Anchor" then
		if root.Parent and root.Anchored == true then root.Anchored = original end
	elseif owner:GetAttribute("OnboardingReady") == false then owner:SetAttribute("OnboardingReady", original) end
	if not ok then record.passed = false end
	record.restored, record.error = true, if ok then nil else tostring(err)
	return save(record)
end
function Fixture.LockedRestart(userId, kind)
	assert(kind == "Anchor" or kind == "Readiness", "Use Anchor or Readiness")
	local owner = player(userId)
	local _, root, humanoid = parts(owner)
	local before = read(owner)
	assert(before.progress and before.progress.active and humanoid.Health > 0 and not root.Anchored
		and owner:GetAttribute("OnboardingReady") ~= false, "Unlocked living active participant required")
	local hit = support(root)
	assert(hit and hit:IsDescendantOf(candidate.RecoveryPads), "Use a permanent recovery bank for the lock rejection case")
	local original = if kind == "Anchor" then root.Anchored else owner:GetAttribute("OnboardingReady")
	local resets, runs = 0, 0
	local connections = {candidate:GetAttributeChangedSignal("KCPhase2RunId"):Connect(function() runs += 1 end)}
	for _, item in candidate.Districts:GetDescendants() do
		if item:IsA("Model") and item:GetAttribute("MechanismId") then
			table.insert(connections, item:GetAttributeChangedSignal("CycleState"):Connect(function()
				if item:GetAttribute("CycleState") == "Stopped" then resets += 1 end
			end))
		end
	end
	if kind == "Anchor" then root.Anchored = true else owner:SetAttribute("OnboardingReady", false) end
	local record = {case = "locked-restart-rejection", lock = kind, before = before}
	local ok, err = pcall(function()
		action("Restart", owner)
		task.wait(.25)
		record.after = read(owner)
		record.passed = record.after.active == before.active and record.after.runId == before.runId
			and record.after.candidate == before.candidate and record.after.progress.generation == before.progress.generation
			and record.after.progress.recoveries == before.progress.recoveries and resets == 0 and runs == 0
			and record.after.runtime.active == before.runtime.active and record.after.runtime.frames >= before.runtime.frames
			and record.after.runtime.elapsed >= before.runtime.elapsed
			and (if kind == "Anchor" then root.Anchored else owner:GetAttribute("OnboardingReady") == false)
	end)
	for _, connection in connections do connection:Disconnect() end
	if kind == "Anchor" then
		if root.Parent and root.Anchored == true then root.Anchored = original end
	elseif owner:GetAttribute("OnboardingReady") == false then owner:SetAttribute("OnboardingReady", original) end
	if not ok then record.passed = false end
	record.restored, record.error, record.resetEvents, record.runEvents = true, if ok then nil else tostring(err), resets, runs
		record.boundary = "Temporary per-avatar lock; runtime may advance naturally, but no reset, recovery, run ID or preview selection change is allowed"
	return save(record)
end
local function mechanism(id)
	assert(id == "H05" or id == "H06", "Use H05 or H06")
	for _, item in candidate.Districts:GetDescendants() do
		if item:IsA("Model") and item:GetAttribute("MechanismId") == id then return item end
	end
	error("Mechanism not found: " .. id)
end
local function transition(name, userId, id, requireRide)
	local owner, unit = player(userId), mechanism(id)
	local _, root, humanoid = parts(owner)
	local current = state().participants[tostring(userId)]
	assert(current and current.active and humanoid.Health > 0 and not root.Anchored and owner:GetAttribute("OnboardingReady") ~= false, "Unlocked active participant required")
	local recovery = candidate.RecoveryPads:FindFirstChild(current.recoveryGate)
	assert(recovery, "Current recovery bank required")
	local function onPad()
		local hit = support(root)
		return hit ~= nil and (hit == recovery or hit:IsDescendantOf(recovery))
	end
	local hit = support(root)
	if requireRide then
		assert(state().active and hit and hit:IsDescendantOf(unit.RideableBank), "Actually board the live mechanism before this transition")
		assert(current.recoveryGate == unit:GetAttribute("RecoveryCheckpoint"), "Reach the mechanism's preceding checkpoint first")
	else assert(onPad(), "Stopped participant must remain on its recovery bank") end
	local record = {case = "mechanism-" .. name, id = id, before = read(owner), observations = {}, resetSeen = false}
	local connections = {}
	local function observe(kind)
		if #record.observations >= 64 then return end
		table.insert(record.observations, {kind = kind, at = Workspace:GetServerTimeNow(), onRecoveryPad = onPad(), root = position(root.Position), cycle = unit:GetAttribute("CycleState"), runId = candidate:GetAttribute("KCPhase2RunId")})
	end
	table.insert(connections, unit:GetAttributeChangedSignal("CycleState"):Connect(function()
		if unit:GetAttribute("CycleState") == "Stopped" then record.resetSeen = true; observe("mechanism-stopped") end
	end))
	table.insert(connections, candidate:GetAttributeChangedSignal("KCPhase2RunId"):Connect(function() observe("run-id") end))
	local ok, err = pcall(function()
		action(name, owner)
		local applied = await(function()
			return if name == "Stop" then not state().active else candidate:GetAttribute("KCPhase2RunId") == record.before.runId + 1
		end, 2)
		task.wait(.2)
		record.after = read(owner)
		record.passed = applied and onPad() and record.after.progress.recoveryGate == current.recoveryGate
			and (if name == "Stop" then record.after.candidate == nil else record.after.candidate == candidate.Name)
		for _, observation in record.observations do
			if not observation.onRecoveryPad then record.passed = false end
		end
		if requireRide and not record.resetSeen then record.passed = false end
	end)
	for _, connection in connections do connection:Disconnect() end
	if not ok then record.passed = false end
	record.error = if ok then nil else tostring(err)
	return save(record)
end
function Fixture.OnRideTransition(userId, id, name)
	assert(name == "Stop" or name == "Restart", "Use Stop or Restart")
	return transition(name, userId, id, true)
end
function Fixture.RestartFromPad(userId, id) return transition("Restart", userId, id, false) end
shared.KCP2LifecycleServer = Fixture
return {installed = true, functions = {"Read", "Action", "BeginPair", "FreshBegin", "LockedBegin", "LockedRestart", "OnRideTransition", "RestartFromPad"},
	boundary = "Prepared native test helper; installing functions runs no case and claims no native pass"}
