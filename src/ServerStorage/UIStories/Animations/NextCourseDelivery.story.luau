-- Next course delivery: the ticket drops in and walks through its steps, including slow loading and
-- the first-checkpoint chip during the preview. Race 0 is a single race. Loops.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({Course = "Keyboard Circuit", Race = 2}, function(holder, values)
	local View = StoryKit.Load("NextCourseView")
	local course = if typeof(values.Course) == "string" and values.Course ~= "" then values.Course else "Keyboard Circuit"
	local race = math.clamp(math.floor(tonumber(values.Race) or 0), 0, 5)
	local function noop() end
	local ticket: any = nil
	local layer: Frame? = nil
	local stop = StoryKit.Sequence(holder, {
		{name = "Ticket drops in", seconds = 1.8, run = function()
			if layer then layer:Destroy() end
			local frame = Instance.new("Frame")
			frame.Name, frame.Size, frame.BackgroundTransparency = "Delivery", UDim2.fromScale(1, 1), 1
			frame.Parent = holder
			layer = frame
			ticket = View.Create(frame, {skip = noop, reduce = noop})
			View.SetHeader(ticket, if race > 0 then "Race " .. race .. " of 5" else nil, course)
			View.SetPills(ticket, true, false)
			View.SetStep(ticket, 1, if race > 1 then "Results are in" else "The opening course is picked", false)
			return nil
		end},
		{name = "Loading", seconds = 1.8, run = function() View.SetStep(ticket, 2, "Loading the course…", true); return nil end},
		{name = "Slow loading", seconds = 1.8, run = function() View.SetStep(ticket, 2, "Still loading. Hang tight, your spot is saved", true); return nil end},
		{name = "Course preview", seconds = 2.2, run = function()
			View.SetStep(ticket, 3, "Aim for the highlighted first checkpoint", false)
			View.SetCheckpoint(ticket, true)
			return nil
		end},
		{name = "3·2·1", seconds = 1.8, run = function() View.SetCheckpoint(ticket, false); View.SetStep(ticket, 4, "Get ready", false); return nil end},
	}, {fresh = false})
	return function() stop(); if layer then layer:Destroy() end end
end, {sky = {"8FD3FF", "F3C68B"}})
