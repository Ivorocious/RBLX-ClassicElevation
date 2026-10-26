local fs=require('@lune/fs')
local luau=require('@lune/luau')
for _,name in {'Installer','Runtime','FallingHazards','WaveHazards'} do
 local p='src/ServerStorage/CourseBuilders/ShipwreckCove/'..name..'.luau'
 luau.load(fs.readFile(p),{debugName=p})
 print('Compiled '..name)
end
