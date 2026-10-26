local fs,roblox,serde=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde')
local own='tools/moonlit-citadel/phase3/closeout-20261014/verification52/'
local base='docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/'
local planPath='docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan52.json'
local exports=serde.decode('json',fs.readFile(planPath))
assert(exports.schema==1 and #exports.units==243)
local files={
	{base..'enclosure_before_source48_kits.rbxm','9dd5064969613b9b20bfeeb3b04ac61a4eed1c0c7395245e726b5e17a08c4a08'},
	{base..'enclosure_er01_library_verified.rbxm','b07d422330ee003a3b1030438b5f8d227dc6f9d42720da02843cc654226da407'},
}
local names={BL02='MoonlitCitadel_BL02Library',P3='MoonlitCitadel_P3Rework_RW01Library',AR01='MoonlitCitadel_P3ArtRepair_AR01Library',
	TL01='MoonlitCitadel_TowerLandscape_TL01Library',ER01='MoonlitCitadel_Enclosure_ER01Library'}
local libraries,inputs={},{[planPath]=serde.hash('sha256',fs.readFile(planPath))}
for _,file in files do
	local bytes=fs.readFile(file[1]);assert(serde.hash('sha256',bytes)==file[2],'Approved saved library recovery differs '..file[1])
	inputs[file[1]]=file[2]
	for _,lib in roblox.deserializeModel(bytes) do for key,name in names do if lib.Name==name then libraries[key]=lib end end end
end
local function relative(root,item)
	local names={};while item~=root do table.insert(names,1,item.Name);item=item.Parent end;return table.concat(names,'/')
end
local function mesh(part)
	local ok,val=pcall(function()return part.MeshId end)
	if not ok then val=part.MeshContent end
	local raw=tostring(val);local id=raw:match('rbxassetid://(%d+)') or raw:match('[?&]id=(%d+)')
	return if id then 'rbxassetid://'..id else raw
end
local function texture(part)
	local ok,val=pcall(function()return part.TextureID end)
	if not ok then val=part.TextureContent end
	local raw=tostring(val)
	if raw=='nil' or raw=='Content(None)' then return '' end
	local id=raw:match('rbxassetid://(%d+)') or raw:match('[?&]id=(%d+)')
	return if id then 'rbxassetid://'..id else raw
end
local expected,used,parts={}, {},0
for _,data in exports.units do
	local libraryKey=data.library or 'BL02';local key=libraryKey..'/'..data.asset
	if used[key] then continue end;used[key]=true
	local lib=assert(libraries[libraryKey],libraryKey);local asset=assert(lib:FindFirstChild(data.asset),key)
	local row={library=libraryKey,libraryName=lib.Name,asset=data.asset,parts={}}
	for _,p in asset:GetDescendants() do if p:IsA('BasePart') then
		local record={path=relative(asset,p),class=p.ClassName,cf={p.CFrame:GetComponents()},size={p.Size.X,p.Size.Y,p.Size.Z},meshId=mesh(p),
			color={p.Color.R,p.Color.G,p.Color.B},material=tostring(p.Material),materialVariant=p.MaterialVariant,castShadow=p.CastShadow,
			transparency=p.Transparency,sourceMaterial=p:GetAttribute('SourceMaterial'),sourceAsset=p:GetAttribute('SourceAsset'),sourceTriangles=p:GetAttribute('SourceTriangles')}
		record.TextureID=texture(p)
		for _,property in {'DoubleSided','RenderFidelity'} do
			local ok,value=pcall(function()return p[property] end);assert(ok,'Approved MeshPart property unavailable '..property)
			record[property]=if typeof(value)=='EnumItem' then tostring(value) else value
		end
		local collisionReadable,collision=pcall(function()return p.CollisionFidelity end)
		if collisionReadable then record.CollisionFidelity=tostring(collision) else record.unavailableSavedProperties={'CollisionFidelity'} end
		table.insert(row.parts,record);parts+=1
	end end
	table.sort(row.parts,function(a,b)return a.path<b.path end);table.insert(expected,row)
end
table.sort(expected,function(a,b)return a.library..'/'..a.asset<b.library..'/'..b.asset end)
local output={schema=1,sourcePlanSHA256=inputs[planPath],expectedUnits=243,expectedMeshes=639,expectedTriangles=198722,
	approvedSource49Libraries=true,templates=expected,uniqueTemplateParts=parts,inputHashes=inputs,
	er01={assetId='83390081804897',nativeVerticesSHA256='10da46e53127ed4b8ce8bf8a851145f0118a8ca570463643b6338e5ec0d94e0f'}}
fs.writeFile(own..'approved-templates52.json',serde.encode('json',output,true))
print(serde.encode('json',{templates=#expected,uniqueTemplateParts=parts,inputHashes=inputs}))
