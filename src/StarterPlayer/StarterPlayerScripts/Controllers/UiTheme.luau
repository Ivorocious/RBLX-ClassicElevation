--!strict

local TweenService = game:GetService("TweenService")
local Theme = {}
Theme.Ink = Color3.fromRGB(6,31,80)
Theme.Blue = Color3.fromRGB(57,104,241)
Theme.Cream = Color3.fromRGB(255,249,231)
Theme.White = Color3.new(1,1,1)
Theme.Muted = Color3.fromRGB(100,112,145)
Theme.Orange = Color3.fromRGB(255,153,66)
Theme.Green = Color3.fromRGB(105,222,157)
Theme.Coral = Color3.fromRGB(255,76,66)
Theme.Lilac = Color3.fromRGB(104,125,255)
Theme.Mint = Color3.fromRGB(93,255,201)
Theme.PaleLilac = Color3.fromRGB(224,212,255)

function Theme.Frame(parent: Instance, name: string, size: UDim2, position: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.Name, frame.Size, frame.Position = name, size, position
	frame.BackgroundTransparency, frame.BorderSizePixel, frame.Parent = 1, 0, parent
	return frame
end

function Theme.Panel(frame: GuiObject, fill: Color3?, radius: number?)
	frame.BackgroundColor3, frame.BackgroundTransparency = fill or Theme.Cream, 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0,radius or 18), frame
	local edge = Instance.new("UIStroke")
	edge.Name, edge.ApplyStrokeMode = "Outline", Enum.ApplyStrokeMode.Border
	edge.Color, edge.Thickness, edge.Parent = Theme.Ink, 3.2, frame
	local gradient = Instance.new("UIGradient")
	gradient.Name, gradient.Rotation = "Enamel", 90
	gradient.Parent = frame
	local function resizeBevel()
		local soft = frame:GetAttribute("SoftFinish") == true
		local bevel = math.min((if soft then 3 else 5) / math.max(frame.AbsoluteSize.Y,40),.125)
		local color = frame.BackgroundColor3
		local warm = color.R>.9 and color.G>.85 and color.B>.7
		local royal = color.R<.6 and color.G<.7 and color.B>.9
		local coral = color.R>.9 and color.G<.45 and color.B<.45
		local mint = color.G>.8 and color.R<.7 and color.B>.55
		local face = if warm then Color3.new(1,1,1) elseif royal then Color3.new(.80,.84,1)
			elseif coral then Color3.new(1,.90,.86) elseif mint then Color3.new(.90,1,.99) else Color3.new(.96,.96,.99)
		local lip = if warm then Color3.new(.94,.92,.87) elseif royal then Color3.new(.62,.67,.93)
			elseif coral then Color3.new(.92,.56,.49) elseif mint then Color3.new(.55,.88,.80) else Color3.new(.84,.83,.93)
		if soft then lip = lip:Lerp(Color3.new(1,1,1),.3) end
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,Color3.new(1,1,1)),
			ColorSequenceKeypoint.new(.22,Color3.new(1,1,1)),
			ColorSequenceKeypoint.new(1-bevel-.012,face),
			ColorSequenceKeypoint.new(1-bevel,lip),
			ColorSequenceKeypoint.new(1,lip),
		})
	end
	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizeBevel)
	frame:GetPropertyChangedSignal("BackgroundColor3"):Connect(resizeBevel)
	frame:GetAttributeChangedSignal("SoftFinish"):Connect(resizeBevel)
	resizeBevel()
end

function Theme.Polish(frame: GuiObject, radius: number?)
	local cornerRadius = radius or 20
	local outline = frame:FindFirstChild("Outline") :: UIStroke
	outline.Thickness = 3.2
	local inset = Theme.Frame(frame,"Inset",UDim2.new(1,-12,1,-12),UDim2.fromOffset(6,6))
	local corner = Instance.new("UICorner")
	corner.CornerRadius,corner.Parent = UDim.new(0,math.max(4,cornerRadius-6)),inset
	local edge = Instance.new("UIStroke")
	edge.Color,edge.Thickness,edge.Transparency,edge.Parent = Theme.White,2,.4,inset
	local rimGradient = Instance.new("UIGradient")
	rimGradient.Rotation = 45
	rimGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.24,.35),NumberSequenceKeypoint.new(.58,1),NumberSequenceKeypoint.new(1,1)})
	rimGradient.Parent = edge
	local light = Theme.Frame(frame,"FaceLight",UDim2.new(1,-12,1,-12),UDim2.fromOffset(6,6))
	light.BackgroundColor3,light.BackgroundTransparency = Theme.White,0
	local lightCorner = Instance.new("UICorner")
	lightCorner.CornerRadius,lightCorner.Parent = UDim.new(0,math.max(4,cornerRadius-6)),light
	local lightGradient = Instance.new("UIGradient")
	lightGradient.Rotation = 45
	lightGradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,.85),NumberSequenceKeypoint.new(.55,1),NumberSequenceKeypoint.new(1,1)})
	lightGradient.Parent = light
	local glint = Theme.Frame(frame,"Glint",UDim2.fromOffset(3,14),UDim2.fromOffset(8,math.max(12,cornerRadius*.8)))
	glint.BackgroundColor3,glint.BackgroundTransparency,glint.Rotation = Theme.White,.2,9
	local glintCorner = Instance.new("UICorner")
	glintCorner.CornerRadius,glintCorner.Parent = UDim.new(1,0),glint
	local shadow = Theme.Frame(frame.Parent,frame.Name.."Shadow",frame.Size,frame.Position)
	shadow.BackgroundColor3,shadow.BackgroundTransparency = Theme.Ink,.65
	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius,shadowCorner.Parent = UDim.new(0,cornerRadius),shadow
	local function placeShadow()
		shadow.Size,shadow.Position,shadow.AnchorPoint = frame.Size,frame.Position+UDim2.fromOffset(0,5),frame.AnchorPoint
		shadow.Visible,shadow.ZIndex = frame.Visible and frame:GetAttribute("HideShadow")~=true,math.max(0,frame.ZIndex-1)
	end
	for _, property in {"Size","Position","AnchorPoint","Visible","ZIndex"} do frame:GetPropertyChangedSignal(property):Connect(placeShadow) end
	frame:GetAttributeChangedSignal("HideShadow"):Connect(placeShadow)
	frame.Destroying:Connect(function() shadow:Destroy() end)
	placeShadow()
