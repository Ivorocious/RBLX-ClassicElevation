-- Event end opening: race columns rise one by one, the title pops and confetti falls. Replays every
-- ReplayEvery seconds.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({YouWon = 4}, function(holder, values)
	return StoryKit.EventEnd(holder, values)
end, {sky = {"1B3A9E", "10215C"}, replay = 7})
