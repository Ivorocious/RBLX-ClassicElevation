--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(game.ReplicatedStorage.Config.MoonlitCitadelCourseConfig)
local Cases = {}
local active, latest
local supportedCases = {adjacent = true, overhead = true, side = true, ["red-body"] = true,
	["cage-body"] = true, ["light-miss"] = true, ["accessory-miss"] = true}
local bodyNames = {Head = true, UpperTorso = true, LowerTorso = true, LeftUpperArm = true, LeftLowerArm = true,
	LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true, LeftUpperLeg = true,
	LeftLowerLeg = true, LeftFoot = true, RightUpperLeg = true, RightLowerLeg = true, RightFoot = true,
	Torso = true, ["Left Arm"] = true, ["Right Arm"] = true, ["Left Leg"] = true, ["Right Leg"] = true}
local function xyz(value) return {value.X, value.Y, value.Z} end
local function resolve(root, path)
	for name in string.gmatch(path, "[^/]+") do root = assert(root:FindFirstChild(name), "Missing native part " .. path) end
	return root
end
local function finite(value) return typeof(value) == "number" and value == value and math.abs(value) < math.huge end
local function actualResult(result, userId)
	for _, list in {result.activeRacers or {}, result.placements or {}, result.dnfs or {}} do
		for _, entry in list do if entry.userId == userId then return entry end end
	end
	return nil
end

