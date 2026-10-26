--!strict
-- Next course ticket (brief "Next course"): race number, course name, the four delivery steps and a
-- status line, with Skip cinematic and Reduce motion pills. TournamentPresentation owns the delivery
-- handshake and only tells this view what to show.
local RunService = game:GetService("RunService")
local Kit = require(script.Parent.UiKit)
local Icons = require(script.Parent.LobbyIcons)

local View = {}
local WIDTH, HEIGHT = 600, 178
local STEPS = {"Results", "Loading", "Preview", "3·2·1"}

local function round(item: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), item
end

local function spinner(parent: Instance): Frame
	local ring = Kit.Frame(parent, "Spinner", UDim2.fromOffset(18, 18), UDim2.new())
	round(ring, 9)
	local edge = Kit.Stroke(ring, Kit.Navy, 3, true)
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(.7, .2), NumberSequenceKeypoint.new(1, 1)})
	gradient.Parent = edge
	return ring
end

local function stepPill(parent: Instance, index: number, text: string): Frame
	local pill = Kit.Frame(parent, "Step" .. index, UDim2.fromOffset(0, 34), UDim2.new(), Kit.Navy, 0)
	pill.AutomaticSize, pill.LayoutOrder = Enum.AutomaticSize.X, index
	round(pill, 17)
	local edge = Kit.Stroke(pill, Kit.Navy, 2.5, true)
	edge.Name = "Edge"
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 14), UDim.new(0, 14)
	padding.Parent = pill
	local list = Instance.new("UIListLayout")
	list.FillDirection, list.VerticalAlignment, list.Padding, list.SortOrder = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 4), Enum.SortOrder.LayoutOrder
	list.Parent = pill
	local tick = Icons.Create(pill, "Check", UDim2.new(), 18)
	tick.Name, tick.LayoutOrder = "Tick", 1
	local label = Kit.Body(pill, "Text", text, 16, Kit.White)
	label.AutomaticSize, label.Size, label.LayoutOrder = Enum.AutomaticSize.X, UDim2.fromScale(0, 1), 2
	return pill
end

local function pillButton(parent: Instance, name: string, text: string, activate: () -> ()): TextButton
	local button = Instance.new("TextButton")
	button.Name, button.Text, button.AutoButtonColor = name, text, false
	button.FontFace, button.TextSize, button.TextColor3 = Kit.Label, 17, Kit.White
	button.BackgroundColor3, button.Size, button.AutomaticSize = Kit.Navy, UDim2.fromOffset(0, 40), Enum.AutomaticSize.X
	round(button, 20)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 16), UDim.new(0, 16)
	padding.Parent = button
	Kit.Stroke(button, Kit.White, 2, true).Transparency = .5
	button.MouseEnter:Connect(function() button.BackgroundColor3 = Kit.SubInk end)
	button.MouseLeave:Connect(function() button.BackgroundColor3 = Kit.Navy end)
	button.Activated:Connect(function() Kit.Play("Click"); activate() end)
	button.Parent = parent
	return button
end

