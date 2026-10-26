--!strict
-- Builds the arrival screen for its stories the way OnboardingController does in game, without a
-- profile or remotes: your own avatar on the right, the bonus badge, and the Heartbeat that animates
-- the stage and sky.
local Players = game:GetService("Players")
local StoryKit = require(script.Parent.Parent.StoryKit)

local Setup = {}

function Setup.Create(holder: Frame, values: {[string]: any}): (any, () -> ())
	local Screen = StoryKit.Load("ArrivalScreen")
	local Config = StoryKit.Config("OnboardingConfig")
	local Appearance = StoryKit.Shared("RacerAppearance")
	local ui = Screen.Create(holder, true)
	ui.Reopen.Visible, ui.Status.Text = false, ""
	ui.Reward.Text = "+" .. Config.CreationBonus .. " coins"
	local reduced = values.Motion == false
	ui.Stage.SetMotion(not reduced)
	task.spawn(function()
		local ok, description = pcall(function() return Players:GetHumanoidDescriptionFromUserIdAsync(StoryKit.Me()) end)
		if not holder.Parent then return end
		ui.Stage.SetDescription(if ok and description then description else Appearance.Description({hair = 3, skin = 2, top = 3, legs = 2}))
	end)
	local stop = StoryKit.Heartbeat(function(dt) ui.Update(dt, reduced) end)
	return ui, stop
end

return Setup
