-- Race HUD: timer, place card, checkpoint ladder and a pass toast.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({Course = "City Run"}, function(holder, values)
	return StoryKit.Race(holder, "Racing", values)
end, {sky = {"8FD3FF", "F3C68B"}})
