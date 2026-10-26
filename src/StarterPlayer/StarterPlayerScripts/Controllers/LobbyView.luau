--!strict
-- Lobby HUD in the Sky Rush look (brief "Lobby"): icon rail, phase capsule, Coins and Keys,
-- next-race card, activity toasts and the shared lobby dialog. LobbyUiController owns the state.
local Kit = require(script.Parent.UiKit)
local Icons = require(script.Parent.LobbyIcons)
local Reveal = require(script.Parent.UiReveal)
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local View = {}

-- Authored on the concept page's 1280 x 720 stage.
local DESIGN = Vector2.new(1280, 720)
local RAIL = {{"Shop", "Shop"}, {"MyRacer", "My racer"}, {"Records", "Records"}, {"Settings", "Settings"}}
local CARD_WIDTH = 334
local COURSE_TEXT = 38
local DIAL_TICKS = 24

local function scaler(item: Instance): UIScale
	local scale = Instance.new("UIScale")
	scale.Name, scale.Parent = "LayoutScale", item
	return scale
end

local function art(parent: Instance, name: string, size: UDim2, position: UDim2): ImageLabel
	local image = Instance.new("ImageLabel")
	image.Name, image.Size, image.Position = name, size, position
	image.BackgroundColor3, image.ScaleType = Kit.Sky, Enum.ScaleType.Crop
	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius, imageCorner.Parent = UDim.new(0, 8), image
	Kit.Stroke(image, Kit.Navy, 3, true)
	-- Courses without card art get a clean flag tile.
	local flag = Kit.Icon(image, "Fallback", Kit.Images.FinishFlag, 44)
	flag.AnchorPoint, flag.Position = Vector2.new(.5, .5), UDim2.fromScale(.5, .5)
	image:GetPropertyChangedSignal("Image"):Connect(function() flag.Visible = image.Image == "" end)
	image.Parent = parent
	return image
end

local function railButton(parent: Instance, name: string, title: string, order: number, activate: () -> ()): TextButton
	local button = Instance.new("TextButton")
	button.Name, button.Text, button.AutoButtonColor, button.BackgroundTransparency = name, "", false, 1
	button.Size, button.LayoutOrder, button.Selectable = UDim2.fromOffset(96, 96), order, true
	button:SetAttribute("Available", true)
	local focusImage = Instance.new("ImageLabel")
	focusImage.Name, focusImage.BackgroundTransparency, focusImage.Image, focusImage.Size = "FocusImage", 1, "", UDim2.fromScale(1, 1)
	button.SelectionImageObject, focusImage.Parent = focusImage, button
	local body = Kit.Frame(button, "Body", UDim2.fromScale(1, 1), UDim2.new())
	local pop = Instance.new("UIScale")
	pop.Name, pop.Parent = "Feedback", body
	local ring = Kit.SkyPlate(body, "Ring", UDim2.new(1, 10, 1, 10), UDim2.fromOffset(-5, -5), {fill = "White", class = "M", shadow = false, highlight = false})
	ring.Visible = false
	Kit.SkyPlate(body, "Plate", UDim2.fromScale(1, 1), UDim2.new(), {class = "M"})
	local icon = Icons.Create(body, name == "Shop" and "Shop" or name, UDim2.fromOffset(12, -10), 72)
	icon.Name, icon.ZIndex = "Icon", 6
	for _, item in icon:GetDescendants() do if item:IsA("GuiObject") then item.ZIndex = 6 end end
	local label = Kit.Caption(body, "Label", title, 16, Kit.White)
	label.FontFace, label.Size, label.Position, label.ZIndex = Kit.Display, UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 1, -26), 6
	Kit.Stroke(label, Kit.Navy, 3.5, false)
	button.Parent = parent
	local hovered, focused = false, false
	local function render()
		local available = button:GetAttribute("Available") ~= false
		local selected = button:GetAttribute("Selected") == true
		ring.Visible = focused or selected
		label.TextTransparency = if available then 0 else .45
		local lifted = (hovered or selected or focused) and available
		Kit.Tween(pop, .18, {Scale = if lifted then 1.06 else 1}, "Pop")
		Kit.Tween(body, .18, {Rotation = if lifted then -2 else 0, Position = UDim2.fromOffset(0, if lifted then -3 else 0)}, "Pop")
	end
	button.MouseEnter:Connect(function() hovered = true; render() end)
	button.MouseLeave:Connect(function() hovered = false; render() end)
	button.SelectionGained:Connect(function() focused = true; render() end)
	button.SelectionLost:Connect(function() focused = false; render() end)
	button:GetAttributeChangedSignal("Available"):Connect(render)
	button:GetAttributeChangedSignal("Selected"):Connect(render)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			Kit.Tween(pop, .1, {Scale = .9}, "Out")
		end
	end)
	button.Activated:Connect(function()
		if button:GetAttribute("Available") == false then return end
		Kit.Play("Click")
		activate()
	end)
	return button
