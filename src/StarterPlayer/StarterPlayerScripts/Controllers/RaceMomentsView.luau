--!strict
-- Race moments (brief "Countdown", "Checkpoint", "Finish" and the Still racing? sticker): short
-- animated beats that use the middle of the screen for about a second, then get out of the way.
local RunService = game:GetService("RunService")
local Kit = require(script.Parent.UiKit)
local Presentation = require(script.Parent.RacePresentation)

local View = {}
local DESIGN = Vector2.new(1280, 720)
local CONFETTI = {Kit.Sun, Kit.Pink, Kit.Sky, Kit.Mint, Kit.White}

local function centerFrame(parent: Instance, name: string, size: Vector2, y: number): Frame
	local item = Kit.Frame(parent, name, UDim2.fromOffset(size.X, size.Y), UDim2.new(.5, 0, 0, y))
	item.AnchorPoint = Vector2.new(.5, 0)
	return item
end

-- `back` and `front` are full-screen layers (no safe-area insets) under and over the moments.
function View.Create(container: Instance, back: Instance, front: Instance): any
	local canvas = Kit.Frame(container, "RaceMomentsCanvas", UDim2.fromScale(1, 1), UDim2.new())
	-- Everything is authored at 1280 x 720 inside one scaled stage centred on the screen.
	local stage = Kit.Frame(canvas, "Stage", UDim2.fromOffset(DESIGN.X, DESIGN.Y), UDim2.fromScale(.5, .5))
	stage.AnchorPoint = Vector2.new(.5, .5)
	local fit = Instance.new("UIScale")
	fit.Name, fit.Parent = "Fit", stage
	local moments: any = {canvas = canvas, stage = stage, fit = fit, countSerial = 0, finishSerial = 0}
	moments.shade = Kit.Frame(back, "Shade", UDim2.fromScale(1, 1), UDim2.new(), Kit.Navy, 1)
	moments.confetti = Kit.Frame(front, "Confetti", UDim2.fromScale(1, 1), UDim2.new())
	moments.confetti.ClipsDescendants = true
	moments.flash = Kit.Frame(front, "Flash", UDim2.fromScale(1, 1), UDim2.new(), Kit.White, 1)
	return moments
end

function View.Layout(moments: any, size: Vector2, largeText: boolean)
	local fit = math.min(size.X / DESIGN.X, size.Y / DESIGN.Y)
	local compact = size.Y < 520
	moments.compact = compact
	-- The stage never grows taller than the screen, so top and bottom beats stay visible.
	moments.fit.Scale = math.min(math.clamp(if compact then fit * 1.08 else fit, .42, 1.3) * (if largeText then 1.08 else 1), size.Y / DESIGN.Y)
end

local function clear(moments: any, name: string)
	local existing = moments.stage:FindFirstChild(name)
	if existing then existing:Destroy() end
end

