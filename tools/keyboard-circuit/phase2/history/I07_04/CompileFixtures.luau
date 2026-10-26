local fs, luau = require("@lune/fs"), require("@lune/luau")
for _,name in {"Setup","Driver","Timing","Race"} do luau.load(fs.readFile("tools/keyboard-circuit/phase2/work-i07/"..name..".client.luau"), {debugName=name}) end
luau.load(fs.readFile("tools/keyboard-circuit/phase2/work-i07/CreateCandidate.luau"))
print("Five I07 build/traversal fixture files compile")
