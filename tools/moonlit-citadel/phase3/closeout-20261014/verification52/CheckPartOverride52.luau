local fs,roblox,serde,luau=require('@lune/fs'),require('@lune/roblox'),require('@lune/serde'),require('@lune/luau')
local own='tools/moonlit-citadel/phase3/closeout-20261014/verification52/'
local source='src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
local oracleRaw=fs.readFile(own..'PartAdjustmentOracle52.luau')
local Oracle=luau.load(oracleRaw,{environment={Vector3=roblox.Vector3}})()
local planPath='docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan52.json'
local plan=serde.decode('json',fs.readFile(planPath)).units
local target
for _,unit in plan do if unit.name==Oracle.Unit then target=unit end end
assert(target and Oracle.ValidatePlan(plan).pass)
local kitPath='docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/before/enclosure_before_source48_kits.rbxm'
local template
for _,library in roblox.deserializeModel(fs.readFile(kitPath)) do
	if library.Name=='MoonlitCitadel_TowerLandscape_TL01Library' then template=assert(library:FindFirstChild(Oracle.Asset)) end
end
local part=assert(template:FindFirstChild(Oracle.Part,true))
local authorScale=roblox.Vector3.new(table.unpack(target.scale))
local localCF=roblox.CFrame.new(table.unpack(target.localCF))
local beforeFrame=localCF*roblox.CFrame.new(part.CFrame.Position*authorScale)*part.CFrame.Rotation
local beforeSize=part.Size*authorScale
local afterFrame,afterSize=Oracle.Expected(target,part,beforeFrame,beforeSize)
assert(afterFrame==beforeFrame and afterSize.X==beforeSize.X and afterSize.Y==beforeSize.Y)
assert(math.abs(afterSize.Z-beforeSize.Z*1.04)<.00001)
local fixtures={approvedSizeOnly=true}
target.partLocalScaleOverrides[Oracle.Part]={1,1,1.02};fixtures.wrongFactor=not Oracle.ValidatePlan(plan).pass
target.partLocalScaleOverrides[Oracle.Part]={1,1,1.04}
target.partLocalScaleOverrides.UnapprovedPart={1,1,1.04};fixtures.extraPart=not Oracle.ValidatePlan(plan).pass;target.partLocalScaleOverrides.UnapprovedPart=nil
local oldName=target.name;target.name='AnotherUnit';fixtures.wrongUnit=not Oracle.ValidatePlan(plan).pass;target.name=oldName
local saved=target.partLocalScaleOverrides;target.partLocalScaleOverrides=nil;fixtures.missingAdjustment=not Oracle.ValidatePlan(plan).pass;target.partLocalScaleOverrides=saved
for name,passed in fixtures do assert(passed,name) end
local config=luau.load(fs.readFile('src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau'),{environment={Vector3=roblox.Vector3}})()
local cache={};local parent=setmetatable({}, {__index=function(_,name)return {moduleName=name} end})
local function load(name)
	if cache[name] then return cache[name] end
	local raw=fs.readFile(source..name..'.luau')
	local result=luau.load(raw,{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,script={Parent=parent},
		game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},require=function(module)return if type(module)=='table' and module.moduleName then load(module.moduleName) else module end}})()
	cache[name]=result;return result
end
local layout=load('Layout')
local clearancePath='tools/moonlit-citadel/phase3/enclosure-repair-20261013/checks/ArchitectureClearance.luau'
local clearance=luau.load(fs.readFile(clearancePath),{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame}})()
local volumes,seen={},{}
for mask=0,7 do for lower=1,2 do for upper=1,2 do
	local chosen=table.clone(layout)
	chosen.GetRoute=function()return layout.GetRoute({bit32.band(mask,1)~=0,bit32.band(mask,2)~=0,bit32.band(mask,4)~=0},{lower,upper}) end
	for _,volume in clearance.Prepare(chosen,config) do
		local key=volume.reason..'|'..tostring(volume.frame)..'|'..tostring(volume.size)
		if not seen[key] then seen[key]=true;table.insert(volumes,volume) end
	end
end end end
local row={path=Oracle.Unit..'/'..Oracle.Part,frame={afterFrame:GetComponents()},size={afterSize.X,afterSize.Y,afterSize.Z},anchored=true,collide=false,query=false,touch=false,transparency=0}
local screen=clearance.CheckParts({row},volumes)
local clearancePass=true;for _,name in {'blocking','headroom','camera','visibility','invalidContactFlags'} do if #screen[name]>0 then clearancePass=false end end
local result={pass=clearancePass,fixtures=fixtures,sizeOnly=true,CFUnchanged=true,unit=Oracle.Unit,part=Oracle.Part,
	nativeAxes='Saved verified part yawpi; itsSize.Z is assetdepth; assetdepthcentre zero',
	before={frame={beforeFrame:GetComponents()},size={beforeSize.X,beforeSize.Y,beforeSize.Z}},correctedPartBoundingRow=row,
	clearance=screen,routeCombinations=32,uniqueVolumes=#volumes,scannedRows=1,
	boundsScope='Actual corrected wholematerialpart boundingbox, not stale old occupiedboxes. This is conservative and does not assert every triangle overlaps a box.',
	finalPlan52Bound=true,nativeVisualVerified=false,protectedCourseEdited=false,
	inputHashes={[planPath]=serde.hash('sha256',fs.readFile(planPath)),[kitPath]=serde.hash('sha256',fs.readFile(kitPath)),
		[own..'PartAdjustmentOracle52.luau']=serde.hash('sha256',oracleRaw),[clearancePath]=serde.hash('sha256',fs.readFile(clearancePath)),
		[source..'Layout.luau']=serde.hash('sha256',fs.readFile(source..'Layout.luau'))}}
fs.writeFile(own..'part-override52-focused-check.json',serde.encode('json',result,true))
print(serde.encode('json',{pass=result.pass,fixtures=fixtures,before=result.before,after=row,screen=screen,uniqueVolumes=#volumes}))
