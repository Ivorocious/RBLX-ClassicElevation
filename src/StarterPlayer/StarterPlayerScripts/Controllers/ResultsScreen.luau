--!strict
-- Race results (brief "Results", replaces RaceResultsUI): a podium with the top three as real 3D
-- avatars, other finishers and DNFs with headshots, your event strip (or this visit's totals after a
-- single race) and the next course with a loading bar. Display only: RaceConfig.ResultsDuration and
-- every result come from the server.
local Players = game:GetService("Players")
local Kit = require(script.Parent.UiKit)
local Presentation = require(script.Parent.RacePresentation)
local FlowPresentation = require(script.Parent.RaceFlowPresentation)

local Screen = {}
local DESIGN = Vector2.new(1280, 720)
local HOLD_SECONDS = 8
local MAX_ROWS = 7
-- Roblox-owned R15 emotes from the default Animate script: cheer, wave and point.
local POSES = {"rbxassetid://507770677", "rbxassetid://507770239", "rbxassetid://507770453"}
local PODIUM = {
	{x = 270, width = 170, height = 210, fill = "Hero"},
	{x = 90, width = 170, height = 150, fill = "White"},
	{x = 450, width = 170, height = 112, fill = "Pink"},
}

local player = Players.LocalPlayer
-- The UI preview supplies its own viewer id; in game it is the local player.
local viewerId = if player then player.UserId else 0
local gui: ScreenGui? = nil
local ui: any = nil
local race: any = {state = nil, raceId = nil, remaining = nil, duration = nil}
local results: any = nil
local event: any = nil
local flow: any = nil
local leftResultsAt: number? = nil
local wasInResults = false
local shownRace: string? = nil
-- Your placings per event race, remembered on the client: [tournamentId][raceIndex] = text.
local eventPlacings: {[string]: {[number]: string}} = {}
local eventPlaces: {[string]: {[number]: number}} = {}
local bestPlace: number? = nil

local function round(item: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, radius), item
end

local function headshot(userId: number): string
	return if userId > 0 then string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId) else ""
end

local function nameOf(result: any): string
	return tostring(result.displayName or result.name or "Racer")
end

local function courseName(courseId: string?): string?
	if not courseId or typeof(event) ~= "table" then return courseId end
	for _, row in event.catalog or {} do if row.id == courseId then return row.name end end
	return courseId
end

local function eventMode(): boolean
	return typeof(event) == "table" and event.eventMode == "Tournament" and typeof(event.lineup) == "table" and #event.lineup > 1
end