end

local function walletPill(parent: Instance, name: string, image: string, x: number, activate: () -> ()): (TextButton, TextLabel)
	local button = Instance.new("TextButton")
	button.Name, button.Text, button.AutoButtonColor, button.BackgroundTransparency = name, "", false, 1
	button.Size, button.Position, button.Selectable = UDim2.fromOffset(158, 56), UDim2.fromOffset(x, 0), true
	button:SetAttribute("Available", true)
	local plate = Kit.SkyPlate(button, "Plate", UDim2.fromScale(1, 1), UDim2.new(), {class = "S", stripes = false, height = 56})
	-- The sweep is clipped to the pill's inside so it never shows past the rounded ends.
	local clip = Kit.Frame(plate, "GlintClip", UDim2.new(1, -24, 1, -10), UDim2.fromOffset(12, 5))
	clip.ClipsDescendants, clip.ZIndex = true, 3
	local shine = Kit.Frame(clip, "Glint", UDim2.fromOffset(22, 70), UDim2.fromOffset(-40, -12), Kit.White, .55)
	shine.Rotation, shine.ZIndex = 20, 3
	local icon = Kit.Icon(button, "Icon", image, 68)
	icon.Position, icon.ZIndex = UDim2.fromOffset(-14, -7), 6
	local balance = Kit.Big(button, "Balance", "—", 30)
	balance.Position, balance.Size, balance.ZIndex = UDim2.fromOffset(58, 13), UDim2.new(1, -66, 0, 30), 6
	Kit.SetBigAlignment(balance, Enum.TextXAlignment.Left)
	for _, label in Kit.BigLabels(balance) do label.ZIndex = 6 end
	button.Parent = parent
	button.Activated:Connect(function() Kit.Play("Click"); activate() end)
	-- A light sweep across the pill every few seconds, as on the page.
	task.spawn(function()
		while button.Parent do
			task.wait(if name == "Keys" then 4.6 else 3.4)
			if Kit.Motion() and button.Parent then
				shine.Position = UDim2.fromOffset(-40, -12)
				Kit.Tween(shine, 1, {Position = UDim2.fromOffset(170, -12)}, "Linear")
			end
		end
	end)
	return button, Kit.BigLabels(balance)[1]
end

