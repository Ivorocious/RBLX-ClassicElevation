-- Run in Studio Edit mode only when this cleanup needs to be reversed.
assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
local holder = assert(workspace:FindFirstChild("ServerStorageCleanupRestore"), "Load the backup into this temporary folder first")
local storage = game:GetService("ServerStorage")
local names = {"DeveloperArchives", "Archive", "MoonlitP3ReworkRecovery", "LobbyAmenityIterations", "__LobbyPreservationProbe"}
local roots = {}
for _, name in names do
    assert(not storage:FindFirstChild(name), "Existing root must be reviewed before restoring: " .. name)
    table.insert(roots, assert(holder:FindFirstChild(name), "Missing backup root: " .. name))
end
local function child(parent, name)
    local matches = {}
    for _, item in parent:GetChildren() do if item.Name == name then table.insert(matches, item) end end
    assert(#matches == 1, "Missing or ambiguous restore path: " .. parent:GetFullName() .. "." .. name)
    return matches[1]
end
local archive = child(child(holder, "DeveloperArchives"), "MoonlitCitadel")
local links = {}
local previous = child(archive, "Cleanup20261019")
for index = 1, 12 do
    local pointer = child(child(previous, string.format("%02d", index)), "OriginalParent")
    table.insert(links, {pointer, if index <= 3 then workspace else storage})
end
local current = child(child(archive, "Cleanup20261020"), "RestoreLinks")
for index = 94, 97 do table.insert(links, {child(child(current, string.format("%03d", index)), "OriginalParent"), storage}) end
local lights = {}
for _, name in {"Sky", "Atmosphere", "Bloom", "SunRays"} do
    lights[child(holder, name)] = child(game:GetService("Lighting"), name)
end
local lightingLinks = 0
for _, root in roots do
    for index, item in root:GetDescendants() do
        if index % 1000 == 0 then task.wait() end
        if item:IsA("ObjectValue") and item.Value and lights[item.Value] then
            table.insert(links, {item, lights[item.Value]})
            lightingLinks += 1
        end
    end
end
assert(lightingLinks == 96, "Unexpected lighting reference count")
for _, link in links do assert(link[1]:IsA("ObjectValue")) end
for _, link in links do link[1].Value = link[2] end
for _, root in roots do root.Parent = storage; task.wait() end
print("Restored five ServerStorage roots and 112 external references; current courses and Lighting were retained.")
