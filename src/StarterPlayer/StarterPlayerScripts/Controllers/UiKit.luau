--!strict
-- Shared Obby Tournament style kit (brief "Shared style kit"): palette, fonts, sticker plates,
-- outlined numbers, chips, buttons, motion and sound. Race screens use the sticker look (mix B).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TextService = game:GetService("TextService")

local Kit = {}

Kit.Navy = Color3.fromHex("10215C")
Kit.SubInk = Color3.fromHex("2C3D73")
Kit.Sky = Color3.fromHex("56C8FF")
Kit.SkyDeep = Color3.fromHex("2A63F0")
Kit.Sun = Color3.fromHex("FFD338")
Kit.SunDeep = Color3.fromHex("FFC21F")
Kit.Pink = Color3.fromHex("FF4F7B")
Kit.PinkPale = Color3.fromHex("FF8FAA")
Kit.Mint = Color3.fromHex("2EE6A6")
Kit.MintInk = Color3.fromHex("06392A")
Kit.White = Color3.new(1, 1, 1)
Kit.Silver = Color3.fromHex("DCE6FF")
Kit.Bronze = Color3.fromHex("FF9F5A")

Kit.Display = Font.fromEnum(Enum.Font.LuckiestGuy)
Kit.Label = Font.fromEnum(Enum.Font.FredokaOne)

-- Receipt: assets/ui/race/upload-receipt.json; sources in assets/ui/race/svg.
Kit.Images = {
	StarCoin = "rbxassetid://111271063911292",
	SkyKey = "rbxassetid://89555402381692",
	Crown = "rbxassetid://81890458189578",
	FinishFlag = "rbxassetid://83888567636514",
	CheckpointFlag = "rbxassetid://79812203026303",
	FallArrow = "rbxassetid://84291893920447",
	Halftone = "rbxassetid://137293337307005",
	Rays = "rbxassetid://115097695717750",
}

local localPlayer = Players.LocalPlayer

-- Set only by UI previews: Frozen stops moments on their settled frame and stays silent; Silent
-- keeps motion but plays no sounds (UI Labs stories).
Kit.Frozen = false
Kit.Silent = false

function Kit.Motion(): boolean
	return not Kit.Frozen and (localPlayer == nil or localPlayer:GetAttribute("ReducedMotion") ~= true)
end

function Kit.LargeText(): boolean
	return localPlayer ~= nil and localPlayer:GetAttribute("LargeText") == true
end

local function corner(parent: Instance, radius: number)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius)
	item.Parent = parent
end

-- UIScale also scales stroke thickness, so strokes are authored at design size.
local function stroke(parent: Instance, color: Color3, thickness: number, border: boolean): UIStroke
	local item = Instance.new("UIStroke")
	item.Color, item.Thickness = color, thickness
	item.LineJoinMode = Enum.LineJoinMode.Round
	item.ApplyStrokeMode = if border then Enum.ApplyStrokeMode.Border else Enum.ApplyStrokeMode.Contextual
	item.Parent = parent
	return item
end
Kit.Stroke = stroke

local function frame(parent: Instance?, name: string, size: UDim2, position: UDim2, color: Color3?, transparency: number?): Frame
	local item = Instance.new("Frame")
	item.Name, item.Size, item.Position = name, size, position
	item.BorderSizePixel = 0
	item.BackgroundColor3 = color or Kit.White
	item.BackgroundTransparency = if transparency ~= nil then transparency elseif color then 0 else 1
	item.Parent = parent
	return item
end
Kit.Frame = frame

export type PlateOptions = {
	fill: Color3?,
	hero: boolean?,
	dots: boolean?,
	tilt: number?,
	radius: number?,
	shadow: boolean?,
}

-- Die-cut sticker plate: offset navy shadow, white cut edge, navy-outlined face with an optional
-- halftone, slightly tilted; the returned frame's "Content" child stays upright for text.
function Kit.Plate(parent: Instance?, name: string, size: UDim2, position: UDim2, options: PlateOptions?): Frame
	local opts: PlateOptions = options or {}
	local hero = opts.hero == true
	local radius = opts.radius or 10
	local tilt = opts.tilt or (if hero then 1.4 else -1.2)
	local root = frame(parent, name, size, position)
	if opts.shadow ~= false then
		local shadow = frame(root, "Shadow", UDim2.new(1, 10, 1, 10), UDim2.fromOffset(2, 4), Kit.Navy, .65)
		shadow.Rotation, shadow.ZIndex = tilt, 1
		corner(shadow, radius + 5)
	end
	local cut = frame(root, "Cut", UDim2.new(1, 12, 1, 12), UDim2.fromOffset(-6, -6), Kit.White, 0)
	cut.Rotation, cut.ZIndex = tilt, 2
	corner(cut, radius + 6)
	local face = frame(root, "Face", UDim2.fromScale(1, 1), UDim2.new(), opts.fill or (if hero then Kit.Sun else Kit.White), 0)
	face.Rotation, face.ZIndex = tilt, 3
	corner(face, radius)
	stroke(face, Kit.Navy, 3.5, true)
	if hero or opts.dots == true then
		local dots = Instance.new("ImageLabel")
		dots.Name, dots.BackgroundTransparency = "Halftone", 1
		dots.Size, dots.Position = UDim2.new(1, -8, 1, -8), UDim2.fromOffset(4, 4)
		dots.Image, dots.ScaleType, dots.TileSize = Kit.Images.Halftone, Enum.ScaleType.Tile, UDim2.fromOffset(9, 9)
		dots.ImageColor3, dots.ImageTransparency = Kit.Navy, .86
		dots.ZIndex, dots.Parent = 3, face
	end
	local content = frame(root, "Content", UDim2.fromScale(1, 1), UDim2.new())
	content.ZIndex = 4
	return root
