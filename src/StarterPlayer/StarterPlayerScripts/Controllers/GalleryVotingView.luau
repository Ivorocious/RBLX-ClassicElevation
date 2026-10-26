--!strict
-- Opening vote (brief "Voting"): one opening course picked from large Sky Rush cards, a one-slot
-- tray and Confirm opening. Ballot rules, the timer, Hide and submitting stay in TournamentController.
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local Kit = require(script.Parent.UiKit)
local Icons = require(script.Parent.LobbyIcons)
local Clock = require(script.Parent.RacePresentation).Clock
local Bests = require(script.Parent.VisitBests)

local View = {}
local DESIGN = Vector2.new(1280, 720)
local CARD = Vector2.new(228, 206)
local CARD_GAP = 14
local EVENT_SIZE = 5

local function round(item: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), item
end

local function setAvailable(button: GuiObject, available: boolean)
	button:SetAttribute("Available", available)
	button.Selectable, button.Active = available, available
end

-- Course art over a flag stand-in: the flag shows only where no image has drawn yet (or none exists).
local function art(parent: Instance, name: string, image: string): Frame
	local holder = Kit.Frame(parent, name, UDim2.fromScale(1, 1), UDim2.new(), Kit.SkyDeep, 0)
	local backdrop = Instance.new("UIGradient")
	backdrop.Rotation, backdrop.Color = 90, ColorSequence.new(Kit.Sky, Kit.SkyDeep)
	backdrop.Parent = holder
	local flag = Kit.Icon(holder, "Fallback", Kit.Images.FinishFlag, 64, Kit.White)
	flag.AnchorPoint, flag.Position = Vector2.new(.5, .5), UDim2.fromScale(.5, .4)
	flag.ImageTransparency = .2
	if image ~= "" then
		local picture = Instance.new("ImageLabel")
		picture.Name, picture.Image, picture.ScaleType = "Picture", image, Enum.ScaleType.Crop
		picture.BackgroundTransparency, picture.Size = 1, UDim2.fromScale(1, 1)
		picture.Parent = holder
		task.spawn(pcall, ContentProvider.PreloadAsync, ContentProvider, {picture})
	end
	return holder
end

local function dashedSlot(parent: Instance, name: string, text: string, size: Vector2): Frame
	local slot = Kit.Frame(parent, name, UDim2.fromOffset(size.X, size.Y), UDim2.new(), Kit.White, .82)
	round(slot, 10)
	local edge = Kit.Stroke(slot, Kit.White, 2.5, true)
	edge.Transparency = .25
	local label = Kit.Caption(slot, "Label", text, 16, Kit.White)
	label.Size = UDim2.fromScale(1, 1)
	label.TextTransparency = .15
	return slot
end

