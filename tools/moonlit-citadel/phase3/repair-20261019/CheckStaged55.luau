local fs,luau,roblox,serde=require("@lune/fs"),require("@lune/luau"),require("@lune/roblox"),require("@lune/serde")
local root="tools/moonlit-citadel/phase3/repair-20261019/staged55/"
local target="docs/artifacts/moonlit-citadel/phase3/repair-20261019/"
local hashes,cache={},{}
local parent={}
local loadNode
setmetatable(parent,{__index=function(_,name) local value={path=root..name..".luau",Parent=parent};rawset(parent,name,value);return value end})
local configNode={path="src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"}
local game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=configNode}}}
loadNode=function(n)
 if cache[n.path] then return cache[n.path] end
 local raw=fs.readFile(n.path);hashes[n.path]=serde.hash("sha256",raw)
 local result=luau.load(raw,{environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,Enum=roblox.Enum,script=n,game=game,require=loadNode}})()
 cache[n.path]=result;return result
end
local compiled=0
for _,entry in fs.readDir(root) do if entry:sub(-5)==".luau" then luau.compile(fs.readFile(root..entry));compiled+=1 end end
local config=loadNode(configNode)
local layout=loadNode(parent.Layout)
local world=loadNode(parent.WorldPlan)
local environment=loadNode(parent.EnvironmentPlan)
local plan,counts=world.Get(layout)
local outer,outerCounts=environment.Get(layout,counts.plantingMounts,counts.assemblies)
for _,row in outer do table.insert(plan,row) end
local function serial(value)
 if typeof(value)=="Vector3" then return {value.X,value.Y,value.Z}
 elseif typeof(value)=="Color3" then return {value.R,value.G,value.B}
 elseif typeof(value)=="CFrame" then return {value:GetComponents()}
 elseif type(value)=="table" then local result={} for k,v in value do result[k]=serial(v) end return result
 else return value end
end
local report={pass=true,compiled=compiled,units=#plan,architectureUnits=counts.units,meshes=counts.meshParts+outerCounts.meshParts,triangles=counts.triangles+outerCounts.triangles,details=counts.detail,finish=serial(layout.FinishGate),candidate=world.Candidate,sourceHashes=hashes}
assert(report.units==315 and report.meshes==868 and report.triangles==259002)
assert(counts.detail.units==78)
assert(layout.FinishGate.size==roblox.Vector3.new(28,12,24))
fs.writeFile(target.."combined-plan55.json",serde.encode("json",{units=serial(plan),counts=report},true))
fs.writeFile(target.."staged-source-check55.json",serde.encode("json",report,true))
print(serde.encode("json",report))