-- `gui` is the delivery ScreenGui in game, or a plain frame in a UI Labs story.
function View.Create(gui: GuiBase2d, actions: {skip: () -> (), reduce: () -> ()}): any
	if gui:IsA("ScreenGui") then gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end
	local holder = Kit.Frame(gui, "TicketHolder", UDim2.fromOffset(WIDTH, HEIGHT), UDim2.new(.5, 0, 0, 14))
	holder.AnchorPoint, holder.ZIndex = Vector2.new(.5, 0), 2
	local scale = Instance.new("UIScale")
	scale.Name, scale.Parent = "LayoutScale", holder
	local plate = Kit.SkyPlate(holder, "Ticket", UDim2.fromScale(1, 1), UDim2.new(), {fill = "Hero", class = "M", stripes = true})
	Kit.Sheen(plate, 4)
	local content = Kit.Content(plate)
	local raceNumber = Kit.SkyCaption(content, "RaceNumber", "", 14, true)
	raceNumber.Position, raceNumber.Size = UDim2.fromOffset(0, 12), UDim2.new(1, 0, 0, 16)
	local course = Kit.SkyBig(content, "Course", "", 50)
	course.Position, course.Size = UDim2.fromOffset(40, 40), UDim2.new(1, -80, 0, 50)
	local steps = Kit.Frame(content, "Steps", UDim2.fromOffset(0, 34), UDim2.new(.5, 0, 0, 96))
	steps.AnchorPoint, steps.AutomaticSize = Vector2.new(.5, 0), Enum.AutomaticSize.X
	local stepList = Instance.new("UIListLayout")
	stepList.FillDirection, stepList.Padding, stepList.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 8), Enum.SortOrder.LayoutOrder
	stepList.Parent = steps
	local pills = {}
	for index, text in STEPS do pills[index] = stepPill(steps, index, text) end
	local status = Kit.Frame(content, "Status", UDim2.fromOffset(0, 24), UDim2.new(.5, 0, 0, 140))
	status.AnchorPoint, status.AutomaticSize = Vector2.new(.5, 0), Enum.AutomaticSize.X
	local statusList = Instance.new("UIListLayout")
	statusList.FillDirection, statusList.VerticalAlignment, statusList.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8)
	statusList.SortOrder, statusList.Parent = Enum.SortOrder.LayoutOrder, status
	local spin = spinner(status)
	spin.LayoutOrder = 1
	local note = Kit.Body(status, "Note", "", 18, Kit.Navy)
	note.AutomaticSize, note.Size, note.LayoutOrder = Enum.AutomaticSize.X, UDim2.fromScale(0, 1), 2
	local chip = Kit.Chip(gui, "FirstCheckpoint", "First checkpoint", 18, "Good")
	chip.AnchorPoint, chip.Position, chip.Visible = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, HEIGHT + 30), false
	local corner = Kit.Frame(gui, "Pills", UDim2.fromOffset(0, 40), UDim2.new(1, -20, 1, -20))
	corner.AnchorPoint, corner.AutomaticSize = Vector2.new(1, 1), Enum.AutomaticSize.X
	local cornerList = Instance.new("UIListLayout")
	cornerList.FillDirection, cornerList.Padding, cornerList.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 10), Enum.SortOrder.LayoutOrder
	cornerList.Parent = corner
	local skip = pillButton(corner, "Skip", "Skip cinematic", actions.skip)
	skip.LayoutOrder = 1
	local reduce = pillButton(corner, "ReduceMotion", "Reduce motion", actions.reduce)
	reduce.LayoutOrder = 2
	local view: any
	view = {gui = gui, holder = holder, scale = scale, plate = plate, raceNumber = raceNumber, course = course,
		pills = pills, spinner = spin, note = note, chip = chip, skip = skip, reduce = reduce, step = 0}
	local started = os.clock()
	local connection = RunService.RenderStepped:Connect(function(dt)
		if not Kit.Motion() then return end
		if spin.Visible then spin.Rotation = (spin.Rotation + dt * 360) % 360 end
		-- The current step's outline breathes so the eye finds where delivery is.
		-- FindFirstChild: with deferred events this can still run for a frame after the ticket is destroyed.
		local edge = pills[view.step] and pills[view.step]:FindFirstChild("Edge")
		if edge then (edge :: UIStroke).Thickness = 2.5 + 1.5 * (.5 + .5 * math.sin((os.clock() - started) * 5)) end
	end)
	gui.Destroying:Connect(function() connection:Disconnect() end)
	local function layout()
		local size = gui.AbsoluteSize
		scale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 720), .6, 1.2) * (if Kit.LargeText() then 1.08 else 1)
		chip.Position = UDim2.new(.5, 0, 0, 14 + (HEIGHT + 14) * scale.Scale)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	if Kit.Motion() then
		plate.Position = UDim2.fromOffset(0, -220)
		Kit.Tween(plate, .56, {Position = UDim2.new()}, "Pop")
		Kit.Play("Whoosh")
	end
	return view
end

function View.SetHeader(view: any, raceNumber: string?, course: string)
	view.raceNumber.Visible = raceNumber ~= nil
	view.raceNumber.Text = string.upper(raceNumber or "")
	Kit.SetBig(view.course, string.upper(course))
	-- A single race and race 1 follow a vote, not results. raceNumber is RacePresentation.RaceNumber's "Race N of M".
	local first = raceNumber == nil or string.match(raceNumber, "^Race 1 ") ~= nil
	;(view.pills[1].Text :: TextLabel).Text = if first then "Vote" else STEPS[1]
end

