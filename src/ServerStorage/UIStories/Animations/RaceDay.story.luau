-- The whole race day in order, as a player sees it: vote and lock-in, next course delivery, the
-- 3-2-1-GO countdown, racing, a checkpoint, the final stretch, the finish burst, the finish ticket,
-- results and, after the fifth race, the event end. The chip top-left names the step. Loops.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({Course = "Keyboard Circuit"}, function(holder, values)
	local course = if typeof(values.Course) == "string" and values.Course ~= "" then values.Course else "Keyboard Circuit"
	local courseId = StoryKit.CourseId(course)
	local race = {Motion = true, Course = course, VersusBest = true, Place = 2, RaceNumber = 1}
	local function noop() end
	local function later(seconds: number, action: () -> ())
		task.delay(seconds, function() pcall(action) end)
	end
	return StoryKit.Sequence(holder, {
		{name = "Opening vote", seconds = 4.6, run = function(stage)
			local View = StoryKit.Load("GalleryVotingView")
			local ui = View.Create(stage, {Hide = noop, Select = noop, Confirm = noop, Search = noop, Remove = noop})
			local catalog = StoryKit.Catalog()
			local function show(picks, confirmed, left)
				View.Render(ui, {catalog = catalog, picks = picks, timeLeft = left, duration = 15, phase = "Voting", pending = false, confirmed = confirmed, message = ""})
			end
			show({}, false, 9)
			later(1.1, function() if stage.Parent then show({courseId}, false, 8) end end)
			later(2.5, function() if stage.Parent then show({courseId}, true, 7) end end)
			return nil
		end},
		{name = "Next course", seconds = 5.2, run = function(stage)
			local View = StoryKit.Load("NextCourseView")
			local ticket = View.Create(stage, {skip = noop, reduce = noop})
			View.SetHeader(ticket, "Race 1 of 5", course)
			View.SetPills(ticket, true, false)
			View.SetStep(ticket, 1, "The opening course is picked", false)
			later(1.2, function() if stage.Parent then View.SetStep(ticket, 2, "Loading the course…", true) end end)
			later(2.6, function() if stage.Parent then View.SetStep(ticket, 3, "Aim for the highlighted first checkpoint", false); View.SetCheckpoint(ticket, true) end end)
			later(4.1, function() if stage.Parent then View.SetCheckpoint(ticket, false); View.SetStep(ticket, 4, "Get ready", false) end end)
			return nil
		end},
		{name = "Countdown", seconds = 5, run = function(stage) return StoryKit.Race(stage, "Countdown", race) end},
		{name = "Racing", seconds = 2.6, run = function(stage) return StoryKit.Race(stage, "Racing", race) end},
		{name = "Checkpoint", seconds = 3, run = function(stage) return StoryKit.Race(stage, "Checkpoint", race) end},
		{name = "Final stretch", seconds = 2.6, run = function(stage) return StoryKit.Race(stage, "Final stretch", race) end},
		{name = "Finish", seconds = 4.6, run = function(stage) return StoryKit.Race(stage, "Finish", race) end},
		{name = "Finish ticket", seconds = 3.6, run = function(stage)
			local ui, cleanup = StoryKit.FlowPanel(stage)
			ui.Show(StoryKit.FinishModel(true), true, false, nil)
			return cleanup
		end},
		{name = "Results", seconds = 7, run = function(stage)
			StoryKit.Results(stage, {Racers = 8, YourPlace = 2, DNF = true, Course = course, RaceNumber = 1}, true)
			return nil
		end},
		{name = "Event end (after race 5)", seconds = 7, run = function(stage) return StoryKit.EventEnd(stage, {YouWon = 4}) end},
	})
end, {sky = {"8FD3FF", "F3C68B"}})
