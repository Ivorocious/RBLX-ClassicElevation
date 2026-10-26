-- Last-checkpoint ribbon.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({}, function(holder, values)
	return StoryKit.Race(holder, "Final stretch", values)
end, {sky = {"8FD3FF", "F3C68B"}})
