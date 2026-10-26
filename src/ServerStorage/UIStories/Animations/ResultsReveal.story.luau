-- Results opening: podium steps rise, racers pop up, rows slide in and confetti falls. Replays every
-- ReplayEvery seconds; the other controls match the Results story.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({Racers = 8, YourPlace = 2, DNF = true, Course = "Keyboard Circuit"}, function(holder, values)
	StoryKit.Results(holder, values, true)
	return nil
end, {sky = {"1B3A9E", "10215C"}, replay = 7})
