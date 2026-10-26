local fs=require("@lune/fs")
local luau=require("@lune/luau")
for _,name in {"Builder","LayoutR02","RevisionR02","HazardKit"} do
 local file="src/ServerStorage/CourseBuilders/EggRush/RestartP2/"..name..".luau"
 luau.load(fs.readFile(file),{debugName=file})
end
luau.load(fs.readFile("src/ServerStorage/CourseBuilders/EggRush/Runtime.luau"),{debugName="EggRush.Runtime"})
print("R02 five source files compile")
