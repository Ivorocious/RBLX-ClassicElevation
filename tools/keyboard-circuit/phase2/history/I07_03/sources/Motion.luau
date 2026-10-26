--!strict
local Motion = {}

Motion.Defaults = {
	MaxClockStep = .2,
	SweepSpacing = .35,
	MaxSweepSteps = 48,
	MaxQueriesPerFrame = 240,
	SupportRayLength = 7,
	ContactRetry = .35,
	Seesaws = {Period = 9, MaxAngle = 8, Offset = 2.25},
	Fallaway = {Period = 10, Open = 4.8, Warning = 1, Drop = .55, Down = 2, Return = .8, RowDelay = .16, LaneOffset = 5, DropDistance = 11, CrossingAllowance = 3.4},
	Foundry = {Period = 6.6, Warning = 1, Drop = .55, Down = .65, Return = .9, Offset = 2.1, DropDistance = 15},
	Lift = {BoardDwell = 1.2, HighDwell = 2.8, Speed = 6, Travel = 8, ArrivalTolerance = .25},
	Shuttle = {Period = 14, BoardDwell = 3, Outbound = 4, ExitDwell = 3, Speed = 6, Travel = 24, Warning = .8, ArrivalTolerance = .25},
	Sweep = {Period = 7.8, Rest = 2, Warning = 1.1, Outbound = 1.8, FarDwell = 1.1, Return = 1.8, Angle = 100},
	Domino = {Period = 10.4, Rest = .4, Warning = 1, Drop = .8, Clear = 4, ReturnWarning = .9, Return = 1, Offset = 1.25, Angle = 90},
	Shift = {Period = 9, Open = 5, Warning = 1.2, Retract = .65, Closed = 1.4, Return = .75, Offset = 3.4, Travel = 13, CrossingAllowance = 1.8},
}

function Motion.Tuning(kind: string, overrides)
	local values = table.clone(assert(Motion.Defaults[kind], "Unknown mechanism kind " .. kind))
	for key, value in overrides or {} do values[key] = value end
	return values
end

function Motion.NewClock(now: number)
	return {wall = now, elapsed = 0, pausedStalls = 0}
end

function Motion.StepClock(clock, now: number, maximum: number?): (number, number, boolean)
	local previous, dt = clock.elapsed, now - clock.wall
	clock.wall = now
	-- Freeze the warning and actor together rather than skipping an unchecked travel path.
	if dt <= 0 or dt > (maximum or Motion.Defaults.MaxClockStep) then
		if dt > (maximum or Motion.Defaults.MaxClockStep) then clock.pausedStalls += 1 end
		return previous, previous, false
	end
	clock.elapsed += dt
	return previous, clock.elapsed, true
end

local function result(state: string, alpha: number, warning: boolean?, open: boolean?, admission: boolean?)
	return {state = state, alpha = alpha, warning = warning == true, open = open == true, admission = admission == true}
end

function Motion.Fallaway(elapsed: number, lane: number, row: number, config)
	if elapsed < (lane - 1) * config.LaneOffset + (row - 1) * config.RowDelay then return result("Open", 0, false, true, false) end
	local laneTime = (elapsed - (lane - 1) * config.LaneOffset) % config.Period
	local t = (laneTime - (row - 1) * config.RowDelay) % config.Period
	local admitted = laneTime < config.Open - config.CrossingAllowance
	if t < config.Open then return result("Open", 0, false, true, admitted) end
	t -= config.Open
	if t < config.Warning then return result("Warning", 0, true, true, false) end
	t -= config.Warning
	if t < config.Drop then return result("Drop", t / config.Drop) end
	t -= config.Drop
	if t < config.Down then return result("Down", 1) end
	t -= config.Down
	if t < config.Return then return result("Return", 1 - t / config.Return) end
	return result("Settled", 0, false, true, false)
end

function Motion.Foundry(elapsed: number, index: number, config)
	if elapsed < (index - 1) * config.Offset then return result("Clear", 0, false, true, true) end
	local t = (elapsed - (index - 1) * config.Offset) % config.Period
	if t < config.Warning then return result("Warning", 0, true) end
	t -= config.Warning
	if t < config.Drop then return result("Drop", t / config.Drop) end
	t -= config.Drop
	if t < config.Down then return result("Contact", 1) end
	t -= config.Down
	if t < config.Return then return result("Return", 1 - t / config.Return) end
	return result("Clear", 0, false, true, true)
end

function Motion.Shuttle(elapsed: number, config)
	local t = elapsed % config.Period
	if t < config.BoardDwell then return result("Boarding", 0, t >= config.BoardDwell - config.Warning, true, true) end
	t -= config.BoardDwell
	if t < config.Outbound then return result("Outbound", t / config.Outbound) end
	t -= config.Outbound
	if t < config.ExitDwell then return result("Exit", 1, t >= config.ExitDwell - config.Warning, true, true) end
	t -= config.ExitDwell
	return result("Returning", math.max(0, 1 - t / config.Outbound))
end

function Motion.Sweep(elapsed: number, config)
	local t = elapsed % config.Period
	if t < config.Rest then return result("Rest", 0, false, true, true) end
	t -= config.Rest
	if t < config.Warning then return result("Warning", 0, true, true, false) end
	t -= config.Warning
	if t < config.Outbound then return result("Sweep", t / config.Outbound) end
	t -= config.Outbound
	if t < config.FarDwell then return result("FarDwell", 1, true) end
	t -= config.FarDwell
	return result("Return", math.max(0, 1 - t / config.Return), true)
end

function Motion.Domino(elapsed: number, index: number, config)
	if elapsed < (index - 1) * config.Offset then return result("Upright", 0) end
	local t = (elapsed - (index - 1) * config.Offset) % config.Period
	if t < config.Rest then return result("Upright", 0) end
	t -= config.Rest
	if t < config.Warning then return result("Warning", 0, true) end
	t -= config.Warning
	if t < config.Drop then return result("Tip", t / config.Drop) end
	t -= config.Drop
	if t < config.Clear then return result("ClearPassage", 1, false, true, true) end
	t -= config.Clear
	if t < config.ReturnWarning then return result("ResetWarning", 1, true, true, false) end
	t -= config.ReturnWarning
	if t < config.Return then return result("Reset", 1 - t / config.Return, true) end
	return result("Upright", 0)
end

function Motion.Shift(elapsed: number, index: number, config)
	if elapsed < (index - 1) * config.Offset then return result("Open", 0, false, true, true) end
	local t = (elapsed - (index - 1) * config.Offset) % config.Period
	if t < config.Open then return result("Open", 0, false, true, t < config.Open - config.CrossingAllowance) end
	t -= config.Open
	if t < config.Warning then return result("Warning", 0, true, true, false) end
	t -= config.Warning
	if t < config.Retract then return result("Retract", t / config.Retract) end
	t -= config.Retract
	if t < config.Closed then return result("Closed", 1) end
	t -= config.Closed
	return result("Return", math.max(0, 1 - t / config.Return))
end

function Motion.SweepSteps(previous: CFrame, destination: CFrame, radius: number, spacing: number?): number
	local _, angle = previous:ToObjectSpace(destination):ToAxisAngle()
	local travel = (destination.Position - previous.Position).Magnitude + math.abs(angle) * radius
	return math.max(1, math.ceil(travel / (spacing or Motion.Defaults.SweepSpacing)))
end

return Motion
