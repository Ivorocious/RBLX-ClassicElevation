--!strict
-- Practice screens (brief "Practice"): the line choice, the running HUD (timer, pad strip, lap,
-- best, Retry, LAP ribbon, departure banner) and the finish burst with its next steps. Pad and lap
-- counts always come from the snapshot or the lane attributes passed in `screen`.
local RunService = game:GetService("RunService")
local Kit = require(script.Parent.UiKit)
local Clock = require(script.Parent.RacePresentation).Clock
local Signs = require(script.Parent.PracticeSigns)

local View = {}
local DESIGN = Vector2.new(1280, 720)
local LINE_NAMES = {Normal = "Normal", Hard = "Harder line"}
-- Pad heights (0-1) sketched on each line card's art.
local LINE_ART = {Normal = {.62, .5, .58, .44, .54}, Hard = {.72, .36, .68, .18, .48}}

local function round(item: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), item
end

local function setAvailable(button: GuiObject, available: boolean)
	button:SetAttribute("Available", available)
	button.Selectable, button.Active = available, available
end

local function lineArt(parent: Instance, line: string): Frame
	local art = Kit.Frame(parent, "Art", UDim2.fromOffset(282, 120), UDim2.fromOffset(24, 22), Kit.White, 0)
	round(art, 10)
	Kit.Stroke(art, Kit.Navy, 3, true)
	local sky = Instance.new("UIGradient")
	sky.Rotation, sky.Color = 90, ColorSequence.new(Color3.fromHex("8EDBFF"), Color3.fromHex("3E8BF5"))
	sky.Parent = art
	for index, height in LINE_ART[line] do
		local pip = Kit.Frame(art, "Pad" .. index, UDim2.fromOffset(34, 14), UDim2.new((index - .5) / 5, 0, height, 0), Kit.White, 0)
		pip.AnchorPoint = Vector2.new(.5, .5)
		round(pip, 4)
		Kit.Stroke(pip, Kit.Navy, 2.5, true)
	end
	return art
end

