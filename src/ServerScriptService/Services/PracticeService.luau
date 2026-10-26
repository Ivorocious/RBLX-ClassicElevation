--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Config.PracticeConfig)
local PracticeRun = require(ReplicatedStorage.Shared.PracticeRun)
local Builder = require(game:GetService("ServerStorage").CourseBuilders.LobbyBuilders.PracticeCircuit)
local Service = {}
local states: {[number]: any} = {}
local cooldowns: {[number]: number} = {}
local groundedSince: {[number]: number} = {}
local portalCooldowns: {[number]: number} = {}
local playerRaceService: any
local onboardingService: any
local stagingService: any
local circuit: Model?
local lobbyModel: Model?
local lobbyPortal: BasePart?
local unavailableReason = "Practice is preparing."
local initialized = false
local started = false
local changed: RemoteEvent?
local action: RemoteFunction?

local function now(): number return workspace:GetServerTimeNow() end
local function stateFor(player: Player): any
	local state = states[player.UserId]
	if not state then state = PracticeRun.New(); states[player.UserId] = state end
	return state
end
local function livingRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	return if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then root else nil
end
local function allowed(player: Player): boolean
	if player.Parent ~= Players then return false end
	if onboardingService and player:GetAttribute("OnboardingReady") ~= true then return false end
	if playerRaceService then
		if playerRaceService.IsOfficialRacer and playerRaceService.IsOfficialRacer(player) then
			if playerRaceService.GetPlayerStatus(player) == "Racing" then return false end
		end
		local status = playerRaceService.GetPlayerStatus(player)
		if status == "Queued" or status == "Racing" or status == "Spectating" or status == "LateRacing" or status == "GhostRacing" then return false end
	end
	return true
end
local function inRoom(root: BasePart): boolean
	if not circuit then return false end
	local center = circuit:GetAttribute("Center") :: Vector3
	local half = (circuit:GetAttribute("InteriorSize") :: Vector3) * 0.5
	local relative = root.Position - center
	return math.abs(relative.X) <= half.X + 1 and math.abs(relative.Z) <= half.Z + 1 and relative.Y >= -3 and relative.Y <= half.Y + 5
end
local function nearPad(root: BasePart, pad: BasePart): boolean
	local relative = pad.CFrame:PointToObjectSpace(root.Position)
	return math.abs(relative.X) <= pad.Size.X * 0.5 + Config.TouchDistanceMargin
		and math.abs(relative.Z) <= pad.Size.Z * 0.5 + Config.TouchDistanceMargin
		and relative.Y >= pad.Size.Y * 0.5 + 1 and relative.Y <= pad.Size.Y * 0.5 + 7
end
local function padFor(line: string, name: string): BasePart?
	local lane = if circuit then circuit:FindFirstChild(line) else nil
	local pad = if lane then lane:FindFirstChild(name) else nil
	return if pad and pad:IsA("BasePart") then pad else nil
end
local function publish(player: Player)
	local state = stateFor(player)
	state.activityRevision = (state.activityRevision or 0) + 1
	if changed and player.Parent == Players then changed:FireClient(player, Service.GetSnapshot(player)) end
	if playerRaceService and playerRaceService.PublishFlow then playerRaceService.PublishFlow(player) end
end
local function deliver(player: Player, pad: BasePart): boolean
	local root = livingRoot(player)
	if not root then return false end
	local spawn = pad.Position + Vector3.new(0, pad.Size.Y * 0.5 + Config.RecoveryOffset, 0)
	local line = pad:GetAttribute("PracticeLine")
	local index = pad:GetAttribute("PracticeIndex")
	local lane = if circuit and type(line) == "string" then circuit:FindFirstChild(line) else nil
	local padCount = if lane then lane:GetAttribute("PadCount") else nil
	local nextPad = nil
	if type(index) == "number" and type(padCount) == "number" and padCount > 0 then
		local nextIndex = (index + 1) % padCount
		nextPad = padFor(line, if nextIndex == 0 then "Start" else "Checkpoint" .. nextIndex)
	end
	if nextPad then
		local target = Vector3.new(nextPad.Position.X, spawn.Y, nextPad.Position.Z)
		root.CFrame = CFrame.lookAt(spawn, target)
	else
		root.CFrame = pad.CFrame + Vector3.new(0, Config.RecoveryOffset, 0)
	end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	groundedSince[player.UserId] = nil
	return true
