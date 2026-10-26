assert(game.PlaceId == 85558151074819, "Wrong place")
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before applying")
local storage = game.ServerStorage
local lobby = workspace.Lobby
assert(lobby:GetAttribute("BlenderRevision")=="B09", "Expected B09")
local archive = storage.LobbyArchive
assert(not archive:FindFirstChild("BlenderLobbyB09BeforeB10"), "Backup already exists")
local builders = storage.CourseBuilders.LobbyBuilders
local installer, manifest = builders.BlenderComparison:Clone(), builders.BlenderManifest:Clone()
installer.Name, manifest.Name = "B10Installer", "B10Manifest"
installer.Parent, manifest.Parent = storage, storage
local candidate = require(installer).Install("SkycourtB10Import",require(manifest),"LobbyB10AuthoredCandidate")
candidate.Parent = storage
local backup = lobby:Clone()
backup.Name, backup.Parent = "BlenderLobbyB09BeforeB10", archive
local replaced = Instance.new("Folder")
replaced.Name, replaced.Parent = "B09SocialGardens", archive
local lower = lobby.Editable["01_Lower"]
local added = {}
for _, group in candidate.Editable["01_Lower"]:GetChildren() do
	if group.Name:match("^Lower_Ceiling_") or group.Name=="Lower_GatheringCrest"
		or group.Name=="Lower_RouteInlays" or group.Name=="Lower_RecordsCrest" or group.Name:match("^Lower_SocialGarden_") then
		local old = lower:FindFirstChild(group.Name)
		if old then old.Parent = replaced end
		group.Parent = lower
		table.insert(added, group.Name)
	end
end
assert(#added==8, "Expected eight finish groups")
candidate.Podium.MonumentFinish.Parent = lobby.Podium
lobby:SetAttribute("BlenderRevision","B10")
return {revision="B10",groups=added,backup=backup:GetFullName()}
