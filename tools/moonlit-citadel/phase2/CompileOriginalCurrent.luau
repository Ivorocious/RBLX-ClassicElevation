local fs, luau, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/serde")
local packet=serde.decode("json",fs.readFile("docs/artifacts/moonlit-citadel/phase2/MC_P2_R06_original_tools03.json"))
for _,row in packet.sources do assert(luau.load(row.source),row.instancePath) end
for _,path in {"src/ServerScriptService/Services/CourseService.luau","src/ServerStorage/CourseBuilders/ManualObstaclePhases.luau","tools/moonlit-citadel/phase2/R06UpdateOriginalTools03.luau"} do assert(luau.load(fs.readFile(path)),path) end
print("Current original diagnostic syntax PASS: 11 temporary sources, CourseService editing handoff, current ManualObstaclePhases, update tool")
