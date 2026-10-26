--!strict
-- Race HUD view (brief "Racing HUD"): timer plate, live place plate, coin pill (hidden until course
-- coins exist), overtake notes and the climb ladder. It only draws; RaceHudController feeds it.
local Kit = require(script.Parent.UiKit)
local Presentation = require(script.Parent.RacePresentation)

local View = {}

-- Layout is authored on the concept page's 1280 x 720 stage and scaled to the screen.
local DESIGN = Vector2.new(1280, 720)
local LADDER_TOP, LADDER_HEIGHT = 26, 420
local MAX_PER_ROW = 7
local DOT_COLORS = {
	Color3.fromHex("FF5A5F"), Color3.fromHex("FFB627"), Color3.fromHex("A855F7"), Color3.fromHex("3D8BFF"),
	Color3.fromHex("EC4899"), Color3.fromHex("14B8A6"), Color3.fromHex("F97316"), Color3.fromHex("84CC16"),
}

local function scaleOf(item: Instance): UIScale
	local scale = Instance.new("UIScale")
	scale.Name, scale.Parent = "Fit", item
	return scale
end

local function headshot(userId: number): string
	return if userId > 0 then string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60", userId) else ""
end

-- Wraps an auto-width item so it sits `lift` pixels above the bottom of a bottom-aligned row.
local function lifted(parent: Instance, name: string, height: number, lift: number, order: number): Frame
	local wrap = Kit.Frame(parent, name, UDim2.fromOffset(0, height + lift), UDim2.new())
	wrap.AutomaticSize, wrap.LayoutOrder = Enum.AutomaticSize.X, order
	return wrap
end