function View.Create(screen: ScreenGui | Frame, actions: {[string]: () -> ()})
	local ui: any = {Labels = {}, Buttons = {}, NavIcons = {}, NavLabels = {}, ProgressNodes = {}, Toasts = {}}
	local root = Kit.Frame(screen, "SafeArea", UDim2.fromScale(1, 1), UDim2.new())
	ui.Root = root

	-- Icon rail (left).
	local menu = Kit.Frame(root, "Menu", UDim2.fromOffset(96, 96 * 4 + 16 * 3), UDim2.new())
	local menuList = Instance.new("UIListLayout")
	menuList.Padding, menuList.SortOrder, menuList.Parent = UDim.new(0, 16), Enum.SortOrder.LayoutOrder, menu
	ui.Menu, ui.MenuScale = menu, scaler(menu)
	for index, entry in RAIL do
		local button = railButton(menu, entry[1], entry[2], index, actions[entry[1]])
		ui.Buttons[entry[1]] = button
		ui.NavIcons[entry[1]] = button.Body.Icon
		ui.NavLabels[entry[1]] = button.Body.Label
	end

	-- Phase capsule (top centre): yellow hero plate with a draining dial.
	local phase = Kit.Frame(root, "Phase", UDim2.fromOffset(320, 86), UDim2.new())
	phase.AnchorPoint = Vector2.new(.5, 0)
	ui.Phase, ui.PhaseScale = phase, scaler(phase)
	local capsule = Kit.SkyPlate(phase, "Capsule", UDim2.fromScale(1, 1), UDim2.new(), {fill = "Hero", class = "M", stripes = true, height = 86})
	Kit.Sheen(capsule, 4.5)
	local content = Kit.Content(capsule)
	-- The approved clock icon inside a ring of ticks that drains as the phase runs out.
	local dial = Kit.Frame(content, "Dial", UDim2.fromOffset(64, 64), UDim2.fromOffset(30, 11))
	ui.DialTicks = {}
	for tick = 1, DIAL_TICKS do
		-- Full-height arms rotate about the dial centre (rotation pivots on an object's centre).
		local arm = Kit.Frame(dial, "Tick" .. tick, UDim2.new(0, 4, 1, 0), UDim2.fromScale(.5, .5))
		arm.AnchorPoint, arm.Rotation = Vector2.new(.5, .5), (tick - 1) * 360 / DIAL_TICKS
		local mark = Kit.Frame(arm, "Mark", UDim2.new(1, 0, 0, 9), UDim2.new(), Kit.Navy, 0)
		local markCorner = Instance.new("UICorner")
		markCorner.CornerRadius, markCorner.Parent = UDim.new(1, 0), mark
		ui.DialTicks[tick] = mark
	end
	local clock = Icons.Create(dial, "Clock", UDim2.fromOffset(12, 12), 40)
	ui.Clock = clock
	local heading = Kit.SkyCaption(content, "Heading", "", 13, true)
	heading.Position, heading.Size, heading.TextXAlignment = UDim2.fromOffset(106, 18), UDim2.fromOffset(196, 16), Enum.TextXAlignment.Left
	local timer = Kit.SkyBig(content, "Timer", "", 40)
	timer.Position, timer.Size = UDim2.fromOffset(104, 36), UDim2.fromOffset(196, 40)
	Kit.SetBigAlignment(timer, Enum.TextXAlignment.Left)
	for _, label in Kit.BigLabels(timer) do label.TextTruncate = Enum.TextTruncate.AtEnd end
	ui.PhaseCapsule, ui.TimerBig = capsule, timer
	ui.Labels.Phase, ui.Labels.Timer = heading, Kit.BigLabels(timer)[1]

	-- Coins and Keys (top right). Keys show a dash until a real balance exists; "+" opens the Shop.
	local currency = Kit.Frame(root, "Currencies", UDim2.fromOffset(336, 64), UDim2.new())
	currency.AnchorPoint = Vector2.new(1, 0)
	ui.Currency, ui.CurrencyScale = currency, scaler(currency)
	local gold, goldLabel = walletPill(currency, "Gold", Kit.Images.StarCoin, 0, actions.Gold)
	local keys, keysLabel = walletPill(currency, "Keys", Kit.Images.SkyKey, 178, actions.Keys)
	ui.Buttons.Gold, ui.Buttons.Keys, ui.Labels.Gold, ui.Labels.Keys = gold, keys, goldLabel, keysLabel
	ui.KeysIcon = keys:FindFirstChild("Icon")
	local plus = Kit.SkyButton(keys, "KeysPlus", "+", UDim2.fromOffset(38, 38), UDim2.new(1, -16, 0, -14), actions.Shop, "Primary", 26)
	plus.ZIndex = 7
	ui.Buttons.KeysPlus = plus

	-- Next-race card (right).
	local stack = Kit.Frame(root, "RaceStack", UDim2.fromOffset(CARD_WIDTH, 360), UDim2.new())
	stack.AnchorPoint = Vector2.new(1, 0)
	ui.Stack, ui.StackScale = stack, scaler(stack)
	local race = Kit.SkyPlate(stack, "NextRace", UDim2.fromOffset(CARD_WIDTH, 360), UDim2.new(), {class = "L", stripes = true})
	Kit.Sheen(race, 6.5)
	ui.Race = race
	local card = Kit.Content(race)
	local artFrame = Kit.Frame(card, "Art", UDim2.fromOffset(CARD_WIDTH - 52, 118), UDim2.fromOffset(30, 14))
	ui.ArtFrame = artFrame
	ui.ArtSingle = art(artFrame, "Single", UDim2.fromScale(1, 1), UDim2.new())
	ui.ArtCollage = {}
	for index = 1, 4 do
		local column, row = (index - 1) % 2, math.floor((index - 1) / 2)
		ui.ArtCollage[index] = art(artFrame, "Collage" .. index, UDim2.new(.5, -3, .5, -3), UDim2.new(column * .5, column * 3, row * .5, row * 3))
	end
	local heading2 = Kit.SkyCaption(card, "Heading", "Next race", 13)
	heading2.Position, heading2.Size, heading2.TextXAlignment = UDim2.fromOffset(24, 142), UDim2.fromOffset(CARD_WIDTH - 60, 16), Enum.TextXAlignment.Left
	local course = Kit.SkyBig(card, "Course", "", COURSE_TEXT)
	course.Position, course.Size = UDim2.fromOffset(20, 160), UDim2.fromOffset(CARD_WIDTH - 50, 40)
	Kit.SetBigAlignment(course, Enum.TextXAlignment.Left)
	for _, label in Kit.BigLabels(course) do label.TextScaled = false; label.TextTruncate = Enum.TextTruncate.AtEnd end
	local format = Kit.Body(card, "Format", "", 15, Color3.fromHex("EAF4FF"))
	format.Position, format.Size, format.TextXAlignment = UDim2.fromOffset(18, 206), UDim2.fromOffset(CARD_WIDTH - 46, 18), Enum.TextXAlignment.Left
	format.TextTruncate = Enum.TextTruncate.AtEnd
	ui.Labels.Heading, ui.Labels.Format, ui.CourseBig = heading2, format, course
	ui.Labels.Course = Kit.BigLabels(course)[1]
	local status = Kit.Chip(card, "StatusChip", "You're in", 16, "Good")
	status.Position, status.Visible = UDim2.fromOffset(18, 234), false
	ui.StatusChip = status
	ui.Labels.Status = status:FindFirstChild("Text") :: TextLabel
	ui.Buttons.Go = Kit.SkyButton(card, "Go", "Start racing", UDim2.fromOffset(CARD_WIDTH - 60, 50), UDim2.fromOffset(24, 236), actions.Go, "Primary", 20)
	ui.Buttons.RaceOptions = Kit.SkyButton(card, "RaceOptions", "Race options", UDim2.fromOffset(136, 42), UDim2.fromOffset(20, 298), actions.RaceOptions, "Alt", 15)
	ui.Buttons.Second = Kit.SkyButton(card, "Second", "Practice", UDim2.fromOffset(136, 42), UDim2.fromOffset(170, 298), actions.Second, "Alt", 15)
	ui.OptionsLabel = ui.Buttons.RaceOptions:FindFirstChild("Label", true)

	-- Quests stay out of the HUD for now; the controller still updates these hidden labels.
	local quest = Kit.Frame(stack, "QuestTicket", UDim2.fromOffset(CARD_WIDTH, 0), UDim2.new())
	quest.Visible = false
	ui.Quest = quest
	ui.Labels.QuestHeading = Kit.Body(quest, "Heading", "QUESTS", 13)
	ui.Labels.Quest = Kit.Body(quest, "Objective", "", 13)
	ui.Labels.QuestHint = Kit.Body(quest, "Progress", "", 13)
	ui.ProgressTrack = Kit.Frame(quest, "ProgressTrack", UDim2.new(), UDim2.new())
	ui.Buttons.Quests = Kit.SkyButton(quest, "ViewAll", "View all", UDim2.fromOffset(120, 44), UDim2.new(), actions.Quests, "Alt", 15)
	ui.Buttons.Quests.Visible = false

	-- Activity toasts (bottom left).
	local feed = Kit.Frame(root, "Feed", UDim2.fromOffset(440, 160), UDim2.new())
	feed.AnchorPoint = Vector2.new(0, 1)
	local feedList = Instance.new("UIListLayout")
	feedList.VerticalAlignment, feedList.Padding, feedList.SortOrder = Enum.VerticalAlignment.Bottom, UDim.new(0, 10), Enum.SortOrder.LayoutOrder
	feedList.Parent = feed
	ui.Feed, ui.FeedScale, ui.FeedOrder = feed, scaler(feed), 0

	-- Stamp layer (YOU'RE IN!).
	ui.StampLayer = Kit.Frame(root, "Stamps", UDim2.fromScale(1, 1), UDim2.new())
	ui.StampLayer.ZIndex = 30

	-- Shared dialog for Records, Settings, Coins and Keys.
	local shade = Instance.new("TextButton")
	shade.Name, shade.Text, shade.AutoButtonColor = "Shade", "", false
	shade.Size, shade.BackgroundColor3, shade.BackgroundTransparency = UDim2.fromScale(1, 1), Kit.Navy, .45
	shade.BorderSizePixel, shade.ZIndex, shade.Selectable, shade.Parent = 0, 19, false, root
	shade.Activated:Connect(actions.Close)
	ui.Shade = shade
	local dialog = Kit.Frame(root, "Dialog", UDim2.fromOffset(560, 380), UDim2.fromScale(.5, .5))
	dialog.AnchorPoint, dialog.ZIndex, dialog.Active = Vector2.new(.5, .5), 20, true
	dialog.SelectionGroup = true
	dialog.SelectionBehaviorUp, dialog.SelectionBehaviorDown = Enum.SelectionBehavior.Stop, Enum.SelectionBehavior.Stop
	dialog.SelectionBehaviorLeft, dialog.SelectionBehaviorRight = Enum.SelectionBehavior.Stop, Enum.SelectionBehavior.Stop
	ui.DialogScale = scaler(dialog)
	Kit.SkyPlate(dialog, "Plate", UDim2.fromScale(1, 1), UDim2.new(), {class = "L", stripes = true})
	ui.Dialog = dialog
	local modalTitle = Kit.SkyBig(dialog, "Title", "Records", 34)
	-- Insets clear the plate's slanted left edge at each row's height.
	modalTitle.Position, modalTitle.Size = UDim2.fromOffset(58, 24), UDim2.new(1, -140, 0, 36)
	Kit.SetBigAlignment(modalTitle, Enum.TextXAlignment.Left)
	ui.ModalTitleBig = modalTitle
	ui.Labels.ModalTitle = Kit.BigLabels(modalTitle)[1]
	local note = Kit.Body(dialog, "Note", "", 15, Color3.fromHex("EAF4FF"))
	note.Position, note.Size, note.TextXAlignment, note.TextWrapped = UDim2.fromOffset(58, 66), UDim2.new(1, -120, 0, 20), Enum.TextXAlignment.Left, true
	ui.Labels.ModalNote = note
	ui.Buttons.Close = Kit.SkyButton(dialog, "Close", "×", UDim2.fromOffset(48, 48), UDim2.new(1, -70, 0, 18), actions.Close, "Light", 28)
	ui.Buttons.Close.Modal = true
	local panelArea = Kit.Frame(dialog, "Area", UDim2.new(1, -116, 1, -128), UDim2.fromOffset(58, 100))
	local records = Instance.new("ScrollingFrame")
	records.Name, records.Size = "Records", UDim2.fromScale(1, 1)
	records.BackgroundTransparency, records.BorderSizePixel, records.CanvasSize = 1, 0, UDim2.new()
	records.AutomaticCanvasSize, records.ScrollingDirection = Enum.AutomaticSize.Y, Enum.ScrollingDirection.Y
	records.ScrollBarThickness, records.ScrollBarImageColor3, records.Parent = 5, Kit.White, panelArea
	local list = Instance.new("UIListLayout")
	list.Padding, list.SortOrder, list.Parent = UDim.new(0, 8), Enum.SortOrder.LayoutOrder, records
	-- Rows draw their outline and drop shadow just outside their box; the scroll area clips, so leave room.
	local inset = Instance.new("UIPadding")
	inset.PaddingLeft, inset.PaddingRight, inset.PaddingTop, inset.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 4), UDim.new(0, 10)
	inset.Parent = records
	ui.Records = records
	local settings = Kit.Frame(panelArea, "Settings", UDim2.fromScale(1, 1), UDim2.new())
	ui.Settings = settings
	for index, definition in {{"TextSize", "Text size", "Standard"}, {"Shadows", "World shadows", "On"}, {"Sound", "Sound", "On"}, {"Motion", "Motion", "Full"}} do
		local y = (index - 1) * 64
		local label = Kit.Body(settings, definition[1] .. "Label", definition[2], 20, Kit.White)
		label.Position, label.Size, label.TextXAlignment = UDim2.fromOffset(0, y), UDim2.new(1, -170, 0, 52), Enum.TextXAlignment.Left
		Kit.Stroke(label, Kit.Navy, 2, false)
		local button = Kit.SkyButton(settings, definition[1], definition[3], UDim2.fromOffset(150, 52), UDim2.new(1, -150, 0, y), actions[definition[1]], "Light", 18)
		ui.Buttons[definition[1]] = button
	end
	local body = Kit.Frame(panelArea, "Body", UDim2.fromScale(1, 1), UDim2.new())
	ui.Body = body
	local message = Kit.Body(body, "Message", "", 20, Kit.White)
	message.Size, message.TextWrapped, message.TextXAlignment, message.TextYAlignment = UDim2.new(1, 0, 0, 90), true, Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
	Kit.Stroke(message, Kit.Navy, 2, false)
	ui.Labels.Body = message
	ui.Buttons.Spectate = Kit.SkyButton(body, "Spectate", "Watch racers", UDim2.new(.5, -8, 0, 52), UDim2.new(0, 0, 1, -58), actions.Spectate, "Alt", 17)
	ui.Buttons.RaceLate = Kit.SkyButton(body, "RaceLate", "Practice", UDim2.new(.5, -8, 0, 52), UDim2.new(.5, 8, 1, -58), actions.RaceLate, "Alt", 17)
	-- Coins panel: the balance as a big number under a coin with a slow sunburst.
	local wallet = Kit.Frame(panelArea, "Wallet", UDim2.fromScale(1, 1), UDim2.new())
	wallet.Visible = false
	Kit.Rays(wallet, 230, UDim2.new(.5, 0, 0, 48), Kit.White, .55)
	local walletCoin = Kit.Icon(wallet, "Coin", Kit.Images.StarCoin, 96)
	walletCoin.AnchorPoint, walletCoin.Position, walletCoin.ZIndex = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, 0), 2
	local walletAmount = Kit.SkyBig(wallet, "Amount", "0", 56)
	walletAmount.Position, walletAmount.Size = UDim2.fromOffset(0, 102), UDim2.new(1, 0, 0, 60)
	local walletHint = Kit.Body(wallet, "Hint", "More ways to earn coins are coming soon.", 17, Color3.fromHex("EAF4FF"))
	walletHint.Position, walletHint.Size, walletHint.TextXAlignment = UDim2.fromOffset(0, 176), UDim2.new(1, 0, 0, 22), Enum.TextXAlignment.Center
	Kit.Stroke(walletHint, Kit.Navy, 1.5, false)
	ui.Wallet, ui.WalletCoin, ui.WalletAmount = wallet, walletCoin, walletAmount

	ui.Activate = function(button: GuiObject)
		if ui.InputReady ~= false and button:IsA("TextButton") and button:GetAttribute("Available") ~= false and button.Visible then
			local name = if button.Name == "ViewAll" then "Quests" else button.Name
			if actions[name] then actions[name]() end
		end
	end
	-- Long names such as KEYBOARD CIRCUIT shrink to fit instead of being cut off. The text-size
	-- setting passes its new preferred size; card updates reuse the last one.
	local preferred = COURSE_TEXT
	ui.FitCourse = function(preferredSize: number?)
		preferred = preferredSize or preferred
		Kit.FitBig(course, preferred, CARD_WIDTH - 56)
	end
	ui.PlaceFormat = function() View.PlaceCard(ui) end
	ui.InputReady, ui.HasQuest = true, false

	-- Idle motion: rail icons bob, the Keys "+" breathes, the dial pulses in the last seconds.
	local started = os.clock()
	local breathe = Kit.Scaler(plus)
	local goPulse = Kit.Scaler(ui.Buttons.Go)
	local motion = RunService.Heartbeat:Connect(function()
		if not root.Parent or not Kit.Motion() then return end
		local t = os.clock() - started
		for index, entry in RAIL do
			local icon = ui.NavIcons[entry[1]]
			icon.Position = UDim2.fromOffset(12, -10 + math.sin(t * 2.25 + index * .8) * 2.5)
		end
		breathe.Scale = 1 + math.max(0, math.sin(t * 3.9)) * .12
		if ui.GoPulse and ui.Buttons.Go.Visible then goPulse.Scale = 1 + math.max(0, math.sin(t * 4.5)) * .04 else goPulse.Scale = 1 end
		if ui.Urgent then ui.PhaseScale.Scale = ui.PhaseBaseScale * (1 + math.abs(math.sin(t * 6.3)) * .06) end
	end)
	root.Destroying:Connect(function() motion:Disconnect() end)

	ui.Reveal = Reveal.Create({
		{frame = phase, delay = 0, direction = Vector2.new(0, -1)}, {frame = currency, delay = .05, direction = Vector2.new(0, -1)},
		{frame = stack, delay = .1, direction = Vector2.new(1, 0)}, {frame = menu, delay = .02, direction = Vector2.new(-1, 0)},
	})
	return ui
