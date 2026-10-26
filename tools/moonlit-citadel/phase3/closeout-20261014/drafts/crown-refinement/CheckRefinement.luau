local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local source = "src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local own = "tools/moonlit-citadel/phase3/closeout-20261014/drafts/crown-refinement/"
local config = luau.load(fs.readFile("src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"), {environment={Vector3=roblox.Vector3}})()
local cache, hashes = {}, {}
local parent = setmetatable({}, {__index=function(_, name) return {moduleName=name} end})
local function loadFile(path)
    local text = fs.readFile(path); hashes[path] = serde.hash("sha256", text); luau.compile(text)
    return luau.load(text, {environment={Vector3=roblox.Vector3, CFrame=roblox.CFrame, Color3=roblox.Color3,
        script={Parent=parent}, game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},
        require=function(value)
            if type(value)~="table" or not value.moduleName then return value end
            local name=value.moduleName
            if not cache[name] then cache[name]=loadFile(source..name..".luau") end
            return cache[name]
        end}})()
end
local layout = loadFile(source.."Layout.luau")
local clearance = loadFile("tools/moonlit-citadel/phase3/enclosure-repair-20261013/checks/ArchitectureClearance.luau")
local crown = loadFile(own.."SceneryRevisions.luau")
local geometry = loadFile(source.."FortressGeometry.luau")
local tower = loadFile(source.."TowerGeometry.luau")
local baseline = loadFile(source.."BaselineWorldPlan.luau")
local units = serde.decode("json", fs.readFile("docs/artifacts/moonlit-citadel/phase3/closeout-20261014/combined-plan50.json")).units
local expected, changed, rows = {}, {}, {}
for _, name in crown.EditedNames do expected[name]=true end
local function append(data)
    table.insert(changed, data)
    local meta=geometry[data.asset] or tower[data.asset]
    if not meta then
        local old=assert(baseline.Assets[data.asset], data.asset)
        meta={parts=old[1], triangles=old[2], center=old[3], size=old[4]}
    end
    local occupied=meta.occupied or {{low=meta.center-meta.size/2,high=meta.center+meta.size/2}}
    for index,box in occupied do
        local frame=data.localCF*roblox.CFrame.new((box.low+box.high)/2*data.scale)
        local size=(box.high-box.low)*data.scale
        table.insert(rows,{path=data.name.."/Occupied"..index,frame={frame:GetComponents()},size={size.X,size.Y,size.Z},
            anchored=true,collide=false,query=false,touch=false,transparency=0})
    end
    return meta
end
for _,unit in units do if expected[unit.name] then
    local data=table.clone(unit)
    data.localCF,data.scale=roblox.CFrame.new(table.unpack(unit.localCF)),roblox.Vector3.new(table.unpack(unit.scale))
    append(crown.Revise(data)); expected[unit.name]=nil
end end
assert(next(expected)==nil)
local additions=crown.Additions()
local partDelta, triangleDelta=0,0
for _,unit in additions do local meta=append(unit);partDelta+=meta.parts;triangleDelta+=meta.triangles end
assert(#additions==10 and partDelta==30 and triangleDelta==1320)
local volumes,seen={},{}
local function reserve(volume)
    local key=volume.kind..volume.reason
    for _,n in {volume.frame:GetComponents()} do key..=string.format("/%.5f",n) end
    for _,n in {volume.size.X,volume.size.Y,volume.size.Z} do key..=string.format("/%.5f",n) end
    if not seen[key] then seen[key]=true;table.insert(volumes,volume) end
end
for mask=0,7 do for lower=1,2 do for upper=1,2 do
    local choices={bit32.band(mask,1)~=0,bit32.band(mask,2)~=0,bit32.band(mask,4)~=0}
    local proxy=table.clone(layout); proxy.GetRoute=function() return layout.GetRoute(choices,{lower,upper}) end
    for _,volume in clearance.Prepare(proxy,config) do reserve(volume) end
end end end
local weight=layout.LiftOrigins.Upper+roblox.Vector3.new(-46,22,-1)
reserve({frame=roblox.CFrame.new(weight),size=roblox.Vector3.new(8,44,6.5),half={4,22,3.25},
    axes={roblox.Vector3.xAxis,roblox.Vector3.yAxis,roblox.Vector3.zAxis},low=weight-roblox.Vector3.new(4,22,3.25),
    high=weight+roblox.Vector3.new(4,22,3.25),kind="Mechanism",reason="Actual Upper west counterweight at -46"})
local result=clearance.CheckParts(rows,volumes)
local findings=0
for _,key in {"blocking","headroom","camera","visibility","invalidContactFlags"} do findings+=#result[key] end
local report={pass=findings==0,staticOnly=true,routeCombinations=32,uniqueVolumes=#volumes,occupiedRows=#rows,result=result,
    resourceDelta={units=#additions,meshParts=partDelta,triangles=triangleDelta},totalAfterRefinement={units=243,meshParts=639,triangles=198722},
    acceptedCourseChanged=false,nativeRenderVerified=false,inputHashes=hashes}
fs.writeFile(own.."focused-checks.json",serde.encode("json",report,true))
fs.writeFile(own.."occupied-plan.json",serde.encode("json",rows,true))
local poses={}
for _,unit in changed do table.insert(poses,{name=unit.name,asset=unit.asset,library=unit.library,district=unit.district,
    localCF={unit.localCF:GetComponents()},scale={unit.scale.X,unit.scale.Y,unit.scale.Z}}) end
fs.writeFile(own.."luau-changed-plan.json",serde.encode("json",poses,true))
print(serde.encode("json",{pass=report.pass,uniqueVolumes=#volumes,occupiedRows=#rows,findings=findings,delta=report.resourceDelta}))
assert(report.pass,"Crown refinement crosses an accepted course reserve")
