assert(game.PlaceId == 85558151074819 and not game:GetService("RunService"):IsRunning())
local expected = shared.KCExpectedC06
local storage = game:GetService("ServerStorage")
local candidate = workspace.KeyboardCircuit_P1_C06
local kit = storage.CourseAssetKits.KeyboardCircuit_EditableKit_K01
local originals = storage.CourseBuilders.KeyboardCircuit
local matched, names = {}, {}
for _,source in originals:GetChildren() do
 assert(not names[source.Name], "Duplicate source")
 names[source.Name] = true
 assert(source.Source == expected[source.Name], "Rojo source mismatch")
 matched[source.Name] = #source.Source
end
assert(#originals:GetChildren() == 10)
assert(game.ReplicatedStorage.Config.KeyboardCircuitConfig.Source == expected.ConfigSnapshot)
assert(game.StarterPlayer.StarterPlayerScripts.Controllers.KeyboardCircuitFeedback.Source == expected.KeyboardCircuitFeedback)
assert(game.StarterPlayer.StarterPlayerScripts.KeyboardCircuitPreview.Source == expected.KeyboardCircuitPreview)
local function numeric(n)
 return string.format("%.4f", if math.abs(n) < .00005 then 0 else n)
end
local function vector(v)
 if typeof(v) == "Color3" then return numeric(v.R) .. "," .. numeric(v.G) .. "," .. numeric(v.B) end
 return numeric(v.X) .. "," .. numeric(v.Y) .. "," .. numeric(v.Z)
end
local function relative(object, root)
 return object:GetFullName():sub(#root:GetFullName() + 2)
end
local function parts(root, omitSigns, collidersOnly)
 local rows = {}
 for _,object in root:GetDescendants() do
  if object:IsA("BasePart") and (not omitSigns or (object.Name ~= "ExpertMarker" and object.Name ~= "NormalRouteSign")) and (not collidersOnly or object.CanCollide) then
   local frame = {object.CFrame:GetComponents()}
   for i,n in frame do frame[i] = numeric(n) end
   local fields = {relative(object,root), object.ClassName, vector(object.Size), table.concat(frame,","), vector(object.Color), tostring(object.Material), tostring(object.CanCollide), tostring(object.CanQuery), tostring(object.CanTouch), numeric(object.Transparency)}
   if object:IsA("MeshPart") then table.insert(fields,object.MeshId) end
   table.insert(rows,table.concat(fields,"|"))
  end
 end
 table.sort(rows)
 return table.concat(rows,"\n")
end
local function sources(root)
 local rows = {}
 for _,object in root:GetDescendants() do
  if object:IsA("LuaSourceContainer") then table.insert(rows,relative(object,root) .. "|" .. object.ClassName .. "|" .. tostring(object:IsA("BaseScript") and object.Disabled) .. "|" .. object.Source) end
 end
 table.sort(rows)
 return table.concat(rows,"\n")
end
local function counts(root)
 local result = {descendants=#root:GetDescendants(), parts=0, meshes=0, colliders=0, prismatics=0, welds=0, scripts=0, lights=0}
 for _,object in root:GetDescendants() do
  if object:IsA("BasePart") then result.parts += 1; if object.CanCollide then result.colliders += 1 end end
  if object:IsA("MeshPart") then result.meshes += 1 end
  if object:IsA("LuaSourceContainer") then result.scripts += 1 end
  if object:IsA("Light") then result.lights += 1 end
  if object:IsA("PrismaticConstraint") then
   result.prismatics += 1
   assert(object.Attachment0:IsDescendantOf(root) and object.Attachment1:IsDescendantOf(root))
  end
  if object:IsA("WeldConstraint") then
   result.welds += 1
   assert(object.Part0:IsDescendantOf(root) and object.Part1:IsDescendantOf(root))
  end
 end
 return result
end
local archives = storage.DeveloperArchives.KeyboardCircuitP1_Archives
assert(parts(candidate,true,false) == parts(archives.KeyboardCircuit_P1_C05,true,false), "Non-sign geometry changed")
assert(parts(candidate,false,true) == parts(archives.KeyboardCircuit_P1_C05,false,true), "Collider geometry changed")
assert(parts(kit,false,false) == parts(archives.KeyboardCircuit_EditableKit_K01_C05_sources,false,false), "Kit geometry changed")
local snapshots = {}
for name,root in {candidate=candidate, kit=kit} do
 local seen, total = {}, 0
 for _,source in root.SourceSnapshot:GetChildren() do
  assert(not seen[source.Name])
  seen[source.Name], total = true, total + 1
  assert(source.Source == expected[source.Name], "Snapshot source mismatch")
 end
 assert(total == 11)
 snapshots[name] = {unique=total, sessionDisabled=root.SourceSnapshot.Session.Disabled}
end
local report = {revision="KC_P1_C06", sourceMatches=matched, sourceCount=13, activeUniqueSources=10, snapshots=snapshots, nonSignGeometryMatchesC05=true, colliderGeometryMatchesC05=true, kitGeometryMatchesC05=true, geometryPrecisionStuds=.0001, signs={normal="NORMAL / LIFT + ENTER", expert="EXPERT X01 / HARD JUMPS"}, engine={}, sourcesCompiled=13}
local serialization = game:GetService("SerializationService")
for name,root in {C06=candidate, KitC06=kit} do
 local bufferValue = serialization:SerializeInstancesAsync({root})
 shared.KCNativeExports[name] = buffer.tostring(bufferValue)
 local reopened = serialization:DeserializeInstancesAsync(bufferValue)[1]
 assert(parts(root,false,false) == parts(reopened,false,false))
 assert(sources(root) == sources(reopened), "Stored source or enabled state differs")
 local before, after = counts(root), counts(reopened)
 for field,n in before do assert(after[field] == n) end
 report.engine[name] = {bytes=buffer.len(bufferValue), geometryPassed=true, everyStoredSourceAndEnabledStatePassed=true, internalReferencesPassed=true, counts=before}
end
for name,source in expected do
 local compiled,err = loadstring(source)
 assert(compiled, name .. ":" .. tostring(err))
end
shared.KCVerificationC06 = report
return report
