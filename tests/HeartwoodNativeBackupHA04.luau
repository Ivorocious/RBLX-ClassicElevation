local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local path = "docs/artifacts/heartwood-ascent/v1/heartwood-v1-HA_V1_04.rbxm"
local bytes = fs.readFile(path)
local roots = roblox.deserializeModel(bytes)
assert(#roots == 2, "Expected course and template library")
local course, library
for _, root in roots do
    if root.Name == "Course_HeartwoodAscent" then course = root end
    if root.Name == "HeartwoodV1HA04" then library = root end
end
assert(course and library, "Native roots missing")
assert(course:GetAttribute("HeartwoodBuild") == "HA_V1_04", "Wrong candidate")
assert(course:GetAttribute("Study") == false, "Study candidate exported")
local artTriangles = course:GetAttribute("ArtTriangles")
assert(typeof(artTriangles) == "number" and artTriangles > 0, "Art inventory missing")
assert(course.Decoration.HeartwoodArt:GetAttribute("AssetLibrary") == library.Name, "Course references a different library")
assert(course.Decoration.S04_SanctuaryBough.J4:FindFirstChild("FinishWalk_1"), "J4 landing ramp missing")
local branchFamilies = #course.Decoration.HeartwoodArt.BranchFamilies:GetChildren()
assert(branchFamilies > 0, "Branch units missing")
local routeGreenery = #course.Decoration.HeartwoodArt.RouteGreenery:GetChildren()
local buttressRoots = #course.Decoration.HeartwoodArt.ButtressRoots:GetChildren()
assert(routeGreenery > 0 and buttressRoots > 0, "Route greenery or buttress roots missing")
assert(#library:GetChildren() > 0 and library:FindFirstChild("HA_LeafCollisionChecked"), "Template library incomplete")
local function meshId(item)
    local ok, id = pcall(function() return item.MeshId end)
    return if ok then id else tostring(item.MeshContent)
end
local parts, meshes, unique, ids = 0, 0, 0, {}
for _, item in course:GetDescendants() do
    if item:IsA("BasePart") then parts += 1 end
    if item:IsA("MeshPart") then
        meshes += 1
        local id = meshId(item)
        assert(id ~= "", "Empty mesh content")
        if not ids[id] then ids[id] = true; unique += 1 end
    end
    assert(not item.Name:find("Study", 1, true) and not item.Name:find("Verification", 1, true), "Temporary object in candidate")
end
assert(parts > 0 and meshes > 0 and unique > 0, "Native course inventory empty")
local function records(items)
    local out = {}
    local function visit(item, key)
        local row = {class = item.ClassName, attrs = item:GetAttributes()}
        if item:IsA("BasePart") then
            row.frame = {item.CFrame:GetComponents()}
            row.size = {item.Size.X, item.Size.Y, item.Size.Z}
            row.flags = {item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch, item.Transparency}
        end
        if item:IsA("MeshPart") then
            row.mesh = meshId(item)
            local ok, fidelity = pcall(function() return item.CollisionFidelity end)
            row.fidelity = if ok then tostring(fidelity) else "Unavailable in local reader"
        end
        out[key] = row
        local counts = {}
        for _, child in item:GetChildren() do
            local name = child.Name .. ":" .. child.ClassName
            counts[name] = (counts[name] or 0) + 1
            visit(child, key .. "/" .. name .. "#" .. counts[name])
        end
    end
    for _, root in items do visit(root, root.Name .. ":" .. root.ClassName) end
    return out
end
local before = records(roots)
local restored = roblox.deserializeModel(roblox.serializeModel(roots))
local after = records(restored)
local compared, maxDifference = 0, 0
local function equal(a, b)
    if typeof(a) ~= typeof(b) then return false end
    if typeof(a) == "table" then
        for k, value in a do if not equal(value, b[k]) then return false end end
        for k in b do if a[k] == nil then return false end end
        return true
    elseif typeof(a) == "number" then
        maxDifference = math.max(maxDifference, math.abs(a - b))
        return math.abs(a - b) < .001
    elseif typeof(a) == "Vector3" then
        maxDifference = math.max(maxDifference, (a - b).Magnitude)
        return (a - b).Magnitude < .001
    elseif typeof(a) == "CFrame" then
        return equal({a:GetComponents()}, {b:GetComponents()})
    end
    return a == b
end
for key, row in before do
    assert(after[key] and equal(row, after[key]), "Restore mismatch at " .. key)
    compared += 1
end
for key in after do assert(before[key], "Unexpected restored instance " .. key) end
local report = {candidate = "HA_V1_04", path = path, reopened = true, roundTrip = true, roots = #roots,
    parts = parts, meshes = meshes, uniqueMeshes = unique, libraryTemplates = #library:GetChildren(),
    assetLibrary = library.Name, artTriangles = artTriangles, branchFamilies = branchFamilies,
    routeGreenery = routeGreenery, buttressRoots = buttressRoots,
    inventoryPolicy = "Observed current HA04 counts; final inventory is not frozen in this recipe",
    comparedInstances = compared, maxNumericDifference = maxDifference,
    compared = "Names, hierarchy, attributes, BasePart transforms/sizes/collision flags and mesh content",
    readerLimitation = "This Lune reflection database cannot read CollisionFidelity; verify it in native Studio separately",
    scope = "Local native serialization comparison; not gameplay or cloud moderation acceptance"}
fs.writeFile("docs/artifacts/heartwood-ascent/v1/native-backup-reopen-HA_V1_04.json", serde.encode("json", report, true))
print(serde.encode("json", report))
