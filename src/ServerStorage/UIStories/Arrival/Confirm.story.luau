-- Arrival confirmation card. CustomRacer shows the creator's Save version; SaveError the retry card.
local StoryKit = require(script.Parent.Parent.StoryKit)
local Arrival = require(script.Parent.ArrivalSetup)

return StoryKit.Story({CustomRacer = false, SaveError = false}, function(holder, values)
	local ui, stop = Arrival.Create(holder, values)
	local function noop() end
	if values.SaveError then
		ui.Choice.Visible, ui.Editor.Visible, ui.Brand.Visible = false, true, false
		ui.Dialog.Show("Couldn’t confirm your save. Your look is still here. Retry safely.", "Retry save →", "Back", noop, true)
	elseif values.CustomRacer then
		ui.Choice.Visible, ui.Editor.Visible, ui.Brand.Visible = false, true, false
		ui.Dialog.Show("Save your racer and head to the lobby?", "Save & play →", "Keep editing", noop)
	else
		ui.Highlight(2)
		ui.Dialog.Show("Ready to join with this look?", "Let’s play →", "Go back", noop)
	end
	return stop
end, {sky = {"05091A", "0A1430"}})
