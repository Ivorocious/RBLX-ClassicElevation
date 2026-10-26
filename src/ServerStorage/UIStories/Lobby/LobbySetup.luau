--!strict
-- Builds the lobby HUD for its stories through LobbyUiController's Edit preview, in one of four
-- states: 1 waiting for racers, 2 joined (opening vote next), 3 up next in an event, 4 racing now.
local StoryKit = require(script.Parent.Parent.StoryKit)

local Setup = {}

function Setup.Create(holder: Frame, values: {[string]: any}): any
	local Lobby = StoryKit.Load("LobbyUiController")
	Lobby.InitPreview(holder, {})
	Lobby.SetPreviewBalance(math.max(0, math.floor(tonumber(values.Coins) or 0)))
	local course = if typeof(values.Course) == "string" and values.Course ~= "" then values.Course else "Keyboard Circuit"
	local courseId = StoryKit.CourseId(course)
	local catalog = StoryKit.Catalog()
	local state = math.clamp(math.floor(tonumber(values.State) or 1), 1, 4)
	if state == 1 or state == 2 then
		Lobby.UpdateEvent({eventMode = "Tournament", phase = "Waiting", catalog = catalog})
		Lobby.UpdateFlow({enrolled = state == 2, actionLabel = if state == 2 then nil else "Start racing", raceId = "story"})
		Lobby.Update("WaitingForPlayers", "Lobby", nil, "-")
	elseif state == 3 then
		local lineup = StoryKit.Lineup(courseId, 2)
		Lobby.UpdateEvent({eventMode = "Tournament", phase = "Racing", catalog = catalog, lineup = lineup, raceIndex = 2})
		Lobby.UpdateFlow({enrolled = true, courseDisplayName = course, courseId = courseId, raceId = "story", preparation = {status = "Preparing"}})
		Lobby.Update("Intermission", "Queued", 20, course, "LapBased", false, 30)
	else
		Lobby.UpdateEvent(nil)
		Lobby.UpdateFlow({enrolled = false, actionLabel = "Join next race", courseDisplayName = course, courseId = courseId, raceId = "story"})
		Lobby.Update("Racing", "Lobby", 80, course, "LapBased", false, 300)
	end
	return Lobby
end

return Setup
