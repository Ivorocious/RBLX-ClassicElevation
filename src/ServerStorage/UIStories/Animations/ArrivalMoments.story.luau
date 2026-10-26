-- Arrival chooser in motion: the spotlight, floor ring and wave move to each racer as the pointer
-- would, then the confirmation card rises in and closes. Loops.
local StoryKit = require(script.Parent.Parent.StoryKit)
local Arrival = require(script.Parent.Parent.Arrival.ArrivalSetup)

return StoryKit.Story({}, function(holder, values)
	local ui, stopStage = Arrival.Create(holder, values)
	local function noop() end
	local stop = StoryKit.Sequence(holder, {
		{name = "Hover Create racer", seconds = 2.8, run = function() ui.Dialog.Close(); ui.Highlight(1); return nil end},
		{name = "Hover Use my avatar", seconds = 2.8, run = function() ui.Highlight(2); return nil end},
		{name = "Confirmation card", seconds = 3, run = function() ui.Dialog.Show("Ready to join with this look?", "Let’s play →", "Go back", noop); return nil end},
		{name = "Back to the choice", seconds = 1.6, run = function() ui.Dialog.Close(); ui.Highlight(0); return nil end},
	}, {fresh = false})
	return function() stop(); stopStage() end
end, {sky = {"05091A", "0A1430"}})
