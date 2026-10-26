local fs,roblox,serde,luau,process=require("@lune/fs"),require("@lune/roblox"),require("@lune/serde"),require("@lune/luau"),require("@lune/process")
local own="tools/moonlit-citadel/phase3/detail-pass-20261014/verification/correction54/"
local frozen="tools/moonlit-citadel/phase3/detail-pass-20261014/verification/"
local planPath=assert(process.args[1],"Pass the actual additive or final detail plan JSON")
local modelPath=process.args[2] or "docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/before/source52-models.rbxm"
local output=process.args[3] or own.."correction-clearance.json"
local metadataPath=assert(process.args[4],"Pass the actual combined corrective occupied metadata")
local clearancePath="tools/moonlit-citadel/phase3/enclosure-repair-20261013/checks/ArchitectureClearance.luau"
local configPath="src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"
local source="src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local hashes={}
local function read(path) local raw=fs.readFile(path);hashes[path]=serde.hash("sha256",raw);return raw end
local function loadModule(path,environment) return luau.load(read(path),{environment=environment})() end
local config=loadModule(configPath,{Vector3=roblox.Vector3})
local cache={};local parent=setmetatable({}, {__index=function(_,name) return {moduleName=name} end})
local function load(name)
    if cache[name] then return cache[name] end
    local result=loadModule(source..name..".luau",{Vector3=roblox.Vector3,CFrame=roblox.CFrame,Color3=roblox.Color3,
        script={Parent=parent},game={ReplicatedStorage={Config={MoonlitCitadelCourseConfig=config}}},
        require=function(module) return if type(module)=="table" and module.moduleName then load(module.moduleName) else module end})
    cache[name]=result;return result
end
local layout=load("Layout")
local clearance=loadModule(clearancePath,{Vector3=roblox.Vector3,CFrame=roblox.CFrame})
local detail=loadModule(frozen.."DetailClearance53.luau",{Vector3=roblox.Vector3,CFrame=roblox.CFrame})
local models=roblox.deserializeModel(read(modelPath));assert(#models==2,"Use the fresh two-course recovery")
local model=models[1]
assert(model:GetAttribute("SourceRevision")==52,"Source52 accepted baseline required")
local origin=assert(model:GetAttribute("Origin"))
local normals={Front=roblox.Vector3.new(0,0,-1),Back=roblox.Vector3.new(0,0,1),Top=roblox.Vector3.new(0,1,0),
    Bottom=roblox.Vector3.new(0,-1,0),Left=roblox.Vector3.new(-1,0,0),Right=roblox.Vector3.new(1,0,0)}
local function relative(item)
    local names={};while item~=model do assert(item);table.insert(names,1,item.Name);item=item.Parent end
    return table.concat(names,"/")
end
local signs={};local seen={}
for _,gui in model:GetDescendants() do
    if not gui:IsA("SurfaceGui") then continue end
    local hasText=false;for _,child in gui:GetDescendants() do if child:IsA("TextLabel") and child.Text~="" then hasText=true;break end end
    if not hasText then continue end
    local holder=gui.Adornee or gui.Parent
    while holder and not holder:IsA("BasePart") do holder=holder.Parent end
    assert(holder and holder:IsA("BasePart"),"Stored course text must bind an actual sign face")
    local normal=assert(normals[gui.Face.Name],"Use the actual stored SurfaceGui face")
    local key=relative(holder).."/"..gui.Face.Name
    if seen[key] then continue end;seen[key]=true
    local cf=roblox.CFrame.new(-origin)*holder.CFrame
    table.insert(signs,{path=key,frame={cf:GetComponents()},size={holder.Size.X,holder.Size.Y,holder.Size.Z},normal={normal.X,normal.Y,normal.Z}})
end
local plan=serde.decode("json",read(planPath))
local metadata=serde.decode("json",read(metadataPath))
local report=detail.Check(clearance,layout,config,plan,metadata,signs)
report.inputHashes=hashes;report.baselineModelSource=52;report.actualPreservedSignFaces=#signs
report.finalPlanBound=type(plan.units)=="table" and #plan.units>243
report.targetSource=process.args[5] and tonumber(process.args[5]) or nil
report.nativeImportBasisVerifiedHere=false
report.signRows=signs
fs.writeFile(output,serde.encode("json",report,true).."\n")
print(serde.encode("json",{pass=report.pass,routeCombinations=report.routeCombinations,protectedVolumes=report.protectedVolumes,
    occupiedRows=report.occupiedRows,signs=#signs,blocking=#report.clearance.blocking,headroom=#report.clearance.headroom,
    camera=#report.clearance.camera,sight=#report.clearance.visibility,output=output}))
assert(report.pass,"New detail occupied geometry overlaps a protected route/camera/sign/crown corridor")
