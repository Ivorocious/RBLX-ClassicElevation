-- Lobby HUD. State: 1 waiting for racers, 2 joined (opening vote next), 3 up next in an event,
-- 4 racing now. Course feeds the next-race card; try a long name.
local StoryKit = require(script.Parent.Parent.StoryKit)
local LobbySetup = require(script.Parent.LobbySetup)

return StoryKit.Story({State = 1, Course = "Keyboard Circuit", Coins = 250}, function(holder, values)
	LobbySetup.Create(holder, values)
	return nil
end)
