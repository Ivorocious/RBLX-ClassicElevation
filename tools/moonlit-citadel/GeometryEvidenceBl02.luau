local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local base = "docs/artifacts/moonlit-citadel/phase1/"
local r01 = roblox.deserializeModel(fs.readFile(base .. "MC_BL02_R01_native.rbxm"))[1]
local current = roblox.deserializeModel(fs.readFile(base .. "MC_BL02_R04_native.rbxm"))[1]
local previous = roblox.deserializeModel(fs.readFile(base .. "MC_BL01_R05_native.rbxm"))[1]
local function relative(instance, root)
    local names = {}
    while instance ~= root do
        local ordinal = 0
        for _, sibling in instance.Parent:GetChildren() do
            if sibling.Name == instance.Name and sibling.ClassName == instance.ClassName then ordinal += 1 end
            if sibling == instance then break end
        end
        table.insert(names, 1, instance.Name .. "#" .. ordinal)
        instance = instance.Parent
    end
    return table.concat(names, "/")
end
local function index(root)
    local result = {}
    for _, part in root:GetDescendants() do
        if part:IsA("BasePart") then result[relative(part, root)] = part end
    end
    return result
end
local priorParts, currentParts, oldParts = index(r01), index(current), index(previous)
local preserved, contacts = 0, 0
for path, part in priorParts do
    if path:match("^RoughRoute#%d+/E1_InnerDiagonal#%d+/") then continue end
    local current = assert(currentParts[path], path)
    assert(current.Size == part.Size and current.CFrame == part.CFrame, path)
    assert(current.CanCollide == part.CanCollide and current.CanQuery == part.CanQuery and current.CanTouch == part.CanTouch, path)
    preserved += 1
end
for path, part in currentParts do
    if not part.CanCollide or not (path:match("^UpperSample#%d+/") or path:match("^LanternStudy#%d+/")) then continue end
    local old = assert(oldParts[path], path)
    assert(old.CanCollide and old.Size == part.Size, path)
    assert((old.CFrame.Position + roblox.Vector3.new(0, 0, 350) - part.CFrame.Position).Magnitude < 0.0001, path)
    assert((old.CFrame.RightVector - part.CFrame.RightVector).Magnitude < 0.00001, path)
    assert((old.CFrame.UpVector - part.CFrame.UpVector).Magnitude < 0.00001, path)
    contacts += 1
end
local counts = {baseParts = 0, meshParts = 0, colliders = 0, visibleShadowCasters = 0, lights = 0, shadowedLights = 0}
local meshIds = {}
for _, part in current:GetDescendants() do
    if part:IsA("BasePart") then
        counts.baseParts += 1
        if part.CanCollide then counts.colliders += 1 end
        if part.Transparency < 1 and part.CastShadow then counts.visibleShadowCasters += 1 end
    end
    if part:IsA("MeshPart") then
        counts.meshParts += 1
        meshIds[tostring(part:GetAttribute("SourceAsset")) .. "|" .. tostring(part:GetAttribute("SourceMaterial"))] = true
        assert(not part.CanCollide and not part.CanTouch, part:GetFullName())
        if part.CanQuery then assert(relative(part, current):match("/CageAndCore#%d+/"), part:GetFullName()) end
    end
    if part:IsA("Light") then
        counts.lights += 1
        if part.Shadows then counts.shadowedLights += 1 end
    end
end
counts.uniqueImportedMaterialGroups = 0
for _ in meshIds do counts.uniqueImportedMaterialGroups += 1 end
assert(contacts == 67, "Expected 67 unchanged upper/lantern colliders; found " .. contacts)
local result = {candidate = "MC_P1_BL02_R04", counts = counts, unchangedR01PartsOutsideExpertArch = preserved,
    unchangedUpperAndLanternCollidersFromBL01 = contacts, oldSampleTranslation = {0, 0, 350},
    scope = "Saved-file geometry identity and resource counts. R01 sample checks remain bound to the unchanged R04 upper/lantern geometry; the revised rough branches require fresh continuous runs."}
fs.writeFile(base .. "MC_BL02_R04_geometry_evidence.json", serde.encode("json", result, true))
print(serde.encode("json", result))