function View.Create(parent: Instance, actions: any)
	local root = Kit.Frame(parent, "GalleryVoting", UDim2.fromScale(1, 1), UDim2.new())
	root.Active = true
	local shade = Kit.Frame(root, "Shade", UDim2.fromScale(1, 1), UDim2.new(), Kit.Navy, .45)
	shade.Name = "Shade"
	local stage = Kit.Frame(root, "Window", UDim2.fromOffset(DESIGN.X, DESIGN.Y), UDim2.fromScale(.5, .5))
	stage.AnchorPoint = Vector2.new(.5, .5)
	local fit = Instance.new("UIScale")
	fit.Name, fit.Parent = "LayoutScale", stage

	-- Timer (with its 6 px drop shadow) ends a few pixels above the header so their outlines never merge.
	local timer = Kit.SkyPlate(stage, "VoteTimer", UDim2.fromOffset(320, 96), UDim2.fromOffset(480, 2), {fill = "Hero", class = "M"})
	Kit.Sheen(timer, 4.5)
	local timerContent = Kit.Content(timer)
	Icons.Create(timerContent, "Clock", UDim2.fromOffset(48, 16), 60)
	local timerCaption = Kit.SkyCaption(timerContent, "Caption", "Opening vote", 14, true)
	timerCaption.Position, timerCaption.Size, timerCaption.TextXAlignment = UDim2.fromOffset(124, 9), UDim2.fromOffset(160, 16), Enum.TextXAlignment.Left
	local time = Kit.SkyBig(timerContent, "Time", "0:15", 42)
	time.Position, time.Size = UDim2.fromOffset(122, 31), UDim2.fromOffset(150, 42)
	Kit.SetBigAlignment(time, Enum.TextXAlignment.Left)
	local drain = Kit.Frame(timerContent, "Drain", UDim2.fromOffset(140, 6), UDim2.fromOffset(124, 80), Kit.Navy, .25)
	round(drain, 3)

	local header = Kit.SkyPlate(stage, "Header", UDim2.fromOffset(780, 80), UDim2.fromOffset(60, 112), {class = "M", stripes = true})
	Kit.Sheen(header, 6)
	local headerContent = Kit.Content(header)
	local heading = Kit.SkyBig(headerContent, "Heading", "CHOOSE THE OPENING COURSE", 32)
	heading.Position, heading.Size = UDim2.fromOffset(30, 10), UDim2.fromOffset(700, 36)
	Kit.SetBigAlignment(heading, Enum.TextXAlignment.Left)
	local subtitle = Kit.Body(headerContent, "Subtitle", "", 16, Kit.White)
	subtitle.Position, subtitle.Size, subtitle.TextXAlignment = UDim2.fromOffset(33, 50), UDim2.fromOffset(700, 18), Enum.TextXAlignment.Left
	local hide = Kit.SkyButton(stage, "HideVoting", "Hide", UDim2.fromOffset(120, 52), UDim2.fromOffset(860, 126), actions.Hide, "Light", 20)

	local grid = Kit.Frame(stage, "Library", UDim2.fromOffset(DESIGN.X, 230), UDim2.fromOffset(0, 210))

	local tray = Kit.SkyPlate(stage, "Tray", UDim2.fromOffset(1080, 132), UDim2.fromOffset(100, 470), {class = "M", stripes = true})
	local trayContent = Kit.Content(tray)
	local trayCaption = Kit.SkyCaption(trayContent, "YourPicks", "Opening course", 14)
	trayCaption.Position, trayCaption.Size, trayCaption.TextXAlignment = UDim2.fromOffset(72, 28), UDim2.fromOffset(150, 16), Enum.TextXAlignment.Left
	local count = Kit.SkyBig(trayContent, "Count", "0/1", 46)
	count.Position, count.Size = UDim2.fromOffset(64, 50), UDim2.fromOffset(120, 46)
	Kit.SetBigAlignment(count, Enum.TextXAlignment.Left)
	local pickSlot = Kit.Frame(trayContent, "Picks", UDim2.fromOffset(210, 92), UDim2.fromOffset(196, 20))
	local emptyPick = dashedSlot(pickSlot, "Empty", "Pick a course", Vector2.new(210, 92))
	local pickArt = Kit.Frame(pickSlot, "Pick", UDim2.fromScale(1, 1), UDim2.new(), Kit.SkyDeep, 0)
	pickArt.ClipsDescendants = true
	round(pickArt, 10)
	Kit.Stroke(pickArt, Kit.Navy, 3, true)
	local pickName = Kit.Body(pickArt, "Title", "", 18, Kit.White)
	pickName.FontFace, pickName.Position, pickName.Size, pickName.ZIndex = Kit.Display, UDim2.new(0, 0, 1, -30), UDim2.new(1, 0, 0, 26), 3
	Kit.Stroke(pickName, Kit.Navy, 2.5, false)
	local followCaption = Kit.SkyCaption(trayContent, "Follow", "Then four more, no repeats", 13)
	followCaption.Position, followCaption.Size, followCaption.TextXAlignment = UDim2.fromOffset(432, 26), UDim2.fromOffset(300, 16), Enum.TextXAlignment.Left
	local followSlots = {}
	for index = 2, EVENT_SIZE do
		local slot = dashedSlot(trayContent, "Slot" .. index, tostring(index), Vector2.new(62, 44))
		slot.Position = UDim2.fromOffset(432 + (index - 2) * 72, 54)
		followSlots[index] = slot
	end
	local single = Kit.Chip(trayContent, "Single", "A single race", 16, "Light")
	single.Position = UDim2.fromOffset(432, 60)
	local status = Kit.Body(trayContent, "Status", "", 15, Kit.White)
	status.Position, status.Size, status.TextXAlignment = UDim2.fromOffset(432, 102), UDim2.fromOffset(330, 18), Enum.TextXAlignment.Left
	local confirm = Kit.SkyButton(trayContent, "Confirm", "Confirm opening", UDim2.fromOffset(270, 68), UDim2.fromOffset(770, 32), actions.Confirm, "Primary", 24)

	local ui: any = {Root = root, Stage = stage, Fit = fit, Timer = timer, Time = time, Drain = drain, Heading = heading,
		Subtitle = subtitle, Hide = hide, Grid = grid, Tray = tray, Count = count, Empty = emptyPick, PickArt = pickArt,
		PickName = pickName, Follow = followCaption, FollowSlots = followSlots, Single = single, Status = status,
		Confirm = confirm, Cards = {}, Actions = actions, State = {}, Order = {}}
	-- Confirm breathes while a pick is waiting to be locked in.
	local started = os.clock()
	local pulse = RunService.RenderStepped:Connect(function(dt)
		if not root.Parent or not root.Visible then return end
		local t, motion = os.clock() - started, Kit.Motion()
		local scale = Kit.Scaler(confirm)
		scale.Scale = if ui.CanConfirm and motion then 1 + .04 * math.sin(t * 6) else 1
		-- Cards drift gently and lift under the pointer; the picked card's rim glows.
		for index, card in ui.Order do
			local target = if card.Hovered and card.Available then -8 else 0
			card.Lift = (card.Lift or 0) + (target - (card.Lift or 0)) * math.min(1, dt * 14)
			local float = if motion then math.sin(t * 1.7 + index * 1.1) * 3 else 0
			if card.Home then card.Button.Position = card.Home + UDim2.fromOffset(0, card.Lift + float) end
			if card.Selected then
				card.Edge.Color = Kit.Sun:Lerp(Kit.White, if motion then (.5 + .5 * math.sin(t * 4)) * .6 else 0)
			end
		end
	end)
	root.Destroying:Connect(function() pulse:Disconnect() end)
	root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() View.Resize(ui) end)
	View.Resize(ui)
	return ui
