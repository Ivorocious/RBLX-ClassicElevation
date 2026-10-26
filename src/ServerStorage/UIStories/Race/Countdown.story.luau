-- 3-2-1-GO with the course card (replays every few seconds while Motion is on). Try a long Course.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({Course = "Keyboard Circuit"}, function(holder, values)
	return StoryKit.Race(holder, "Countdown", values)
end, {sky = {"8FD3FF", "F3C68B"}})