end

function Service.GetSnapshot(player: Player): any
	local snapshot = PracticeRun.Snapshot(stateFor(player), now())
	snapshot.activityRevision = stateFor(player).activityRevision or 0
	snapshot.available = circuit ~= nil
	local root = livingRoot(player)
	snapshot.inRoom = root ~= nil and inRoom(root)
	snapshot.entranceCue = if snapshot.inRoom then "Choose Normal or Hard. Follow the numbered pads, then return through the lobby portal."
		else "Enter practice portal. Practice is in a separate area."
	snapshot.targetMinSeconds = Config.TargetMinSeconds
	snapshot.targetMaxSeconds = Config.TargetMaxSeconds
	local lane = if circuit then circuit:FindFirstChild(snapshot.line) else nil
	if lane then
		snapshot.lapCount = lane:GetAttribute("LapCount")
		snapshot.padCount = lane:GetAttribute("PadCount")
		snapshot.lap = math.min(snapshot.lapCount, math.floor((snapshot.nextCheckpoint - 1) / snapshot.padCount) + 1)
		local nextIndex = snapshot.nextCheckpoint % snapshot.padCount
		snapshot.nextPad = if nextIndex == 0 then "Start / Finish" else "Pad " .. nextIndex
	end
	if not circuit then snapshot.status = "Unavailable"; snapshot.message = unavailableReason end
	return snapshot
end
function Service.Enter(player: Player): (boolean, string)
	if not circuit or not lobbyModel then return false, unavailableReason or "Practice is unavailable." end
	if not allowed(player) or (playerRaceService and playerRaceService.GetPlayerStatus(player) ~= "Lobby") then
		return false, "Return to the lobby before going to practice."
	end
	local root = livingRoot(player)
	if not root then return false, "Your character isn't ready yet." end
	if not inRoom(root) then
		local frame, size = lobbyModel:GetBoundingBox()
		local relative = frame:PointToObjectSpace(root.Position)
		local half = size * 0.5 + Vector3.new(Config.LobbyEntryBoundMargin, Config.LobbyEntryBoundMargin, Config.LobbyEntryBoundMargin)
		if math.abs(relative.X) > half.X or math.abs(relative.Y) > half.Y or math.abs(relative.Z) > half.Z then
			return false, "Go to practice from the lobby."
		end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = {lobbyModel}
		params.RespectCanCollide = true
		if not workspace:Raycast(root.Position, Vector3.new(0, -Config.LobbyEntrySupportDepth, 0), params) then
			return false, "Stand on the lobby floor before going to practice."
		end
	end
	local pad = padFor("Normal", "Start")
	if not pad then return false, "Practice entrance is unavailable." end
	PracticeRun.Stop(stateFor(player), "Choose a practice line.")
	if not deliver(player, pad) then return false, "Your character isn't ready yet." end
	publish(player)
	return true, "You're in the practice area. Choose Normal or Hard."
end
function Service.Exit(player: Player): (boolean, string)
	local root = livingRoot(player)
	if not allowed(player) or not root or not inRoom(root)
		or (playerRaceService and playerRaceService.GetPlayerStatus(player) ~= "Lobby") then
		return false, "Return to lobby is available from the practice area."
	end
	if not stagingService or not stagingService.ReturnPlayersToLobby then return false, "Lobby return is unavailable." end
	PracticeRun.Stop(stateFor(player), "Practice ended; returning to lobby.")
	groundedSince[player.UserId] = nil
	stagingService.ReturnPlayersToLobby({player}, "Practice return portal")
	local currentRoot = livingRoot(player)
	local returned = currentRoot ~= nil and not inRoom(currentRoot)
	publish(player)
	return returned, if returned then "Returned to lobby." else "Lobby return is unavailable. Try the return portal again."
end
function Service.IsPracticing(player: Player): boolean
	return stateFor(player).status == "Running"
end
function Service.StartAttempt(player: Player, line: string): (boolean, string)
	if not circuit then return false, unavailableReason end
	if line ~= "Normal" and line ~= "Hard" then return false, "Choose Normal or Hard." end
	local root = livingRoot(player)
	if not allowed(player) or not root or not inRoom(root) then return false, "Enter practice portal before choosing a line." end
	local pad = padFor(line, "Start")
	local lane = circuit:FindFirstChild(line)
	if not pad or not lane or not deliver(player, pad) then return false, "Practice start is unavailable." end
	PracticeRun.Start(stateFor(player), line, lane:GetAttribute("CheckpointCount"), now())
	publish(player)
	return true, "Practice started."
