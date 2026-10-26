--!strict
local Progression = {}

export type State = {
	active: boolean,
	finished: boolean,
	lap: number,
	completedLaps: number,
	nextGate: string,
	recoveryGate: string,
	startedAt: number,
	lapStartedAt: number,
	lastAt: number,
	finishedAt: number?,
	recoveries: number,
	generation: number,
	lapTimes: {number},
}

export type Change = {accepted: boolean, reason: string, gate: string?, lap: number, finished: boolean}

local REQUIRED_LAPS = require(script.Parent.Layout).TargetLaps
local NEXT_GATE = {CP1 = "CP2", CP2 = "CP3", CP3 = "F01", F01 = "F00"}

local function validTime(now: number): boolean
	return now == now and now > -math.huge and now < math.huge
end

local function change(state: State, accepted: boolean, reason: string, gate: string?): Change
	return {accepted = accepted, reason = reason, gate = gate, lap = state.lap, finished = state.finished}
end

function Progression.New(now: number): State
	assert(validTime(now), "Progression needs a finite server time")
	return {
		active = false, finished = false, lap = 1, completedLaps = 0,
		nextGate = "F00", recoveryGate = "F00", startedAt = now, lapStartedAt = now,
		lastAt = now, recoveries = 0, generation = 0, lapTimes = {},
	}
end

function Progression.Begin(state: State, now: number): Change
	if not validTime(now) or now < state.lastAt then return change(state, false, "time", nil) end
	state.active, state.finished, state.finishedAt = true, false, nil
	state.lap, state.completedLaps = 1, 0
	state.nextGate, state.recoveryGate = "CP1", "F00"
	state.startedAt, state.lapStartedAt, state.lastAt = now, now, now
	state.recoveries = 0
	state.generation += 1
	table.clear(state.lapTimes)
	return change(state, true, "begin", "F00")
end

-- The server calls this only after validating a continuous forward crossing by its current participant.
function Progression.Pass(state: State, gate: string, now: number): Change
	if not state.active or state.finished then return change(state, false, "inactive", gate) end
	if not validTime(now) or now < state.lastAt then return change(state, false, "time", gate) end
	if gate ~= state.nextGate then return change(state, false, "order", gate) end
	state.lastAt = now
	if gate == "F00" then
		table.insert(state.lapTimes, now - state.lapStartedAt)
		state.completedLaps += 1
		state.recoveryGate = "F00"
		if state.completedLaps == REQUIRED_LAPS then
			state.finished, state.active, state.finishedAt = true, false, now
			state.nextGate = ""
			return change(state, true, "finish", gate)
		end
		state.lap += 1
		state.lapStartedAt, state.nextGate = now, "CP1"
		return change(state, true, "lap", gate)
	end
	local nextGate = NEXT_GATE[gate]
	assert(nextGate ~= nil, "Unexpected progression gate")
	state.nextGate = nextGate
	if gate ~= "F01" then state.recoveryGate = gate end
	return change(state, true, "gate", gate)
end

function Progression.Recover(state: State, now: number): string?
	if not state.active or state.finished or not validTime(now) or now < state.lastAt then return nil end
	state.lastAt = now
	state.recoveries += 1
	return state.recoveryGate
end

function Progression.Snapshot(state: State, now: number)
	local endAt = state.finishedAt or (if validTime(now) then math.max(now, state.lastAt) else state.lastAt)
	return {
		active = state.active, finished = state.finished, lap = state.lap, requiredLaps = REQUIRED_LAPS,
		completedLaps = state.completedLaps, nextGate = state.nextGate, recoveryGate = state.recoveryGate,
		elapsed = math.max(0, endAt - state.startedAt), lapElapsed = math.max(0, endAt - state.lapStartedAt),
		recoveries = state.recoveries, generation = state.generation, lapTimes = table.clone(state.lapTimes),
	}
end

return Progression