function View.Create(parent: Instance, activate: (string) -> ()): any
	-- Dims the world behind the line choice and finish screens, edge to edge.
	local shade = Kit.Frame(parent, "PracticeShade", UDim2.fromScale(1, 1), UDim2.new(), Kit.Navy, .55)
	shade.ZIndex, shade.Visible = 0, false
	local stage = Kit.Frame(parent, "PracticeStage", UDim2.fromOffset(DESIGN.X, DESIGN.Y), UDim2.fromScale(.5, .5))
	stage.AnchorPoint = Vector2.new(.5, .5)
	local fit = Instance.new("UIScale")
	fit.Name, fit.Parent = "Fit", stage
	local practice: any = {shade = shade, stage = stage, fit = fit, buttons = {}, cells = {}, padCount = 0, nextIndex = -1, lap = 0}

	-- Running HUD.
	local hud = Kit.Frame(stage, "Hud", UDim2.fromScale(1, 1), UDim2.new())
	hud.Visible = false
	local timer = Kit.Plate(hud, "Timer", UDim2.fromOffset(380, 96), UDim2.fromOffset(450, 12), {hero = true})
	local timerContent = Kit.Content(timer)
	practice.timerCaption = Kit.Caption(timerContent, "Caption", "Practice", 13)
	practice.timerCaption.Position = UDim2.fromOffset(0, 14)
	practice.time = Kit.Big(timerContent, "Time", "0:00.0", 54)
	practice.time.Position = UDim2.fromOffset(0, 32)
	local pads = Kit.Frame(hud, "Pads", UDim2.fromOffset(0, 40), UDim2.new(.5, 0, 0, 122))
	pads.AnchorPoint, pads.AutomaticSize = Vector2.new(.5, 0), Enum.AutomaticSize.X
	local padList = Instance.new("UIListLayout")
	padList.FillDirection, padList.VerticalAlignment, padList.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0, 8)
	padList.SortOrder, padList.Parent = Enum.SortOrder.LayoutOrder, pads
	practice.lapChip = Kit.Chip(pads, "Lap", "Lap 1 / 1", 16)
	practice.lapChip.LayoutOrder = 1000
	practice.best = Kit.Chip(hud, "Best", "", 16)
	practice.best.AnchorPoint, practice.best.Position = Vector2.new(1, 0), UDim2.new(1, -24, 0, 100)
	practice.retry = Kit.Button(hud, "Retry", "Retry", UDim2.fromOffset(124, 48), UDim2.new(1, -24, 0, 140), function() activate("Retry") end, false, 19)
	practice.retry.AnchorPoint = Vector2.new(1, 0)
	local banner = Kit.Plate(hud, "Departure", UDim2.fromOffset(580, 92), UDim2.fromOffset(350, 190), {fill = Kit.PinkPale, dots = true, tilt = 1})
	banner.Visible = false
	local bannerContent = Kit.Content(banner)
	local bannerTitle = Kit.Title(bannerContent, "Title", "YOUR RACE IS GETTING READY", 26)
	bannerTitle.Position, bannerTitle.Size = UDim2.fromOffset(26, 18), UDim2.fromOffset(420, 28)
	Kit.SetBigAlignment(bannerTitle, Enum.TextXAlignment.Left)
	practice.bannerLine = Kit.Body(bannerContent, "Line", "", 15, Kit.Navy)
	practice.bannerLine.Position, practice.bannerLine.Size, practice.bannerLine.TextXAlignment = UDim2.fromOffset(26, 54), UDim2.fromOffset(420, 18), Enum.TextXAlignment.Left
	practice.bannerTime = Kit.Big(bannerContent, "Countdown", "0:00", 48)
	practice.bannerTime.Position, practice.bannerTime.Size = UDim2.fromOffset(430, 20), UDim2.fromOffset(126, 52)
	Kit.SetBigAlignment(practice.bannerTime, Enum.TextXAlignment.Right)
	practice.hud, practice.banner = hud, banner

	-- Line choice.
	local lines = Kit.Frame(stage, "Lines", UDim2.fromScale(1, 1), UDim2.new())
	lines.Visible = false
	local header = Kit.Plate(lines, "Header", UDim2.fromOffset(480, 112), UDim2.fromOffset(400, 18), {hero = true})
	local headerContent = Kit.Content(header)
	local headerCaption = Kit.Caption(headerContent, "Caption", "Practice area · no placings, no rewards", 13)
	headerCaption.Position = UDim2.fromOffset(0, 20)
	local headerTitle = Kit.Title(headerContent, "Title", "PICK A LINE", 50)
	headerTitle.Position = UDim2.fromOffset(0, 42)
	practice.linesClose = Kit.Button(lines, "Close", "×", UDim2.fromOffset(48, 48), UDim2.fromOffset(838, 40), function() activate("Close") end, false, 26)
	practice.cards = {}
	for index, line in {"Normal", "Hard"} do
		local card = Kit.Plate(lines, "Line" .. line, UDim2.fromOffset(330, 300), UDim2.fromOffset(295 + (index - 1) * 360, 162), {tilt = if index == 1 then -1.5 else 1.5})
		local content = Kit.Content(card)
		lineArt(content, line)
		local title = Kit.Title(content, "Title", string.upper(LINE_NAMES[line]), 34)
		title.Position = UDim2.fromOffset(0, 152)
		local chip = Kit.Chip(content, "Facts", "", 15)
		chip.AnchorPoint, chip.Position = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, 196)
		local id = "Practice" .. line
		local start = Kit.Button(content, id, "Start a run", UDim2.fromOffset(282, 52), UDim2.fromOffset(24, 232), function() activate(id) end, true, 21)
		practice.cards[line] = {card = card, chip = chip, start = start}
	end
	practice.linesJoin = Kit.Button(lines, "Join", "Start racing", UDim2.fromOffset(240, 50), UDim2.fromOffset(392, 494), function() activate(practice.joinId or "Join") end, false, 19)
	practice.linesExit = Kit.Button(lines, "ExitPractice", "Return to lobby", UDim2.fromOffset(240, 50), UDim2.fromOffset(648, 494), function() activate("ExitPractice") end, false, 19)
	practice.lines = lines

	-- Finish burst and next steps.
	local finished = Kit.Frame(stage, "Finished", UDim2.fromScale(1, 1), UDim2.new())
	finished.Visible = false
	local rays = Kit.Icon(finished, "Rays", Kit.Images.Rays, 1200, Kit.Sun)
	rays.AnchorPoint, rays.Position, rays.ImageTransparency = Vector2.new(.5, .5), UDim2.fromOffset(640, 230), .6
	practice.rays = rays
	practice.finishCaption = Kit.Caption(finished, "Caption", "Practice done", 20, Kit.White)
	practice.finishCaption.Position, practice.finishCaption.Size = UDim2.fromOffset(0, 92), UDim2.new(1, 0, 0, 22)
	Kit.Stroke(practice.finishCaption, Kit.Navy, 4, false)
	practice.finishTime = Kit.Big(finished, "Time", "0:00.00", 124, {outline = 9, shadow = 8})
	practice.finishTime.Position = UDim2.fromOffset(0, 148)
	practice.finishChip = Kit.Chip(finished, "Best", "", 19, "Good")
	practice.finishChip.AnchorPoint, practice.finishChip.Position = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, 296)
	local card = Kit.Plate(finished, "Card", UDim2.fromOffset(620, 160), UDim2.fromOffset(330, 520))
	local cardContent = Kit.Content(card)
	practice.finishRetry = Kit.Button(cardContent, "Retry", "Retry practice", UDim2.fromOffset(572, 58), UDim2.fromOffset(24, 20), function() activate("Retry") end, true, 24)
	practice.finishOther = Kit.Button(cardContent, "Other", "Try the harder line", UDim2.fromOffset(180, 48), UDim2.fromOffset(24, 94), function() activate(practice.otherId or "PracticeHard") end, false, 16)
	practice.finishJoin = Kit.Button(cardContent, "Join", "Start racing", UDim2.fromOffset(180, 48), UDim2.fromOffset(220, 94), function() activate(practice.joinId or "Join") end, false, 16)
	practice.finishExit = Kit.Button(cardContent, "ExitPractice", "Return to lobby", UDim2.fromOffset(180, 48), UDim2.fromOffset(416, 94), function() activate("ExitPractice") end, false, 16)
	practice.finishClose = Kit.Button(card, "Close", "×", UDim2.fromOffset(44, 44), UDim2.fromOffset(596, -22), function() activate("Close") end, false, 24)
	practice.finishClose.ZIndex = 5
	practice.finished, practice.card = finished, card

	local spin = RunService.RenderStepped:Connect(function(dt)
		if finished.Visible and Kit.Motion() then rays.Rotation = (rays.Rotation + dt * 18) % 360 end
		-- The next pad breathes so it reads at a glance.
		local nextCell = practice.cells[if practice.nextIndex == 0 then practice.padCount else practice.nextIndex]
		if hud.Visible and nextCell and Kit.Motion() then
			Kit.Scaler(nextCell).Scale = 1.22 + .08 * math.sin(os.clock() * 6)
		end
		if hud.Visible and practice.startedAt then
			Kit.SetBig(practice.time, Clock(math.max(0, workspace:GetServerTimeNow() - practice.startedAt), 1))
		end
	end)
	stage.Destroying:Connect(function() spin:Disconnect() end)
	return practice
