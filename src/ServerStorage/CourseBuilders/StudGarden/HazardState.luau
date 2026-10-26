--!strict

local HazardState = {}

export type Timing = {
	Clear: number,
	Warning: number,
	Active: number,
	Offset: number?,
}

function HazardState.Phase(elapsed: number, timing: Timing): (string, number)
	local cycle = timing.Clear + timing.Warning + timing.Active
	local age = (math.max(0, elapsed) + (timing.Offset or 0)) % cycle
	if age < timing.Clear then
		return "Clear", age / timing.Clear
	end
	if age < timing.Clear + timing.Warning then
		return "Warning", (age - timing.Clear) / timing.Warning
	end
	return "Active", (age - timing.Clear - timing.Warning) / timing.Active
end

function HazardState.ActiveIntervals(previous: number, current: number, timing: Timing): {{number}}
	local intervals = {}
	if current < previous then
		return intervals
	end
	local cycle = timing.Clear + timing.Warning + timing.Active
	local offset = timing.Offset or 0
	for lap = math.floor((previous + offset) / cycle), math.floor((current + offset) / cycle) do
		local start = lap * cycle - offset + timing.Clear + timing.Warning
		local first, last = math.max(previous, start), math.min(current, start + timing.Active)
		if last > first then
			table.insert(intervals, {math.clamp((first - start) / timing.Active, 0, 1),
				math.clamp((last - start) / timing.Active, 0, 1)})
		end
	end
	return intervals
end

function HazardState.CanContact(active: boolean, eligible: boolean, alive: boolean, now: number,
	recoveryUntil: number, lastRecovery: number?, cooldown: number, elapsedDt: number, maxDt: number): boolean
	return active and eligible and alive and elapsedDt > 0 and elapsedDt <= maxDt
		and recoveryUntil <= now
		and (lastRecovery == nil or now - lastRecovery >= cooldown)
end

return HazardState
