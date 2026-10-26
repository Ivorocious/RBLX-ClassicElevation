--!strict
-- Watching (brief "Watching"): a yellow banner with the watched racer's headshot, place and
-- checkpoint, big Previous/Next arrows, Exit watching, a name tag over the racer and a chip counting
-- down to results. SpectateController keeps the camera lease and target choice.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local Kit = require(script.Parent.UiKit)
local Presentation = require(script.Parent.RacePresentation)

local View = {}
local DESIGN = Vector2.new(1280, 720)
local BINDING = "WatchCycle"

local function round(item: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), item
end

function View.Create(container: Instance, activate: (string) -> ()): any
	local stage = Kit.Frame(container, "WatchStage", UDim2.fromOffset(DESIGN.X, DESIGN.Y), UDim2.fromScale(.5, .5))
	stage.AnchorPoint, stage.Visible = Vector2.new(.5, .5), false
	local fit = Instance.new("UIScale")
	fit.Name, fit.Parent = "Fit", stage
	local banner = Kit.Plate(stage, "Banner", UDim2.fromOffset(470, 104), UDim2.fromOffset(405, 14), {hero = true})
	local content = Kit.Content(banner)
	local bust = Instance.new("ImageLabel")
	bust.Name, bust.Size, bust.Position, bust.BackgroundColor3 = "Headshot", UDim2.fromOffset(78, 78), UDim2.fromOffset(18, 15), Kit.Silver
	round(bust, 39)
	Kit.Stroke(bust, Kit.Navy, 3.5, true)
	bust.Parent = content
	local caption = Kit.Caption(content, "Caption", "Watching", 13)
	caption.Position, caption.Size, caption.TextXAlignment = UDim2.fromOffset(110, 20), UDim2.fromOffset(240, 16), Enum.TextXAlignment.Left
	local name = Kit.Title(content, "Name", "", 40)
	-- Up to the right-aligned place ("2ND" leaves about 100 px at the end), so 20-character names fit.
	name.Position, name.Size = UDim2.fromOffset(110, 40), UDim2.fromOffset(236, 44)
	Kit.SetBigAlignment(name, Enum.TextXAlignment.Left)
	local place = Kit.Big(content, "Place", "", 46)
	place.Position, place.Size = UDim2.fromOffset(310, 16), UDim2.fromOffset(140, 48)
	Kit.SetBigAlignment(place, Enum.TextXAlignment.Right)
	local checkpoint = Kit.Caption(content, "Checkpoint", "", 13)
	checkpoint.Position, checkpoint.Size, checkpoint.TextXAlignment = UDim2.fromOffset(250, 70), UDim2.fromOffset(200, 16), Enum.TextXAlignment.Right
	local previous = Kit.Button(stage, "Previous", "", UDim2.fromOffset(84, 84), UDim2.fromOffset(40, 318), function() activate("Previous") end, true, 20)
	local nextButton = Kit.Button(stage, "Next", "", UDim2.fromOffset(84, 84), UDim2.fromOffset(1156, 318), function() activate("Next") end, true, 20)
	-- A thick navy chevron drawn from two bars (points left on Previous, right on Next).
	for _, button in {previous, nextButton} do
		local direction = if button == previous then -1 else 1
		for _, sign in {-1, 1} do
			-- Upper bar (sign -1) leans "\" and lower "/" for a right-pointing ">"; Previous mirrors it.
			local bar = Kit.Frame(button:FindFirstChild("Body") :: Instance, "Arrow", UDim2.fromOffset(34, 11), UDim2.new(.5, direction * 2, .5, sign * 10), Kit.Navy, 0)
			bar.AnchorPoint, bar.Rotation, bar.ZIndex = Vector2.new(.5, .5), -sign * direction * 45, 6
			local round = Instance.new("UICorner")
			round.CornerRadius, round.Parent = UDim.new(1, 0), bar
		end
	end
	local exit = Kit.Button(stage, "StopWatching", "Exit watching", UDim2.fromOffset(240, 58), UDim2.fromOffset(520, 640), function() activate("StopWatching") end, false, 21)
	local results = Kit.Chip(stage, "ResultsIn", "", 17)
	results.AnchorPoint, results.Position = Vector2.new(.5, 1), UDim2.new(.5, 0, 0, 626)
	local tag = Instance.new("BillboardGui")
	tag.Name, tag.Size, tag.StudsOffset, tag.AlwaysOnTop, tag.LightInfluence = "WatchTag", UDim2.fromOffset(220, 64), Vector3.new(0, 4.2, 0), true, 0
	tag.ResetOnSpawn, tag.MaxDistance = false, 400
	local tagChip = Kit.Chip(tag, "Name", "", 20)
	tagChip.AnchorPoint, tagChip.Position = Vector2.new(.5, 0), UDim2.fromScale(.5, 0)
	local arrow = Kit.Icon(tag, "Arrow", Kit.Images.FallArrow, 24, Kit.Sun)
	arrow.AnchorPoint, arrow.Position = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, 36)
	tag.Parent = container
	return {stage = stage, fit = fit, banner = banner, bust = bust, name = name, place = place, checkpoint = checkpoint,
		previous = previous, next = nextButton, exit = exit, results = results, tag = tag, tagChip = tagChip, activate = activate,
		shown = false, userId = nil}
