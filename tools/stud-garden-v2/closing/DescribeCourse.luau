local fs=require("@lune/fs")
local process=require("@lune/process")
local roblox=require("@lune/roblox")
local serde=require("@lune/serde")
local fingerprint=require("../Fingerprint")
local root=roblox.deserializeModel(fs.readFile(assert(process.args[1])))[1]
local function vector(v) return {v.X,v.Y,v.Z} end
local function attributes(object)
    local out={}
    for key,value in object:GetAttributes() do
        local kind=typeof(value)
        if kind=="Vector3" then out[key]={type=kind,value=vector(value)}
        elseif kind=="CFrame" then out[key]={type=kind,value={value:GetComponents()}}
        elseif kind=="Color3" then out[key]={type=kind,value={value.R,value.G,value.B}}
        elseif kind=="number" or kind=="string" or kind=="boolean" then out[key]=value end
    end
    return out
end
local data={name=root.Name,attributes=attributes(root),fingerprint=fingerprint(root),parts={},models={},labels={}}
local prefix=#root:GetFullName()+2
for _,p in root:GetDescendants() do
    local path=p:GetFullName():sub(prefix)
    if p:IsA("BasePart") then
        local row={path=path,name=p.Name,class=p.ClassName,cf={p.CFrame:GetComponents()},size=vector(p.Size),
            color={p.Color.R,p.Color.G,p.Color.B},collide=p.CanCollide,query=p.CanQuery,touch=p.CanTouch,
            transparency=p.Transparency,role=p:GetAttribute("Role"),material=tostring(p.Material),attributes=attributes(p),
            shape=if p:IsA("Part") then p.Shape.Name else p.ClassName}
        if p:IsA("MeshPart") then local ok,id=pcall(function() return p.MeshId end) if ok then row.mesh=id end end
        table.insert(data.parts,row)
    elseif p:IsA("Model") or p:IsA("Folder") then
        local row={path=path,class=p.ClassName,attributes=attributes(p)}
        if p:IsA("Model") then
            local ok,pivot=pcall(function() return p.WorldPivot end)
            if not ok then ok,pivot=pcall(function() return p.WorldPivotData end) end
            if ok and typeof(pivot)=="CFrame" then row.pivot={pivot:GetComponents()} end
        end
        table.insert(data.models,row)
    elseif p:IsA("TextLabel") then
        local row={path=path,text=p.Text}
        if p.Parent and p.Parent:IsA("SurfaceGui") and p.Parent.Parent then
            row.partPath=p.Parent.Parent:GetFullName():sub(prefix)
            row.face=p.Parent.Face.Name
            row.color={p.TextColor3.R,p.TextColor3.G,p.TextColor3.B}
        end
        table.insert(data.labels,row)
    end
end
table.sort(data.parts,function(a,b) return a.path<b.path end)
fs.writeFile(assert(process.args[2]),serde.encode("json",data))
print(serde.encode("json",{name=data.name,fingerprint=data.fingerprint,models=#data.models,labels=#data.labels}))