-- `step` is the current step (1 Results or Vote … 4 3·2·1); earlier steps show as done.
function View.SetStep(view: any, step: number, note: string, busy: boolean)
	if step ~= view.step then
		view.step = step
		for index, pill in view.pills do
			local done, current = index < step, index == step
			pill.BackgroundColor3 = if done then Kit.Navy else Kit.White
			pill.BackgroundTransparency = if done or current then 0 else .5
			;(pill.Edge :: UIStroke).Transparency = if done or current then 0 else .55
			;(pill.Text :: TextLabel).TextColor3 = if done then Kit.White else Kit.Navy
			pill.Tick.Visible = done
			if current then Kit.Punch(pill, .7, .36) end
		end
	end
	view.note.Text = note
	view.spinner.Visible = busy
end

function View.SetCheckpoint(view: any, visible: boolean)
	if visible and not view.chip.Visible then Kit.Punch(view.chip, .01, .45) end
	view.chip.Visible = visible
end

function View.SetPills(view: any, motion: boolean, skipped: boolean)
	view.reduce.Text = if motion then "Reduce motion" else "Motion reduced"
	view.skip.Text = if skipped then "Cinematic skipped" else "Skip cinematic"
end

-- A failed preparation outlives the delivery session briefly: pink ticket with the server's message.
-- `playerGui` may also be a plain frame (UI Labs stories); the ticket then fills that frame.
function View.ShowFailed(playerGui: Instance, course: string, message: string, canWatch: boolean, activate: ((string) -> ())?)
	local old = playerGui:FindFirstChild("CourseDeliveryFailed")
	if old then old:Destroy() end
	local gui: GuiBase2d
	if playerGui:IsA("GuiObject") then
		gui = Kit.Frame(nil, "CourseDeliveryFailed", UDim2.fromScale(1, 1), UDim2.new())
	else
		local screen = Instance.new("ScreenGui")
		screen.Name, screen.ResetOnSpawn, screen.DisplayOrder, screen.ZIndexBehavior = "CourseDeliveryFailed", false, 70, Enum.ZIndexBehavior.Sibling
		screen.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
		gui = screen
	end
	local holder = Kit.Frame(gui, "TicketHolder", UDim2.fromOffset(WIDTH, 200), UDim2.new(.5, 0, 0, 14))
	holder.AnchorPoint = Vector2.new(.5, 0)
	local scale = Instance.new("UIScale")
	scale.Parent = holder
	local plate = Kit.SkyPlate(holder, "Ticket", UDim2.fromScale(1, 1), UDim2.new(), {fill = "Pink", class = "M", stripes = true})
	local content = Kit.Content(plate)
	local caption = Kit.SkyCaption(content, "Caption", "Couldn't get " .. course .. " ready", 14)
	caption.Position, caption.Size = UDim2.fromOffset(0, 18), UDim2.new(1, 0, 0, 16)
	local title = Kit.SkyBig(content, "Title", "STAY IN THE LOBBY", 40)
	title.Position, title.Size = UDim2.fromOffset(40, 40), UDim2.new(1, -80, 0, 42)
	local line = Kit.Body(content, "Message", message, 17, Kit.Navy)
	line.Position, line.Size, line.TextWrapped = UDim2.fromOffset(60, 88), UDim2.new(1, -120, 0, 36), true
	local function close() gui:Destroy() end
	local buttons = Kit.Frame(content, "Buttons", UDim2.fromOffset(0, 46), UDim2.new(.5, 0, 0, 132))
	buttons.AnchorPoint, buttons.AutomaticSize = Vector2.new(.5, 0), Enum.AutomaticSize.X
	local list = Instance.new("UIListLayout")
	list.FillDirection, list.Padding, list.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 12), Enum.SortOrder.LayoutOrder
	list.Parent = buttons
	if canWatch and activate then
		local watch = Kit.SkyButton(buttons, "Watch", "Watch racers", UDim2.fromOffset(200, 46), UDim2.new(), function() close(); activate("Watch") end, "Primary", 18)
		watch.LayoutOrder = 1
	end
	local back = Kit.SkyButton(buttons, "Lobby", "Return to lobby", UDim2.fromOffset(200, 46), UDim2.new(), close, "Light", 18)
	back.LayoutOrder = 2
	gui.Parent = playerGui
	local size = gui.AbsoluteSize
	scale.Scale = math.clamp(math.min(size.X / 1280, size.Y / 720), .6, 1.2)
	Kit.Play("Alert")
	Kit.Punch(plate, .8, .45)
	task.delay(10, function() if gui.Parent then close() end end)
end

return View
