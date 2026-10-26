-- Lobby dialogs. Panel: 1 Settings, 2 Records, 3 Coins. Records shows that many sample finishes
-- (0 shows the empty state).
local StoryKit = require(script.Parent.Parent.StoryKit)
local LobbySetup = require(script.Parent.LobbySetup)

return StoryKit.Story({Panel = 1, Records = 3, Coins = 250}, function(holder, values)
	local Lobby = LobbySetup.Create(holder, values)
	local panel = math.clamp(math.floor(tonumber(values.Panel) or 1), 1, 3)
	if panel == 1 then
		Lobby.ToggleSettings()
	elseif panel == 2 then
		local placements = {}
		for index = 1, math.clamp(math.floor(tonumber(values.Records) or 0), 0, 8) do
			table.insert(placements, {placement = index, displayName = StoryKit.Names[index], finishTime = 88.4 + index * 5.13, official = true})
		end
		Lobby.UpdateRecords({raceId = "story", courseDisplayName = "Keyboard Circuit", placements = placements})
		Lobby.ToggleRecords()
	else
		Lobby.ToggleCoins()
	end
	return nil
end)
