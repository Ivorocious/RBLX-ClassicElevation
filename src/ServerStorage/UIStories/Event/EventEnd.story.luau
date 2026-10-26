-- Event end ("Tournament complete"). YouWon: which race you won (0 = none). LongName gives one
-- winner a long name. Finale shows the Exit celebration pill instead.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({YouWon = 4, LongName = false, Finale = false}, function(holder, values)
	return StoryKit.EventEnd(holder, values)
end, {sky = {"1B3A9E", "10215C"}})
