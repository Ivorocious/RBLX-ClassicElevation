local fs, luau = require("@lune/fs"), require("@lune/luau")
local prefix = "tools/keyboard-circuit/phase3/work-m03/"
local count = 0
for _, directory in {prefix, prefix .. "sources/"} do
 for _, name in fs.readDir(directory) do
  if name:sub(-5) == ".luau" then luau.load(fs.readFile(directory..name), {debugName=name}); count+=1 end
 end
end
print(count .. " scoped map, traversal and audit files compile")
