-- Watching another racer. Loading shows "Finding a racer…"; try a long Name.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({Name = "Mia", Place = 2, Loading = false}, function(holder, values)
	local View = StoryKit.Load("WatchView")
	local view = View.Create(holder, function() end)
	local sizing = StoryKit.OnSize(holder, function(size) View.Layout(view, size, false) end)
	View.Set(view, {userId = StoryKit.Me(), name = values.Name, loading = values.Loading == true,
		place = math.max(1, math.floor(tonumber(values.Place) or 2)), total = 8, checkpoint = 7, checkpoints = 9, remaining = 41})
	return function() sizing:Disconnect() end
end, {sky = {"8FD3FF", "F3C68B"}})
