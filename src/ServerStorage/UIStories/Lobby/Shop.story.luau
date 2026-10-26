-- Shop over the lobby. Styles switches to the Finish styles tab.
local StoryKit = require(script.Parent.Parent.StoryKit)
local LobbySetup = require(script.Parent.LobbySetup)

return StoryKit.Story({Styles = false, Coins = 250}, function(holder, values)
	local Lobby = LobbySetup.Create(holder, values)
	Lobby.ToggleShop(if values.Styles then "Styles" else "Keys")
	return nil
end)
