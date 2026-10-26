local fs,luau,roblox,serde=require("@lune/fs"),require("@lune/luau"),require("@lune/roblox"),require("@lune/serde")
local source="src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local draft="tools/moonlit-citadel/phase3/tower-landscape-20261013/drafts/tower/"
local config=luau.load(fs.readFile("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"),{environment={Vector3=roblox.Vector3}})()
local parent={}
local function load(name,directory)
	return luau.load(fs.readFile((directory or source)..name..".luau"),{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,
		script={Parent=parent},game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},require=function(value) return value end}})()
end
for _,name in {"RouteHazardGoals","SupportingObstacles","RouteHazardLayout","ExpertRoutes"} do parent[name]=load(name) end
local layout=load("Layout")
for _,name in {"BaselineWorldPlan","AssetGeometry","TowerGeometry","Source43WorldPlan"} do parent[name]=load(name,draft) end
local world=load("WorldPlan",draft)
local clearance=load("ArchitectureClearance","tools/moonlit-citadel/phase3/art-repair-20261013/drafts/protection/")
local function encode(value)
	if typeof(value)=="Vector3" then return {value.X,value.Y,value.Z} end
	if typeof(value)=="CFrame" then return {value:GetComponents()} end
	if type(value)~="table" then return value end
	local result={};for key,item in value do if type(item)~="function" then result[key]=encode(item) end end;return result
end
local plan,counts=world.Get(layout,{config=config,clearance=clearance})
for _,screen in {"blocking","headroom","camera","visibility","invalidContactFlags"} do
	assert(#counts.clearance[screen]==0,"New grand-keep geometry fails "..screen)
end
fs.writeFile(draft.."tower-plan.json",serde.encode("json",encode(plan)))
fs.writeFile(draft.."tower-check.json",serde.encode("json",encode(counts)))
print(counts.units,counts.meshParts,counts.triangles,"retired",#counts.retired)
for _,screen in {"blocking","headroom","camera","visibility","invalidContactFlags"} do
	print(screen,#counts.clearance[screen]);for index,item in counts.clearance[screen] do if index<=12 then print(serde.encode("json",encode(item))) end end
end
