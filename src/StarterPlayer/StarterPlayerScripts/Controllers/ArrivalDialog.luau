--!strict
-- Confirmation card for the arrival choice: night glass with a cyan rim (matching the choice bar),
-- a bold question, a reassurance line and Back / confirm pills. While it is open it stands in for
-- the choice bar, which hides so no edges peek out around it.
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local View = require(script.Parent.ArrivalView)
local Dialog = {}

local NIGHT = Color3.fromRGB(12, 20, 44)
local MUTED = Color3.fromRGB(159, 186, 224)

local function pill(button: TextButton)
	button.Corners.CornerRadius = UDim.new(0.5, 0)
	button.Font, button.AutoButtonColor = Enum.Font.GothamBlack, false
	button.TextLimit.MaxTextSize = 19
end

function Dialog.Create(parent, preview: boolean?, dock: GuiObject?)
	local overlay = View.Make("TextButton", "ArrivalDialog", parent, {Size = UDim2.fromScale(1,1),
		BackgroundColor3 = Color3.fromRGB(0,2,8), BackgroundTransparency = 0.45, BorderSizePixel = 0,
		Text = "", AutoButtonColor = false, Selectable = false, Active = true, Visible = false, ZIndex = 20})
	local panel = View.Make("Frame", "Panel", overlay, {AnchorPoint = Vector2.new(0.5,1), BackgroundColor3 = NIGHT,
		BackgroundTransparency = 0.04, BorderSizePixel = 0,
		SelectionGroup = true, SelectionBehaviorUp = Enum.SelectionBehavior.Stop, SelectionBehaviorDown = Enum.SelectionBehavior.Stop,
		SelectionBehaviorLeft = Enum.SelectionBehavior.Stop, SelectionBehaviorRight = Enum.SelectionBehavior.Stop})
	View.Round(panel, 26)
	View.Make("UIStroke", "Rim", panel, {Color = View.Cyan, Thickness = 2, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	View.Make("UIGradient", "Glass", panel, {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255,255,255), Color3.fromRGB(196,210,235))})
	local caption = View.Text("Caption", panel, "YOUR RACER", UDim2.new(1,-56,0,16), UDim2.fromOffset(28,24))
	caption.Font, caption.TextColor3, caption.TextLimit.MaxTextSize = Enum.Font.GothamBold, View.Cyan, 13
	caption.TextXAlignment = Enum.TextXAlignment.Left
	local message = View.Text("Message", panel, "", UDim2.new(1,-56,0,40), UDim2.fromOffset(28,44))
	message.TextColor3, message.Font, message.TextLimit.MaxTextSize = Color3.new(1,1,1), Enum.Font.LuckiestGuy, 32
	message.TextXAlignment = Enum.TextXAlignment.Left
	local note = View.Text("Note", panel, "", UDim2.new(1,-56,0,18), UDim2.fromOffset(28,88))
	note.Font, note.TextColor3, note.TextLimit.MaxTextSize = Enum.Font.GothamMedium, MUTED, 15
	note.TextXAlignment = Enum.TextXAlignment.Left
	local cancel = View.Button("Cancel", panel, "Back", UDim2.new(0.36,-28,0,52), UDim2.new(0,28,1,-76), true)
	pill(cancel)
	cancel.BackgroundColor3, cancel.BackgroundTransparency, cancel.TextColor3 = Color3.new(1,1,1), 0.92, Color3.fromRGB(221,232,255)
	View.Make("UIStroke", "Edge", cancel, {Color = Color3.new(1,1,1), Transparency = 0.7, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	local confirm = View.Button("Confirm", panel, "Confirm", UDim2.new(0.64,-42,0,52), UDim2.new(0.36,14,1,-76))
	pill(confirm)
	confirm.BackgroundColor3, confirm.TextColor3 = Color3.new(1,1,1), View.Ink
	local confirmFill = View.Make("UIGradient", "Fill", confirm, {Color = ColorSequence.new(View.Mint, View.Cyan)})
	cancel.NextSelectionRight, confirm.NextSelectionLeft = confirm, cancel
	for _, button in {cancel, confirm} do
		local scale = View.Make("UIScale", "Hover", button)
		button.MouseEnter:Connect(function() TweenService:Create(scale, TweenInfo.new(0.14, Enum.EasingStyle.Back), {Scale = 1.04}):Play() end)
		button.MouseLeave:Connect(function() TweenService:Create(scale, TweenInfo.new(0.14), {Scale = 1}):Play() end)
	end
	local callback, previousFocus, locked = nil, nil, false
	local motion, entrance = true, nil
	local restingPosition = UDim2.new(0.5,0,1,-40)
	local function layout()
		local compact = parent.AbsoluteSize.X < 500
		local width = math.min(600, parent.AbsoluteSize.X - 32)
		panel.Size = UDim2.fromOffset(width, if compact then 230 else 206)
		message.Size = UDim2.new(1,-56,0,if compact then 64 else 40)
		note.Position = UDim2.fromOffset(28, if compact then 112 else 88)
		restingPosition = UDim2.new(0.5,0,1,if compact then -24 else -40)
		if entrance then entrance:Cancel() end
		panel.Position = restingPosition
	end
	parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	local function setOpen(open: boolean)
		overlay.Visible = open
		if dock then dock.Visible = not open end
	end
	local function close()
		if entrance then entrance:Cancel() end
		setOpen(false)
		callback, locked = nil, false
		if not preview then ContextActionService:UnbindAction("ArrivalDialogBack") end
		if not preview and GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(overlay) then
			GuiService.SelectedObject = if previousFocus and previousFocus.Parent then previousFocus else nil
		end
	end
	cancel.Activated:Connect(function() if not locked then close() end end)
	confirm.Activated:Connect(function()
		if locked or not callback then return end
		local action = callback
		locked = true
		confirm.Text, cancel.Active, confirm.Active = "Saving…", false, false
		action()
	end)
	return {
		Close = close,
		SetMotion = function(enabled)
			motion = enabled
			if not enabled then layout() end
		end,
		IsOpen = function() return overlay.Visible end,
		Show = function(body, primary, secondary, action, isError)
			if not preview and not overlay.Visible then previousFocus = GuiService.SelectedObject end
			message.Text, confirm.Text, cancel.Text = body, primary, secondary
			caption.Text = if isError then "SOMETHING WENT WRONG" else "YOUR RACER"
			caption.TextColor3 = if isError then Color3.fromRGB(255,170,120) else View.Cyan
			note.Text = if isError then "" else "You can change it anytime from My racer."
			message.Font = if isError then Enum.Font.GothamBold else Enum.Font.LuckiestGuy
			message.TextLimit.MaxTextSize = if isError then 20 else 32
			confirmFill.Color = if isError then ColorSequence.new(Color3.fromRGB(255,190,90), Color3.fromRGB(255,140,80)) else ColorSequence.new(View.Mint, View.Cyan)
			layout()
			if motion then
				panel.Position = restingPosition + UDim2.fromOffset(0,40)
				entrance = TweenService:Create(panel, TweenInfo.new(0.34,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Position=restingPosition})
				entrance:Play()
			end
			callback, locked = action, false
			setOpen(true)
			cancel.Active, confirm.Active = true, true
			if not preview then
				ContextActionService:BindActionAtPriority("ArrivalDialogBack", function(_, state)
					if state == Enum.UserInputState.Begin and not locked then close() end
					return Enum.ContextActionResult.Sink
				end, false, 3100, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
				if UserInputService.GamepadEnabled then GuiService.SelectedObject = cancel end
			end
		end,
	}
end

return Dialog
