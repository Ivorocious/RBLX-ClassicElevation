-- Run once in Edit mode, after verified native backups.
assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning(), "Wrong place or mode")
local storage = game:GetService("ServerStorage")
assert(not storage:GetAttribute("DevelopmentCleanup20260922"), "Cleanup already applied")
local preview = assert(workspace:FindFirstChild("CityRunV3Stage2Preview"), "Visible V3 is missing")
local course = assert(preview:FindFirstChild("RaceCourse"), "V3 course missing")
local context = assert(preview:FindFirstChild("Context"), "V3 surroundings missing")
assert(course:GetAttribute("CityRunV3Build") == "V3_FINAL_03C", "Unexpected V3 build")
local transforms = {}
for _, root in {course, context} do
    for _, part in root:GetDescendants() do
        if part:IsA("BasePart") then transforms[part] = {part.CFrame, part.Size} end
    end
end
local function folder(parent, name, description)
    local item = parent:FindFirstChild(name)
    if not item then item = Instance.new("Folder"); item.Name = name; item.Parent = parent end
    assert(item:IsA("Folder"), "Expected folder " .. name)
    if description then item:SetAttribute("Purpose", description) end
    return item
end
local archive = folder(storage, "Archive", "Preserved old builds. Never used as the active map.")
local cityArchive = folder(archive, "CityRun", "V1, V2, old V3 snapshots and prior construction stages.")
local lobbyArchive = folder(archive, "Lobby", "Older lobby candidates and imported revisions.")
local legacyTools = folder(archive, "LegacyTools", "One-off installers and verification modules; not startup code.")
local loose = folder(archive, "LooseWorkspace", "Loose and floating assets preserved from Workspace on 2026-09-22.")
local assets = folder(storage, "DeveloperAssets", "Reusable models: duplicate a template into the editable map.")
local libraries = folder(storage, "AssetLibraries", "Reusable mesh libraries used by builders.")
local imports = folder(storage, "AssetImports", "Original import packages used by builders.")
local moves = {}
local function move(item, destination)
    local original = item:GetFullName()
    item:SetAttribute("ArchivedFrom", original)
    item.Parent = destination
    table.insert(moves, {from=original, to=item:GetFullName()})
end
local old = workspace:FindFirstChild("Course_CityRun")
if old then move(old, cityArchive); old.Name = "CityRun_V1_Editable" end
for _, item in storage:GetChildren() do
    local name = item.Name
    if item == archive or item == assets or item == libraries or item == imports
        or name == "CourseLibrary" or name == "CourseBuilders" or name == "__Rojo_SessionLock" then continue end
    if name == "CityRunInspectionSources" then
        item:SetAttribute("Enabled", false)
        move(item, cityArchive)
    elseif item:IsA("ModuleScript") then move(item, legacyTools)
    elseif name == "ClassicStudKit_V1" or name == "MedievalStudShowcase_M02" or name == "CourseTemplates" then move(item, assets)
    elseif string.find(name, "MeshLibrary", 1, true) or name == "CityRunFinal03Library" then move(item, libraries)
    elseif name == "AscentPropsImportV5" or name == "AscentPropsImportV7" or name == "LobbyPropsImport" or name == "SkycourtB10Import" then move(item, imports)
    elseif string.find(name, "Skycourt", 1, true) or string.find(name, "Lobby", 1, true) then move(item, lobbyArchive)
    else move(item, cityArchive) end
end
for _, item in workspace:GetChildren() do
    if item == preview or item.Name == "Lobby" or item:IsA("Camera") or item:IsA("Terrain") then continue end
    if item.Name == "ObstacleKit_Palette" or item.Name == "DepthIllusionKit" then move(item, assets)
    elseif item.Name == "CityRunV3AssetReview" then move(item, cityArchive)
    else move(item, loose) end
end
context.Name = "Surroundings"
context.Parent = course
course.Name = "Course_CityRun"
course:SetAttribute("ManualEditing", true)
course:SetAttribute("EditingSource", "Edit this model before Play. Play uses a fresh runtime copy.")
course:SetAttribute("MapVersion", "V3")
course.CourseInfo:SetAttribute("DisplayName", "City Run V3")
course.Parent = workspace
move(preview, cityArchive)
preview.Name = "V3_PreviousPreviewContainer"
local palette = assets:FindFirstChild("ObstacleKit_Palette")
if palette then palette:SetAttribute("Placement", "Duplicate a numbered model from CopyThese into Workspace.Course_CityRun.Obstacles in Edit mode") end
local checked = 0
for part, before in transforms do
    assert(part:IsDescendantOf(course) and part.CFrame == before[1] and part.Size == before[2], "V3 geometry changed: " .. part.Name)
    checked += 1
end
local receipt = Instance.new("StringValue")
receipt.Name = "DevelopmentCleanup20260922"
receipt.Value = game:GetService("HttpService"):JSONEncode({moves=moves, preservedParts=checked})
receipt.Parent = archive
storage:SetAttribute("DevelopmentCleanup20260922", true)
return {moves=#moves, preservedParts=checked, active=course:GetFullName(), descendants=#course:GetDescendants()}
