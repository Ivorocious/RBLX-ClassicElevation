--!strict
-- Race screens for the UI preview: the game's own race views filled with sample data and frozen
-- on their settled frame (UiKit.Frozen), so layouts can be checked at each device size.
local StudioService = game:GetService("StudioService")
local RacePreview = {}

RacePreview.Screens = {"Countdown", "Racing", "Checkpoint", "Final stretch", "Still racing?", "Finish", "Finish ticket", "Time's up", "Unfinished ticket", "Coins"}

local NAMES = {"Mia", "Leo", "Zara", "Kai", "Nova", "Theo", "Finn", "Ruby", "Ash", "Ivy", "Jun"}
local STEPS = {7, 6, 5, 4, 4, 4, 3, 3, 2, 2, 1}

local function sampleRace(myUserId: number, mySteps: number): any
	local active = {}
	local function racer(userId: number, name: string, steps: number, at: number)
		local splits = {}
		for index = 1, steps do table.insert(splits, {checkpointIndex = index, lap = 1, elapsedTime = index * 11 + at}) end
		table.insert(active, {userId = userId, displayName = name, status = "Racing", official = true, falls = 2,
			nextCheckpointIndex = steps + 1, checkpointCount = 9, requiredLaps = 1, checkpointSplits = splits})
	end
	racer(myUserId, "You", mySteps, 1)
	for index, name in NAMES do racer(-index, name, STEPS[index], index % 3) end
	return {raceId = "preview", checkpointCount = 9, requiredLaps = 1, activeRacers = active, placements = {}, dnfs = {}}
end

function RacePreview.Render(selection: string, content: Frame, modules: any, largeText: boolean)
	local Kit, Presentation, Hud, Moments, Ticket, Flow = modules.Kit, modules.RacePresentation, modules.RaceHudView, modules.RaceMomentsView, modules.FinishTicketView, modules.RaceFlowPresentation
	Kit.Frozen = true
	local sky = Instance.new("Frame")
	sky.Name, sky.Size, sky.BorderSizePixel, sky.BackgroundColor3 = "Sky", UDim2.fromScale(1, 1), 0, Color3.new(1, 1, 1)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation, gradient.Color = 90, ColorSequence.new(Color3.fromHex("8FD3FF"), Color3.fromHex("F3C68B"))
	gradient.Parent, sky.Parent = sky, content
	local layer = Instance.new("Frame")
	layer.Name, layer.Size, layer.BackgroundTransparency = "RaceLayer", UDim2.fromScale(1, 1), 1
	layer.Parent = content
	local hud = Hud.Create(layer)
	local moments = Moments.Create(layer, layer, layer)
	local ticket: any = nil
	local function layout()
		local size = content.AbsoluteSize
		if size.X <= 0 then return end
		Hud.Layout(hud, size, largeText)
		Moments.Layout(moments, size, largeText)
		if ticket then Ticket.Layout(ticket, size, largeText) end
	end
	content:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	local me = StudioService:GetUserId()
	local mySteps = if selection == "Checkpoint" then 6 elseif selection == "Final stretch" then 9 else 5
	local race = sampleRace(me, mySteps)
	local rows = Presentation.Standings(race)
	local racing = table.find({"Racing", "Checkpoint", "Final stretch", "Still racing?", "Coins"}, selection) ~= nil
	if racing then
		Hud.SetShown(hud, true, false)
		Hud.SetCourse(hud, "City Run")
		Hud.SetClock(hud, Presentation.Clock(64.2, 1))
		Hud.SetPlace(hud, Presentation.PlaceOf(rows, me), #rows, false)
		Hud.SetStats(hud, mySteps, 9, 2)
		Hud.SetLadder(hud, rows, me, nil, false)
		Hud.Toast(hud, "Passed Kai", true)
	end
	if selection == "Coins" then
		Hud.SetCoins(hud, true, 7)
		layout()
	elseif selection == "Countdown" then
		Moments.Countdown(moments, {title = "City Run", caption = "Race 2 of 5", line = "12 racers · 9 checkpoints · point to point", image = modules.Artwork.Image("city_run")}, 3, 3, function() return 0 end, function() end)
	elseif selection == "Checkpoint" then
		Moments.Ribbon(moments, {checkpoint = 6, count = 9, lap = 1, laps = 1, split = 72.8, delta = -0.9, final = false})
	elseif selection == "Final stretch" then
		Moments.Ribbon(moments, {checkpoint = 9, count = 9, lap = 1, laps = 1, split = 101, final = true})
	elseif selection == "Still racing?" then
		Moments.SetIdle(moments, true, .7, function() end)
	elseif selection == "Finish" then
		Moments.Finish(moments, {placement = 2, finishTime = 102.38, falls = 2, improvement = 3.1}, function() end)
	elseif selection == "Time's up" then
		Moments.Unfinished(moments, {reached = "Reached checkpoint 7 of 9"}, function() end)
	elseif selection == "Finish ticket" or selection == "Unfinished ticket" then
		local finished = selection == "Finish ticket"
		local state = {raceId = "preview", enrolled = true, status = if finished then "Finished" else "DNF", watchTargets = {{userId = 1}},
			finishTicket = if finished then {raceId = "preview", status = "Finished", official = true, placement = 2, finishTime = 102.38, isVisitBest = true, previousBestTime = 105.5}
				else {raceId = "preview", status = "DNF", official = true, furthestCheckpoint = 7, checkpointCount = 9},
			visit = {racesEntered = 3, completions = if finished then 3 else 2, target = if finished then nil else {message = "Reach checkpoint 8 of 9"}}}
		local model = Flow.Model(state, {available = true, inRoom = false, status = "Idle"})
		table.insert(model.buttons, {id = "ReduceMotion", text = "Reduce motion"})
		model.ticket.resultsIn = if finished then "0:41" else nil
		if finished then Moments.MiniFinish(moments, {placement = 2, finishTime = 102.38}, false) end
		ticket = Ticket.Create(layer, function() end)
		layout()
		Ticket.Render(ticket, model, false, nil)
		ticket.plate.Visible = true
		layout()
	end
end

return RacePreview
