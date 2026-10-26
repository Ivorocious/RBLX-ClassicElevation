local fs, luau = require("@lune/fs"), require("@lune/luau")
local path = "tools/keyboard-circuit/phase3/work-m04/EffectLifecycle.client.luau"
luau.load(fs.readFile(path), {debugName = path})
print("M04 EffectLifecycle.client.luau compiles")
