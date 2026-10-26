--!strict
-- Finish ticket (brief "Finish"): the Race options model drawn as the race-sticker ticket.
-- Watch racers and Return to lobby are the large pair; every other model button keeps its
-- order in a smaller grid underneath.
local Kit = require(script.Parent.UiKit)
local Presentation = require(script.Parent.RacePresentation)

local View = {}
local MAIN_ACTIONS = {Watch = true, Lobby = true}
local WIDTH = 540

local function list(parent: Instance, horizontal: boolean, padding: number): UIListLayout
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	layout.HorizontalAlignment, layout.VerticalAlignment = Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center
	layout.Padding, layout.SortOrder = UDim.new(0, padding), Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

function View.Create(parent: Instance, activate: (string) -> ()): any
	local ticket: any = {buttons = {}, signature = "", activate = activate}
	local plate = Kit.Plate(parent, "FinishTicket", UDim2.fromOffset(WIDTH, 300), UDim2.new(.5, 0, 1, -16))
	plate.AnchorPoint, plate.Visible = Vector2.new(.5, 1), false
	local fit = Instance.new("UIScale")
	fit.Name, fit.Parent = "Fit", plate
	local content = Kit.Content(plate)
	local stack = Kit.Frame(content, "Stack", UDim2.new(1, -44, 1, -36), UDim2.fromOffset(22, 16))
	local layout = list(stack, false, 10)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	local title = Kit.Title(stack, "Title", "", 36)
	title.LayoutOrder = 1
	local line = Kit.Frame(stack, "Line", UDim2.fromOffset(0, 36), UDim2.new())
	line.AutomaticSize, line.LayoutOrder = Enum.AutomaticSize.X, 2
	list(line, true, 14)
	local place = Kit.Big(line, "Place", "", 34, {auto = true})
	place.LayoutOrder = 1
	local time = Kit.Big(line, "Time", "", 34, {auto = true})
	time.LayoutOrder = 2
	local best = Kit.Chip(stack, "VisitBest", "Fastest official run on this course this visit", 16, "Good")
	best.LayoutOrder = 3
	local bar = Kit.Frame(stack, "Checkpoints", UDim2.fromOffset(0, 14), UDim2.new())
	bar.AutomaticSize, bar.LayoutOrder = Enum.AutomaticSize.X, 4
	list(bar, true, 6)
	local target = Kit.Chip(stack, "Target", "", 16)
	target.LayoutOrder = 5
	local message = Kit.Body(stack, "Message", "", 15, Kit.Navy)
	message.LayoutOrder, message.TextWrapped = 6, true
	message.Size, message.AutomaticSize = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y
	local visit = Kit.Body(stack, "Visit", "", 15)
	visit.LayoutOrder, visit.TextWrapped = 7, true
	visit.Size, visit.AutomaticSize = UDim2.new(1, 0, 0, 0), Enum.AutomaticSize.Y
	local actions = Kit.Frame(stack, "Actions", UDim2.new(1, 0, 0, 54), UDim2.new())
	actions.LayoutOrder = 8
	list(actions, true, 14)
	local more = Kit.Frame(stack, "More", UDim2.new(1, 0, 0, 0), UDim2.new())
	more.LayoutOrder, more.AutomaticSize = 9, Enum.AutomaticSize.Y
	local grid = Instance.new("UIGridLayout")
	grid.CellPadding, grid.FillDirectionMaxCells = UDim2.fromOffset(10, 10), 3
	grid.HorizontalAlignment, grid.SortOrder = Enum.HorizontalAlignment.Center, Enum.SortOrder.LayoutOrder
	grid.Parent = more
	local close = Kit.Button(content, "Close", "×", UDim2.fromOffset(44, 44), UDim2.new(1, -14, 0, -14), function() activate("Close") end, false, 30)
	close.AnchorPoint = Vector2.new(.5, .5)
	ticket.plate, ticket.fit, ticket.layout, ticket.close, ticket.actions, ticket.more, ticket.grid = plate, fit, layout, close, actions, more, grid
	ticket.title, ticket.line, ticket.place, ticket.time, ticket.best, ticket.bar, ticket.target, ticket.message, ticket.visit =
		title, line, place, time, best, bar, target, message, visit
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() View.FitHeight(ticket) end)
	return ticket
end

function View.FitHeight(ticket: any)
	local scale = math.max(ticket.fit.Scale, .01)
	ticket.plate.Size = UDim2.fromOffset(WIDTH, math.ceil(ticket.layout.AbsoluteContentSize.Y / scale) + 36)
end

