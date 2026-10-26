local fs, roblox, serde = require('@lune/fs'), require('@lune/roblox'), require('@lune/serde')
local root = 'docs/artifacts/moonlit-citadel/phase3/closeout-20261014/before/'
local bytes = fs.readFile(root..'source49-models.rbxm')
local models = roblox.deserializeModel(bytes)
assert(#models == 2)
local report = {models={}, sources={}, savedModelsReopened=true, nativeSourceParity=true,
	modelHash=serde.hash('sha256',bytes)}
for _, model in models do
	assert(model:GetAttribute('SourceRevision') == 49 and model:GetAttribute('BuildRevision') == 43)
	local counts={descendants=#model:GetDescendants(),parts=0,meshes=0,colliders=0,floors=0,red=0}
	for _, item in model:GetDescendants() do
		if item:IsA('BasePart') then
			counts.parts+=1
			if item:IsA('MeshPart') then counts.meshes+=1 end
			if item.CanCollide then counts.colliders+=1 end
			if item:GetAttribute('MCWalkable') then counts.floors+=1 end
			if item:GetAttribute('MoonlitHazard') then counts.red+=1 end
		end
	end
	assert(counts.descendants==2210 and counts.parts==1381 and counts.meshes==1087)
	assert(counts.colliders==147 and counts.floors==135 and counts.red==55)
	table.insert(report.models,counts)
end
local roots=roblox.deserializeModel(fs.readFile(root..'source49-native-modules.rbxm'))
local modules={}
for _, item in roots do
	if item:IsA('LuaSourceContainer') then modules[item.Name]=item end
	for _, child in item:GetDescendants() do
		if child:IsA('LuaSourceContainer') then modules[child.Name]=child end
	end
end
local packet=serde.decode('json',fs.readFile('docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/final/enclosure_source49_packet.json'))
for _, row in packet.records do
	local item=assert(modules[row.name],'Missing native recovery module '..row.name)
	local hash=serde.hash('sha256',item.Source:gsub('\r\n','\n'))
	assert(hash==row.sha256,'Native source differs '..row.name)
	table.insert(report.sources,{name=row.name,sha256=hash})
end
report.pass=true
fs.writeFile(root..'recovery-verification.json',serde.encode('json',report,true))
print(serde.encode('json',{pass=true,models=report.models,nativeSources=#report.sources,modelHash=report.modelHash}))
