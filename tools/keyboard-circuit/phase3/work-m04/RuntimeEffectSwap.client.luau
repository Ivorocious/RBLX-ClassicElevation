--!strict
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient() and game.PlaceId == 85558151074819 and game.GameId == 10191126818)
assert(not shared.KCP2I09Race or not shared.KCP2I09Race.active)
assert(not shared.KCP3M04Lifecycle01 or not shared.KCP3M04Lifecycle01.running)
local player = game.Players.LocalPlayer
local candidate = workspace.KeyboardCircuit_P3_M04_01
assert(candidate:GetAttribute("PrototypeRevision") == "KC_P3_M04_01")
local source = assert(shared.KCP3M04EffectSource01)
assert(type(source) == "string" and source:find("ContentProvider:PreloadAsync({skyProbe}", 1, true))
local snapshot = candidate.SourceSnapshot
local original = snapshot.ArchiveEffects
local previousPreview = candidate:GetAttribute("KCPhase2PreviewEnabled")
candidate:SetAttribute("KCPhase2PreviewEnabled", false)
local deadline = os.clock() + 5
repeat task.wait(.05) until not player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects") or os.clock() > deadline
assert(not player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects") and not workspace:FindFirstChild("KeyboardCircuitArchiveVisuals"), "Old cosmetic resources must close first")
local holder = Instance.new("Folder")
holder.Name, holder.Parent = "KCM04ClientPreloaderRecovery", player.PlayerGui
local replacement = original:Clone()
replacement.Source = source
original.Parent = holder
replacement.Parent = snapshot
assert(replacement.Source == source and original.Parent == holder and snapshot.ArchiveEffects == replacement)
candidate:SetAttribute("KCPhase2PreviewEnabled", previousPreview)
shared.KCP3M04RuntimeEffectSwap01 = {candidate = candidate.Name, revision = "KC_P3_M04_01", passed = true,
	clientOnly = true, previousSourcePreserved = true, filesystemSourceExact = true, sourceBytes = #source,
	boundary = "Ephemeral client ModuleScript copy tests the durable corrected source without restarting owner Play. Original module remains in a client-only recovery folder. Server and Edit copies are unchanged until root mirrors the same file in Edit before final source agreement and recovery."}
return game.HttpService:JSONEncode(shared.KCP3M04RuntimeEffectSwap01)
