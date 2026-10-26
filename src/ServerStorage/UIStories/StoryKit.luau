--!strict
-- Shared helpers for the UI Labs stories in this folder. Stories draw the game's own screen modules
-- with sample data in Edit mode; they never call remotes, save data or add anything to the place.
-- Every story gets two controls: Sky (a backdrop; turn it off in "View on Viewport" to see the
-- place behind), Motion (off shows each screen on its settled frame) and Sound (plays the UI sounds).
-- Animation stories also get ReplayEvery (seconds; 0 plays once), which rebuilds the screen so its
-- entrance plays again.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local StudioService = game:GetService("StudioService")

local StoryKit = {}

StoryKit.Courses = {
	{id = "city_run", name = "City Run"},
	{id = "egg_rush_circuit", name = "Egg Rush Circuit"},
	{id = "keyboard_circuit", name = "Keyboard Circuit"},
	{id = "moonlit_citadel", name = "Moonlit Citadel"},
	{id = "shipwreck_cove", name = "Shipwreck Cove"},
	{id = "stud_garden_v2", name = "Stud Garden"},
}
StoryKit.Names = {"Mia", "Leo", "Zara", "Kai", "Nova", "Theo", "Finn", "Ruby", "Ash", "Ivy", "Jun"}
StoryKit.LongName = "SuperSpeedyRacer2026"

-- A screen module from StarterPlayerScripts.Controllers. UI Labs swaps `require` for a fresh copy on
-- every reload, so saving a change (synced by Rojo) redraws the story.
function StoryKit.Load(name: string): any
	return require(StarterPlayer.StarterPlayerScripts.Controllers:WaitForChild(name))
end

function StoryKit.Config(name: string): any
	return require(ReplicatedStorage.Config:WaitForChild(name))
end

function StoryKit.Shared(name: string): any
	return require(ReplicatedStorage.Shared:WaitForChild(name))
end

function StoryKit.Me(): number
	local ok, id = pcall(function() return StudioService:GetUserId() end)
	return if ok and typeof(id) == "number" then id else 0
end

function StoryKit.Image(courseId: string): string
	local ok, image = pcall(StoryKit.Config("VotingArtwork").Image, courseId)
	return if ok and typeof(image) == "string" then image else ""
end

