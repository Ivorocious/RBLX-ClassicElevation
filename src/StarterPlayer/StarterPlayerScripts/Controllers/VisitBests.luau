--!strict
-- The local player's fastest official finish per course this visit, from race results the client
-- already receives. Display only; nothing is saved.
local Players = game:GetService("Players")

local Bests = {}
local times: {[string]: number} = {}

function Bests.Record(results: any)
	local player = Players.LocalPlayer
	if typeof(results) ~= "table" or typeof(results.courseId) ~= "string" or typeof(results.placements) ~= "table" or not player then return end
	for _, entry in results.placements do
		if typeof(entry) == "table" and entry.userId == player.UserId and typeof(entry.finishTime) == "number" and entry.finishTime > 0 then
			local previous = times[results.courseId]
			if not previous or entry.finishTime < previous then times[results.courseId] = entry.finishTime end
		end
	end
end

function Bests.Get(courseId: string): number?
	return times[courseId]
end

return Bests
