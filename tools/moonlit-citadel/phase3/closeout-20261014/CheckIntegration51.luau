local fs,luau,roblox,serde,process=require('@lune/fs'),require('@lune/luau'),require('@lune/roblox'),require('@lune/serde'),require('@lune/process')
local source='src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
local own='tools/moonlit-citadel/phase3/closeout-20261014/'
local stage=process.args[1] or 'tools/moonlit-citadel/phase3/closeout-20261014/stage51/'
if string.sub(stage,-1)~='/' then stage..='/' end
local config=luau.load(fs.readFile('src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau'),{environment={Vector3=roblox.Vector3}})()
local cache,loading,inputHashes={},{},{}
local parent=setmetatable({}, {__index=function(_,name)return {moduleName=name} end})
local function load(name)
	if cache[name] then return cache[name] end
	assert(not loading[name],'Source module cycle: '..name);loading[name]=true
	local file=if fs.isFile(stage..name..'.luau') then stage..name..'.luau' else source..name..'.luau'
	assert(fs.isFile(file),'Missing static dependency '..name)
	local text=fs.readFile(file);luau.compile(text)
	inputHashes[name]={path=file,sha256=serde.hash('sha256',text)}
	local result=luau.load(text,{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,
		script={Parent=parent},game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},
		require=function(value)return if type(value)=='table' and value.moduleName then load(value.moduleName) else value end}})()
	cache[name],loading[name]=result,nil
	return result
end
local layout=load('Layout')
local clearance=luau.load(fs.readFile('tools/moonlit-citadel/phase3/enclosure-repair-20261013/checks/ArchitectureClearance.luau'),{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame}})()
local world,environment=load('WorldPlan'),load('EnvironmentPlan')
local plan,architecture=world.Get(layout)
local outer,landscape=environment.Get(layout,architecture.plantingMounts,architecture.assemblies,architecture.additionalGroundRoots)
local assemblyFile=if fs.isFile(stage..'WorldAssembly.luau') then stage..'WorldAssembly.luau' else source..'WorldAssembly.luau'
local assemblyText=fs.readFile(assemblyFile);luau.compile(assemblyText)
inputHashes.WorldAssembly={path=assemblyFile,sha256=serde.hash('sha256',assemblyText)}
local limits=world.Limits
local totals={units=architecture.units+landscape.units,meshParts=architecture.meshParts+landscape.meshParts,triangles=architecture.triangles+landscape.triangles}
local failures={}
for key,limit in limits do if totals[key]>limit then table.insert(failures,'Combined '..key..' exceeds '..limit) end end
local names={};for _,rows in {plan,outer} do for _,unit in rows do
	assert(not names[unit.name],'Duplicate combined art name '..unit.name);names[unit.name]=true