-- Course rows like the server's catalog: {id, name, image}.
function StoryKit.Catalog(count: number?): {any}
	local rows = {}
	for index, course in StoryKit.Courses do
		if index > math.clamp(count or #StoryKit.Courses, 1, #StoryKit.Courses) then break end
		table.insert(rows, {id = course.id, name = course.name, image = StoryKit.Image(course.id)})
	end
	return rows
end

-- A five-race lineup with no repeats and `courseId` as race `position`.
function StoryKit.Lineup(courseId: string, position: number): {string}
	local lineup = {}
	for _, course in StoryKit.Courses do
		if course.id ~= courseId and #lineup < 4 then table.insert(lineup, course.id) end
	end
	table.insert(lineup, math.clamp(position, 1, 5), courseId)
	return lineup
end

function StoryKit.CourseId(name: string): string
	for _, course in StoryKit.Courses do
		if string.lower(course.name) == string.lower(name) then return course.id end
	end
	return StoryKit.Courses[1].id
end

-- Calls `layout(size)` now and whenever the story area changes size.
function StoryKit.OnSize(holder: GuiObject, layout: (Vector2) -> ()): RBXScriptConnection
	local function apply()
		if holder.AbsoluteSize.X > 0 then layout(holder.AbsoluteSize) end
	end
	local connection = holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(apply)
	apply()
	return connection
end

-- Runs `action` now and then every `seconds` until the returned function is called (replays moments).
function StoryKit.Every(seconds: number, action: () -> ()): () -> ()
	local running = true
	task.spawn(function()
		while running do
			action()
			task.wait(seconds)
		end
	end)
	return function() running = false end
end

local function sky(parent: Instance, top: string, bottom: string)
	local backdrop = Instance.new("Frame")
	backdrop.Name, backdrop.Size, backdrop.BorderSizePixel, backdrop.BackgroundColor3 = "StorySky", UDim2.fromScale(1, 1), 0, Color3.new(1, 1, 1)
	backdrop.ZIndex = -10
	local gradient = Instance.new("UIGradient")
	gradient.Rotation, gradient.Color = 90, ColorSequence.new(Color3.fromHex(top), Color3.fromHex(bottom))
	gradient.Parent = backdrop
	backdrop.Parent = parent
end

export type Build = (holder: Frame, values: {[string]: any}) -> (() -> ())?

-- A UI Labs generic story. `build` draws one state into a fresh frame and may return a cleanup;
-- any control change rebuilds it. `replay` (seconds) adds the ReplayEvery control.
function StoryKit.Story(controls: {[string]: any}, build: Build, options: {sky: {string}?, replay: number?}?): any
	local all: {[string]: any} = {Sky = true, Motion = true, Sound = false}
	if options and options.replay then all.ReplayEvery = options.replay end
	for key, value in controls do all[key] = value end
	local colors = options and options.sky or {"8FD3FF", "EAF6FF"}
	return {
		controls = all,
		render = function(props: any)
			local Kit = StoryKit.Load("UiKit")
			local holder: Frame? = nil
			local cleanup: (() -> ())? = nil
			local generation = 0
			local function mount(values: {[string]: any})
				generation += 1
				local token = generation
				if cleanup then cleanup(); cleanup = nil end
				if holder then holder:Destroy() end
				Kit.Silent, Kit.Frozen = values.Sound ~= true, values.Motion == false
				local frame = Instance.new("Frame")
				frame.Name, frame.Size, frame.BackgroundTransparency, frame.BorderSizePixel = "Story", UDim2.fromScale(1, 1), 1, 0
				frame.ClipsDescendants = true
				frame.Parent = props.target
				holder = frame
				if values.Sky ~= false then sky(frame, colors[1], colors[2]) end
				local ok, result = pcall(build, frame, values)
				if not ok then
					local message = Instance.new("TextLabel")
					message.Name, message.Size, message.BackgroundTransparency, message.TextWrapped = "StoryError", UDim2.fromScale(1, 1), 1, true
					message.Text, message.TextColor3, message.TextSize = "Story failed: " .. tostring(result), Color3.new(1, 1, 1), 16
					message.Parent = frame
					warn("[UI story] " .. tostring(result))
				elseif typeof(result) == "function" then
					cleanup = result
				end
				local every = tonumber(values.ReplayEvery) or 0
				if every > 0 and values.Motion ~= false then
					task.delay(math.max(1, every), function()
						if token == generation then mount(values) end
					end)
				end
			end
			mount(props.controls)
			local disconnect = props.subscribe(function(values: {[string]: any}) mount(values) end)
			return function()
				generation += 1
				disconnect()
				if cleanup then cleanup() end
				if holder then holder:Destroy() end
			end
		end,
	}
end

-- Keeps a Heartbeat-driven screen (arrival) moving; the returned function stops it.
function StoryKit.Heartbeat(step: (number) -> ()): () -> ()
	local connection = RunService.Heartbeat:Connect(step)
	return function() connection:Disconnect() end
end

export type Step = {name: string, seconds: number, run: (stage: Frame) -> (() -> ())?}

-- Plays `steps` one after another (for theatrics that unfold over time). Each step runs in a fresh
-- frame (or in `holder` itself when `fresh` is false) and may return a cleanup. A caption chip names
-- the step playing. Loops when `loop` is true; the returned function stops it.
function StoryKit.Sequence(holder: Frame, steps: {Step}, options: {loop: boolean?, captions: boolean?, fresh: boolean?}?): () -> ()
	local Kit = StoryKit.Load("UiKit")
	local opts = options or {}
	local running = true
	local stage: Frame? = nil
	local stepCleanup: (() -> ())? = nil
	local caption: Frame? = nil
	if opts.captions ~= false then
		local chip = Kit.Chip(holder, "StepCaption", "", 15)
		-- Top-left: the one corner no screen uses for its own panels.
		chip.Position, chip.ZIndex = UDim2.fromOffset(16, 16), 100
		caption = chip
	end
	local function clear()
		if stepCleanup then pcall(stepCleanup); stepCleanup = nil end
		if stage and stage ~= holder then stage:Destroy() end
		stage = nil
	end
	task.spawn(function()
		repeat
			for index, step in steps do
				if not running then break end
				clear()
				if opts.fresh == false then
					stage = holder
				else
					local frame = Instance.new("Frame")
					frame.Name, frame.Size, frame.BackgroundTransparency = "Step" .. index, UDim2.fromScale(1, 1), 1
					frame.Parent = holder
					stage = frame
				end
				if caption then Kit.SetChip(caption, index .. "/" .. #steps .. " · " .. step.name) end
				local ok, result = pcall(step.run, stage :: Frame)
				if not ok then warn("[UI story] " .. step.name .. ": " .. tostring(result))
				elseif typeof(result) == "function" then stepCleanup = result end
				task.wait(step.seconds)
			end
		until not running or opts.loop == false
	end)
	return function()
		running = false
		clear()
	end
end

-- Which race of the five event races a story shows (RaceNumber control, default 2).
local function raceNumber(values: {[string]: any}): number
	return math.clamp(math.floor(tonumber(values.RaceNumber) or 2), 1, 5)
end

-- Race screens: the game's race HUD, moments and finish ticket over sample standings.
local function sampleRace(me: number, mySteps: number): any
	local active = {}
	local steps = {7, 6, 5, 4, 4, 4, 3, 3, 2, 2, 1}
	local function racer(userId: number, name: string, done: number, at: number)
		local splits = {}
		for index = 1, done do table.insert(splits, {checkpointIndex = index, lap = 1, elapsedTime = index * 11 + at}) end
		table.insert(active, {userId = userId, displayName = name, status = "Racing", official = true, falls = 2,
			nextCheckpointIndex = done + 1, checkpointCount = 9, requiredLaps = 1, checkpointSplits = splits})
	end
	racer(me, "You", mySteps, 1)
	for index, name in StoryKit.Names do racer(-index, name, steps[index], index % 3) end
	return {raceId = "story", checkpointCount = 9, requiredLaps = 1, activeRacers = active, placements = {}, dnfs = {}}
end

export type RaceScreen = "Countdown" | "Racing" | "Checkpoint" | "Final stretch" | "Still racing?" | "Finish" | "Finish ticket" | "Time's up" | "Unfinished ticket" | "Coins"

function StoryKit.Race(holder: Frame, screen: RaceScreen, values: {[string]: any}): () -> ()
	local Presentation, Hud, Moments = StoryKit.Load("RacePresentation"), StoryKit.Load("RaceHudView"), StoryKit.Load("RaceMomentsView")
	local Ticket = StoryKit.Load("FinishTicketView")
	local course = if typeof(values.Course) == "string" and values.Course ~= "" then values.Course else "City Run"
	local layer = Instance.new("Frame")
	layer.Name, layer.Size, layer.BackgroundTransparency = "RaceLayer", UDim2.fromScale(1, 1), 1
	layer.Parent = holder
	local hud = Hud.Create(layer)
	local moments = Moments.Create(layer, layer, layer)
	local ticket: any = nil
	local sizing = StoryKit.OnSize(holder, function(size)
		Hud.Layout(hud, size, false)
		Moments.Layout(moments, size, false)
		if ticket then Ticket.Layout(ticket, size, false) end
	end)
	local stops: {() -> ()} = {function() sizing:Disconnect() end}
	local me = StoryKit.Me()
	local mySteps = if screen == "Checkpoint" then 6 elseif screen == "Final stretch" then 9 else 5
	local rows = Presentation.Standings(sampleRace(me, mySteps))
	if table.find({"Racing", "Checkpoint", "Final stretch", "Still racing?", "Coins"}, screen) then
		Hud.SetShown(hud, true, false)
		Hud.SetCourse(hud, course)
		Hud.SetClock(hud, Presentation.Clock(64.2, 1))
		Hud.SetPlace(hud, Presentation.PlaceOf(rows, me), #rows, false)
		Hud.SetStats(hud, mySteps, 9, 2)
		Hud.SetLadder(hud, rows, me, nil, false)
		Hud.Toast(hud, "Passed Kai", true)
	end
	local frozen = values.Motion == false
	-- Moments replay on a loop while Motion is on; with Motion off they draw once, settled.
	local function replay(seconds: number, action: () -> ())
		if frozen then action() else table.insert(stops, StoryKit.Every(seconds, action)) end
	end
	if screen == "Coins" then
		Hud.SetCoins(hud, true, 7)
	elseif screen == "Countdown" then
		local card = {title = course, caption = "Race " .. raceNumber(values) .. " of 5", line = "12 racers · 9 checkpoints · point to point", image = StoryKit.Image(StoryKit.CourseId(course))}
		if frozen then
			Moments.Countdown(moments, card, 3, 3, function() return 0 end, function() end)
		else
			replay(7, function() Moments.Countdown(moments, card, os.clock() + 3.4, 3, os.clock, function() end) end)
		end
	elseif screen == "Checkpoint" then
		local ribbon = {checkpoint = 6, count = 9, lap = 1, laps = 1, split = 72.8, delta = if values.VersusBest then -0.9 else nil, final = false}
		replay(4, function() Moments.Ribbon(moments, ribbon) end)
	elseif screen == "Final stretch" then
		replay(4, function() Moments.Ribbon(moments, {checkpoint = 9, count = 9, lap = 1, laps = 1, split = 101, final = true}) end)
	elseif screen == "Still racing?" then
		Moments.SetIdle(moments, true, .7, function() end)
	elseif screen == "Finish" then
		local place = math.clamp(math.floor(tonumber(values.Place) or 1), 1, 20)
		replay(7, function()
			Moments.ClearFinish(moments)
			Moments.Finish(moments, {placement = place, finishTime = 102.38, falls = 2, improvement = 3.1}, function() end)
		end)
	elseif screen == "Time's up" then
		replay(7, function()
			Moments.ClearFinish(moments)
			Moments.Unfinished(moments, {reached = "Reached checkpoint 7 of 9"}, function() end)
		end)
	elseif screen == "Finish ticket" or screen == "Unfinished ticket" then
		local finished = screen == "Finish ticket"
		local model = StoryKit.FinishModel(finished)
		if finished then Moments.MiniFinish(moments, {placement = 2, finishTime = 102.38}, false) end
		ticket = Ticket.Create(layer, function() end)
		Ticket.Layout(ticket, holder.AbsoluteSize, false)
		Ticket.Render(ticket, model, false, nil)
		ticket.plate.Visible = true
	end
	return function()
		for _, stop in stops do stop() end
	end
end

-- Results screen with sample finishers. `animate` plays the reveal (podium rise, racer pop, confetti).
function StoryKit.Results(holder: Frame, values: {[string]: any}, animate: boolean?)
	local Screen, Presentation = StoryKit.Load("ResultsScreen"), StoryKit.Load("RacePresentation")
	local me = StoryKit.Me()
	local count = math.clamp(math.floor(tonumber(values.Racers) or 8), 1, 12)
	local mine = math.floor(tonumber(values.YourPlace) or 0)
	local placements, dnfs = {}, {}
	local others = 0
	for place = 1, count do
		local you = place == mine
		if not you then others += 1 end
		local name = if you then "You" elseif values.LongNames then StoryKit.LongName else StoryKit.Names[others] or ("Racer " .. others)
		table.insert(placements, {userId = if you then me else -place, displayName = name, placement = place, finishTime = 84 + place * 6.37, falls = place % 4, official = true})
	end
	if values.DNF then table.insert(dnfs, {userId = -99, displayName = "Ruby", dnfReason = "Time expired", falls = 3}) end
	local course = if typeof(values.Course) == "string" and values.Course ~= "" then values.Course else "Keyboard Circuit"
	local courseId = StoryKit.CourseId(course)
	local number = raceNumber(values)
	-- Earlier races carry sample placings; this race shows your place. raceIndex is already one ahead, as on the server.
	local placings = {}
	for index = 1, number - 1 do placings[index] = ({"1ST", "3RD", "2ND", "4TH"})[index] end
	placings[number] = if mine > 0 then mine .. Presentation.Ordinal(mine) else "DNF"
	local event = if values.SingleRace then nil else {eventMode = "Tournament", lineup = StoryKit.Lineup(courseId, number), raceIndex = number + 1,
		catalog = StoryKit.Catalog(), tournamentId = "story", displayTournamentId = "story"}
	Screen.Preview(holder, {raceId = "story", courseId = courseId, courseDisplayName = course, placements = placements, dnfs = dnfs},
		event, {visit = {racesEntered = 2, completions = 2}}, me, placings, animate)
end

-- Event end ("Tournament complete") with five sample race winners; its reveal plays when Motion is on.
function StoryKit.EventEnd(holder: Frame, values: {[string]: any}): () -> ()
	local View = StoryKit.Load("EventEndView")
	local me = StoryKit.Me()
	local function noop() end
	local view = View.Create(holder, noop, noop)
	local sizing = StoryKit.OnSize(holder, function(size) View.Layout(view, size, false) end)
	local won = math.floor(tonumber(values.YouWon) or 0)
	local winners = {{"Mia", 72.4, "4TH", 4}, {"Leo", 98.1, "2ND", 2}, {"Zara", 121.7, "3RD", 3}, {"Kai", 115, "2ND", 2}, {"Nova", 107.3, "5TH", 5}}
	local races, best, finished = {}, 99, 0
	for index, course in StoryKit.Courses do
		if index > 5 then break end
		local winner = winners[index]
		local you = index == won
		local name = if you then "You" elseif values.LongName and index == 5 then StoryKit.LongName else winner[1]
		local place = if you then 1 else winner[4]
		best, finished = math.min(best, place), finished + 1
		table.insert(races, {image = StoryKit.Image(course.id), winnerName = name, winnerUserId = if you then me else 0,
			winnerTime = winner[2], mine = if you then "1ST" else winner[3], place = place})
	end
	View.Set(view, {key = "story", raceCount = 5, races = races, best = best, finished = finished, visit = "This visit: 6 races entered · 5 completed"}, me)
	View.SetFinale(view, values.Finale == true)
	if values.Finale then view.root.Visible = false end
	return function() sizing:Disconnect() end
end

-- RaceFlowView (Race options panel, finish ticket) drawn into `holder` with a stand-in player:
-- the view only reads UserId and listens for the LargeText setting. Returns the view and a cleanup.
function StoryKit.FlowPanel(holder: Frame): (any, () -> ())
	local View = StoryKit.Load("RaceFlowView")
	local layer = Instance.new("Frame")
	layer.Name, layer.Size, layer.BackgroundTransparency = "RaceFlow", UDim2.fromScale(1, 1), 1
	layer.Parent = holder
	local settingChanged = Instance.new("BindableEvent")
	local player = {UserId = StoryKit.Me(), GetAttributeChangedSignal = function() return settingChanged.Event end}
	local ui = View.Create(player :: any, function() end, layer)
	return ui, function() ui.Destroy(); settingChanged:Destroy() end
end

-- The finish ticket model the race flow builds after a finish (or a time-out when `finished` is false).
function StoryKit.FinishModel(finished: boolean): any
	local Flow = StoryKit.Load("RaceFlowPresentation")
	local state = {raceId = "story", enrolled = true, status = if finished then "Finished" else "DNF", watchTargets = {{userId = 1}},
		finishTicket = if finished then {raceId = "story", status = "Finished", official = true, placement = 2, finishTime = 102.38, isVisitBest = true, previousBestTime = 105.5}
			else {raceId = "story", status = "DNF", official = true, furthestCheckpoint = 7, checkpointCount = 9},
		visit = {racesEntered = 3, completions = if finished then 3 else 2, target = if finished then nil else {message = "Reach checkpoint 8 of 9"}}}
	local model = Flow.Model(state, {available = true, inRoom = false, status = "Idle"})
	table.insert(model.buttons, {id = "ReduceMotion", text = "Reduce motion"})
	model.ticket.resultsIn = if finished then "0:41" else nil
	return model
end

StoryKit.SampleRace = sampleRace

return StoryKit
