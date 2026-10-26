-- Ticket after running out of time.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({}, function(holder, values)
	return StoryKit.Race(holder, "Unfinished ticket", values)
end, {sky = {"8FD3FF", "F3C68B"}})
