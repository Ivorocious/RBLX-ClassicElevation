--!strict

local FormatTime = {}

function FormatTime.fromSeconds(seconds: number): string
	local safeSeconds = seconds

	if safeSeconds ~= safeSeconds or safeSeconds < 0 then
		safeSeconds = 0
	end

	local totalMilliseconds = math.floor((safeSeconds * 1000) + 0.5)
	local minutes = math.floor(totalMilliseconds / 60000)
	local remainingMilliseconds = totalMilliseconds % 60000
	local wholeSeconds = math.floor(remainingMilliseconds / 1000)
	local milliseconds = remainingMilliseconds % 1000

	if minutes > 0 then
		return string.format("%d:%02d.%03d", minutes, wholeSeconds, milliseconds)
	end

	return string.format("%d.%03d", wholeSeconds, milliseconds)
end

return FormatTime
