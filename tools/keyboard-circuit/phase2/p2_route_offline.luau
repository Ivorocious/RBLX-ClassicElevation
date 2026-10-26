local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local base = "tools/keyboard-circuit/phase2/staged/"
local compiled = {}
for _,name in {"Motion", "Layout", "Mechanisms", "MechanismRuntime"} do
	luau.load(fs.readFile(base .. name .. ".luau"), {debugName = name})
	table.insert(compiled, name)
end
local environment = {}
for key, value in roblox do environment[key] = value end
local Motion = luau.load(fs.readFile(base .. "Motion.luau"), {environment = environment})()
local Layout = luau.load(fs.readFile(base .. "Layout.luau"), {environment = environment})()
local xml = fs.readFile("docs/artifacts/keyboard-circuit/keyboard-circuit.drawio")
assert(#Layout.Sequences == 16 and #Layout.Main == 21)
for i, id in Layout.Main do
	assert(xml:find('source="' .. id .. '" target="' .. Layout.Main[i % #Layout.Main + 1] .. '"', 1, true), "Missing native edge " .. id)
end
for _,branch in Layout.Branches do
	assert(xml:find('source="' .. branch.from .. '" target="' .. branch.id .. '"', 1, true))
	assert(xml:find('source="' .. branch.id .. '" target="' .. branch.before .. '"', 1, true))
end
local foundrySamples, overlapMaximum, followerSamples, warningSamples = 0, 0, 0, 0
local config = Motion.Defaults.Foundry
for n = 0, 1320 do
	local busy = 0
	for i = 1, 3 do
		local state = Motion.Foundry(n / 100, i, config)
		assert(state.alpha >= 0 and state.alpha <= 1)
		if state.state == "Drop" or state.state == "Contact" or state.state == "Return" then busy += 1 end
	end
	assert(busy < 3, "Foundry blocks all lanes together")
	overlapMaximum = math.max(overlapMaximum, busy)
	foundrySamples += 1
end
for lane = 1, 2 do
	for n = 0, 999 do
		local arrival = n / 100
		local gate = Motion.Fallaway(arrival, lane, 1, Motion.Defaults.Fallaway)
		if not gate.admission then continue end
		for _,followDelay in {0, .35, .7} do
			for _,fraction in {0, .25, .5, .75, 1} do
				local row = math.clamp(math.ceil(fraction * 3), 1, 3)
				local state = Motion.Fallaway(arrival + followDelay + fraction * 2.7, lane, row, Motion.Defaults.Fallaway)
				assert(state.open, "Admitted follower loses the fallaway route")
				followerSamples += 1
			end
		end
	end
end
for _,kind in {"Fallaway", "Foundry", "Sweep", "Domino", "Shift"} do
	local tuning = Motion.Defaults[kind]
	for n = 0, math.floor(tuning.Period * 100) do
		local state = if kind == "Fallaway" then Motion.Fallaway(n / 100, 1, 1, tuning) else if kind == "Sweep" then Motion.Sweep(n / 100, tuning) else Motion[kind](n / 100, 1, tuning)
		assert(state.alpha >= -1e-7 and state.alpha <= 1 + 1e-7, kind .. " out of range")
		if state.warning then warningSamples += 1 end
		if state.admission then assert(state.open, kind .. " admits on absent support") end
	end
end
local clock = Motion.NewClock(0)
assert(select(3, Motion.StepClock(clock, .1)))
assert(not select(3, Motion.StepClock(clock, 1)))
assert(clock.elapsed == .1 and clock.pausedStalls == 1)
assert(select(3, Motion.StepClock(clock, 1.1)))
local output = {
	status = "passed", sourceRevision = Layout.Revision, compiled = compiled,
	sequences = #Layout.Sequences, nativeNormalEdges = #Layout.Main, nativeExpertEdges = 4,
	foundrySamples = foundrySamples, maxSimultaneousDropPaths = overlapMaximum,
	admittedFollowerSupportSamples = followerSamples, warningSamples = warningSamples,
	stallClock = "warning and scripted motion freeze together",
	limits = "Offline syntax and source math. No Studio contact, physical support, player input, crowd, frame time, FPS, device, sound or full-race proof.",
}
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/research/p2_route_offline_receipt.json", serde.encode("json", output, true))
print(serde.encode("json", output, true))
