local geometryFingerprint = require("./Fingerprint")

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