end

function View.SetBalances(ui: any, coins: string, keys: string)
	Kit.SetBig(ui.Buttons.Gold:FindFirstChild("Balance") :: Instance, coins)
	Kit.SetBig(ui.Buttons.Keys:FindFirstChild("Balance") :: Instance, keys)
end

-- Sizes the next-race card to its content: art, heading, course, line, status/primary, secondary row.
-- The large plate's left edge leans (Kit.SkySlant("L") across its height), so each row starts
-- just inside the edge at its own height.
function View.PlaceCard(ui: any)
	local rows: {{item: GuiObject, height: number, gap: number}} = {}
	local function row(item: GuiObject, height: number, gap: number)
		if item.Visible then table.insert(rows, {item = item, height = height, gap = gap}) end
	end
	row(ui.ArtFrame, 118, 12)
	row(ui.Labels.Heading, 16, 4)
	row(ui.CourseBig, 40, 6)
	row(ui.Labels.Format, 18, 10)
	row(ui.StatusChip, 28, 12)
	row(ui.Buttons.Go, 50, 12)
	row(ui.Buttons.RaceOptions, 42, 0)
	local height = 16 + 22
	for _, entry in rows do height += entry.height + entry.gap end
	local slant = Kit.SkySlant("L")
	local function inset(y: number, h: number): number
		return slant * (1 - (y + h / 2) / height) + 18
	end
	local y = 16
	for _, entry in rows do
		local x = inset(y, entry.height)
		entry.item.Position = UDim2.fromOffset(x, y)
		if entry.item == ui.ArtFrame or entry.item == ui.CourseBig or entry.item == ui.Labels.Format or entry.item == ui.Buttons.Go then
			entry.item.Size = UDim2.fromOffset(CARD_WIDTH - x - 26 - slant * (y / height), entry.height)
		end
		y += entry.height + entry.gap
	end
	local buttonsY = ui.Buttons.RaceOptions.Position.Y.Offset
	local left = ui.Buttons.RaceOptions.Position.X.Offset
	local pair = ui.Buttons.Second.Visible
	local width = CARD_WIDTH - left - 24
	ui.Buttons.RaceOptions.Size = UDim2.fromOffset(if pair then (width - 12) / 2 else width, 42)
	ui.Buttons.Second.Size = UDim2.fromOffset((width - 12) / 2, 42)
	ui.Buttons.Second.Position = UDim2.fromOffset(left + (width - 12) / 2 + 12, buttonsY)
	ui.Race.Size = UDim2.fromOffset(CARD_WIDTH, height)
	ui.Stack.Size = UDim2.fromOffset(CARD_WIDTH, height)
