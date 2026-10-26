-- The lobby HUD flying in after the arrival screen (the same reveal the game plays). Loops.
local StoryKit = require(script.Parent.Parent.StoryKit)
local LobbySetup = require(script.Parent.Parent.Lobby.LobbySetup)

return StoryKit.Story({}, function(holder, values)
	local Lobby = LobbySetup.Create(holder, {State = 1, Coins = 250})
	return StoryKit.Sequence(holder, {
		{name = "Lobby flies in", seconds = 2.2, run = function()
			Lobby.PrepareEntrance()
			task.delay(.35, function() Lobby.RevealEntrance(values.Motion ~= false) end)
			return nil
		end},
		{name = "Settled", seconds = 1.4, run = function() Lobby.FinishEntrance(); return nil end},
	}, {fresh = false})
end)
