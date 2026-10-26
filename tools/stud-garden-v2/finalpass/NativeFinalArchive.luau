assert(not game.RunService:IsRunning())
local root=workspace.SGV2_Phase3_F04
local status=root.GardenGiants.GiantIvor.Humanoid:FindFirstChild("Status")
assert(status and status.ClassName=="Status" and #status:GetChildren()==0 and next(status:GetAttributes())==nil)
status.Archivable=false
local rawFingerprint=(function()
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
    local instances = root:GetDescendants()
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
        if object.ClassName=="Status" and object:GetFullName():sub(#root:GetFullName()+2)=="GardenGiants.GiantIvor.Humanoid.Status" then
            assert(#object:GetChildren()==0 and next(object:GetAttributes())==nil,"Unexpected Status contents")
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
local archive=(function()
return function(root, filename, fingerprint)
    assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
    assert(filename:match("^[a-z0-9%-]+%.rbxm$"))
    local serializer = game:GetService("SerializationService")
    local http = game:GetService("HttpService")
    local priorHttp = http.HttpEnabled
    local restored
    local ok, result = xpcall(function()
        local rawBefore = rawFingerprint(root)
        local before = fingerprint(root)
        local bytes = buffer.tostring(serializer:SerializeInstancesAsync({root}))
        http.HttpEnabled = true
        local url = "http://127.0.0.1:8768/" .. filename
        local response = http:RequestAsync({Url=url, Method="POST", Headers={["Content-Type"]="application/octet-stream"}, Body=bytes})
        assert(response.Success, response.StatusMessage)
        local readback = http:GetAsync(url, true)
        assert(readback == bytes, "Saved bytes differ")
        restored = serializer:DeserializeInstancesAsync(buffer.fromstring(readback))
        assert(#restored == 1)
        local rawRestored = rawFingerprint(restored[1])
        local after = fingerprint(restored[1])
        for _,key in {"contentHash","instances","parts","meshes","colliders","scripts","sourceBytes","stringBytes"} do
            assert(before[key] == after[key], "Restored " .. key .. " differs")
        end
        assert(before.geometry.hash == after.geometry.hash, "Restored geometry differs")
        local function labels(model)
            local rows={}
            for _,v in model:GetDescendants() do if v:IsA("TextLabel") then
                local gui=v.Parent
                table.insert(rows,table.concat({v:GetFullName():sub(#model:GetFullName()+2),v.Text,tostring(v.Font),tostring(v.TextSize),tostring(v.TextScaled),tostring(v.TextColor3),tostring(v.Size),tostring(gui.Face),tostring(gui.PixelsPerStud)},"|"))
            end end
            table.sort(rows);return table.concat(rows,"\n"),#rows
        end
        local labelBefore,labelCount=labels(root)
        local labelAfter,restoredLabelCount=labels(restored[1])
        assert(labelBefore==labelAfter and labelCount==restoredLabelCount,"Restored labels differ")
        return {receipt=http:JSONDecode(response.Body), before=before, restored=after, rawBefore=rawBefore, rawRestored=rawRestored, labelsVerified=labelCount, verified=true, exclusion="Only the empty engine-created GardenGiants.GiantIvor.Humanoid.Status instance is excluded from instance/content counts; Roblox omits it even if Archivable=true. No part or physics flag is normalized."}
    end, debug.traceback)
    if restored then for _,object in restored do object:Destroy() end end
    http.HttpEnabled = priorHttp
    assert(ok, result)
    return result
end



end)()
return archive(root,"sgv2-finalpass-f01.rbxm",fingerprint)
