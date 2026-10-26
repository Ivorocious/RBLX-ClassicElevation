local fs, luau, serde, process = require('@lune/fs'), require('@lune/luau'), require('@lune/serde'), require('@lune/process')
for _, path in process.args do
	if path:match('%.json$') then
		local packet = serde.decode('json', fs.readFile(path))
		for _, row in packet.sources do assert(luau.load(row.source), row.instancePath) end
		print(path .. ': ' .. #packet.sources .. ' exact sources compile')
	else assert(luau.load(fs.readFile(path)), path); print(path .. ': source compiles') end
end
