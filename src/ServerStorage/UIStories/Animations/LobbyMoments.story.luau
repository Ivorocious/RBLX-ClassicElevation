-- Lobby moments in order: the YOU'RE IN! stamp on joining, a race-winner toast, a dialog sliding up,
-- the shop popping open, the coins panel, and the phase timer's last five seconds. Loops.
local StoryKit = require(script.Parent.Parent.StoryKit)
local LobbySetup = require(script.Parent.Parent.Lobby.LobbySetup)

return StoryKit.Story({}, function(holder, _values)
	local Lobby = LobbySetup.Create(holder, {State = 1, Coins = 250})
	local function joined(value: boolean)
		Lobby.UpdateFlow({enrolled = value, actionLabel = if value then nil else "Start racing", raceId = "story"})
	end
	return StoryKit.Sequence(holder, {
		{name = "Join: YOU'RE IN!", seconds = 2.6, run = function() Lobby.ClosePanel(); joined(false); joined(true); return nil end},
		{name = "Race winner toast", seconds = 2.4, run = function() Lobby.PreviewToast("Mia", "won Keyboard Circuit", "1:33.53"); return nil end},
		{name = "Dialog slides up", seconds = 2.2, run = function() Lobby.ToggleSettings(); return nil end},
		{name = "Shop pops open", seconds = 2.6, run = function() Lobby.ClosePanel(); Lobby.ToggleShop(); return nil end},
		{name = "Coins panel", seconds = 2.2, run = function() Lobby.ClosePanel(); Lobby.ToggleCoins(); return nil end},
		{name = "Last five seconds", seconds = 5.6, run = function()
			Lobby.ClosePanel(); joined(false)
			local running = true
			task.spawn(function()
				for left = 5, 1, -1 do
					if not running then return end
					Lobby.Update("Intermission", "Lobby", left, "Keyboard Circuit", "LapBased", false, 30)
					task.wait(1)
				end
			end)
			return function() running = false; Lobby.Update("WaitingForPlayers", "Lobby", nil, "-") end
		end},
	}, {fresh = false})
end)
