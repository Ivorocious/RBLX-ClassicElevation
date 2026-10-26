--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Http = game:GetService("HttpService")
if not RunService:IsStudio() or not RunService:IsServer() then return end
local candidate = script.Parent.Parent
if not candidate:IsA("Model") or candidate:GetAttribute("KCPhase2SessionEnabled") ~= true then return end
local Progression = require(script.Parent.Progression)
local ForwardGate = require(script.Parent.ForwardGate)
local MechanismRuntime = require(script.Parent.MechanismRuntime)
local participants, previous, cooldowns, playerConnections, priorAttributes = {}, {}, {}, {}, {}
local records, gateRecords = {}, {}
local active = true
local lifecycle = 0
local runtime, heartbeat
local encodes, dirty, publishedAt = 0, true, -math.huge
local origin = candidate:GetAttribute("Origin")
local ray = RaycastParams.new()
ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {candidate}, true
local params = OverlapParams.new()
params.FilterType, params.RespectCanCollide = Enum.RaycastFilterType.Include, false
local staticShapes = {}
for _, item in candidate:GetDescendants() do
	if item:IsA("BasePart") and item:GetAttribute("Role") == "Lethal" and item:FindFirstAncestor("StaticHazards") then table.insert(staticShapes, item) end
	if item:IsA("Model") and item:GetAttribute("StaticHazard") then
		for _, part in item:GetDescendants() do if part:IsA("BasePart") and part:GetAttribute("Role") == "Lethal" then table.insert(staticShapes, part) end end
	end
end
local controlledAttributes = {"KCPhase2Candidate", "KCPhase2Lap", "KCPhase2CompletedLaps", "KCPhase2NextGate", "KCPhase2Finished", "KCPhase2Recoveries"}
local function append(list, value)
	table.insert(list, value)
	if #list > 128 then table.remove(list, 1) end
end
local function characterParts(player: Player)
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not character or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return nil end
	return character, root, humanoid
end
local function publishPlayer(player: Player)
	local state = participants[player]
	if not state then return end
	player:SetAttribute("KCPhase2Candidate", if active then candidate.Name else nil)
	player:SetAttribute("KCPhase2Lap", state.lap)
	player:SetAttribute("KCPhase2CompletedLaps", state.completedLaps)
	player:SetAttribute("KCPhase2NextGate", state.nextGate)
	player:SetAttribute("KCPhase2Finished", state.finished)
	player:SetAttribute("KCPhase2Recoveries", state.recoveries)
end
local function eligible(player: Player): boolean
	local state = participants[player]
	return active and state ~= nil and state.active and not state.finished
end
local function recoveryParts(player: Player, allowStopped: boolean?)
	local state = participants[player]
	local character, root = characterParts(player)
	if (not active and not allowStopped) or not state or not state.active or not character or not root
		or root.Anchored or player:GetAttribute("OnboardingReady") == false then return nil end
	local pad = candidate.RecoveryPads:FindFirstChild(state.recoveryGate)
	if pad and pad:IsA("Model") then pad = pad:FindFirstChild("BankContact") end
	if not pad or not pad:IsA("BasePart") or not pad.Anchored then return nil end
	local spawn = pad:GetAttribute("SpawnCFrame")
	if typeof(spawn) ~= "CFrame" then return nil end
	return character, root, spawn
end
local function recover(player: Player, reason: string, force: boolean?, allowStopped: boolean?): boolean
	local state = participants[player]
	local character, root, spawn = recoveryParts(player, allowStopped)
	if not character or not root then return false end
	local now = Workspace:GetServerTimeNow()
	if not force and now < (cooldowns[player] or 0) then return false end
	local selected, clearance = spawn, -math.huge
	for row = 1, 4 do
		for column = 1, 5 do
			local slot = spawn * CFrame.new((column - 3) * 4.5, 0, (row - 2.5) * 4)
			local minimum = math.huge
			for _, other in Players:GetPlayers() do
				if other == player then continue end
				local _, otherRoot = characterParts(other)
				if otherRoot then minimum = math.min(minimum, (otherRoot.Position - slot.Position).Magnitude) end
			end
			if minimum > clearance then selected, clearance = slot, minimum end
		end
	end
	character:PivotTo(selected)
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	previous[player], cooldowns[player] = nil, now + .7
	if reason ~= "Begin" then
		Progression.Recover(state, now)
		append(records, {userId = player.UserId, reason = reason, checkpoint = state.recoveryGate, lap = state.lap, at = now})
	end
	publishPlayer(player)
	dirty = true
	return true
