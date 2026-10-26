--!strict
if not game:GetService("RunService"):IsStudio() then return end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local Feedback = require(script.Parent.Controllers.KeyboardCircuitFeedback)
local root, controller
local sequence, clearLoading = 0, nil
local function beginLoading(candidate: Model, current: any)
	sequence += 1
	local action = "KeyboardCircuitLoading" .. sequence
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "KeyboardCircuitLoading", false, 81
	gui.Parent = player.PlayerGui
	local label = Instance.new("TextLabel")
	label.Name, label.Text = "Status", "Preparing key sounds…"
	label.AnchorPoint, label.Position, label.Size = Vector2.new(.5, 1), UDim2.fromScale(.5, .94), UDim2.new(.86, 0, 0, 64)
	label.BackgroundColor3, label.TextColor3 = Color3.fromRGB(255, 248, 225), Color3.fromRGB(12, 30, 59)
	label.Font, label.TextSize, label.TextWrapped = Enum.Font.FredokaOne, 19, true
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 14), label
	local bounds = Instance.new("UISizeConstraint")
	bounds.MaxSize, bounds.Parent = Vector2.new(360, 64), label
	local alive, holding = true, true
	ContextActionService:BindActionAtPriority(action, function() return Enum.ContextActionResult.Sink end, false, 5000,
		Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
	-- Override movement after normal input without changing another screen's control state.
	RunService:BindToRenderStep(action, Enum.RenderPriority.Input.Value + 1, function()
		local character = player.Character
		local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
		if humanoid then humanoid:Move(Vector3.zero); humanoid.Jump = false end
	end)
	local function releaseMovement()
		if not holding then return end
		holding = false
		ContextActionService:UnbindAction(action)
		RunService:UnbindFromRenderStep(action)
	end
	local function cleanup()
		if not alive then return end
		alive = false
		releaseMovement()
		gui:Destroy()
	end
	clearLoading = cleanup
	task.spawn(function()
		local result = current.AwaitReady(function() return not alive or root ~= candidate or not candidate.Parent end)
		if not alive then return end
		releaseMovement()
		if result.state == "degraded" then
			label.Text = "Some key sounds could not load. You can still play."
			task.delay(3, cleanup)
		else cleanup() end
	end)
end
local function refresh()
	local found
	for _,model in workspace:GetChildren() do
		if model:IsA("Model") and model:GetAttribute("CourseId") == "keyboard-circuit" and model:GetAttribute("KCSessionEnabled") == true then found = model; break end
	end
	if found == root then return end
	if clearLoading then clearLoading(); clearLoading = nil end
	if controller then controller.Stop() end
	local snapshot = if found then found:FindFirstChild("SourceSnapshot") else nil
	local frozenFeedback = if snapshot then snapshot:FindFirstChild("KeyboardCircuitFeedback") else nil
	local implementation = if frozenFeedback and frozenFeedback:IsA("ModuleScript") then require(frozenFeedback) else Feedback
	root, controller = found, if found then implementation.Start(found) else nil
	if found and controller then beginLoading(found, controller) end
end
workspace.ChildAdded:Connect(refresh)
workspace.ChildRemoved:Connect(refresh)
refresh()
