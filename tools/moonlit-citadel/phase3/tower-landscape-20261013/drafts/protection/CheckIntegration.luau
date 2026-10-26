local fs,luau,roblox,serde,process=require('@lune/fs'),require('@lune/luau'),require('@lune/roblox'),require('@lune/serde'),require('@lune/process')
local source='src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
local own='tools/moonlit-citadel/phase3/tower-landscape-20261013/drafts/protection/'
local stage=process.args[1] or 'tools/moonlit-citadel/phase3/tower-landscape-20261013/stage/'
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
local clearance=luau.load(fs.readFile(own..'ArchitectureClearance.luau'),{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame}})()
local world,environment=load('WorldPlan'),load('EnvironmentPlan')
local plan,architecture=world.Get(layout,{config=config,clearance=clearance})
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
local volumes=clearance.Prepare(layout,config)
local function screen(rows,label)
	if not rows then table.insert(failures,label..' occupied geometry rows are unavailable');return nil end
	local report=clearance.CheckParts(rows,volumes)
	for _,key in {'blocking','headroom','camera','visibility','invalidContactFlags'} do
		if #report[key]>0 then table.insert(failures,label..' '..key..' '..#report[key]) end
	end
	return report
end
local archScreen=architecture.clearance or screen(architecture.proposalRows,'Architecture')
if architecture.clearance then for _,key in {'blocking','headroom','camera','visibility','invalidContactFlags'} do
	if #architecture.clearance[key]>0 then table.insert(failures,'Architecture '..key..' '..#architecture.clearance[key]) end
end end
local landscapeScreen=screen(landscape.proposalRows,'Landscape')
if not fs.isFile(stage..'EnvironmentPlan.luau') then table.insert(failures,'New landscape EnvironmentPlan has not been staged; Source43 fallback only') end
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
	compiledWorldAssembly=true,gameplayReplayed=false,nativeGeometryCompared=false,staticOnly=true}
report.inputHashes=inputHashes
report.architecture.proposalRows=nil;report.landscape.proposalRows=nil
fs.writeFile(own..'combined-stage-check.json',serde.encode('json',encode(report),true))
if fs.isFile(own..'resource-ledger.json') then
	local ledger=serde.decode('json',fs.readFile(own..'resource-ledger.json'))
	ledger.stagedActualStatic={totals=totals,remaining=report.remaining,clearancePass=report.pass,report='combined-stage-check.json',nativeCountVerified=false}
	fs.writeFile(own..'resource-ledger.json',serde.encode('json',ledger,true))
end
print(serde.encode('json',{pass=report.pass,failures=failures,totals=totals,remaining=report.remaining}))
if not report.pass then error('Combined stage has concrete outstanding findings; see combined-stage-check.json') end
