-- Next course ticket. Race: 1-5 in an event (0 = single race). Step: 1 Results/Vote, 2 Loading,
-- 3 Preview, 4 3·2·1. SlowLoading shows the "spot is saved" line; Failed the pink failure ticket.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({Race = 2, Step = 2, Course = "Keyboard Circuit", SlowLoading = false, Failed = false}, function(holder, values)
	local View = StoryKit.Load("NextCourseView")
	local course = if typeof(values.Course) == "string" and values.Course ~= "" then values.Course else "City Run"
	if values.Failed then
		View.ShowFailed(holder, course, "Not enough racers loaded the course in time.", true, function() end)
		return nil
	end
	local ticket = View.Create(holder, {skip = function() end, reduce = function() end})
	local race = math.clamp(math.floor(tonumber(values.Race) or 0), 0, 5)
	View.SetHeader(ticket, if race > 0 then "Race " .. race .. " of 5" else nil, course)
	local step = math.clamp(math.floor(tonumber(values.Step) or 2), 1, 4)
	local notes = {"Results are in", if values.SlowLoading then "Still loading. Hang tight, your spot is saved" else "Loading the course…",
		"Aim for the highlighted first checkpoint", "Get ready"}
	View.SetStep(ticket, step, notes[step], step == 2)
	View.SetCheckpoint(ticket, step == 3)
	View.SetPills(ticket, true, false)
	return nil
end)
