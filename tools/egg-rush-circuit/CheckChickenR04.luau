local fs,luau=require("@lune/fs"),require("@lune/luau")
for _,name in {"GuardianPeck","ChickenMotion","ChickenPeck","RestartP2/Builder","RestartP2/ChickenKit","RestartP2/ChickenR04"}do
 local path="src/ServerStorage/CourseBuilders/EggRush/"..name..".luau"
 luau.load(fs.readFile(path),{debugName=path})
end
print("Chicken R04 six current production modules compile")
