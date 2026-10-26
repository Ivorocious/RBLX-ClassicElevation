assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Studio Edit only")
assert(game.PlaceId == 85558151074819 and game.CreatorId == 86069177, "Wrong destination")
local root = workspace.MoonlitCitadelPhase1_BL01
assert(root:GetAttribute("CandidateId") == "MC_P1_BL01_R04", "Expected BL01 R04")
local recovery = game.ServerStorage.Moonlit_BL01_GeometryRecovery
local previous = root.RoughRoute:FindFirstChild("GalleryToLifts") or recovery:FindFirstChild("GalleryToLifts_R04")
assert(previous, "The current or preserved join must exist")
assert(not recovery:FindFirstChild("RoughJoinBuilderSnapshot_R05_Fixed"), "Preserve prior builder snapshots")
local snapshot = Instance.new("Folder")
snapshot.Name, snapshot.Parent = "RoughJoinBuilderSnapshot_R05_Fixed", recovery
local configModule = game.ReplicatedStorage.Config.MoonlitCitadelConfig:Clone()
configModule.Name, configModule.Parent = "Config", snapshot
local source = game.ServerStorage.CourseBuilders.MoonlitCitadel
for _, name in {"Kit", "Installer"} do
	local module = source[name]:Clone()
	module.Source = module.Source:gsub("require%(game.ReplicatedStorage.Config.MoonlitCitadelConfig%)", "require(script.Parent.Config)")
	module.Parent = snapshot
end
local config = require(configModule)
assert(config.BlenderCandidateId == "MC_P1_BL01_R05", "Wait for current Rojo source")
local staging = Instance.new("Model")
staging.Name, staging.Parent = "R05_JoinStaging", recovery
local replacement = require(snapshot.Installer).AddGalleryToLifts(staging, config.RoughOrigin + config.BlenderOffset)
assert(#replacement:GetChildren() > 0, "Build and validate the join before touching the current route")
previous.Name, previous.Parent = "GalleryToLifts_R04", recovery
replacement.Parent = root.RoughRoute
root:SetAttribute("CandidateId", config.BlenderCandidateId)
root:SetAttribute("AssemblyRevision", "R05: longer gallery rise avoids early upper landing; prior gallery/catch/light repairs retained")
return {candidate = root:GetAttribute("CandidateId"), descendants = #root:GetDescendants(), preservedJoin = previous:GetFullName()}
