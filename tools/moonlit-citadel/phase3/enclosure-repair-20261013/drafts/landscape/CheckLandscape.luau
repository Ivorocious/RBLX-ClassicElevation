local fs,luau,roblox,serde=require("@lune/fs"),require("@lune/luau"),require("@lune/roblox"),require("@lune/serde")
local source="src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local draft="tools/moonlit-citadel/phase3/enclosure-repair-20261013/drafts/landscape/"
local config=luau.load(fs.readFile("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"),{environment={Vector3=roblox.Vector3}})()
local parent={}
local function load(name,directory)
	return luau.load(fs.readFile((directory or source)..name..".luau"),{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,
		script={Parent=parent},game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},require=function(value)return value end}})()
end
for _,name in {"RouteHazardGoals","SupportingObstacles","RouteHazardLayout","ExpertRoutes"} do parent[name]=load(name) end
local layout=load("Layout")
for _,name in {"BaselineWorldPlan","AssetGeometry","TowerGeometry","Source43WorldPlan"} do parent[name]=load(name) end
local world=load("WorldPlan")
local _,architecture=world.Get(layout)
for _,name in {"PreviousEnvironment","EnclosureGeometry","WoodlandPlacements"} do parent[name]=load(name,draft) end
local offline=serde.decode("json",fs.readFile(draft.."terrain-metadata.json"))
local compared=0
for asset,meta in parent.EnclosureGeometry do
	if not meta.xs then continue end
	local expected=offline[asset].occupied
	assert(#meta.occupied==#expected,"Generated terrain columns changed")
	for index,item in meta.occupied do
		local target=expected[index]
		assert((item.low-roblox.Vector3.new(table.unpack(target.low))).Magnitude<.00002,"Terrain low bound mismatch")
		assert((item.high-roblox.Vector3.new(table.unpack(target.high))).Magnitude<.00002,"Terrain high bound mismatch")
		for point=1,3 do assert((item.top[point]-roblox.Vector3.new(table.unpack(target.top[point]))).Magnitude<.00002,"Terrain triangle parity mismatch") end
		compared+=1
	end
end
print("compact/offline triangle columns compared",compared)
local environment=load("EnvironmentPlan",draft)
local clearance=load("ArchitectureClearance","tools/moonlit-citadel/phase3/art-repair-20261013/drafts/protection/")
local plan,counts=environment.Get(layout,architecture.plantingMounts,architecture.assemblies,{config=config,clearance=clearance})
local function encode(value)
	if typeof(value)=="Vector3" then return {value.X,value.Y,value.Z} end
	if typeof(value)=="CFrame" then return {value:GetComponents()} end
	if type(value)~="table" then return value end
	local result={};for key,item in value do if type(item)~="function" then result[key]=encode(item) end end;return result
end
local rows=#counts.proposalRows
counts.proposalRows=nil;counts.terrainSolids=nil;counts.foundationBeds=nil
fs.writeFile(draft.."landscape-plan.json",serde.encode("json",encode(plan)))
fs.writeFile(draft.."landscape-check.json",serde.encode("json",encode(counts)))
print("landscape",counts.units,counts.meshParts,counts.triangles,"trees",counts.ruralTreeCount,"occupied rows",rows)
for _,screen in {"blocking","headroom","camera","visibility","invalidContactFlags"} do
	local list=counts.clearanceReport[screen];print(screen,#list)
	for index,item in list do if index<=18 then print(serde.encode("json",item)) end end
	assert(#list==0,"Enclosure landscape fails accepted space screen: "..screen)
end