end
function Service.Retry(player: Player): (boolean, string)
	return Service.StartAttempt(player, stateFor(player).line)
end
function Service.StopAttempt(player: Player, reason: string)
	PracticeRun.Stop(stateFor(player), reason)
	groundedSince[player.UserId] = nil
	publish(player)
end
function Service.InterruptForRace(player: Player)
	if Service.IsPracticing(player) then Service.StopAttempt(player, "Race departure") end
end

local function touch(player: Player, pad: BasePart)
	local root = livingRoot(player)
	if not root or not allowed(player) or not inRoom(root) or not nearPad(root, pad) then return end
	local state = stateFor(player)
	local line = pad:GetAttribute("PracticeLine")
	if pad.Name == "Start" and state.status ~= "Running" then
		if state.status ~= "Running" and state.autoStartBlocked ~= true then
			local previous = cooldowns[player.UserId] or 0
			if now() - previous >= Config.RequestCooldown then cooldowns[player.UserId] = now(); Service.StartAttempt(player, line) end
		end
		return
	end
	if state.status ~= "Running" or state.line ~= line then return end
	local index = pad:GetAttribute("PracticeIndex")
	local lane = circuit:FindFirstChild(line)
	local padCount = lane:GetAttribute("PadCount")
	if index ~= state.nextCheckpoint % padCount then return end
	local previousIndex = (index - 1) % padCount
	local previous = padFor(line, if previousIndex == 0 then "Start" else "Checkpoint" .. previousIndex)
	if not previous then return end
	local minimum = (pad.Position - previous.Position).Magnitude / Config.MaximumTravelSpeed
	local accepted = if index == 0 and state.nextCheckpoint > state.checkpointCount then PracticeRun.Finish(state, now(), minimum)
		else PracticeRun.Checkpoint(state, state.nextCheckpoint, now(), minimum)
	if accepted then publish(player) end
end

function Service.Init(context: any)
	if initialized then return end
	initialized = true
	playerRaceService = context.Services.PlayerRaceService
	onboardingService = context.Services.OnboardingService
	stagingService = context.Services.StagingService
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local function remote(name: string, className: string): Instance
		local existing = remotes:FindFirstChild(name)
		if existing then assert(existing.ClassName == className, "Wrong class for practice remote " .. name); return existing end
		local instance = Instance.new(className); instance.Name = name; instance.Parent = remotes; return instance
	end
	changed = remote(Config.RemoteNames.StateChanged, "RemoteEvent") :: RemoteEvent
	action = remote(Config.RemoteNames.Action, "RemoteFunction") :: RemoteFunction
end

