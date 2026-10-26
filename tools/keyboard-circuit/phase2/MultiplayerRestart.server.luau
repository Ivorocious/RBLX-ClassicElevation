assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsServer())
local candidate = workspace.KeyboardCircuit_P2_C01
local ids = {-1, -2}
local unit
for _, item in candidate.Districts:GetDescendants() do if item:IsA("Model") and item:GetAttribute("MechanismId") == "H06" then unit = item end end
assert(unit)
local ride = unit.RideableBank.BankContact
local ray = RaycastParams.new()
ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {ride}, true
local result = {active = true, ids = ids, observations = {}}
shared.KCP2MultiplayerRestart = result
local function supported(id)
	local player = assert(game.Players:GetPlayerByUserId(id))
	local root, humanoid = player.Character.HumanoidRootPart, player.Character.Humanoid
	local point = ride.CFrame:PointToObjectSpace(root.Position)
	return humanoid.FloorMaterial ~= Enum.Material.Air and math.abs(point.X) < ride.Size.X / 2 + .5 and math.abs(point.Z) < ride.Size.Z / 2 + .5
		and workspace:Raycast(root.Position, Vector3.new(0, -7, 0), ray) ~= nil
end
local function waitFor(predicate, seconds)
	local began = os.clock()
	repeat if predicate() then return true end; task.wait(.03) until os.clock() - began > seconds
	return false
end
task.spawn(function()
	local connections = {}
	local ok, err = xpcall(function()
		assert(waitFor(function() return not unit:GetAttribute("BoardingWindow") end, 15))
		assert(waitFor(function() return unit:GetAttribute("BoardingWindow") end, 15))
		candidate:SetAttribute("KCP2FixtureShuttleStart", workspace:GetServerTimeNow() + .15)
		assert(waitFor(function() return unit:GetAttribute("CycleState") == "Outbound" and unit.Slider.CurrentPosition > 1.5 and supported(-1) and supported(-2) end, 9), "Both avatars must genuinely ride the moving shuttle")
		result.before = {first = shared.KCP2LifecycleServer.Read(-1), second = shared.KCP2LifecycleServer.Read(-2), travel = unit.Slider.CurrentPosition, cycle = unit:GetAttribute("CycleState")}
		local function observe(kind)
			local row = {kind = kind, at = workspace:GetServerTimeNow(), cycle = unit:GetAttribute("CycleState"), players = {}}
			for _, id in ids do
				local state = shared.KCP2LifecycleServer.Read(id)
				local pad = candidate.RecoveryPads[state.progress.recoveryGate].BankContact
				table.insert(row.players, {id = id, root = state.root, onRecoveryPad = state.support == pad:GetFullName(), runId = state.runId})
			end
			table.insert(result.observations, row)
		end
		table.insert(connections, unit:GetAttributeChangedSignal("CycleState"):Connect(function() if unit:GetAttribute("CycleState") == "Stopped" then observe("mechanism-stopped") end end))
		table.insert(connections, candidate:GetAttributeChangedSignal("KCPhase2RunId"):Connect(function() observe("run-id") end))
		result.transition = shared.KCP2LifecycleServer.OnRideTransition(-1, "H06", "Restart")
		result.after = {first = shared.KCP2LifecycleServer.Read(-1), second = shared.KCP2LifecycleServer.Read(-2)}
		local firstRoot = game.Players:GetPlayerByUserId(-1).Character.HumanoidRootPart
		local secondRoot = game.Players:GetPlayerByUserId(-2).Character.HumanoidRootPart
		result.recoverySpacing = (firstRoot.Position - secondRoot.Position).Magnitude
		result.passed = result.transition.passed and result.recoverySpacing >= 4.5 and #result.observations >= 2
		for _, row in result.observations do for _, player in row.players do if not player.onRecoveryPad then result.passed = false end end end
		for _, name in {"first", "second"} do
			local before, after = result.before[name], result.after[name]
			if after.runId ~= before.runId + 1 or after.progress.recoveryGate ~= before.progress.recoveryGate
				or after.progress.nextGate ~= before.progress.nextGate or after.progress.lap ~= before.progress.lap then result.passed = false end
		end
	end, debug.traceback)
	for _, connection in connections do connection:Disconnect() end
	result.error = if ok then nil else tostring(err)
	if not ok then result.passed = false end
	result.active = false
	result.boundary = "Actual two-client moving-rider restart. Both recover before the mechanism reset and run-ID transition; recovery spacing and retained progress are native observations."
end)
return {scheduled = true, ids = ids}
