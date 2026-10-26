local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Studio Edit only")
assert(game.PlaceId == 85558151074819 and game.CreatorId == 86069177, "Wrong destination")
local source = game.ServerStorage.CourseBuilders.MoonlitCitadel
local name = "Moonlit_BL01_BuilderSnapshot"
assert(not game.ServerStorage:FindFirstChild(name), "Preserve the existing builder snapshot")
local snapshot = Instance.new("Folder")
snapshot.Name, snapshot.Parent = name, game.ServerStorage
snapshot:SetAttribute("Reason", "Fresh Edit require context; preserve Rojo modules and previous caches")
local config = game.ReplicatedStorage.Config.MoonlitCitadelConfig:Clone()
config.Name, config.Parent = "Config", snapshot
for _, moduleName in {"Kit", "Installer", "MeshKit", "BlenderInstaller"} do
	local module = source[moduleName]:Clone()
	module.Source = module.Source:gsub("require%(game.ReplicatedStorage.Config.MoonlitCitadelConfig%)", "require(script.Parent.Config)")
	module.Parent = snapshot
end
local root = require(snapshot.BlenderInstaller).Build()
return game:GetService("HttpService"):JSONEncode({name=root.Name,candidate=root:GetAttribute("CandidateId"),descendants=#root:GetDescendants()})
