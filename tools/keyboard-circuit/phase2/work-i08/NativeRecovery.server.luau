--!strict
local RunService, Storage, Http = game:GetService("RunService"), game:GetService("ServerStorage"), game:GetService("HttpService")
assert(RunService:IsStudio() and not RunService:IsRunning())
assert(game.PlaceId == 85558151074819 and game.GameId == 10191126818)
local candidate = workspace.KeyboardCircuit_P2_I08_TwoLaps01
assert(candidate:GetAttribute("PrototypeRevision") == "KC_P2_I08_01")
assert(not Storage:FindFirstChild("KCP2I08TwoLapNativeRecovery01"), "Inspect the existing recovery receipt before retry")
local serialization, encoding = game:GetService("SerializationService"), game:GetService("EncodingService")
local blob = serialization:SerializeInstancesAsync({candidate})
local proof = Instance.new("Folder")
proof.Name, proof.Parent = "KCP2I08TwoLapNativeRecovery01", Storage
proof:SetAttribute("KCOwnedPhase2Preparation", true)
local objects = serialization:DeserializeInstancesAsync(blob)
assert(#objects == 1 and objects[1]:IsA("Model"))
local reopened = objects[1]
for _, item in reopened:GetDescendants() do if item:IsA("BaseScript") then item.Disabled = true end end
reopened.Parent = proof
local fresh = candidate.SourceSnapshot:Clone()
fresh.Name = "FreshBuilderSources"
for _, item in fresh:GetChildren() do if item:IsA("BaseScript") then item.Disabled = true end end
fresh.Parent = proof
local rebuildParent = Instance.new("Folder")
rebuildParent.Name, rebuildParent.Parent = "RebuiltCourse", proof
local template = Storage.AssetImports.KCKeyImport_K02:FindFirstChild("KC_OrdinaryKey", true)
local rebuilt = require(fresh.Course).Build(rebuildParent, candidate:GetAttribute("Origin"), template)
local copied = fresh:Clone()
copied.Name, copied.Parent = "SourceSnapshot", rebuilt
rebuilt.Parent = rebuildParent
local function relative(model, item) return item:GetFullName():sub(#model:GetFullName() + 2) end
local function numbers(...)
 local values = {...}
 for i, v in values do values[i] = string.format("%.3f", if math.abs(v) < .0005 then 0 else v) end
 return table.concat(values, ",")
end
local function geometry(model)
 local rows = {}
 for _, item in model:GetDescendants() do
  local row = item.ClassName .. "|" .. relative(model, item)
  if item:IsA("BasePart") then
   row ..= "|" .. numbers(item.CFrame:GetComponents()) .. "|" .. numbers(item.Size.X, item.Size.Y, item.Size.Z)
   row ..= "|" .. numbers(item.Color.R, item.Color.G, item.Color.B) .. "|" .. item.Material.Name
   row ..= "|" .. tostring(item.CanCollide) .. "|" .. tostring(item.CanTouch) .. "|" .. tostring(item.CanQuery) .. "|" .. tostring(item.CastShadow) .. "|" .. item.CollisionGroup
   if item:IsA("MeshPart") then row ..= "|" .. item.MeshId .. "|" .. item.TextureID .. "|" .. item.CollisionFidelity.Name end
  elseif item:IsA("TextLabel") then row ..= "|" .. item.Text .. "|" .. item.Font.Name .. "|" .. tostring(item.Visible)
  elseif item:IsA("SurfaceGui") then row ..= "|" .. tostring(item.Enabled)
  elseif item:IsA("ObjectValue") then row ..= "|" .. (if item.Value and item.Value:IsDescendantOf(model) then relative(model, item.Value) else tostring(item.Value))
  elseif item:IsA("Vector3Value") then row ..= "|" .. numbers(item.Value.X, item.Value.Y, item.Value.Z)
  end
  table.insert(rows, row)
 end
 table.sort(rows)
 return rows
end
local function compare(left, right)
 local a, b, differences, sourceFailures, external = geometry(left), geometry(right), {}, {}, {}
 for i = 1, math.max(#a, #b) do if a[i] ~= b[i] and #differences < 12 then table.insert(differences, {index=i,left=a[i],right=b[i]}) end end
 for _, item in left.SourceSnapshot:GetChildren() do if item.Source ~= right.SourceSnapshot[item.Name].Source then table.insert(sourceFailures, item.Name) end end
 for _, item in right:GetDescendants() do
  if item:IsA("BaseScript") then assert(item.Disabled, "Recovery scripts must stay inert") end
  if item:IsA("ObjectValue") and item.Value and not item.Value:IsDescendantOf(right) then table.insert(external, relative(right, item)) end
  if item:IsA("Constraint") then for _, name in {"Attachment0", "Attachment1"} do local attachment=item[name]; if attachment and not attachment:IsDescendantOf(right) then table.insert(external, relative(right,item).."."..name) end end end
 end
 return {passed=#a==#b and #differences==0 and #sourceFailures==0 and #external==0,leftCount=#a,rightCount=#b,differences=differences,sourceFailures=sourceFailures,externalReferences=external}
end
local preserved = {}
for _, course in Storage.KeyboardCircuitPhase2Archive.TwoLapCleanup20261008.OlderCourses:GetChildren() do
 assert(not course:IsDescendantOf(workspace))
 for _, item in course:GetDescendants() do if item:IsA("BaseScript") then assert(item.Disabled) end end
 table.insert(preserved, course.Name)
end
assert(#preserved == 9)
local function hex(value) return (value:gsub(".", function(char) return string.format("%02x", string.byte(char)) end)) end
local receipt = {candidate=candidate.Name,revision=candidate:GetAttribute("PrototypeRevision"),courseBytes=buffer.len(blob),proof=proof:GetFullName(),
 roundTrip=compare(candidate,reopened),freshSourceRebuild=compare(candidate,rebuilt),preserved=preserved,
 nativeSha256=hex(buffer.tostring(encoding:ComputeBufferHash(blob,Enum.HashAlgorithm.Sha256))),
 boundary="Native engine serialization/reopening and fresh-identity source rebuild. Inert recovery in ServerStorage, scripts disabled. Geometry at .001 stud precision, internal references, source bytes and visible legends compared. No whole-place save or publication."}
shared.KCP2I08TwoLapNativeExport01=buffer.tostring(encoding:Base64Encode(encoding:CompressBuffer(blob,Enum.CompressionAlgorithm.Zstd,3)))
receipt.compressedBase64Chars=#shared.KCP2I08TwoLapNativeExport01
shared.KCP2I08TwoLapRecoveryReceipt01=receipt
assert(receipt.roundTrip.passed and receipt.freshSourceRebuild.passed,Http:JSONEncode(receipt))
return Http:JSONEncode(receipt)
