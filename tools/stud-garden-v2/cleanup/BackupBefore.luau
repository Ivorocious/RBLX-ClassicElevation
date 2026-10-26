assert(game.PlaceId==85558151074819 and not game.RunService:IsRunning())
local fingerprint=(function()
local geometryFingerprint = (function()
return function(root)
 local rows={}
 for _,p in root:GetDescendants() do
  if p:IsA("BasePart") then
   local row={p:GetFullName():sub(#root:GetFullName()+2),p.ClassName,tostring(p.CanCollide),tostring(p.CanQuery),tostring(p:GetAttribute("Role"))}
   for _,n in {p.CFrame:GetComponents()} do table.insert(row,string.format("%.5f",if math.abs(n)<.000005 then 0 else n)) end
   for _,n in {p.Size.X,p.Size.Y,p.Size.Z,p.Color.R,p.Color.G,p.Color.B,p.Transparency} do table.insert(row,string.format("%.5f",if math.abs(n)<.000005 then 0 else n)) end
   table.insert(rows,table.concat(row,"|"))
  end
 end
 table.sort(rows)
 local hash=2166136261
 for _,row in rows do
  for i=1,#row do
   local h=bit32.bxor(hash,string.byte(row,i))
   local low,high=bit32.band(h,65535),bit32.rshift(h,16)
   hash=(low*403+bit32.band(low*256+high*403,65535)*65536)%4294967296
  end
 end
 return {parts=#rows,hash=string.format("%08x",hash)}
end


end)()

return function(root)
    local result = {name=root.Name, instances=0, parts=0, meshes=0, colliders=0, scripts=0, sourceBytes=0, stringBytes=0, nonArchivable=0}
    local rows = {}
    local function number(value)
        return string.format("%.5f", if math.abs(value)<0.000005 then 0 else value)
    end
    local function valueText(value)
        local kind = typeof(value)
        if kind == "number" then return number(value) end
        if kind == "Vector3" then return number(value.X)..","..number(value.Y)..","..number(value.Z) end
        if kind == "Color3" then return number(value.R)..","..number(value.G)..","..number(value.B) end
        if kind == "CFrame" then
            local values = {value:GetComponents()}
            for index, value in values do values[index] = number(value) end
            return table.concat(values, ",")
        end
        return tostring(value)
    end
    local instances = {}
    for _,object in root:GetDescendants() do
        if object.ClassName=="Status" then
            assert(#object:GetChildren()==0 and next(object:GetAttributes())==nil,"Nonempty engine Status")
        else table.insert(instances,object) end
    end
    table.insert(instances, root)
    for _,object in instances do
        local path = if object == root then "." else object:GetFullName():sub(#root:GetFullName()+2)
        result.instances += 1
        if not object.Archivable then result.nonArchivable += 1 end
        table.insert(rows,path.."|"..object.ClassName)
        for key,value in object:GetAttributes() do table.insert(rows,path.."/@"..key.."="..valueText(value)) end
        if object:IsA("BasePart") then
            result.parts += 1
            if object.CanCollide then result.colliders += 1 end
            for _,key in {"CanTouch","Anchored","Material","CollisionGroup"} do table.insert(rows,path.."/"..key.."="..tostring(object[key])) end
        end
        if object:IsA("MeshPart") then
            result.meshes += 1
            table.insert(rows,path.."/mesh="..object.MeshId.."/texture="..object.TextureID.."/collision="..tostring(object.CollisionFidelity))
        end
        if object:IsA("LuaSourceContainer") then
            result.scripts += 1
            result.sourceBytes += #object.Source
            table.insert(rows,path.."/source="..object.Source)
        end
        if object:IsA("StringValue") then
            result.stringBytes += #object.Value
            table.insert(rows,path.."/value="..object.Value)
        elseif object:IsA("BoolValue") or object:IsA("NumberValue") or object:IsA("IntValue") then
            table.insert(rows,path.."/value="..valueText(object.Value))
        end
    end
    table.sort(rows)
    local hash = 2166136261
    for _,row in rows do
        for index=1,#row do
            local h=bit32.bxor(hash,string.byte(row,index))
            local low,high=bit32.band(h,65535),bit32.rshift(h,16)
            hash=(low*403+bit32.band(low*256+high*403,65535)*65536)%4294967296
        end
    end
    result.contentHash = string.format("%08x",hash)
    result.geometry = geometryFingerprint(root)
    return result
end


end)()
local roots={}
for _,name in {"StudGardenV2Assets_M01","StudGardenV2Assets_M02","SGV2_R02_Recovery_20261006","SGV2OwnerAvatarSource"} do table.insert(roots,assert(game.ServerStorage:FindFirstChild(name))) end
for _,o in workspace:GetChildren() do if o.Name=="ForkRosemaryClump" or o.Name=="Earth" or o.Name=="GrassCap" then table.insert(roots,o) end end
assert(#roots==8,"Expected four obsolete storage roots and four loose owner objects")
local http=game.HttpService;local prior=http.HttpEnabled;local restored
local ok,result=xpcall(function()
 local before={};local rawInstances=0
 for _,root in roots do table.insert(before,{path=root:GetFullName(),fingerprint=fingerprint(root)});rawInstances+=#root:GetDescendants()+1 end
 local bytes=buffer.tostring(game:GetService("SerializationService"):SerializeInstancesAsync(roots))
 http.HttpEnabled=true
 local url="http://127.0.0.1:8768/sgv2-before-cleanup.rbxm"
 local response=http:RequestAsync({Url=url,Method="POST",Headers={["Content-Type"]="application/octet-stream"},Body=bytes})
 assert(response.Success,response.StatusMessage)
 local readback=http:GetAsync(url,true);assert(readback==bytes,"Archive bytes differ")
 restored=game:GetService("SerializationService"):DeserializeInstancesAsync(buffer.fromstring(readback))
 assert(#restored==#roots)
 local remaining={};local restoredFingerprints={};local restoredInstances=0
 for _,root in restored do local f=fingerprint(root);table.insert(restoredFingerprints,f);remaining[f.name.."|"..f.contentHash.."|"..f.geometry.hash]=(remaining[f.name.."|"..f.contentHash.."|"..f.geometry.hash]or 0)+1;restoredInstances+=#root:GetDescendants()+1 end
 for _,record in before do local f=record.fingerprint;local k=f.name.."|"..f.contentHash.."|"..f.geometry.hash;assert(remaining[k]and remaining[k]>0,"Restored root mismatch: "..record.path);remaining[k]-=1 end
 return {verified=true,receipt=http:JSONDecode(response.Body),before=before,restored=restoredFingerprints,rawInstances=rawInstances,restoredInstances=restoredInstances,exclusion="Only empty engine Status objects are excluded; geometry, physics flags, attributes, meshes and script source are compared.",purpose="Recover obsolete Stud Garden storage and preserve four loose owner objects before grouping"}
end,debug.traceback)
if restored then for _,root in restored do root:Destroy()end end
http.HttpEnabled=prior;assert(ok,result)
return game.HttpService:JSONEncode(result)
