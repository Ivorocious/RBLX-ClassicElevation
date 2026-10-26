-- Run in Studio Edit mode after syncing the B09 builder and manifest.
assert(game.PlaceId == 85558151074819, "Wrong place")
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before applying")
local storage = game:GetService("ServerStorage")
local lobby = workspace.Lobby
assert(lobby:GetAttribute("BlenderRevision") == "B08", "Expected the existing B08 lobby")
local archive = storage.LobbyArchive
assert(not archive:FindFirstChild("BlenderLobbyB08BeforeB09"), "Backup already exists; inspect before reapplying")
local builders = storage.CourseBuilders.LobbyBuilders
local installer = builders.BlenderComparison:Clone()
local manifest = builders.BlenderManifest:Clone()
installer.Name, manifest.Name = "B09Installer", "B09Manifest"
installer.Parent, manifest.Parent = storage, storage
local candidate = require(installer).Install("SkycourtB09Import", require(manifest), "LobbyB09AuthoredCandidate")
candidate.Parent = storage
local backup = lobby:Clone()
backup.Name, backup.Parent = "BlenderLobbyB08BeforeB09", archive

-- Only these merged meshes contain the sign; the other podium pieces stay in place.
local oldMeshes = Instance.new("Folder")
oldMeshes.Name, oldMeshes.Parent = "B08PodiumSignMeshes", archive
local names = { "Monument__Gold__00", "Monument__Pale__00", "Monument__DeepBlue__00" }
for _, name in names do
    local previous = lobby.Podium.Monument:FindFirstChild(name)
    assert(previous, "Missing original podium mesh " .. name)
    previous.Parent = oldMeshes
    local replacement = candidate.Podium.Monument:FindFirstChild(name)
    if replacement then replacement.Parent = lobby.Podium.Monument end
end
local added = {}
for _, component in candidate.Editable["01_Lower"]:GetChildren() do
    if component.Name:match("^Lower_GrandPillar_") or component.Name:match("^Lower_FloorInlay_")
        or component.Name:match("^Lower_SocialBench_") or component.Name:match("^Lower_SocialGarden_") then
        assert(not lobby.Editable["01_Lower"]:FindFirstChild(component.Name), "Component already exists")
        table.insert(added, component.Name)
        component.Parent = lobby.Editable["01_Lower"]
    end
end
assert(#added == 8, "Expected eight new editable components")
lobby:SetAttribute("BlenderRevision", "B09")
lobby:SetAttribute("ManualEditsPreservedFrom", "B08")
return { revision = "B09", added = added, backup = backup:GetFullName() }
