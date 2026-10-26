local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local own = "tools/moonlit-citadel/phase3/repair-20261019/depth/"
local source = "src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local config = luau.load(fs.readFile("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"), {environment={Vector3=roblox.Vector3}})()
local packet = serde.decode("json", fs.readFile("docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/source54-packet.json"))
local prior = {}
for _, row in packet.records do prior[row.name] = row.sha256 end
local function run(staged)
    local parent = setmetatable({}, {__index=function(_,name) return {moduleName=name} end})
    local cache, hashes = {}, {}
    local function load(name)
        if cache[name] then return cache[name] end
        local path = if staged and (name=="DepthPlan" or name=="EnvironmentPlan") then own..name..".proposed.luau" else source..name..".luau"
        local raw = fs.readFile(path):gsub("\r\n","\n")
        luau.compile(raw)
        hashes[name] = serde.hash("sha256",raw)
        if not (staged and (name=="DepthPlan" or name=="EnvironmentPlan")) then assert(hashes[name]==prior[name], "Frozen54 source differs "..name) end
        local value = luau.load(raw, {environment={Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,
            script={Parent=parent},game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},
            require=function(token) return if type(token)=="table" and token.moduleName then load(token.moduleName) else token end}})()
        cache[name] = value
        return value
    end
    local layout = load("Layout")
    local world, env = load("WorldPlan"), load("EnvironmentPlan")
    local plan, counts = world.Get(layout)
    local outer, outerCounts = env.Get(layout, counts.plantingMounts, counts.assemblies)
    for _, row in outer do table.insert(plan,row) end
    return plan, {units=#plan,meshes=counts.meshParts+outerCounts.meshParts,triangles=counts.triangles+outerCounts.triangles,architecture=counts.units}, hashes
end
local old, oldCounts = run(false)
local new, newCounts, hashes = run(true)
assert(oldCounts.units==320 and oldCounts.meshes==881 and oldCounts.triangles==282944)
assert(newCounts.units==320 and newCounts.meshes==880 and newCounts.triangles==270288 and newCounts.architecture==253)
local differences = {}
for index, before in old do
    local after = assert(new[index])
    assert(before.name==after.name and before.district==after.district and before.localCF==after.localCF and before.scale==after.scale)
    if before.asset~=after.asset or before.library~=after.library then
        assert(before.name=="MC_EC_InnerRavine" and before.asset=="MC_EC_InnerRavine" and before.library=="ER01"
            and after.asset=="MC_DP_InnerChasm" and after.library=="DP01")
        table.insert(differences,{index=index,name=before.name,beforeAsset=before.asset,afterAsset=after.asset})
    end
end
assert(#differences==1)
for _, name in {"DepthPlan","EnvironmentPlan","WorldAssembly"} do luau.compile(fs.readFile(own..name..".proposed.luau")) end
local report={pass=true,baseline=oldCounts,candidate=newCounts,changedWorldUnits=differences,
    other319UnitNamesAssetsLibrariesFramesScalesExact=true,stageSourceHashes=hashes,
    compileProposedModules=3,productionModified=false,studioTouched=false,nativeVerified=false}
fs.writeFile(own.."staged-depth-check.json",serde.encode("json",report,true))
print(serde.encode("json",{pass=true,changedWorldUnits=#differences,counts=newCounts}))
