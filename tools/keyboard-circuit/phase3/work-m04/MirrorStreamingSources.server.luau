--!strict
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning() and game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local c = workspace.KeyboardCircuit_P3_M04_01
assert(c:GetAttribute("PrototypeRevision") == "KC_P3_M04_01" and c:GetAttribute("Origin") == Vector3.new(2222, 330, -1158))
local proofRoot = game.ServerStorage.KeyboardCircuitPhase2Archive.Phase3FinalTuning20261009
local holder = proofRoot.M04Sources01
local source, expected = assert(shared.KCP3M04StreamingEffectSource), assert(shared.KCP3M04StreamingEffectSHA)
local encoding = game:GetService("EncodingService")
local function hash(value)
 local raw = buffer.tostring(encoding:ComputeBufferHash(buffer.fromstring(value), Enum.HashAlgorithm.Sha256))
 return (raw:gsub(".", function(char) return string.format("%02x", string.byte(char)) end))
end
assert(hash(source) == expected)
assert(not proofRoot:FindFirstChild("M04StreamingSourcesBefore03"), "Inspect existing mirror before retry")
local rows = {{object=c.SourceSnapshot.ArchiveEffects,backup="SnapshotArchiveEffects"},{object=holder.ArchiveEffects,backup="HolderArchiveEffects"}}
for _,row in rows do row.before=hash(row.object.Source);assert(row.before=="c17ac2c67a6e4681955897917d3524adb65563f44ffcbb5878069792f8ead41d" or row.before==expected,"Intervening source edit")end
local backup=Instance.new("Folder")
backup.Name,backup.Parent="M04StreamingSourcesBefore03",proofRoot
backup:SetAttribute("KCOwnedPhase3Preparation",true)
local results={}
for _,row in rows do
 local copy=row.object:Clone();copy.Name=row.backup;copy.Parent=backup
 row.object.Source=source
 assert(row.object.Source==source)
 table.insert(results,{path=row.object:GetFullName(),beforeSha256=row.before,sha256=hash(row.object.Source),bytes=#row.object.Source,oldSourcePreserved=true})
end
shared.KCP3M04StreamingMirror03={candidate=c.Name,revision="KC_P3_M04_01",passed=true,datamodel="Edit",rows=results,backup=backup:GetFullName(),
 boundary="Only the durable cosmetic module is mirrored to its two saved copies. Prior guarded sources retained, exact expected bytes verified; no geometry, global scripts, gameplay authority, streaming settings, computer/camera control or publication changed."}
return game.HttpService:JSONEncode(shared.KCP3M04StreamingMirror03)
