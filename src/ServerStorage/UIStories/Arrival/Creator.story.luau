-- Racer creator ("Make it yours"). Hair, Skin, Top and Legs pick the option number shown.
local StoryKit = require(script.Parent.Parent.StoryKit)
local Arrival = require(script.Parent.ArrivalSetup)

return StoryKit.Story({Hair = 1, Skin = 1, Top = 2, Legs = 7, BonusClaimed = false}, function(holder, values)
	local ui, stop = Arrival.Create(holder, values)
	ui.Choice.Visible, ui.Editor.Visible, ui.Brand.Visible = false, true, false
	ui.EditBonus.Text = if values.BonusClaimed then "Bonus already claimed" else ui.EditBonus.Text
	local Config = StoryKit.Config("OnboardingConfig")
	local function pick(value: number, list: {any}): number return math.clamp(math.floor(value), 1, #list) end
	ui.SetLook({hair = pick(values.Hair, Config.Hair), skin = pick(values.Skin, Config.Skin), top = pick(values.Top, Config.Colors), legs = pick(values.Legs, Config.Colors)})
	return stop
end, {sky = {"05091A", "0A1430"}})
