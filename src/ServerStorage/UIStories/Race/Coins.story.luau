-- Race HUD with the coin counter showing.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({}, function(holder, values)
	return StoryKit.Race(holder, "Coins", values)
end, {sky = {"8FD3FF", "F3C68B"}})