function View.Create(container: Instance): any
	local canvas = Kit.Frame(container, "RaceHudCanvas", UDim2.fromScale(1, 1), UDim2.new())
	local hud: any = {canvas = canvas, dots = {}, overflow = {}, ticks = {}, tickTotal = 0, shown = false, home = {}, entrance = {}}

	-- Timer plate (top centre).
	local timer = Kit.Plate(canvas, "Timer", UDim2.fromOffset(240, 96), UDim2.new(), {hero = true})
	timer.AnchorPoint = Vector2.new(.5, 0)
	local timerContent = Kit.Content(timer)
	local course = Kit.Caption(timerContent, "Course", "", 13)
	course.Position, course.Size = UDim2.fromOffset(10, 13), UDim2.new(1, -20, 0, 16)
	course.TextTruncate = Enum.TextTruncate.AtEnd
	local clock = Kit.Big(timerContent, "Clock", "0:00.0", 50)
	clock.Position = UDim2.fromOffset(0, 34)
	local lap = Kit.Chip(timerContent, "Lap", "LAP 1 / 3", 16)
	lap.AnchorPoint, lap.Position, lap.Visible = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, 94), false
	hud.timer, hud.course, hud.clock, hud.lap = timer, course, clock, lap

	-- Live place plate (top right).
	-- Wide enough for "20TH / 20".
	local place = Kit.Plate(canvas, "Place", UDim2.fromOffset(250, 132), UDim2.new())
	place.AnchorPoint = Vector2.new(1, 0)
	local placeContent = Kit.Content(place)
	local row = Kit.Frame(placeContent, "Row", UDim2.new(1, -36, 0, 86), UDim2.new(.5, 0, 0, 53))
	row.AnchorPoint = Vector2.new(.5, .5)
	local rowList = Instance.new("UIListLayout")
	rowList.FillDirection, rowList.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Bottom
	rowList.Padding, rowList.SortOrder = UDim.new(0, 4), Enum.SortOrder.LayoutOrder
	rowList.Parent = row
	local number = Kit.Big(row, "Number", "–", 84, {auto = true})
	number.LayoutOrder = 1
	local suffix = Kit.Big(lifted(row, "SuffixWrap", 34, 10, 2), "Suffix", "", 34, {auto = true})
	local of = Kit.Body(lifted(row, "OfWrap", 22, 12, 3), "Of", "", 22, Kit.SubInk)
	of.AutomaticSize, of.Size, of.Position = Enum.AutomaticSize.X, UDim2.fromOffset(0, 22), UDim2.fromOffset(6, 0)
	local live = Kit.Chip(placeContent, "Live", "LIVE", 12, "Bad")
	live.AnchorPoint, live.Position = Vector2.new(1, 0), UDim2.new(1, -12, 0, 10)
	local stats = Kit.Frame(placeContent, "Stats", UDim2.new(1, -36, 0, 22), UDim2.fromOffset(18, 100))
	local statsList = Instance.new("UIListLayout")
	statsList.FillDirection, statsList.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center
	statsList.Padding, statsList.SortOrder = UDim.new(0, 6), Enum.SortOrder.LayoutOrder
	statsList.Parent = stats
	local function stat(name: string, image: string, order: number): TextLabel
		local icon = Kit.Icon(stats, name .. "Icon", image, 18, Kit.SubInk)
		icon.LayoutOrder = order
		local label = Kit.Body(stats, name, "", 16, Kit.SubInk)
		label.RichText, label.AutomaticSize, label.Size, label.LayoutOrder = true, Enum.AutomaticSize.X, UDim2.fromOffset(0, 20), order + 1
		return label
	end
	local checkpoints = stat("Checkpoints", Kit.Images.CheckpointFlag, 1)
	local gap = Kit.Frame(stats, "Gap", UDim2.fromOffset(8, 1), UDim2.new())
	gap.LayoutOrder = 3
	local falls = stat("Falls", Kit.Images.FallArrow, 4)
	hud.place, hud.number, hud.suffix, hud.of, hud.checkpoints, hud.falls, hud.live = place, number, suffix, of, checkpoints, falls, live

	-- Coin pill: part of the design, hidden until course coins exist.
	local coins = Kit.Plate(canvas, "Coins", UDim2.fromOffset(158, 52), UDim2.new())
	coins.AnchorPoint, coins.Visible = Vector2.new(1, 0), false
	local coinIcon = Kit.Icon(Kit.Content(coins), "Coin", Kit.Images.StarCoin, 64)
	coinIcon.Position = UDim2.fromOffset(-12, -8)
	local coinCount = Kit.Big(Kit.Content(coins), "Count", "0", 30)
	coinCount.Position, coinCount.Size = UDim2.fromOffset(58, 11), UDim2.new(1, -66, 0, 30)
	Kit.SetBigAlignment(coinCount, Enum.TextXAlignment.Left)
	hud.coins, hud.coinCount = coins, coinCount

	-- Overtake notes (right column).
	local toasts = Kit.Frame(canvas, "Toasts", UDim2.fromOffset(320, 200), UDim2.new())
	toasts.AnchorPoint = Vector2.new(1, 0)
	local toastList = Instance.new("UIListLayout")
	toastList.HorizontalAlignment, toastList.Padding = Enum.HorizontalAlignment.Right, UDim.new(0, 8)
	toastList.SortOrder = Enum.SortOrder.LayoutOrder
	toastList.Parent = toasts
	hud.toasts, hud.toastOrder = toasts, 0

	-- Climb ladder (left).
	local ladder = Kit.Frame(canvas, "Ladder", UDim2.fromOffset(240, 480), UDim2.new())
	local track = Kit.Frame(ladder, "Track", UDim2.fromOffset(16, LADDER_HEIGHT), UDim2.fromOffset(16, LADDER_TOP), Kit.White, 0)
	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius, trackCorner.Parent = UDim.new(0, 8), track
	Kit.Stroke(track, Kit.Navy, 3.5, true)
	track.ClipsDescendants = true
	local fill = Kit.Frame(track, "Fill", UDim2.fromScale(1, 0), UDim2.fromScale(0, 1), Kit.White, 0)
	fill.AnchorPoint = Vector2.new(0, 1)
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius, fillCorner.Parent = UDim.new(0, 8), fill
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new(Kit.Sun, Kit.Sky)
	gradient.Parent = fill
	local ticks = Kit.Frame(ladder, "Ticks", UDim2.fromScale(1, 1), UDim2.new())
	local summit = Kit.Icon(ladder, "Summit", Kit.Images.FinishFlag, 40)
	summit.Position = UDim2.fromOffset(6, -14)
	local start = Kit.Caption(ladder, "Start", "Start", 13, Kit.White)
	start.Position, start.Size, start.TextXAlignment = UDim2.fromOffset(2, LADDER_TOP + LADDER_HEIGHT + 26), UDim2.fromOffset(60, 16), Enum.TextXAlignment.Left
	Kit.Stroke(start, Kit.Navy, 2, false)
	local dots = Kit.Frame(ladder, "Dots", UDim2.fromScale(1, 1), UDim2.new())
	local youTag = Kit.Chip(ladder, "YouTag", "You", 14)
	youTag.ZIndex, youTag.Visible = 6, false
	hud.ladder, hud.fill, hud.ticksFolder, hud.dotsFolder, hud.youTag = ladder, fill, ticks, dots, youTag

	hud.fits = {
		timer = scaleOf(timer), place = scaleOf(place), coins = scaleOf(coins), toasts = scaleOf(toasts), ladder = scaleOf(ladder),
	}
	canvas.Visible = false
	return hud
