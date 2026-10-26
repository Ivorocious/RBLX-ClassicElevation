local fs,luau=require('@lune/fs'),require('@lune/luau')
local root='tools/moonlit-citadel/phase3/closeout-20261014/verification52/'
for _,name in {'GeometryAudit52','PartAdjustmentOracle52','ExpectedAppearance52','AuditNative52','RunAudit52','CompareSavedWorld51To52','CheckSavedReopen52'} do
	luau.compile(fs.readFile(root..name..'.luau'));print('Compiled '..name)
end
