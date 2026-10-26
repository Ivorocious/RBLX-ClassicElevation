--!strict
-- Pure presentation rules for the race screens. No services, so the Lune checks can load it.
-- Live places are worked out from RaceResultsUpdated progress for display only; the official
-- place still comes from the server at the finish.
local Presentation = {}

function Presentation.Ordinal(place: number): string
	local lastTwo = place % 100
	if lastTwo >= 11 and lastTwo <= 13 then return "TH" end
	local last = place % 10
	return if last == 1 then "ST" elseif last == 2 then "ND" elseif last == 3 then "RD" else "TH"
end

local function finite(value: any): boolean
	return typeof(value) == "number" and value == value and value > -math.huge and value < math.huge
end

-- Race clock text such as 1:07.2 (decimals 1) or 1:42.38 (decimals 2); never rounds up.
function Presentation.Clock(seconds: any, decimals: number?): string
	if not finite(seconds) then return "–" end
	local places = decimals or 1
	local step = 10 ^ places
	local value = math.floor(math.max(0, seconds :: number) * step + 1e-6) / step
	local minutes = math.floor(value / 60)
	local rest = value - minutes * 60
	if places <= 0 then return string.format("%d:%02d", minutes, math.floor(rest)) end
	return string.format("%d:%0" .. (3 + places) .. "." .. places .. "f", minutes, rest)
end

-- Whole-second countdown such as 0:41.
function Presentation.Remaining(seconds: any): string
	if not finite(seconds) then return "–" end
	local whole = math.max(0, math.ceil(seconds :: number))
	return string.format("%d:%02d", math.floor(whole / 60), whole % 60)
end

local function number(value: any, fallback: number): number
	return if finite(value) then value :: number else fallback
end

-- Progress steps for the climb ladder: every checkpoint on every lap, then the finish line as
-- the last step, so reaching the final checkpoint is never drawn as finished.
function Presentation.Steps(result: any, race: any?): (number, number)
	local count = math.max(0, math.floor(number(result.checkpointCount, number(race and race.checkpointCount, 0))))
	local laps = math.max(1, math.floor(number(result.requiredLaps, number(race and race.requiredLaps, 1))))
	local total = count * laps + 1
	if result.status == "Finished" then return total, total end
	local lap = math.clamp(math.floor(number(result.currentLap, 1)), 1, laps)
	local done = math.floor(number(result.nextCheckpointIndex, 1)) - 1
	-- The server sends a checkpoint's split before its progress update; count the split already.
	if typeof(result.checkpointSplits) == "table" then
		for _, split in result.checkpointSplits do
			if typeof(split) == "table" and finite(split.checkpointIndex) and math.floor(number(split.lap, 1)) == lap then
				done = math.max(done, split.checkpointIndex)
			end
		end
	end
	done = math.clamp(done, 0, count)
	return math.min(total - 1, (lap - 1) * count + done), total
end

local function reachedAt(result: any): number
	local latest = 0
	if typeof(result.checkpointSplits) == "table" then
		for _, split in result.checkpointSplits do
			if typeof(split) == "table" and finite(split.elapsedTime) then latest = math.max(latest, split.elapsedTime) end
		end
	end
	return latest
end

export type Standing = {
	userId: number,
	name: string,
	steps: number,
	total: number,
	finished: boolean,
	dnf: boolean,
	placement: number?,
	finishTime: number?,
	falls: number,
	at: number,
}

local function standing(result: any, race: any): Standing?
	if typeof(result) ~= "table" or typeof(result.userId) ~= "number" or result.official == false then return nil end
	local steps, total = Presentation.Steps(result, race)
	local name = if typeof(result.displayName) == "string" and result.displayName ~= "" then result.displayName
		elseif typeof(result.name) == "string" then result.name else "Racer"
	return {
		userId = result.userId, name = name, steps = steps, total = total,
		finished = result.status == "Finished", dnf = result.status == "DNF",
		placement = if finite(result.placement) then result.placement else nil,
		finishTime = if finite(result.finishTime) then result.finishTime else nil,
		falls = math.max(0, math.floor(number(result.falls, 0))), at = reachedAt(result),
	}
end

-- Official racers in live order: finishers by placement, then racers still running by progress
-- (earlier arrival breaks ties), then unfinished runs.
function Presentation.Standings(race: any): {Standing}
	local finished, running, out = {}, {}, {}
	if typeof(race) ~= "table" then return {} end
	local seen: {[number]: boolean} = {}
	local function collect(list: any, into: {Standing})
		if typeof(list) ~= "table" then return end
		for _, result in list do
			local row = standing(result, race)
			if row and not seen[row.userId] then seen[row.userId] = true; table.insert(into, row) end
		end
	end
	collect(race.placements, finished)
	collect(race.activeRacers, running)
	collect(race.dnfs, out)
	table.sort(finished, function(a, b) return (a.placement or math.huge) < (b.placement or math.huge) end)
	local function byProgress(a: Standing, b: Standing): boolean
		if a.steps ~= b.steps then return a.steps > b.steps end
		if a.at ~= b.at then return a.at < b.at end
		return a.userId < b.userId
	end
	table.sort(running, byProgress)
	table.sort(out, byProgress)
	local rows = {}
	for _, list in {finished, running, out} do for _, row in list do table.insert(rows, row) end end
	return rows