end

function Theme.Label(parent: Instance, name: string, text: string, size: number, position: UDim2, bounds: UDim2): TextLabel
	local label = Instance.new("TextLabel")
	label.Name, label.Text, label.TextSize = name, text, size
	label:SetAttribute("BaseTextSize",size)
	label.Position, label.Size, label.Parent = position, bounds, parent
	label.BackgroundTransparency, label.BorderSizePixel = 1, 0
	label.Font, label.TextColor3, label.TextTruncate = Enum.Font.FredokaOne, Theme.Ink, Enum.TextTruncate.AtEnd
	return label
end

function Theme.SetSelected(button: TextButton, selected: boolean)
	button:SetAttribute("Selected",selected)
end

function Theme.SetAvailable(button: TextButton, available: boolean)
	button:SetAttribute("Available",available)
	button.Selectable, button.Active = available, available
end

function Theme.Button(parent: Instance, name: string, text: string, position: UDim2, bounds: UDim2, activate: () -> (), fill: Color3?, radius: number?): TextButton
	local button = Instance.new("TextButton")
	button.Name, button.Text, button.Position, button.Size = name,text,position,bounds
	button.BorderSizePixel, button.AutoButtonColor = 0,false
	button.Font, button.TextSize, button.TextColor3 = Enum.Font.FredokaOne,20,Theme.Ink
	button:SetAttribute("BaseTextSize",20)
	button:SetAttribute("Available",true)
	button.Selectable, button.Parent = true,parent
	local selection = Instance.new("ImageLabel")
	selection.Name, selection.Size, selection.BackgroundTransparency = "FocusImage",UDim2.fromScale(1,1),1
	selection.BorderSizePixel, selection.Image, selection.Parent = 0,"",button
	button.SelectionImageObject = selection
	local color = fill or Theme.Cream
	Theme.Panel(button,color,radius or 16)
	Theme.Polish(button,radius or 16)
	local scale = Instance.new("UIScale")
	scale.Name, scale.Parent = "Feedback",button
	local focused, pressed = false,false
	local tween: Tween? = nil
	local function render()
		if tween then tween:Cancel() end
		local available = button:GetAttribute("Available") ~= false
		local selected = button:GetAttribute("Selected") == true
		button.BackgroundColor3 = if not available then color:Lerp(Theme.Muted,.12) elseif focused or selected then color:Lerp(Theme.White,.18) else color
		local outline = button:FindFirstChild("Outline") :: UIStroke
		outline.Color = if focused or selected then Theme.Blue else Theme.Ink
		outline.Thickness = 3.2
		tween = TweenService:Create(scale,TweenInfo.new(.12,Enum.EasingStyle.Quad),{Scale=if pressed and available then .96 else 1})
		tween:Play()
	end
	local function focus() focused=true; render() end
	local function blur() focused,pressed=false,false; render() end
	button.MouseEnter:Connect(focus)
	button.MouseLeave:Connect(blur)
	button.SelectionGained:Connect(focus)
	button.SelectionLost:Connect(blur)
	local function isPress(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA or input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space
	end
	button.InputBegan:Connect(function(input) if isPress(input) then pressed=true; render() end end)
	button.InputEnded:Connect(function(input) if isPress(input) then pressed=false; render() end end)
	button:GetAttributeChangedSignal("Selected"):Connect(render)
	button:GetAttributeChangedSignal("Available"):Connect(render)
	button.Activated:Connect(function() if button:GetAttribute("Available") ~= false then activate() end end)
	return button
end

return Theme
