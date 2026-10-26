local fs,luau=require('@lune/fs'),require('@lune/luau')
luau.compile(fs.readFile('tools/moonlit-citadel/phase3/closeout-20261014/RecordRenderedSequence.luau'))
print('Prepared renderer probe compiles; no Studio execution')
