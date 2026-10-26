
local fs,rbx,luau,serde=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau"),require("@lune/serde")
local base="src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local stage="tools/moonlit-citadel/phase3/detail-pass-20261014/stage54/"
local cache={}
local parent=setmetatable({}, {__index=function(_,name)return {moduleName=name}end})
local config=luau.load(fs.readFile("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"),{environment={Vector3=rbx.Vector3}})()
local function load(name)
 if cache[name]then return cache[name]end
 local path=if fs.isFile(stage..name..".luau")then stage..name..".luau"else base..name..".luau"
 local v=luau.load(fs.readFile(path),{environment={Vector3=rbx.Vector3,CFrame=rbx.CFrame,Color3=rbx.Color3,script={Parent=parent},game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},require=function(m)return if type(m)=="table"and m.moduleName then load(m.moduleName)else m end}})()
 cache[name]=v;return v
end
local world=load("WorldPlan")
local plan,c=world.Get(load("Layout"))
local outer,e=load("EnvironmentPlan").Get(load("Layout"),c.plantingMounts,c.assemblies)
assert(c.units==253 and c.detail.units==77 and c.detail.meshParts==242 and c.detail.triangles==84222)
for _,p in outer do table.insert(plan,p)end
assert(#plan==320 and c.meshParts+e.meshParts==881 and c.triangles+e.triangles==282944)
local function plain(v)
 if typeof(v)=="CFrame"then return {v:GetComponents()}elseif typeof(v)=="Vector3"then return {v.X,v.Y,v.Z}elseif typeof(v)=="Color3"then return {v.R,v.G,v.B}
 elseif type(v)=="table"then local out={};for k,n in v do out[k]=plain(n)end;return out
 else return v end
end
local result={sourceRevision=54,buildRevision=48,candidate=world.Candidate,units=plain(plan),details=plain(c.detail),derivation={totalUnits=320,totalMeshes=881,totalTriangles=282944,architectureUnits=253,outerUnits=e.units},schema="ActualWorldPlanPlusEnvironment54"}
fs.writeFile("docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/combined-plan54.generated.json",serde.encode("json",result))
print("PASS staged actualWorldPlan.Get+Environment:320units/881meshes/282944tri;77details")
