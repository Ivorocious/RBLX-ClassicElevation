local fs, luau, roblox, serde = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox'), require('@lune/serde')
local base = 'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
local parent = {}
local config = luau.load(fs.readFile('src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau'), {environment={Vector3=roblox.Vector3}})()
local function load(name)
	return luau.load(fs.readFile(base .. name .. '.luau'), {environment={Vector3=roblox.Vector3, CFrame=roblox.CFrame, Color3=roblox.Color3,
		script={Parent=parent}, game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}}, require=function(value) return value end}})()
end
for _, name in {'ExpertRoutes','RouteHazardLayout','RouteHazardGoals','SupportingObstacles'} do parent[name]=load(name) end
local layout=load('Layout')
local world=load('WorldPlan')
local environment=load('EnvironmentPlan')
local function encode(value)
	if typeof(value)=='Vector3' then return {_t='v',value={value.X,value.Y,value.Z}} end
	if typeof(value)=='CFrame' then return {_t='c',value={value:GetComponents()}} end
	if typeof(value)=='Color3' then return {_t='color',value={value.R,value.G,value.B}} end
	if type(value)~='table' then return value end
	local result={};for key,item in value do if type(item)~='function' then result[key]=encode(item) end end;return result
end
local report={surfaces=#layout.Surfaces,transfers=#layout.Transfers,redHazards=#layout.RouteHazards,routes={}}
local byPath={}
for _, floor in layout.Surfaces do byPath['Obstacles/'..floor.group..'/'..floor.name..'/Contact']=floor end
for mask=0,7 do
	for _, bays in {{1,1},{1,2},{2,1},{2,2}} do
		local choices={bit32.band(mask,1)~=0,bit32.band(mask,2)~=0,bit32.band(mask,4)~=0}
		local route=layout.GetRoute(choices,bays)
		local checkpoints,rides,bands=0,0,{}
		for _, node in route do
			if node.path and node.kind~='Ride' then assert(byPath[node.path],'Missing route support '..node.path) end
			if node.checkpoint and node.checkpoint>checkpoints then assert(node.checkpoint==checkpoints+1);checkpoints=node.checkpoint end
			if node.kind=='Ride' then rides+=1 end
			if node.lanternBand then bands[node.lanternBand]=true end
		end
		assert(checkpoints==4 and rides==2 and bands[1] and bands[2] and bands[3])
		table.insert(report.routes,{mask=mask,bays=bays,nodes=#route})
	end
end
for _, name in {'RouteBuilder','RouteHazards','Wayfinding','WorldAssembly','Coverage','VisualAssembly'} do assert(luau.load(fs.readFile(base..name..'.luau')),name) end
layout.Routes={NNN=layout.GetRoute({false,false,false},{1,2}),EEE=layout.GetRoute({true,true,true},{1,2})}
layout.CatchRoutes={Arch=layout.GetCatchRoute('Arch'),Upper=layout.GetCatchRoute('Upper')}
fs.writeFile('docs/artifacts/moonlit-citadel/phase3/rework-20261012/rw10_layout_r07.json',serde.encode('json',encode(layout)))
local plan, counts=world.Get(layout)
local outer, outerCounts=environment.Get(layout)
report.world, report.environment=counts,outerCounts
report.worldPlanUnits=#plan;report.outerUnits=#outer
fs.writeFile('docs/artifacts/moonlit-citadel/phase3/rework-20261012/rw10_static_r07.json',serde.encode('json',encode(report)))
print(serde.encode('json',encode(report)))
