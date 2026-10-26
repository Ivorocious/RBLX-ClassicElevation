-- Race results. Racers: how many finished (1-12; 3 or fewer centres the podium). YourPlace: your
-- finish (0 = not in the race). DNF adds a racer who ran out of time. LongNames tests name fitting.
-- SingleRace shows "This visit" instead of the event strip. The reveal is in Animations/Results reveal.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({Racers = 8, YourPlace = 2, DNF = true, LongNames = false, SingleRace = false, Course = "Keyboard Circuit"}, function(holder, values)
	StoryKit.Results(holder, values, false)
	return nil
end, {sky = {"1B3A9E", "10215C"}})
