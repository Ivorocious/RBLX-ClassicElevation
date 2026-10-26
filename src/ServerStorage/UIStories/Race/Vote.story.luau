-- Opening-course vote. Courses: how many are eligible (1-6). Picked, Locked (confirmed) and
-- SecondsLeft (5 or less turns the timer urgent).
local StoryKit = require(script.Parent.Parent.StoryKit)

return StoryKit.Story({Courses = 6, Picked = true, Locked = false, SecondsLeft = 9}, function(holder, values)
	local View = StoryKit.Load("GalleryVotingView")
	local function noop() end
	local ui = View.Create(holder, {Hide = noop, Select = noop, Confirm = noop, Search = noop, Remove = noop})
	local catalog = StoryKit.Catalog(math.floor(tonumber(values.Courses) or 6))
	View.Render(ui, {catalog = catalog, picks = if values.Picked or values.Locked then {catalog[1].id} else {},
		timeLeft = math.max(0, tonumber(values.SecondsLeft) or 9), duration = 15, phase = "Voting", pending = false,
		confirmed = values.Locked == true, message = ""})
	return nil
end)