end

function View.Resize(ui: any)
	local size = ui.Root.AbsoluteSize
	if size.X < 1 or size.Y < 1 then return end
	local large = Kit.LargeText()
	ui.Fit.Scale = math.min(math.clamp(math.min(size.X / DESIGN.X, size.Y / DESIGN.Y), .42, 1.3) * (if large then 1.06 else 1), size.Y / DESIGN.Y)
	-- One row up to seven courses (cards shrink to fit the 1180-wide row), two rows beyond that.
	local count = #ui.Order
	local rows = if count > 7 then 2 else 1
	local perRow = math.max(1, math.ceil(count / rows))
	local fitWidth = (1180 - (perRow - 1) * CARD_GAP) / (perRow * CARD.X)
	local fitHeight = (250 - (rows - 1) * CARD_GAP) / (rows * CARD.Y)
	local cardScale = math.min(1, fitWidth, fitHeight)
	local w, h = CARD.X * cardScale, CARD.Y * cardScale
	for index, card in ui.Order do
		local row = (index - 1) // perRow
		local inRow = if row == rows - 1 then count - row * perRow else perRow
		local column = (index - 1) % perRow
		local width = inRow * w + (inRow - 1) * CARD_GAP
		local home = UDim2.fromOffset((DESIGN.X - width) / 2 + column * (w + CARD_GAP), row * (h + CARD_GAP))
		card.Home = home
		card.Scale.Scale = cardScale
		card.Button.Position = home + UDim2.fromOffset(0, if card.Hovered and card.Available then -6 else 0)
	end
end