-- Desktop matches the page's 1280 x 720 ticket; phones keep it centred between the thumbstick
-- and jump button, at a size where every button stays at least 46 pixels tall.
function View.Layout(ticket: any, size: Vector2, largeText: boolean)
	local fit = math.min(size.X / 1280, size.Y / 720)
	local compact = size.Y < 520
	local scale = math.clamp(if compact then math.max(fit * 1.15, .6) else fit, .55, 1.15) * (if largeText then 1.08 else 1)
	ticket.fit.Scale = scale
	ticket.plate.Position = UDim2.new(.5, 0, 1, -(if compact then 14 else 22) * scale)
	ticket.buttonHeight = math.max(54, 46 / scale)
	ticket.smallHeight = math.max(40, 46 / scale)
	local closeSize = math.max(44, 46 / scale)
	ticket.close.Size = UDim2.fromOffset(closeSize, closeSize)
	ticket.actions.Size = UDim2.new(1, 0, 0, ticket.buttonHeight)
	ticket.grid.CellSize = UDim2.fromOffset(150, ticket.smallHeight)
	for id, button in ticket.buttons do
		button.Size = if MAIN_ACTIONS[id] then UDim2.fromOffset(220, ticket.buttonHeight) else UDim2.new(1, 0, 1, 0)
	end
	View.FitHeight(ticket)
end

local function setCells(ticket: any, count: number, reached: number)
	local bar = ticket.bar
	if bar:GetAttribute("Cells") ~= count then
		for _, cell in bar:GetChildren() do if cell:IsA("Frame") then cell:Destroy() end end
		local width = math.clamp(math.floor(360 / math.max(count, 1)) - 6, 10, 36)
		for index = 1, count do
			local cell = Kit.Frame(bar, "Cell", UDim2.fromOffset(width, 14), UDim2.new(), Kit.White, 0)
			cell.LayoutOrder = index
			local cellCorner = Instance.new("UICorner")
			cellCorner.CornerRadius, cellCorner.Parent = UDim.new(1, 0), cell
			Kit.Stroke(cell, Kit.Navy, 2.5, true)
		end
		bar:SetAttribute("Cells", count)
	end
	for _, cell in bar:GetChildren() do
		if cell:IsA("Frame") then cell.BackgroundColor3 = if cell.LayoutOrder <= reached then Kit.Sun else Kit.White end
	end
end

-- Fills the ticket from RaceFlowPresentation.Model (model.ticket holds the structured lines).
function View.Render(ticket: any, model: any, pending: boolean, message: string?)
	local data = model.ticket
	Kit.SetBig(ticket.title, if data.finished then "COURSE COMPLETED" else "RUN UNFINISHED")
	ticket.line.Visible = data.finished == true
	if data.finished then
		Kit.SetBig(ticket.place, if typeof(data.placement) == "number" then data.placement .. Presentation.Ordinal(data.placement) else "–")
		Kit.SetBig(ticket.time, Presentation.Clock(data.finishTime, 2))
	end
	ticket.best.Visible = data.finished == true and data.visitBest == true
	local count = if typeof(data.count) == "number" then math.clamp(data.count, 0, 30) else 0
	ticket.bar.Visible = not data.finished and count > 0
	if ticket.bar.Visible then setCells(ticket, count, if typeof(data.furthest) == "number" then data.furthest else 0) end
	ticket.target.Visible = not data.finished and data.target ~= nil
	if data.target then Kit.SetChip(ticket.target, data.target) end
	local note = data.message or ""
	if message and message ~= "" then note = if note ~= "" then note .. "\n" .. message else message end
	ticket.message.Text, ticket.message.Visible = note, note ~= ""
	ticket.visit.Text = (data.visitLine or "") .. (if data.resultsIn then " · results in " .. data.resultsIn else "")
	ticket.visit.Visible = ticket.visit.Text ~= ""
	local ids = {}
	for _, definition in model.buttons do table.insert(ids, definition.id) end
	local signature = table.concat(ids, ",")
	if signature ~= ticket.signature then
		for _, button in ticket.buttons do button:Destroy() end
		table.clear(ticket.buttons)
		ticket.signature = signature
		local mains, others = 0, 0
		for index, definition in model.buttons do
			local id = definition.id
			local main = MAIN_ACTIONS[id] == true
			local button = Kit.Button(if main then ticket.actions else ticket.more, id, definition.text,
				if main then UDim2.fromOffset(220, ticket.buttonHeight or 54) else UDim2.fromScale(1, 1), UDim2.new(),
				function() ticket.activate(id) end, main and id == "Watch", if main then 19 else 15)
			button.LayoutOrder = index
			ticket.buttons[id] = button
			if main then mains += 1 else others += 1 end
		end
		ticket.actions.Visible, ticket.more.Visible = mains > 0, others > 0
	end
	for _, definition in model.buttons do
		local button = ticket.buttons[definition.id]
		if button then
			Kit.SetButtonText(button, definition.text)
			button:SetAttribute("Available", not pending)
			button.Selectable, button.Active = not pending, not pending
		end
	end
	View.FitHeight(ticket)
end

return View
