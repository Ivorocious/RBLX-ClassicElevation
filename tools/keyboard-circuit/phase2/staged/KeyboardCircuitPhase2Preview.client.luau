--!strict
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer

local selected: Model? = nil
local selectedRun: any = nil
local cleanup: (() -> ())? = nil
local sequence = 0
local watches: {[Instance]: {RBXScriptConnection}} = {}
local scriptAlive = true
local unavailableCharacter: Model? = nil

local function start(candidate: Model, snapshot: Folder)
	local Feedback = require(snapshot.KeyboardCircuitFeedback)
	local Readiness = require(snapshot.Phase2Readiness)
	local Config = require(snapshot.ConfigSnapshot)
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	assert(playerGui, "Phase2 preview needs PlayerGui")
	sequence += 1
	local action = "KeyboardCircuitPhase2Loading_" .. sequence
	local status = Readiness.New(os.clock(), Config.AudioReadyTimeout)
	local feedback = Feedback.Start(candidate)
	local alive, holding = true, false
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "KeyboardCircuitPhase2Status", false, 81
	gui.Parent = playerGui
	local label = Instance.new("TextLabel")
	label.Name, label.Text = "Status", "Preparing key sounds…"
	label.AnchorPoint, label.Position = Vector2.new(.5, 1), UDim2.new(.5, 0, 1, -24)
	label.Size = UDim2.new(.60, 0, 0, 80)
	label.BackgroundColor3, label.TextColor3 = Color3.fromRGB(255, 248, 225), Color3.fromRGB(12, 30, 59)
	label.Font, label.TextSize, label.TextWrapped = Enum.Font.FredokaOne, 19, true
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 14), label
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize, bounds.Parent = Vector2.new(340, 80), label
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
	padding.Parent = label
	local lapGui = Instance.new("ScreenGui")
	lapGui.Name, lapGui.ResetOnSpawn, lapGui.DisplayOrder = "KeyboardCircuitPhase2Lap", false, 80
	lapGui.Parent = playerGui
	local lapLabel = Instance.new("TextLabel")
	lapLabel.Name = "Progress"
	lapLabel.AnchorPoint, lapLabel.Position = Vector2.new(.5, 1), UDim2.new(.5, 0, 1, -112)
	lapLabel.Size = UDim2.new(.52, 0, 0, 44)
	lapLabel.BackgroundColor3, lapLabel.TextColor3 = Color3.fromRGB(255, 248, 225), Color3.fromRGB(12, 30, 59)
	lapLabel.Font, lapLabel.TextSize, lapLabel.TextWrapped = Enum.Font.FredokaOne, 18, true
	lapLabel.Parent = lapGui
	local lapCorner = Instance.new("UICorner")
	lapCorner.CornerRadius, lapCorner.Parent = UDim.new(0, 12), lapLabel
	local lapBounds = Instance.new("UISizeConstraint")
	lapBounds.MaxSize, lapBounds.Parent = Vector2.new(280, 44), lapLabel
	local function updateLap()
		if player:GetAttribute("KCPhase2Finished") == true then lapLabel.Text = "Course complete · 3 laps"; return end
		local authoredLap = player:GetAttribute("KCPhase2Lap")
		local lap = if type(authoredLap) == "number" then math.clamp(math.floor(authoredLap), 1, 3) else 1
		local gate = player:GetAttribute("KCPhase2NextGate")
		local nextStep = if gate == "F00" then "Return to start" elseif gate == "F01" then "Finish this lap"
			else (if gate == "CP3" then "2" elseif gate == "CP2" then "1" else "0") .. "/3 checkpoints"
		lapLabel.Text = "Lap " .. lap .. " of 3 · " .. nextStep
	end
	local lapConnections = {}
	for _, name in {"KCPhase2Lap", "KCPhase2CompletedLaps", "KCPhase2NextGate", "KCPhase2Finished", "KCPhase2Recoveries"} do
		table.insert(lapConnections, player:GetAttributeChangedSignal(name):Connect(updateLap))
	end
	updateLap()
	local ray = RaycastParams.new()
	ray.FilterType, ray.FilterDescendantsInstances, ray.RespectCanCollide = Enum.RaycastFilterType.Include, {candidate}, true
	local function safeSupport(): boolean
		local pads = candidate:FindFirstChild("RecoveryPads")
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if not pads or not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then return false end
		local state = humanoid:GetState()
		if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall or humanoid.FloorMaterial == Enum.Material.Air then return false end
		local hit = Workspace:Raycast(root.Position, Vector3.new(0, -6.5, 0), ray)
		return hit ~= nil and hit.Normal.Y > .65 and hit.Instance.Anchored and hit.Instance:IsDescendantOf(pads)
	end
	local function release()
		if not holding then return end
		holding = false
		ContextActionService:UnbindAction(action)
		RunService:UnbindFromRenderStep(action)
	end
	local function hold()
		if holding then return end
		holding = true
		ContextActionService:BindActionAtPriority(action, function() return Enum.ContextActionResult.Sink end, false, 5000,
			Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
			Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
		RunService:BindToRenderStep(action, Enum.RenderPriority.Input.Value + 1, function()
			if not alive or not safeSupport() then release(); return end
			local character = player.Character
			local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
			if humanoid then humanoid:Move(Vector3.zero); humanoid.Jump = false end
		end)
	end
	local function finish()
		if not alive then return end
		alive = false
		Readiness.Cancel(status, "selection")
		release()
		feedback.Stop()
		for _, connection in lapConnections do connection:Disconnect() end
		gui:Destroy()
		lapGui:Destroy()
	end
	cleanup = finish
	task.spawn(function()
		while alive do
			local ok, audio = pcall(feedback.Readiness)
			if not ok then audio = {state = "degraded", reason = "feedback"} end
			local result = Readiness.Step(status, os.clock(), audio, safeSupport())
			if result.holding then hold() else release() end
			gui:SetAttribute("ReadinessState", result.state)
			gui:SetAttribute("HoldingMovement", holding)
			gui:SetAttribute("LoadedClips", result.loaded)
			gui:SetAttribute("Elapsed", result.elapsed)
			if result.state ~= "loading" then
				if result.state == "degraded" then
					label.Text = "Some key sounds could not load. You can still play."
					task.delay(3, function()
						if alive then gui:Destroy(); lapLabel.Position = UDim2.new(.5, 0, 1, -24) end
					end)
				else gui:Destroy(); lapLabel.Position = UDim2.new(.5, 0, 1, -24) end
				return
			end
			label.Text = if holding then "Preparing key sounds…" else "Preparing key sounds… You can keep moving."
			task.wait(.05)
		end
	end)
end

local function refresh()
	if not scriptAlive then return end
	local wanted = player:GetAttribute("KCPhase2Candidate")
	local found: Model? = nil
	local count = 0
	if type(wanted) == "string" then
		for _, child in Workspace:GetChildren() do
			if child:IsA("Model") and child.Name == wanted and child:GetAttribute("CourseId") == "keyboard-circuit-phase2"
				and child:GetAttribute("KCPhase2PreviewEnabled") == true then
				found, count = child, count + 1
			end
		end
	end
	if count ~= 1 then found = nil end
	if player.Character == nil or player.Character == unavailableCharacter or not player:FindFirstChildOfClass("PlayerGui") then found = nil end
	local run = if found then found:GetAttribute("KCPhase2RunId") else nil
	local snapshot = if found then found:FindFirstChild("SourceSnapshot") else nil
	if found and (not snapshot or not snapshot:IsA("Folder")) then found = nil end
	if found and snapshot then
		for _, name in {"KeyboardCircuitAudio", "KeyboardCircuitFeedback", "Phase2Readiness", "ConfigSnapshot"} do
			local module = snapshot:FindFirstChild(name)
			if not module or not module:IsA("ModuleScript") then found = nil; break end
		end
	end
	if found == selected and run == selectedRun then return end
	if cleanup then cleanup(); cleanup = nil end
	selected, selectedRun = found, run
	if found and snapshot then
		local ok, err = pcall(start, found, snapshot :: Folder)
		if not ok then
			if cleanup then cleanup(); cleanup = nil end
			warn("[KeyboardCircuit Phase2] Feedback could not start: " .. tostring(err))
		end
	end
end

local function watch(child: Instance)
	if not scriptAlive or not child:IsA("Model") then return end
	local connections = {
		child:GetAttributeChangedSignal("CourseId"):Connect(refresh),
		child:GetAttributeChangedSignal("KCPhase2PreviewEnabled"):Connect(refresh),
		child:GetAttributeChangedSignal("KCPhase2RunId"):Connect(refresh),
		child.DescendantAdded:Connect(function(item) if item:IsA("ModuleScript") or item.Name == "SourceSnapshot" then refresh() end end),
		child.DescendantRemoving:Connect(function(item)
			if selected == child and (item:IsA("ModuleScript") or item.Name == "SourceSnapshot") then
				if cleanup then cleanup(); cleanup = nil end
				selected, selectedRun = nil, nil
			end
		end),
	}
	watches[child] = connections
end

local connections = {
	Workspace.ChildAdded:Connect(function(child) watch(child); refresh() end),
	Workspace.ChildRemoved:Connect(function(child)
		local watched = watches[child]
		if watched then for _, connection in watched do connection:Disconnect() end; watches[child] = nil end
		refresh()
	end),
	player:GetAttributeChangedSignal("KCPhase2Candidate"):Connect(refresh),
	player.CharacterRemoving:Connect(function(character)
		unavailableCharacter = character
		if cleanup then cleanup(); cleanup = nil end
		selected, selectedRun = nil, nil
	end),
	player.CharacterAdded:Connect(function() unavailableCharacter = nil; refresh() end),
	player.ChildAdded:Connect(function(child) if child:IsA("PlayerGui") then refresh() end end),
}
script.Destroying:Connect(function()
	scriptAlive = false
	if cleanup then cleanup(); cleanup = nil end
	for _, connection in connections do connection:Disconnect() end
	for _, connections in watches do for _, connection in connections do connection:Disconnect() end end
end)
for _, child in Workspace:GetChildren() do watch(child) end
refresh()