local function newCard(ui: any, row: any): any
	local button = Instance.new("TextButton")
	button.Name, button.Text, button.AutoButtonColor, button.BackgroundTransparency = row.id, "", false, 1
	button.Size = UDim2.fromOffset(CARD.X, CARD.Y)
	-- Layout scale for crowded rows; scaling from the top-left keeps Position as the card's corner.
	local cardScale = Instance.new("UIScale")
	cardScale.Name, cardScale.Parent = "CardScale", button
	button.Selectable = true
	local focusImage = Instance.new("ImageLabel")
	focusImage.Name, focusImage.BackgroundTransparency, focusImage.Image, focusImage.Size = "FocusImage", 1, "", UDim2.fromScale(1, 1)
	button.SelectionImageObject = focusImage
	focusImage.Parent = button
	local body = Kit.Frame(button, "Body", UDim2.fromScale(1, 1), UDim2.new(), Kit.Navy, 0)
	round(body, 14)
	local shadow = Kit.Frame(button, "Shadow", UDim2.fromScale(1, 1), UDim2.fromOffset(0, 6), Kit.Navy, .35)
	shadow.ZIndex = 0
	round(shadow, 14)
	local frame = Kit.Frame(body, "Clip", UDim2.new(1, -8, 1, -8), UDim2.fromOffset(4, 4), Kit.SkyDeep, 0)
	frame.ClipsDescendants = true
	round(frame, 11)
	art(frame, "Artwork", row.image or "")
	local fade = Kit.Frame(frame, "LabelFade", UDim2.fromScale(1, 1), UDim2.new(), Kit.Navy, 0)
	fade.ZIndex = 2
	local gradient = Instance.new("UIGradient")
	gradient.Rotation, gradient.Transparency = 90, NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(.55, 1), NumberSequenceKeypoint.new(1, .15)})
	gradient.Parent = fade
	local title = Kit.Body(frame, "Title", row.name, 20, Kit.White)
	title.FontFace, title.Position, title.Size = Kit.Display, UDim2.new(0, 6, 1, -34), UDim2.new(1, -12, 0, 26)
	title.TextScaled, title.ZIndex = true, 3
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize, limit.Parent = 22, title
	Kit.Stroke(title, Kit.Navy, 2.5, false)
	local edge = Kit.Stroke(body, Kit.Navy, 3, true)
	local check = Kit.Frame(button, "Selector", UDim2.fromOffset(40, 40), UDim2.new(1, -8, 0, 8), Kit.White, 0)
	check.AnchorPoint, check.ZIndex = Vector2.new(1, 0), 4
	round(check, 20)
	Kit.Stroke(check, Kit.Navy, 3, true)
	local tick = Icons.Create(check, "Check", UDim2.fromOffset(4, 4), 32)
	tick.Visible = false
	local best = Kit.Chip(button, "Best", "", 13)
	best.Position, best.ZIndex = UDim2.fromOffset(10, 12), 4
	best.Visible = false
	button.Parent = ui.Grid
	local card: any = {Scale = cardScale, Button = button, Body = body, Edge = edge, Check = check, Tick = tick, Best = best, Title = title, Hovered = false, Selected = false, Available = true}
	local function hover(value: boolean)
		card.Hovered = value
		if value and card.Available then Kit.Play("Pop", 1.3) end
	end
	button.MouseEnter:Connect(function() hover(true) end)
	button.MouseLeave:Connect(function() hover(false) end)
	button.SelectionGained:Connect(function() hover(true) end)
	button.SelectionLost:Connect(function() hover(false) end)
	button.Activated:Connect(function()
		if button:GetAttribute("Available") == false then return end
		Kit.Play("Click")
		ui.Actions.Select(row.id)
	end)
	return card
end

