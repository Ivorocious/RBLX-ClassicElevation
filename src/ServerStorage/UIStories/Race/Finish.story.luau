-- Finish burst. Place sets the result shown.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({Place = 1}, function(holder, values)
	return StoryKit.Race(holder, "Finish", values)
end, {sky = {"8FD3FF", "F3C68B"}})
