-- Checkpoint ribbon. VersusBest adds the gap to your best split.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({VersusBest = false}, function(holder, values)
	return StoryKit.Race(holder, "Checkpoint", values)
end, {sky = {"8FD3FF", "F3C68B"}})
