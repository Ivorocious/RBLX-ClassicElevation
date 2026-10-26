local fs,luau=require("@lune/fs"),require("@lune/luau")
local own="tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/geometry/"
for _,name in {"AuditNative49.luau","CheckFrozen49.luau"} do luau.compile(fs.readFile(own..name));print("Compiled "..name) end
