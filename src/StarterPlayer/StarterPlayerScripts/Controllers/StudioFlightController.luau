--!strict

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage.Config.StudioFlightConfig)
local Flight = {}
local initialized = false
local focused = true
local button: TextButton? = nil
local hint: TextLabel? = nil

type FlightState = {
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	attachment: Attachment,
	velocity: LinearVelocity,
	orientation: AlignOrientation,
	autoRotate: boolean,
	platformStand: boolean,
	died: RBXScriptConnection?,
}

local current: FlightState? = nil
local movementAction = "StudioFlightMovement"

local function refreshButton()
	if button then
		button.Text = string.format("Fly [%s]: %s", Config.ToggleKey.Name, if current then "ON" else "OFF")
		button.BackgroundColor3 = if current then Color3.fromRGB(38, 111, 92) else Color3.fromRGB(55, 68, 86)
	end
	if hint then hint.Visible = current ~= nil end
end

local function stopFlying()
	local state = current
	if not state then return end
	current = nil
	ContextActionService:UnbindAction(movementAction)
	if state.died then state.died:Disconnect() end
	state.velocity:Destroy()
	state.orientation:Destroy()
	state.attachment:Destroy()
	if state.root.Parent then
		state.root.AssemblyLinearVelocity = Vector3.zero
		state.root.AssemblyAngularVelocity = Vector3.zero
	end
	if state.humanoid.Parent then
		state.humanoid.AutoRotate = state.autoRotate
		state.humanoid.PlatformStand = state.platformStand
		if state.humanoid.Health > 0 and not state.platformStand then
			state.humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
	refreshButton()
end

function Flight.IsFlying(): boolean
	return current ~= nil
end

function Flight.SetFlying(enabled: boolean): boolean
	-- Guard the callable controller as well as its Studio-only entry script.
	if not RunService:IsStudio() or not RunService:IsClient() then return false end
	if not enabled then stopFlying(); return true end
	if current then return true end

	local character = Players.LocalPlayer.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or not humanoid or humanoid.Health <= 0 or humanoid.Sit
		or not root or not root:IsA("BasePart") or root.Anchored then
		return false
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "StudioFlightAttachment"
	attachment.Parent = root
	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "StudioFlightVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.ForceLimitsEnabled = false
	velocity.VectorVelocity = Vector3.zero
	velocity.Parent = root
	local orientation = Instance.new("AlignOrientation")
	orientation.Name = "StudioFlightOrientation"
	orientation.Attachment0 = attachment
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.RigidityEnabled = true
	orientation.CFrame = root.CFrame.Rotation
	orientation.Parent = root

	local state: FlightState = {
		character = character, humanoid = humanoid, root = root,
		attachment = attachment, velocity = velocity, orientation = orientation,
		autoRotate = humanoid.AutoRotate, platformStand = humanoid.PlatformStand,
		died = nil,
	}
	current = state
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	humanoid.Jump = false
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	state.died = humanoid.Died:Connect(stopFlying)
	ContextActionService:BindActionAtPriority(movementAction, function()
		return if UserInputService:GetFocusedTextBox() then Enum.ContextActionResult.Pass else Enum.ContextActionResult.Sink
	end, false, Enum.ContextActionPriority.High.Value + 1,
		Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
		Config.UpKey, Config.DownKey, Config.FastKey)
	refreshButton()
	return true
end

local function held(key: Enum.KeyCode): number
	return if UserInputService:IsKeyDown(key) then 1 else 0
end

local function updateFlight()
	local state = current
	if not state then return end
	if Players.LocalPlayer.Character ~= state.character or not state.root.Parent
		or state.root.Anchored or state.humanoid.Health <= 0 or state.humanoid.Sit then
		stopFlying()
		return
	end
	local camera = Workspace.CurrentCamera
	if not focused or not camera or UserInputService:GetFocusedTextBox() or GuiService.MenuIsOpen then
		state.velocity.VectorVelocity = Vector3.zero
		return
	end

	local movement = camera.CFrame.LookVector * (held(Enum.KeyCode.W) - held(Enum.KeyCode.S))
		+ camera.CFrame.RightVector * (held(Enum.KeyCode.D) - held(Enum.KeyCode.A))
		+ Vector3.yAxis * (held(Config.UpKey) - held(Config.DownKey))
	local speed = if held(Config.FastKey) == 1 then Config.FastSpeed else Config.Speed
	state.velocity.VectorVelocity = if movement.Magnitude > 0 then movement.Unit * speed else Vector3.zero
	local forward = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
	if forward.Magnitude > 0.001 then
		state.orientation.CFrame = CFrame.lookAt(Vector3.zero, forward.Unit)
	end
end

function Flight.Init()
	if initialized or not RunService:IsStudio() or not RunService:IsClient() then return end
	initialized = true
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "StudioFlightControls"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local toggle = Instance.new("TextButton")
	toggle.Name = "ToggleFlight"
	toggle.AnchorPoint = Vector2.new(1, 0)
	toggle.Position = UDim2.new(1, -32, 0, 398)
	toggle.Size = UDim2.fromOffset(180, 32)
	toggle.BorderSizePixel = 0
	toggle.Font = Enum.Font.Gotham
	toggle.TextSize = 14
	toggle.TextColor3 = Color3.new(1, 1, 1)
	toggle.Parent = gui
	button = toggle
	local controls = Instance.new("TextLabel")
	controls.Name = "Controls"
	controls.AnchorPoint = Vector2.new(1, 0)
	controls.Position = UDim2.new(1, -32, 0, 434)
	controls.Size = UDim2.fromOffset(180, 48)
	controls.BackgroundColor3 = Color3.fromRGB(25, 28, 34)
	controls.BackgroundTransparency = 0.1
	controls.BorderSizePixel = 0
	controls.Font = Enum.Font.Gotham
	controls.TextSize = 12
	controls.TextColor3 = Color3.new(1, 1, 1)
	controls.Text = "WASD move | Space up\nCtrl down | Shift faster\nStudio testing only"
	controls.Parent = gui
	hint = controls
	refreshButton()
	toggle.Activated:Connect(function() Flight.SetFlying(not Flight.IsFlying()) end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and not UserInputService:GetFocusedTextBox() and not GuiService.MenuIsOpen
			and input.KeyCode == Config.ToggleKey then
			Flight.SetFlying(not Flight.IsFlying())
		end
	end)
	UserInputService.WindowFocusReleased:Connect(function()
		focused = false
		if current then current.velocity.VectorVelocity = Vector3.zero end
	end)
	UserInputService.WindowFocused:Connect(function() focused = true end)
	player.CharacterRemoving:Connect(stopFlying)
	RunService.PreSimulation:Connect(updateFlight)
end

return Flight