function Service.Start()
	if started then return end
	started = true
	local lobby = workspace:FindFirstChild("Lobby")
	lobbyModel = if lobby and lobby:IsA("Model") then lobby else nil
	if Config.Enabled and lobby then circuit, unavailableReason, lobbyPortal = Builder.Ensure(lobby, Config) else unavailableReason = "Practice portal is unavailable." end
	if circuit then
		for _, descendant in ipairs(circuit:GetDescendants()) do
			if descendant:IsA("BasePart") and descendant:GetAttribute("PracticeIndex") ~= nil then
				descendant.Touched:Connect(function(part)
					local character = part:FindFirstAncestorOfClass("Model")
					local player = if character then Players:GetPlayerFromCharacter(character) else nil
					if player and character == player.Character and part:IsA("BasePart") and part.Parent == character then
						touch(player, descendant)
					end
				end)
			end
		end
	end
	local function bindPortal(portal: BasePart, actionName: string)
		portal.Touched:Connect(function(part)
			local character = part:FindFirstAncestorOfClass("Model")
			local player = if character then Players:GetPlayerFromCharacter(character) else nil
			if not player or character ~= player.Character or not part:IsA("BasePart") or part.Parent ~= character then return end
			local root = livingRoot(player)
			if not root then return end
			local relative = portal.CFrame:PointToObjectSpace(root.Position)
			local half = portal.Size * 0.5 + Vector3.new(Config.PortalTouchMargin, Config.PortalTouchMargin, Config.PortalTouchMargin)
			if math.abs(relative.X) > half.X or math.abs(relative.Y) > half.Y or math.abs(relative.Z) > half.Z then return end
			local at = now()
			if at - (portalCooldowns[player.UserId] or -math.huge) < Config.PortalCooldown then return end
			portalCooldowns[player.UserId] = at
			if actionName == "Enter" then Service.Enter(player) else Service.Exit(player) end
		end)
	end
	if lobbyPortal then bindPortal(lobbyPortal, "Enter") end
	local returnFolder = if circuit then circuit:FindFirstChild("ReturnPortal") else nil
	local returnPortal = if returnFolder then returnFolder:FindFirstChild("PortalTrigger") else nil
	if returnPortal and returnPortal:IsA("BasePart") then bindPortal(returnPortal, "Exit") end
	assert(action, "PracticeService.Init must run before Start")
	action.OnServerInvoke = function(player: Player, payload: any)
		local at = now()
		if at - (cooldowns[player.UserId] or 0) < Config.RequestCooldown then
			return {ok = false, message = "Please wait a moment.", practice = Service.GetSnapshot(player)}
		end
		cooldowns[player.UserId] = at
		if type(payload) ~= "table" then return {ok = false, message = "Invalid practice action.", practice = Service.GetSnapshot(player)} end
		local ok, message = false, "Invalid practice action."
		if payload.action == "Enter" then ok, message = Service.Enter(player)
		elseif payload.action == "Start" then ok, message = Service.StartAttempt(player, payload.line or "Normal")
		elseif payload.action == "Retry" then ok, message = Service.Retry(player)
		elseif payload.action == "Exit" then ok, message = Service.Exit(player) end
		return {ok = ok, message = message, practice = Service.GetSnapshot(player)}
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player.UserId] = nil; cooldowns[player.UserId] = nil; groundedSince[player.UserId] = nil; portalCooldowns[player.UserId] = nil
	end)
	local function bindPlayer(player: Player)
		player.CharacterRemoving:Connect(function()
			if Service.IsPracticing(player) then Service.StopAttempt(player, "Character reset; start again when ready.") end
		end)
	end
	Players.PlayerAdded:Connect(bindPlayer)
	for _, player in ipairs(Players:GetPlayers()) do bindPlayer(player) end
	local elapsed = 0
	RunService.Heartbeat:Connect(function(delta)
		elapsed += delta
		if elapsed < 0.1 then return end
		elapsed = 0
		local at = now()
		for _, player in ipairs(Players:GetPlayers()) do
			local state = states[player.UserId]
			if not state or state.status ~= "Running" then continue end
			local root = livingRoot(player)
			if not allowed(player) then Service.InterruptForRace(player)
			elseif not root or not inRoom(root) then Service.StopAttempt(player, "Practice ended; return to the room to retry.")
			elseif at - state.startedAt > Config.AttemptTimeout then Service.StopAttempt(player, "Practice timed out. Try again.")
			else
				local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
				local floorY = circuit:GetAttribute("FloorY")
				local groundParams = RaycastParams.new()
				groundParams.FilterType = Enum.RaycastFilterType.Exclude
				groundParams.FilterDescendantsInstances = {player.Character}
				groundParams.RespectCanCollide = true
				local ground = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), groundParams)
				local onFloor = humanoid.FloorMaterial ~= Enum.Material.Air and ground ~= nil and math.abs(ground.Position.Y - floorY) < 0.6
				local pastStart = (root.Position - padFor(state.line, "Start").Position).Magnitude > 6 or state.nextCheckpoint > 1
				if onFloor and pastStart then
					groundedSince[player.UserId] = groundedSince[player.UserId] or at
					if at - groundedSince[player.UserId] >= Config.FloorRecoverySeconds then
						local lane = circuit:FindFirstChild(state.line)
						local checkpointIndex = (state.nextCheckpoint - 1) % lane:GetAttribute("PadCount")
						local checkpoint = padFor(state.line, if checkpointIndex == 0 then "Start" else "Checkpoint" .. checkpointIndex)
						if checkpoint and deliver(player, checkpoint) then PracticeRun.Fall(state); publish(player) end
					end
				else groundedSince[player.UserId] = nil end
			end
		end
	end)
end

return Service
