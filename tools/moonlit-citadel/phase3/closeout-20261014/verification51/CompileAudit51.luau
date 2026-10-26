local fs,luau=require('@lune/fs'),require('@lune/luau')
local root='tools/moonlit-citadel/phase3/closeout-20261014/verification51/'
for _,name in {'GeometryAudit49','ExpectedAppearance51','AuditNative51','RunAudit51'} do
	luau.compile(fs.readFile(root..name..'.luau'));print('Compiled '..name)
end
