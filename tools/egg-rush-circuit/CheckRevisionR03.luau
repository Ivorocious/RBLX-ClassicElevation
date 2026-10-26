local fs=require("@lune/fs")
local luau=require("@lune/luau")
local files={"Runtime","GuardianPeck","RestartP2/Builder","RestartP2/LayoutR02","RestartP2/RevisionR02","RestartP2/RevisionR03","RestartP2/HazardKit","RestartP2/ReadableKit","RestartP2/Presentation"}
for _,name in files do
 local file="src/ServerStorage/CourseBuilders/EggRush/"..name..".luau"
 luau.load(fs.readFile(file),{debugName=file})
end
for _,name in {"RaceHudView","RaceHudController"} do
 local file="src/StarterPlayer/StarterPlayerScripts/Controllers/"..name..".luau"
 luau.load(fs.readFile(file),{debugName=file})
end
print("R03 eleven production modules compile")
