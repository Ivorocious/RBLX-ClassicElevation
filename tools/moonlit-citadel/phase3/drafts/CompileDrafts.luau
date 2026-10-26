local fs = require("@lune/fs")
local luau = require("@lune/luau")
local root = "tools/moonlit-citadel/phase3/drafts/"
for _, name in {"RUNTIME_INTEGRATION.luau", "MoonlitCitadelAmbienceConfig.luau", "AmbienceGate.luau"} do
	assert(luau.load(fs.readFile(root .. name)), name)
	print("Compiled " .. name)
end