end

function View.Resize(ui: any)
	local screen = ui.Root.Parent
	local width, height = ui.Root.AbsoluteSize.X, ui.Root.AbsoluteSize.Y
	if screen:IsA("ScreenGui") then
		local viewport = GuiService:GetInsetArea(Enum.ScreenInsets.None)
		local screenInset = GuiService:GetInsetArea(screen.ScreenInsets)
		local safe = GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets)
		-- Keep HUD controls below Roblox's top bar while the shade covers the whole screen.
		ui.Root.Position = UDim2.fromOffset(safe.Min.X - screenInset.Min.X, safe.Min.Y - screenInset.Min.Y)
		ui.Root.Size = UDim2.fromOffset(safe.Width, safe.Height)
		width, height = safe.Width, safe.Height
		ui.Shade.Position = UDim2.fromOffset(viewport.Min.X - safe.Min.X, viewport.Min.Y - safe.Min.Y)
		ui.Shade.Size = UDim2.fromOffset(viewport.Width, viewport.Height)
	else
		ui.Shade.Position, ui.Shade.Size = UDim2.new(), UDim2.fromScale(1, 1)
	end
	local largeText = Kit.LargeText()
	local fit = math.min(width / DESIGN.X, height / DESIGN.Y)
	local scale = math.clamp(fit, .55, 1.3) * (if largeText then 1.1 else 1)
	ui.Scale = scale
	for _, item in {ui.MenuScale, ui.CurrencyScale, ui.StackScale, ui.FeedScale, ui.DialogScale} do item.Scale = scale end
	ui.PhaseBaseScale = scale
	if not ui.Urgent then ui.PhaseScale.Scale = scale end
	ui.Menu.Position = UDim2.fromOffset(24 * scale, 64 * scale)
	ui.Phase.Position = UDim2.new(.5, 0, 0, 16 * scale)
	ui.Currency.Position = UDim2.new(1, -24 * scale, 0, 20 * scale)
	ui.Stack.Position = UDim2.new(1, -24 * scale, 0, 104 * scale)
	ui.Feed.Position = UDim2.new(0, 24 * scale, 1, -26 * scale)
	View.PlaceCard(ui)