end

-- Places every widget for the current screen size; phones get the page's compact zooms.
function View.Layout(hud: any, size: Vector2, largeText: boolean)
	local fit = math.min(size.X / DESIGN.X, size.Y / DESIGN.Y)
	local compact = size.Y < 520
	local plate = math.clamp(if compact then fit * 1.12 else fit, .5, 1.25) * (if largeText then 1.12 else 1)
	local ladderScale = math.clamp(if compact then fit * .8 else fit, .36, 1.2) * (if largeText then 1.08 else 1)
	hud.scale, hud.compact = plate, compact
	for name, scale in hud.fits do
		scale.Scale = if name == "ladder" then ladderScale else plate
	end
	hud.home.timer = UDim2.new(.5, 0, 0, 14 * plate)
	hud.home.place = UDim2.new(1, -20 * plate, 0, 16 * plate)
	hud.home.coins = UDim2.new(1, -20 * plate, 0, (16 + 132 + 14) * plate)
	-- Toasts sit below the Race options launcher (44 px tall) that waits under the place plate.
	hud.home.toasts = UDim2.new(1, -20 * plate, 0, (16 + 132 + 14 + (if hud.coins.Visible then 52 + 14 else 0)) * plate + 44 + 12)
	hud.home.ladder = UDim2.new(0, (if compact then 10 else 26 * plate), 0, (if compact then 34 else 128) * ladderScale)
	hud.entrance = {
		timer = UDim2.fromOffset(0, -150 * plate), place = UDim2.fromOffset(320 * plate, 0), coins = UDim2.fromOffset(320 * plate, 0),
		toasts = UDim2.new(), ladder = UDim2.fromOffset(-300 * ladderScale, 0),
	}
	for name, home in hud.home do
		local item = if name == "timer" then hud.timer elseif name == "place" then hud.place elseif name == "coins" then hud.coins
			elseif name == "toasts" then hud.toasts else hud.ladder
		item.Position = if hud.shown then home else home + hud.entrance[name]
	end
end

-- Slides the HUD in (timer from the top, place from the right, ladder from the left).
function View.SetShown(hud: any, shown: boolean, animate: boolean)
	if hud.shown == shown then return end
	hud.shown = shown
	if shown then hud.canvas.Visible = true end
	local items = {timer = hud.timer, place = hud.place, coins = hud.coins, ladder = hud.ladder}
	local delays = {timer = 0, place = .08, coins = .14, ladder = .2}
	local last: Tween? = nil
	for name, item in items do
		local home = hud.home[name] or item.Position
		local away = home + (hud.entrance[name] or UDim2.new())
		if not animate or not Kit.Motion() then
			item.Position = if shown then home else away
		elseif shown then
			item.Position = away
			last = Kit.Tween(item, .6, {Position = home}, "Pop", delays[name])
		else
			last = Kit.Tween(item, .35, {Position = away}, "In")
		end
	end
	if not shown then
		if last then
			local tween = last :: Tween
			tween.Completed:Once(function() if not hud.shown then hud.canvas.Visible = false end end)
		else
			hud.canvas.Visible = false
		end
	end
end

-- While watching, the ladder stays and the timer and place plates (about the local racer) hide.
function View.SetWatching(hud: any, watching: boolean)
	hud.timer.Visible, hud.place.Visible = not watching, not watching
end

function View.SetCourse(hud: any, name: string)
	hud.course.Text = string.upper(name)
end

function View.SetLap(hud: any, lap: number, total: number)
	hud.lap.Visible = total > 1
	hud.timer.Size = UDim2.fromOffset(240, if total > 1 then 134 else 96)
	if total > 1 then Kit.SetChip(hud.lap, string.format("LAP %d / %d", lap, total)) end
end

function View.SetClock(hud: any, value: string)
	Kit.SetBig(hud.clock, value)
end

function View.SetPlace(hud: any, place: number?, total: number, animate: boolean)
	Kit.SetBig(hud.number, if place then tostring(place) else "–")
	Kit.SetBig(hud.suffix, if place then Presentation.Ordinal(place) else "")
	hud.of.Text = if total > 0 then "/ " .. total else ""
	if animate then Kit.Punch(hud.number.Parent, .7, .45) end
end

function View.SetStats(hud: any, done: number, total: number, falls: number)
	hud.checkpoints.Text = string.format('<font color="#10215C" size="18">%d</font> / %d', done, total)
	hud.falls.Text = string.format('<font color="#10215C" size="18">%d</font> %s', falls, if falls == 1 then "fall" else "falls")
