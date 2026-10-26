--!strict
local PracticeRun = {}

local function finite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function PracticeRun.New()
	return {sequence = 0, status = "Idle", line = "Normal", nextCheckpoint = 1, falls = 0, best = {}, last = {}}
end

function PracticeRun.Start(state: any, line: string, checkpointCount: number, now: number): boolean
	if (line ~= "Normal" and line ~= "Hard") or not finite(now)
		or not finite(checkpointCount) or checkpointCount < 1 or checkpointCount % 1 ~= 0 then return false end
	state.sequence += 1
	state.status = "Running"
	state.line = line
	state.startedAt = now
	state.finishedAt = nil
	state.nextCheckpoint = 1
	state.checkpointCount = checkpointCount
	state.falls = 0
	state.lastTouchAt = now
	state.message = "Follow the numbered pads."
	state.autoStartBlocked = false
	return true
end

function PracticeRun.Checkpoint(state: any, index: number, now: number, minimumSeconds: number): boolean
	if state.status ~= "Running" or index ~= state.nextCheckpoint or not finite(now)
		or not finite(minimumSeconds) or minimumSeconds < 0
		or now - state.lastTouchAt < minimumSeconds or index > state.checkpointCount then return false end
	state.nextCheckpoint += 1
	state.lastTouchAt = now
	return true
end

function PracticeRun.Finish(state: any, now: number, minimumSeconds: number): boolean
	if state.status ~= "Running" or state.nextCheckpoint <= state.checkpointCount or not finite(now)
		or not finite(minimumSeconds) or minimumSeconds < 0 or now - state.lastTouchAt < minimumSeconds then return false end
	local elapsed = now - state.startedAt
	if elapsed <= 0 then return false end
	state.status = "Finished"
	state.autoStartBlocked = true
	state.finishedAt = now
	state.last[state.line] = elapsed
	local previous = state.best[state.line]
	if previous == nil or elapsed < previous then state.best[state.line] = elapsed end
	state.message = if previous ~= nil and elapsed < previous then "New practice best this visit!" else "Circuit complete. Try again?"
	return true
end

function PracticeRun.Fall(state: any): boolean
	if state.status ~= "Running" then return false end
	state.falls += 1
	return true
end

function PracticeRun.Stop(state: any, reason: string)
	state.status = if reason == "Race departure" then "Interrupted" else "Idle"
	state.startedAt = nil
	state.finishedAt = nil
	state.nextCheckpoint = 1
	state.message = reason
	state.autoStartBlocked = true
end

function PracticeRun.Snapshot(state: any, now: number)
	return {
		status = state.status, line = state.line, attemptId = state.sequence,
		startedAt = state.startedAt,
		elapsed = if state.startedAt then math.max(0, (state.finishedAt or now) - state.startedAt) else 0,
		nextCheckpoint = state.nextCheckpoint, checkpointCount = state.checkpointCount or 0,
		falls = state.falls, bestTime = state.best[state.line], lastTime = state.last[state.line],
		message = state.message or "Choose a practice line.",
	}
end

return PracticeRun
