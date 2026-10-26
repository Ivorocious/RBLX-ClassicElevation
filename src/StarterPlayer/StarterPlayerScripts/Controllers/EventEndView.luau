--!strict
-- Event end (brief "Event end"): race-winner columns with headshots, times and where you placed,
-- your totals, this visit's line, placeholder Overall champion and coins, Watch the finale and Back
-- to lobby. The finale itself is RaceFlowController's existing camera; no scoring is added here.
local Kit = require(script.Parent.UiKit)
local Presentation = require(script.Parent.RacePresentation)

local View = {}
local DESIGN = Vector2.new(1280, 720)
local COLUMN = Vector2.new(214, 300)

local function round(item: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), item
end

local function stat(parent: Instance, name: string, caption: string, x: number): Frame
	local box = Kit.Frame(parent, name, UDim2.fromOffset(150, 70), UDim2.fromOffset(x, 26))
	local label = Kit.SkyCaption(box, "Caption", caption, 13)
	label.Size, label.TextXAlignment = UDim2.new(1, 0, 0, 16), Enum.TextXAlignment.Left
	local value = Kit.SkyBig(box, "Value", "", 38)
	value.Position, value.Size = UDim2.fromOffset(0, 22), UDim2.new(1, 0, 0, 40)
	Kit.SetBigAlignment(value, Enum.TextXAlignment.Left)
	return box
end

local function placeholder(parent: Instance, name: string, caption: string, x: number): Frame
	local box = Kit.Frame(parent, name, UDim2.fromOffset(150, 72), UDim2.fromOffset(x, 30), Kit.White, .9)
	round(box, 10)
	local edge = Kit.Stroke(box, Kit.White, 2, true)
	edge.Transparency = .3
	local label = Kit.SkyCaption(box, "Caption", caption, 12)
	label.Position, label.Size = UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 14)
	-- Coin rewards and the overall scoring are not decided yet, so these read "Soon" rather than a bare "?".
	local value = Kit.SkyBig(box, "Value", "SOON", 30)
	value.Position, value.Size = UDim2.fromOffset(12, 28), UDim2.new(1, -24, 0, 32)
	return box
end

function View.Create(parent: Instance, activate: (string) -> (), close: () -> ()): any
	local root = Kit.Frame(parent, "EventEnd", UDim2.fromScale(1, 1), UDim2.new())
	root.Visible = false
	-- Same nearly solid backdrop as Results, so the lobby HUD never shows through behind the title.
	local shade = Kit.Frame(root, "Shade", UDim2.fromScale(1, 1), UDim2.new(), Kit.White, .08)
	shade.Active = true
	local backdrop = Instance.new("UIGradient")
	backdrop.Rotation, backdrop.Color = 90, ColorSequence.new(Color3.fromHex("1B3A9E"), Kit.Navy)
	backdrop.Parent = shade
	local stage = Kit.Frame(root, "Stage", UDim2.fromOffset(DESIGN.X, DESIGN.Y), UDim2.fromScale(.5, .5))
	stage.AnchorPoint = Vector2.new(.5, .5)
	local fit = Instance.new("UIScale")
	fit.Name, fit.Parent = "Fit", stage
	Kit.Rays(stage, 900, UDim2.fromOffset(640, 62), Kit.Sun, .72)
	local title = Kit.SkyPlate(stage, "Title", UDim2.fromOffset(600, 100), UDim2.fromOffset(340, 12), {fill = "Hero", class = "M", stripes = true})
	Kit.Sheen(title, 4.5)
	local titleContent = Kit.Content(title)
	local caption = Kit.SkyCaption(titleContent, "Caption", "", 14, true)
	caption.Position, caption.Size = UDim2.fromOffset(0, 16), UDim2.new(1, 0, 0, 16)
	local heading = Kit.SkyBig(titleContent, "Heading", "TOURNAMENT COMPLETE", 50)
	heading.Position, heading.Size = UDim2.fromOffset(30, 36), UDim2.new(1, -60, 0, 52)
	local columns = Kit.Frame(stage, "Races", UDim2.fromScale(1, 0), UDim2.fromOffset(0, 130))
	local strip = Kit.SkyPlate(stage, "Totals", UDim2.fromOffset(1060, 132), UDim2.fromOffset(110, 448), {class = "M", stripes = true})
	local content = Kit.Content(strip)
	local yours = Kit.SkyCaption(content, "Caption", "Your tournament", 14)
	yours.Position, yours.Size, yours.TextXAlignment = UDim2.fromOffset(56, 58), UDim2.fromOffset(150, 16), Enum.TextXAlignment.Left
	local best = stat(content, "Best", "Best place", 200)
	local finished = stat(content, "Finished", "Races finished", 345)
	placeholder(content, "Coins", "Coins earned", 490)
	placeholder(content, "Champion", "Overall champion", 652)
	-- Stacked with room for each button's outline and drop shadow inside the 132 px bar.
	local watch = Kit.SkyButton(content, "Finale", "Watch the finale", UDim2.fromOffset(200, 44), UDim2.fromOffset(832, 16), function() activate("Finale") end, "Primary", 18)
	local back = Kit.SkyButton(content, "Lobby", "Back to lobby", UDim2.fromOffset(200, 42), UDim2.fromOffset(832, 74), close, "Alt", 18)
	local visit = Kit.Chip(stage, "Visit", "", 17)
	visit.AnchorPoint, visit.Position = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, 600)
	local exit = Kit.SkyButton(parent, "ExitFinale", "Exit celebration", UDim2.fromOffset(230, 56), UDim2.new(.5, -115, 1, -84), function() activate("ExitFinale") end, "Light", 20)
	exit.Visible = false
	return {root = root, fit = fit, caption = caption, columns = columns, best = best, finished = finished, visit = visit,
		watch = watch, back = back, exit = exit, key = nil}
