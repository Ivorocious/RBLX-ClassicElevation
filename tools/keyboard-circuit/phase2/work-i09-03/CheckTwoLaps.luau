local fs, luau = require("@lune/fs"), require("@lune/luau")
local directory = "tools/keyboard-circuit/phase2/work-i09-03/sources/"
local layout = luau.load(fs.readFile(directory .. "Layout.luau"))()
local token = {}
local progression = luau.load(fs.readFile(directory .. "Progression.luau"), {environment = {
 script = {Parent = {Layout = token}}, require = function(module) assert(module == token); return layout end,
}})()
assert(layout.TargetLaps == 2)
local state = progression.New(0)
assert(progression.Begin(state, 0).accepted)
assert(not progression.Pass(state, "F00", 1).accepted)
assert(progression.Recover(state, 2) == "F00" and state.completedLaps == 0 and state.nextGate == "CP1")
local now = 2
for lap = 1, 2 do
 for _,gate in {"CP1", "CP2", "CP3", "F01", "F00"} do
  local midpoint = ({CP1="R1",CP2="R2",CP3="R3",F01="R4"})[gate]
  if midpoint then
   assert(not progression.Checkpoint(state, if midpoint=="R4" then "R1" else "R4", now).accepted)
   now += 1
   local nextGate, completedLaps = state.nextGate, state.completedLaps
   assert(progression.Checkpoint(state, midpoint, now).accepted)
   assert(state.nextGate == nextGate and state.completedLaps == completedLaps)
   assert(progression.Recover(state, now) == midpoint)
   assert(not progression.Checkpoint(state, midpoint, now).accepted)
   assert(not progression.Checkpoint(state, midpoint, 0/0).accepted)
  end
  now += 1
  assert(progression.Pass(state, gate, now).accepted)
 end
 assert(state.completedLaps == lap and state.finished == (lap == 2) and state.checkpointOrdinal == 0)
 if lap == 1 then assert(state.active and state.lap == 2 and state.nextGate == "CP1") end
end
assert(not state.active and state.lap == 2 and state.nextGate == "" and #state.lapTimes == 2)
assert(not progression.Pass(state, "CP1", now + 1).accepted)
assert(progression.Recover(state, now + 1) == nil)
assert(progression.Snapshot(state, now + 50).elapsed == now)
assert(progression.Begin(state, now + 51).accepted)
assert(state.active and not state.finished and state.lap == 1 and state.completedLaps == 0 and state.recoveries == 0 and #state.lapTimes == 0)
print("Two-lap ordered progression and four midpoint saves pass: forward order, duplicate/future rejection, no gate credit, recovery, lap reset and restart")