local function clientEnvelope(report, entry)
	assert(entry.source == "native-client-contact-observer" and entry.caseId == report.caseId
		and entry.raceId == report.raceId and entry.candidate == report.candidate, "Client observation belongs to a different case/race/candidate")
	assert(entry.failure == nil and type(entry.samples) == "table" and #entry.samples >= 3, "Client observation failed or lacks readiness samples")
	local index = table.find(report.actualClientUserIds, entry.userId)
	assert(index, "Client observation user ID is not an actual case participant")
	return index
end

function Cases.CheckClientEvidence(report, entries)
	assert(#entries == 2 and report.measurementStartedAt and report.measurementEndedAt, "Require both client reports and the exact measured server window")
	local summaries, seen = {}, {}
	for _, entry in entries do
		local index = clientEnvelope(report, entry)
		assert(not seen[index], "Duplicate client observation")
		seen[index] = true
		local baseline = report.before.players[index]
		local previous, first, last, deckSamples, postRecovery, firstRelative, maximumRelative = nil, nil, nil, 0, {}, nil, 0
		for _, sample in entry.samples do
			if sample.at < report.measurementStartedAt - 0.35 or sample.at > report.measurementEndedAt + 0.35 then continue end
			assert(sample.raceId == report.raceId and sample.status == "Racing" and sample.official and sample.alive and not sample.anchored,
				"Actual client race/status/character changed during measured case")
			assert(sample.cp == baseline.checkpoint, "Actual client checkpoint changed during controlled case")
			if previous then assert(sample.at > previous and sample.at - previous <= 0.6, "Gap in simultaneous actual client observation") end
			previous, first, last = sample.at, first or sample.at, sample.at
			local positiveActor = index == 1 and (report.case == "overhead" or report.case == "side")
			local afterRecovery = positiveActor and report.recoveryServerTime and sample.at >= report.recoveryServerTime + 0.5
			local recoveryTransition = positiveActor and report.recoveryServerTime and math.abs(sample.at - report.recoveryServerTime) <= 0.5
			if afterRecovery then
				assert(sample.falls == baseline.falls + 1 and sample.support ~= report.deck, "Affected client did not leave Deck through actual shared recovery")
				if sample.at >= report.recoveryServerTime + 1 then table.insert(postRecovery, sample.position) end
			elseif not recoveryTransition then
				assert(sample.falls == baseline.falls and sample.support == report.deck and sample.floor ~= "Air"
					and sample.normalY >= 0.95 and math.abs(sample.footGap) <= 0.6, "Actual client lost physical Deck support")
				deckSamples += 1
				local relative = Vector3.new(unpack(sample.relative))
				firstRelative = firstRelative or relative
				maximumRelative = math.max(maximumRelative, (relative - firstRelative).Magnitude)
				assert(maximumRelative <= (report.relativeTolerance or 0.8), "Actual client moved outside the existing relative-pose tolerance")
			end
		end
		assert(first and first <= report.measurementStartedAt + 0.35 and last >= report.measurementEndedAt - 0.35,
			"Actual client report does not cover the same full measured server window")
		assert(deckSamples >= 3, "Actual client Deck support evidence is insufficient")
		if index == 1 and (report.case == "overhead" or report.case == "side") then
			assert(#postRecovery >= 2, "Actual recovered client lacks settled observations")
			local firstPosition = Vector3.new(unpack(postRecovery[1]))
			local maximum = 0
			for _, position in postRecovery do maximum = math.max(maximum, (Vector3.new(unpack(position)) - firstPosition).Magnitude) end
			assert(maximum < 0.6, "Actual client drifted after shared recovery")
		end
		table.insert(summaries, {userId = entry.userId, firstAt = first, lastAt = last, deckSamples = deckSamples,
			maximumRelative3D = maximumRelative, postRecoverySamples = #postRecovery})
	end
	return summaries
end

function Cases.Start(services, options)
	assert(RunService:IsStudio() and RunService:IsServer() and game.PlaceId == 0 and game.GameId == 0,
		"Controlled placements require the owned unpublished Studio server fixture")
	assert(not active, "Stop the current controlled case first")
	options = options or {}
	local caseName = assert(options.case, "Name one controlled case")
	assert(supportedCases[caseName], "Unknown controlled case " .. caseName)
	for _, name in {"RaceService", "CourseService", "PlayerRaceService", "ResultsService", "CheckpointService", "MoonlitCitadelService"} do
		assert(services[name], "Missing actual shared service " .. name)
	end
	local course = assert(services.CourseService.GetActiveCourse(), "No actual shared active course")
	assert(course:GetAttribute("CandidateId") == Config.CandidateId and services.CourseService.GetActiveCourseId() == Config.CourseId, "Wrong actual candidate")
	local raceId = services.RaceService.GetCurrentRaceId()
	assert(raceId ~= "" and services.RaceService.IsRaceActive(), "Start an actual official shared race first")
	local ids = assert(options.userIds, "Supply actual existing client user IDs")
	assert(#ids == 2 and ids[1] ~= ids[2], "Each controlled case requires exactly two distinct actual clients")
	local duration = options.durationSeconds or (if caseName == "adjacent" then 16 elseif caseName == "light-miss" or caseName == "accessory-miss" then 14 else 6)
	assert(finite(duration) and duration >= 1 and duration <= 60, "Case duration must be1–60seconds")
	local sampleInterval = options.sampleInterval or 0.1
	assert(finite(sampleInterval) and sampleInterval >= 0.05 and sampleInterval <= 0.25, "Sample interval must be0.05–0.25seconds")
	local relativeTolerance = options.relativeTolerance or 0.8
	assert(finite(relativeTolerance) and relativeTolerance > 0 and relativeTolerance <= 0.8, "Relative tolerance cannot exceed the existing0.8stud bound")
	local readinessMaxAge = options.readinessMaxAgeSeconds or 15
	assert(finite(readinessMaxAge) and readinessMaxAge >= 12 and readinessMaxAge <= 15, "Preflight readiness age must be bounded to12–15seconds")
	if caseName == "adjacent" then assert(duration >= Config.CycleSeconds, "Adjacent trial must cover at least one complete car cycle") end
	local actors = {}
	for _, userId in ids do
		local player = assert(Players:GetPlayerByUserId(userId), "No actual Player for requested user ID")
		assert(services.PlayerRaceService.IsOfficialRacer(player) and services.PlayerRaceService.GetPlayerStatus(player) == "Racing", "Actual official Racing players required")
		local character = assert(player.Character, "Actual character absent")
		local humanoid = assert(character:FindFirstChildOfClass("Humanoid"), "Actual humanoid absent")
		local root = assert(character:FindFirstChild("HumanoidRootPart"), "Actual root absent")
		assert(humanoid.Health > 0 and humanoid.RigType == Enum.HumanoidRigType.R15 and not root.Anchored, "Use live supported R15 racers")
		table.insert(actors, {player = player, character = character, humanoid = humanoid, root = root})
	end
	local caseId = "MC_" .. HttpService:GenerateGUID(false):gsub("%-", "")
	local report = {caseId = caseId, case = caseName, candidate = Config.CandidateId, raceId = raceId,
		evidenceKind = "Controlled native placement; separate from continuous ordinary traversal",
		actualClientUserIds = table.clone(ids), actualClientsPresent = #Players:GetPlayers(), state = "Starting",
		samples = {}, placements = {}, serverFloorMaterialNote = "Air can occur with client-owned physics; require the real server down-ray and separate client observation",
		clientObservationRequired = true, durationSeconds = duration, relativeTolerance = relativeTolerance,
		readinessMaxAgeSeconds = readinessMaxAge, completeRoute = false}
	latest = report
	local stopped, cancelled, owned, connection = false, nil, {}, nil
	local started = os.clock()
	local liftCase = caseName == "adjacent" or caseName == "overhead" or caseName == "side"
	local deadline = started + math.min(120, duration + (if liftCase then 75 else 45))
	local handle = {}
	active = handle
	local deck, target, visible, temporaryBlock, accessoryHandle
	local previousRelative, maximumRelativeDrift = {}, {}
	local firstRecovery, recoverySettled, finalPosition = nil, nil, nil
	local supportMisses, accessoryOverlaps, lightExposureSamples, bodyOverlapSamples = {0, 0}, 0, 0, 0
	local phases = {}
	local beginRequested, clientEvidence = false, nil
	local function own(item)
		item:SetAttribute("MCContactCaseOwner", caseId)
		table.insert(owned, item)
		return item
	end
	local function dispose(item)
		if item and item.Parent and item:GetAttribute("MCContactCaseOwner") == caseId then item:Destroy() end
	end
	local function guard()
		assert(not cancelled, cancelled or "Cancelled")
		assert(os.clock() <= deadline, "Controlled case watchdog expired")
		assert(services.RaceService.GetCurrentRaceId() == raceId and services.RaceService.IsRaceActive(), "Actual shared race changed or stopped")
		assert(services.CourseService.GetActiveCourse() == course and course:GetAttribute("CandidateId") == Config.CandidateId, "Actual active course changed")
		for _, actor in actors do
			assert(actor.player.Character == actor.character and actor.humanoid.Health > 0, "Actual character replaced or died")
			assert(services.PlayerRaceService.IsOfficialRacer(actor.player) and services.PlayerRaceService.GetPlayerStatus(actor.player) == "Racing", "Actual official status changed")
		end
	end
	local function state(actor)
		local result = assert(services.ResultsService.GetCurrentRaceResult(), "Actual results absent")
		assert(result.raceId == raceId, "Actual result race ID changed")
		local entry = assert(actualResult(result, actor.player.UserId), "Actual racer result absent")
		local splits = {}
		for _, split in entry.checkpointSplits or {} do table.insert(splits, {index = split.checkpointIndex, lap = split.lap, elapsed = split.elapsedTime}) end
		return {userId = actor.player.UserId, status = services.PlayerRaceService.GetPlayerStatus(actor.player),
			official = services.PlayerRaceService.IsOfficialRacer(actor.player), checkpoint = services.CheckpointService.GetLatestCheckpointIndex(actor.player),
			falls = entry.falls, splits = splits, finished = entry.status == "Finished", root = xyz(actor.root.Position),
			recoveryUntil = actor.character:GetAttribute("RecoveryUntil"), humanoidState = actor.humanoid:GetState().Name,
			floorMaterial = actor.humanoid.FloorMaterial.Name, raceId = result.raceId}
	end
	local function diagnostics() return services.MoonlitCitadelService.GetDiagnostics() end
	local function snapshot()
		local result = {raceId = raceId, serverTime = workspace:GetServerTimeNow(), players = {}, diagnostics = diagnostics()}
		for _, actor in actors do table.insert(result.players, state(actor)) end
		return result
	end
	local function support(actor)
		local params = RaycastParams.new()
		params.FilterType, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, true
		local characters = {}
		for _, player in Players:GetPlayers() do if player.Character then table.insert(characters, player.Character) end end
		params.FilterDescendantsInstances = characters
		local depth = actor.humanoid.HipHeight + actor.root.Size.Y / 2 + 1
		local hit = workspace:Raycast(actor.root.Position, Vector3.new(0, -depth, 0), params)
		return hit
	end
	local function visibleBody(actor)
		local parts = {}
		for _, item in actor.character:GetChildren() do
			if item:IsA("BasePart") and bodyNames[item.Name] and item.Transparency < 1 and item.CanQuery then table.insert(parts, item) end
		end
		return parts
	end
	local function overlap(part, included)
		local params = OverlapParams.new()
		params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Include, included
		return #workspace:GetPartsInPart(part, params)
	end
	local function hazardContacts(actor, handlePart)
		if caseName == "red-body" then return overlap(target, visibleBody(actor)), 0 end
		if not visible then return 0, 0 end
		local bodyHits, handleHits = 0, 0
		for _, part in visible:GetDescendants() do
			if part:IsA("BasePart") and part.Transparency < 1 then
				bodyHits += overlap(part, visibleBody(actor))
				if handlePart then handleHits += overlap(part, {handlePart}) end
			end
		end
		return bodyHits, handleHits
	end
	local function place(actor, frame, label, reference)
		guard()
		actor.humanoid.Jump = false
		actor.humanoid:Move(Vector3.zero, false)
		actor.root.AssemblyLinearVelocity, actor.root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
		actor.character:PivotTo(frame * actor.root.CFrame:Inverse() * actor.character:GetPivot())
		table.insert(report.placements, {userId = actor.player.UserId, label = label, root = xyz(actor.root.Position),
			reference = reference and reference:GetFullName(), localPose = reference and {reference:GetPivot():ToObjectSpace(actor.root.CFrame):GetComponents()},
			at = workspace:GetServerTimeNow(), checkpoint = services.CheckpointService.GetLatestCheckpointIndex(actor.player)})
	end
	local function standingFrame(part, actor, offset)
		assert(part:IsA("BasePart") and part.CanCollide, "Standing target must be an actual collidable contact")
		local height = part.Size.Y / 2 + actor.humanoid.HipHeight + actor.root.Size.Y / 2 + 0.08
		return part.CFrame * CFrame.new((offset or Vector3.zero) + Vector3.new(0, height, 0))
	end
	local function waitFor(name, predicate, seconds)
		report.waiting = name
		local untilClock = os.clock() + seconds
		repeat guard(); if predicate() then report.waiting = nil; return end; task.wait(0.025) until os.clock() >= untilClock
		error("Timed out " .. name)
	end
	local function cleanup()
		if connection then connection:Disconnect() end
		for _, item in owned do dispose(item) end
		if active == handle then active = nil end
	end
	local function persist()
		local folder = ServerStorage:FindFirstChild("MoonlitPhase2Evidence")
		if not folder then folder = Instance.new("Folder"); folder.Name = "MoonlitPhase2Evidence"; folder.Parent = ServerStorage end
		local caseFolder = Instance.new("Folder")
		caseFolder.Name, caseFolder.Parent = caseId, folder
		report.evidencePath = caseFolder:GetFullName()
		local encoded = HttpService:JSONEncode(report)
		local chunks = math.ceil(#encoded / 140000)
		caseFolder:SetAttribute("JSONChunks", chunks)
		caseFolder:SetAttribute("JSONBytes", #encoded)
		for index = 1, chunks do
			local value = Instance.new("StringValue")
			value.Name = string.format("JSON_%03d", index)
			value.Value = string.sub(encoded, (index - 1) * 140000 + 1, index * 140000)
			value.Parent = caseFolder
		end
	end
	function handle.Stop(reason) cancelled = reason or "Stopped by lead" end
	function handle.Debug() return report end
	function handle.Begin(entries)
		assert(liftCase and report.state == "Armed" and not beginRequested, "Case must be Armed before Begin")
		assert(#entries == 2, "Begin requires readiness from both actual clients")
		local seen = {}
		local ages = {}
		for _, entry in entries do
			local index = clientEnvelope(report, entry)
			assert(not seen[index], "Duplicate readiness participant")
			seen[index] = true
			local samples = entry.samples
			for sampleIndex = #samples - 2, #samples do
				local sample = samples[sampleIndex]
				local age = workspace:GetServerTimeNow() - sample.at
				assert(age <= readinessMaxAge and sample.at <= workspace:GetServerTimeNow() + 0.2,
					"Actual client readiness is stale or from the future")
				ages[tostring(entry.userId)] = math.max(ages[tostring(entry.userId)] or 0, age)
				assert(sample.support == report.deck and sample.floor ~= "Air" and sample.normalY >= 0.95 and math.abs(sample.footGap) <= 0.6
					and sample.status == "Racing" and sample.official and sample.alive and not sample.anchored, "Actual client is not ready on the real Deck")
				assert(sample.cp == report.before.players[index].checkpoint and sample.falls == report.before.players[index].falls,
					"Actual client changed progress/recovery during controlled setup")
			end
		end
		report.beginReadiness = entries
		report.beginReadinessMaximumAges = ages
		beginRequested = true
		return {caseId = caseId, accepted = true, state = "WaitingForStableLowDwell"}
	end
	function handle.SubmitClientEvidence(entries)
		assert(liftCase and report.state == "AwaitingClientEvidence", "Measured server window must finish before submitting paired client evidence")
		local summary = Cases.CheckClientEvidence(report, entries)
		report.clientEvidence, report.clientSupportSummary = entries, summary
		clientEvidence = entries
		return summary
	end
	task.spawn(function()
		local ok, reason = xpcall(function()
			guard()
			report.before = snapshot()
			assert(report.before.diagnostics.bound, "Actual Moonlit runtime is not bound")
			waitFor("Previous recovery immunity expired", function()
				for _, actor in actors do if (actor.character:GetAttribute("RecoveryUntil") or 0) > workspace:GetServerTimeNow() then return false end end
				return true
			end, 3)
			if liftCase then
				local stage, bay = options.stage or "Lower", options.bay or 1
				assert((stage == "Lower" or stage == "Upper") and (bay == 1 or bay == 2), "Choose actual Lower/Upper and Bay1/Bay2")
				deck = resolve(course, "Obstacles/MovingCars/" .. stage .. "_Bay" .. bay .. "/Deck")
				assert(deck:IsA("BasePart") and deck.CanCollide, "Actual car Deck missing")
				report.deck = deck:GetFullName()
				waitFor("Actual LowDwell setup", function()
					return diagnostics().elapsed >= (deck.Parent:GetAttribute("PhaseSeconds") or 0)
						and deck.Parent:GetAttribute("MoonlitPhase") == "LowDwell"
						and (deck.Parent:GetAttribute("MoonlitNextPhaseAt") or 0) - workspace:GetServerTimeNow() >= 1.2
				end, Config.CycleSeconds + 2)
				for index, actor in actors do place(actor, standingFrame(deck, actor, Vector3.new(if index == 1 then -3 else 3, 0, 0)), "Controlled actual Deck placement", deck) end
				local stableSince
				local function stableLow()
					if deck.Parent:GetAttribute("MoonlitPhase") ~= "LowDwell" then stableSince = nil; return false end
					for _, actor in actors do
						local hit = support(actor)
						local gap = hit and actor.root.Position.Y - hit.Position.Y - actor.humanoid.HipHeight - actor.root.Size.Y / 2
						if not hit or hit.Instance ~= deck or math.abs(gap) > 0.6 or hit.Normal.Y < 0.95 then stableSince = nil; return false end
					end
					stableSince = stableSince or os.clock()
					return os.clock() - stableSince >= 0.4
				end
				waitFor("Stable actual LowDwell feet", stableLow, Config.CycleSeconds * 2 + 4)
				report.setup = snapshot()
				report.state = "Armed"
				waitFor("Lead Begin with both actual client readiness reports", function() return beginRequested end, 30)
				stableSince = nil
				waitFor("Measured window stable LowDwell", stableLow, Config.CycleSeconds + 2)
				if caseName ~= "adjacent" then
					temporaryBlock = own(Instance.new("Part"))
					temporaryBlock.Name = caseId .. "_" .. caseName
					temporaryBlock.Anchored, temporaryBlock.CanCollide, temporaryBlock.CanQuery = true, true, true
					temporaryBlock.Color, temporaryBlock.Transparency = Color3.fromRGB(77, 167, 230), 0.25
					local root = actors[1].root
					local topHeight = root.Position.Y + 4
					if caseName == "overhead" then
						temporaryBlock.Size = Vector3.new(3, 0.5, 3)
						temporaryBlock.CFrame = CFrame.new(root.Position.X, topHeight + 0.8, root.Position.Z)
					else
						temporaryBlock.Size = Vector3.new(0.6, 8, 3)
						temporaryBlock.CFrame = CFrame.new(root.Position.X + 0.7, topHeight + 4.8, root.Position.Z)
					end
					temporaryBlock.Parent = workspace
					report.blocker = {path = temporaryBlock:GetFullName(), size = xyz(temporaryBlock.Size), position = xyz(temporaryBlock.Position)}
				end
			else
				local unaffected = resolve(course, options.unaffectedStandPath or "Obstacles/Gate/GateCourt/Contact")
				place(actors[2], standingFrame(unaffected, actors[2], options.unaffectedStandOffset), "Controlled unaffected parking", unaffected)
				target = resolve(course, assert(options.targetPath, "Name the actual red contact or SwingBand target"))
				if caseName == "red-body" then
					assert(target:IsA("BasePart") and target:GetAttribute("MoonlitHazard") == true and target.Transparency < 1
						and target:GetAttribute("Role") == "VisibleResetContact" and target.Material == Enum.Material.Neon, "Name actual visible red hazard")
					place(actors[1], target.CFrame * CFrame.new(0, actors[1].humanoid.HipHeight + actors[1].root.Size.Y / 2, 0), "Controlled body/red contact", target)
				else
					visible = assert(target:FindFirstChild("CageAndCore", true), "Name actual SwingBand model")
					local contact = assert(visible:FindFirstChildWhichIsA("BasePart", true), "Actual visible cage mesh absent")
					if caseName == "cage-body" then
						place(actors[1], contact.CFrame * CFrame.new(contact.Size.X * 0.35, 0, 0), "Controlled body/visible cage contact", contact)
					else
						local stand = resolve(course, assert(options.standPath, "Negative case requires a measured actual safe standing contact"))
						place(actors[1], standingFrame(stand, actors[1], options.standOffset), "Controlled safe body placement", stand)
						if caseName == "accessory-miss" then
							local accessory = own(Instance.new("Accessory"))
							accessory.Name = caseId .. "_Accessory"
							accessoryHandle = Instance.new("Part")
							accessoryHandle.Name, accessoryHandle.Size, accessoryHandle.CFrame = "Handle", Vector3.new(3, 3, 3), contact.CFrame
							accessoryHandle.CanCollide, accessoryHandle.CanTouch, accessoryHandle.CanQuery, accessoryHandle.Massless = false, false, true, true
							accessoryHandle.Color, accessoryHandle.Parent = Color3.fromRGB(193, 118, 225), accessory
							local head = assert(actors[1].character:FindFirstChild("Head"), "Actual accessory attachment Head absent")
							local headAttachment = own(Instance.new("Attachment"))
							headAttachment.Name, headAttachment.CFrame = caseId .. "_Attachment", head.CFrame:ToObjectSpace(contact.CFrame)
							headAttachment.Parent = head
							local handleAttachment = Instance.new("Attachment")
							handleAttachment.Name, handleAttachment.Parent = headAttachment.Name, accessoryHandle
							actors[1].humanoid:AddAccessory(accessory)
							-- Use the engine accessory joint; parenting an Accessory overrides a manual root weld.
							task.wait(0.1)
							local joint = assert(accessoryHandle:FindFirstChild("AccessoryWeld")
								or accessoryHandle:FindFirstChild("AccessoryRigidConstraint"), "Actual native accessory joint absent")
							local correctPair = if joint:IsA("Weld") then joint.Part0 == head and joint.Part1 == accessoryHandle
								elseif joint:IsA("RigidConstraint") then
									(joint.Attachment0 == headAttachment and joint.Attachment1 == handleAttachment)
									or (joint.Attachment1 == headAttachment and joint.Attachment0 == handleAttachment)
								else false
							assert(joint.Active and correctPair, "Actual native engine accessory attachment is not active")
							report.accessoryAttachment = {nativeJoint = joint:GetFullName(), root = xyz(actors[1].root.Position),
								handle = xyz(accessoryHandle.Position), target = xyz(contact.Position), active = joint.Active, className = joint.ClassName}
						end
					end
				end
				report.target = target:GetFullName()
			end
			report.afterPlacement = snapshot()
			local firstBody, firstAccessory = hazardContacts(actors[1], accessoryHandle)
			report.initialNativeOverlap = {bodyParts = firstBody, accessoryParts = firstAccessory}
			if caseName == "red-body" or caseName == "cage-body" then assert(firstBody > 0, "Controlled placement did not contact actual visible hazard geometry") end
			if caseName == "accessory-miss" then assert(firstBody == 0 and firstAccessory > 0, "Accessory-only visible cage contact was not established") end
			report.state, report.measurementStartedAt = "Running", workspace:GetServerTimeNow()
			report.measurementBefore = snapshot()
			if liftCase then
				for index, current in report.measurementBefore.players do
					assert(current.checkpoint == report.before.players[index].checkpoint and current.falls == report.before.players[index].falls,
						"Controlled setup changed actual progress/recovery before measurement")
				end
			end
			local measurementStart, lastSample = os.clock(), 0
			local baseline = report.before.players
			local function sample()
				guard()
				local row = {at = workspace:GetServerTimeNow(), elapsed = os.clock() - measurementStart, players = {}, deckY = deck and deck.Position.Y,
					phase = deck and deck.Parent:GetAttribute("MoonlitPhase")}
				if row.phase then phases[row.phase] = true end
				for index, actor in actors do
					local current, hit = state(actor), support(actor)
					assert(current.checkpoint == baseline[index].checkpoint, "Controlled case unexpectedly advanced checkpoint")
					local fallDelta = current.falls - baseline[index].falls
					local mustStay = index == 2 or caseName == "adjacent" or caseName == "light-miss" or caseName == "accessory-miss"
					assert(fallDelta == 0 or (not mustStay and fallDelta == 1), "Unexpected actual official recovery count")
					local relative = deck and deck.CFrame:PointToObjectSpace(actor.root.Position)
					local footGap = hit and (actor.root.Position.Y - hit.Position.Y - actor.humanoid.HipHeight - actor.root.Size.Y / 2)
					if deck and fallDelta == 0 then
						if not hit or hit.Instance ~= deck or math.abs(footGap) > 0.6 or hit.Normal.Y < 0.95 then supportMisses[index] += 1 end
						if not previousRelative[index] then previousRelative[index] = relative end
						maximumRelativeDrift[index] = math.max(maximumRelativeDrift[index] or 0, (relative - previousRelative[index]).Magnitude)
					end
					if index == 1 and fallDelta == 1 then
						if not firstRecovery then firstRecovery = os.clock(); report.recoveryServerTime = workspace:GetServerTimeNow(); report.recovery = current; dispose(temporaryBlock) end
						if os.clock() - firstRecovery >= 0.8 then
							if not recoverySettled then recoverySettled = actor.root.Position end
							finalPosition = actor.root.Position
						end
					end
					table.insert(row.players, {userId = current.userId, cp = current.checkpoint, falls = current.falls, status = current.status,
						root = current.root, support = hit and hit.Instance:GetFullName(), expectedDeck = deck and hit and hit.Instance == deck,
						footGap = footGap, supportNormal = hit and xyz(hit.Normal),
						floor = current.floorMaterial, humanoidState = current.humanoidState, jump = actor.humanoid.Jump,
						deckRelativeY = relative and relative.Y, relative = relative and xyz(relative)})
				end
				local bodyHits, handleHits = hazardContacts(actors[1], accessoryHandle)
				row.visibleBodyHits, row.accessoryHits = bodyHits, handleHits
				if bodyHits > 0 then bodyOverlapSamples += 1 end
				if handleHits > 0 then accessoryOverlaps += 1 end
				if caseName == "light-miss" or caseName == "accessory-miss" then assert(bodyHits == 0, "Negative case body touched actual visible cage") end
				if caseName == "light-miss" then
					local light = target:FindFirstChildWhichIsA("PointLight", true)
					assert(light and light.Enabled, "Actual enabled amber PointLight absent")
					row.inLightRange = (actors[1].root.Position - light.Parent.Position).Magnitude <= light.Range
					if row.inLightRange then lightExposureSamples += 1 end
				end
				table.insert(report.samples, row)
			end
			sample()
			connection = RunService.Heartbeat:Connect(function()
				if stopped or cancelled or report.failure then return end
				if os.clock() - lastSample < sampleInterval then return end
				lastSample = os.clock()
				local sampled, errorMessage = pcall(sample)
				if not sampled then report.failure = tostring(errorMessage) end
			end)
			repeat guard(); assert(not report.failure, report.failure or "Sample failed"); task.wait(0.025) until os.clock() - measurementStart >= duration
			connection:Disconnect(); connection = nil
			sample()
			report.measurementEndedAt = workspace:GetServerTimeNow()
			report.after = snapshot()
			report.supportMisses, report.maximumRelativeDrift, report.observedPhases = supportMisses, maximumRelativeDrift, phases
			report.accessoryOverlapSamples, report.lightExposureSamples, report.bodyOverlapSamples = accessoryOverlaps, lightExposureSamples, bodyOverlapSamples
			local positive = caseName == "overhead" or caseName == "side" or caseName == "red-body" or caseName == "cage-body"
			local delta = report.after.players[1].falls - report.before.players[1].falls
			assert(delta == (if positive then 1 else 0), "Expected actual recovery outcome did not occur")
			assert(report.after.players[2].falls == report.before.players[2].falls, "Unaffected actual rider recovered")
			if liftCase then
				report.serverPoseDisagreement = {rayMisses = supportMisses, maximumRelative3D = maximumRelativeDrift,
					claim = "Server pose versus current Deck; replication disagreement must be assessed against simultaneous native client rays"}
				if caseName == "adjacent" then
					assert(phases.Rising and phases.Descending and phases.LowDwell and phases.HighDwell, "Did not observe the full native cycle")
				else
					local blocker = report.after.diagnostics.lastBlocker
					assert(blocker and blocker.userId == ids[1] and blocker.part == report.blocker.path and blocker.recoveryAccepted,
						"Actual carry blocker/recovery did not match the genuine owned obstruction")
				end
				assert(report.after.diagnostics.stats.carriedSteps > report.measurementBefore.diagnostics.stats.carriedSteps, "No actual measured-window runtime carry steps recorded")
				report.measuredRuntimeDeltas = {}
				for _, key in {"supportChecks", "groundedRiders", "carriedSteps", "carryProbes", "blockedCarries", "recoveries", "hazardHits"} do
					report.measuredRuntimeDeltas[key] = report.after.diagnostics.stats[key] - report.measurementBefore.diagnostics.stats[key]
				end
			end
			if positive then
				assert(recoverySettled and finalPosition, "Recovery did not settle long enough to check stale carry")
				report.postRecoveryDrift = (finalPosition - recoverySettled).Magnitude
				assert(report.postRecoveryDrift < 0.6, "Actual recovered character drifted after recovery")
				local expected = services.CheckpointService.GetCheckpointRespawnCFrame(actors[1].player)
				assert(expected, "Actual saved checkpoint recovery pose absent")
				report.recoveryTarget = xyz(expected.Position)
				local difference = actors[1].root.Position - expected.Position
				assert(Vector3.new(difference.X, 0, difference.Z).Magnitude < 1.5 and math.abs(difference.Y) < 6, "Recovery did not return to actual saved checkpoint")
			end
			if caseName == "red-body" or caseName == "cage-body" then
				assert(report.after.diagnostics.stats.hazardHits > report.before.diagnostics.stats.hazardHits,
					"No actual runtime visible-hazard hit recorded alongside the official recovery")
			end
			if caseName == "accessory-miss" then assert(accessoryOverlaps > 0 or report.initialNativeOverlap.accessoryParts > 0, "No actual accessory-only overlap recorded") end
			if caseName == "light-miss" then assert(lightExposureSamples > 0, "No actual light-range exposure recorded") end
			if liftCase then
				report.state = "AwaitingClientEvidence"
				waitFor("Both native client reports covering exact measured window", function() return clientEvidence ~= nil end, 25)
			end
			report.state, report.passed = "Complete", true
		end, debug.traceback)
		stopped = true
		if not ok then report.failure, report.state, report.passed = tostring(reason), "Failed", false end
		report.elapsedSeconds = os.clock() - started
		local afterOk, after = pcall(snapshot)
		if afterOk then
			if report.after then report.cleanupSnapshot = after else report.after = after end
		else report.afterSnapshotFailure = tostring(after) end
		cleanup()
		local saved, saveError = pcall(persist)
		if not saved then report.storageFailure = tostring(saveError) end
	end)
	return handle
end

function Cases.Current() return latest end
function Cases.Debug() return latest end
function Cases.Stop(reason) if active then active.Stop(reason) end; return latest end
function Cases.Begin(entries) assert(active, "No active controlled case"); return active.Begin(entries) end
function Cases.SubmitClientEvidence(entries) assert(active, "No active controlled case"); return active.SubmitClientEvidence(entries) end

local function compactClientEnvelope(report)
	return {source = report.source, caseId = report.caseId, userId = report.userId, candidate = report.candidate,
		raceId = report.raceId, state = report.state, failure = report.failure, samples = {}}
end

function Cases.Readiness()
	assert(RunService:IsClient() and latest and latest.source == "native-client-contact-observer", "Require the actual client's current native observer")
	assert(#latest.samples >= 3, "Wait for three actual client samples")
	local compact = compactClientEnvelope(latest)
	for index = #latest.samples - 2, #latest.samples do table.insert(compact.samples, table.clone(latest.samples[index])) end
	return compact
end

function Cases.EvidenceSlice(startAt, endAt)
	assert(RunService:IsClient() and latest and latest.source == "native-client-contact-observer", "Require the actual client's current native observer")
	assert(finite(startAt) and finite(endAt) and endAt >= startAt, "Provide the actual measured server time window")
	local compact = compactClientEnvelope(latest)
	for _, sample in latest.samples do
		if sample.at >= startAt - 0.35 and sample.at <= endAt + 0.35 then table.insert(compact.samples, table.clone(sample)) end
	end
	compact.sliceStartAt, compact.sliceEndAt = startAt, endAt
	compact.rawSampleCount, compact.rawReportRetained = #latest.samples, true
	assert(#HttpService:JSONEncode(compact) < 95000, "Exact client window exceeds compact transport budget; retrieve/preserve raw JSON rather than truncating evidence")
	return compact
end

function Cases.ObserveClient(course, options)
	assert(RunService:IsStudio() and RunService:IsClient(), "Native Studio client observation only")
	assert(not active, "Stop the current local ContactCases observer first")
	options = options or {}
	local player = Players.LocalPlayer
	local character = assert(player.Character)
	local humanoid = assert(character:FindFirstChildOfClass("Humanoid"))
	local root = assert(character:FindFirstChild("HumanoidRootPart"))
	local deck = resolve(course, "Obstacles/MovingCars/" .. assert(options.stage) .. "_Bay" .. tostring(assert(options.bay)) .. "/Deck")
	local bridge = HttpService:JSONDecode(assert(player:GetAttribute("MCPhase2Progress")))
	local duration = options.durationSeconds or 90
	assert(finite(duration) and duration > 0 and duration <= 90, "Client observation duration must be at most90seconds")
	local report = {source = "native-client-contact-observer", caseId = assert(options.caseId), userId = player.UserId,
		candidate = course:GetAttribute("CandidateId"), raceId = bridge.raceId, state = "Observing", samples = {},
		startedAt = workspace:GetServerTimeNow(), deck = deck:GetFullName(), evidenceKind = "Actual native client read-only contact observation"}
	latest = report
	local function bodySnapshot()
		local parts = {}
		for _, part in character:GetChildren() do
			if part:IsA("BasePart") and (bodyNames[part.Name] or part.Name == "HumanoidRootPart") then
				table.insert(parts, {name = part.Name, size = xyz(part.Size), collidable = part.CanCollide, queryable = part.CanQuery,
					visible = part.Transparency < 1, localPose = {root.CFrame:ToObjectSpace(part.CFrame):GetComponents()}})
			end
		end
		return parts
	end
	report.initialBody = bodySnapshot()
	local connection, lastSample, handle = nil, 0, {}
	active = handle
	local function stop(reason)
		if connection then connection:Disconnect(); connection = nil end
		if active == handle then active = nil end
		report.failure, report.state, report.endedAt = reason, if reason then "Failed" else "Observed", workspace:GetServerTimeNow()
		if character.Parent and root.Parent then report.finalBody = bodySnapshot() end
	end
	connection = RunService.Heartbeat:Connect(function()
		if os.clock() - lastSample < 0.1 then return end
		lastSample = os.clock()
		local ok, reason = pcall(function()
			assert(player.Character == character and humanoid.Health > 0, "Observed native character replaced or died")
			local state = HttpService:JSONDecode(assert(player:GetAttribute("MCPhase2Progress")))
			assert(state.raceId == report.raceId and state.candidate == report.candidate and state.coursePath == course:GetFullName()
				and workspace:GetServerTimeNow() - state.observedAt <= 1.5, "Native observed shared race changed or bridge stale")
			local params, characters = RaycastParams.new(), {}
			for _, actual in Players:GetPlayers() do if actual.Character then table.insert(characters, actual.Character) end end
			params.FilterType, params.FilterDescendantsInstances, params.RespectCanCollide = Enum.RaycastFilterType.Exclude, characters, true
			local hit = workspace:Raycast(root.Position, Vector3.new(0, -(humanoid.HipHeight + root.Size.Y / 2 + 1), 0), params)
			table.insert(report.samples, {at = workspace:GetServerTimeNow(), raceId = state.raceId, status = state.status,
				official = state.official, cp = state.checkpoint, falls = state.falls, alive = humanoid.Health > 0,
				anchored = root.Anchored, position = xyz(root.Position), velocity = xyz(root.AssemblyLinearVelocity),
				deckY = deck.Position.Y, relative = xyz(deck.CFrame:PointToObjectSpace(root.Position)),
				support = hit and hit.Instance:GetFullName(), normalY = hit and hit.Normal.Y,
				footGap = hit and root.Position.Y - hit.Position.Y - humanoid.HipHeight - root.Size.Y / 2,
				floor = humanoid.FloorMaterial.Name, humanoidState = humanoid:GetState().Name, jump = humanoid.Jump})
			if workspace:GetServerTimeNow() - report.startedAt >= duration then stop() end
		end)
		if not ok then stop(tostring(reason)) end
	end)
	function handle.Stop(reason) stop(reason) end
	function handle.Debug() return report end
	return handle
end

return Cases
