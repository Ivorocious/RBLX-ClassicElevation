local fs, luau, roblox, serde = require('@lune/fs'), require('@lune/luau'), require('@lune/roblox'), require('@lune/serde')
local base = 'src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/'
local parent = {}
local function load(name)
	return luau.load(fs.readFile(base .. name .. '.luau'), {environment = {
		Vector3 = roblox.Vector3, CFrame = roblox.CFrame, script = {Parent = parent},
		game = {ReplicatedStorage = {Config = {MoonlitCitadelCourseConfig = {Origin = roblox.Vector3.new(4000,300,2600)}}}},
		require = function(value) return value end,
	}})()
end
for _, name in {'ExpertRoutes','RouteHazardLayout','RouteHazardGoals'} do parent[name] = load(name) end
local layout = load('Layout')
local function encode(value)
	if typeof(value) == 'Vector3' then return {_t='v',value={value.X,value.Y,value.Z}} end
	if typeof(value) == 'CFrame' then return {_t='c',value={value:GetComponents()}} end
	if type(value) ~= 'table' then return value end
	local result = {}; for key, item in value do if type(item) ~= 'function' then result[key] = encode(item) end end
	return result
end
layout.Routes = {NNN=layout.GetRoute({false,false,false},{1,2}), EEE=layout.GetRoute({true,true,true},{1,2}), EEEMirror=layout.GetRoute({true,true,true},{1,1})}
layout.CatchRoutes = {Arch=layout.GetCatchRoute('Arch'),Upper=layout.GetCatchRoute('Upper')}
local output = 'docs/artifacts/moonlit-citadel/phase2/revision07/INTEGRATED_LAYOUT.json'
fs.writeFile(output, serde.encode('json', encode(layout)))
print(output .. ' surfaces=' .. #layout.Surfaces .. ' onfloorHazards=' .. #layout.RouteHazards)
