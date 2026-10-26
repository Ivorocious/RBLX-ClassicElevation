local fs = require("@lune/fs")
local luau = require("@lune/luau")
for _,path in {"tools/stud-garden/env01/Backup.luau", "tools/stud-garden/env01/Recover.luau"} do
 luau.load(fs.readFile(path), {debugName=path})
 print("Syntax compiled: " .. path)
end
