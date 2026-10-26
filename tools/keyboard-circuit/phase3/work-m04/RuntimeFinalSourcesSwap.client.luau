--!strict
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsClient() and game.PlaceId == 85558151074819 and game.GameId == 10191126818)
assert(not shared.KCP2I09Race or not shared.KCP2I09Race.active)
assert(not shared.KCP3M04Lifecycle01 or not shared.KCP3M04Lifecycle01.running)
local player = game.Players.LocalPlayer
local candidate = workspace.KeyboardCircuit_P3_M04_01
assert(candidate:GetAttribute("PrototypeRevision") == "KC_P3_M04_01")
local effectSource, previewSource = assert(shared.KCP3M04FinalEffectSource), assert(shared.KCP3M04FinalPreviewSource)
assert(effectSource:find("ContentProvider:PreloadAsync({skyProbe}", 1, true) and effectSource:find("originalFeedbackRun", 1, true))
assert(previewSource:find("refreshPending", 1, true))
local previousPreview = candidate:GetAttribute("KCPhase2PreviewEnabled")
candidate:SetAttribute("KCPhase2PreviewEnabled", false)
local deadline = os.clock() + 5
repeat task.wait(.05) until not player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects") or os.clock() > deadline
assert(not player.PlayerGui:FindFirstChild("KeyboardCircuitArchiveEffects") and not workspace:FindFirstChild("KeyboardCircuitArchiveVisuals"), "Old cosmetic resources must close first")
local holder = Instance.new("Folder")
holder.Name, holder.Parent = "KCM04ClientFinalSourceRecovery", player.PlayerScripts
local originalPreview = assert(player.PlayerScripts:FindFirstChild("KeyboardCircuitPhase2Preview"))
originalPreview.Disabled = true
local replacementPreview = originalPreview:Clone()
replacementPreview.Source = previewSource
originalPreview.Parent = holder
local originalEffect = candidate.SourceSnapshot.ArchiveEffects
local replacementEffect = originalEffect:Clone()
replacementEffect.Source = effectSource
originalEffect.Parent = holder
replacementEffect.Parent = candidate.SourceSnapshot
local originalSnapshotPreview = candidate.SourceSnapshot.KeyboardCircuitPhase2Preview
assert(originalSnapshotPreview.Disabled)
local snapshotPreview = originalSnapshotPreview:Clone()
snapshotPreview.Source = previewSource
originalSnapshotPreview.Parent = holder
snapshotPreview.Parent = candidate.SourceSnapshot
replacementPreview.Parent = player.PlayerScripts
replacementPreview.Disabled = false
candidate:SetAttribute("KCPhase2PreviewEnabled", previousPreview)
assert(candidate.SourceSnapshot.ArchiveEffects.Source == effectSource and candidate.SourceSnapshot.KeyboardCircuitPhase2Preview.Source == previewSource and player.PlayerScripts.KeyboardCircuitPhase2Preview.Source == previewSource)
shared.KCP3M04RuntimeFinalSourcesSwap01 = {candidate = candidate.Name, revision = "KC_P3_M04_01", passed = true,
 clientOnly = true, previousSourcesPreserved = 3, filesystemSourcesExact = true, effectSourceBytes = #effectSource, previewSourceBytes = #previewSource,
 boundary = "Ephemeral client copies test the exact durable guarded effects and preview without restarting owner Play. Originals are retained disabled in a client recovery folder. Saved Edit and server copies remain unchanged until the same files are mirrored in Edit before recovery and final source agreement."}
return game.HttpService:JSONEncode(shared.KCP3M04RuntimeFinalSourcesSwap01)
