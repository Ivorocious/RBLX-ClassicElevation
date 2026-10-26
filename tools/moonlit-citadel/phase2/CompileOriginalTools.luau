local fs, luau, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/serde")
local packet=serde.decode("json",fs.readFile("docs/artifacts/moonlit-citadel/phase2/MC_P2_R06_original_tools02.json"))
for _,row in packet.sources do assert(luau.load(row.source),row.instancePath) end
assert(luau.load(fs.readFile("tools/moonlit-citadel/phase2/R06UpdateOriginalTools.luau")))
print("Original diagnostic syntax PASS: "..#packet.sources.." copied sources and update tool; arrival is excluded, gameplay execution remains separate")
