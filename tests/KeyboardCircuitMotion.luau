local fs = require("@lune/fs")
local luau = require("@lune/luau")
local config = luau.load(fs.readFile("src/ReplicatedStorage/Config/KeyboardCircuitConfig.luau"))()
local states = luau.load(fs.readFile("src/ServerStorage/CourseBuilders/KeyboardCircuit/DropState.luau"))()
local passed = 0
local function check(t, state, alpha)
	local actual, value = states.Get(t, 0, config)
	assert(actual == state and math.abs(value - alpha) < .00001, tostring(t) .. " expected " .. state)
	passed += 1
end
check(0, "Warning", 0)
check(.999, "Warning", 0)
check(1.275, "Drop", .5)
check(1.9, "Contact", 1)
check(2.65, "Return", .5)
check(3.101, "Clear", 0)
check(6.6, "Warning", 0)
for n = 0, 660 do
	local count = 0
	for _,offset in {0, 2.1, 4.2} do
		local state, alpha = states.Get(n / 100, offset, config)
		assert(alpha >= 0 and alpha <= 1)
		if state == "Drop" or state == "Contact" or state == "Return" then count += 1 end
	end
	assert(count < 3, "All drops active together")
end
print("PASS " .. passed .. " phase boundaries; 661 phased coverage samples. Source logic only; live contact remains separate.")