-- A podium avatar: the racer's real look in a small 3D view, posed with a looping emote.
local function avatar(parent: Instance, userId: number, pose: string, onModel: () -> ()): Frame
	local holder = Kit.Frame(parent, "Avatar", UDim2.fromOffset(220, 250), UDim2.new())
	local fallback = Instance.new("ImageLabel")
	fallback.Name, fallback.Image, fallback.BackgroundColor3 = "Headshot", headshot(userId), Kit.Silver
	fallback.AnchorPoint, fallback.Position, fallback.Size = Vector2.new(.5, 1), UDim2.new(.5, 0, 1, -8), UDim2.fromOffset(130, 130)
	round(fallback, 60)
	Kit.Stroke(fallback, Kit.Navy, 4, true)
	fallback.Parent = holder
	local viewport = Instance.new("ViewportFrame")
	viewport.Name, viewport.BackgroundTransparency, viewport.Size = "Model", 1, UDim2.fromScale(1, 1)
	viewport.Ambient, viewport.LightColor, viewport.LightDirection = Color3.fromRGB(165, 172, 190), Color3.fromRGB(255, 248, 232), Vector3.new(-.6, -1, 1.4)
	viewport.Parent = holder
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 3.2, -11.5), Vector3.new(0, 2.7, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	if userId <= 0 then return holder end
	task.spawn(function()
		local ok, model = pcall(function() return Players:CreateHumanoidModelFromUserIdAsync(userId) end)
		if not ok or not model or not holder.Parent then if ok and model then model:Destroy() end; return end
		local root = model:FindFirstChild("HumanoidRootPart")
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not root or not root:IsA("BasePart") or not humanoid then model:Destroy(); return end
		for _, item in model:GetDescendants() do
			if item:IsA("BasePart") then item.CanCollide, item.CanTouch, item.CanQuery = false, false, false
			elseif item:IsA("Script") or item:IsA("LocalScript") then item:Destroy() end
		end
		-- Only the root is anchored so the Animator can still move the limbs inside the WorldModel.
		root.Anchored = true
		local _, size = model:GetBoundingBox()
		model:PivotTo(CFrame.new(0, size.Y / 2, 0) * CFrame.Angles(0, math.rad(if pose == POSES[2] then -14 else 10), 0))
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		model.Parent = world
		fallback.Visible = false
		onModel()
		if not Kit.Motion() then return end
		local animation = Instance.new("Animation")
		animation.AnimationId = pose
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		local loaded, track = pcall(function() return (animator :: Animator):LoadAnimation(animation) end)
		if loaded and track then
			track.Looped, track.Priority = true, Enum.AnimationPriority.Action
			track:Play(.2)
		end
	end)
	return holder
end

local function build(parent: ScreenGui)
	local root = Kit.Frame(parent, "Results", UDim2.fromScale(1, 1), UDim2.new())
	root.Visible = false
	-- Nearly solid, so the lobby HUD and the course behind never show through around the podium.
	local shade = Kit.Frame(root, "Shade", UDim2.fromScale(1, 1), UDim2.new(), Kit.White, .08)
	shade.Name = "Shade"
	local backdrop = Instance.new("UIGradient")
	backdrop.Rotation, backdrop.Color = 90, ColorSequence.new(Color3.fromHex("1B3A9E"), Kit.Navy)
	backdrop.Parent = shade
	local stage = Kit.Frame(root, "Stage", UDim2.fromOffset(DESIGN.X, DESIGN.Y), UDim2.fromScale(.5, .5))
	stage.AnchorPoint = Vector2.new(.5, .5)
	local fit = Instance.new("UIScale")
	fit.Name, fit.Parent = "Fit", stage
	local title = Kit.SkyPlate(stage, "Title", UDim2.fromOffset(400, 94), UDim2.fromOffset(440, 12), {fill = "Hero", class = "M", stripes = true})
	Kit.Sheen(title, 4.5)
	local titleContent = Kit.Content(title)
	local caption = Kit.SkyCaption(titleContent, "Caption", "Race results", 14, true)
	caption.Position, caption.Size = UDim2.fromOffset(0, 16), UDim2.new(1, 0, 0, 16)
	local course = Kit.SkyBig(titleContent, "Course", "", 46)
	course.Position, course.Size = UDim2.fromOffset(30, 36), UDim2.new(1, -60, 0, 48)
	local podium = Kit.Frame(stage, "Podium", UDim2.fromScale(1, 1), UDim2.new())
	local rows = Kit.Frame(stage, "Rows", UDim2.fromOffset(520, 440), UDim2.fromOffset(690, 130))
	local strip = Kit.SkyPlate(stage, "Strip", UDim2.fromOffset(1090, 100), UDim2.fromOffset(95, 604), {class = "M", stripes = true})
	local stripContent = Kit.Content(strip)
	local stripCaption = Kit.SkyCaption(stripContent, "Caption", "Your event", 14)
	stripCaption.Position, stripCaption.Size, stripCaption.TextXAlignment = UDim2.fromOffset(54, 22), UDim2.fromOffset(220, 16), Enum.TextXAlignment.Left
	local stripLine = Kit.Body(stripContent, "Line", "", 17, Kit.White)
	stripLine.Position, stripLine.Size, stripLine.TextXAlignment = UDim2.fromOffset(50, 48), UDim2.fromOffset(560, 22), Enum.TextXAlignment.Left
	local chips = Kit.Frame(stripContent, "Races", UDim2.fromOffset(0, 46), UDim2.fromOffset(50, 42))
	chips.AutomaticSize = Enum.AutomaticSize.X
	local chipList = Instance.new("UIListLayout")
	chipList.FillDirection, chipList.Padding, chipList.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 10), Enum.SortOrder.LayoutOrder
	chipList.Parent = chips
	local nextCaption = Kit.SkyCaption(stripContent, "Next", "", 13)
	nextCaption.Position, nextCaption.Size, nextCaption.TextXAlignment = UDim2.fromOffset(700, 18), UDim2.fromOffset(330, 16), Enum.TextXAlignment.Right
	local bar = Kit.Frame(stripContent, "Loading", UDim2.fromOffset(240, 14), UDim2.fromOffset(790, 44), Kit.White, 0)
	round(bar, 7)
	Kit.Stroke(bar, Kit.Navy, 2.5, true)
	local fill = Kit.Frame(bar, "Fill", UDim2.fromScale(0, 1), UDim2.new(), Kit.Sun, 0)
	round(fill, 7)
	local nextLine = Kit.SkyCaption(stripContent, "NextLine", "", 13)
	nextLine.Position, nextLine.Size, nextLine.TextXAlignment = UDim2.fromOffset(700, 66), UDim2.fromOffset(330, 16), Enum.TextXAlignment.Right
	ui = {root = root, fit = fit, title = title, caption = caption, course = course, podium = podium, rows = rows, stripCaption = stripCaption,
		stripLine = stripLine, chips = chips, nextCaption = nextCaption, fill = fill, nextLine = nextLine}
