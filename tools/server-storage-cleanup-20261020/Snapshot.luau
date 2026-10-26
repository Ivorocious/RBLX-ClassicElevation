return function(root, roots, hash, yieldBatch, externalLinks, binaryValueHashes)
    local function property(item, key)
        local ok, result = pcall(function() return item[key] end)
        if ok then return result end
        if item:IsA("MeshPart") and (key == "MeshId" or key == "TextureID") then
            local content = tostring(item[if key == "MeshId" then "MeshContent" else "TextureContent"])
            if content == "Content(None)" then return "" end
            return assert(content:match("^Content%(Uri=(.*)%)$"), "Unknown content representation: " .. content)
        end
        error(result)
    end
    local function number(value)
        return string.format("%.5f", if math.abs(value) < .000005 then 0 else value)
    end
    local function value(item)
        local kind = typeof(item)
        if kind == "number" then return number(item) end
        if kind == "Vector3" or kind == "Color3" then
            local a, b, c
            if kind == "Color3" then a, b, c = item.R, item.G, item.B else a, b, c = item.X, item.Y, item.Z end
            return number(a) .. "," .. number(b) .. "," .. number(c)
        end
        if kind == "CFrame" then
            local fields = {item:GetComponents()}
            for i, component in fields do fields[i] = number(component) end
            return table.concat(fields, ",")
        end
        return tostring(item)
    end
    local function reference(item)
        if not item then return "nil" end
        for _, candidate in roots do
            if item == candidate then return candidate.Name end
            if item:IsDescendantOf(candidate) then
                return candidate.Name .. "." .. item:GetFullName():sub(#candidate:GetFullName() + 2)
            end
        end
        return "external:" .. item:GetFullName()
    end
    local result = {name = root.Name, instances = 0, parts = 0, scripts = 0, refs = 0, classes = {}, omitted = {}}
    local rows = {}
    local all = root:GetDescendants()
    table.insert(all, root)
    for index, item in all do
        if index % 1000 == 0 then yieldBatch() end
        local path = if item == root then "." else item:GetFullName():sub(#root:GetFullName() + 2)
        if item.ClassName == "Status" and not item.Archivable and #item:GetChildren() == 0 and next(item:GetAttributes()) == nil then
            table.insert(result.omitted, path)
            continue
        end
        result.instances += 1
        result.classes[item.ClassName] = (result.classes[item.ClassName] or 0) + 1
        local fields = {path, item.ClassName, tostring(item.Archivable)}
        for key, attribute in item:GetAttributes() do table.insert(fields, "@" .. key .. "=" .. value(attribute)) end
        for _, tag in item:GetTags() do table.insert(fields, "tag=" .. tag) end
        local properties = {}
        if item:IsA("BasePart") then
            result.parts += 1
            properties = {"CFrame", "Size", "Color", "Transparency", "Material", "MaterialVariant", "Reflectance", "Anchored", "CanCollide", "CanTouch", "CanQuery", "CastShadow", "CollisionGroup", "Massless", "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface", "BackSurface"}
        elseif item:IsA("LuaSourceContainer") then
            result.scripts += 1
            table.insert(fields, "source=" .. hash(item.Source))
            if item:IsA("BaseScript") then properties = {"Disabled", "RunContext"} end
        elseif item:IsA("ObjectValue") then
            result.refs += 1
            local canonical = root.Name .. "." .. path
            table.insert(fields, "Value=" .. (externalLinks[canonical] or reference(item.Value)))
        elseif item:IsA("StringValue") then
            local key = root.Name .. "." .. path
            table.insert(fields, "ValueHash=" .. (binaryValueHashes and binaryValueHashes[key] or hash(item.Value)))
        elseif item:IsA("ValueBase") then
            properties = {"Value"}
        elseif item:IsA("Model") then
            table.insert(fields, "PrimaryPart=" .. reference(item.PrimaryPart))
        elseif item:IsA("Attachment") then
            properties = {"CFrame"}
        end
        if item:IsA("MeshPart") then
            for _, key in {"MeshId", "TextureID", "DoubleSided", "RenderFidelity", "CollisionFidelity"} do table.insert(properties, key) end
        elseif item:IsA("SpecialMesh") then
            properties = {"MeshId", "TextureId", "MeshType", "Scale", "Offset"}
        end
        for _, key in properties do table.insert(fields, key .. "=" .. value(property(item, key))) end
        table.sort(fields)
        table.insert(rows, table.concat(fields, "\30"))
    end
    table.sort(rows)
    table.sort(result.omitted)
    result.contentHash = hash(table.concat(rows, "\n"))
    return result
end