end

function View.Layout(practice: any, size: Vector2, large: boolean)
	local fit = math.min(size.X / DESIGN.X, size.Y / DESIGN.Y)
	practice.fit.Scale = math.min(math.clamp(fit, .42, 1.3) * (if large then 1.08 else 1), size.Y / DESIGN.Y)
end

local function buildPads(practice: any, padCount: number)
	for _, cell in practice.cells do cell:Destroy() end
	table.clear(practice.cells)
	for index = 1, padCount do
		-- The last cell is the Start pad, which ends each lap.
		local finishCell = index == padCount
		local cell = Kit.Frame(practice.hud.Pads, "Pad" .. index, UDim2.fromOffset(32, 32), UDim2.new(), Kit.White, 0)
		cell.LayoutOrder = index
		round(cell, 8)
		Kit.Stroke(cell, Kit.Navy, 3, true)
		if finishCell then
			local flag = Kit.Icon(cell, "Flag", Kit.Images.FinishFlag, 22)
			flag.AnchorPoint, flag.Position = Vector2.new(.5, .5), UDim2.fromScale(.5, .5)
		else
			local label = Instance.new("TextLabel")
			label.Name, label.BackgroundTransparency, label.Size = "Number", 1, UDim2.fromScale(1, 1)
			label.FontFace, label.TextSize, label.TextColor3, label.Text = Kit.Display, 16, Kit.Navy, tostring(index)
			label.Parent = cell
		end
		practice.cells[index] = cell
	end
	practice.padCount = padCount
end

local function lapRibbon(practice: any, lap: number, lapCount: number)
	local old = practice.hud:FindFirstChild("LapRibbon")
	if old then old:Destroy() end
	local ribbon = Kit.Plate(practice.hud, "LapRibbon", UDim2.fromOffset(300, 112), UDim2.fromOffset(150, 250), {hero = true})
	local content = Kit.Content(ribbon)
	local caption = Kit.Caption(content, "Caption", if lap == lapCount then "Back through Start · last lap" else "Back through Start", 13)
	caption.Position = UDim2.fromOffset(0, 16)
	local big = Kit.Big(content, "Lap", "LAP " .. lap, 64)
	big.Position = UDim2.fromOffset(0, 36)
	Kit.Play("Whoosh")
	if Kit.Motion() then
		ribbon.Position = UDim2.fromOffset(-30, 250)
		Kit.Tween(ribbon, .46, {Position = UDim2.fromOffset(150, 250)}, "Pop")
	end
	if Kit.Frozen then return end
	task.delay(1.6, function()
		if not ribbon.Parent then return end
		Kit.Tween(ribbon, .34, {Position = UDim2.fromOffset(330, 250)}, "In")
		Kit.FadeTree(ribbon, false, .34)
		task.delay(.4, function() ribbon:Destroy() end)
	end)
