assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient())
local player = game.Players.LocalPlayer
local candidate = workspace.KeyboardCircuit_P2_C01
local before = shared.KCP2LifecycleClient.Read()
local originalCharacter = player.Character
local function feedback()
	for _, folder in player.PlayerGui:GetChildren() do
		local identity, diagnostic = folder:FindFirstChild("Candidate"), folder:FindFirstChild("Diagnostics")
		if identity and identity:IsA("ObjectValue") and identity.Value == candidate and diagnostic then return folder, diagnostic:Invoke() end
	end
end
local originalFeedback = feedback()
local state = {active = true, userId = player.UserId, before = before, loadingSamples = 0, samples = {}}
shared.KCP2ConcurrentRespawn = state
task.spawn(function()
	local ok, err = xpcall(function()
		local began, sampled = os.clock(), 0
		while os.clock() - began < 16 do
			local folder, diagnostic = feedback()
			local readiness = diagnostic and diagnostic.readiness
			local changed = player.Character ~= nil and player.Character ~= originalCharacter
			if changed and not state.changedAt then state.changedAt = workspace:GetServerTimeNow() end
			if changed and readiness and readiness.state == "loading" then state.loadingSamples += 1 end
			if os.clock() - sampled > .1 then
				sampled = os.clock()
				table.insert(state.samples, {at = workspace:GetServerTimeNow(), changed = changed, freshFeedback = folder ~= originalFeedback,
					readiness = readiness, previewHolding = player.PlayerGui:FindFirstChild("KeyboardCircuitPhase2Status") and player.PlayerGui.KeyboardCircuitPhase2Status:GetAttribute("HoldingMovement")})
			end
			local current = shared.KCP2LifecycleClient.Read()
			local pad = candidate.RecoveryPads[before.server.recoveryGate].BankContact
			if changed and folder and folder ~= originalFeedback and readiness and (readiness.state == "ready" or readiness.state == "degraded")
				and current.support == pad:GetFullName() then
				state.after, state.resolved, state.finishedAt = current, readiness, workspace:GetServerTimeNow()
				state.originalFeedbackRemoved = originalFeedback == nil or originalFeedback.Parent == nil
				local actions = game:GetService("ContextActionService"):GetAllBoundActionInfo()
				state.loadingActions, state.foreignNavigationPreserved = 0, actions.ClassicElevationLobbyNavigation ~= nil
				for name in actions do if string.sub(name, 1, #"KeyboardCircuitPhase2Loading_") == "KeyboardCircuitPhase2Loading_" then state.loadingActions += 1 end end
				state.passed = current.lap == before.lap and current.completedLaps == before.completedLaps and current.nextGate == before.nextGate
					and current.recoveries > before.recoveries and state.originalFeedbackRemoved and state.loadingActions == 0
					and state.foreignNavigationPreserved and not current.anchored and current.alive
				return
			end
			task.wait(.03)
		end
		state.passed, state.reason = false, "Concurrent respawn did not resolve within 16 seconds"
	end, debug.traceback)
	state.error = if ok then nil else tostring(err)
	if not ok then state.passed = false end
	state.active = false
	state.boundary = "Observer only. The server starts both real LoadCharacterAsync calls together; existing arrival, Session recovery and installed preview own respawn behavior. Warm audio cache remains disclosed."
end)
return {observing = true, userId = player.UserId}
