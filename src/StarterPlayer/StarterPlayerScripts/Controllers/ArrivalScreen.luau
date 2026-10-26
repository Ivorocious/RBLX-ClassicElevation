--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Config = require(ReplicatedStorage.Config.OnboardingConfig)
local Appearance = require(ReplicatedStorage.Shared.RacerAppearance)
local View = require(script.Parent.ArrivalView)
local Stage = require(script.Parent.ArrivalStage)
local Dialog = require(script.Parent.ArrivalDialog)
local Kit = require(script.Parent.UiKit)
local NIGHT, NIGHT_TEXT = Color3.fromRGB(12, 20, 44), Color3.fromRGB(236, 245, 255)
local SOFT_GLOW = "rbxassetid://74781722084941" -- assets/ui/arrival/make_glow.py
local Screen = {}

local function sequence(points)
	local keys = {}
	for _, point in points do table.insert(keys, NumberSequenceKeypoint.new(point[1], point[2])) end
	return NumberSequence.new(keys)
end

function Screen.Create(gui, preview: boolean?)
	local backdrop = View.Make("Frame", "Starfield", gui, {Size = UDim2.fromScale(1,1), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Active = true})
	-- Two stops only: Roblox draws a dark gradient with a middle stop as visible horizontal bands.
	View.Make("UIGradient", "Sky", backdrop, {Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(5,9,22), Color3.fromRGB(9,16,40))})
	-- One radial image per glow: stacked rounded frames showed hard edges across the sky.
	local glows = {}
	for index, definition in {{View.Cyan, 0.16, 0.18, 0.75, 0.7}, {Color3.fromRGB(150,90,255), 0.86, 0.26, 0.6, 0.62}, {View.Mint, 0.5, 1.05, 0.9, 0.6}} do
		local glow = View.Make("ImageLabel", "Glow" .. index, backdrop, {Image = SOFT_GLOW, ImageColor3 = definition[1], ImageTransparency = 0.82,
			BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5,0.5), Position = UDim2.fromScale(definition[2], definition[3]),
			Size = UDim2.fromScale(definition[4] * 1.2, definition[5] * 1.2), ZIndex = 0})
		glows[index] = View.Make("UIScale", "Breath", glow)
	end
	local starData = {}
	local random = Random.new(29)
	for index = 1, 78 do
		local x, y, depth = random:NextNumber(), random:NextNumber(), random:NextNumber()
		local tint = random:NextNumber()
		local size = if depth > 0.9 then 3 elseif depth > 0.55 then 2 else 1.5
		local base = 0.15 + (1 - depth) * 0.5
		local dot = View.Make("Frame", "Star" .. index, backdrop, {Size = UDim2.fromOffset(size, size), Position = UDim2.fromScale(x,y), BorderSizePixel = 0,
			BackgroundColor3 = if tint > 0.9 then Color3.fromRGB(150,236,255) elseif tint > 0.83 then Color3.fromRGB(170,255,228) else Color3.fromRGB(214,228,255),
			BackgroundTransparency = base})
		View.Round(dot, 4)
		table.insert(starData, {dot = dot, x = x, y = y, speed = 0.001 + depth * 0.002, base = base,
			rate = math.pi * 2 / random:NextNumber(2, 6), phase = random:NextNumber(0, math.pi * 2)})
	end
	local shooting = View.Make("Frame", "ShootingStar", backdrop, {Size = UDim2.fromOffset(170,2), AnchorPoint = Vector2.new(1,0.5), Rotation = -18,
		BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Visible = false})
	View.Make("UIGradient", "Tail", shooting, {Transparency = sequence({{0,1},{1,0}})})
	local brand = View.Text("Brand", backdrop, "OBBY <font color='#FFD338'>TOURNAMENT</font>", UDim2.fromOffset(520,48), UDim2.new(0.5,-260,0,60))
	brand.RichText, brand.Font, brand.TextColor3 = true, Enum.Font.LuckiestGuy, Color3.new(1,1,1)
	brand.TextLimit.MaxTextSize = 44
	View.Make("UIStroke", "Outline", brand, {Color = Kit.Navy, Thickness = 3, LineJoinMode = Enum.LineJoinMode.Round})
	local shine = View.Make("UIGradient", "Shine", brand, {Rotation = 15, Offset = Vector2.new(-0.6,0), Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(0.88,0.88,0.88)), ColorSequenceKeypoint.new(0.44, Color3.new(0.88,0.88,0.88)),
		ColorSequenceKeypoint.new(0.5, Color3.new(1,1,1)), ColorSequenceKeypoint.new(0.56, Color3.new(0.88,0.88,0.88)), ColorSequenceKeypoint.new(1, Color3.new(0.88,0.88,0.88))})})
	local emblem = View.Make("ImageLabel", "Emblem", brand, {Image = View.StarCoin, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5,0.5), ScaleType = Enum.ScaleType.Fit})
	local underline = View.Make("Frame", "Underline", brand, {AnchorPoint = Vector2.new(0.5,0), BackgroundColor3 = View.Cyan, BorderSizePixel = 0})
	View.Make("UIGradient", "Fade", underline, {Transparency = sequence({{0,1},{0.5,0},{1,1}})})
	local function placeEmblem()
		-- Measured directly: TextBounds lags a frame behind MaxTextSize changes and is not always re-signalled.
		local measured = TextService:GetTextSize("OBBY TOURNAMENT", math.min(brand.TextLimit.MaxTextSize, brand.Size.Y.Offset), brand.Font, Vector2.new(10000, 10000))
		local textWidth = math.min(measured.X, brand.Size.X.Offset)
		local size = math.floor(brand.Size.Y.Offset * 1.15)
		emblem.Size = UDim2.fromOffset(size, size)
		emblem.Position = UDim2.new(0.5, -textWidth / 2 - 12 - size / 2, 0.5, 0)
		underline.Size, underline.Position = UDim2.fromOffset(textWidth, 2), UDim2.new(0.5, 0, 1, 8)
	end
	local choice = View.Make("Frame", "Choice", backdrop, {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1})
	local stage = Stage.Create(choice)
	stage.SetDescription(Appearance.Description(Config.DefaultLook), 1)
	-- Under the brand so it hides with it in the creator.
	local tagline = View.Text("Tagline", brand, "CHOOSE YOUR RACER", UDim2.fromOffset(320,20), UDim2.new(0.5,-160,0,62))
	tagline.Font, tagline.TextColor3, tagline.TextLimit.MaxTextSize = Enum.Font.GothamBold, Color3.fromRGB(143,190,230), 15
	-- Night glass with a cyan rim, so the choice belongs to the space scene.
	local dock = View.Make("Frame", "ActionDock", choice, {BackgroundColor3 = NIGHT, BackgroundTransparency = 0.08, BorderSizePixel = 0})
	View.Make("UICorner", "Corners", dock, {CornerRadius = UDim.new(0.5,0)})
	View.Make("UIStroke", "Edge", dock, {Color = View.Cyan, Thickness = 2, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	View.Make("Frame", "Divider", dock, {Size = UDim2.new(0,2,1,-36), Position = UDim2.new(0.5,-1,0,18), BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 0.85, BorderSizePixel = 0})
	local fills = {}
	for index, name in {"CreateFill", "AvatarFill"} do
		local fill = View.Make("Frame", name, dock, {AnchorPoint = Vector2.new(index - 1, 0), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Visible = false, ZIndex = 1})
		View.Make("UICorner", "Corners", fill, {CornerRadius = UDim.new(0.5,0)})
		View.Make("UIGradient", "Mint", fill, {Color = ColorSequence.new(View.Mint, View.Cyan)})
		fills[index] = fill
	end
	local create = View.Button("CreateRacer", dock, "Create racer", UDim2.new(0.5,-12,0,44), UDim2.fromOffset(6,5))
	create.Padding.PaddingTop, create.Padding.PaddingBottom = UDim.new(), UDim.new()
	local useAvatar = View.Button("UseAvatar", dock, "Use my avatar", UDim2.new(0.5,-12,1,-12), UDim2.new(0.5,6,0,6))
	local buttons = {create, useAvatar}
	local focusRing = View.Make("Frame", "FocusRing", nil, {BackgroundTransparency = 1, Size = UDim2.fromScale(1,1)})
	View.Make("UICorner", "Corners", focusRing, {CornerRadius = UDim.new(0.5,0)})
	View.Make("UIStroke", "Ring", focusRing, {Color = View.Cyan, Thickness = 3})
	local arrows = {}
	for index, button in buttons do
		button.ZIndex, button.Font, button.SelectionImageObject = 2, Enum.Font.GothamBlack, focusRing
		arrows[index] = View.Make("TextLabel", "Arrow", button, {Text = "›", Font = Enum.Font.GothamBlack, TextSize = 34, TextColor3 = NIGHT_TEXT,
			BackgroundTransparency = 1, Size = UDim2.fromOffset(20,40), AnchorPoint = Vector2.new(index - 1, 0.5)})
	end
	local bonusRow = View.Make("Frame", "Bonus", create, {Size = UDim2.fromOffset(100,16), AnchorPoint = Vector2.new(0.5,1), BackgroundTransparency = 1, Visible = false})
	View.Make("ImageLabel", "Coin", bonusRow, {Image = View.StarCoin, Size = UDim2.fromOffset(16,16), BackgroundTransparency = 1})
	local bonusText = View.Make("TextLabel", "Amount", bonusRow, {Text = "", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.fromRGB(255,216,106),
		TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1, Size = UDim2.new(1,-20,1,0), Position = UDim2.fromOffset(20,0)})
	-- A matching second line under "Use my avatar" keeps both choices the same shape.
	local avatarLine = View.Make("TextLabel", "Subline", useAvatar, {Text = "Race as your Roblox look", Font = Enum.Font.GothamBold, TextSize = 13,
		TextColor3 = Color3.fromRGB(159,186,224), BackgroundTransparency = 1, Size = UDim2.fromOffset(220,16), AnchorPoint = Vector2.new(0.5,1), Visible = false})
	local dialog = Dialog.Create(backdrop, preview, dock)
	local focusedChoice, still, roomy = 0, false, true
	local fillLevel = {0, 0}
	local function applyFills()
		for index, fill in fills do
			local value = fillLevel[index]
			fill.Visible = value > 0.02
			fill.BackgroundTransparency = 1 - value
			fill.Size = UDim2.new(0.5, -8, 1, -8)
			fill.Position = UDim2.new(index - 1, if index == 1 then 4 else -4, 0, 4)
			-- The button's bottom padding (room for its second line) also shifts children, so undo half of it to centre the arrow on the bar.
			local padding = buttons[index].Padding.PaddingBottom.Offset
			arrows[index].Position = UDim2.new(index - 1, (if index == 1 then 2 else -2) + (if index == 1 then 6 else -6) * value, 0.5, padding / 2)
		end
	end
	local function highlight(index)
		focusedChoice = index
		stage.SetFocus(index)
		for i, button in buttons do
			local selected = i == index
			button.BackgroundTransparency = 1
			-- Dark text only on the bright mint fill of the chosen side.
			button.TextColor3 = if selected then View.Ink else NIGHT_TEXT
			arrows[i].TextColor3 = button.TextColor3
			button:SetAttribute("Pressed", selected)
		end
		bonusText.TextColor3 = if index == 1 then Color3.fromRGB(108,72,0) else Color3.fromRGB(255,216,106)
		avatarLine.TextColor3 = if index == 2 then Color3.fromRGB(20,60,80) else Color3.fromRGB(159,186,224)
		if still then
			for i in fillLevel do fillLevel[i] = if i == index then 1 else 0 end
		end
		applyFills()
	end
	for index, button in buttons do
		button.BackgroundTransparency, button.AutoButtonColor = 1, false
		button.Corners.CornerRadius = UDim.new(0.5,0)
		button.TextLimit.MaxTextSize = 27
		button.MouseEnter:Connect(function() if not dialog.IsOpen() then highlight(index) end end)
		button.SelectionGained:Connect(function() if not dialog.IsOpen() then highlight(index) end end)
		local function leave()
			if focusedChoice == index and not dialog.IsOpen() then highlight(0) end
		end
		button.MouseLeave:Connect(leave)
		button.SelectionLost:Connect(leave)
	end
	for index, target in stage.HitTargets do
		target.MouseEnter:Connect(function() if not dialog.IsOpen() then highlight(index) end end)
		target.MouseLeave:Connect(function() if focusedChoice == index and not dialog.IsOpen() then highlight(0) end end)
	end
	create.NextSelectionRight, useAvatar.NextSelectionLeft = useAvatar, create
	local reward = View.Text("GoldBonus", choice, "+" .. Config.CreationBonus .. " coins", UDim2.fromOffset(120,24), UDim2.new())
	-- The floating reward is one gold badge above the Create racer side, its coin tucked into the left end.
	reward.AnchorPoint, reward.Font, reward.Size = Vector2.new(0.5,1), Enum.Font.GothamBlack, UDim2.fromOffset(146,32)
	reward.TextColor3, reward.TextLimit.MaxTextSize = Kit.Navy, 16
	-- Above the stage viewport, so a waving racer passes behind the badge.
	reward.BackgroundColor3, reward.BackgroundTransparency, reward.ZIndex = Kit.Sun, 0, 3
	View.Make("UICorner", "Corners", reward, {CornerRadius = UDim.new(0.5,0)})
	View.Make("UIStroke", "Edge", reward, {Color = Kit.Navy, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
	View.Make("UIPadding", "Padding", reward, {PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,6), PaddingLeft = UDim.new(0,32), PaddingRight = UDim.new(0,12)})
	-- Children sit inside the padding, so -38 puts the coin 6 px past the badge's left edge.
	local rewardCoin = View.Make("ImageLabel", "Coin", reward, {Image = View.StarCoin, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromOffset(36,36), AnchorPoint = Vector2.new(0,0.5), Position = UDim2.new(0,-38,0.5,0)})
	local function syncBonus()
		bonusText.Text = reward.Text
		-- Title and second line sit as one block centred in the bar.
		bonusRow.Visible = reward.Visible and roomy
		create.Padding.PaddingBottom = UDim.new(0, if bonusRow.Visible then 32 else 0)
		bonusRow.Position = UDim2.new(0.5, 0, 1, if bonusRow.Visible then 22 else 0)
		avatarLine.Visible = roomy
		useAvatar.Padding.PaddingTop, useAvatar.Padding.PaddingBottom = UDim.new(), UDim.new(0, if roomy then 32 else 0)
		avatarLine.Position = UDim2.new(0.5, 0, 1, if roomy then 22 else 0)
	end
	reward:GetPropertyChangedSignal("Text"):Connect(syncBonus)
	reward:GetPropertyChangedSignal("Visible"):Connect(syncBonus)
	local footer = View.Text("ChangeAnytime", choice, "You can change this anytime from My racer", UDim2.new(0.6,0,0,24), UDim2.fromScale(0.2,0.86))
	footer.TextColor3, footer.TextLimit.MaxTextSize = Color3.fromRGB(143,163,200), 16
	local status = View.Text("Status", backdrop, "Loading your profile…", UDim2.new(0.56,0,0,28), UDim2.new(0,24,1,-47))
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextColor3 = Color3.fromRGB(182,199,220)
	status.TextLimit.MaxTextSize = 15
	local soundButton = View.Pill(View.Button("Sound", backdrop, "Sound on", UDim2.fromOffset(104,44), UDim2.new(1,-224,1,-53), true))
	local motionButton = View.Pill(View.Button("Motion", backdrop, "Motion on", UDim2.fromOffset(104,44), UDim2.new(1,-112,1,-53), true))
	soundButton.TextLimit.MaxTextSize, motionButton.TextLimit.MaxTextSize = 14, 14
	local retry = View.Button("Retry", backdrop, "Retry", UDim2.fromOffset(160,48), UDim2.new(0.5,-80,0.52,0))
	retry.Visible = false
	local editor = View.Make("Frame", "Creator", backdrop, {Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Visible = false})
	local editPreview = View.Preview("RacerPreview", editor, UDim2.fromScale(0.40,0.66), UDim2.fromScale(0.08,0.17))
	local options = View.Card("Options", editor)
	local heading = View.Text("Heading", options, "Make it yours", UDim2.new(0.9,0,0,40), UDim2.fromScale(0.05,0.04))
	heading.Font = Enum.Font.GothamBlack
	local wardrobe = View.Make("ScrollingFrame", "Wardrobe", options, {Position = UDim2.fromScale(0.05,0.17), Size = UDim2.fromScale(0.9,0.60), BackgroundTransparency = 1,
		BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = View.Cyan})
	View.Make("UIListLayout", "Rows", wardrobe, {Padding = UDim.new(0,10), SortOrder = Enum.SortOrder.LayoutOrder})
	-- The selected option's outline sits outside the button, so the scroll area leaves room for it.
	View.Make("UIPadding", "Room", wardrobe, {PaddingLeft = UDim.new(0,3), PaddingRight = UDim.new(0,3), PaddingTop = UDim.new(0,3), PaddingBottom = UDim.new(0,3)})
	local look = table.clone(Config.DefaultLook)
	local buttonsByKey = {}
	local rowsByKey = {}
	local function updateLook()
		editPreview.SetDescription(Appearance.Description(look))
		for key, items in buttonsByKey do
			for index, button in items do button.SelectedStroke.Enabled = look[key] == index end
		end
	end
	for order, definition in {{"hair", "Hair", Config.Hair}, {"skin", "Skin", Config.Skin}, {"top", "Top", Config.Colors}, {"legs", "Legs", Config.Colors}} do
		local key, title, values = definition[1], definition[2], definition[3]
		local row = View.Make("Frame", title, wardrobe, {Size = UDim2.new(1,-8,0,74), BackgroundTransparency = 1, LayoutOrder = order})
		rowsByKey[key] = row
		local label = View.Text("Label", row, title, UDim2.new(1,0,0,22), UDim2.new())
		label.TextXAlignment, label.TextLimit.MaxTextSize = Enum.TextXAlignment.Left, 17
		label.TextColor3 = Color3.fromRGB(159,179,217)
		buttonsByKey[key] = {}
		for index, value in values do
			local button = View.Button(key .. index, row, if key == "hair" then value.name else "", UDim2.new(1/#values,-6,0,42), UDim2.new((index-1)/#values,2,0,27), true)
			button.TextLimit.MaxTextSize = 13
			button.Corners.CornerRadius = UDim.new(0,10)
			if key ~= "hair" then button.BackgroundColor3 = Color3.fromRGB(value[1],value[2],value[3]) end
			View.Make("UIStroke", "SelectedStroke", button, {Color = View.Mint, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Enabled = look[key] == index})
			button.Activated:Connect(function() look[key] = index; updateLook() end)
			table.insert(buttonsByKey[key], button)
		end
	end
	local save = View.Button("SaveRacer", options, "Save & play", UDim2.fromScale(0.9,0.11), UDim2.fromScale(0.05,0.83))
	save.Font = Enum.Font.GothamBlack
	local back = View.Pill(View.Button("Back", editor, "‹ Back", UDim2.fromOffset(110,44), UDim2.fromOffset(24,76), true))
	local editBonus = View.Text("CreationBonus", options, "+" .. Config.CreationBonus .. " coins · one time", UDim2.fromScale(0.9,0.06), UDim2.fromScale(0.05,0.94))
	editBonus.TextColor3, editBonus.TextLimit.MaxTextSize = Color3.fromRGB(255,216,106), 14
	local reopen = View.Button("EditRacer", gui, "My racer", UDim2.fromOffset(126,42), UDim2.new(0,20,1,-62), true)
	reopen.Visible = false

	local cancel = View.Pill(View.Button("KeepLook", choice, "‹ Keep current look", UDim2.fromOffset(220,44), UDim2.fromOffset(24,76), true))
	cancel.Visible = false
	local function layout()
		local size = backdrop.AbsoluteSize
		local portrait = size.X < size.Y * 0.95
		footer.Visible = true
		wardrobe.Size, wardrobe.Position = UDim2.new(0.9,0,1,-160), UDim2.new(0.05,0,0,70)
		save.Size, save.Position = UDim2.new(0.9,0,0,44), UDim2.new(0.05,0,1,-82)
		for key, items in buttonsByKey do
			local columns = if portrait and #items > 4 then math.ceil(#items / 2) else #items
			rowsByKey[key].Size = UDim2.new(1,-8,0,if columns < #items then 124 else 74)
			for index, button in items do
				button.Size = UDim2.new(1/columns,-6,0,44)
				button.Position = UDim2.new(((index-1)%columns)/columns,2,0,27 + math.floor((index-1)/columns)*50)
			end
		end
		local compact = size.Y < 540
		local dockWidth = math.min(size.X * (if portrait then 0.94 else 0.74), 1060)
		local dockHeight = if compact then 64 else 82
		local dockY = if portrait then size.Y * 0.65 else size.Y * 0.77
		if compact then dockY = size.Y - 121 end
		dock.Size, dock.Position = UDim2.fromOffset(dockWidth, dockHeight), UDim2.fromOffset((size.X-dockWidth)/2, dockY)
		create.Size, create.Position = UDim2.new(0.5,-8,1,-8), UDim2.fromOffset(4,4)
		useAvatar.Size, useAvatar.Position = UDim2.new(0.5,-8,1,-8), UDim2.new(0.5,4,0,4)
		create.TextLimit.MaxTextSize = if portrait then 19 else 27
		useAvatar.TextLimit.MaxTextSize = if portrait then 19 else 27
		for _, arrow in arrows do arrow.Visible = dockWidth / 2 >= 300 end
		roomy = not portrait and not compact
		syncBonus()
		reward.TextLimit.MaxTextSize = if portrait or compact then 13 else 16
		highlight(focusedChoice)
		local stageTop = if compact then 70 else 150
		stage.frame.Size, stage.frame.Position = UDim2.new(if portrait then 1 else 0.86,0,0,math.max(100,dockY-stageTop-10)), UDim2.new(if portrait then 0 else 0.07,0,0,stageTop)
		local brandWidth = math.min(520, size.X - 32)
		brand.Size, brand.Position = UDim2.fromOffset(brandWidth, if compact then 30 else 46), UDim2.new(0.5,-brandWidth/2,0,if compact then 24 else 56)
		brand.TextLimit.MaxTextSize = if compact or portrait then 26 else 42
		tagline.Visible = not compact
		placeEmblem()
		footer.Size = UDim2.fromOffset(if portrait then size.X-32 elseif compact then 260 else 360,22)
		footer.Position = if portrait then UDim2.new(0,16,1,-86) elseif compact then UDim2.new(0,24,1,-45) else UDim2.new(0.5,-180,0,dockY+dockHeight+8)
		footer.TextXAlignment = if portrait or not compact then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left
		footer.TextLimit.MaxTextSize = if compact then 13 else 14
		-- Top-left like the creator's Back pill, clear of the title and tagline.
		cancel.Size, cancel.Position = UDim2.fromOffset(if compact then 180 else 220, if compact then 36 else 44), UDim2.fromOffset(if compact then 16 else 24, if compact then 64 else 76)
		cancel.TextLimit.MaxTextSize = if compact then 15 else 18
		if portrait then
			options.Size, options.Position = UDim2.fromScale(0.92,0.47), UDim2.fromScale(0.04,0.40)
			editPreview.frame.Size, editPreview.frame.Position = UDim2.fromScale(0.75,0.27), UDim2.fromScale(0.125,0.12)
			status.Size, status.Position = UDim2.new(1,-32,0,28), UDim2.new(0,16,1,-96)
		else
			options.Size, options.Position = UDim2.fromScale(0.43,0.71), UDim2.fromScale(0.5,0.15)
			editPreview.frame.Size, editPreview.frame.Position = UDim2.fromScale(0.40,0.66), UDim2.fromScale(0.06,0.17)
			status.Size, status.Position = UDim2.new(0.56,0,0,28), UDim2.new(0,24,1,-47)
		end
	end
	backdrop:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	local skyClock, skyStep, nextShot, shotStart = 0, 0, 3, -10
	local shotOrigin = Vector2.zero
	local shotRandom = Random.new()
	local function setStill(value)
		still = value
		if not value then return end
		for _, star in starData do star.dot.BackgroundTransparency = star.base end
		for _, scale in glows do scale.Scale = 1 end
		shooting.Visible, shine.Offset = false, Vector2.new(-0.6,0)
		for i in fillLevel do fillLevel[i] = if i == focusedChoice then 1 else 0 end
		applyFills()
	end
	local function update(dt, reducedMotion)
		if not backdrop.Visible or not gui.Parent then return end
		if reducedMotion ~= still then setStill(reducedMotion) end
		if choice.Visible then
			-- Inside the choice bar the pointer's half decides the highlight each frame, so a fast move
			-- between the halves can never leave the wrong side lit; elsewhere hover events decide.
			local selected = GuiService.SelectedObject
			local keyboardFocus = selected ~= nil and (selected == create or selected == useAvatar)
			if not dialog.IsOpen() and UserInputService.MouseEnabled and not keyboardFocus then
				local mouse = UserInputService:GetMouseLocation()
				local origin, extent = dock.AbsolutePosition, dock.AbsoluteSize
				if mouse.X >= origin.X and mouse.X <= origin.X + extent.X and mouse.Y >= origin.Y and mouse.Y <= origin.Y + extent.Y then
					local side = if mouse.X < origin.X + extent.X / 2 then 1 else 2
					if side ~= focusedChoice then highlight(side) end
				end
			end
			stage.Update(dt)
			local anchor = stage.BonusPosition() + stage.frame.AbsolutePosition - choice.AbsolutePosition
			reward.Position = UDim2.fromOffset(anchor.X, anchor.Y)
			rewardCoin.Rotation = if reducedMotion then 0 else math.sin(skyClock * 1.1) * 8
			local moving = false
			for index, value in fillLevel do
				local target = if index == focusedChoice then 1 else 0
				if value ~= target then
					fillLevel[index] = if math.abs(target - value) < 0.01 then target else value + (target - value) * math.min(1, dt * 9)
					moving = true
				end
			end
			if moving then applyFills() end
		end
		if reducedMotion then return end
		skyStep += math.min(dt, 0.1)
		if skyStep < 1/30 then return end
		local step = skyStep
		skyStep = 0
		skyClock += step
		for _, star in starData do
			star.x = (star.x - step * star.speed) % 1
			star.y = (star.y + step * star.speed * 0.35) % 1
			star.dot.Position = UDim2.fromScale(star.x, star.y)
			star.dot.BackgroundTransparency = star.base + (0.9 - star.base) * (0.5 - 0.5 * math.cos(skyClock * star.rate + star.phase))
		end
		for index, scale in glows do scale.Scale = 1 + 0.05 * math.sin(skyClock * 0.6 + index * 2) end
		if editor.Visible then editPreview.Sway(skyClock) end
		local sweep = (skyClock % 4.2) / 1.2
		shine.Offset = Vector2.new(if sweep < 1 then -0.6 + 1.2 * sweep else -0.6, 0)
		if skyClock >= nextShot then
			shotStart, nextShot = skyClock, skyClock + shotRandom:NextNumber(3.5, 7)
			-- Start in the left or right sky so a streak never crosses the title.
			local left = shotRandom:NextNumber() < 0.5
			shotOrigin = Vector2.new(if left then shotRandom:NextNumber(0.02, 0.12) else shotRandom:NextNumber(0.67, 0.78), shotRandom:NextNumber(0.1, 0.4))
		end
		local progress = (skyClock - shotStart) / 0.9
		shooting.Visible = progress < 1
		if progress < 1 then
			local travel = 1 - (1 - progress) ^ 2
			shooting.Position = UDim2.new(shotOrigin.X, 323 * travel, shotOrigin.Y, -105 * travel)
			shooting.BackgroundTransparency = if progress < 0.2 then 1 - progress / 0.2 else (progress - 0.2) / 0.8
		end
	end
	return {
		Backdrop = backdrop,
		Brand = brand,
		Choice = choice,
		Stage = stage,
		Dock = dock,
		Create = create,
		UseAvatar = useAvatar,
		Dialog = dialog,
		Reward = reward,
		Footer = footer,
		Status = status,
		SoundButton = soundButton,
		MotionButton = motionButton,
		Retry = retry,
		Editor = editor,
		EditPreview = editPreview,
		Options = options,
		Save = save,
		Back = back,
		EditBonus = editBonus,
		Reopen = reopen,
		Cancel = cancel,
		Look = look,
		UpdateLook = updateLook,
		Highlight = highlight,
		Layout = layout,
		Update = update,
		SetLook = function(value)
			for key in Config.DefaultLook do look[key] = value[key] end
			updateLook()
		end,
	}
end

return Screen