end

function View.PunchCheckpoints(hud: any)
	Kit.Punch(hud.checkpoints, 1.8, .42)
end

function View.SetCoins(hud: any, visible: boolean, count: number?)
	hud.coins.Visible = visible
	if count then Kit.SetBig(hud.coinCount, tostring(count)) end
end

function View.Toast(hud: any, value: string, good: boolean)
	hud.toastOrder -= 1
	local chip = Kit.Chip(hud.toasts, "Toast", value, 17, if good then "Good" else "Bad")
	chip.LayoutOrder = hud.toastOrder
	Kit.ChipIcon(chip, Kit.Images.FallArrow, if good then 180 else 0)
	Kit.Punch(chip, .6, .4)
	if Kit.Frozen then return end
	task.delay(2.2, function()
		if not chip.Parent then return end
		Kit.FadeTree(chip, false, .3)
		task.delay(.32, function() chip:Destroy() end)
	end)
	local children = {}
	for _, child in hud.toasts:GetChildren() do if child:IsA("Frame") then table.insert(children, child) end end
	if #children > 3 then
		table.sort(children, function(a, b) return a.LayoutOrder > b.LayoutOrder end)
		children[1]:Destroy()
	end
end

local function levelY(steps: number, total: number): number
	return LADDER_TOP + LADDER_HEIGHT - steps / math.max(1, total) * LADDER_HEIGHT
end

local function rebuildTicks(hud: any, total: number)
	if hud.tickTotal == total then return end
	hud.tickTotal = total
	for _, tick in hud.ticks do tick:Destroy() end
	table.clear(hud.ticks)
	-- One mark per checkpoint (the finish flag is the last step); long courses thin the marks.
	local every = math.max(1, math.ceil(total / 20))
	for step = 1, total - 1 do
		if step % every == 0 or step == total - 1 then
			local tick = Kit.Frame(hud.ticksFolder, "Tick" .. step, UDim2.fromOffset(32, 5), UDim2.fromOffset(8, levelY(step, total) - 2.5), Kit.Navy, .45)
			tick:SetAttribute("Step", step)
			local tickCorner = Instance.new("UICorner")
			tickCorner.CornerRadius, tickCorner.Parent = UDim.new(0, 3), tick
			local edge = Kit.Stroke(tick, Kit.Navy, 2, true)
			edge.Enabled = false
			table.insert(hud.ticks, tick)
		end
	end
end

