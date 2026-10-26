--!strict

local Theme = {}
Theme.Navy = Color3.fromRGB(18, 37, 59)
Theme.Raised = Color3.fromRGB(29, 51, 74)
Theme.Cream = Color3.fromRGB(255, 243, 215)
Theme.Gold = Color3.fromRGB(202, 163, 90)
Theme.Muted = Color3.fromRGB(192, 201, 209)

function Theme.Frame(parent: Instance, name: string, size: UDim2, position: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name, frame.Size, frame.Position = name, size, position
	frame.BackgroundTransparency, frame.BorderSizePixel = 1, 0
	frame.Parent = parent
	return frame
end

function Theme.Panel(frame: GuiObject)
	frame.BackgroundColor3, frame.BackgroundTransparency = Theme.Navy, .04
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 9)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color, stroke.Thickness, stroke.Transparency = Theme.Gold, 1, .12
	stroke.ApplyStrokeMode, stroke.Parent = Enum.ApplyStrokeMode.Border, frame
end

function Theme.Label(parent: Instance, name: string, text: string, size: number, position: UDim2, bounds: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.Name, label.Text, label.TextSize = name, text, size
	label:SetAttribute("BaseTextSize", size)
	label.Position, label.Size = position, bounds
	label.BackgroundTransparency, label.BorderSizePixel = 1, 0
	label.Font, label.TextColor3 = Enum.Font.GothamMedium, Theme.Cream
	label.TextTruncate, label.RichText = Enum.TextTruncate.AtEnd, false
	label.Parent = parent
	return label
end

function Theme.Button(parent: Instance, name: string, text: string, position: UDim2, bounds: UDim2, activate: () -> ()): TextButton
	local button = Instance.new("TextButton")
	button.Name, button.Text, button.Position, button.Size = name, text, position, bounds
	button.BorderSizePixel, button.AutoButtonColor = 0, false
	button.TextColor3, button.Font, button.TextSize = Theme.Cream, Enum.Font.GothamMedium, 18
	button:SetAttribute("BaseTextSize", 18)
	button.Selectable = true
	Theme.Panel(button)
	button.Parent = parent
	local function focus() button.BackgroundColor3 = Theme.Raised end
	local function blur() button.BackgroundColor3 = Theme.Navy end
	button.MouseEnter:Connect(focus)
	button.MouseLeave:Connect(blur)
	button.SelectionGained:Connect(focus)
	button.SelectionLost:Connect(blur)
	button.Activated:Connect(activate)
	return button
end

local function shape(parent: Instance, position: UDim2, size: UDim2, rotation: number?): Frame
	local frame = Theme.Frame(parent, "Mark", size, position)
	frame.AnchorPoint = Vector2.new(.5, .5)
	frame.BackgroundColor3, frame.BackgroundTransparency = Theme.Gold, 0
	frame.Rotation = rotation or 0
	return frame
end

function Theme.Icon(parent: Instance, kind: string, position: UDim2): Frame
	local icon = Theme.Frame(parent, kind .. "Icon", UDim2.fromOffset(28, 28), position)
	if kind == "Records" then
		for i = 1, 4 do shape(icon, UDim2.fromOffset(3 + i * 5, 25 - i * 2.5), UDim2.fromOffset(3, i * 5)) end
	elseif kind == "Settings" then
		for i = 0, 3 do shape(icon, UDim2.fromScale(.5, .5), UDim2.fromOffset(8, 27), i * 45) end
		local centre = shape(icon, UDim2.fromScale(.5, .5), UDim2.fromOffset(12, 12))
		centre.BackgroundColor3 = Theme.Navy
		local round = Instance.new("UICorner")
		round.CornerRadius, round.Parent = UDim.new(1, 0), centre
	else
		local ring = Theme.Frame(icon, "Ring", UDim2.fromOffset(23, 23), UDim2.fromOffset(2.5, 2.5))
		local round = Instance.new("UICorner")
		round.CornerRadius, round.Parent = UDim.new(1, 0), ring
		local stroke = Instance.new("UIStroke")
		stroke.Color, stroke.Thickness, stroke.Parent = Theme.Gold, 1.5, ring
		if kind == "Check" then
			shape(icon, UDim2.fromOffset(10, 16), UDim2.fromOffset(3, 8), -45)
			shape(icon, UDim2.fromOffset(17, 13), UDim2.fromOffset(3, 13), 45)
		else
			shape(icon, UDim2.fromScale(.5, .5), UDim2.fromOffset(2, 32))
			shape(icon, UDim2.fromScale(.5, .5), UDim2.fromOffset(29, 2))
			shape(icon, UDim2.fromScale(.5, .5), UDim2.fromOffset(7, 7), 45)
		end
	end
	return icon
end

return Theme