end

-- Running HUD; `screen` is RaceFlowPresentation.PracticeScreen's Running result or nil.
function View.SetHud(practice: any, screen: any?)
	Signs.Update(screen)
	local running = screen ~= nil and screen.mode == "Running"
	local appearing = running and not practice.hud.Visible
	practice.hud.Visible = running
	if not running then
		practice.startedAt, practice.nextIndex, practice.lap = nil, -1, 0
		return
	end
	practice.startedAt = screen.startedAt
	if not screen.startedAt then Kit.SetBig(practice.time, Clock(screen.elapsed or 0, 1)) end
	practice.timerCaption.Text = string.upper("Practice · " .. (LINE_NAMES[screen.line] or screen.line))
	local padCount = if typeof(screen.padCount) == "number" and screen.padCount > 0 then screen.padCount else 0
	if padCount ~= practice.padCount then buildPads(practice, padCount) end
	local nextIndex = if typeof(screen.nextIndex) == "number" then screen.nextIndex else -1
	if nextIndex ~= practice.nextIndex then
		for index, cell in practice.cells do
			local isFinish = index == padCount
			local done = if nextIndex == 0 then not isFinish else index < nextIndex and nextIndex > 0
			local isNext = if nextIndex == 0 then isFinish else index == nextIndex
			cell.BackgroundColor3 = if isNext then Kit.Sun elseif done then Kit.Mint else Kit.White
			local scale = Kit.Scaler(cell)
			scale.Scale = if isNext then 1.25 else 1
		end
		local finished = practice.cells[if nextIndex == 0 then padCount - 1 elseif nextIndex == 1 then padCount else nextIndex - 1]
		if not appearing and practice.nextIndex >= 0 and finished then
			Kit.Punch(finished, 1.6, .3)
			Kit.Play("Pop")
		end
		practice.nextIndex = nextIndex
	end
	local lap, lapCount = screen.lap or 1, screen.lapCount or 1
	Kit.SetChip(practice.lapChip, "Lap " .. lap .. " / " .. lapCount)
	if not appearing and practice.lap > 0 and lap > practice.lap then lapRibbon(practice, lap, lapCount) end
	practice.lap = lap
	practice.best.Visible = typeof(screen.best) == "number"
	if typeof(screen.best) == "number" then Kit.SetChip(practice.best, "Best this visit " .. Clock(screen.best, 2)) end
	local departing = typeof(screen.departure) == "number"
	if departing and not practice.banner.Visible then
		practice.banner.Visible = true
		Kit.Play("Alert")
		Kit.Punch(practice.banner, .8, .5)
	elseif not departing then
		practice.banner.Visible = false
	end
	if departing then
		local seconds = math.ceil(screen.departure)
		local text = string.format("%d:%02d", seconds // 60, seconds % 60)
		if (practice.bannerTime :: any):GetAttribute("Shown") ~= text then
			practice.bannerTime:SetAttribute("Shown", text)
			Kit.SetBig(practice.bannerTime, text)
			Kit.Punch(practice.bannerTime, 1.3, .32)
		end
		practice.bannerLine.Text = "Practice ends when you leave for " .. tostring(screen.course or "your race")
	end
	if appearing and Kit.Motion() then
		Kit.Punch(practice.hud.Timer, .6, .5)
		Kit.Punch(practice.hud.Pads, .6, .45, .12)
	end
end

local function joinLabel(join: any?): (string, string)
	if join and join.id == "Break" then return "Break", join.text end
	return "Join", if join then join.text else "Start racing"
end

-- Line choice or finish screen. Returns the close button and buttons for keyboard/controller
-- navigation, in order.
function View.ShowModal(practice: any, screen: any?, join: any?, visible: boolean, pending: boolean, opening: boolean): (GuiObject, {{id: string}}, {[string]: GuiObject})
	local mode = if screen then screen.mode else nil
	practice.lines.Visible = visible and mode == "Lines"
	practice.finished.Visible = visible and mode == "Finished"
	practice.shade.Visible = practice.lines.Visible or practice.finished.Visible
	local joinId, joinText = joinLabel(join)
	practice.joinId = joinId
	if mode == "Finished" then
		local other = screen.other
		practice.otherId = "Practice" .. other
		Kit.SetButtonText(practice.finishOther, if other == "Hard" then "Try the harder line" else "Try the normal route")
		Kit.SetButtonText(practice.finishJoin, joinText)
		practice.finishCaption.Text = string.upper("Practice done · " .. (LINE_NAMES[screen.line] or screen.line))
		local chipText, kind = "", "Good"
		if typeof(screen.previous) ~= "number" then chipText = "First run on this line this visit"
		elseif screen.time < screen.previous then chipText = string.format("New best this visit · -%.2fs", screen.previous - screen.time)
		else chipText, kind = "Best this visit " .. Clock(screen.best or screen.previous, 2), "Plain" end
		Kit.SetChip(practice.finishChip, chipText, kind :: any)
		local buttons = {practice.finishRetry, practice.finishOther, practice.finishJoin, practice.finishExit}
		for _, button in buttons do setAvailable(button, not pending) end
		if opening and visible then
			local serial = (practice.finishSerial or 0) + 1
			practice.finishSerial = serial
			Kit.Play("Fanfare")
			practice.finishChip.Visible = Kit.Frozen or not Kit.Motion()
			Kit.Punch(practice.finishTime, 2.4, .64)
			if Kit.Motion() then
				practice.rays.ImageTransparency = 1
				Kit.Tween(practice.rays, .6, {ImageTransparency = .6}, "Out")
				practice.card.Position = UDim2.fromOffset(330, 760)
				Kit.Tween(practice.card, .56, {Position = UDim2.fromOffset(330, 520)}, "Pop", .9)
			end
			task.spawn(function()
				local started, seconds = os.clock(), if Kit.Motion() then .8 else 0
				while practice.finishSerial == serial and practice.finished.Visible do
					local k = if seconds <= 0 then 1 else math.clamp((os.clock() - started) / seconds, 0, 1)
					Kit.SetBig(practice.finishTime, Clock(screen.time * (1 - (1 - k) ^ 3), 2))
					if k >= 1 then break end
					RunService.RenderStepped:Wait()
				end
			end)
			task.delay(if Kit.Motion() then 1 else 0, function()
				if practice.finishSerial ~= serial then return end
				practice.finishChip.Visible = true
				Kit.Punch(practice.finishChip, .01, .48)
			end)
		end
		return practice.finishClose, {{id = "Retry"}, {id = practice.otherId}, {id = joinId}, {id = "ExitPractice"}},
			{Retry = practice.finishRetry, [practice.otherId] = practice.finishOther, [joinId] = practice.finishJoin, ExitPractice = practice.finishExit}
	end
	for _, info in (screen and screen.lines or {}) do
		local card = practice.cards[info.line]
		if card then
			local facts = {}
			if typeof(info.pads) == "number" then table.insert(facts, info.pads .. " pads") end
			if typeof(info.laps) == "number" then table.insert(facts, info.laps .. (if info.laps == 1 then " lap" else " laps")) end
			table.insert(facts, if typeof(info.best) == "number" then "best " .. Clock(info.best, 2) else "no time yet")
			Kit.SetChip(card.chip, table.concat(facts, " · "))
			setAvailable(card.start, not pending)
		end
	end
	Kit.SetButtonText(practice.linesJoin, joinText)
	setAvailable(practice.linesJoin, not pending)
	setAvailable(practice.linesExit, not pending)
	if opening and visible and Kit.Motion() then
		Kit.Play("Whoosh")
		local header = practice.lines.Header
		header.Position = UDim2.fromOffset(400, -140)
		Kit.Tween(header, .56, {Position = UDim2.fromOffset(400, 18)}, "Pop")
		for index, line in {"Normal", "Hard"} do
			local card = practice.cards[line].card
			local home = UDim2.fromOffset(295 + (index - 1) * 360, 162)
			card.Position = home + UDim2.fromOffset(0, 140)
			Kit.Tween(card, .56, {Position = home}, "Pop", .2 + (index - 1) * .14)
		end
	end
	return practice.linesClose, {{id = "PracticeNormal"}, {id = "PracticeHard"}, {id = joinId}, {id = "ExitPractice"}},
		{PracticeNormal = practice.cards.Normal.start, PracticeHard = practice.cards.Hard.start, [joinId] = practice.linesJoin, ExitPractice = practice.linesExit}
end

return View