end
local function leave(player: Player)
	participants[player], previous[player], cooldowns[player] = nil, nil, nil
	local watched = playerConnections[player]
	if watched then watched:Disconnect(); playerConnections[player] = nil end
	local original = priorAttributes[player]
	if original then for _, name in controlledAttributes do player:SetAttribute(name, original[name]) end end
	priorAttributes[player] = nil
	dirty = true
end
local function begin(player: Player, move: boolean): boolean
	local _, root = characterParts(player)
	if not active or not root or root.Anchored or player:GetAttribute("OnboardingReady") == false then return false end
	if not priorAttributes[player] then
		local original = {}
		for _, name in controlledAttributes do original[name] = player:GetAttribute(name) end
		priorAttributes[player] = original
	end
	local now = Workspace:GetServerTimeNow()
	local state = participants[player] or Progression.New(now)
	Progression.Begin(state, now)
	participants[player], previous[player], cooldowns[player] = state, nil, 0
	if not playerConnections[player] then
		playerConnections[player] = player.CharacterAdded:Connect(function(character)
			previous[player] = nil
			if not active then return end
			local beganLifecycle, beganGeneration = lifecycle, participants[player].generation
			task.spawn(function()
				if not active or lifecycle ~= beganLifecycle then return end
				local root = character:WaitForChild("HumanoidRootPart", 10)
				local humanoid = character:WaitForChild("Humanoid", 10)
				local current = participants[player]
				if active and lifecycle == beganLifecycle and root and humanoid and current
					and current.generation == beganGeneration and player.Character == character then recover(player, "Respawn", true) end
			end)
		end)
	end
	if move and not recover(player, "Begin", true) then leave(player); return false end
	publishPlayer(player)
	dirty = true
	return true
