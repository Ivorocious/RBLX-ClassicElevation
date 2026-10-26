--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Http = game:GetService("HttpService")
if not RunService:IsStudio() or not RunService:IsServer() then return end
local candidate = script.Parent.Parent
if not candidate:IsA("Model") or candidate:GetAttribute("KCSessionEnabled") ~= true then return end
local participants, cooldowns, records = {}, {}, {}
local sample = candidate.S02_ThockySwitchworks
local diagnosticsDirty, diagnosticsAt, diagnosticEncodes = true, -math.huge, 0
local diagnosticStates = {}
local supportRay = RaycastParams.new()
supportRay.FilterType, supportRay.FilterDescendantsInstances, supportRay.RespectCanCollide = Enum.RaycastFilterType.Include, {sample}, true
local function eligible(player: Player): boolean return participants[player] ~= nil end
local function recover(player: Player, reason: string): boolean
	local state = participants[player]
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not state or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return false end
	local now = Workspace:GetServerTimeNow()
	if (cooldowns[player] or 0) > now then return false end
	cooldowns[player] = now + .7
	local cf
	if state.mode == "Shuttle" then cf = candidate.H06_EarlyProof.CP2_DepartureDock:GetAttribute("TopPosition")
	elseif state.mode == "Study" then
		local id = if state.cp == 0 then "F00" else "CP" .. state.cp
		cf = candidate.CheapWholeRouteStudy[id].PrimaryPart.Position + Vector3.new(0, .5, 0)
	else cf = sample[if state.cp == 2 then "CP2_Recovery" else "CP1_Recovery"]:GetAttribute("TopPosition") end
	root.Anchored = false
	root.CFrame = CFrame.new(cf + Vector3.new(-3, 3.2, 3))
	root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
	if reason ~= "Begin" then table.insert(records, {userId = player.UserId, reason = reason, cp = state.cp, mode = state.mode, at = now}) end
	diagnosticsDirty = true
	return true
end
local runtime = require(script.Parent.Runtime).Start(candidate, eligible, recover)
local function publishDiagnostics(now: number, force: boolean?)
	if not force and not diagnosticsDirty and now - diagnosticsAt < .1 then return end
	diagnosticsAt, diagnosticsDirty = now, false
	diagnosticEncodes += 1
	table.clear(diagnosticStates)
	for player,state in participants do diagnosticStates[tostring(player.UserId)] = state end
	candidate:SetAttribute("KCServerDiagnostics", Http:JSONEncode({runtime = runtime.Diagnostics(), recoveries = records, participants = diagnosticStates, realServer = RunService:IsServer(), diagnosticEncodes = diagnosticEncodes}))
end
local controls = Instance.new("Folder")
controls.Name, controls.Parent = "StudioProbeControls", candidate
local function event(name: string, callback): BindableEvent
	local signal = Instance.new("BindableEvent")
	signal.Name, signal.Parent = name, controls
	signal.Event:Connect(callback)
	return signal
end
event("Begin", function(userId: number, mode: string)
	if mode ~= "Sample" and mode ~= "Shuttle" and mode ~= "Study" then return end
	local player = Players:GetPlayerByUserId(userId)
	if not player or not player.Character then return end
	participants[player] = {mode = mode, cp = if mode == "Study" then 0 else if mode == "Shuttle" then 2 else 1, laps = 0, began = Workspace:GetServerTimeNow(), insideGate = false}
	cooldowns[player] = 0
	recover(player, "Begin")
	diagnosticsDirty = true
end)
local heartbeat: RBXScriptConnection
heartbeat = RunService.Heartbeat:Connect(function()
	for _,player in Players:GetPlayers() do
		if participants[player] then continue end
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if not root or not root:IsA("BasePart") or not humanoid or humanoid.FloorMaterial == Enum.Material.Air then continue end
		local top = sample.CP1_Recovery:GetAttribute("TopPosition")
		if math.abs(root.Position.X - top.X) < 7 and math.abs(root.Position.Z - top.Z) < 7 and root.Position.Y > top.Y and root.Position.Y < top.Y + 7 then
			participants[player] = {mode = "Sample", cp = 1, laps = 0, began = Workspace:GetServerTimeNow(), insideGate = false}
			diagnosticsDirty = true
		end
	end
	for player,state in participants do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if not root or not root:IsA("BasePart") or not humanoid then continue end
		if root.Position.Y < 318 then recover(player, "Fall") end
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			if state.mode == "Sample" then
				local ground = Workspace:Raycast(root.Position, Vector3.new(0, -6, 0), supportRay)
				if ground and ground.Instance:GetAttribute("Role") == "SolidBlocker" then recover(player, "SupportLanding"); continue end
			end
			if state.mode == "Sample" and state.cp == 1 then
				local top = sample.CP2_Recovery:GetAttribute("TopPosition")
				if math.abs(root.Position.X - top.X) < 7 and math.abs(root.Position.Z - top.Z) < 7 and root.Position.Y > top.Y and root.Position.Y < top.Y + 7 then state.cp = 2; diagnosticsDirty = true end
			elseif state.mode == "Study" and not state.finished then
				local id = if state.cp < 3 then "CP" .. (state.cp + 1) else "F00"
				local bank = candidate.CheapWholeRouteStudy[id].PrimaryPart
				local point = bank.CFrame:PointToObjectSpace(root.Position)
				local inside = math.abs(point.X) < bank.Size.X / 2 and math.abs(point.Z) < bank.Size.Z / 2 and point.Y > 0 and point.Y < 7
				if inside and not state.insideGate then
					if state.cp == 3 then state.laps += 1; state.cp = 0; state.finished = state.laps >= 3 else state.cp += 1 end
					diagnosticsDirty = true
				end
				if inside ~= state.insideGate then diagnosticsDirty = true end
				state.insideGate = inside
			end
		end
	end
	publishDiagnostics(Workspace:GetServerTimeNow())
end)
event("Stop", function()
	runtime.Stop()
	heartbeat:Disconnect()
	candidate:SetAttribute("KCSessionStopped", true)
	publishDiagnostics(Workspace:GetServerTimeNow(), true)
end)
candidate:SetAttribute("KCRealServerStarted", true)

