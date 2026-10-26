local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local inputPath = "docs/artifacts/city-run/c18/original-before-optimization.rbxm"
local outputPath = "docs/artifacts/city-run/c18/lune-roundtrip.rbxm"
local reportPath = "docs/artifacts/city-run/c18/lune_roundtrip_report.json"

local function safeToString(value)
    local ok, result = pcall(tostring, value)
    if ok then
        return result
    end
    return "<tostring-error>"
end

local function formatNumber(value)
    if value ~= value then
        return "nan"
    end
    if value == math.huge then
        return "inf"
    end
    if value == -math.huge then
        return "-inf"
    end
    return string.format("%.17g", value)
end

local function sortedKeys(value)
    local keys = {}
    for key in pairs(value) do
        table.insert(keys, key)
    end
    table.sort(keys, function(left, right)
        return safeToString(left) < safeToString(right)
    end)
    return keys
end

local function canonicalValue(value, pathByInstance, seen)
    local valueType = typeof(value)

    if value == nil then
        return "nil"
    elseif valueType == "boolean" then
        return value and "boolean:true" or "boolean:false"
    elseif valueType == "string" then
        return "string:" .. value
    elseif valueType == "number" then
        return "number:" .. formatNumber(value)
    elseif valueType == "Instance" then
        local path = pathByInstance[value]
        if path ~= nil then
            return "Instance:" .. path
        end
        local ok, name = pcall(function()
            return value.Name
        end)
        return "Instance:<outside-tree:" .. (ok and safeToString(name) or "unknown") .. ">"
    elseif valueType == "Vector2" then
        return "Vector2:" .. formatNumber(value.X) .. "," .. formatNumber(value.Y)
    elseif valueType == "Vector3" then
        return "Vector3:" .. formatNumber(value.X) .. "," .. formatNumber(value.Y) .. "," .. formatNumber(value.Z)
    elseif valueType == "Vector2int16" then
        return "Vector2int16:" .. safeToString(value.X) .. "," .. safeToString(value.Y)
    elseif valueType == "Vector3int16" then
        return "Vector3int16:" .. safeToString(value.X) .. "," .. safeToString(value.Y) .. "," .. safeToString(value.Z)
    elseif valueType == "CFrame" then
        local ok, components = pcall(function()
            return { value:GetComponents() }
        end)
        if ok then
            local parts = {}
            for _, component in ipairs(components) do
                table.insert(parts, formatNumber(component))
            end
            return "CFrame:" .. table.concat(parts, ",")
        end
        return "CFrame:" .. safeToString(value)
    elseif valueType == "Color3" then
        return "Color3:" .. formatNumber(value.R) .. "," .. formatNumber(value.G) .. "," .. formatNumber(value.B)
    elseif valueType == "Color3uint8" then
        return "Color3uint8:" .. safeToString(value.R) .. "," .. safeToString(value.G) .. "," .. safeToString(value.B)
    elseif valueType == "BrickColor" then
        local okName, name = pcall(function()
            return value.Name
        end)
        local okNumber, number = pcall(function()
            return value.Number
        end)
        return "BrickColor:" .. (okName and safeToString(name) or "?") .. ":" .. (okNumber and safeToString(number) or "?")
    elseif valueType == "EnumItem" then
        return "EnumItem:" .. safeToString(value)
    elseif valueType == "UDim" then
        return "UDim:" .. formatNumber(value.Scale) .. "," .. formatNumber(value.Offset)
    elseif valueType == "UDim2" then
        return "UDim2:" .. formatNumber(value.X.Scale) .. "," .. safeToString(value.X.Offset) .. "," .. formatNumber(value.Y.Scale) .. "," .. safeToString(value.Y.Offset)
    elseif valueType == "NumberRange" then
        return "NumberRange:" .. formatNumber(value.Min) .. "," .. formatNumber(value.Max)
    elseif valueType == "Rect" then
        return "Rect:" .. safeToString(value.Min) .. "," .. safeToString(value.Max)
    elseif valueType == "PhysicalProperties" then
        return "PhysicalProperties:" .. formatNumber(value.Density) .. "," .. formatNumber(value.Friction) .. "," .. formatNumber(value.Elasticity) .. "," .. formatNumber(value.FrictionWeight) .. "," .. formatNumber(value.ElasticityWeight)
    elseif valueType == "table" then
        seen = seen or {}
        if seen[value] then
            return "table:<cycle>"
        end
        seen[value] = true
        local parts = {}
        for _, key in ipairs(sortedKeys(value)) do
            table.insert(parts, "[" .. canonicalValue(key, pathByInstance, seen) .. "]=" .. canonicalValue(value[key], pathByInstance, seen))
        end
        seen[value] = nil
        return "table:{" .. table.concat(parts, ";") .. "}"
    end

    return valueType .. ":" .. safeToString(value)
