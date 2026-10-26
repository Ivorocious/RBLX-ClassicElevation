local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local own = "tools/moonlit-citadel/phase3/repair-20261019/depth/"
local source = "src/ServerStorage/CourseBuilders/MoonlitCitadelCourse/"
local packetPath = "docs/artifacts/moonlit-citadel/phase3/detail-pass-20261014/source54/source54-packet.json"
local packetRaw = fs.readFile(packetPath)
local packet = serde.decode("json", packetRaw)
assert(packet.sourceRevision == 54 and packet.buildRevision == 48)
local records, hashes = {}, {}
for _, row in packet.records do records[row.name] = row end
local configPath = "src/ReplicatedStorage/Config/MoonlitCitadelCourseConfig.luau"
local configRaw = fs.readFile(configPath)
local config = luau.load(configRaw, {environment = {Vector3 = roblox.Vector3}})()
local cache, loading = {}, {}
local parent = setmetatable({}, {__index = function(_, name) return {moduleName = name} end})
local function load(name)
    if cache[name] then return cache[name] end
    assert(not loading[name], "Module cycle " .. name)
    loading[name] = true
    local row = assert(records[name], "Missing frozen module " .. name)
    local raw = fs.readFile(source .. name .. ".luau"):gsub("\r\n", "\n")
    assert(raw == row.source:gsub("\r\n", "\n") and serde.hash("sha256", raw) == row.sha256, "Source54 parity " .. name)
    hashes[name] = row.sha256
    local result = luau.load(raw, {environment = {
        Vector3 = roblox.Vector3, CFrame = roblox.CFrame, Color3 = roblox.Color3,
        script = {Parent = parent}, game = {ReplicatedStorage = {Config = {MoonlitCitadelCourseConfig = config}}},
        require = function(value) return if type(value) == "table" and value.moduleName then load(value.moduleName) else value end,
    }})()
    cache[name], loading[name] = result, nil
    return result
end
local layout, world = load("Layout"), load("WorldPlan")
local plan, architecture = world.Get(layout)
local planned = {}
for _, unit in plan do planned[unit.name] = unit end
local supports = {}
for _, seat in architecture.groundSeats do
    local unit = assert(planned[seat.name])
    local metadata = assert(world.AssetGeometry[unit.asset])
    local boxes = metadata.occupied or {{low = metadata.center - metadata.size / 2, high = metadata.center + metadata.size / 2}}
    local touching = {}
    for index, box in boxes do
        local frame = unit.localCF * roblox.CFrame.new((box.low + box.high) / 2 * unit.scale)
        local size = (box.high - box.low) * unit.scale
        if frame.Position.Y - size.Y / 2 <= seat.bottomY + seat.burialStuds + .05
            and frame.Position.Y + size.Y / 2 >= seat.bottomY then
            table.insert(touching, {index = index, frame = frame, size = size})
        end
    end
    assert(#touching > 0, "Ground seat lacks actual occupied support " .. seat.name)
    table.insert(supports, {name = seat.name, asset = unit.asset, bottomY = seat.bottomY, boxes = touching})
end
local function encode(value)
    local kind = typeof(value)
    if kind == "Vector3" then return {value.X, value.Y, value.Z} end
    if kind == "CFrame" then return {value:GetComponents()} end
    if kind == "Color3" then return {value.R, value.G, value.B} end
    if kind == "table" then
        local result = {}
        for key, item in value do result[key] = encode(item) end
        return result
    end
    return value
end
local report = {
    sourceRevision = 54, buildRevision = 48, packetPath = packetPath,
    packetSha256 = serde.hash("sha256", packetRaw), inputHashes = hashes,
    courseConfigSha256 = serde.hash("sha256", configRaw), origin = encode(config.Origin),
    groundSeats = encode(architecture.groundSeats), groundContactBoxes = encode(supports), plantingMounts = encode(architecture.plantingMounts),
    architectureUnits = architecture.units, plan = encode(plan),
    fallYLocal = -23, physicsChanged = false, nativeVerified = false,
}
fs.writeFile(own .. "source54-depth-inputs.json", serde.encode("json", report, true))
print(serde.encode("json", {groundSeats = #architecture.groundSeats, architectureUnits = architecture.units, source54Parity = true}))
