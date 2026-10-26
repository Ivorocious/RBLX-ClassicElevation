local fs,roblox=require("@lune/fs"),require("@lune/roblox")
local library=roblox.deserializeModel(fs.readFile("docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/enclosure_er01_library_verified.rbxm"))[1]
local part=library:FindFirstChildWhichIsA("MeshPart",true)
for _,key in {"MeshId","MeshContent","TextureID","TextureContent","MeshSize"} do local ok,value=pcall(function()return part[key]end);print(key,ok,tostring(value))end