function View.Confetti(moments: any, count: number)
	if not Kit.Motion() then return end
	local layer = moments.confetti
	local width, height = layer.AbsoluteSize.X, layer.AbsoluteSize.Y
	local scale = moments.fit.Scale
	for index = 1, count do
		local piece = Kit.Frame(layer, "Piece", UDim2.fromOffset(12 * scale, 18 * scale),
			UDim2.fromOffset(width * (.08 + math.random() * .84), -30 * scale), CONFETTI[(index % #CONFETTI) + 1], 0)
		local pieceCorner = Instance.new("UICorner")
		pieceCorner.CornerRadius, pieceCorner.Parent = UDim.new(0, 3), piece
		local edge = Kit.Stroke(piece, Kit.Navy, 2, true)
		edge.Transparency = .4
		local seconds = 1.8 + math.random() * 1.6
		local drift = (math.random() - .5) * 260 * scale
		Kit.Tween(piece, seconds, {
			Position = piece.Position + UDim2.fromOffset(drift, height + 60),
			Rotation = (math.random() - .5) * 900,
		}, "Out", math.random() * .5)
		task.delay(seconds + .6, function() piece:Destroy() end)
	end
end

-- 3, 2, 1, GO! timed to the server's countdown end. `card` is {title, caption, line, image}.
function View.Countdown(moments: any, card: any, endsAt: number, duration: number, now: () -> number, onGo: () -> ())
	moments.countSerial += 1
	local serial = moments.countSerial
	clear(moments, "CourseCard"); clear(moments, "Count")
	local plate = Kit.Plate(moments.stage, "CourseCard", UDim2.fromOffset(600, 128), UDim2.fromOffset(40, 556))
	local content = Kit.Content(plate)
	local art = Instance.new("ImageLabel")
	art.Name, art.Size, art.Position, art.BackgroundColor3 = "Art", UDim2.fromOffset(170, 100), UDim2.fromOffset(14, 14), Kit.Sky
	art.Image, art.ScaleType = card.image or "", Enum.ScaleType.Crop
	local artCorner = Instance.new("UICorner")
	artCorner.CornerRadius, artCorner.Parent = UDim.new(0, 6), art
	Kit.Stroke(art, Kit.Navy, 3.5, true)
	art.Parent = content
	if (card.image or "") == "" then
		local flag = Kit.Icon(art, "Flag", Kit.Images.FinishFlag, 64)
		flag.AnchorPoint, flag.Position = Vector2.new(.5, .5), UDim2.fromScale(.5, .5)
	end
	local caption = Kit.Caption(content, "Caption", card.caption or "Get ready", 13)
	caption.Position, caption.Size, caption.TextXAlignment = UDim2.fromOffset(202, 20), UDim2.fromOffset(380, 16), Enum.TextXAlignment.Left
	local title = Kit.Title(content, "Title", string.upper(card.title or ""), 50)
	title.Position, title.Size = UDim2.fromOffset(202, 40), UDim2.fromOffset(380, 50)
	for _, label in Kit.BigLabels(title) do label.TextXAlignment, label.TextScaled = Enum.TextXAlignment.Left, false; label.TextTruncate = Enum.TextTruncate.AtEnd end
	Kit.FitBig(title, 50, 372)
	local line = Kit.Body(content, "Line", card.line or "", 15)
	line.Position, line.Size, line.TextXAlignment = UDim2.fromOffset(202, 94), UDim2.fromOffset(380, 18), Enum.TextXAlignment.Left
	-- Phones keep the bottom corners for the thumbstick and jump button, so the card sits on top.
	local home = if moments.compact then UDim2.fromOffset(340, 24) else UDim2.fromOffset(40, 556)
	local away = home - UDim2.fromOffset(740, 0)
	plate.Position = away
	Kit.Tween(plate, .65, {Position = home}, "Pop")

	local count = Kit.Frame(moments.stage, "Count", UDim2.fromOffset(DESIGN.X, 320), UDim2.fromOffset(0, 170))
	local ring = Kit.Frame(count, "Shock", UDim2.fromOffset(300, 300), UDim2.fromScale(.5, .5))
	ring.AnchorPoint, ring.Visible = Vector2.new(.5, .5), false
	local ringCorner = Instance.new("UICorner")
	ringCorner.CornerRadius, ringCorner.Parent = UDim.new(1, 0), ring
	local ringEdge = Kit.Stroke(ring, Kit.White, 10, true)
	-- One beat per second of the server's countdown, then GO! at its end.
	local beats = {}
	local colors = {Kit.Sky, Kit.Sun, Kit.Pink}
	local seconds = math.max(1, math.floor(duration + .5))
	for second = seconds, 1, -1 do
		table.insert(beats, {at = endsAt - second, text = tostring(second), color = colors[((second - 1) % 3) + 1], pitch = 1 + (seconds - second) * .06})
	end
	table.insert(beats, {at = endsAt, text = "GO!", color = Kit.Mint, go = true, pitch = 1.35})
	local function beat(entry: any)
		if moments.countSerial ~= serial then return end
		local old = count:FindFirstChild("Number")
		if old then old:Destroy() end
		local size = if entry.go then 290 else 250
		local number = Kit.Big(count, "Number", entry.text, size, {fill = entry.color, outline = 10, shadow = 10})
		number.AnchorPoint, number.Position, number.Size = Vector2.new(.5, .5), UDim2.fromScale(.5, .5), UDim2.fromOffset(DESIGN.X, size)
		Kit.Play(if entry.go then "Go" else "Beep", entry.pitch)
		if Kit.Frozen then return end
		if not Kit.Motion() then
			Kit.FadeTree(number, false, 0); Kit.FadeTree(number, true, .2)
			task.delay(.85, function() if number.Parent then Kit.FadeTree(number, false, .2) end end)
			if entry.go then onGo() end
			return
		end
		local scale = Kit.Scaler(number)
		scale.Scale, number.Rotation = 2.6, -14
		Kit.Tween(scale, .33, {Scale = .9}, "Out")
		Kit.Tween(number, .33, {Rotation = 3}, "Out")
		task.delay(.33, function()
			if not number.Parent then return end
			Kit.Tween(scale, .15, {Scale = 1}, "Out"); Kit.Tween(number, .15, {Rotation = 0}, "Out")
		end)
		task.delay(if entry.go then .9 else .78, function()
			if not number.Parent then return end
			Kit.Tween(scale, .2, {Scale = if entry.go then 1.5 else .6}, "In")
			Kit.FadeTree(number, false, .2)
		end)
		ring.Visible, ring.Size, ringEdge.Transparency = true, UDim2.fromOffset(90, 90), 0
		Kit.Tween(ring, .65, {Size = UDim2.fromOffset(780, 780)}, "Out")
		Kit.Tween(ringEdge, .65, {Transparency = 1}, "Out")
		if entry.go then
			moments.flash.BackgroundTransparency = 1
			Kit.Tween(moments.flash, .14, {BackgroundTransparency = .55}, "Out")
			task.delay(.14, function() Kit.Tween(moments.flash, .55, {BackgroundTransparency = 1}, "Out") end)
			local speed = Kit.Icon(count, "Speed", Kit.Images.Rays, 900, Kit.White)
			speed.AnchorPoint, speed.Position, speed.ImageTransparency = Vector2.new(.5, .5), UDim2.fromScale(.5, .5), .35
			Kit.Tween(speed, 1, {Size = UDim2.fromOffset(1900, 1900), ImageTransparency = 1}, "Out")
			task.delay(1.05, function() speed:Destroy() end)
			onGo()
		end
	end
	for _, entry in beats do
		local delay = entry.at - now()
		if Kit.Frozen and delay > .05 then continue end
		if entry.go or delay > -.5 then
			task.delay(math.max(0, delay), beat, entry)
		end
	end
	if Kit.Frozen then return end
	task.delay(math.max(0, endsAt - now()) + .9, function()
		if moments.countSerial ~= serial or not plate.Parent then return end
		Kit.Tween(plate, .42, {Position = away}, "In")
		task.delay(.45, function() plate:Destroy() end)
	end)
	task.delay(math.max(0, endsAt - now()) + 1.4, function() if count.Parent then count:Destroy() end end)
end

function View.CancelCountdown(moments: any)
	moments.countSerial += 1
	clear(moments, "CourseCard"); clear(moments, "Count")
end

-- Checkpoint ribbon: number and split, gap to your best only when the server sends it.
function View.Ribbon(moments: any, moment: any)
	clear(moments, "Ribbon")
	local ribbon = Kit.Plate(moments.stage, "Ribbon", UDim2.fromOffset(520, 104), UDim2.fromOffset(380, 150), {hero = true})
	local content = Kit.Content(ribbon)
	local caption = Kit.Caption(content, "Caption", if moment.final then "Last checkpoint"
		elseif moment.laps > 1 then "Lap " .. moment.lap .. " · checkpoint" else "Checkpoint", 13)
	if moment.final then
		caption.Position, caption.Size = UDim2.fromOffset(0, 16), UDim2.new(1, 0, 0, 16)
		local big = Kit.Big(content, "Number", "FINAL STRETCH", 52)
		big.Position = UDim2.fromOffset(0, 36)
	else
		caption.Position, caption.Size, caption.TextXAlignment = UDim2.fromOffset(30, 18), UDim2.fromOffset(200, 16), Enum.TextXAlignment.Left
		local number = Kit.Big(content, "Number", moment.checkpoint .. "/" .. moment.count, 58)
		number.Position, number.Size = UDim2.fromOffset(30, 36), UDim2.fromOffset(200, 58)
		Kit.SetBigAlignment(number, Enum.TextXAlignment.Left)
		local divider = Kit.Frame(content, "Divider", UDim2.fromOffset(3, 64), UDim2.fromOffset(262, 20), Kit.Navy, .75)
		divider.Name = "Divider"
		local split = Kit.Big(content, "Split", Presentation.Clock(moment.split, 1), if moment.delta then 34 else 44)
		split.Position, split.Size = UDim2.fromOffset(290, if moment.delta then 18 else 40), UDim2.fromOffset(210, if moment.delta then 34 else 44)
		Kit.SetBigAlignment(split, Enum.TextXAlignment.Left)
		if not moment.delta then
			-- Caption over value, mirroring the checkpoint half.
			local label = Kit.Caption(content, "SplitCaption", "Time", 13)
			label.Position, label.Size, label.TextXAlignment = UDim2.fromOffset(290, 18), UDim2.fromOffset(200, 16), Enum.TextXAlignment.Left
		else
			local better = moment.delta < 0
			local chip = Kit.Chip(content, "Delta", string.format("%s%.1fs vs your best", if better then "-" else "+", math.abs(moment.delta)), 16, if better then "Good" else "Bad")
			chip.Position = UDim2.fromOffset(290, 60)
		end
	end
	Kit.Play("Checkpoint", 1 + .45 * math.clamp(((moment.lap - 1) * moment.count + moment.checkpoint) / math.max(1, moment.count * moment.laps), 0, 1))
	if Kit.Motion() then
		ribbon.Position = UDim2.fromOffset(200, 150)
		Kit.Tween(ribbon, .52, {Position = UDim2.fromOffset(380, 150)}, "Pop")
	end
	if Kit.Frozen then return end
	task.delay(2.1, function()
		if not ribbon.Parent then return end
		Kit.Tween(ribbon, .38, {Position = UDim2.fromOffset(580, 150)}, "In")
		Kit.FadeTree(ribbon, false, .38)
		task.delay(.4, function() ribbon:Destroy() end)
	end)
end

-- Pink "Still racing?" sticker with a draining bar; `fraction` 1 → 0 until the break.
function View.SetIdle(moments: any, visible: boolean, fraction: number?, keepRacing: (() -> ())?)
	local sticker = moments.stage:FindFirstChild("Idle")
	if not visible then
		if sticker and sticker:GetAttribute("Leaving") ~= true then
			sticker:SetAttribute("Leaving", true)
			Kit.FadeTree(sticker, false, .25)
			task.delay(.3, function() sticker:Destroy() end)
		end
		return
	end
	if not sticker or sticker:GetAttribute("Leaving") == true then
		if sticker then sticker:Destroy() end
		sticker = Kit.Plate(moments.stage, "Idle", UDim2.fromOffset(600, 136), UDim2.fromOffset(340, 150), {fill = Kit.PinkPale, dots = true, tilt = 1.2})
		local content = Kit.Content(sticker :: Frame)
		local title = Kit.Title(content, "Title", "STILL RACING?", 42)
		title.Position, title.Size = UDim2.fromOffset(28, 22), UDim2.fromOffset(330, 42)
		Kit.SetBigAlignment(title, Enum.TextXAlignment.Left)
		local line = Kit.Body(content, "Line", "Move or press Keep racing to stay in this race", 15, Kit.Navy)
		line.Position, line.Size, line.TextXAlignment = UDim2.fromOffset(28, 72), UDim2.fromOffset(340, 18), Enum.TextXAlignment.Left
		local bar = Kit.Frame(content, "Bar", UDim2.fromOffset(260, 14), UDim2.fromOffset(28, 100), Kit.White, 0)
		local barCorner = Instance.new("UICorner")
		barCorner.CornerRadius, barCorner.Parent = UDim.new(1, 0), bar
		Kit.Stroke(bar, Kit.Navy, 2.5, true)
		local drain = Kit.Frame(bar, "Drain", UDim2.fromScale(1, 1), UDim2.new(), Kit.Sun, 0)
		local drainCorner = Instance.new("UICorner")
		drainCorner.CornerRadius, drainCorner.Parent = UDim.new(1, 0), drain
		-- At least 46 screen pixels tall on phones, where the stage is scaled down.
		local height = math.max(56, 46 / math.max(moments.fit.Scale, .01))
		local button: TextButton
		button = Kit.Button(content, "KeepRacing", "Keep racing", UDim2.fromOffset(170, height), UDim2.fromOffset(402, (136 - height) / 2), function()
			if keepRacing then keepRacing() end
			-- The sticker goes away when the server clears the warning; until then show it was heard.
			button:SetAttribute("Available", false)
			Kit.SetButtonText(button, "One moment…")
			task.delay(6, function()
				if button.Parent then button:SetAttribute("Available", true); Kit.SetButtonText(button, "Keep racing") end
			end)
		end, true, 19)
		button.Name = "KeepRacing"
		Kit.Play("Alert")
		if Kit.Motion() then
			local scale = Kit.Scaler(sticker :: Frame)
			scale.Scale = .4
			Kit.Tween(scale, .56, {Scale = 1}, "Pop")
		end
	end
	local drain = (sticker :: Frame):FindFirstChild("Drain", true) :: Frame?
	if drain and fraction then drain.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1) end
end

function View.IdleButton(moments: any): GuiObject?
	local sticker = moments.stage:FindFirstChild("Idle")
	return if sticker then sticker:FindFirstChild("KeepRacing", true) :: GuiObject? else nil
end

-- Place burst with rays, time count-up and badges, then a compact plate at the top.
function View.Finish(moments: any, data: any, onSettled: () -> ())
	moments.finishSerial += 1
	local serial = moments.finishSerial
	View.ClearFinish(moments)
	local stage = moments.stage
	local rays = Kit.Icon(stage, "Rays", Kit.Images.Rays, 1400, Kit.Sun)
	rays.AnchorPoint, rays.Position, rays.ImageTransparency, rays.ZIndex = Vector2.new(.5, .5), UDim2.fromOffset(640, 300), 1, 1
	Kit.Tween(rays, .6, {ImageTransparency = .3}, "Out")
	if Kit.Motion() then
		local spin = RunService.RenderStepped:Connect(function(dt) rays.Rotation = (rays.Rotation + dt * 22.5) % 360 end)
		rays.Destroying:Connect(function() spin:Disconnect() end)
	end
	local burst = Kit.Frame(stage, "FinishBurst", UDim2.fromOffset(DESIGN.X, 460), UDim2.fromOffset(0, 120))
	burst.ZIndex = 3
	local caption = Kit.Caption(burst, "Caption", "You finished", 20, Kit.White)
	caption.Size = UDim2.new(1, 0, 0, 22)
	Kit.Stroke(caption, Kit.Navy, 4, false)
	local placeRow = Kit.Frame(burst, "Place", UDim2.fromOffset(0, 210), UDim2.new(.5, 0, 0, 30))
	placeRow.AnchorPoint, placeRow.AutomaticSize = Vector2.new(.5, 0), Enum.AutomaticSize.X
	local list = Instance.new("UIListLayout")
	list.FillDirection, list.VerticalAlignment, list.Padding = Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Bottom, UDim.new(0, 6)
	list.SortOrder, list.Parent = Enum.SortOrder.LayoutOrder, placeRow
	local number = Kit.Big(placeRow, "Number", tostring(data.placement or "–"), 210, {fill = Kit.Sun, outline = 10, shadow = 9, auto = true})
	number.LayoutOrder = 1
	local suffixWrap = Kit.Frame(placeRow, "SuffixWrap", UDim2.fromOffset(0, 112), UDim2.new())
	suffixWrap.AutomaticSize, suffixWrap.LayoutOrder = Enum.AutomaticSize.X, 2
	Kit.Big(suffixWrap, "Suffix", if data.placement then Presentation.Ordinal(data.placement) else "", 84, {fill = Kit.Sun, outline = 7, shadow = 7, auto = true})
	local time = Kit.Big(burst, "Time", Presentation.Clock(0, 2), 72)
	time.Position = UDim2.fromOffset(0, 250)
	local chips = Kit.Frame(burst, "Chips", UDim2.fromOffset(0, 36), UDim2.new(.5, 0, 0, 340))
	chips.AnchorPoint, chips.AutomaticSize = Vector2.new(.5, 0), Enum.AutomaticSize.X
	local chipList = Instance.new("UIListLayout")
	chipList.FillDirection, chipList.Padding, chipList.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 12), Enum.SortOrder.LayoutOrder
	chipList.Parent = chips
	local badges = {}
	if data.improvement then table.insert(badges, Kit.Chip(chips, "Best", string.format("Fastest this visit · -%.1fs", data.improvement), 20, "Good")) end
	if typeof(data.falls) == "number" then
		table.insert(badges, Kit.Chip(chips, "Falls", data.falls .. (if data.falls == 1 then " fall" else " falls"), 20))
	end
	for index, chip in badges do chip.LayoutOrder = index; chip.Visible = false end
	Kit.Play("Fanfare")
	Kit.Punch(placeRow, 3.2, .7, .12)
	if Kit.Motion() then
		placeRow.Rotation = -10
		Kit.Tween(placeRow, .7, {Rotation = 0}, "Pop", .12)
	end
	task.delay(.15, function() if moments.finishSerial == serial then View.Confetti(moments, 60) end end)
	local target = if typeof(data.finishTime) == "number" then data.finishTime else 0
	if not Kit.Motion() then Kit.SetBig(time, Presentation.Clock(target, 2)) end
	task.delay(.45, function()
		local started = os.clock()
		local seconds = if Kit.Motion() then .9 else 0
		while moments.finishSerial == serial and time.Parent do
			local k = if seconds <= 0 then 1 else math.clamp((os.clock() - started) / seconds, 0, 1)
			Kit.SetBig(time, Presentation.Clock(target * (1 - (1 - k) ^ 3), 2))
			if k >= 1 then break end
			RunService.RenderStepped:Wait()
		end
	end)
	for index, chip in badges do
		task.delay(if Kit.Frozen then 0 else 1.35 + (index - 1) * .15, function()
			if moments.finishSerial ~= serial or not chip.Parent then return end
			chip.Visible = true
			Kit.Punch(chip, .01, .48)
		end)
	end
	if Kit.Frozen then return end
	task.delay(2.9, function()
		if moments.finishSerial ~= serial then return end
		Kit.Tween(burst, .45, {Position = UDim2.fromOffset(0, -40)}, "In")
		Kit.FadeTree(burst, false, .45)
		Kit.Tween(rays, .45, {ImageTransparency = 1}, "In")
		task.delay(.5, function() burst:Destroy(); rays:Destroy() end)
		View.MiniFinish(moments, data, true)
		onSettled()
	end)
end

-- Compact "FINISHED 2ND 1:42.38" plate shown above the finish ticket.
function View.MiniFinish(moments: any, data: any, animate: boolean)
	clear(moments, "MiniFinish")
	local mini = Kit.Plate(moments.stage, "MiniFinish", UDim2.fromOffset(340, 84), UDim2.fromOffset(470, 16), {hero = true})
	local row = Kit.Frame(Kit.Content(mini), "Row", UDim2.fromScale(1, 1), UDim2.new())
	local list = Instance.new("UIListLayout")
	list.FillDirection, list.HorizontalAlignment, list.VerticalAlignment = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center
	list.Padding, list.SortOrder, list.Parent = UDim.new(0, 14), Enum.SortOrder.LayoutOrder, row
	local caption = Kit.Caption(row, "Caption", "Finished", 13)
	caption.AutomaticSize, caption.Size, caption.LayoutOrder = Enum.AutomaticSize.X, UDim2.fromOffset(0, 16), 1
	local place = Kit.Big(row, "Place", if data.placement then data.placement .. Presentation.Ordinal(data.placement) else "–", 44, {auto = true})
	place.LayoutOrder = 2
	local time = Kit.Big(row, "Time", Presentation.Clock(data.finishTime, 2), 30, {auto = true})
	time.LayoutOrder = 3
	if animate and Kit.Motion() then
		mini.Position = UDim2.fromOffset(470, -110)
		Kit.Tween(mini, .55, {Position = UDim2.fromOffset(470, 16)}, "Pop", .25)
	end
end

-- "Time's up / Run unfinished" with checkpoints reached, then out of the way for the ticket.
function View.Unfinished(moments: any, data: any, onSettled: () -> ())
	moments.finishSerial += 1
	local serial = moments.finishSerial
	View.ClearFinish(moments)
	moments.shade.BackgroundTransparency = 1
	Kit.Tween(moments.shade, .4, {BackgroundTransparency = .55}, "Out")
	local box = Kit.Frame(moments.stage, "Unfinished", UDim2.fromOffset(DESIGN.X, 240), UDim2.fromOffset(0, 150))
	local caption = Kit.Caption(box, "Caption", data.caption or "Time's up", 20, Kit.White)
	caption.Size = UDim2.new(1, 0, 0, 22)
	Kit.Stroke(caption, Kit.Navy, 4, false)
	local big = Kit.Big(box, "Big", "RUN UNFINISHED", 104, {outline = 7, shadow = 7})
	big.Position, big.Rotation = UDim2.fromOffset(0, 36), -4
	local chip = Kit.Chip(box, "Reached", data.reached or "", 20)
	chip.AnchorPoint, chip.Position, chip.Visible = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, 170), (data.reached or "") ~= ""
	Kit.Play("Sting")
	Kit.Punch(big, 2.4, .64)
	Kit.Punch(chip, .01, .46, .7)
	if Kit.Frozen then return end
	task.delay(1.9, function()
		if moments.finishSerial ~= serial then return end
		Kit.Tween(box, .42, {Position = UDim2.fromOffset(0, 30)}, "In")
		Kit.FadeTree(box, false, .42)
		Kit.Tween(moments.shade, .42, {BackgroundTransparency = 1}, "In")
		task.delay(.45, function() box:Destroy() end)
		onSettled()
	end)
end

function View.ClearFinish(moments: any)
	for _, name in {"Rays", "FinishBurst", "MiniFinish", "Unfinished"} do clear(moments, name) end
	moments.shade.BackgroundTransparency = 1
end

function View.HasMini(moments: any): boolean
	return moments.stage:FindFirstChild("MiniFinish") ~= nil
end

function View.HideMini(moments: any)
	local mini = moments.stage:FindFirstChild("MiniFinish")
	if not mini or mini:GetAttribute("Leaving") == true then return end
	mini:SetAttribute("Leaving", true)
	Kit.FadeTree(mini, false, .3)
	task.delay(.32, function() mini:Destroy() end)
end

return View