end

-- Phase capsule: label, time and the draining dial (last five seconds pulse pink).
function View.SetPhase(ui: any, phase: any)
	ui.Labels.Phase.Text = string.upper(phase.label or "")
	Kit.SetBig(ui.TimerBig, phase.time or "")
	local fraction = if typeof(phase.fraction) == "number" then math.clamp(phase.fraction, 0, 1) else nil
	local lit = if fraction then math.ceil(fraction * DIAL_TICKS) else DIAL_TICKS
	local urgent = phase.urgent == true
	for index, mark in ui.DialTicks do
		mark.BackgroundColor3 = if urgent then Kit.Pink else Kit.Navy
		mark.BackgroundTransparency = if index <= lit then 0 else .8
	end
	if urgent ~= ui.Urgent then
		ui.Urgent = urgent
		if not urgent then ui.PhaseScale.Scale = ui.PhaseBaseScale or ui.PhaseScale.Scale end
	end
	Kit.SetBigColor(ui.TimerBig, if urgent then Kit.Pink else Kit.White)
end

-- Next-race card contents from LobbyPresentation.Card. The two lower buttons carry action ids
-- in ui.CardActions so the controller can route them.
function View.SetCard(ui: any, card: any)
	ui.Labels.Heading.Text = string.upper(card.heading)
	Kit.SetBig(ui.CourseBig, string.upper(card.title))
	ui.FitCourse()
	ui.Labels.Format.Text = card.line
	local collage = #card.images > 1
	ui.ArtSingle.Visible = not collage
	ui.ArtSingle.Image = card.images[1] or ""
	for index, image in ui.ArtCollage do
		image.Visible = collage and card.images[index] ~= nil
		image.Image = card.images[index] or ""
	end
	ui.StatusChip.Visible = card.chip ~= nil
	if card.chip then Kit.SetChip(ui.StatusChip, card.chip) end
	ui.Buttons.Go.Visible = card.primary ~= nil
	if card.primary then Kit.SetButtonText(ui.Buttons.Go, card.primary) end
	ui.GoPulse = card.pulse == true
	ui.CardActions = {Go = "Join", RaceOptions = card.left.id, Second = if card.right then card.right.id else nil}
	Kit.SetButtonText(ui.Buttons.RaceOptions, card.left.text)
	ui.Buttons.Second.Visible = card.right ~= nil
	if card.right then Kit.SetButtonText(ui.Buttons.Second, card.right.text) end
	View.PlaceCard(ui)
