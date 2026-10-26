local fs,luau=require('@lune/fs'),require('@lune/luau')
local root='tools/moonlit-citadel/phase3/closeout-20261014/verification-draft/'
for _,name in {'GeometryAudit49','ExpectedAppearance50','AuditNative50','RunAudit50'} do
	luau.compile(fs.readFile(root..name..'.luau'));print('Compiled '..name)
end