end

function View.Layout(view: any, size: Vector2, large: boolean)
	local fit = math.min(size.X / DESIGN.X, size.Y / DESIGN.Y)
	view.fit.Scale = math.min(math.clamp(fit, .42, 1.3) * (if large then 1.06 else 1), size.Y / DESIGN.Y)
end

local function column(parent: Instance, index: number, count: number, race: any, me: number)
	local x = (DESIGN.X - (count * COLUMN.X + (count - 1) * 14)) / 2 + (index - 1) * (COLUMN.X + 14)
	local mineWon = race.winnerUserId == me
	local plate = Kit.SkyPlate(parent, "Race" .. index, UDim2.fromOffset(COLUMN.X, COLUMN.Y), UDim2.fromOffset(x, 0), {class = "L", fill = if mineWon then "Hero" else "Sky"})
	local content = Kit.Content(plate)
	-- Course art over a flag stand-in for courses without artwork.
	local art = Kit.Frame(content, "Art", UDim2.fromOffset(150, 74), UDim2.fromOffset(32, 12), Kit.SkyDeep, 0)
	art.ClipsDescendants = true
	round(art, 8)
	Kit.Stroke(art, Kit.Navy, 3, true)
	local flag = Kit.Icon(art, "Fallback", Kit.Images.FinishFlag, 44, Kit.White)
	flag.AnchorPoint, flag.Position = Vector2.new(.5, .5), UDim2.fromScale(.5, .5)
	if race.image and race.image ~= "" then
		local picture = Instance.new("ImageLabel")
		picture.Name, picture.Image, picture.ScaleType, picture.BackgroundTransparency = "Picture", race.image, Enum.ScaleType.Crop, 1
		picture.Size = UDim2.fromScale(1, 1)
		round(picture, 8)
		picture.Parent = art
	end
	local caption = Kit.SkyCaption(content, "Caption", "Race " .. index .. " winner", 13, mineWon)
	caption.Position, caption.Size = UDim2.fromOffset(20, 96), UDim2.new(1, -30, 0, 16)
	local bust = Instance.new("ImageLabel")
	bust.Name, bust.BackgroundColor3 = "Headshot", Kit.Silver
	bust.Image = if race.winnerUserId and race.winnerUserId > 0 then string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", race.winnerUserId) else ""
	bust.Position, bust.Size = UDim2.fromOffset(75, 118), UDim2.fromOffset(64, 64)
	round(bust, 32)
	Kit.Stroke(bust, Kit.Navy, 3, true)
	bust.Parent = content
	local name = Kit.SkyBig(content, "Name", string.upper(if mineWon then "You" elseif race.winnerName then race.winnerName else "No finisher"), 24)
	name.Position, name.Size = UDim2.fromOffset(16, 190), UDim2.new(1, -30, 0, 26)
	Kit.FitBig(name, 24, COLUMN.X - 34)
	local time = Kit.Chip(content, "Time", if race.winnerTime then Presentation.Clock(race.winnerTime, 1) else "–", 14)
	time.AnchorPoint, time.Position = Vector2.new(.5, 0), UDim2.new(.5, -6, 0, 226)
	local you = Kit.Chip(content, "You", "You: " .. (race.mine or "–"), 14, if race.place == 1 then "Good" else nil)
	you.AnchorPoint, you.Position = Vector2.new(.5, 0), UDim2.new(.5, -10, 0, 258)
	if Kit.Motion() then
		plate.Position = UDim2.fromOffset(x, 320)
		Kit.Tween(plate, .56, {Position = UDim2.fromOffset(x, 0)}, "Pop", .15 + index * .09)
	end
end

-- info: {key, raceCount, races = {{image, winnerName, winnerUserId, winnerTime, mine}}, best, finished, visit}
function View.Set(view: any, info: any?, me: number)
	local shown = info ~= nil
	if not shown then
		view.root.Visible = false
		view.key = nil
		return
	end
	if view.key ~= info.key then
		view.key = info.key
		view.columns:ClearAllChildren()
		for index, race in info.races do column(view.columns, index, #info.races, race, me) end
		Kit.Play("Fanfare")
	end
	view.caption.Text = string.upper("Grand Arcade · " .. info.raceCount .. " races")
	Kit.SetBig(view.best.Value, if info.best then info.best .. Presentation.Ordinal(info.best) else "–")
	Kit.SetBig(view.finished.Value, info.finished .. "/" .. info.raceCount)
	view.visit.Visible = info.visit ~= nil
	if info.visit then Kit.SetChip(view.visit, info.visit) end
	if not view.root.Visible then
		view.root.Visible = true
		-- Pop the title, not the stage: the stage's own UIScale is its layout scale.
		Kit.Punch(view.root.Stage.Title, .7, .5)
		task.delay(.25, function() if view.root.Visible then Kit.Confetti(view.root, 90) end end)
	end
end

function View.SetFinale(view: any, active: boolean)
	view.exit.Visible = active
end

return View
