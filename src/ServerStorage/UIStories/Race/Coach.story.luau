-- First-visit coach card. Step 1-3; the last step adds the Start racing button.
local StoryKit = require(script.Parent.Parent.StoryKit)

-- The same cues as VisitIntroController.
local CUES = {
	{title = "Your racer", message = "This is your racer. Your saved look stays with you in this experience."},
	{title = "Grand Arcade", message = "These arches show the upcoming courses and real finishes. Practice stays open while races run."},
	{title = "Start racing when you're ready", message = "Choose Start racing to join. You'll stay enrolled until you choose Take a break."},
}

return StoryKit.Story({Step = 2}, function(holder, values)
	local View = StoryKit.Load("VisitCoachView")
	local coach = View.Create(holder, function() end)
	coach.plate.Visible = true
	local step = math.clamp(math.floor(tonumber(values.Step) or 2), 1, 3)
	local cue = CUES[step]
	View.Render(coach, {title = cue.title, message = cue.message, step = step, count = 3,
		buttons = if step == 3 then {{id = "Join", text = "Start racing"}} else {}}, false, true)
	local sizing = StoryKit.OnSize(holder, function(size) View.Layout(coach, size, false) end)
	return function() sizing:Disconnect() end
end)
