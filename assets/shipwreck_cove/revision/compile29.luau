local fs=require('@lune/fs')
local luau=require('@lune/luau')
local paths={
 'src/ServerScriptService/Services/CourseService.luau',
 'src/ReplicatedStorage/Config/ShipwreckConfig.luau',
 'src/ReplicatedStorage/Shared/ShipwreckHazards.luau',
}
for _,name in {'Installer','Runtime','Authoring','FallingHazards','WaveHazards','Crumble','Layout','Kit'} do
 table.insert(paths,'src/ServerStorage/CourseBuilders/ShipwreckCove/'..name..'.luau')
end
for _,path in paths do
 luau.load(fs.readFile(path),{debugName=path})
 print('Compiled '..path)
end
