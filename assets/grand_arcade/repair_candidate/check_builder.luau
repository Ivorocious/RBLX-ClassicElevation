local fs = require("@lune/fs")
local luau = require("@lune/luau")
local path = "src/ServerStorage/CourseBuilders/GrandArcade/Builder.luau"
luau.load(fs.readFile(path), {debugName = path})
print("Grand Arcade Builder syntax passed")
