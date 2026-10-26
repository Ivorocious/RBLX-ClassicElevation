--!strict
-- First-visit coach card (brief "First visit"): three step bars, the guide's cue and Skip
-- introduction; the last step adds the flow's join action. Camera moves and every stop rule stay
-- in VisitIntroController.
local TextService = game:GetService("TextService")
local Kit = require(script.Parent.UiKit)

local View = {}
local WIDTH, PAD, TITLE, MESSAGE = 620, 26, 40, 19
local SKIP_WIDTH, GO_WIDTH = 230, 210
local SLANT = Kit.SkySlant("L")

function View.Create(parent: Instance, activate: (string) -> ()): any
	local holder = Kit.Frame(parent, "CoachHolder", UDim2.fromOffset(WIDTH, 210), UDim2.new(.5, 0, 1, -24))
	holder.AnchorPoint = Vector2.new(.5, 1)
	local scale = Instance.new("UIScale")
	scale.Name, scale.Parent = "LayoutScale", holder
	local plate = Kit.SkyPlate(holder, "Coach", UDim2.fromScale(1, 1), UDim2.new(), {class = "L", stripes = true})
	Kit.Sheen(plate, 5)
	plate.Visible = false
	local content = Kit.Content(plate)
	local steps = {}
	for index = 1, 3 do
		local bar = Kit.Frame(content, "Step" .. index, UDim2.fromOffset(42, 10), UDim2.new(), Kit.White, .6)
		local round = Instance.new("UICorner")
		round.CornerRadius, round.Parent = UDim.new(1, 0), bar
		Kit.Stroke(bar, Kit.Navy, 2, true)
		steps[index] = bar
	end
	local title = Kit.SkyBig(content, "Title", "", TITLE)
	Kit.SetBigAlignment(title, Enum.TextXAlignment.Left)
	local message = Kit.Body(content, "Message", "", MESSAGE, Kit.White)
	message.TextXAlignment, message.TextYAlignment, message.TextWrapped = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, true
	local edge = Kit.Stroke(message, Kit.Navy, 1.2, false)
	edge.Transparency = .35
	local skip = Kit.SkyButton(content, "SkipIntro", "Skip introduction", UDim2.fromOffset(SKIP_WIDTH, 48), UDim2.new(), function() activate("SkipIntro") end, "Alt", 18)
	local go = Kit.SkyButton(content, "Join", "Start racing", UDim2.fromOffset(GO_WIDTH, 48), UDim2.new(), function() activate("Join") end, "Primary", 19)
	go.Visible = false
	return {holder = holder, scale = scale, plate = plate, steps = steps, title = title, message = message,
		skip = skip, go = go, buttons = {Join = go}, height = 210, step = 0, signature = ""}
end

-- Rows run top to bottom; each starts just inside the slanted left edge at its own height.
local function place(coach: any)
	local textWidth = WIDTH - SLANT - PAD * 2
	local measured = TextService:GetTextSize(coach.message.Text, MESSAGE, Enum.Font.FredokaOne, Vector2.new(textWidth, 1000))
	local messageHeight = math.max(48, measured.Y + 4)
	local height = 18 + 10 + 10 + 46 + 6 + messageHeight + 12 + 48 + 22
	coach.height = height
	coach.holder.Size = UDim2.fromOffset(WIDTH, height)
	local function edges(y: number, h: number): (number, number)
		local middle = (y + h / 2) / height
		return SLANT * (1 - middle) + PAD, WIDTH - SLANT * middle - PAD
	end
	local y = 18
	local left, right = edges(y, 10)
	for index, bar in coach.steps do bar.Position = UDim2.fromOffset(left + (index - 1) * 50, y) end
	y += 20
	left, right = edges(y, 46)
	coach.title.Position, coach.title.Size = UDim2.fromOffset(left, y), UDim2.fromOffset(right - left, 46)
	local labels = Kit.BigLabels(coach.title)
	local titleWidth = TextService:GetTextSize(labels[1].Text, TITLE, Enum.Font.LuckiestGuy, Vector2.new(10000, 100)).X
	for _, label in labels do label.TextSize = math.max(22, math.min(TITLE, math.floor(TITLE * (right - left) / math.max(1, titleWidth)))) end
	y += 52
	left, right = edges(y, messageHeight)
	coach.message.Position, coach.message.Size = UDim2.fromOffset(left, y), UDim2.fromOffset(right - left, messageHeight)
	y += messageHeight + 12
	left, right = edges(y, 48)
	local x = right
	if coach.go.Visible then
		x -= GO_WIDTH
		coach.go.Position = UDim2.fromOffset(x, y)
		x -= 12
	end
	coach.skip.Position = UDim2.fromOffset(x - SKIP_WIDTH, y)
end

function View.Layout(coach: any, size: Vector2, large: boolean)
	local design = math.clamp(math.min(size.X / 1280, size.Y / 720), .6, 1.2) * (if large then 1.1 else 1)
	coach.scale.Scale = math.min(design, (size.X - 24) / WIDTH, (size.Y - 44) / coach.height)
end

-- cue: {title, message, step, count, buttons} from RaceFlowController; buttons holds the join
-- action on the last step only.
function View.Render(coach: any, cue: any, pending: boolean, opening: boolean)
	local join = cue.buttons and cue.buttons[1]
	local signature = table.concat({tostring(cue.step), cue.title, cue.message, if join then join.text else "", tostring(pending)}, "|")
	if signature == coach.signature and not opening then return end
	coach.signature = signature
	local stepChanged = cue.step ~= coach.step
	coach.step = cue.step
	Kit.SetBig(coach.title, cue.title)
	coach.message.Text = cue.message
	for index, bar in coach.steps do
		local lit = index <= cue.step
		bar.BackgroundColor3, bar.BackgroundTransparency = if lit then Kit.Sun else Kit.White, if lit then 0 else .6
	end
	local appeared = join ~= nil and not coach.go.Visible
	coach.go.Visible = join ~= nil
	if join then Kit.SetButtonText(coach.go, join.text) end
	for _, button in {coach.skip, coach.go} do
		button:SetAttribute("Available", not pending)
		button.Selectable, button.Active = not pending, not pending
	end
	place(coach)
	if opening and Kit.Motion() then
		coach.plate.Position = UDim2.fromOffset(0, 220)
		Kit.Tween(coach.plate, .6, {Position = UDim2.new()}, "Pop")
	elseif opening then
		coach.plate.Position = UDim2.new()
	end
	if stepChanged then
		Kit.Punch(coach.title, .8, .38)
		Kit.Play(if cue.step == cue.count then "Checkpoint" else "Whoosh")
	end
	if appeared then Kit.Punch(coach.go, .01, .48, .1) end
end

return View
