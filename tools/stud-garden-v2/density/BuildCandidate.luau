local fs=require("@lune/fs")
local luau=require("@lune/luau")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local fingerprint=require("../Fingerprint")
local function pivot(model)
    if model.PrimaryPart then return model.PrimaryPart.CFrame*model.PrimaryPart.PivotOffset end
    local ok,value=pcall(function() return model.WorldPivot end)
    return if ok then value else model.WorldPivotData or roblox.CFrame.identity
end
roblox.implementMethod("Model","GetPivot",pivot)
local env={}
for _,key in {"Instance","Vector3","Vector2","CFrame","Color3","UDim2","UDim","Enum"} do env[key]=roblox[key] end
local function load(path) return luau.load(fs.readFile(path),{environment=env,debugName=path})() end
local base="docs/artifacts/stud-garden-v2/density-20261006/"
local root=roblox.deserializeModel(fs.readFile(base.."native/sgv2-s05-before-density.rbxm"))[1]
local kit=load("tools/stud-garden-v2/closing/NativeKit.luau")
local ledger=load("tools/stud-garden-v2/density/GardenUnderstory.luau")(root,kit)
ledger.finish=load("tools/stud-garden-v2/density/StudFinishD03.luau")(root)
root.WorldPivotData=root:GetPivot()
local counts={parts=0,colliders=0,meshes=0,scripts=0}
for _,p in root:GetDescendants() do
    if p:IsA("Model") then p.WorldPivotData=p:GetPivot() end
    if p:IsA("BasePart") then counts.parts+=1;assert(p.Anchored);if p.CanCollide then counts.colliders+=1 end end
    if p:IsA("MeshPart") then counts.meshes+=1 end
    if p:IsA("LuaSourceContainer") then counts.scripts+=1 end
end
assert(counts.scripts==0 and counts.meshes==377 and not root.CourseInfo:GetAttribute("Enabled"))
local revision=string.lower(root:GetAttribute("CandidateId"):match("(D%d+)$"))
fs.writeDir(base..revision)
fs.writeFile(base..revision.."/candidate-offline.rbxm",roblox.serializeModel({root}))
ledger.geometry=fingerprint(root);ledger.counts=counts
fs.writeFile(base..revision.."/build-result.json",serde.encode("json",ledger,true))
print(serde.encode("json",ledger))

