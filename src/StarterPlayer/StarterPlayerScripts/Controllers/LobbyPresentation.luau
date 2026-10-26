--!strict

local Presentation = {}

function Presentation.Duration(value: any): number?
	return if typeof(value)=="number" and value==value and value>0 and value<math.huge then value else nil
end

function Presentation.Phase(state: string?, remaining: number?, duration: number?, held: boolean)
	local finite = typeof(remaining)=="number" and remaining==remaining and remaining<math.huge and remaining>-math.huge
	local timedState = state=="Intermission" or state=="Racing" or state=="Resetting"
	local timed = finite and timedState and not held
	local total = Presentation.Duration(duration)
	local label = if held then "LOBBY OPEN" elseif state=="Intermission" then "INTERMISSION"
		elseif state=="Racing" then "RACING" elseif state=="Resetting" then "PREPARING" else "WAITING"
	return {label=label,time=if timed then Presentation.Timer(remaining) elseif held then "Explore"
		elseif state=="Racing" then "In progress" else "Waiting",timed=timed,
		fraction=if timed and total then math.clamp((remaining :: number)/total,0,1) else nil}
end

function Presentation.Timer(remaining: number?): string
	if remaining == nil or remaining ~= remaining or remaining == math.huge or remaining == -math.huge then return "--:--" end
	local seconds = math.max(0, math.ceil(remaining))
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

function Presentation.Balance(value: any): string
	if typeof(value) ~= "number" or value ~= value or value < 0 or value == math.huge then return "—" end
	local digits = tostring(math.floor(value))
	local formatted = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return formatted:gsub("^,", "")
end

function Presentation.Race(state: string?, status: string, remaining: number?, studioPreview: boolean, ready: boolean)
	local waiting = state == nil or state == "WaitingForPlayers" or state == "Intermission" or state == "Resetting"
	local inLobby = status == "Lobby" or status == "Queued"
	local result = {
		visible = ready and inLobby and (waiting or state == "Racing"),
		heading = "NEXT RACE", timer = "Waiting", status = "Waiting for players",
		queued = false, canEdit = ready and status == "Lobby", canChoose = ready and status == "Lobby" and state == "Racing",
		timed = state == "Intermission" or state == "Racing",
		options = "Choose to start racing, or enter the practice portal.",
	}
	if state == "Intermission" then
		result.timer = Presentation.Timer(remaining)
		result.queued = status == "Queued"
		result.status = if result.queued then "You're in" else "Not queued yet"
		result.options = if result.queued then "You're queued for the next race." else "Choose Join this race while entry is open."
	elseif state == "Racing" then
		result.heading, result.timer, result.status = "RACE IN PROGRESS", Presentation.Timer(remaining), "Join next race"
		result.options = "Full-course replay is unavailable. Watch racers or enter the practice portal until the next race."
	elseif state == "Resetting" then
		result.status, result.timer = "Preparing next race", "Soon"
	elseif studioPreview then
		result.heading, result.timer, result.status = "LOBBY OPEN", "Explore", "Studio preview"
		result.options = "Rounds are held in Studio. Start one with F6."
	end
	return result
end

local function courseImage(event: any, courseId: string?): string?
	if typeof(event) ~= "table" or typeof(event.catalog) ~= "table" or not courseId then return nil end
	for _, entry in event.catalog do
		if typeof(entry) == "table" and entry.id == courseId then return entry.image or "" end
	end
	return nil
end

-- Next-race card for the lobby, from the race-flow snapshot (flow), the race state and the event
-- snapshot. Buttons are ids the controller routes: Join, Break, Watch, RaceOptions, Practice.
function Presentation.Card(flow: any, raceState: string?, event: any, racers: number?): any
	local enrolled = typeof(flow) == "table" and flow.enrolled == true
	local actionLabel = if typeof(flow) == "table" and typeof(flow.actionLabel) == "string" and not enrolled then flow.actionLabel else nil
	local practice = typeof(flow) == "table" and flow.practice
	local canPractice = typeof(practice) == "table" and practice.available == true and practice.inRoom ~= true
	local course = if typeof(flow) == "table" and typeof(flow.courseDisplayName) == "string" and flow.courseDisplayName ~= "" then flow.courseDisplayName else nil
	local courseId = if typeof(flow) == "table" then flow.courseId else nil
	local watchable = typeof(flow) == "table" and typeof(flow.watchTargets) == "table" and #flow.watchTargets > 0
	local tournament = typeof(event) == "table" and event.eventMode == "Tournament" and typeof(event.lineup) == "table" and #event.lineup > 1
	local running = raceState == "Racing" or raceState == "Countdown" or raceState == "RaceEnding"
	local opening = typeof(event) == "table" and (event.phase == "Waiting" or event.phase == "Voting")
	local card: any = {images = {}, primary = actionLabel, pulse = actionLabel ~= nil}
	card.chip = if enrolled then (if running and typeof(flow) == "table" and flow.status ~= "Racing" then "You're in · next race" else "You're in") else nil
	card.right = if enrolled then {id = "Break", text = "Take a break"} elseif canPractice then {id = "Practice", text = "Practice"} else nil
	card.left = {id = "RaceOptions", text = "Race options"}
	if running and course then
		card.heading, card.title = "Racing now", course
		card.line = if typeof(racers) == "number" and racers > 0 then racers .. (if racers == 1 then " racer" else " racers") .. " · entry closed" else "Entry closed"
		if watchable and not enrolled then card.left = {id = "Watch", text = "Watch racers"} end
		local image = courseImage(event, courseId)
		card.images = {image or ""}
	elseif opening or not course then
		local voting = typeof(event) == "table" and event.phase == "Voting"
		card.heading, card.title = "Next race", "Opening vote"
		card.line = if voting then "Pick the first course now" elseif enrolled then "You'll vote when the event starts" else "Join in, then pick the first course"
		if typeof(event) == "table" and typeof(event.catalog) == "table" then
			-- Courses with artwork fill the collage first, so a new course without a picture never shows a blank tile.
			for _, wantArt in {true, false} do
				for _, entry in event.catalog do
					local image = if typeof(entry) == "table" and typeof(entry.image) == "string" then entry.image else ""
					if #card.images < 4 and (image ~= "") == wantArt then table.insert(card.images, image) end
				end
			end
		end
	else
		local number = if tournament and typeof(event.raceIndex) == "number" then string.format(" · Race %d of %d", event.raceIndex, #event.lineup) else ""
		card.heading, card.title = "Up next" .. number, course
		card.line = if typeof(flow.preparation) == "table" and flow.preparation.status == "Failed" then "Couldn't load · try again"
			elseif typeof(flow.preparation) == "table" then "Preparing the course" elseif enrolled then "You're racing next" else "Join in to race"
		card.images = {courseImage(event, courseId) or ""}
	end
	return card
end

return Presentation