end

function Presentation.PlaceOf(rows: {Standing}, userId: number): number?
	for index, row in rows do if row.userId == userId then return index end end
	return nil
end

-- Who you passed or who passed you between two standings, ignoring finishes and unfinished runs.
function Presentation.Overtakes(before: {Standing}, after: {Standing}, userId: number): (string?, string?)
	local oldPlace, newPlace = Presentation.PlaceOf(before, userId), Presentation.PlaceOf(after, userId)
	if not oldPlace or not newPlace then return nil, nil end
	local oldAhead: {[number]: boolean} = {}
	for index, row in before do if index < oldPlace then oldAhead[row.userId] = true end end
	local passed, passedBy = {}, {}
	for index, row in after do
		if row.userId ~= userId and not row.dnf then
			local ahead = index < newPlace
			local wasAhead = oldAhead[row.userId] == true
			local wasListed = Presentation.PlaceOf(before, row.userId) ~= nil
			if wasListed and wasAhead and not ahead then table.insert(passed, row.name) end
			if wasListed and not wasAhead and ahead and not row.finished then table.insert(passedBy, row.name) end
		end
	end
	local function describe(names: {string}): string?
		if #names == 0 then return nil end
		if #names == 1 then return names[1] end
		return #names .. " racers"
	end
	return describe(passed), describe(passedBy)
end

function Presentation.FindResult(race: any, userId: number): any
	if typeof(race) ~= "table" then return nil end
	for _, key in {"placements", "dnfs", "activeRacers"} do
		local list = race[key]
		if typeof(list) == "table" then
			for _, result in list do
				if typeof(result) == "table" and result.userId == userId then return result end
			end
		end
	end
	return nil
end

export type CheckpointMoment = {
	key: string,
	checkpoint: number,
	count: number,
	lap: number,
	laps: number,
	split: number,
	delta: number?,
	final: boolean,
}

-- The newest split in a result, described for the checkpoint ribbon.
function Presentation.LatestCheckpoint(result: any, race: any?): CheckpointMoment?
	if typeof(result) ~= "table" or typeof(result.checkpointSplits) ~= "table" then return nil end
	local latest: any = nil
	for _, split in result.checkpointSplits do
		if typeof(split) == "table" and finite(split.elapsedTime) and finite(split.checkpointIndex)
			and (latest == nil or split.elapsedTime >= latest.elapsedTime) then latest = split end
	end
	if not latest then return nil end
	local count = math.max(1, math.floor(number(result.checkpointCount, number(race and race.checkpointCount, latest.checkpointIndex))))
	local laps = math.max(1, math.floor(number(result.requiredLaps, number(race and race.requiredLaps, 1))))
	local lap = math.clamp(math.floor(number(latest.lap, 1)), 1, laps)
	return {
		key = lap .. ":" .. latest.checkpointIndex,
		checkpoint = latest.checkpointIndex, count = count, lap = lap, laps = laps,
		split = latest.elapsedTime,
		delta = if finite(latest.deltaFromPersonalBest) then latest.deltaFromPersonalBest else nil,
		final = latest.checkpointIndex >= count and lap >= laps,
	}
end

-- Whether the finish ticket shows a completed run; anything else is an unfinished run.
function Presentation.TicketFinished(ticket: any): boolean
	return typeof(ticket) == "table" and ticket.status == "Finished" and ticket.official == true
end

-- Course card line such as "9 checkpoints · point to point".
function Presentation.CourseLine(race: any): string
	local parts = {}
	if typeof(race) ~= "table" then return "" end
	if finite(race.racers) and race.racers > 0 then table.insert(parts, race.racers .. (if race.racers == 1 then " racer" else " racers")) end
	if finite(race.checkpointCount) and race.checkpointCount > 0 then
		table.insert(parts, race.checkpointCount .. (if race.checkpointCount == 1 then " checkpoint" else " checkpoints"))
	end
	local laps = number(race.lapCount, number(race.requiredLaps, 1))
	if race.raceFormat == "LapBased" or laps > 1 then table.insert(parts, laps .. " laps")
	elseif race.raceFormat == "PointToPoint" then table.insert(parts, "point to point") end
	return table.concat(parts, " · ")
end

-- "Race 2 of 5" inside a 5-race event; nil in a single race.
-- Player-facing course name: drops build-version tags such as "City Run V3" -> "City Run".
function Presentation.CourseName(name: any): any
	if typeof(name) ~= "string" then return name end
	return (string.gsub(name, "%s+[Vv]%d+$", ""))
end

function Presentation.RaceNumber(event: any, courseId: string?): string?
	if typeof(event) ~= "table" or event.eventMode ~= "Tournament" or typeof(event.lineup) ~= "table" or #event.lineup < 2 then return nil end
	local index = event.raceIndex
	if not finite(index) then return nil end
	-- The server may already point past this course (after the last race raceIndex runs off the end).
	if courseId and event.lineup[index] ~= courseId then
		for position, entry in event.lineup do if entry == courseId then index = position end end
	end
	return string.format("Race %d of %d", math.clamp(index, 1, #event.lineup), #event.lineup)
end

return Presentation
