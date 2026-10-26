local fs = require("@lune/fs")
local luau = require("@lune/luau")
local names = {
	"p2_integration_native_server.luau",
	"p2_integration_native_client.luau",
	"p2_integration_native_fault.client.luau",
}
for _, name in names do luau.load(fs.readFile("tools/keyboard-circuit/phase2/" .. name)) end
print("Compiled " .. #names .. " prepared native fixtures; no Roblox code executed")
