local fs=require("@lune/fs")
local luau=require("@lune/luau")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local process=require("@lune/process")
local V,C=roblox.Vector3,roblox.CFrame
local sourceCFrame=table.clone(C)
function sourceCFrame.lookAt(position,target,up)
    local forward=(target-position).Unit
    local side=forward:Cross(up or V.yAxis)
    if side.Magnitude<1e-6 then side=forward:Cross(V.zAxis) end
    local right=side.Unit
    return C.fromMatrix(position,right,right:Cross(forward),-forward)
end
local function modelPivot(m)
    if m.PrimaryPart then return m.PrimaryPart.CFrame*m.PrimaryPart.PivotOffset end
    local ok,pivot=pcall(function() return m.WorldPivot end)
    return if ok then pivot else m.WorldPivotData or C.identity
end
roblox.implementMethod("Model","GetPivot",modelPivot)
roblox.implementMethod("Model","PivotTo",function(m,target)
    local delta=target*m:GetPivot():Inverse()
    for _,v in m:GetDescendants() do
        if v:IsA("BasePart") then v.CFrame=delta*v.CFrame
        elseif v:IsA("Model") then v.WorldPivot=delta*modelPivot(v) end
    end
    m.WorldPivot=target
end)
local env={}
for _,key in {"Instance","Vector3","Vector2","Color3","UDim2","UDim","Enum"} do env[key]=roblox[key] end
env.CFrame=sourceCFrame
local function load(name)
    return luau.load(fs.readFile("tools/stud-garden-v2/closing/"..name..".luau"),{environment=env,debugName=name})()
end
local root=roblox.deserializeModel(fs.readFile("docs/artifacts/stud-garden-v2/closing-20261005/baseline/sgv2-closing-start-native-verified.rbxm"))[1]
local font
for _,v in root:GetDescendants() do if v:IsA("TextLabel") then font=v.FontFace;break end end
local Kit=load("NativeKit")
local result=load("Calibrate")(root,Kit,load("ToolFamily")(Kit),load("RoutePresentation")(Kit))
if process.args[2]=="route" or process.args[2]=="full" then
    local spec=serde.decode("json",fs.readFile("docs/artifacts/stud-garden-v2/closing-20261005/route-spec.json"))
    result.route=load("RouteClosing")(root,Kit,load("ToolFamily")(Kit),load("RoutePresentation")(Kit),spec)
end
if process.args[2]=="full" then
    result.scenery=load("SceneryClosing")(root,Kit,load("GardenScenery")(Kit))
end
local output=process.args[1] or "docs/artifacts/stud-garden-v2/closing-20261005/calibration"
fs.writeDir(output)
root.WorldPivotData=root:GetPivot()
for _,v in root:GetDescendants() do
    assert(not v:IsA("LuaSourceContainer"),"Course archive must remain geometry only")
    if v:IsA("BasePart") then assert(v.Anchored,"Unanchored course part") end
    if v:IsA("Model") then v.WorldPivotData=v:GetPivot()
    elseif v:IsA("TextLabel") then v.FontFace=font end
end
fs.writeFile(output.."/sample.rbxm",roblox.serializeModel({root}))
fs.writeFile(output.."/build-result.json",serde.encode("json",result))
print(serde.encode("json",{candidate=root:GetAttribute("CandidateId"),objects=#root:GetDescendants(),scenery=result.scenery}))