end

function Kit.SetPlateFill(plate: Instance, fill: Color3)
	local face = plate:FindFirstChild("Face")
	if face and face:IsA("Frame") then face.BackgroundColor3 = fill end
end

function Kit.Content(plate: Instance): Frame
	return plate:FindFirstChild("Content") :: Frame
end

local function text(parent: Instance?, name: string, value: string, size: number, font: Font, color: Color3): TextLabel
	local label = Instance.new("TextLabel")
	label.Name, label.Text, label.TextSize, label.FontFace, label.TextColor3 = name, value, size, font, color
	label.BackgroundTransparency, label.BorderSizePixel = 1, 0
	label.Size = UDim2.new(1, 0, 0, size)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label:SetAttribute("BaseTextSize", size)
	label.Parent = parent
	return label
end

-- Small uppercase Fredoka label (the page's .lbl).
function Kit.Caption(parent: Instance?, name: string, value: string, size: number?, color: Color3?): TextLabel
	local label = text(parent, name, string.upper(value), size or 13, Kit.Label, color or Kit.Navy)
	return label
end

function Kit.Body(parent: Instance?, name: string, value: string, size: number?, color: Color3?): TextLabel
	return text(parent, name, value, size or 15, Kit.Label, color or Kit.SubInk)
end

export type BigOptions = {
	fill: Color3?,
	outline: number?,
	shadow: number?,
	auto: boolean?,
	down: boolean?,
}

-- Roblox caps TextSize at 100, so bigger numbers render at 100 inside a UIScale.
local MAX_TEXT = 100

local function bigWidth(big: Instance)
	local scale = big:GetAttribute("BigScale")
	local main = big:FindFirstChild("Main", true)
	if typeof(scale) ~= "number" or not big:IsA("Frame") or not main or not main:IsA("TextLabel") then return end
	local bounds = TextService:GetTextSize(main.Text, main.TextSize, Enum.Font.LuckiestGuy, Vector2.new(10000, 10000))
	big.Size = UDim2.fromOffset(math.ceil((bounds.X + (big:GetAttribute("BigDrop") :: number)) * scale), big.Size.Y.Offset)
end

-- Luckiest Guy number/title with a navy outline and an offset navy shadow (the page's .big).
-- Returns a transparent frame; use Kit.SetBig to change its text. With `auto` the frame takes
-- its text width, for use inside horizontal list layouts.
function Kit.Big(parent: Instance?, name: string, value: string, size: number, options: BigOptions?): Frame
	local opts: BigOptions = options or {}
	local auto = opts.auto == true
	local scale = math.max(1, size / MAX_TEXT)
	local textSize = size / scale
	local root = frame(parent, name, if auto then UDim2.fromOffset(0, size) else UDim2.new(1, 0, 0, size), UDim2.new())
	local holder: Frame = root
	if scale > 1 then
		holder = frame(root, "Scale", UDim2.fromScale(1 / scale, 1 / scale), UDim2.fromScale(.5, .5))
		holder.AnchorPoint = Vector2.new(.5, .5)
		local fit = Instance.new("UIScale")
		fit.Scale, fit.Parent = scale, holder
	end
	local width = (opts.outline or math.max(2, size * .06)) / scale
	local drop = (opts.shadow or math.max(2, size * .055)) / scale
	local back = text(holder, "Shadow", value, textSize, Kit.Display, Kit.Navy)
	back.Position, back.ZIndex = UDim2.fromOffset(if opts.down then 0 else drop, drop), 1
	stroke(back, Kit.Navy, width, false)
	local main = text(holder, "Main", value, textSize, Kit.Display, opts.fill or Kit.White)
	main.ZIndex = 2
	stroke(main, Kit.Navy, width, false)
	if auto and scale > 1 then
		-- Automatic sizing cannot see through the UIScale, so measure the text instead.
		root:SetAttribute("BigScale", scale)
		root:SetAttribute("BigDrop", drop)
		back.Size, main.Size = UDim2.fromScale(1, 1), UDim2.fromScale(1, 1)
		bigWidth(root)
	elseif auto then
		root.AutomaticSize = Enum.AutomaticSize.X
		for _, label in {back, main} do
			label.Size, label.AutomaticSize = UDim2.fromOffset(0, textSize), Enum.AutomaticSize.X
		end
	else
		back.Size, main.Size = UDim2.fromScale(1, 1), UDim2.fromScale(1, 1)
	end
	return root
end

-- Luckiest Guy title in navy with a sky-blue offset shadow and no outline (the page's .ttl).
function Kit.Title(parent: Instance?, name: string, value: string, size: number, auto: boolean?): Frame
	local root = Kit.Big(parent, name, value, size, {fill = Kit.Navy, auto = auto, shadow = math.max(2, size * .07)})
	for _, label in Kit.BigLabels(root) do
		local edge = label:FindFirstChildOfClass("UIStroke")
		if edge then edge:Destroy() end
	end
	(root:FindFirstChild("Shadow", true) :: TextLabel).TextColor3 = Kit.Sky
	return root
end

function Kit.SetBigColor(big: Instance, fill: Color3)
	local main = big:FindFirstChild("Main", true)
	if main and main:IsA("TextLabel") then main.TextColor3 = fill end
end

function Kit.SetBig(big: Instance, value: string)
	for _, name in {"Main", "Shadow"} do
		local label = big:FindFirstChild(name, true)
		if label and label:IsA("TextLabel") then label.Text = value end
	end
	bigWidth(big)
end

function Kit.BigLabels(big: Instance): {TextLabel}
	return {big:FindFirstChild("Main", true) :: TextLabel, big:FindFirstChild("Shadow", true) :: TextLabel}
end

-- Shrinks a Big title (size up to MAX_TEXT) to fit `width`; below half size it ends with "…" instead.
function Kit.FitBig(big: Instance, size: number, width: number)
	local labels = Kit.BigLabels(big)
	local measured = TextService:GetTextSize(labels[1].Text, size, Enum.Font.LuckiestGuy, Vector2.new(10000, 1000)).X
	local fitted = math.max(math.floor(size * .5), math.min(size, math.floor(size * width / math.max(1, measured))))
	for _, label in labels do label.TextSize, label.TextTruncate = fitted, Enum.TextTruncate.AtEnd end
end

function Kit.SetBigAlignment(big: Instance, alignment: Enum.TextXAlignment)
	for _, label in Kit.BigLabels(big) do label.TextXAlignment = alignment end
end

export type ChipKind = "Plain" | "Good" | "Bad" | "Light"

-- Rounded pill sized to its text (the page's .chip).
function Kit.Chip(parent: Instance?, name: string, value: string, size: number?, kind: ChipKind?): Frame
	local chip = frame(parent, name, UDim2.fromOffset(0, (size or 15) + 12), UDim2.new(), Kit.Navy, 0)
	chip.AutomaticSize = Enum.AutomaticSize.X
	corner(chip, 999)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 12), UDim.new(0, 12)
	padding.Parent = chip
	local list = Instance.new("UIListLayout")
	list.FillDirection, list.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center
	list.Padding, list.SortOrder = UDim.new(0, 6), Enum.SortOrder.LayoutOrder
	list.Parent = chip
	local label = text(chip, "Text", value, size or 15, Kit.Label, Kit.White)
	label.AutomaticSize, label.Size, label.LayoutOrder = Enum.AutomaticSize.X, UDim2.fromScale(0, 1), 2
	Kit.SetChip(chip, value, kind)
	return chip
end

function Kit.SetChip(chip: Instance, value: string?, kind: ChipKind?)
	local label = chip:FindFirstChild("Text") :: TextLabel?
	if not label or not chip:IsA("Frame") then return end
	if value then label.Text = value end
	if kind then
		chip.BackgroundColor3 = if kind == "Good" then Kit.Mint elseif kind == "Bad" then Kit.Pink elseif kind == "Light" then Kit.White else Kit.Navy
		label.TextColor3 = if kind == "Good" then Kit.MintInk elseif kind == "Light" then Kit.Navy else Kit.White
	end
end

-- Adds a small icon before the chip's text (for example an arrow for overtakes).
function Kit.ChipIcon(chip: Instance, image: string, rotation: number?): ImageLabel
	local label = chip:FindFirstChild("Text") :: TextLabel
	local size = label.TextSize
	-- Layout items ignore Rotation, so the icon turns inside its own slot.
	local slot = frame(chip, "IconSlot", UDim2.fromOffset(size, size), UDim2.new())
	slot.LayoutOrder = 1
	local icon = Instance.new("ImageLabel")
	icon.Name, icon.Image, icon.BackgroundTransparency = "Icon", image, 1
	icon.Size, icon.Rotation = UDim2.fromScale(1, 1), rotation or 0
	icon.ImageColor3 = label.TextColor3
	icon.Parent = slot
	return icon
end

function Kit.Icon(parent: Instance?, name: string, image: string, size: number, color: Color3?): ImageLabel
	local icon = Instance.new("ImageLabel")
	icon.Name, icon.Image, icon.BackgroundTransparency = name, image, 1
	icon.Size = UDim2.fromOffset(size, size)
	icon.ScaleType = Enum.ScaleType.Fit
	if color then icon.ImageColor3 = color end
	icon.Parent = parent
	return icon
end

-- Close buttons get a drawn X: the "×" glyph renders tiny in the display font.
local function closeMark(label: TextLabel, size: number)
	label.Text = ""
	for _, angle in {45, -45} do
		local bar = frame(label.Parent, "CloseMark", UDim2.fromOffset(size * .5, math.max(4, size * .11)), UDim2.fromScale(.5, .5), Kit.Navy, 0)
		bar.AnchorPoint, bar.Rotation, bar.ZIndex = Vector2.new(.5, .5), angle, label.ZIndex
		corner(bar, 3)
	end
end

-- Sticker button (the page's .gbtn): sky or white face, navy outline, white cut, offset shadow,
-- lift on hover/focus and squash on press. Keeps the "Available"/"Selected" attributes used by
-- existing navigation code.
function Kit.Button(parent: Instance?, name: string, value: string, size: UDim2, position: UDim2, activate: () -> (), primary: boolean?, textSize: number?): TextButton
	local button = Instance.new("TextButton")
	button.Name, button.Size, button.Position = name, size, position
	button.Text, button.AutoButtonColor, button.BackgroundTransparency, button.BorderSizePixel = "", false, 1, 0
	button.Selectable = true
	button:SetAttribute("Available", true)
	local focusRing = Instance.new("ImageLabel")
	focusRing.Name, focusRing.BackgroundTransparency, focusRing.Image = "FocusImage", 1, ""
	focusRing.Size = UDim2.fromScale(1, 1)
	button.SelectionImageObject = focusRing
	focusRing.Parent = button
	local body = frame(button, "Body", UDim2.fromScale(1, 1), UDim2.new())
	local scale = Instance.new("UIScale")
	scale.Name, scale.Parent = "Feedback", body
	local fill = if primary then Kit.Sky else Kit.White
	local shadow = frame(body, "Shadow", UDim2.new(1, 8, 1, 8), UDim2.fromOffset(2, 4), Kit.Navy, .65)
	shadow.ZIndex = 1
	corner(shadow, 14)
	local cut = frame(body, "Cut", UDim2.new(1, 10, 1, 10), UDim2.fromOffset(-5, -5), Kit.White, 0)
	cut.ZIndex = 2
	corner(cut, 15)
	-- Keyboard/controller focus ring around the white cut edge.
	local ring = stroke(cut, Kit.SkyDeep, 4, true)
	ring.Enabled = false
	local face = frame(body, "Face", UDim2.fromScale(1, 1), UDim2.new(), fill, 0)
	face.ZIndex = 3
	corner(face, 10)
	local edge = stroke(face, Kit.Navy, 3.5, true)
	local label = text(body, "Label", value, textSize or 19, Kit.Display, Kit.Navy)
	label.Size, label.Position, label.ZIndex = UDim2.new(1, -16, 1, -4), UDim2.fromOffset(8, 3), 4
	label.TextScaled = false
	label.TextWrapped = true
	if value == "×" then closeMark(label, if size.Y.Scale == 0 then size.Y.Offset else 44) end
	button.Parent = parent
	local hovered, pressed, focused = false, false, false
	local tween: Tween? = nil
	local function render()
		local available = button:GetAttribute("Available") ~= false
		local selected = button:GetAttribute("Selected") == true
		face.BackgroundColor3 = if not available then fill:Lerp(Kit.Navy, .18) elseif hovered or selected then fill:Lerp(Kit.White, .25) else fill
		edge.Color = if (hovered or selected) and available then Kit.SkyDeep else Kit.Navy
		ring.Enabled = focused
		label.TextTransparency = if available then 0 else .35
		if tween then tween:Cancel() end
		local target = if pressed and available then .94 elseif hovered and available then 1.04 else 1
		if not Kit.Motion() then scale.Scale = target; return end
		tween = TweenService:Create(scale, TweenInfo.new(.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = target})
		;(tween :: Tween):Play()
	end
	local function isPress(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA or input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space
	end
	button.MouseEnter:Connect(function() hovered = true; render() end)
	button.MouseLeave:Connect(function() hovered, pressed = false, false; render() end)
	button.SelectionGained:Connect(function() hovered, focused = true, true; render() end)
	button.SelectionLost:Connect(function() hovered, pressed, focused = false, false, false; render() end)
	button.InputBegan:Connect(function(input) if isPress(input) then pressed = true; render() end end)
	button.InputEnded:Connect(function(input) if isPress(input) then pressed = false; render() end end)
	button:GetAttributeChangedSignal("Available"):Connect(render)
	button:GetAttributeChangedSignal("Selected"):Connect(render)
	button.Activated:Connect(function()
		if button:GetAttribute("Available") == false then return end
		Kit.Play("Click")
		activate()
	end)
	render()
	return button
end

function Kit.SetButtonText(button: Instance, value: string)
	local label = button:FindFirstChild("Label", true)
	if label and label:IsA("TextLabel") then label.Text = value end
end

function Kit.SetButtonPrimary(button: Instance, primary: boolean)
	local face = button:FindFirstChild("Face", true)
	if face and face:IsA("Frame") then face.BackgroundColor3 = if primary then Kit.Sky else Kit.White end
end

-- Sky Rush (lobby, Race options, vote, results) plates and buttons are straight rounded panels: a
-- gradient body, navy outline and drop shadow. The earlier slanted 9-slice images showed a step in
-- the slanted edge at almost every size (Roblox rounds each slice separately, which is invisible on
-- straight edges but not on slanted ones), so nothing is drawn from those images any more.
Kit.Images.SpeedStripes = "rbxassetid://131279099037009"

local function sequence(...: string): ColorSequence
	local colors = {...}
	if #colors == 1 then return ColorSequence.new(Color3.fromHex(colors[1])) end
	local points = {}
	for index, hex in colors do
		table.insert(points, ColorSequenceKeypoint.new((index - 1) / (#colors - 1), Color3.fromHex(hex)))
	end
	return ColorSequence.new(points)
end

Kit.SkyFills = {
	Sky = sequence("56C8FF", "3A9CFF", "2A63F0"),
	Hero = sequence("FFE766", "FFC21F"),
	White = sequence("FFFFFF", "E9F2FF"),
	Pink = sequence("FFA3B9", "FF6F92"),
	Mint = sequence("8BF7D2", "2EE6A6"),
	Navy = sequence("223A8C", "10215C"),
}

export type SkyClass = "S" | "M" | "L"
export type SkyOptions = {
	fill: string?,
	class: SkyClass?,
	stripes: boolean?,
	shadow: boolean?,
	highlight: boolean?,
	-- Design height in pixels when `size` is scale-based, so short plates can keep their slant.
	height: number?,
}

local function skyClassFor(size: UDim2, class: SkyClass?): SkyClass
	if class then return class end
	local height = size.Y.Offset
	return if size.Y.Scale > 0 or height <= 0 then "M" elseif height < 76 then "S" elseif height < 200 then "M" else "L"
end

-- Plates are straight, so no row needs a slanted-edge inset; kept for the layouts that ask.
function Kit.SkySlant(_class: SkyClass): number
	return 0
end

local function straightBody(parent: Instance, name: string, radius: number): ImageLabel
	local body = Instance.new("ImageLabel")
	body.Name, body.Image, body.BackgroundColor3, body.BackgroundTransparency, body.BorderSizePixel = name, "", Kit.White, 0, 0
	body.Size = UDim2.fromScale(1, 1)
	corner(body, radius)
	body.Parent = parent
	return body
end

function Kit.SetSkyOpacity(plate: Instance, transparency: number)
	local body = plate:FindFirstChild("Body")
	if body and body:IsA("ImageLabel") then body.BackgroundTransparency = transparency end
end

-- Sky Rush plate: rounded gradient body with a navy outline, navy drop shadow, optional speed
-- stripes and top shine. Text and children go in the "Content" frame.
function Kit.SkyPlate(parent: Instance?, name: string, size: UDim2, position: UDim2, options: SkyOptions?): Frame
	local opts: SkyOptions = options or {}
	local class = skyClassFor(size, opts.class)
	local root = frame(parent, name, size, position)
	root:SetAttribute("SkyClass", class)
	local height = opts.height or (if size.Y.Scale == 0 and size.Y.Offset > 0 then size.Y.Offset else nil)
	local radius = if height and height < 76 then 12 else 16
	local drop = if class == "S" then 4 else 6
	if opts.shadow ~= false then
		local shadow = straightBody(root, "Shadow", radius)
		shadow.Position, shadow.BackgroundColor3, shadow.BackgroundTransparency, shadow.ZIndex = UDim2.fromOffset(0, drop), Kit.Navy, .3, 1
	end
	local body = straightBody(root, "Body", radius)
	body.ZIndex = 2
	stroke(body, Kit.Navy, 3, true)
	local fill = Instance.new("UIGradient")
	fill.Name, fill.Rotation, fill.Color = "Fill", 90, Kit.SkyFills[opts.fill or "Sky"] or Kit.SkyFills.Sky
	fill.Parent = body
	if opts.highlight ~= false then
		-- Kept clear of the rounded corners so it never crosses the outline.
		local shine = frame(root, "Shine", UDim2.new(1, -(radius * 2 + 4), 0, 3), UDim2.fromOffset(radius + 2, 4), Kit.White, .5)
		shine.ZIndex = 3
		corner(shine, 2)
	end
	if opts.stripes then
		local stripes = Instance.new("ImageLabel")
		stripes.Name, stripes.BackgroundTransparency, stripes.Image = "Stripes", 1, Kit.Images.SpeedStripes
		stripes.ScaleType, stripes.TileSize = Enum.ScaleType.Tile, UDim2.fromOffset(44, 44)
		stripes.AnchorPoint, stripes.Position = Vector2.new(1, 0), UDim2.new(1, -10, 0, 8)
		stripes.Size, stripes.ImageTransparency, stripes.ZIndex = UDim2.new(.5, 0, 1, -16), .83, 3
		local fade = Instance.new("UIGradient")
		fade.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.6, 0), NumberSequenceKeypoint.new(1, .3)})
		fade.Parent = stripes
		stripes.Parent = root
	end
	local content = frame(root, "Content", UDim2.fromScale(1, 1), UDim2.new())
	content.ZIndex = 4
	return root
end

function Kit.SetSkyFill(plate: Instance, fill: string)
	local body = plate:FindFirstChild("Body")
	local gradient = body and body:FindFirstChild("Fill")
	if gradient and gradient:IsA("UIGradient") then gradient.Color = Kit.SkyFills[fill] or Kit.SkyFills.Sky end
end

-- White Luckiest Guy text with a navy outline and a straight-down navy shadow (Sky Rush .big/.ttl).
function Kit.SkyBig(parent: Instance?, name: string, value: string, size: number, auto: boolean?): Frame
	return Kit.Big(parent, name, value, size, {auto = auto, down = true, outline = math.max(2, size * .1), shadow = math.max(2, size * .1)})
end

-- Small uppercase label for Sky plates: white on blue, warm brown on the yellow hero plate.
function Kit.SkyCaption(parent: Instance?, name: string, value: string, size: number?, onHero: boolean?): TextLabel
	return Kit.Caption(parent, name, value, size or 13, if onHero then Color3.fromHex("6B4300") else Kit.White)
end

export type SkyButtonKind = "Primary" | "Alt" | "Light"

-- Slanted Sky Rush button: yellow primary, sky alt or white; lifts on hover/focus, squashes on press.
-- Keeps the "Available"/"Selected" attributes used by existing navigation code.
function Kit.SkyButton(parent: Instance?, name: string, value: string, size: UDim2, position: UDim2, activate: () -> (), kind: SkyButtonKind?, textSize: number?): TextButton
	local style = kind or "Primary"
	local button = Instance.new("TextButton")
	button.Name, button.Size, button.Position = name, size, position
	button.Text, button.AutoButtonColor, button.BackgroundTransparency, button.BorderSizePixel = "", false, 1, 0
	button.Selectable = true
	button:SetAttribute("Available", true)
	local focusImage = Instance.new("ImageLabel")
	focusImage.Name, focusImage.BackgroundTransparency, focusImage.Image, focusImage.Size = "FocusImage", 1, "", UDim2.fromScale(1, 1)
	button.SelectionImageObject = focusImage
	focusImage.Parent = button
	local body = frame(button, "Body", UDim2.fromScale(1, 1), UDim2.new())
	local scale = Instance.new("UIScale")
	scale.Name, scale.Parent = "Feedback", body
	local height = if size.Y.Scale == 0 and size.Y.Offset > 0 then size.Y.Offset else nil
	local class: SkyClass = if height and height < 76 then "S" else "M"
	local plate = Kit.SkyPlate(body, "Plate", UDim2.fromScale(1, 1), UDim2.new(), {
		fill = if style == "Primary" then "Hero" elseif style == "Light" then "White" else "Sky", class = class, height = height,
	})
	-- Keyboard/controller focus: a white halo around the plate, in the plate's own shape.
	local ring = straightBody(body, "Ring", if height and height < 76 then 17 else 21)
	ring.Size, ring.Position, ring.ZIndex, ring.Visible = UDim2.new(1, 10, 1, 10), UDim2.fromOffset(-5, -5), 0, false
	local label = text(body, "Label", value, textSize or 19, Kit.Display, if style == "Alt" then Kit.White else Kit.Navy)
	label.Size, label.Position, label.ZIndex = UDim2.new(1, -18, 1, -4), UDim2.fromOffset(9, 3), 5
	label.TextWrapped = true
	if style == "Alt" then stroke(label, Kit.Navy, math.max(1.5, (textSize or 19) * .1), false) end
	if value == "×" then closeMark(label, height or 46) end
	button.Parent = parent
	if style == "Primary" then Kit.Sheen(plate) end
	local hovered, pressed, focused = false, false, false
	local tween: Tween? = nil
	local function render()
		local available = button:GetAttribute("Available") ~= false
		local selected = button:GetAttribute("Selected") == true
		-- "Done" buttons (for example Locked in) are finished, not broken: full colour.
		local done = button:GetAttribute("Done") == true
		Kit.SetSkyOpacity(plate, if available or done then 0 else .25)
		label.TextTransparency = if available or done then 0 else .4
		ring.Visible = focused
		if tween then tween:Cancel() end
		local target = if pressed and available then .94 elseif (hovered or selected) and available then 1.04 else 1
		local lift = if (hovered or selected) and available and not pressed then -2 else 0
		if not Kit.Motion() then scale.Scale = target; body.Position = UDim2.fromOffset(0, lift); return end
		tween = TweenService:Create(scale, TweenInfo.new(.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = target})
		;(tween :: Tween):Play()
		TweenService:Create(body, TweenInfo.new(.16, Enum.EasingStyle.Quad), {Position = UDim2.fromOffset(0, lift)}):Play()
	end
	local function isPress(input: InputObject): boolean
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA or input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space
	end
	button.MouseEnter:Connect(function() hovered = true; render() end)
	button.MouseLeave:Connect(function() hovered, pressed = false, false; render() end)
	button.SelectionGained:Connect(function() hovered, focused = true, true; render() end)
	button.SelectionLost:Connect(function() hovered, pressed, focused = false, false, false; render() end)
	button.InputBegan:Connect(function(input) if isPress(input) then pressed = true; render() end end)
	button.InputEnded:Connect(function(input) if isPress(input) then pressed = false; render() end end)
	button:GetAttributeChangedSignal("Available"):Connect(render)
	button:GetAttributeChangedSignal("Selected"):Connect(render)
	button:GetAttributeChangedSignal("Done"):Connect(render)
	button.Activated:Connect(function()
		if button:GetAttribute("Available") == false then return end
		Kit.Play("Click")
		activate()
	end)
	render()
	return button
end

function Kit.SetSkyButtonKind(button: Instance, kind: SkyButtonKind)
	local plate = button:FindFirstChild("Plate", true)
	local label = button:FindFirstChild("Label", true)
	if plate then Kit.SetSkyFill(plate, if kind == "Primary" then "Hero" elseif kind == "Light" then "White" else "Sky") end
	if label and label:IsA("TextLabel") then
		label.TextColor3 = if kind == "Alt" then Kit.White else Kit.Navy
		local edge = label:FindFirstChildOfClass("UIStroke")
		if kind == "Alt" and not edge then stroke(label, Kit.Navy, math.max(1.5, label.TextSize * .1), false)
		elseif kind ~= "Alt" and edge then edge:Destroy() end
	end
end

-- Stamp such as YOU'RE IN! or LOCKED IN!: slams in rotated, then fades.
function Kit.Stamp(parent: Instance, value: string, color: Color3?, size: number?)
	local height = size or 120
	local big = Kit.SkyBig(parent, "Stamp", value, height)
	big.AnchorPoint, big.Position, big.Size = Vector2.new(.5, .5), UDim2.fromScale(.5, .5), UDim2.new(1, 0, 0, height)
	big.ZIndex = 50
	Kit.SetBigColor(big, color or Kit.Mint)
	Kit.Play("Pop")
	if Kit.Motion() then
		local pop = Kit.Scaler(big)
		pop.Scale, big.Rotation = 3, -14
		Kit.Tween(pop, .5, {Scale = 1}, "Out")
		Kit.Tween(big, .5, {Rotation = -8}, "Out")
	else
		big.Rotation = -8
	end
	task.delay(1.5, function()
		if not big.Parent then return end
		Kit.FadeTree(big, false, .4)
		task.delay(.45, function() big:Destroy() end)
	end)
end

-- Motion: tweens collapse to their end state when the player reduces motion.
export type Ease = "Pop" | "Out" | "In" | "Linear"
local styles: {[string]: {Enum.EasingStyle | Enum.EasingDirection}} = {
	Pop = {Enum.EasingStyle.Back, Enum.EasingDirection.Out},
	Out = {Enum.EasingStyle.Quint, Enum.EasingDirection.Out},
	In = {Enum.EasingStyle.Quad, Enum.EasingDirection.In},
	Linear = {Enum.EasingStyle.Linear, Enum.EasingDirection.Out},
}

function Kit.Tween(target: Instance, seconds: number, goals: {[string]: any}, ease: Ease?, delay: number?): Tween
	local style = styles[ease or "Pop"]
	local info = TweenInfo.new(if Kit.Motion() then seconds else 0, style[1] :: Enum.EasingStyle, style[2] :: Enum.EasingDirection, 0, false, if Kit.Motion() then delay or 0 else 0)
	local tween = TweenService:Create(target, info, goals)
	tween:Play()
	return tween
end

-- A UIScale on the object, created on demand, for punch/pop animations.
function Kit.Scaler(target: Instance): UIScale
	local existing = target:FindFirstChild("PopScale")
	if existing and existing:IsA("UIScale") then return existing end
	local scale = Instance.new("UIScale")
	scale.Name, scale.Parent = "PopScale", target
	return scale
end

-- Scale from `from` to 1 with an overshoot; with reduced motion it only snaps.
function Kit.Punch(target: Instance, from: number, seconds: number?, delay: number?)
	local scale = Kit.Scaler(target)
	if not Kit.Motion() then scale.Scale = 1; return end
	scale.Scale = from
	Kit.Tween(scale, seconds or .45, {Scale = 1}, "Pop", delay)
end

-- Fade a whole subtree in or out, remembering each object's own transparency to fade back to.
function Kit.FadeTree(root: Instance, visible: boolean, seconds: number?)
	local time = if Kit.Motion() then seconds or .25 else 0
	local items: {Instance} = root:GetDescendants()
	table.insert(items, root)
	for _, item in items do
		local props: {[string]: number} = {}
		if item:IsA("TextLabel") or item:IsA("TextButton") then
			local base = item:GetAttribute("FadeText")
			if base == nil then item:SetAttribute("FadeText", item.TextTransparency); base = item.TextTransparency end
			props.TextTransparency = if visible then base :: number else 1
		end
		if item:IsA("ImageLabel") or item:IsA("ImageButton") then
			local base = item:GetAttribute("FadeImage")
			if base == nil then item:SetAttribute("FadeImage", item.ImageTransparency); base = item.ImageTransparency end
			props.ImageTransparency = if visible then base :: number else 1
		end
		if item:IsA("GuiObject") then
			local base = item:GetAttribute("FadeBackground")
			if base == nil then item:SetAttribute("FadeBackground", item.BackgroundTransparency); base = item.BackgroundTransparency end
			props.BackgroundTransparency = if visible then base :: number else 1
		end
		if item:IsA("UIStroke") then
			local base = item:GetAttribute("FadeStroke")
			if base == nil then item:SetAttribute("FadeStroke", item.Transparency); base = item.Transparency end
			props.Transparency = if visible then base :: number else 1
		end
		if next(props) then
			if time <= 0 then
				for property, value in props do (item :: any)[property] = value end
			else
				TweenService:Create(item, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
			end
		end
	end
end

-- Ambient life: one shared loop drives light sweeps across hero plates and main buttons and slow
-- spinning rays. Nothing moves with reduced motion or in the frozen UI preview.
-- Plain tables (Roblox can drop instances from weak tables while they are still in use); entries
-- leave when their object is destroyed.
local sweeps: {[UIGradient]: {phase: number, period: number}} = {}
local spinners: {[GuiObject]: number} = {}
local lifeClock = 0
local lifeLoop: RBXScriptConnection? = nil
local SWEEP_SECONDS = 1.1
local SWEEP_BAND = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.4, 1), NumberSequenceKeypoint.new(.5, .5),
	NumberSequenceKeypoint.new(.6, 1), NumberSequenceKeypoint.new(1, 1),
})

local function startLife()
	if lifeLoop then return end
	lifeLoop = RunService.Heartbeat:Connect(function(dt)
		if not Kit.Motion() then return end
		lifeClock += dt
		for gradient, sweep in sweeps do
			local k = ((lifeClock + sweep.phase) % sweep.period) / SWEEP_SECONDS
			gradient.Offset = Vector2.new(if k < 1 then -1 + 2 * k else -1, 0)
		end
		for item, speed in spinners do item.Rotation = (item.Rotation + dt * speed) % 360 end
	end)
end

-- A soft white band that sweeps across a Sky plate (or a Sky button's plate) every few seconds,
-- in the plate's rounded shape so it never spills past the edges.
function Kit.Sheen(plate: Instance, period: number?)
	local target = if plate:IsA("TextButton") then plate:FindFirstChild("Plate", true) else plate
	local body = target and target:FindFirstChild("Body")
	if not target or not body or not body:IsA("ImageLabel") or target:FindFirstChild("Sheen") then return end
	local sheen = Instance.new("ImageLabel")
	sheen.Name, sheen.Size, sheen.Position, sheen.ZIndex = "Sheen", body.Size, body.Position, 3
	sheen.Image, sheen.BackgroundColor3, sheen.BackgroundTransparency = "", Kit.White, 0
	local radius = body:FindFirstChildOfClass("UICorner")
	if radius then radius:Clone().Parent = sheen end
	local band = Instance.new("UIGradient")
	band.Name, band.Rotation, band.Transparency, band.Offset = "Band", 18, SWEEP_BAND, Vector2.new(-1, 0)
	band.Parent = sheen
	sheen.Parent = target
	sweeps[band] = {phase = math.random() * 5, period = period or 5.5}
	band.Destroying:Connect(function() sweeps[band] = nil end)
	startLife()
end

-- Slowly turning sunburst behind a winner or a title.
function Kit.Rays(parent: Instance, size: number, position: UDim2, color: Color3?, transparency: number?): ImageLabel
	local rays = Kit.Icon(parent, "Rays", Kit.Images.Rays, size, color or Kit.Sun)
	rays.AnchorPoint, rays.Position, rays.ImageTransparency, rays.ZIndex = Vector2.new(.5, .5), position, transparency or .55, 0
	spinners[rays] = 14
	rays.Destroying:Connect(function() spinners[rays] = nil end)
	startLife()
	return rays
end

-- Falling confetti over a full-screen layer; pieces clean themselves up.
local CONFETTI_COLORS = {Color3.fromHex("FFD338"), Color3.fromHex("FF4F7B"), Color3.fromHex("56C8FF"), Color3.fromHex("2EE6A6"), Color3.new(1, 1, 1)}
function Kit.Confetti(layer: GuiObject, count: number)
	if not Kit.Motion() then return end
	local width, height = layer.AbsoluteSize.X, layer.AbsoluteSize.Y
	if width < 1 then return end
	for index = 1, count do
		local piece = frame(layer, "Confetti", UDim2.fromOffset(10, 15), UDim2.fromOffset(width * (.05 + math.random() * .9), -24), CONFETTI_COLORS[(index % #CONFETTI_COLORS) + 1], 0)
		piece.ZIndex = 60
		corner(piece, 3)
		local seconds = 1.8 + math.random() * 1.6
		Kit.Tween(piece, seconds, {Position = piece.Position + UDim2.fromOffset((math.random() - .5) * 240, height + 60), Rotation = (math.random() - .5) * 900}, "Out", math.random() * .5)
		task.delay(seconds + .6, function() piece:Destroy() end)
	end
end

-- Sounds: Roblox-owned UI sounds and Roblox-licensed library clips (ProSoundEffects, APM).
-- Picks await the owner's listening approval (docs/LOBBY_UI.md); an empty id stays silent.
Kit.Sounds = {
	Click = {id = "rbxassetid://15675059323", volume = .4}, -- Roblox_UI_Bright_Click
	Beep = {id = "rbxassetid://9117060347", volume = .45}, -- Nasa Transmission Beep 1 (ProSoundEffects)
	Go = {id = "rbxassetid://9117060368", volume = .55}, -- Nasa Transmission Beep 3 (ProSoundEffects), played higher
	Checkpoint = {id = "rbxassetid://15675085146", volume = .5}, -- Roblox_UI_Indicator, pitch rises per checkpoint
	Whoosh = {id = "rbxassetid://15675028888", volume = .35}, -- Roblox_UI_Whoosh_02
	Fanfare = {id = "rbxassetid://1839982934", volume = .45}, -- J Funk (sting), APM Music
	Sting = {id = "rbxassetid://15675043410", volume = .45}, -- Roblox_UI_Tonal_Stinger
	Alert = {id = "rbxassetid://15675062723", volume = .5}, -- Roblox_UI_Whistle_Low
	Pop = {id = "rbxassetid://15675055424", volume = .45}, -- Roblox_UI_Cute_Pop
}

local soundFolder: Folder? = nil
local soundCache: {[string]: Sound} = {}

function Kit.Play(name: string, pitch: number?)
	if Kit.Frozen or Kit.Silent or (localPlayer and localPlayer:GetAttribute("SoundMuted") == true) then return end
	local entry = (Kit.Sounds :: any)[name]
	if not entry or entry.id == "" then return end
	if not soundFolder or not soundFolder.Parent then
		soundFolder = Instance.new("Folder")
		;(soundFolder :: Folder).Name = "UiKitSounds"
		;(soundFolder :: Folder).Parent = SoundService
		table.clear(soundCache)
	end
	local sound = soundCache[name]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name, sound.SoundId, sound.Volume = name, entry.id, entry.volume
		sound.Parent = soundFolder
		soundCache[name] = sound
	end
	sound.PlaybackSpeed = pitch or 1
	SoundService:PlayLocalSound(sound)
end

return Kit
