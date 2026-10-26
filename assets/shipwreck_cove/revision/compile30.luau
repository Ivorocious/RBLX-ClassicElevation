local fs=require('@lune/fs')
local luau=require('@lune/luau')
for _,name in {'Installer','Runtime','Authoring','Crumble','Layout','Kit'} do
    local path='src/ServerStorage/CourseBuilders/ShipwreckCove/'..name..'.luau'
    luau.load(fs.readFile(path),{debugName=path})
end
local client='src/StarterPlayer/StarterPlayerScripts/ShipwreckOcean.client.luau'
luau.load(fs.readFile(client),{debugName=client})
print('Seven candidate Luau sources compiled')
