-- Practice. Screen: 1 pick a line, 2 running (Departing adds the "race is getting ready" banner),
-- 3 finished.
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({Screen = 1, Departing = false}, function(holder, values)
	local View = StoryKit.Load("PracticeView")
	local practice = View.Create(holder, function() end)
	local sizing = StoryKit.OnSize(holder, function(size) View.Layout(practice, size, false) end)
	local join = {id = "Join", text = "Start racing"}
	local screen = math.clamp(math.floor(tonumber(values.Screen) or 1), 1, 3)
	if screen == 2 then
		View.SetHud(practice, {mode = "Running", line = "Normal", elapsed = 12.4, lap = 1, lapCount = 2, padCount = 12, nextIndex = 6, best = 30.88,
			departure = if values.Departing then 6 else nil, course = "City Run"})
	elseif screen == 3 then
		View.ShowModal(practice, {mode = "Finished", line = "Normal", time = 30.34, previous = 30.88, best = 30.34, other = "Hard"}, join, true, false, true)
	else
		View.ShowModal(practice, {mode = "Lines", lines = {{line = "Normal", pads = 12, laps = 2, best = 30.88}, {line = "Hard", pads = 12, laps = 2}}}, join, true, false, true)
	end
	return function() sizing:Disconnect() end
end, {sky = {"8FD3FF", "F3C68B"}})