end

local function collectPropertyNames(db, className)
    local names = {}
    local seen = {}
    local currentClass = className
    local depth = 0

    while currentClass ~= nil and depth < 64 do
        depth += 1
        local okClass, class = pcall(function()
            return db:GetClass(currentClass)
        end)
        if not okClass or class == nil then
            break
        end

        local okProperties, properties = pcall(function()
            return class.Properties
        end)
        if okProperties and properties ~= nil then
            for propertyKey, property in properties do
                local okName, propertyName = pcall(function()
                    return property.Name
                end)
                local name = okName and safeToString(propertyName) or safeToString(propertyKey)
                if not seen[name] then
                    seen[name] = true
                    table.insert(names, name)
                end
            end
        end

        local okSuperclass, superclass = pcall(function()
            return class.Superclass
        end)
        if not okSuperclass or superclass == nil or superclass == currentClass then
            break
        end
        currentClass = superclass
    end

    table.sort(names)
    return names
end

local function pathSegment(name, index, count)
    local text = safeToString(name)
    if count > 1 then
        return text .. "[" .. tostring(index) .. "]"
    end
    return text
end

local function getPathByInstance(roots)
    local pathByInstance = {}
    local instanceByPath = {}

    local function walk(instance, path)
        local name = "<unnamed>"
        pcall(function()
            name = instance.Name
        end)

        local siblings = {}
        local siblingCounts = {}
        local okChildren, children = pcall(function()
            return instance:GetChildren()
        end)
        if okChildren and children ~= nil then
            for _, child in ipairs(children) do
                local childName = "<unnamed>"
                pcall(function()
                    childName = child.Name
                end)
                siblingCounts[childName] = (siblingCounts[childName] or 0) + 1
                table.insert(siblings, { instance = child, name = childName })
            end
        end


        pathByInstance[instance] = path
        instanceByPath[path] = instance

        local occurrence = {}
        for _, childInfo in ipairs(siblings) do
            local childName = childInfo.name
            occurrence[childName] = (occurrence[childName] or 0) + 1
            local childPath = path .. "." .. pathSegment(childName, occurrence[childName], siblingCounts[childName])
            walk(childInfo.instance, childPath)
            local assignedPath = pathByInstance[childInfo.instance]
            if assignedPath ~= childPath then
                pathByInstance[childInfo.instance] = childPath
                instanceByPath[assignedPath] = nil
                instanceByPath[childPath] = childInfo.instance
            end
        end
    end

    for index, root in ipairs(roots) do
        local rootName = "<unnamed>"
        pcall(function()
            rootName = root.Name
        end)
        walk(root, pathSegment(rootName, index, #roots))
    end

    return pathByInstance, instanceByPath
end

local function increment(map, key)
    map[key] = (map[key] or 0) + 1
end

local function snapshot(roots, db)
    local pathByInstance, instanceByPath = getPathByInstance(roots)
    local records = {}
    local readErrors = {}
    local unsupportedTypes = {}
    local readablePropertyCount = 0

    local function recordError(className, propertyName, message)
        local key = className .. "." .. propertyName
        if readErrors[key] == nil then
            readErrors[key] = { count = 0, sample = message }
        end
        readErrors[key].count += 1
    end

    local function recordUnsupported(valueType)
        increment(unsupportedTypes, valueType)
    end

    for path, instance in pairs(instanceByPath) do
        local className = "<unknown>"
        local name = "<unknown>"
        pcall(function()
            className = instance.ClassName
        end)
        pcall(function()
            name = instance.Name
        end)

        local record = {
            path = path,
            name = safeToString(name),
            className = safeToString(className),
            properties = {},
            attributes = nil,
            attributeError = nil,
        }

        local okAttributes, attributes = pcall(function()
            return instance:GetAttributes()
        end)
        if okAttributes then
            record.attributes = canonicalValue(attributes, pathByInstance)
            local function scanUnsupported(value)
                local valueType = typeof(value)
                if valueType ~= "nil" and valueType ~= "boolean" and valueType ~= "string" and valueType ~= "number" and valueType ~= "Vector2" and valueType ~= "Vector3" and valueType ~= "Vector2int16" and valueType ~= "Vector3int16" and valueType ~= "CFrame" and valueType ~= "Color3" and valueType ~= "Color3uint8" and valueType ~= "BrickColor" and valueType ~= "EnumItem" and valueType ~= "UDim" and valueType ~= "UDim2" and valueType ~= "NumberRange" and valueType ~= "Rect" and valueType ~= "PhysicalProperties" and valueType ~= "table" and valueType ~= "Instance" then
                    recordUnsupported(valueType)
                elseif valueType == "table" then
                    for _, nested in pairs(value) do
                        scanUnsupported(nested)
                    end
                end
            end
            scanUnsupported(attributes)
        else
            record.attributeError = safeToString(attributes)
            recordError(record.className, "<attributes>", record.attributeError)
        end

        for _, propertyName in ipairs(collectPropertyNames(db, record.className)) do
            local okValue, value = pcall(function()
                return instance[propertyName]
            end)
            if okValue then
                readablePropertyCount += 1
                record.properties[propertyName] = canonicalValue(value, pathByInstance)
                local valueType = typeof(value)
                if valueType ~= "nil" and valueType ~= "boolean" and valueType ~= "string" and valueType ~= "number" and valueType ~= "Vector2" and valueType ~= "Vector3" and valueType ~= "Vector2int16" and valueType ~= "Vector3int16" and valueType ~= "CFrame" and valueType ~= "Color3" and valueType ~= "Color3uint8" and valueType ~= "BrickColor" and valueType ~= "EnumItem" and valueType ~= "UDim" and valueType ~= "UDim2" and valueType ~= "NumberRange" and valueType ~= "Rect" and valueType ~= "PhysicalProperties" and valueType ~= "table" and valueType ~= "Instance" then
                    recordUnsupported(valueType)
                end
            else
                recordError(record.className, propertyName, safeToString(value))
            end
        end

        records[path] = record
    end

    return {
        records = records,
        pathByInstance = pathByInstance,
        readErrors = readErrors,
        unsupportedTypes = unsupportedTypes,
        readablePropertyCount = readablePropertyCount,
    }
end

local function cappedInsert(list, value, cap)
    if #list < cap then
        table.insert(list, value)
    end
end

local function compareSnapshots(before, after)
    local missingPaths = {}
    local extraPaths = {}
    local classDiffs = {}
    local nameDiffs = {}
    local propertyDiffs = {}
    local attributeDiffs = {}
    local propertyDiffCount = 0
    local attributeDiffCount = 0
    local sampleCap = 200

    for path, beforeRecord in pairs(before.records) do
        local afterRecord = after.records[path]
        if afterRecord == nil then
            cappedInsert(missingPaths, path, sampleCap)
        else
            if beforeRecord.className ~= afterRecord.className then
                table.insert(classDiffs, { path = path, before = beforeRecord.className, after = afterRecord.className })
            end
            if beforeRecord.name ~= afterRecord.name then
                table.insert(nameDiffs, { path = path, before = beforeRecord.name, after = afterRecord.name })
            end

            local propertyNames = {}
            for propertyName in pairs(beforeRecord.properties) do
                propertyNames[propertyName] = true
            end
            for propertyName in pairs(afterRecord.properties) do
                propertyNames[propertyName] = true
            end
            for _, propertyName in ipairs(sortedKeys(propertyNames)) do
                local beforeValue = beforeRecord.properties[propertyName]
                local afterValue = afterRecord.properties[propertyName]
                if beforeValue ~= afterValue then
                    propertyDiffCount += 1
                    cappedInsert(propertyDiffs, {
                        path = path,
                        property = propertyName,
                        before = beforeValue,
                        after = afterValue,
                    }, sampleCap)
                end
            end

            if beforeRecord.attributes ~= afterRecord.attributes or beforeRecord.attributeError ~= afterRecord.attributeError then
                attributeDiffCount += 1
                cappedInsert(attributeDiffs, {
                    path = path,
                    before = beforeRecord.attributes or beforeRecord.attributeError,
                    after = afterRecord.attributes or afterRecord.attributeError,
                }, sampleCap)
            end
        end
    end

    for path in pairs(after.records) do
        if before.records[path] == nil then
            cappedInsert(extraPaths, path, sampleCap)
        end
    end

    table.sort(missingPaths)
    table.sort(extraPaths)
    return {
        missingPaths = missingPaths,
        extraPaths = extraPaths,
        classDiffs = classDiffs,
        nameDiffs = nameDiffs,
        propertyDiffCount = propertyDiffCount,
        propertyDiffs = propertyDiffs,
        attributeDiffCount = attributeDiffCount,
        attributeDiffs = attributeDiffs,
    }
end

local function writeReport(report)
    fs.writeFile(reportPath, serde.encode("json", report))
end

print("Lune roundtrip: reading " .. inputPath)
local inputContents = fs.readFile(inputPath)
local db = roblox.getReflectionDatabase()

local okBeforeDeserialize, rootsBeforeOrError = pcall(function()
    return roblox.deserializeModel(inputContents)
end)
if not okBeforeDeserialize then
    writeReport({
        status = "deserialize_failed",
        inputPath = inputPath,
        inputBytes = #inputContents,
        error = safeToString(rootsBeforeOrError),
    })
    error(rootsBeforeOrError)
end

local rootsBefore = rootsBeforeOrError
local before = snapshot(rootsBefore, db)
local beforeCount = 0
for _ in pairs(before.records) do
    beforeCount += 1
end
print("Lune roundtrip: deserialized " .. tostring(#rootsBefore) .. " roots / " .. tostring(beforeCount) .. " instances")

local okSerialize, serializedOrError = pcall(function()
    return roblox.serializeModel(rootsBefore)
end)
if not okSerialize then
    writeReport({
        status = "serialize_failed",
        inputPath = inputPath,
        inputBytes = #inputContents,
        rootCountBefore = #rootsBefore,
        instanceCountBefore = beforeCount,
        readablePropertyCountBefore = before.readablePropertyCount,
        error = safeToString(serializedOrError),
        readErrorsBefore = before.readErrors,
        unsupportedTypesBefore = before.unsupportedTypes,
    })
    error(serializedOrError)
end

local serialized = serializedOrError
fs.writeFile(outputPath, serialized)
print("Lune roundtrip: wrote " .. tostring(#serialized) .. " bytes to " .. outputPath)

local okAfterDeserialize, rootsAfterOrError = pcall(function()
    return roblox.deserializeModel(serialized)
end)
if not okAfterDeserialize then
    writeReport({
        status = "roundtrip_deserialize_failed",
        inputPath = inputPath,
        outputPath = outputPath,
        inputBytes = #inputContents,
        outputBytes = #serialized,
        rootCountBefore = #rootsBefore,
        instanceCountBefore = beforeCount,
        readablePropertyCountBefore = before.readablePropertyCount,
        error = safeToString(rootsAfterOrError),
        readErrorsBefore = before.readErrors,
        unsupportedTypesBefore = before.unsupportedTypes,
    })
    error(rootsAfterOrError)
end

local rootsAfter = rootsAfterOrError
local after = snapshot(rootsAfter, db)
local afterCount = 0
for _ in pairs(after.records) do
    afterCount += 1
end
local comparison = compareSnapshots(before, after)

local report = {
    status = "ok",
    inputPath = inputPath,
    outputPath = outputPath,
    reportPath = reportPath,
    inputBytes = #inputContents,
    outputBytes = #serialized,
    rootCountBefore = #rootsBefore,
    rootCountAfter = #rootsAfter,
    instanceCountBefore = beforeCount,
    instanceCountAfter = afterCount,
    readablePropertyCountBefore = before.readablePropertyCount,
    readablePropertyCountAfter = after.readablePropertyCount,
    missingPathCount = #comparison.missingPaths,
    missingPaths = comparison.missingPaths,
    extraPathCount = #comparison.extraPaths,
    extraPaths = comparison.extraPaths,
    classDiffCount = #comparison.classDiffs,
    classDiffs = comparison.classDiffs,
    nameDiffCount = #comparison.nameDiffs,
    nameDiffs = comparison.nameDiffs,
    propertyDiffCount = comparison.propertyDiffCount,
    propertyDiffs = comparison.propertyDiffs,
    attributeDiffCount = comparison.attributeDiffCount,
    attributeDiffs = comparison.attributeDiffs,
    readErrorsBefore = before.readErrors,
    readErrorsAfter = after.readErrors,
    unsupportedTypesBefore = before.unsupportedTypes,
    unsupportedTypesAfter = after.unsupportedTypes,
}
writeReport(report)
print("Lune roundtrip: paths missing=" .. tostring(#comparison.missingPaths) .. " extra=" .. tostring(#comparison.extraPaths) .. ", property diffs=" .. tostring(comparison.propertyDiffCount) .. ", attribute diffs=" .. tostring(comparison.attributeDiffCount))
