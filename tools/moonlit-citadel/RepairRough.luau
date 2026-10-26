assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning(), "Studio Edit only")
assert(game.PlaceId == 85558151074819 and game.CreatorId == 86069177, "Wrong destination")
local root = workspace.MoonlitCitadelPhase1_BL01
assert(root:GetAttribute("CandidateId") == "MC_P1_BL01_R02", "Expected the current BL01 R02 sample")
local recovery = game.ServerStorage.Moonlit_BL01_GeometryRecovery
assert(not recovery:FindFirstChild("H2_ThreeBands_R02"), "Preserve prior gallery recovery")
local configModule = game.ReplicatedStorage.Config.MoonlitCitadelConfig:Clone()
configModule.Name, configModule.Parent = "RoughRepairConfig", recovery
local config = require(configModule)
assert(config.BlenderCandidateId == "MC_P1_BL01_R03", "Wait for current Rojo source")
local gallery = root.RoughRoute.H2_ThreeBands
local archived = gallery:Clone()
archived.Name, archived.Parent = "H2_ThreeBands_R02", recovery
local frame = CFrame.new(gallery:GetPivot().Position) * CFrame.Angles(0, -math.pi / 2, 0)
gallery:PivotTo(frame)
gallery:SetAttribute("BoundsCenter", frame:PointToWorldSpace(config.LanternBoundsOffset))
gallery:SetAttribute("BoundsSize", Vector3.new(config.LanternBoundsSize.Z, config.LanternBoundsSize.Y, config.LanternBoundsSize.X))
gallery:SetAttribute("FallY", frame.Position.Y - 18)
gallery.Start:SetAttribute("RecoveryCFrame", frame * CFrame.new(0, 4, 0))
gallery.Finish:SetAttribute("RecoveryCFrame", frame * CFrame.new(0, 16, -80))
gallery.Checkpoints.CP02:SetAttribute("RecoveryCFrame", frame * CFrame.new(-8, 4, 0))
for _, cage in gallery.SwingLanterns:GetChildren() do
	cage:SetAttribute("PivotPosition", cage:GetPivot().Position + Vector3.new(0, config.LanternLength, 0))
	cage:SetAttribute("SwingAxis", frame:VectorToWorldSpace(Vector3.zAxis))
	if cage:GetAttribute("RestCFrame") then cage:SetAttribute("RestCFrame", cage:GetPivot()) end
end
root:SetAttribute("CandidateId", config.BlenderCandidateId)
root:SetAttribute("AssemblyRevision", "R03: gallery joins forward to lifts; R02 catch return and moving lantern light retained")
return {candidate = root:GetAttribute("CandidateId"), galleryExit = tostring(gallery.ExitWait.Position), galleryRecovery = archived:GetFullName()}