end

local function layout()
	if not gui or not ui then return end
	local size = gui.AbsoluteSize
	local fit = math.min(size.X / DESIGN.X, size.Y / DESIGN.Y)
	ui.fit.Scale = math.min(math.clamp(fit, .42, 1.3) * (if Kit.LargeText() then 1.06 else 1), size.Y / DESIGN.Y)
end

local function row(parent: Instance, index: number, result: any, dnf: boolean)
	local plate = Kit.SkyPlate(parent, "Row" .. index, UDim2.fromOffset(520, 52), UDim2.fromOffset(0, (index - 1) * 60), {class = "S"})
	local content = Kit.Content(plate)
	local place = Kit.SkyBig(content, "Place", if dnf then "DNF" else tostring(result.placement or "–"), if dnf then 20 else 30)
	place.Position, place.Size = UDim2.fromOffset(18, if dnf then 15 else 10), UDim2.fromOffset(56, if dnf then 22 else 32)
	local bust = Instance.new("ImageLabel")
	bust.Name, bust.Image, bust.BackgroundColor3 = "Headshot", headshot(tonumber(result.userId) or 0), Kit.Silver
	bust.Position, bust.Size = UDim2.fromOffset(80, 7), UDim2.fromOffset(38, 38)
	round(bust, 19)
	Kit.Stroke(bust, Kit.Navy, 2.5, true)
	bust.Parent = content
	local name = Kit.Body(content, "Name", nameOf(result), 19, Kit.White)
	name.FontFace, name.Position, name.Size, name.TextXAlignment = Kit.Display, UDim2.fromOffset(128, 14), UDim2.fromOffset(190, 24), Enum.TextXAlignment.Left
	name.TextTruncate = Enum.TextTruncate.AtEnd
	Kit.Stroke(name, Kit.Navy, 2, false)
	local time = Kit.Body(content, "Time", if dnf then "–" else Presentation.Clock(result.finishTime, 2), 18, Kit.White)
	time.Position, time.Size, time.TextXAlignment = UDim2.fromOffset(318, 15), UDim2.fromOffset(90, 22), Enum.TextXAlignment.Right
	local falls = typeof(result.falls) == "number" and result.falls or 0
	local detail = if dnf then (if typeof(result.dnfReason) == "string" and result.dnfReason ~= "" then (if result.dnfReason == "Time expired" then "Out of time" else result.dnfReason) else "Did not finish")
		else falls .. (if falls == 1 then " fall" else " falls")
	local extra = Kit.Body(content, "Detail", detail, 14, Kit.White)
	extra.Position, extra.Size, extra.TextXAlignment, extra.TextTransparency = UDim2.fromOffset(412, 17), UDim2.fromOffset(92, 18), Enum.TextXAlignment.Right, .15
	if tonumber(result.userId) == viewerId then Kit.SetSkyFill(plate, "Hero") end
	if Kit.Motion() then
		plate.Position = UDim2.fromOffset(600, (index - 1) * 60)
		Kit.Tween(plate, .5, {Position = UDim2.fromOffset(0, (index - 1) * 60)}, "Pop", .5 + index * .07)
	end
end

