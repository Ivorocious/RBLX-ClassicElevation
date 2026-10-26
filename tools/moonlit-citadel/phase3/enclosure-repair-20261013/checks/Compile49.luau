local fs,luau,serde=require('@lune/fs'),require('@lune/luau'),require('@lune/serde')
local p=serde.decode('json',fs.readFile('docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/enclosure_source49_packet.json'))
for _,r in p.records do luau.compile(r.source) end
print('compiled '..#p.records..' source49 modules')