end

function View.SetRaceMood(_ui: any, _timed: boolean, _queued: boolean) end

-- The dialog grows to its panel's content instead of a fixed size.
function View.SizeDialog(ui: any, height: number)
	ui.Dialog.Size = UDim2.fromOffset(560, height)
end

-- In the practice area the practice screens own the screen; only the wallet stays (Keys never hide).
function View.SetPracticeMode(ui: any, practicing: boolean)
	for _, item in {ui.Menu, ui.Phase, ui.Stack, ui.Feed} do item.Visible = not practicing end
end

-- Activity toast from results seen this visit, e.g. "Mia won City Run · 1:12.4".
function View.Toast(ui: any, strong: string, rest: string, dim: string?)
	ui.FeedOrder += 1
	local toast = Kit.SkyPlate(ui.Feed, "Toast", UDim2.fromOffset(380, 44), UDim2.new(), {class = "S"})
	toast.LayoutOrder = ui.FeedOrder
	local content = Kit.Content(toast)
	local trophy = Icons.Create(content, "Records", UDim2.fromOffset(12, 7), 28)
	trophy.Name = "Trophy"
	local label = Kit.Body(content, "Text", "", 16, Kit.White)
	label.RichText, label.Position, label.Size = true, UDim2.fromOffset(46, 0), UDim2.new(1, -60, 1, 0)
	label.TextXAlignment, label.TextTruncate = Enum.TextXAlignment.Left, Enum.TextTruncate.AtEnd
	label.Text = string.format("<b>%s</b> %s%s", strong, rest, if dim then string.format(' <font transparency="0.25">· %s</font>', dim) else "")
	Kit.Stroke(label, Kit.Navy, 1.5, false)
	Kit.Punch(toast, .8, .4)
	local toasts: {Frame} = {}
	for _, child in ui.Feed:GetChildren() do if child:IsA("Frame") then table.insert(toasts, child) end end
	table.sort(toasts, function(a, b) return a.LayoutOrder > b.LayoutOrder end)
	for index, item in toasts do
		if index > 3 then item:Destroy() else Kit.FadeTree(item, true, 0) end
	end
	task.delay(9, function()
		if not toast.Parent then return end
		Kit.FadeTree(toast, false, .4)
		task.delay(.45, function() toast:Destroy() end)
	end)
end

-- Big YOU'RE IN! stamp over the screen centre.
function View.Stamp(ui: any, value: string)
	Kit.Stamp(ui.StampLayer, value, Kit.Mint, 120)
end

return View
