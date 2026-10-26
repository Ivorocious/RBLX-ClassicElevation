local fs=require("@lune/fs")
local luau=require("@lune/luau")
local process=require("@lune/process")
for _,path in process.args do luau.compile(fs.readFile(path)); print("PASS "..path) end
