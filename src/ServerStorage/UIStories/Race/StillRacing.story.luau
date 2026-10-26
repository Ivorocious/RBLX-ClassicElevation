-- Idle check sticker with its draining bar.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({}, function(holder, values)
	return StoryKit.Race(holder, "Still racing?", values)
end, {sky = {"8FD3FF", "F3C68B"}})
