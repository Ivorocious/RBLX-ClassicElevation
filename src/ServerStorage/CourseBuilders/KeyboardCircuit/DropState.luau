--!strict
local DropState = {}

function DropState.Get(elapsed: number, offset: number, config): (string, number)
	local t = (elapsed + offset) % config.DropPeriod
	local warning, fall, hold, returning = config.DropWarning, config.DropFall, config.DropHold, config.DropReturn
	if t < warning then return "Warning", 0 end
	if t < warning + fall then return "Drop", (t - warning) / fall end
	if t < warning + fall + hold then return "Contact", 1 end
	if t < warning + fall + hold + returning then return "Return", 1 - (t - warning - fall - hold) / returning end
	return "Clear", 0
end

return DropState