end

function View.Layout(view: any, size: Vector2, large: boolean)
	local fit = math.min(size.X / DESIGN.X, size.Y / DESIGN.Y)
	view.fit.Scale = math.min(math.clamp(fit, .42, 1.3) * (if large then 1.08 else 1), size.Y / DESIGN.Y)
end

local function bind(view: any, on: boolean)
	ContextActionService:UnbindAction(BINDING)
	if not on then return end
	-- Controller shoulder buttons cycle racers and B exits, like the old panel's navigation.
	ContextActionService:BindActionAtPriority(BINDING, function(_, state, input)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if input.KeyCode == Enum.KeyCode.ButtonL1 then view.activate("Previous")
		elseif input.KeyCode == Enum.KeyCode.ButtonR1 then view.activate("Next")
		elseif input.KeyCode == Enum.KeyCode.ButtonB then view.activate("StopWatching") end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonB)
end

-- info: {userId, name, loading, place, total, checkpoint, checkpoints, remaining} or nil to hide.
function View.Set(view: any, info: any?)
	local shown = info ~= nil
	if shown ~= view.shown then
		view.shown = shown
		view.stage.Visible = shown
		bind(view, shown)
		if shown and Kit.Motion() then
			view.banner.Position = UDim2.fromOffset(405, -140)
			Kit.Tween(view.banner, .6, {Position = UDim2.fromOffset(405, 14)}, "Pop")
			Kit.Punch(view.previous, .01, .42, .4)
			Kit.Punch(view.next, .01, .42, .48)
			view.exit.Position = UDim2.fromOffset(520, 760)
			Kit.Tween(view.exit, .52, {Position = UDim2.fromOffset(520, 640)}, "Pop", .3)
		end
	end
	if not info then
		view.tag.Adornee, view.tag.Enabled, view.userId = nil, false, nil
		return
	end
	local userId = if info.loading then nil else info.userId
	if userId ~= view.userId then
		view.userId = userId
		view.bust.Image = if userId and userId > 0 then string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId) else ""
		if userId then Kit.Punch(view.banner, .9, .35); Kit.Play("Whoosh") end
	end
	Kit.SetBig(view.name, string.upper(if info.loading then "Finding a racer…" else tostring(info.name or "Racer")))
	Kit.FitBig(view.name, 40, 220)
	view.place.Visible = not info.loading and typeof(info.place) == "number"
	if typeof(info.place) == "number" then Kit.SetBig(view.place, tostring(info.place) .. string.upper(Presentation.Ordinal(info.place))) end
	view.checkpoint.Text = if not info.loading and typeof(info.checkpoint) == "number" and typeof(info.checkpoints) == "number"
		then string.upper(string.format("Checkpoint %d of %d", info.checkpoint, info.checkpoints)) else ""
	view.results.Visible = typeof(info.remaining) == "number"
	if typeof(info.remaining) == "number" then Kit.SetChip(view.results, "Results when the race ends · " .. Presentation.Remaining(info.remaining)) end
	local racer = userId and Players:GetPlayerByUserId(userId)
	local head = racer and racer.Character and racer.Character:FindFirstChild("Head")
	view.tag.Adornee = if head and head:IsA("BasePart") then head else nil
	view.tag.Enabled = view.tag.Adornee ~= nil
	Kit.SetChip(view.tagChip, tostring(info.name or ""))
end

return View
