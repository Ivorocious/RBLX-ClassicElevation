local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Studio Edit only")
assert(game.PlaceId == 85558151074819 and game.CreatorId == 86069177, "Wrong destination")
local root = workspace.MoonlitCitadelPhase1_BL01
assert(root:GetAttribute("CandidateId") == "MC_P1_BL01", "Expected the preserved BL01 first assembly")
local source = game.ServerStorage.CourseBuilders.MoonlitCitadel
local snapshotName = "Moonlit_BL01_R02_BuilderSnapshot"
assert(not game.ServerStorage:FindFirstChild(snapshotName), "Preserve the existing repair snapshot")
local snapshot = Instance.new("Folder")
snapshot.Name, snapshot.Parent = snapshotName, game.ServerStorage
local configModule = game.ReplicatedStorage.Config.MoonlitCitadelConfig:Clone()
configModule.Name, configModule.Parent = "Config", snapshot
for _, name in {"Kit", "Installer", "MeshKit", "BlenderInstaller"} do
	local module = source[name]:Clone()
	module.Source = module.Source:gsub("require%(game.ReplicatedStorage.Config.MoonlitCitadelConfig%)", "require(script.Parent.Config)")
	module.Parent = snapshot
end
local config = require(configModule)
assert(config.BlenderCandidateId == "MC_P1_BL01_R02", "Wait for current Rojo source before repair")
local recovery = Instance.new("Folder")
recovery.Name, recovery.Parent = "Moonlit_BL01_GeometryRecovery", game.ServerStorage
local oldReturn = root.UpperSample.CatchReturn
oldReturn:SetAttribute("ArchivedReason", "Folded return blocked real avatar headroom; preserved before side ramp replacement")
oldReturn.Parent = recovery
require(snapshot.BlenderInstaller).AddCatchReturn(root.UpperSample, config.SampleOrigin + config.BlenderOffset)
for _, cage in root.LanternStudy.SwingLanterns:GetChildren() do
	local core = cage.CageAndCore.MC_LanternCore:FindFirstChildWhichIsA("BasePart", true)
	assert(core and not core:FindFirstChild("AmberLight"), "Expected an unlit imported lantern core")
	local light = Instance.new("PointLight")
	light.Name, light.Color = "AmberLight", Color3.fromRGB(255, 188, 75)
	light.Brightness, light.Range, light.Shadows = 1.2, 12, false
	light.Parent = core
end
root:SetAttribute("CandidateId", config.BlenderCandidateId)
root:SetAttribute("PreviewEnabled", false)
root:SetAttribute("AssemblyRevision", "R02: open side catch return and modest moving lantern light")
return {candidate = root:GetAttribute("CandidateId"), descendants = #root:GetDescendants(), preservedReturn = oldReturn:GetFullName()}