function View.Render(ui: any, state: any)
	local wasConfirmed = ui.State.confirmed == true
	ui.State = state
	local catalog = state.catalog or {}
	local picks = state.picks or {}
	local picked = picks[1]
	local voting = state.phase == "Voting" and not state.pending
	local seen = {}
	table.clear(ui.Order)
	local pickedRow = nil
	for _, row in catalog do
		seen[row.id] = true
		local card = ui.Cards[row.id] or newCard(ui, row)
		ui.Cards[row.id] = card
		table.insert(ui.Order, card)
		card.Title.Text = row.name
		local selected = row.id == picked
		if selected then pickedRow = row end
		if selected and not card.Selected then
			Kit.Punch(card.Body, .86, .3)
			Kit.Punch(card.Check, .3, .4)
		end
		card.Selected = selected
		card.Tick.Visible = selected
		card.Check.BackgroundColor3 = if selected then Kit.Mint else Kit.White
		card.Edge.Color, card.Edge.Thickness = if selected then Kit.Sun else Kit.Navy, if selected then 5 else 3
		local best = Bests.Get(row.id)
		card.Best.Visible = best ~= nil
		if best then Kit.SetChip(card.Best, "Your best this visit " .. Clock(best, 2)) end
		card.Available = voting and not state.confirmed
		setAvailable(card.Button, voting)
	end
	for id, card in ui.Cards do
		if not seen[id] then card.Button:Destroy(); ui.Cards[id] = nil end
	end
	local event = #catalog >= EVENT_SIZE
	ui.Subtitle.Text = if event and #catalog > EVENT_SIZE then "It opens a 5-race event. Four of the other courses follow, with no repeats."
		elseif event then "It opens a 5-race event. The other four follow, with no repeats."
		else #catalog .. (if #catalog == 1 then " course is" else " courses are") .. " ready, so this is a single race."
	ui.Follow.Visible = event
	for _, slot in ui.FollowSlots do slot.Visible = event end
	ui.Single.Visible = not event
	Kit.SetBig(ui.Count, #picks .. "/1")
	ui.Empty.Visible = pickedRow == nil
	ui.PickArt.Visible = pickedRow ~= nil
	if pickedRow and ui.PickArt:GetAttribute("CourseId") ~= pickedRow.id then
		ui.PickArt:SetAttribute("CourseId", pickedRow.id)
		local old = ui.PickArt:FindFirstChild("Artwork")
		if old then old:Destroy() end
		local picture = art(ui.PickArt, "Artwork", pickedRow.image or "")
		picture.ZIndex = 1
		ui.PickName.Text = pickedRow.name
		Kit.Punch(ui.PickArt, .6, .4)
	end
	local can = #picks == 1 and state.phase == "Voting" and not state.pending and not state.confirmed
	ui.CanConfirm = can
	Kit.SetButtonText(ui.Confirm, if state.pending then "Sending…" elseif state.confirmed then "Locked in" elseif state.phase ~= "Voting" then "Voting closed" else "Confirm opening")
	setAvailable(ui.Confirm, can)
	ui.Confirm:SetAttribute("Done", state.confirmed == true)
	Kit.SetSkyButtonKind(ui.Confirm, if state.confirmed then "Light" else "Primary")
	ui.Status.Text = if state.message and state.message ~= "" then state.message
		elseif state.confirmed and pickedRow then "Your pick is in · the vote ends with the timer"
		elseif not pickedRow then "Pick the course you want to race first" else ""
	if state.confirmed and not wasConfirmed then Kit.Stamp(ui.Root, "LOCKED IN!", Kit.Sun, 110) end
	if state.timeLeft ~= nil then
		local seconds = math.max(0, math.ceil(state.timeLeft))
		local text = Clock(seconds, 0)
		local urgent = seconds <= 5 and seconds > 0
		if ui.Time:GetAttribute("Shown") ~= text then
			ui.Time:SetAttribute("Shown", text)
			Kit.SetBig(ui.Time, text)
			if urgent then Kit.Punch(ui.Timer, 1.12, .3); Kit.Play("Beep") end
		end
		Kit.SetSkyFill(ui.Timer, if urgent then "Pink" else "Hero")
		ui.Drain.Size = UDim2.fromOffset(140 * math.clamp(state.timeLeft / math.max(state.duration or 15, 1), 0, 1), 6)
	end
	View.Resize(ui)
end

return View
