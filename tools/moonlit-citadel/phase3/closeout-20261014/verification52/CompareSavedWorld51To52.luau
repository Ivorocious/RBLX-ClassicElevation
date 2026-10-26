local fs,roblox,serde,process=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/process')
local own='tools/moonlit-citadel/phase3/closeout-20261014/verification52/'
local artifacts='docs/artifacts/moonlit-citadel/phase3/closeout-20261014/'
local bindings=serde.decode('json',fs.readFile(own..'bindings52.json'))
assert(bindings.ready==true and bindings.expected.source==52,'Bind the final Source52 packet/plan before saved comparison')
local oldPath=process.args[1] or artifacts..'final/source51-models.rbxm'
local newPath=process.args[2] or artifacts..'final/source52-models.rbxm'
local oldBytes,newBytes=fs.readFile(oldPath),fs.readFile(newPath)
local oldModels,newModels=roblox.deserializeModel(oldBytes),roblox.deserializeModel(newBytes)
assert(#oldModels==2 and #newModels==2,'Exactly two saved courses per candidate required')
local targetUnit,targetPart='GrandRearCentralPinnacle','MC_TL_GrandPinnacle__StoneLight'
local function relative(root,item)
	local list={};while item~=root do assert(item);table.insert(list,1,item.Name);item=item.Parent end;return table.concat(list,'/')
end
local function frame(value)return {value:GetComponents()} end
local function equals(a,b)
	if type(a)~=type(b) then return false end
	if type(a)~='table' then return a==b end
	for key,value in a do if not equals(value,b[key]) then return false end end
	for key in b do if a[key]==nil then return false end end;return true
end
local function content(part,key,fallback)
	local ok,value=pcall(function()return part[key]end);if not ok then value=part[fallback] end
	local raw=tostring(value);local id=raw:match('rbxassetid://(%d+)') or raw:match('[?&]id=(%d+)')
	return if id then 'rbxassetid://'..id else raw
end
local function properties(part)
	local result={cf=frame(part.CFrame),size={part.Size.X,part.Size.Y,part.Size.Z},class=part.ClassName,
		color={part.Color.R,part.Color.G,part.Color.B},material=tostring(part.Material),materialVariant=part.MaterialVariant,
		transparency=part.Transparency,castShadow=part.CastShadow,anchored=part.Anchored,collide=part.CanCollide,query=part.CanQuery,touch=part.CanTouch,
		doubleSided=part.DoubleSided,renderFidelity=tostring(part.RenderFidelity),meshId=content(part,'MeshId','MeshContent'),textureId=content(part,'TextureID','TextureContent'),
		sourceMaterial=part:GetAttribute('SourceMaterial'),sourceAsset=part:GetAttribute('SourceAsset'),sourceTriangles=part:GetAttribute('SourceTriangles')}
	local readable,fidelity=pcall(function()return part.CollisionFidelity end)
	if readable then result.collisionFidelity=tostring(fidelity) end
	return result
end
local function pivot(model)
	local ok,value=pcall(function()return model:GetPivot() end)
	if not ok then ok,value=pcall(function()return model.WorldPivot end) end
	if not ok or typeof(value)~='CFrame' then value=model.WorldPivotData end
	assert(typeof(value)=='CFrame','Saved pivot must be readable');return frame(value)
end
local function map(course)
	local world=assert(course.Decoration.Phase3World)
	local units,parts={},{ }
	for _,item in world:GetDescendants() do
		if item:IsA('Model') and item:GetAttribute('MCEditUnit') then
			local key=relative(world,item);assert(not units[key]);local scale=item:GetAttribute('AuthorScale')
			units[key]={asset=item:GetAttribute('MCEditUnit'),district=item:GetAttribute('District'),localCF=frame(item:GetAttribute('CourseLocalFrame')),
				scale={scale.X,scale.Y,scale.Z},materialRole=item:GetAttribute('MaterialRole'),pivot=pivot(item)}
		elseif item:IsA('BasePart') then local key=relative(world,item);assert(not parts[key]);parts[key]=properties(item) end
	end
	return units,parts
end
local report={pass=true,sourceBefore=51,sourceAfter=52,candidateAfter=bindings.expected.candidate,models={},failures={},
	savedModelOnly=true,nativeVisualJudgment=false,scope='Exact saved world unit identities/pivots/AuthorScale and part poses/sizes/static appearance. Only one Size.Z scale adjustment permitted per course.',
	illuminationBoundary='Equal stored appearance and all other part geometry do not prove identical rendered shadows or every rendered frame.',
	inputHashes={[oldPath]=serde.hash('sha256',oldBytes),[newPath]=serde.hash('sha256',newBytes),[own..'bindings52.json']=serde.hash('sha256',fs.readFile(own..'bindings52.json'))}}
local function fail(index,path,detail)table.insert(report.failures,{model=index,path=path,detail=detail});report.pass=false end
for index=1,2 do
	local a,b=oldModels[index],newModels[index]
	assert(a:GetAttribute('SourceRevision')==51 and b:GetAttribute('SourceRevision')==52)
	assert(a:GetAttribute('SourcePacketHash')=='016c10fdcc4d70a75af996216a2cef4687b773a3a42bc7ea389b4608273e62c4')
	assert(b:GetAttribute('SourcePacketHash')==bindings.expected.packet and b:GetAttribute('BuildRevision')==bindings.expected.build)
	local oldUnits,oldParts=map(a);local newUnits,newParts=map(b)
	local row={index=index,unitsBefore=0,unitsAfter=0,partsBefore=0,partsAfter=0,exactUnits=0,exactUnchangedParts=0,adjustedParts=0}
	for key,unit in oldUnits do row.unitsBefore+=1;if equals(unit,newUnits[key]) then row.exactUnits+=1 else fail(index,key,'Unit identity,frame,pivot,AuthorScale or materialRole changed') end end
	for key in newUnits do row.unitsAfter+=1;if not oldUnits[key] then fail(index,key,'Unexpected unit') end end
	for key,part in oldParts do
		row.partsBefore+=1;local actual=newParts[key]
		if not actual then fail(index,key,'Missing saved part');continue end
		if key:match('/'..targetUnit..'/'..targetPart..'$') then
			row.adjustedParts+=1
			local before=table.clone(part);local after=table.clone(actual)
			before.size=nil;after.size=nil
			if not equals(before,after) then fail(index,key,'Adjusted part pose,mesh identity,static appearance or contact flags changed') end
			local expectedZ=part.size[3]*1.04
			if actual.size[1]~=part.size[1] or actual.size[2]~=part.size[2] or math.abs(actual.size[3]-expectedZ)>.00001 then fail(index,key,'Only Size.Z x1.04 with native float rounding is permitted') end
			row.adjustment={path=key,beforeSize=part.size,actualSize=actual.size,expectedDepthDoubleProduct=expectedZ,
				depthFloatRoundingError=math.abs(actual.size[3]-expectedZ),depthTolerance=.00001,frameExactlyUnchanged=equals(part.cf,actual.cf)}
		elseif equals(part,actual) then row.exactUnchangedParts+=1 else fail(index,key,'Non-target saved part changed') end
	end
	for key in newParts do row.partsAfter+=1;if not oldParts[key] then fail(index,key,'Unexpected saved part') end end
	if row.unitsBefore~=243 or row.unitsAfter~=243 or row.exactUnits~=243 or row.partsBefore~=639 or row.partsAfter~=639 or row.exactUnchangedParts~=638 or row.adjustedParts~=1 then
		fail(index,'counts',row)
	end
	table.insert(report.models,row)
end
fs.writeFile(artifacts..'final/saved-world-delta51-to52.json',serde.encode('json',report,true))
print(serde.encode('json',{pass=report.pass,models=report.models,failures=report.failures}))
assert(report.pass,'Unexpected saved Source51-to52 world delta')
