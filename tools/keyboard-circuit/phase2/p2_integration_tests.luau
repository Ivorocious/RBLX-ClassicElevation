local luau = require("@lune/luau")
local fs = require("@lune/fs")
local prefix = "tools/keyboard-circuit/phase2/staged/"
for _, name in {"Progression.luau", "Phase2Readiness.luau", "KeyboardCircuitPhase2Preview.client.luau"} do
	luau.load(fs.readFile(prefix .. name))
end
local Progression = require("./staged/Progression")
local Readiness = require("./staged/Phase2Readiness")
local checks = 0
local function check(value, message)
	checks += 1
	assert(value, message)
end
local function unchanged(state, callback, message)
	local before = Progression.Snapshot(state, state.lastAt)
	local result = callback()
	check(not result.accepted, message .. " rejected")
	local after = Progression.Snapshot(state, state.lastAt)
	for _, key in {"active", "finished", "lap", "completedLaps", "nextGate", "recoveryGate", "recoveries", "elapsed"} do
		check(before[key] == after[key], message .. " preserved " .. key)
	end
end

local first = Progression.New(0)
unchanged(first, function() return Progression.Pass(first, "CP1", 1) end, "before begin")
check(Progression.Begin(first, 1).accepted, "begin participant")
local second = Progression.New(1)
check(Progression.Begin(second, 1).accepted, "simultaneous independent participant")
check(Progression.Pass(second, "CP1", 2).accepted, "second participant CP1")
check(first.nextGate == "CP1" and first.recoveryGate == "F00", "one participant cannot advance another")

local now = 1
for lap = 1, 3 do
	for _, invalid in {"CP2", "CP3", "F01", "F00", "X01", "S04", ""} do
		unchanged(first, function() return Progression.Pass(first, invalid, now + .1) end, "early " .. invalid)
	end
	for _, gate in {"CP1", "CP2", "CP3", "F01"} do
		now += 10
		local result = Progression.Pass(first, gate, now)
		check(result.accepted and result.reason == "gate", "ordered " .. gate)
		local recovery = if gate == "F01" then "CP3" else gate
		check(first.recoveryGate == recovery, "recovery for " .. gate)
		unchanged(first, function() return Progression.Pass(first, gate, now + .1) end, "duplicate " .. gate)
		local expected = first.nextGate
		check(Progression.Recover(first, now + .2) == recovery, "recover at " .. gate)
		check(first.nextGate == expected and first.lap == lap, "recovery never awards a gate or lap")
	end
	now += 10
	local result = Progression.Pass(first, "F00", now)
	check(result.accepted, "return from F01 into F00")
	check(first.completedLaps == lap, "completed lap count")
	if lap < 3 then
		check(not first.finished and first.nextGate == "CP1" and first.recoveryGate == "F00", "fresh checkpoint order each lap")
	else
		check(first.finished and not first.active and result.reason == "finish", "final F00 completes exactly three laps")
	end
end
unchanged(first, function() return Progression.Pass(first, "F00", now + 1) end, "duplicate finish")
check(Progression.Recover(first, now + 1) == nil, "finished participant cannot recover into active racing")
local final = Progression.Snapshot(first, now + 100)
check(final.elapsed == now - 1 and #final.lapTimes == 3, "finish clock and all lap times freeze")
final.lapTimes[1] = -1
check(first.lapTimes[1] > 0, "snapshot cannot mutate source lap times")
check(Progression.Begin(first, now + 1).accepted and first.generation == 2, "supported fresh begin resets generation")
check(first.completedLaps == 0 and first.recoveries == 0 and #first.lapTimes == 0, "restart clears only course progress")
unchanged(first, function() return Progression.Pass(first, "CP1", 0 / 0) end, "NaN clock")
unchanged(first, function() return Progression.Pass(first, "CP1", math.huge) end, "infinite clock")
unchanged(first, function() return Progression.Pass(first, "CP1", now) end, "stale clock")

local loading = Readiness.New(0, 10)
local result = Readiness.Step(loading, .1, {state = "loading", loaded = 4, total = 8}, true)
check(result.holding and result.loaded == 4, "stable recovery pad can own a loading hold")
result = Readiness.Step(loading, .2, {state = "loading"}, false)
check(not result.holding and result.state == "loading", "departing stable support releases hold")
result = Readiness.Step(loading, 10, {state = "loading"}, true)
check(result.state == "degraded" and not result.holding and result.elapsed == 10, "hard deadline resolves stalled clips")
result = Readiness.Step(loading, 11, {state = "ready"}, true)
check(result.state == "degraded" and not result.holding, "late load cannot reacquire movement")
local ready = Readiness.New(10, 10)
check(Readiness.Step(ready, 10.2, {state = "ready", loaded = 8, total = 8}, true).state == "ready", "resolved clips release immediately")
local respawn = Readiness.New(10, 10)
check(not Readiness.Step(respawn, 10.1, {state = "loading"}, false).holding, "loading without an alive supported character does not hold")
check(Readiness.Step(respawn, 10.2, {state = "loading"}, true).holding, "respawn on permanent recovery pad can hold safely")
check(not Readiness.Cancel(respawn, "respawn").holding, "cancel releases ownership")
check(Readiness.Step(respawn, 10.3, {state = "loading"}, true).state == "cancelled", "cancelled generation never reacquires controls")
local degraded = Readiness.New(0, 10)
check(Readiness.Step(degraded, .2, {state = "degraded", loaded = 7, total = 8, reason = "failed"}, true).state == "degraded", "failed clip still permits play")
local stopped = Readiness.New(0, 10)
check(Readiness.Step(stopped, .2, {state = "stopped"}, true).state == "cancelled", "stopped feedback closes loading")
local clock = Readiness.New(1, 10)
check(Readiness.Step(clock, 0, {}, true).state == "degraded", "bad clock cannot create an endless hold")
local a, b = Readiness.New(0, 10), Readiness.New(0, 10)
Readiness.Step(a, .2, {state = "ready"}, true)
check(Readiness.Step(b, .2, {state = "loading"}, true).holding, "simultaneous client readiness stays independent")

local receipt = {
	scope = "offline pure state and syntax only; no Studio, audio playback, device, crowd or FPS proof",
	checks = checks, passed = true,
	sources = {"Progression.luau", "Phase2Readiness.luau", "KeyboardCircuitPhase2Preview.client.luau"},
	cases = {"ordered CP1/CP2/CP3/F01/F00", "three-lap final completion", "independent participants", "invalid and duplicate gates", "checkpoint recovery", "fresh generation restart", "bounded readiness", "safe support only", "degraded clip", "cancellation", "no late reacquisition"},
}
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/research/p2_integration_pure_receipt.json", require("@lune/serde").encode("json", receipt, true))
print(checks .. " Phase2 integration pure checks passed")
