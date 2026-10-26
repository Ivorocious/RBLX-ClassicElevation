local fs,rbx,luau=require("@lune/fs"),require("@lune/roblox"),require("@lune/luau")
local base="src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local cache={}
local parent=setmetatable({}, {__index=function(_,name)return {moduleName=name}end})
local config=luau.load(fs.readFile("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"),{environment={Vector3=rbx.Vector3}})()
local function load(name)
 if cache[name] then return cache[name] end
 local v=luau.load(fs.readFile(base..name..".luau"),{environment={Vector3=rbx.Vector3,CFrame=rbx.CFrame,Color3=rbx.Color3,script={Parent=parent},game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},require=function(m)return if type(m)=="table"and m.moduleName then load(m.moduleName)else m end}})()
 cache[name]=v;return v
end
local plan,counts=load("WorldPlan").Get(load("Layout"))
assert(#plan==254 and counts.units==254 and counts.detail.units==78 and counts.detail.meshParts==250 and counts.detail.triangles==92092)
local outer,env=load("EnvironmentPlan").Get(load("Layout"),counts.plantingMounts,counts.assemblies)
assert(counts.units+env.units==321 and counts.meshParts+env.meshParts==889 and counts.triangles+env.triangles==290814)
print("PASS actual WorldPlan.Get + Environment:321 units/889 meshes/290814 triangles;78 detail units")
