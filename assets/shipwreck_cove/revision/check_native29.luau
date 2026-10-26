local fs=require('@lune/fs')
local roblox=require('@lune/roblox')
local serde=require('@lune/serde')
local args=require('@lune/process').args
local path=args[1]
local roots=roblox.deserializeModel(fs.readFile(path))
assert(#roots==1)
local model=roots[1]
local counts={}
for _,v in model:GetDescendants() do counts[v.ClassName]=(counts[v.ClassName] or 0)+1 end
local result={path=path,name=model.Name,reviewBuild=model:GetAttribute('ReviewBuild'),build=model:GetAttribute('ShipwreckBuild'),classes=counts,bytes=#fs.readFile(path)}
assert(result.build=='SC_MAP_29')
fs.writeFile(path..'.verification.json',serde.encode('json',result,true))
print(serde.encode('json',result))
