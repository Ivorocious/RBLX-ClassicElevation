--!strict
local Readiness = {}

export type State = {
	state: string,
	reason: string,
	startedAt: number,
	lastAt: number,
	timeout: number,
	elapsed: number,
	loaded: number,
	total: number,
	holding: boolean,
}

local function validTime(now: number): boolean
	return now == now and now > -math.huge and now < math.huge
end

function Readiness.New(now: number, timeout: number): State
	assert(validTime(now), "Readiness needs a finite clock")
	assert(timeout == timeout and timeout > 0 and timeout <= 30, "Readiness must resolve within 30 seconds")
	return {
		state = "loading", reason = "preparing", startedAt = now, lastAt = now, timeout = timeout,
		elapsed = 0, loaded = 0, total = 8, holding = false,
	}
end

function Readiness.Step(state: State, now: number, audio: any, safePad: boolean)
	if state.state ~= "loading" then return table.clone(state) end
	if not validTime(now) or now < state.lastAt then
		state.state, state.reason, state.holding = "degraded", "clock", false
		return table.clone(state)
	end
	state.lastAt, state.elapsed = now, now - state.startedAt
	if type(audio) == "table" then
		if type(audio.loaded) == "number" then state.loaded = math.clamp(audio.loaded, 0, 8) end
		if type(audio.total) == "number" then state.total = math.clamp(audio.total, 0, 8) end
	end
	if state.elapsed >= state.timeout then
		state.state, state.reason = "degraded", "deadline"
	elseif type(audio) == "table" and (audio.state == "ready" or audio.state == "degraded") then
		state.state, state.reason = audio.state, audio.reason or audio.state
	elseif type(audio) == "table" and (audio.state == "stopped" or audio.state == "cancelled") then
		state.state, state.reason = "cancelled", audio.state
	end
	-- A load hold is allowed only on a permanent recovery pad, never on an active mechanism.
	state.holding = state.state == "loading" and safePad
	return table.clone(state)
end

function Readiness.Cancel(state: State, reason: string)
	state.state, state.reason, state.holding = "cancelled", reason, false
	return table.clone(state)
end

return Readiness

