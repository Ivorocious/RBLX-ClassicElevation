local fs,luau,roblox,serde,process=require('@lune/fs'),require('@lune/luau'),require('@lune/roblox'),require('@lune/serde'),require('@lune/process')
local source='src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
local own='tools/moonlit-citadel/phase3/enclosure-repair-20261013/checks/'
local stage=process.args[1] or 'tools/moonlit-citadel/phase3/enclosure-repair-20261013/stage/'
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
local plan,architecture=world.Get(layout)
local outer,landscape=environment.Get(layout,architecture.plantingMounts,architecture.assemblies,architecture.additionalGroundRoots)

local rows={}
for _,set in {plan,outer} do for _,r in set do table.insert(rows,{name=r.name,asset=r.asset,library=r.library or 'BL02',district=r.district,scale={r.scale.X,r.scale.Y,r.scale.Z},localCF={r.localCF:GetComponents()},materialRole=r.materialRole}) end end
fs.writeFile('docs/artifacts/moonlit-citadel/phase3/enclosure-repair-20261013/combined-plan49.json',serde.encode('json',{schema=1,units=rows,inputHashes=inputHashes},true))
print(serde.encode('json',{units=#rows,architecture=architecture.units,landscape=landscape.units}))