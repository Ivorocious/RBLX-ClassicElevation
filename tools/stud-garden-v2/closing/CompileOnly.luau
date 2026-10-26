local fs=require("@lune/fs")
local luau=require("@lune/luau")
local process=require("@lune/process")
for _,path in process.args do
    luau.load(fs.readFile(path),{debugName=path})
    print("COMPILED_ONLY "..path)
end