local function render(animate: boolean)
	if not ui then return end
	ui.podium:ClearAllChildren()
	ui.rows:ClearAllChildren()
	local number = Presentation.RaceNumber(event, results and results.courseId)
	ui.caption.Text = string.upper(if number then number .. " · Results" else "Race results")
	Kit.SetBig(ui.course, string.upper(tostring(results and results.courseDisplayName or "Race")))
	Kit.FitBig(ui.course, 46, 340)
	local placements = if results and typeof(results.placements) == "table" then table.clone(results.placements) else {}
	table.sort(placements, function(a, b) return (a.placement or 999) < (b.placement or 999) end)
	local dnfs = if results and typeof(results.dnfs) == "table" then results.dnfs else {}
	-- With nobody beyond the podium the rows column would be empty, so the podium takes the middle and
	-- the title moves to the top left, clear of the winner's name.
	local shift = if #placements <= 3 and #dnfs == 0 then 285 else 0
	ui.title.Position = UDim2.fromOffset(if shift > 0 then 60 else 440, 12)
	for rank = 1, 3 do
		local spot = table.clone(PODIUM[rank])
		spot.x += shift
		if not placements[rank] then continue end
		local plate = Kit.SkyPlate(ui.podium, "Step" .. rank, UDim2.fromOffset(spot.width, spot.height), UDim2.fromOffset(spot.x, 590 - spot.height), {fill = spot.fill, class = "L"})
		local big = Kit.SkyBig(Kit.Content(plate), "Number", tostring(rank), 92)
		big.Position = UDim2.fromOffset(0, 18)
		local result = placements[rank]
		if result then
			local holder = Kit.Frame(ui.podium, "Racer" .. rank, UDim2.fromOffset(220, 330), UDim2.fromOffset(spot.x + spot.width / 2 - 110, 590 - spot.height - 330))
			if rank == 1 then Kit.Rays(ui.podium, 460, UDim2.fromOffset(spot.x + spot.width / 2, 590 - spot.height - 150), Kit.Sun, .62) end
			-- Name and time sit just above the stand-in headshot, and move up once the 3D racer appears.
			local name, chip
			local figure = avatar(holder, tonumber(result.userId) or 0, POSES[rank], function()
				if name and chip then name.Position, chip.Position = UDim2.fromOffset(0, 26), UDim2.new(.5, 0, 0, 58) end
			end)
			figure.Position = UDim2.fromOffset(0, 80)
			name = Kit.Body(holder, "Name", if tonumber(result.userId) == viewerId then "You" else nameOf(result), 22, Kit.White)
			name.FontFace, name.Position, name.Size = Kit.Display, UDim2.fromOffset(0, 116), UDim2.new(1, 0, 0, 26)
			Kit.Stroke(name, Kit.Navy, 3, false)
			chip = Kit.Chip(holder, "Time", Presentation.Clock(result.finishTime, 2), 15)
			chip.AnchorPoint, chip.Position = Vector2.new(.5, 0), UDim2.new(.5, 0, 0, 148)
			if animate and Kit.Motion() then Kit.Punch(holder, .2, .6, .2 + rank * .15) end
		end
		if animate and Kit.Motion() then
			plate.Position = UDim2.fromOffset(spot.x, 720)
			Kit.Tween(plate, .6, {Position = UDim2.fromOffset(spot.x, 590 - spot.height)}, "Pop", rank * .12)
		end
	end
	local index = 0
	local rest = {}
	for rank = 4, #placements do table.insert(rest, {placements[rank], false}) end
	for _, result in dnfs do table.insert(rest, {result, true}) end
	for _, entry in rest do
		index += 1
		if index > MAX_ROWS then break end
		row(ui.rows, index, entry[1], entry[2])
	end
	if #rest > MAX_ROWS then
		local more = Kit.Chip(ui.rows, "More", "+" .. (#rest - MAX_ROWS) .. " more racers", 15)
		more.Position = UDim2.fromOffset(20, MAX_ROWS * 60)
	end
	ui.chips:ClearAllChildren()
	local list = Instance.new("UIListLayout")
	list.FillDirection, list.Padding, list.SortOrder = Enum.FillDirection.Horizontal, UDim.new(0, 10), Enum.SortOrder.LayoutOrder
	list.Parent = ui.chips
	-- The race these results belong to: the server may already have moved on to the next one.
	local shownIndex = if eventMode() then (if results and typeof(results.courseId) == "string" then table.find(event.lineup, results.courseId) else nil) or event.raceIndex else nil
	if eventMode() then
		ui.stripCaption.Text, ui.stripLine.Visible, ui.chips.Visible = "YOUR EVENT", false, true
		local placings = eventPlacings[tostring(event.displayTournamentId or event.tournamentId)] or {}
		for raceIndex = 1, #event.lineup do
			local text = placings[raceIndex]
			local current = raceIndex == shownIndex
			local chip = Kit.Chip(ui.chips, "Race" .. raceIndex, "Race " .. raceIndex .. (if text then " · " .. text else ""), 15, if current then "Light" elseif text then "Plain" else nil)
			chip.LayoutOrder = raceIndex
			if not text then chip.BackgroundTransparency = .65 end
		end
	else
		ui.stripCaption.Text, ui.stripLine.Visible, ui.chips.Visible = "THIS VISIT", true, false
		local visit = flow and flow.visit
		local parts = {}
		if visit then table.insert(parts, FlowPresentation.VisitCounts(visit)) end
		if bestPlace then table.insert(parts, "best place " .. bestPlace .. string.lower(Presentation.Ordinal(bestPlace))) end
		ui.stripLine.Text = table.concat(parts, " · ")
	end
	local nextId = if typeof(shownIndex) == "number" then event.lineup[shownIndex + 1] else nil
	ui.nextCaption.Text = if nextId then "NEXT · " .. string.upper(courseName(nextId) or "") elseif eventMode() then "EVENT COMPLETE" else "NEXT RACE SOON"
	ui.nextLine.Text = if nextId then "LOADING THE COURSE" elseif eventMode() then "SEE THE EVENT RESULTS" else "GETTING THE NEXT RACE READY"
end

-- Records your placing for the event strip and this visit's best place.
local function remember(payload: any)
	local mine = Presentation.FindResult(payload, viewerId)
	if not mine then return end
	local placement = if typeof(mine.placement) == "number" then mine.placement else nil
	if placement and (not bestPlace or placement < bestPlace) then bestPlace = placement end
	if eventMode() then
		local index = if typeof(payload.courseId) == "string" then table.find(event.lineup, payload.courseId) else nil
		index = index or (if typeof(event.raceIndex) == "number" then event.raceIndex else nil)
		if not index then return end
		local key = tostring(event.displayTournamentId or event.tournamentId)
		eventPlacings[key] = eventPlacings[key] or {}
		eventPlacings[key][index] = if placement then placement .. Presentation.Ordinal(placement) else "DNF"
		eventPlaces[key] = eventPlaces[key] or {}
		eventPlaces[key][index] = placement :: any
	end
end

local function update()
	if not gui or not ui then return end
	local inResults = race.state == "RaceEnding" or race.state == "Results"
	if inResults then leftResultsAt = nil
	elseif wasInResults and not leftResultsAt then leftResultsAt = os.clock() end
	wasInResults = inResults
	-- The finish burst owns the screen first (RaceMoment); results follow it.
	local moment = player:GetAttribute("RaceMoment") == true
	-- Results stay through loading (about 8 seconds at most) and hand over when the course preview
	-- starts (TournamentPresentation); a failed delivery or a new vote takes over at once.
	local playerGui = player:FindFirstChild("PlayerGui")
	local failed = playerGui ~= nil and playerGui:FindFirstChild("CourseDeliveryFailed") ~= nil
	local holding = leftResultsAt ~= nil and os.clock() - leftResultsAt < HOLD_SECONDS and not failed and race.state ~= "Countdown" and race.state ~= "Racing"
	-- Once the event is complete its End screen (which lists every race winner) owns the short finale window.
	local eventOver = typeof(event) == "table" and event.phase == "Complete"
	local show = (inResults or holding) and not moment and results ~= nil and player:GetAttribute("TournamentPresentation") ~= true
		and player:GetAttribute("VoteOpen") ~= true and not eventOver
	-- The Next course ticket exists from the start of loading; keep it out of sight behind the results
	-- (looks only: delivery never reads its visibility) so the two never overlap.
	local ticket = playerGui and playerGui:FindFirstChild("CourseDelivery")
	if ticket and ticket:IsA("ScreenGui") then ticket.Enabled = not show end
	if show and results.raceId ~= shownRace then
		shownRace = results.raceId
		render(true)
	end
	if show ~= ui.root.Visible then
		ui.root.Visible = show
		gui.Enabled = show
		if show then
			Kit.Play("Fanfare")
			task.delay(.3, function() if ui.root.Visible then Kit.Confetti(ui.root, 70) end end)
		elseif ticket then
			-- Its own entrance played while hidden, so greet the handover with a pop.
			local plate = ticket:FindFirstChild("Ticket", true)
			if plate and plate:IsA("GuiObject") then Kit.Punch(plate, .85, .45) end
		end
	end
	if not show then return end
	local fraction = if inResults and typeof(race.remaining) == "number" and typeof(race.duration) == "number" and race.duration > 0
		then 1 - race.remaining / race.duration elseif leftResultsAt then .8 + .2 * math.clamp((os.clock() - leftResultsAt) / HOLD_SECONDS, 0, 1) else 0
	ui.fill.Size = UDim2.fromScale(math.clamp(fraction * (if inResults then .8 else 1), 0, 1), 1)
end

function Screen.Init()
	local playerGui = player:WaitForChild("PlayerGui")
	local old = playerGui:FindFirstChild("RaceResultsUI")
	if old then old:Destroy() end
	local screen = Instance.new("ScreenGui")
	-- Above the lobby HUD (20), the vote (30) and Race options (35) while it shows, so the finish panel
	-- never draws over the podium; update() hides it whenever a vote is open.
	screen.Name, screen.ResetOnSpawn, screen.DisplayOrder, screen.Enabled = "RaceResultsUI", false, 40, false
	screen.ZIndexBehavior, screen.ScreenInsets = Enum.ZIndexBehavior.Sibling, Enum.ScreenInsets.CoreUISafeInsets
	screen.Parent = playerGui
	gui = screen
	build(screen)
	screen:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	player:GetAttributeChangedSignal("LargeText"):Connect(layout)
	player:GetAttributeChangedSignal("TournamentPresentation"):Connect(update)
	layout()
	task.spawn(function()
		while screen.Parent do
			update()
			task.wait(.1)
		end
	end)
end

function Screen.HandleRaceState(state: string?, remaining: number?, duration: number?, raceId: string?)
	race.state, race.remaining, race.duration, race.raceId = state, remaining, duration, raceId
	update()
end

function Screen.HandleResults(payload: any)
	if typeof(payload) ~= "table" then return end
	results = payload
	-- Placings only count once the race is over; live standings arrive during the race too.
	local mine = Presentation.FindResult(payload, viewerId)
	if (mine and typeof(mine.placement) == "number") or race.state == "RaceEnding" or race.state == "Results" then remember(payload) end
	local count = (if typeof(payload.placements) == "table" then #payload.placements else 0) + (if typeof(payload.dnfs) == "table" then #payload.dnfs else 0)
	if ui and ui.root.Visible and payload.raceId == shownRace and count ~= ui.count then render(false) end
	if ui then ui.count = count end
	update()
end

function Screen.HandleEvent(snapshot: any) event = snapshot end

-- UI preview: draws the results screen into `parent` from sample data, without the live update loop.
-- `animate` plays the reveal the game plays when results open: podium rise, racer pop and confetti.
function Screen.Preview(parent: GuiBase2d, payload: any, eventSnapshot: any?, flowSnapshot: any?, me: number, placings: {[number]: string}?, animate: boolean?)
	-- A preview may draw into a plain frame; the live update loop (which needs a ScreenGui) never runs here.
	gui, viewerId, results, event, flow = parent :: any, me, payload, eventSnapshot, flowSnapshot
	if eventSnapshot and placings then eventPlacings[tostring(eventSnapshot.displayTournamentId or eventSnapshot.tournamentId)] = placings end
	build(parent)
	layout()
	ui.root.Visible = true
	render(animate == true)
	ui.fill.Size = UDim2.fromScale(.6, 1)
	if animate then
		local root = ui.root
		task.delay(.3, function() if root.Parent and root.Visible then Kit.Confetti(root, 70) end end)
	end
end
-- Your remembered placings for an event: text per race ("4TH", "DNF") and numeric places.
function Screen.EventPlacings(tournamentId: string): ({[number]: string}, {[number]: number})
	return eventPlacings[tournamentId] or {}, eventPlaces[tournamentId] or {}
end
function Screen.IsShowing(): boolean return ui ~= nil and ui.root.Visible end
function Screen.HandleFlow(snapshot: any) flow = snapshot end

return Screen
