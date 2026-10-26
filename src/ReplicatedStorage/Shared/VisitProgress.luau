--!strict
local VisitProgress = {}

local function finite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function integer(value: any, minimum: number): boolean
	return finite(value) and value % 1 == 0 and value >= minimum
end
local function copy(value: any): any
	if type(value) ~= "table" then return value end
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item) end
	return result
end
local function component(value: any): string
	local text = tostring(value or "")
	return tostring(#text) .. ":" .. text
end

function VisitProgress.Key(info: any): string?
	if type(info) ~= "table" or type(info.courseId) ~= "string" or info.courseId == "" then return nil end
	return component(info.courseId) .. component(info.variant or info.revision or "Unversioned")
		.. component(info.route or "Normal") .. component(info.raceFormat or info.format or "PointToPoint")
		.. component(info.lapCount or info.requiredLaps or 1) .. component(info.checkpointCount)
end

function VisitProgress.New()
	return {races = {}, courses = {}, racesEntered = 0, completions = 0, coursesImproved = 0}
end

function VisitProgress.Enter(state: any, raceId: string, info: any): boolean
	local key = VisitProgress.Key(info)
	if type(raceId) ~= "string" or raceId == "" or not key or state.races[raceId] then return false end
	local course = state.courses[key]
	if not course then
		course = {key = key, courseId = info.courseId, displayName = info.displayName or info.courseDisplayName or info.courseId,
			entries = 0, completions = 0, improved = false, checkpointCount = info.checkpointCount}
		state.courses[key] = course
	end
	course.entries += 1
	state.racesEntered += 1
	state.races[raceId] = {key = key, info = copy(info), resolved = false}
	return true
end

function VisitProgress.Resolve(state: any, result: any, raceInfo: any): boolean
	if type(result) ~= "table" or type(raceInfo) ~= "table" or result.official ~= true then return false end
	local race = state.races[raceInfo.raceId]
	if not race or race.resolved or VisitProgress.Key(raceInfo) ~= race.key then return false end
	local finished = result.status == "Finished"
	if not finished and result.status ~= "DNF" then return false end
	if finished and (not finite(result.finishTime) or result.finishTime <= 0 or not integer(result.placement, 1)) then return false end
	if finished and finite(raceInfo.duration) and result.finishTime > raceInfo.duration then return false end
	local course = state.courses[race.key]
	local previousBest = course.bestTime
	local falls = if race.info.fallsSupported == true and integer(result.falls, 0) then result.falls else nil
	local checkpointCount = race.info.checkpointCount
	local furthest = nil
	if integer(checkpointCount, 0) then
		if integer(result.nextCheckpointIndex, 1) then furthest = math.clamp(result.nextCheckpointIndex - 1, 0, checkpointCount) end
		if type(result.checkpointSplits) == "table" then
			for _, split in ipairs(result.checkpointSplits) do
				if type(split) == "table" and integer(split.checkpointIndex, 1) and split.checkpointIndex <= checkpointCount then
					furthest = math.max(furthest or 0, split.checkpointIndex)
				end
			end
		end
		if furthest ~= nil then course.furthestCheckpoint = math.max(course.furthestCheckpoint or 0, furthest) end
	end
	local improved = false
	if finished then
		course.completions += 1
		state.completions += 1
		improved = previousBest ~= nil and result.finishTime < previousBest
		course.bestTime = if previousBest then math.min(previousBest, result.finishTime) else result.finishTime
		course.bestPlacement = math.min(course.bestPlacement or result.placement, result.placement)
		state.bestPlacement = math.min(state.bestPlacement or result.placement, result.placement)
		if falls ~= nil then
			improved = improved or (course.fewestFalls ~= nil and falls < course.fewestFalls)
			course.fewestFalls = math.min(course.fewestFalls or falls, falls)
			course.lastFalls = falls
		end
		if integer(checkpointCount, 0) then course.furthestCheckpoint = checkpointCount; furthest = checkpointCount end
	end
	if improved and not course.improved then course.improved = true; state.coursesImproved += 1 end
	race.resolved = true
	race.ticket = {
		raceId = raceInfo.raceId, courseId = course.courseId, courseDisplayName = course.displayName,
		status = result.status, official = true,
		placement = if finished then result.placement else nil, finishTime = if finished then result.finishTime else nil,
		falls = falls, furthestCheckpoint = furthest, checkpointCount = checkpointCount,
		previousBestTime = previousBest,
		isVisitBest = finished and previousBest ~= nil and result.finishTime < previousBest,
		message = if finished then (if previousBest ~= nil and result.finishTime < previousBest then "Fastest official run on this course this visit" else "Course completed")
			elseif furthest ~= nil then string.format("Unfinished: reached checkpoint %d of %d", furthest, checkpointCount)
			else "Official run unfinished",
	}
	return true
end

function VisitProgress.Ticket(state: any, raceId: string): any
	local race = state.races[raceId]
	return if race and race.ticket then copy(race.ticket) else nil
end

function VisitProgress.Target(state: any, info: any): any
	local key = VisitProgress.Key(info)
	if not key then return nil end
	local course = state.courses[key]
	if not course or course.completions == 0 then
		local checkpointCount = info.checkpointCount
		local furthest = if course then course.furthestCheckpoint else nil
		if integer(checkpointCount, 1) and (furthest or 0) < checkpointCount then
			local target = (furthest or 0) + 1
			return {kind = "Checkpoint", checkpoint = target, message = "Reach checkpoint " .. target .. " of " .. checkpointCount}
		end
		return {kind = "Finish", message = "Complete this course"}
	end
	if course.fewestFalls ~= nil and course.lastFalls ~= nil and course.lastFalls > 0 then
		local target = math.max(0, course.lastFalls - 1)
		return {kind = "Falls", falls = target, message = "Try to finish with " .. target .. " or fewer falls"}
	end
	-- Expert suggestions require authored support and separate evidence, never an ordinary finish alone.
	if type(info.expertRoute) == "table" and info.expertRoute.supported == true and info.expertRoute.verified == true
		and type(info.expertRoute.id) == "string" and info.expertRoute.id ~= "" and course.completions >= 3 then
		return {kind = "Route", route = info.expertRoute.id, message = "Try the verified " .. info.expertRoute.id .. " route"}
	end
	return {kind = "Time", time = course.bestTime, message = string.format("Beat your visit best of %.2fs", course.bestTime)}
end

function VisitProgress.Snapshot(state: any, info: any?): any
	local courses = {}
	for _, course in pairs(state.courses) do table.insert(courses, copy(course)) end
	table.sort(courses, function(a, b) return a.key < b.key end)
	return {racesEntered = state.racesEntered, completions = state.completions, coursesImproved = state.coursesImproved,
		bestPlacement = state.bestPlacement, courses = courses, target = if info then VisitProgress.Target(state, info) else nil}
end

return VisitProgress
