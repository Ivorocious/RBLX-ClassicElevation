--!strict
local Restore = {}
local tolerance = .001

local function components(value)
    local kind = typeof(value)
    if kind == "CFrame" then return {value:GetComponents()}
    elseif kind == "Vector3" then return {value.X, value.Y, value.Z}
    elseif kind == "Vector2" then return {value.X, value.Y}
    elseif kind == "Color3" then return {value.R, value.G, value.B}
    elseif kind == "EnumItem" then return tostring(value)
    elseif kind == "BrickColor" then return value.Number
    elseif kind == "UDim" then return {value.Scale, value.Offset}
    elseif kind == "UDim2" then return {value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset}
    elseif kind == "NumberRange" then return {value.Min, value.Max}
    elseif kind == "NumberSequence" or kind == "ColorSequence" then
        local points = {}
        for _, point in value.Keypoints do
            table.insert(points, {time = point.Time, value = components(point.Value),
                envelope = if kind == "NumberSequence" then point.Envelope else nil})
        end
        return points
    end
    return value
end

local function records(roots)
    local objects, paths = {}, {}
    local function index(object, path)
        objects[path] = object; paths[object] = path
        local occurrences = {}
        for _, child in object:GetChildren() do
            local segment = child.Name .. ":" .. child.ClassName
            occurrences[segment] = (occurrences[segment] or 0) + 1
            index(child, path .. "/" .. segment .. "#" .. occurrences[segment])
        end
    end
    for _, root in roots do index(root, root.Name .. ":" .. root.ClassName) end
    local result, counts = {}, {instances = 0, parts = 0, meshes = 0}
    for path, object in objects do
        counts.instances += 1
        local attrs = {}
        for name, value in object:GetAttributes() do attrs[name] = components(value) end
        local row = {name = object.Name, class = object.ClassName, archivable = object.Archivable, attributes = attrs}
        if object:IsA("BasePart") then
            counts.parts += 1
            for _, property in {"CFrame", "PivotOffset", "Size", "Color", "Material", "MaterialVariant", "Transparency", "Reflectance",
                "Anchored", "CanCollide", "CanQuery", "CanTouch", "CollisionGroup", "Massless", "CastShadow", "RootPriority"} do
                row[property] = components(object[property])
            end
            local physical = object.CustomPhysicalProperties
            row.CustomPhysicalProperties = if physical then {physical.Density, physical.Friction, physical.Elasticity,
                physical.FrictionWeight, physical.ElasticityWeight} else false
            if object:IsA("Part") then row.Shape = tostring(object.Shape) end
        end
        if object:IsA("MeshPart") then
            counts.meshes += 1
            row.MeshId = object.MeshId; row.TextureID = object.TextureID
            row.CollisionFidelity = tostring(object.CollisionFidelity)
            row.RenderFidelity = tostring(object.RenderFidelity); row.DoubleSided = object.DoubleSided
        elseif object:IsA("Model") then
            row.pivot = components(object:GetPivot()); row.primaryPart = if object.PrimaryPart then paths[object.PrimaryPart] else false
        end
        result[path] = row
    end
    return result, counts
end

local function frameDifference(a, b)
    local left, right = {a:GetComponents()}, {b:GetComponents()}
    local maximum = 0
    for i, value in left do maximum = math.max(maximum, math.abs(value - right[i])) end
    return maximum
end

local function moveUnit(unit, requireVein)
    assert(unit:IsA("Model"), "Editable unit must be a Model: " .. unit.Name)
    local pivot = unit:GetPivot(); local offset = Vector3.new(3, 0, 0); local original = {}
    local count, veinFound = 0, false
    for _, object in unit:GetDescendants() do
        if object:IsA("BasePart") then
            original[object] = {frame = object.CFrame, relative = pivot:ToObjectSpace(object.CFrame)}
            count += 1; if object.Name == "WarningVein" then veinFound = true end
        end
    end
    local shiftError, relativeError, returnError = 0, 0, 0
    local ok, failure = xpcall(function()
        assert(count > 0, "Editable unit has no parts")
        assert(not requireVein or veinFound, "Leaf warning vein missing")
        unit:PivotTo(pivot + offset)
        local moved = unit:GetPivot()
        shiftError = (moved.Position - pivot.Position - offset).Magnitude
        for object, before in original do
            shiftError = math.max(shiftError, frameDifference(object.CFrame, before.frame + offset))
            relativeError = math.max(relativeError, frameDifference(moved:ToObjectSpace(object.CFrame), before.relative))
        end
    end, debug.traceback)
    local returned, returnFailure = pcall(function() unit:PivotTo(pivot) end)
    if returned then
        for object, before in original do returnError = math.max(returnError, frameDifference(object.CFrame, before.frame)) end
    end
    return {unit = unit.Name, passed = ok and returned and shiftError <= tolerance and relativeError <= tolerance and returnError <= tolerance,
        parts = count, warningVein = veinFound, maxShiftError = shiftError, maxRelativeError = relativeError, maxReturnError = returnError,
        error = if not ok then tostring(failure) elseif not returned then tostring(returnFailure) else nil}
end

