assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Studio Edit only")
assert(game.PlaceId == 85558151074819 and game.CreatorId == 86069177, "Wrong destination")
local root = workspace.MoonlitCitadelPhase1_BL01
assert(root:GetAttribute("CandidateId") == "MC_P1_BL01_R03", "Expected BL01 R03")
local recovery = game.ServerStorage.Moonlit_BL01_GeometryRecovery
assert(not recovery:FindFirstChild("CP03_R03"), "Preserve prior recovery")
local configModule = game.ReplicatedStorage.Config.MoonlitCitadelConfig:Clone()
configModule.Name, configModule.Parent = "Cp03RepairConfig", recovery
local config = require(configModule)
assert(config.BlenderCandidateId == "MC_P1_BL01_R04", "Wait for current Rojo source")
local prior = Instance.new("Folder")
prior.Name, prior.Parent = "CP03_R03", recovery
local waitPart, checkpoint = root.RoughRoute.CP03Wait, root.RoughRoute.Checkpoints.CP03
for _, part in {waitPart, checkpoint} do part:Clone().Parent = prior end
local delta = Vector3.new(0, 0, -14)
waitPart.CFrame += delta
checkpoint.CFrame += delta
checkpoint:SetAttribute("RecoveryCFrame", checkpoint:GetAttribute("RecoveryCFrame") + delta)
root:SetAttribute("CandidateId", config.BlenderCandidateId)
root:SetAttribute("AssemblyRevision", "R04: CP03 wait clear of rising gallery join; R03 gallery and R02 catch/light retained")
return {candidate = root:GetAttribute("CandidateId"), waitPosition = tostring(waitPart.Position), recovery = tostring(checkpoint:GetAttribute("RecoveryCFrame"))}