end
local function diagnostics()
	local now = Workspace:GetServerTimeNow()
	local states = {}
	for player, state in participants do states[tostring(player.UserId)] = Progression.Snapshot(state, now) end
	return {revision = candidate:GetAttribute("KCPhase2Revision"), active = active, realServer = RunService:IsServer(), participants = states, runtime = runtime and runtime.Diagnostics() or {}, recoveries = records, gates = gateRecords, diagnosticEncodes = encodes, staticShapes = #staticShapes}
end
local function publish(force: boolean?)
	local now = Workspace:GetServerTimeNow()
	if not force and now - publishedAt < (if dirty then .1 else 1) then return end
	encodes += 1
	publishedAt, dirty = now, false
	candidate:SetAttribute("KCPhase2ServerDiagnostics", Http:JSONEncode(diagnostics()))
end
local controls = Instance.new("Folder")
controls.Name, controls.Parent = "StudioProbeControls", candidate
local function event(name: string, callback)
	local signal = Instance.new("BindableEvent")
	signal.Name, signal.Parent = name, controls
	signal.Event:Connect(callback)
end
local getState = Instance.new("BindableFunction")
getState.Name, getState.OnInvoke, getState.Parent = "State", diagnostics, controls
local function connectHeartbeat()
	heartbeat = RunService.Heartbeat:Connect(function(dt: number)
		local now = Workspace:GetServerTimeNow()
		for _, player in Players:GetPlayers() do
			local _, root, humanoid = characterParts(player)
			if root and humanoid and not participants[player] and humanoid.FloorMaterial ~= Enum.Material.Air then
				local gate = candidate.Gates.F00
				local localPosition = gate.CFrame:PointToObjectSpace(root.Position)
				local support = Workspace:Raycast(root.Position, Vector3.new(0, -6.5, 0), ray)
				if math.abs(localPosition.X) < 17 and math.abs(localPosition.Z) < 17 and math.abs(localPosition.Y) < 4 and support then begin(player, true) end
			end
		end
		local characters = {}
		for player, state in participants do
			local character, root, humanoid = characterParts(player)
			if not root or not humanoid then previous[player] = nil; continue end
			if not state.active or state.finished then previous[player] = nil; continue end
			table.insert(characters, character)
			if root.Position.Y < origin.Y - 16 then recover(player, "Fall"); continue end
			local ground = Workspace:Raycast(root.Position, Vector3.new(0, -6.5, 0), ray)
			if humanoid.FloorMaterial ~= Enum.Material.Air and ground and ground.Instance:GetAttribute("Role") == "SolidBlocker" then recover(player, "SupportLanding"); continue end
			local old = previous[player]
			local gate = candidate.Gates:FindFirstChild(state.nextGate)
			if gate and gate:IsA("BasePart") and ground and ForwardGate.Crossed(gate.CFrame, gate.Size, old and old.position, root.Position, old and now - old.at or dt) then
				local change = Progression.Pass(state, gate.Name, now)
				if change.accepted then append(gateRecords, {userId = player.UserId, gate = gate.Name, reason = change.reason, lap = state.lap, completedLaps = state.completedLaps, at = now}); publishPlayer(player); dirty = true end
			end
			previous[player] = {position = root.Position, at = now}
		end
		params.FilterDescendantsInstances = characters
		if #characters > 0 then
			for _, shape in staticShapes do
				local nearby = false
				for player in participants do local _, root = characterParts(player); if eligible(player) and root and (root.Position - shape.Position).Magnitude < 12 then nearby = true; break end end
				if nearby then
					for _, body in Workspace:GetPartsInPart(shape, params) do
						if body:FindFirstAncestorWhichIsA("Accessory") then continue end
						local character = body:FindFirstAncestorOfClass("Model")
						local player = character and Players:GetPlayerFromCharacter(character)
						if player and eligible(player) then recover(player, "StaticKillContact") end
					end
				end
			end
		end
		publish()
	end)
end
runtime = MechanismRuntime.Start(candidate, eligible, recover)
connectHeartbeat()
event("Begin", function(userId: number) local player = Players:GetPlayerByUserId(userId); if player then begin(player, true) end end)
event("Leave", function(userId: number) local player = Players:GetPlayerByUserId(userId); if player then leave(player); publish(true) end end)
event("Stop", function()
	if not active then return end
	lifecycle += 1
	for player in participants do if eligible(player) then recover(player, "SessionStop", true) end end
	runtime.Stop()
	heartbeat:Disconnect()
	active = false
	candidate:SetAttribute("KCPhase2Stopped", true)
	for player in participants do player:SetAttribute("KCPhase2Candidate", nil) end
	publish(true)
end)
event("Restart", function()
	for player, state in participants do
		if state.active and characterParts(player) and not recoveryParts(player, true) then return end
	end
	for player in participants do if participants[player].active then recover(player, "SessionRestart", true, true) end end
	if active then runtime.Stop(); heartbeat:Disconnect() end
	lifecycle += 1
	active = true
	table.clear(previous)
	runtime = MechanismRuntime.Start(candidate, eligible, recover)
	connectHeartbeat()
	candidate:SetAttribute("KCPhase2RunId", (candidate:GetAttribute("KCPhase2RunId") or 0) + 1)
	candidate:SetAttribute("KCPhase2Stopped", false)
	for player in participants do publishPlayer(player) end
	publish(true)
end)
Players.PlayerRemoving:Connect(function(player)
 leave(player)
 publish(true)
end)
candidate.Destroying:Connect(function()
	if active then runtime.Stop(); heartbeat:Disconnect(); active = false end
	for player in participants do leave(player) end
end)
candidate:SetAttribute("KCPhase2RealServerStarted", true)
publish(true)

