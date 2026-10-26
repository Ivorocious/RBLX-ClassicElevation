--!strict
local Players, RunService = game:GetService("Players"), game:GetService("RunService")
local Lighting, Http = game:GetService("Lighting"), game:GetService("HttpService")
assert(RunService:IsStudio() and RunService:IsClient(), "Owned native Play only")
assert(not shared.KCP2I09Race or not shared.KCP2I09Race.active, "Finish owned traversal first")
assert(not shared.KCP3M04Death01 or not shared.KCP3M04Death01.running, "Death observer already running")
local baselineCheck = assert(shared.KCP3M04LifecycleBaselineCheck, "Run the lifecycle fixture first to capture a real Lobby baseline")
local player = Players.LocalPlayer
local candidate = workspace.KeyboardCircuit_P3_M04_01
local character = assert(player.Character)
local humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
assert(humanoid.Health > 0 and player:GetAttribute("KCPhase2Candidate") == candidate.Name, "Begin from a live F6 test avatar")
local probes = assert(player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects"))
local world = assert(workspace:FindFirstChild("KeyboardCircuitArchiveVisuals"))
local before = probes.Diagnostics:Invoke()
assert(before.active and before.lightingApplied and before.ownsLighting, "Archive profile not active")
local remote = game.ReplicatedStorage.Remotes.StudioDevControl
local startAt = os.clock()
local receipt: any = {candidate = candidate.Name, running = true, passed = false, waitingForServerDeath = true, before = before, failures = {},
	boundary = "Actual Humanoid.Died observer for the owned test avatar. Root performs only the ephemeral server Health=0 action. This fixture does not set Health or simulate a fall. Server auto-respawn is observed; real supported Lobby/F6 actions restore the final test entry."}
shared.KCP3M04Death01 = receipt
local diedAt, removedAt
local died = humanoid.Died:Connect(function() diedAt = os.clock(); receipt.waitingForServerDeath = false end)
local removed = player.CharacterRemoving:Connect(function(old) if old == character then removedAt = os.clock() end end)
local function await(label, duration, predicate)
	local deadline = os.clock() + duration
	repeat
		local value = predicate()
		if value then return value end
		task.wait(.05)
	until os.clock() >= deadline
	error(label .. " timed out")
end
local function gone()
	return probes.Parent == nil and world.Parent == nil and player:GetAttribute("KCArchiveLightingOwner") == nil
		and not Lighting:FindFirstChild("KeyboardArchiveBloom") and not Lighting:FindFirstChild("KeyboardArchiveSky")
end
local function active()
	local folder = player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects")
	if not folder or not folder:FindFirstChild("Diagnostics") then return nil end
	local row = folder.Diagnostics:Invoke()
	if row.active and row.lightingApplied and row.ownsLighting and (row.readiness.state == "ready" or row.readiness.state == "degraded") then return row end
	return nil
end
local function request(payload)
	task.wait(.2)
	local row = remote:InvokeServer(payload)
	assert(row and row.ok, row and row.message or "Studio action failed")
	return row
end
task.spawn(function()
	local success, problem = xpcall(function()
		await("real server Humanoid.Died", 30, function() return diedAt ~= nil end)
		receipt.diedObserved, receipt.healthAtDeath = true, humanoid.Health
		assert(humanoid.Health <= 0, "Died event without actual dead health")
		await("effects clean up while dead", 5, gone)
		local baseline, changes = baselineCheck()
		assert(baseline, "Death changed baseline: " .. table.concat(changes, "; "))
		receipt.cleanupAfterDeathSeconds = os.clock() - diedAt
		receipt.exactBaselineWhileDead, receipt.oldFoldersRemoved = true, true
		await("server auto-respawn", 30, function()
			local fresh = player.Character
			local freshHumanoid = if fresh then fresh:FindFirstChildOfClass("Humanoid") else nil
			return fresh and fresh ~= character and freshHumanoid and freshHumanoid.Health > 0 and fresh:FindFirstChild("HumanoidRootPart")
		end)
		assert(removedAt ~= nil, "No CharacterRemoving for the dead avatar")
		local after = await("new automatic-respawn owner", 16, active)
		assert(after.lightingOwnerToken ~= before.lightingOwnerToken and after.updateConnections == 1 and after.entryConnections == 1, "Respawn reused old cosmetic resources")
		receipt.autoRespawnObserved, receipt.characterRemovalObserved, receipt.afterRespawn = true, true, after
		receipt.autoRespawnSeconds = os.clock() - diedAt
	end, debug.traceback)
	if not success then table.insert(receipt.failures, tostring(problem)) end
	died:Disconnect(); removed:Disconnect()
	local returned, restoreProblem = xpcall(function()
		request({action = "Teleport", destination = "Lobby"})
		await("final death test cleanup", 5, function()
			return player:GetAttribute("KCPhase2Candidate") == nil and not player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects")
				and not workspace:FindFirstChild("KeyboardCircuitArchiveVisuals") and player:GetAttribute("KCArchiveLightingOwner") == nil
		end)
		local baseline, changes = baselineCheck()
		assert(baseline, "Final death Lobby baseline: " .. table.concat(changes, "; "))
		receipt.exactBaselineAfterLobby = true
		request({action = "KeyboardCircuitTest"})
		local after = await("owner start after death fixture", 16, active)
		assert(player:GetAttribute("KCPhase2CompletedLaps") == 0 and player:GetAttribute("KCPhase2CheckpointOrdinal") == 0, "Final test progression not clean")
		receipt.ownerReady = after
	end, debug.traceback)
	if not returned then table.insert(receipt.failures, "Final handoff: " .. tostring(restoreProblem)) end
	receipt.running, receipt.passed, receipt.elapsedSeconds = false, #receipt.failures == 0, os.clock() - startAt
end)
return Http:JSONEncode({started = true, receipt = "shared.KCP3M04Death01", ownedPlayerUserId = player.UserId,
	awaiting = "Root sets only this test avatar's server Humanoid.Health=0; observer does not kill or claim a fall."})