function Restore.Run()
    local runService = game:GetService("RunService")
    assert(runService:IsStudio() and not runService:IsRunning(), "Studio Edit mode required")
    local storage = game:GetService("ServerStorage")
    local course = assert(workspace:FindFirstChild("Course_HeartwoodAscent"), "HA04 course missing")
    local libraries = assert(storage:FindFirstChild("AssetLibraries"), "AssetLibraries missing")
    local library = assert(libraries:FindFirstChild("HeartwoodV1HA04"), "HA04 library missing")
    assert(course:GetAttribute("HeartwoodBuild") == "HA_V1_04" and course:GetAttribute("Study") == false, "Wrong candidate")
    assert(course.Decoration.HeartwoodArt:GetAttribute("AssetLibrary") == library.Name, "Course/library mismatch")
    local differences, differenceCount, compared, maxDifference, unitChecks = {}, 0, 0, 0, {}
    local roundTrip, roundTripDifferenceCount, roundTripDifference = false, 0, 0
    local archive, restored, serializedBytes, inventory
    local function difference(path, reason)
        differenceCount += 1
        if #differences < 25 then table.insert(differences, {path = path, reason = reason}) end
    end
    local function equal(a, b, path)
        if typeof(a) ~= typeof(b) then difference(path, "value type differs"); return end
        if typeof(a) == "table" then
            for key, value in a do
                if b[key] == nil then difference(path .. "/" .. tostring(key), "missing value")
                else equal(value, b[key], path .. "/" .. tostring(key)) end
            end
            for key in b do if a[key] == nil then difference(path .. "/" .. tostring(key), "extra value") end end
        elseif typeof(a) == "number" then
            local delta = math.abs(a - b); maxDifference = math.max(maxDifference, delta)
            if delta > tolerance then difference(path, "numeric difference " .. tostring(delta)) end
        elseif a ~= b then difference(path, "value differs") end
    end
    local ok, failure = xpcall(function()
        local roots = {course, library}
        local before; before, inventory = records(roots)
        local serializer = game:GetService("SerializationService")
        local data = serializer:SerializeInstancesAsync(roots); serializedBytes = buffer.len(data)
        restored = serializer:DeserializeInstancesAsync(data)
        local history = storage:FindFirstChild("HeartwoodBuildHistory")
        if not history then history = Instance.new("Folder"); history.Name = "HeartwoodBuildHistory"; history.Parent = storage end
        archive = Instance.new("Folder"); archive.Name = "HA04NativeRestore_" .. game:GetService("HttpService"):GenerateGUID(false)
        archive.Parent = history
        for _, root in restored do root.Parent = archive end
        assert(#restored == 2, "Expected restored course and library")
        local after = records(restored)
        for path, row in before do
            compared += 1
            if not after[path] then difference(path, "restored instance missing") else equal(row, after[path], path) end
        end
        for path in after do if not before[path] then difference(path, "unexpected restored instance") end end
        roundTripDifferenceCount = differenceCount; roundTripDifference = maxDifference
        roundTrip = differenceCount == 0
        local copy = assert(archive:FindFirstChild("Course_HeartwoodAscent"), "Restored course missing")
        local branches = copy.Decoration.HeartwoodArt.BranchFamilies:GetChildren()
        table.sort(branches, function(a, b) return a.Name < b.Name end)
        assert(#branches > 0, "Restored branch families missing")
        for _, branch in branches do table.insert(unitChecks, moveUnit(branch, false)) end
        local forest = copy.Decoration.HeartwoodArt.ForestSurroundings
        local forestCount = 0
        for _, layer in forest:GetChildren() do
            if layer:IsA("Folder") then
                for _, tree in layer:GetChildren() do
                    if tree:IsA("Model") and tree:GetAttribute("WholeTree") == true then
                        table.insert(unitChecks, moveUnit(tree, false)); forestCount += 1
                    end
                end
            end
        end
        assert(forestCount == 26, "Expected 26 editable whole forest trees")
        local leaves = copy.Decoration.S03_HangingGardens.Leaves:GetChildren()
        table.sort(leaves, function(a, b) return a.Name < b.Name end)
        assert(#leaves == 3, "Expected three restored leaves")
        for _, leaf in leaves do table.insert(unitChecks, moveUnit(leaf, true)) end
        local returned = records(restored)
        for path, row in after do
            if not returned[path] then difference(path, "instance missing after unit checks") else equal(row, returned[path], path .. "/after-moves") end
        end
        local untouched = records(roots)
        for path, row in before do equal(row, untouched[path], path .. "/original-preserved") end
    end, debug.traceback)
    local editable = ok
    local maxUnitDifference = 0
    for _, check in unitChecks do
        editable = editable and check.passed
        maxUnitDifference = math.max(maxUnitDifference, check.maxShiftError, check.maxRelativeError, check.maxReturnError)
    end
    editable = editable and differenceCount == roundTripDifferenceCount
    return {candidate = "HA_V1_04", passed = ok and differenceCount == 0 and editable,
        nativeRoundTrip = roundTrip, editableUnits = editable, comparedInstances = compared,
        roots = restored and #restored or 0, inventory = inventory, serializedBytes = serializedBytes,
        differenceCount = differenceCount, differences = differences, maxNumericDifference = roundTripDifference,
        maxComparisonDifference = maxDifference,
        numericTolerance = tolerance, unitChecks = unitChecks, maxUnitDifference = maxUnitDifference,
        archive = archive and archive:GetFullName(), error = if not ok then tostring(failure) else nil,
        compared = "All names/classes/attributes; part transforms/sizes/collision flags/material/custom physics; exact mesh/texture IDs and CollisionFidelity",
        scope = "Native Studio Edit serialization and restored-copy editing only; no Runtime, autosave, publish or gameplay proof"}
end

return Restore
