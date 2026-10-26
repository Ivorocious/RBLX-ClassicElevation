-- Course completed ticket after a finish.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({}, function(holder, values)
	return StoryKit.Race(holder, "Finish ticket", values)
end, {sky = {"8FD3FF", "F3C68B"}})
