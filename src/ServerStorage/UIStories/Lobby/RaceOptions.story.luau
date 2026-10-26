-- Race options panel (RaceFlowView) over the lobby. Joined shows the enrolled version.
local StoryKit = require(script.Parent.Parent.StoryKit)
local LobbySetup = require(script.Parent.LobbySetup)

return StoryKit.Story({Joined = false, Coins = 250}, function(holder, values)
	LobbySetup.Create(holder, {State = if values.Joined then 2 else 1, Coins = values.Coins})
	local ui, cleanup = StoryKit.FlowPanel(holder)
	local joined = values.Joined == true
	local buttons = if joined
		then {{id = "Break", text = "Take a break"}, {id = "EnterPractice", text = "Enter practice portal"}, {id = "ReduceMotion", text = "Reduce motion"}}
		else {{id = "Join", text = "Start racing"}, {id = "EnterPractice", text = "Enter practice portal"}, {id = "Intro", text = "Show me around"}, {id = "ReduceMotion", text = "Reduce motion"}}
	ui.Show({title = "Race options", body = "1 race entered · 1 completed this visit\nEnter practice portal. Practice is in a separate area.",
		enrolled = joined, enrollment = if joined then "You're in for the next race" else "Choose to join races for this visit", buttons = buttons}, true, false, nil)
	return cleanup
end)