local function makeDot(hud: any, row: any, mine: boolean): Frame
	local size = if mine then 40 else 28
	local dot = Kit.Frame(hud.dotsFolder, "Dot" .. row.userId, UDim2.fromOffset(size, size), UDim2.fromOffset(46, levelY(0, 1) - size / 2),
		DOT_COLORS[(math.abs(row.userId) % #DOT_COLORS) + 1], 0)
	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius, dotCorner.Parent = UDim.new(1, 0), dot
	Kit.Stroke(dot, if mine then Kit.Pink else Kit.Navy, if mine then 4 else 2.5, true)
	local initial = Kit.Body(dot, "Initial", string.upper(string.sub(row.name, 1, 1)), if mine then 20 else 14, Kit.White)
	initial.Size, initial.TextYAlignment = UDim2.fromScale(1, 1), Enum.TextYAlignment.Center
	local face = Instance.new("ImageLabel")
	face.Name, face.BackgroundTransparency, face.Size, face.Image = "Headshot", 1, UDim2.fromScale(1, 1), headshot(row.userId)
	local faceCorner = Instance.new("UICorner")
	faceCorner.CornerRadius, faceCorner.Parent = UDim.new(1, 0), face
	face.Parent = dot
	dot.ZIndex = if mine then 5 else 2
	for _, child in dot:GetDescendants() do if child:IsA("GuiObject") then child.ZIndex = dot.ZIndex end end
	hud.dots[row.userId] = dot
	return dot
end

local function setCrown(dot: Frame, on: boolean)
	local crown = dot:FindFirstChild("Crown")
	if on and not crown then
		local icon = Kit.Icon(dot, "Crown", Kit.Images.Crown, 22)
		icon.AnchorPoint, icon.Position, icon.Size, icon.ZIndex = Vector2.new(.5, 1), UDim2.new(.5, 0, 0, 4), UDim2.fromOffset(22, 18), dot.ZIndex
	elseif not on and crown then
		crown:Destroy()
	end
end

local function moveTo(item: GuiObject, position: UDim2, animate: boolean)
	if item.Position == position then return end
	if animate and Kit.Motion() then
		Kit.Tween(item, .7, {Position = position}, "Pop")
	else
		item.Position = position
	end
end

-- Draws every official racer's progress. `rows` come from RacePresentation.Standings.
function View.SetLadder(hud: any, rows: {any}, me: number, watched: number?, animate: boolean)
	local total = if rows[1] then rows[1].total else 1
	hud.me = me
	rebuildTicks(hud, total)
	local groups: {[number]: {any}} = {}
	local mySteps = 0
	for _, row in rows do
		local list = groups[row.steps]
		if not list then list = {}; groups[row.steps] = list end
		table.insert(list, row)
		if row.userId == me then mySteps = row.steps end
	end
	local present: {[number]: boolean} = {}
	local leader = rows[1]
	for steps, list in groups do
		table.sort(list, function(a, b)
			if a.userId == me then return true elseif b.userId == me then return false end
			return a.at < b.at
		end)
		local x = if list[1].userId == me then 104 else 46
		local shownOthers = 0
		local hidden = 0
		for _, row in list do
			local mine = row.userId == me
			local dot = hud.dots[row.userId] or makeDot(hud, row, mine)
			present[row.userId] = true
			local size = dot.Size.X.Offset
			if not mine and shownOthers >= MAX_PER_ROW then
				dot.Visible = false
				hidden += 1
			else
				dot.Visible = true
				local position = UDim2.fromOffset(if mine then 4 else x, levelY(steps, total) - size / 2)
				moveTo(dot, position, animate)
				if not mine then x += 17; shownOthers += 1 end
			end
			setCrown(dot, leader ~= nil and row.userId == leader.userId and (leader.steps > 0 or leader.finished))
			local edge = dot:FindFirstChildOfClass("UIStroke")
			if edge and not mine then
				edge.Color = if row.userId == watched then Kit.White else Kit.Navy
				edge.Thickness = if row.userId == watched then 4 else 2.5
			end
		end
		local more = hud.overflow[steps]
		if hidden > 0 then
			if not more then
				more = Kit.Chip(hud.dotsFolder, "More" .. steps, "", 12)
				hud.overflow[steps] = more
			end
			Kit.SetChip(more, "+" .. hidden)
			more.Position = UDim2.fromOffset(x + 14, levelY(steps, total) - 12)
		elseif more then
			more:Destroy()
			hud.overflow[steps] = nil
		end
	end
	for steps, more in hud.overflow do
		if not groups[steps] then more:Destroy(); hud.overflow[steps] = nil end
	end
	for userId, dot in hud.dots do
		if not present[userId] then dot:Destroy(); hud.dots[userId] = nil end
	end
	local mine = hud.dots[me]
	hud.youTag.Visible = mine ~= nil
	if mine then moveTo(hud.youTag, UDim2.fromOffset(50, levelY(mySteps, total) - 13), animate) end
	local fraction = mySteps / math.max(1, total)
	if animate and Kit.Motion() then
		Kit.Tween(hud.fill, .6, {Size = UDim2.fromScale(1, fraction)}, "Pop")
	else
		hud.fill.Size = UDim2.fromScale(1, fraction)
	end
	for _, tick in hud.ticks do
		local on = (tick:GetAttribute("Step") :: number) <= mySteps
		tick.BackgroundColor3 = if on then Kit.Pink else Kit.Navy
		tick.BackgroundTransparency = if on then 0 else .45
		local edge = tick:FindFirstChildOfClass("UIStroke")
		if edge then edge.Enabled = on end
	end
end

-- Ring burst at the player's new ladder level.
function View.LadderBurst(hud: any, steps: number, total: number)
	if not Kit.Motion() then return end
	local ring = Kit.Frame(hud.ladder, "Burst", UDim2.fromOffset(60, 60), UDim2.fromOffset(24, levelY(steps, total)))
	ring.AnchorPoint, ring.ZIndex = Vector2.new(.5, .5), 7
	local ringCorner = Instance.new("UICorner")
	ringCorner.CornerRadius, ringCorner.Parent = UDim.new(1, 0), ring
	local edge = Kit.Stroke(ring, Kit.Pink, 4, true)
	local scale = Kit.Scaler(ring)
	scale.Scale = .3
	Kit.Tween(scale, .65, {Scale = 1.8}, "Out")
	Kit.Tween(edge, .65, {Transparency = 1}, "Out")
	task.delay(.7, function() ring:Destroy() end)
	local mine = hud.dots[hud.me or 0]
	if mine then Kit.Punch(mine, 1.5, .5) end
end

return View
