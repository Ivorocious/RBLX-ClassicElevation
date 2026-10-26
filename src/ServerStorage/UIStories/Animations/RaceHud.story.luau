-- The race HUD in motion: it slides in at GO, the clock runs, you pass a racer, reach a checkpoint
-- (ladder burst), get passed, and the coin counter appears. Loops.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({Course = "City Run"}, function(holder, values)
	local Presentation, Hud = StoryKit.Load("RacePresentation"), StoryKit.Load("RaceHudView")
	local course = if typeof(values.Course) == "string" and values.Course ~= "" then values.Course else "City Run"
	local me = StoryKit.Me()
	local hud: any = nil
	local layer: Frame? = nil
	local startedAt = os.clock()
	local function standings(steps: number) return Presentation.Standings(StoryKit.SampleRace(me, steps)) end
	local sizing = StoryKit.OnSize(holder, function(size) if hud then Hud.Layout(hud, size, false) end end)
	local clock = StoryKit.Heartbeat(function()
		if hud then Hud.SetClock(hud, Presentation.Clock(os.clock() - startedAt, 1)) end
	end)
	local stop = StoryKit.Sequence(holder, {
		{name = "HUD slides in", seconds = 2.2, run = function()
			if layer then layer:Destroy() end
			local frame = Instance.new("Frame")
			frame.Name, frame.Size, frame.BackgroundTransparency = "RaceLayer", UDim2.fromScale(1, 1), 1
			frame.Parent = holder
			layer = frame
			hud = Hud.Create(frame)
			Hud.Layout(hud, holder.AbsoluteSize, false)
			startedAt = os.clock()
			local rows = standings(4)
			Hud.SetCourse(hud, course)
			Hud.SetPlace(hud, Presentation.PlaceOf(rows, me), #rows, false)
			Hud.SetStats(hud, 4, 9, 1)
			Hud.SetLadder(hud, rows, me, nil, false)
			Hud.SetCoins(hud, false)
			Hud.SetShown(hud, true, true)
			return nil
		end},
		{name = "Passed a racer", seconds = 2, run = function()
			Hud.Toast(hud, "Passed Kai", true)
			Hud.SetPlace(hud, 2, 12, true)
			return nil
		end},
		{name = "Checkpoint", seconds = 2.2, run = function()
			local rows = standings(5)
			Hud.SetStats(hud, 5, 9, 1)
			Hud.PunchCheckpoints(hud)
			Hud.SetLadder(hud, rows, me, nil, true)
			Hud.LadderBurst(hud, 5, 9)
			return nil
		end},
		{name = "Passed by a racer", seconds = 2, run = function()
			Hud.Toast(hud, "Leo passed you", false)
			Hud.SetPlace(hud, 3, 12, true)
			return nil
		end},
		{name = "Coins", seconds = 2, run = function() Hud.SetCoins(hud, true, 7); return nil end},
	}, {fresh = false})
	return function() stop(); clock(); sizing:Disconnect(); if layer then layer:Destroy() end end
end, {sky = {"8FD3FF", "F3C68B"}})
