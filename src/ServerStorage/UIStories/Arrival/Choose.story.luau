-- Arrival chooser: Create racer or Use my avatar. Hover 1 or 2 lights a side; your own Roblox
-- avatar stands on the right.
local StoryKit = require(script.Parent.Parent.StoryKit)
local Arrival = require(script.Parent.ArrivalSetup)

return StoryKit.Story({Hover = 0, BonusClaimed = false}, function(holder, values)
	local ui, stop = Arrival.Create(holder, values)
	ui.Reward.Visible = not values.BonusClaimed
	ui.Highlight(math.clamp(math.floor(values.Hover), 0, 2))
	return stop
end, {sky = {"05091A", "0A1430"}})