end end
assert(totals.units==#plan+#outer,'Combined ledger differs from actual returned unit count')
local original=serde.decode('json',fs.readFile('docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/combined-plan49.json'))
local originalByName={}
for _,unit in original.units do originalByName[unit.name]=unit end
local changedNames,unchangedNames={},{}
local function unchanged(unit)
 local old=originalByName[unit.name]
 if not old or old.asset~=unit.asset or old.library~=(unit.library or 'BL02') or old.materialRole~=unit.materialRole then return false end
 for index,value in {unit.localCF:GetComponents()} do if math.abs(value-old.localCF[index])>.0001 then return false end end
 for index,value in {unit.scale.X,unit.scale.Y,unit.scale.Z} do if math.abs(value-old.scale[index])>.0001 then return false end end
 return true
end
for _,unit in plan do
 if unchanged(unit) then table.insert(unchangedNames,unit.name) else changedNames[unit.name]=true end
end
for _,unit in outer do assert(unchanged(unit),'Existing terrain or landscape changed '..unit.name) end
local focusedRows={}
for _,row in architecture.proposalRows do
 local unitName=row.path:match('^(.-)/Occupied')
 if changedNames[unitName] then table.insert(focusedRows,row) end
end
local volumes, seenVolumes = {}, {}
for mask=0,7 do
 for lower=1,2 do for upper=1,2 do
  local chosen=table.clone(layout)
  chosen.GetRoute=function()return layout.GetRoute({bit32.band(mask,1)~=0,bit32.band(mask,2)~=0,bit32.band(mask,4)~=0},{lower,upper}) end
  for _,space in clearance.Prepare(chosen,config) do
   local key=space.reason..'|'..tostring(space.frame)..'|'..tostring(space.size)
   if not seenVolumes[key] then seenVolumes[key]=true;table.insert(volumes,space) end
  end
 end end
end
local function screen(rows,label)
	if not rows then table.insert(failures,label..' occupied geometry rows are unavailable');return nil end
	local report=clearance.CheckParts(rows,volumes)
	for _,key in {'blocking','headroom','camera','visibility','invalidContactFlags'} do
		if #report[key]>0 then table.insert(failures,label..' '..key..' '..#report[key]) end
	end
	return report
end
local archScreen=screen(focusedRows,'Changed architecture, windows and cliffs')
if architecture.clearance then for _,key in {'blocking','headroom','camera','visibility','invalidContactFlags'} do
	if #architecture.clearance[key]>0 then table.insert(failures,'Architecture '..key..' '..#architecture.clearance[key]) end
end end
local landscapeScreen={unchangedSource49Placements=#outer,clearanceNotRepeated=true,baseline='Verified Source49 unchanged environment source and native frozen geometry'}
if not fs.isFile(stage..'EnvironmentPlan.luau') then table.insert(failures,'New landscape EnvironmentPlan has not been staged; Previous scenery fallback only') end
if landscape.omittedPlanting and #landscape.omittedPlanting>0 then table.insert(failures,'Architecture planting was omitted') end
local function encode(value)
	if typeof(value)=='Vector3' then return {value.X,value.Y,value.Z} end
	if typeof(value)=='CFrame' then return {value:GetComponents()} end
	if typeof(value)=='Color3' then return {value.R,value.G,value.B} end
	if typeof(value)=='EnumItem' then return tostring(value) end
	if type(value)~='table' then return value end
	local result={};for key,item in value do if type(item)~='function' then result[key]=encode(item) end end;return result
end
local report={stage=stage,pass=#failures==0,failures=failures,totals=totals,limits=limits,
	remaining={units=limits.units-totals.units,meshParts=limits.meshParts-totals.meshParts,triangles=limits.triangles-totals.triangles},
	architecture=architecture,landscape=landscape,architectureScreen=archScreen,landscapeScreen=landscapeScreen,
	protectedVolumeCount=#volumes,routeCombinations=32,focusedChangedNames=changedNames,focusedOccupiedRows=#focusedRows,unchangedArchitectureNames=unchangedNames,compiledWorldAssembly=true,gameplayReplayed=false,nativeGeometryCompared=false,staticOnly=true}
report.inputHashes=inputHashes
report.architecture.proposalRows=nil;report.landscape.proposalRows=nil
fs.writeFile(own..'combined-stage-check51.json',serde.encode('json',encode(report),true))
local export={}
for _, set in {plan,outer} do for _,r in set do
 table.insert(export,{name=r.name,asset=r.asset,library=r.library or 'BL02',district=r.district,scale={r.scale.X,r.scale.Y,r.scale.Z},localCF={r.localCF:GetComponents()},materialRole=r.materialRole})
end end
fs.writeFile('docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan51.json',serde.encode('json',{schema=1,units=export,inputHashes=inputHashes},true))
if fs.isFile(own..'resource-ledger.json') then
	local ledger=serde.decode('json',fs.readFile(own..'resource-ledger.json'))
	ledger.stagedActualStatic={totals=totals,remaining=report.remaining,clearancePass=report.pass,report='combined-stage-check51.json',nativeCountVerified=false}
	fs.writeFile(own..'resource-ledger.json',serde.encode('json',ledger,true))
end
print(serde.encode('json',{pass=report.pass,failures=failures,totals=totals,remaining=report.remaining}))
if not report.pass then error('Combined stage has concrete outstanding findings; see combined-stage-check51.json') end
