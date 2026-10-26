assert(game:GetService("RunService"):IsStudio() and game:GetService("RunService"):IsClient(), "Actual Studio client required")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")
local Actions = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local original = assert(workspace:FindFirstChild("KeyboardCircuit_P2_C01"))
local Probe = assert(shared.KCP2TraversalProbe, "Install TraversalProbe.client.luau first")
local Fixture = {active = false, records = {}}
local function await(predicate, seconds)
	local deadline = os.clock() + seconds
	repeat if predicate() then return true end; task.wait(.02) until os.clock() >= deadline
	return predicate()
end
local function body()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return character, root, humanoid
end
local function feedback(candidate)
	for _, folder in player.PlayerGui:GetChildren() do
		local identity, diagnostic = folder:FindFirstChild("Candidate"), folder:FindFirstChild("Diagnostics")
		if folder.Name == "KeyboardCircuitAudition" and identity and identity:IsA("ObjectValue")
			and identity.Value == candidate and diagnostic and diagnostic:IsA("BindableFunction") then
			return folder, diagnostic:Invoke()
		end
	end
end
local function snapshot(candidate)
	local folder, diagnostic = feedback(candidate)
	local gui = player.PlayerGui:FindFirstChild("KeyboardCircuitPhase2Status")
	local label = gui and gui:FindFirstChild("Status")
	local _, root, humanoid = body()
	local actions = {}
	for name in Actions:GetAllBoundActionInfo() do
		if string.sub(name, 1, #"KeyboardCircuitPhase2Loading_") == "KeyboardCircuitPhase2Loading_" then table.insert(actions, name) end
	end
	local playing = 0
	if folder then
		for _, sound in folder:GetChildren() do if sound:IsA("Sound") and sound.IsPlaying then playing += 1 end end
	end
	return {
		at = workspace:GetServerTimeNow(), runId = candidate:GetAttribute("KCPhase2RunId"),
		readiness = diagnostic and diagnostic.readiness, totals = diagnostic and diagnostic.totals,
		heldKeys = diagnostic and #diagnostic.held, playing = playing, actions = actions,
		status = gui and gui:GetAttribute("ReadinessState"), holding = gui and gui:GetAttribute("HoldingMovement"),
		width = label and label.AbsoluteSize.X, height = label and label.AbsoluteSize.Y,
		alive = humanoid ~= nil and humanoid.Health > 0, anchored = root and root.Anchored,
	}
end
function Fixture.Run(mode, injectPreloadDelay)
	assert(table.find({"Degrade", "Restart", "Respawn"}, mode), "Use Degrade, Restart or Respawn")
	assert(not Fixture.active, "Finish this helper's current fault case first")
	local encoded = original:GetAttribute("KCPhase2ServerDiagnostics")
	local state = Http:JSONDecode(encoded)
	assert(state.realServer and state.participants[tostring(player.UserId)] == nil
		and player:GetAttribute("KCPhase2Candidate") == nil, "Lead must Leave the real Session before isolated local faults")
	local character, root, humanoid = body()
	assert(root and humanoid and humanoid.Health > 0 and not root.Anchored
		and player:GetAttribute("OnboardingReady") ~= false, "Released living arrival required")
	local baseBank = assert(original.RecoveryPads:FindFirstChild("F00"))
	local baseContact = assert(baseBank:FindFirstChild("BankContact"))
	local filter = RaycastParams.new()
	filter.FilterType, filter.FilterDescendantsInstances, filter.RespectCanCollide = Enum.RaycastFilterType.Include, {baseBank}, true
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -7, 0), filter)
	assert(hit, "Start on the original off-route F00 recovery bank")
	local foreignActions, foreignFolders = {}, {}
	for name in Actions:GetAllBoundActionInfo() do foreignActions[name] = true end
	for _, folder in player.PlayerGui:GetChildren() do
		local identity = folder:FindFirstChild("Candidate")
		if folder.Name == "KeyboardCircuitAudition" and identity and identity:IsA("ObjectValue") then
			foreignFolders[folder] = identity.Value
		end
	end
	local model = Instance.new("Model")
	model.Name = "KC_P2_LoadingFixture_" .. player.UserId .. "_" .. Http:GenerateGUID(false)
	model:SetAttribute("CourseId", "keyboard-circuit-phase2")
	model:SetAttribute("KCPhase2PreviewEnabled", true)
	model:SetAttribute("KCPhase2Revision", "FIXTURE_ONLY")
	model:SetAttribute("KCPhase2RunId", 1)
	local record = {case = "isolated-loading-" .. mode, active = true, nativeExecuted = true, samples = {}, beganAt = os.clock(),
		fault = {family = "Clicky", kind = "up", id = "0", timeout = .8, preloadDelay = 0},
		boundary = "Local-only temporary candidate using production Feedback/Readiness/installed Preview; no authoritative Session, race, network/cache or device claim"}
	table.insert(Fixture.records, record)
	Fixture.active = true
	task.spawn(function()
		local completed, completionError = xpcall(function()
			local originalPose = root.CFrame
			local ok, err = xpcall(function()
				local sources = Instance.new("Folder")
				sources.Name, sources.Parent = "SourceSnapshot", model
				for _, name in {"ConfigSnapshot", "KeyboardCircuitAudio", "KeyboardCircuitFeedback", "Phase2Readiness"} do
					local module = assert(original.SourceSnapshot:FindFirstChild(name)):Clone()
					module.Parent = sources
				end
				record.sourceIdentity = {}
				for _, name in {"ConfigSnapshot", "KeyboardCircuitAudio", "KeyboardCircuitFeedback", "Phase2Readiness"} do
					local checked, equal = pcall(function() return sources[name].Source == original.SourceSnapshot[name].Source end)
					record.sourceIdentity[name] = {freshClone = sources[name] ~= original.SourceSnapshot[name],
						equalBefore = if checked then equal else nil, readError = if checked then nil else tostring(equal), role = "exactFixtureCopy"}
				end
				local originalConfigSource = original.SourceSnapshot.ConfigSnapshot.Source
				local configModule = sources.ConfigSnapshot
				local beforeConfig = configModule.Source
				local prefix = "--!strict\nlocal config = (function()\n"
				local suffix = "\nend)()\nconfig.AudioReadyTimeout = .8\nconfig.Audio.Clicky.upId = \"0\"\nreturn config\n"
				local faultConfig = prefix .. beforeConfig .. suffix
				-- The plugin and PlayerScripts have separate require caches, so the fault must live in source.
				configModule.Source = faultConfig
				assert(configModule.Source == faultConfig, "Own ConfigSnapshot fault source was not applied")
				record.sourceIdentity.ConfigSnapshot.role = "fixtureModifiedConfig"
				record.sourceIdentity.ConfigSnapshot.equalAfter = configModule.Source == originalConfigSource
				record.fault.configPatch = {prefix = prefix, suffix = suffix, beforeBytes = #beforeConfig, afterBytes = #faultConfig,
					sourceEqualsExactPatch = configModule.Source == faultConfig, cacheBoundary = "Fresh clone source is patched before any VM requires it"}
				if injectPreloadDelay then
					local audio = sources.KeyboardCircuitAudio
					local changed, sourceError = pcall(function()
						local beforeSource = audio.Source
						local source, count = beforeSource:gsub("ContentProvider:PreloadAsync%(list%)", "task.wait(.35); ContentProvider:PreloadAsync(list)")
						assert(count == 1, "Expected one preload call in own fresh Audio clone")
						audio.Source = source
						record.fault.patch = {from = "ContentProvider:PreloadAsync(list)", to = "task.wait(.35); ContentProvider:PreloadAsync(list)", replacements = count,
							beforeBytes = #beforeSource, afterBytes = #source, sourceEqualsExactPatch = audio.Source == source}
					end)
					record.fault.preloadDelay = if changed then .35 else 0
					record.fault.sourceWriteError = if changed then nil else tostring(sourceError)
					record.sourceIdentity.KeyboardCircuitAudio.role = if changed then "fixtureModifiedAudio" else "exactFixtureCopy"
					record.fault.audioSourceBoundary = if changed then "Audio clone is fixture-modified by recorded preload delay; Feedback/Readiness remain exact" else "Audio clone remains unchanged; repeatable loading is unverified"
				end
				local pads = Instance.new("Folder")
				pads.Name, pads.Parent = "RecoveryPads", model
				local bank = baseBank:Clone()
				bank.Parent = pads
				local coursePose, courseSize = original:GetBoundingBox()
				local maxX = coursePose.Position.X + (math.abs(coursePose.RightVector.X) * courseSize.X
					+ math.abs(coursePose.UpVector.X) * courseSize.Y + math.abs(coursePose.LookVector.X) * courseSize.Z) / 2
				local overlap = OverlapParams.new()
				overlap.FilterType, overlap.FilterDescendantsInstances, overlap.RespectCanCollide = Enum.RaycastFilterType.Exclude, {character}, true
				local destination
				for step = 1, 5 do
					local point = Vector3.new(maxX + 48 * step, baseContact.Position.Y, baseContact.Position.Z)
					if #workspace:GetPartBoundsInBox(CFrame.new(point), Vector3.new(28, 12, 24), overlap) == 0 then destination = point; break end
				end
				assert(destination, "No clear isolated fixture space found in five bounded probes")
				bank:PivotTo(bank:GetPivot() + destination - baseContact.Position)
				record.padPosition = {destination.X, destination.Y, destination.Z}
				for _, part in bank:GetDescendants() do
					if part:IsA("BasePart") then part.Anchored, part.CanTouch = true, false end
				end
				model.Parent = workspace
				Probe.Place(bank.BankContact)
				local oldFolder, restartedAt = nil, nil
				local selectedAt, deadline = os.clock(), os.clock() + (if mode == "Respawn" then 16 else 3)
				player:SetAttribute("KCPhase2Candidate", model.Name)
				record.loadingSamples = 0
				repeat
					local sample = snapshot(model)
					if sample.readiness then
						assert(sample.readiness.timeout == .8, "Production feedback did not receive the source-patched fault deadline")
						record.fault.configObservedByFeedback = true
					end
					if #record.samples < 192 then table.insert(record.samples, sample) end
					if sample.readiness and sample.readiness.state == "loading" then
						record.loadingSamples += 1
						if sample.holding == true then record.heldOnSafePad = true end
						if not record.triggered and mode ~= "Degrade" then
							record.triggered = true
							oldFolder = feedback(model)
							if mode == "Restart" then
								restartedAt = os.clock()
								model:SetAttribute("KCPhase2RunId", 2)
							else
								task.spawn(function()
									local called, response = pcall(function() return game.ReplicatedStorage.Remotes.StudioDevControl:InvokeServer({action = "Respawn"}) end)
									record.respawnResponse = if called then response else {error = tostring(response)}
								end)
							end
						end
					end
					record.characterChanged = player.Character ~= character
					local currentFolder = feedback(model)
					local replaced = if mode == "Restart" then record.triggered and currentFolder and currentFolder ~= oldFolder
						elseif mode == "Respawn" then record.triggered and record.characterChanged and currentFolder and currentFolder ~= oldFolder else true
					if sample.readiness and sample.readiness.state == "degraded" and replaced
						and sample.status == "degraded" and sample.holding == false and #sample.actions == 0 then
						record.resolved, record.resolveSeconds = sample, os.clock() - (restartedAt or selectedAt)
						break
					end
					task.wait(.02)
				until os.clock() >= deadline
				if mode ~= "Degrade" and not record.triggered then
					record.status, record.reason = "unverified", "No actual loading sample; invalid asset alone did not create an observable loading window"
				else
					record.passed = record.resolved ~= nil and not record.resolved.holding and #record.resolved.actions == 0
						and (not oldFolder or oldFolder.Parent == nil)
					if record.resolved then
						record.invalidClipFailed = false
						for _, clip in record.resolved.readiness.failed or {} do
							if clip.family == "Clicky" and clip.kind == "up" and (clip.id == "rbxassetid://0" or clip.id == "https://www.roblox.com/asset/?id=0") then record.invalidClipFailed = true end
						end
						record.passed = record.passed and record.invalidClipFailed and record.resolved.readiness.elapsed <= 1.1
					end
					if record.fault.preloadDelay > 0 then record.passed = record.passed and record.loadingSamples > 0 and record.heldOnSafePad == true end
					if mode ~= "Respawn" then record.passed = record.passed and record.resolveSeconds <= 1.1 end
				end
				record.contactsDuringLoading = false
				for _, sample in record.samples do
					if sample.readiness and sample.readiness.state == "loading" and sample.totals
						and (sample.totals.played > 0 or sample.heldKeys > 0) then record.contactsDuringLoading = true end
				end
				if record.contactsDuringLoading then record.passed = false end
				if mode == "Respawn" and record.resolved then
					record.noReplayAwayFromFixture = record.resolved.playing == 0 and record.resolved.heldKeys == 0 and record.resolved.totals.played == 0
					if not record.noReplayAwayFromFixture then record.passed = false end
				end
				record.originalConfigSourceUnchanged = original.SourceSnapshot.ConfigSnapshot.Source == originalConfigSource
				if not record.originalConfigSourceUnchanged then record.passed = false end
				record.oldFolderRemoved = oldFolder ~= nil and oldFolder.Parent == nil
				record.nativePlaybackBoundary = "Sound.IsPlaying and loaded diagnostics are engine observations; audible output requires separate listening"
			end, debug.traceback)
			record.caseError = if ok then nil else tostring(err)
			if not ok then record.error, record.passed = record.caseError, false end
			if player:GetAttribute("KCPhase2Candidate") == model.Name then player:SetAttribute("KCPhase2Candidate", nil) end
			await(function() return feedback(model) == nil end, .6)
			local currentCharacter, currentRoot, currentHumanoid = body()
			local avatarRestored = false
			if currentRoot and currentHumanoid and currentHumanoid.Health > 0 and not currentRoot.Anchored
				and player:GetAttribute("OnboardingReady") ~= false then
				if currentCharacter == character then
					currentCharacter:PivotTo(originalPose)
					currentRoot.AssemblyLinearVelocity, currentRoot.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
				else Probe.Place(baseContact) end
				avatarRestored = true
			end
			local preserveSupport = currentCharacter == character and currentRoot ~= nil and not avatarRestored
			if not preserveSupport then model:Destroy() end
			task.wait(.1)
			record.cleanup = {ownCandidateRemoved = model.Parent == nil, ownFeedbackRemoved = feedback(model) == nil, ownActionsRemoved = true,
				foreignActionsPresent = true, foreignFeedbackPresent = true, avatarRestored = avatarRestored,
				pendingSupport = preserveSupport, ownCandidateName = if preserveSupport then model.Name else nil}
			local afterActions = Actions:GetAllBoundActionInfo()
			for name in afterActions do
				if string.sub(name, 1, #"KeyboardCircuitPhase2Loading_") == "KeyboardCircuitPhase2Loading_" then record.cleanup.ownActionsRemoved = false end
			end
			for name in foreignActions do if afterActions[name] == nil then record.cleanup.foreignActionsPresent = false end end
			if mode ~= "Respawn" then
				for folder, identity in foreignFolders do
					if not folder.Parent or not folder:FindFirstChild("Candidate") or folder.Candidate.Value ~= identity then record.cleanup.foreignFeedbackPresent = false end
				end
			else record.cleanup.foreignFeedbackBoundary = "Character replacement may recreate other screens' feedback; use independent before/after candidate inventory" end
			if not ok then record.error, record.passed = tostring(err), false end
			if record.passed then record.passed = record.cleanup.ownCandidateRemoved and record.cleanup.ownFeedbackRemoved
				and record.cleanup.ownActionsRemoved and record.cleanup.avatarRestored and record.cleanup.foreignActionsPresent and record.cleanup.foreignFeedbackPresent end
			record.remotePending = mode == "Respawn" and record.triggered == true and record.respawnResponse == nil
			if record.remotePending then record.passed = false end
			end, debug.traceback)
		if not completed then
			record.completionError, record.passed, record.status = tostring(completionError), false, "failed"
			record.error = record.error or record.completionError
			local cleaned, cleanupError = pcall(function()
				if player:GetAttribute("KCPhase2Candidate") == model.Name then player:SetAttribute("KCPhase2Candidate", nil) end
				local currentCharacter, currentRoot, currentHumanoid = body()
				if currentRoot and currentHumanoid and currentHumanoid.Health > 0 and not currentRoot.Anchored
					and player:GetAttribute("OnboardingReady") ~= false then Probe.Place(baseContact); model:Destroy()
				elseif currentCharacter ~= character then model:Destroy()
				else record.pendingSupport = model.Parent ~= nil; record.ownCandidateName = model.Name end
			end)
			record.completionCleanupError = if cleaned then nil else tostring(cleanupError)
		end
		record.status = record.status or (if record.passed then "passed" else "failed")
		record.finishedAt, record.completed = os.clock(), true
		record.active, Fixture.active = false, false
	end)
	return {started = true, case = record.case, boundary = "Result pending in shared.KCP2LoadingFault.records; installing or starting is not a native pass"}
end
shared.KCP2LoadingFault = Fixture
return {installed = true, functions = {"Run"}, boundary = "Prepared optional isolated local fault helper; installing runs no case"}
