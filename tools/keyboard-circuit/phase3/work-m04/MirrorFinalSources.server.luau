--!strict
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Mirror final sources only in saved Edit")
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local c = workspace.KeyboardCircuit_P3_M04_01
assert(c:GetAttribute("PrototypeRevision") == "KC_P3_M04_01" and c:GetAttribute("Origin") == Vector3.new(2222, 330, -1158))
local proofRoot = game.ServerStorage.KeyboardCircuitPhase2Archive.Phase3FinalTuning20261009
local holder = proofRoot.M04Sources01
local fx, preview = assert(shared.KCP3M04FinalEffectSource), assert(shared.KCP3M04FinalPreviewSource)
local encoding = game:GetService("EncodingService")
local function hash(value)
 local raw = buffer.tostring(encoding:ComputeBufferHash(buffer.fromstring(value), Enum.HashAlgorithm.Sha256))
 return (raw:gsub(".", function(char) return string.format("%02x", string.byte(char)) end))
end
local fxHash = "c17ac2c67a6e4681955897917d3524adb65563f44ffcbb5878069792f8ead41d"
local previewHash = "902c1aa47063fda8a093baf219c3f44307e5a6cec89519f2419579908d8c4a20"
assert(hash(fx) == fxHash and hash(preview) == previewHash, "Expected exact guarded repository source bytes")
assert(not proofRoot:FindFirstChild("M04FinalSourcesBefore02"), "Inspect preserved mirror before retry")
local rows = {
 {object = c.SourceSnapshot.ArchiveEffects, source = fx, before = "0c6f6aa9adbf43681b49b254fa2ac1833f4346c81d3b6b82315f8c80c3c69aad", after = fxHash, backup = "SnapshotArchiveEffects"},
 {object = holder.ArchiveEffects, source = fx, before = "0c6f6aa9adbf43681b49b254fa2ac1833f4346c81d3b6b82315f8c80c3c69aad", after = fxHash, backup = "HolderArchiveEffects"},
 {object = c.SourceSnapshot.KeyboardCircuitPhase2Preview, source = preview, before = "f226df8ef4f7be3bc470840f02512c9eb019bda980149507f652899f11325476", after = previewHash, backup = "SnapshotPreview"},
 {object = holder.KeyboardCircuitPhase2Preview, source = preview, before = "f226df8ef4f7be3bc470840f02512c9eb019bda980149507f652899f11325476", after = previewHash, backup = "HolderPreview"},
 {object = game.StarterPlayer.StarterPlayerScripts.KeyboardCircuitPhase2Preview, source = preview, before = "f226df8ef4f7be3bc470840f02512c9eb019bda980149507f652899f11325476", after = previewHash, backup = "GlobalPreview"},
}
for _, row in rows do
 row.actualBefore = hash(row.object.Source)
 assert(row.actualBefore == row.before or row.actualBefore == row.after or row.object.Source:gsub("\r\n", "\n") == row.source:gsub("\r\n", "\n"), "Intervening source edit: " .. row.object:GetFullName())
end
local backup = Instance.new("Folder")
backup.Name, backup.Parent = "M04FinalSourcesBefore02", proofRoot
backup:SetAttribute("KCOwnedPhase3Preparation", true)
local results = {}
for _, row in rows do
 local copy = row.object:Clone()
 copy.Name = row.backup
 if copy:IsA("BaseScript") then copy.Disabled = true end
 copy.Parent = backup
 row.object.Source = row.source
 assert(row.object.Source == row.source and hash(row.object.Source) == row.after)
 table.insert(results, {path = row.object:GetFullName(), beforeSha256 = row.actualBefore, sha256 = row.after, bytes = #row.source, oldSourcePreserved = true})
end
shared.KCP3M04FinalSourceMirror02 = {candidate = c.Name, revision = "KC_P3_M04_01", passed = true, rows = results, preservedCopies = 5,
 datamodel = "Edit", backup = backup:GetFullName(),
 boundary = "Exact two durable guarded source files mirrored to active snapshot, durable preparation and global Preview in saved Edit. Every prior source was verified then retained disabled; no course geometry, authority, camera/computer control, stored data or publication changed."}
return game.HttpService:JSONEncode(shared.KCP3M04FinalSourceMirror02)
