local fs, roblox, serde = require("@lune/fs"), require("@lune/roblox"), require("@lune/serde")
local own = "tools/moonlit-citadel/phase3/repair-20261019/depth/"
local input = "docs/artifacts/moonlit-citadel/phase3/repair-20261019/repair_before_models.rbxm"
local bytes = fs.readFile(input)
local hash = serde.hash("sha256", bytes)
assert(hash == "c7cb26d6c08ffd1251844fb5076396ab846069f9247e971abec92dac8506d158")
local models = roblox.deserializeModel(bytes)
assert(#models == 2)
local rows = {}
for index, course in models do
    local origin = course:GetAttribute("Origin")
    assert(course.Name == "Course_MoonlitCitadel" and course:GetAttribute("SourceRevision") == 54
        and course:GetAttribute("BuildRevision") == 48 and origin == roblox.Vector3.new(4000, 300, 2600))
    local unit = course.Decoration.Phase3World.JoinedRavineRidges.MC_EC_InnerRavine
    local parts = {}
    for _, part in unit:GetDescendants() do
        if part:IsA("BasePart") then
            assert(part:IsA("MeshPart") and part.Anchored and not part.CanCollide and not part.CanQuery and not part.CanTouch)
            local idReadable, meshId = pcall(function() return part.MeshId end)
            local contentReadable, meshContent = pcall(function() return part.MeshContent end)
            table.insert(parts, {name = part.Name, meshId = if idReadable then meshId else nil,
                meshIdReadableInLune = idReadable, meshContent = if contentReadable then tostring(meshContent) else nil,
                localCF = {(roblox.CFrame.new(-origin) * part.CFrame):GetComponents()},
                size = {part.Size.X, part.Size.Y, part.Size.Z},
                material = part.Material.Name, color = {part.Color.R, part.Color.G, part.Color.B}})
        end
    end
    assert(#parts == 3)
    table.insert(rows, {index = index, sourceRevision = 54, buildRevision = 48,
        unit = "Decoration/Phase3World/JoinedRavineRidges/MC_EC_InnerRavine", parts = parts,
        fallY = course:GetAttribute("FallY"), packetHash = course:GetAttribute("SourcePacketHash")})
end
fs.writeFile(own .. "fresh54-depth-binding.json", serde.encode("json", {
    pass = true, path = input, bytes = #bytes, sha256 = hash, models = rows,
    savedFileReadOnly = true, studioTouched = false, geometryImportVerified = false,
}, true))
print(serde.encode("json", {pass = true, models = #rows, terrainPartsPerModel = 3, sha256 = hash}))
