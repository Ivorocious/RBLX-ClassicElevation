--!nonstrict
-- Scoped recovery only; this does not save or publish the place.
local TOLERANCE = .0005
local CHUNK_CHARS = 45000
local SOURCE_NORMALIZATION = "CRLF and lone CR converted to LF"
local SOURCE_BASE = {"ServerStorage", "CourseBuilders", "EggRush"}
local CURRENT_SOURCES = {
 {suffix = {"Runtime"}},
 {suffix = {"RestartP2", "Builder"}},
 {suffix = {"RestartP2", "LayoutR02"}},
 {suffix = {"RestartP2", "RevisionR02"}},
 {suffix = {"RestartP2", "HazardKit"}},
 {suffix = {"RestartP2", "Presentation"}},
}
local PRIOR_SOURCES = {
 {name = "Builder_C05_BeforeRevision", canonical = "ServerStorage.CourseBuilders.EggRush.RestartP2.Builder"},
 {name = "Runtime_C05_BeforeRevision", canonical = "ServerStorage.CourseBuilders.EggRush.Runtime"},
}

local function resolve(path)
 local object = game
 for _, name in path do
  object = assert(object:FindFirstChild(name), "Missing recovery input: " .. table.concat(path, "."))
 end
 return object
end

local function normalize(source)
 return (source:gsub("\r\n", "\n"):gsub("\r", "\n"))
end

local function difference(a, b)
 if typeof(a) ~= typeof(b) then return math.huge end
 local kind = typeof(a)
 if kind == "number" then return math.abs(a - b) end
 if kind == "Vector3" then return math.max(math.abs(a.X-b.X), math.abs(a.Y-b.Y), math.abs(a.Z-b.Z)) end
 if kind == "Vector2" then return math.max(math.abs(a.X-b.X), math.abs(a.Y-b.Y)) end
 if kind == "Color3" then return math.max(math.abs(a.R-b.R), math.abs(a.G-b.G), math.abs(a.B-b.B)) end
 if kind == "CFrame" then
  local ac, bc, largest = {a:GetComponents()}, {b:GetComponents()}, 0
  for i = 1, 12 do largest = math.max(largest, math.abs(ac[i]-bc[i])) end
  return largest
 end
 return if a == b then 0 else math.huge
end

local function sortedChildren(parent)
 local entries = {}
 for index, object in parent:GetChildren() do
  local position = {}
  if object:IsA("BasePart") or object:IsA("Model") then
   position = {object:GetPivot():GetComponents()}
  end
  if object:IsA("BasePart") then
   for _, value in {object.Size.X, object.Size.Y, object.Size.Z, object.Color.R, object.Color.G, object.Color.B, object.Transparency} do
    table.insert(position, value)
   end
  end
  local text = if object:IsA("LuaSourceContainer") then normalize(object.Source) else ""
  table.insert(entries, {object = object, index = index, position = position, text = text})
 end
 table.sort(entries, function(a, b)
  if a.object.Name ~= b.object.Name then return a.object.Name < b.object.Name end
  if a.object.ClassName ~= b.object.ClassName then return a.object.ClassName < b.object.ClassName end
  for i = 1, math.max(#a.position, #b.position) do
   local av, bv = a.position[i] or 0, b.position[i] or 0
   if av ~= bv then return av < bv end
  end
  if a.text ~= b.text then return a.text < b.text end
  return a.index < b.index
 end)
 return entries
end

local function snapshot(roots)
 local state = {records = {}, paths = {}, roots = {}}
 local function visit(object, path, counts)
  assert(object.Archivable, "Nonarchivable recovery input: " .. object:GetFullName())
  local record = {object = object, path = path, name = object.Name, class = object.ClassName,
   attributes = object:GetAttributes(), properties = {Archivable = object.Archivable}, references = {}}
  state.paths[object] = path
  table.insert(state.records, record)
  counts.instances += 1
  local properties = record.properties
  local function copy(names)
   for _, name in names do properties[name] = object[name] end
  end
  if object:IsA("BasePart") then
   counts.parts += 1
   copy({"CFrame", "Size", "Color", "Transparency", "CanCollide", "CanQuery", "CanTouch", "Anchored",
    "Material", "MaterialVariant", "Reflectance", "CastShadow", "CollisionGroup", "TopSurface", "BottomSurface"})
  end
  if object:IsA("Part") then copy({"Shape"}) end
  if object:IsA("MeshPart") then copy({"MeshId", "TextureID", "CollisionFidelity", "RenderFidelity", "DoubleSided"}) end
  if object:IsA("SpecialMesh") then copy({"MeshId", "TextureId", "MeshType", "Scale", "Offset", "VertexColor"}) end
  if object:IsA("Model") then
   counts.models += 1
   properties.Pivot = object:GetPivot()
   record.references.PrimaryPart = object.PrimaryPart or false
  end
  if object:IsA("ObjectValue") then
   counts.objectValues += 1
   record.references.Value = object.Value or false
  elseif object:IsA("ValueBase") then
   copy({"Value"})
  end
  if object:IsA("LuaSourceContainer") then
   counts.sources += 1
   properties.NormalizedSource = normalize(object.Source)
  end
  if object:IsA("Script") or object:IsA("LocalScript") then copy({"Disabled"}) end
  if object:IsA("TextLabel") or object:IsA("TextButton") then
   copy({"Text", "TextColor3", "TextSize", "TextScaled", "TextWrapped", "FontFace", "BackgroundTransparency"})
  end
  if object:IsA("SurfaceGui") then copy({"Face", "CanvasSize", "PixelsPerStud", "SizingMode"}) end
  if object:IsA("Sound") then copy({"SoundId", "Volume", "PlaybackSpeed", "Looped", "RollOffMinDistance", "RollOffMaxDistance"}) end
  local children = sortedChildren(object)
  record.children = #children
  for index, entry in children do
   visit(entry.object, path .. "/" .. entry.object.Name .. "[" .. index .. "]", counts)
  end
 end
 for index, root in roots do
  local counts = {name = root.Name, instances = 0, parts = 0, models = 0, sources = 0, objectValues = 0}
  table.insert(state.roots, counts)
  visit(root, tostring(index) .. ":" .. root.Name, counts)
 end
 return state
end

local function compare(before, after, requireSameObjects)
 assert(#before.roots == #after.roots and #before.records == #after.records, "Recovery instance/root counts differ")
 local result = {roots = #before.roots, instances = #before.records, parts = 0, models = 0, sources = 0,
  objectValues = 0, internalObjectValues = 0, primaryParts = 0, maximumNumericDifference = 0, tolerance = TOLERANCE}
 local function equal(a, b, path)
  local delta = difference(a, b)
  assert(delta <= TOLERANCE, "Recovery property differs: " .. path)
  result.maximumNumericDifference = math.max(result.maximumNumericDifference, delta)
 end
 local function equalFields(a, b, path)
  for name, value in a do equal(value, b[name], path .. "/" .. name) end
  for name in b do assert(a[name] ~= nil, "Recovery added property: " .. path .. "/" .. name) end
 end
 for index, a in before.records do
  local b = after.records[index]
  assert(a.path == b.path and a.class == b.class and a.name == b.name and a.children == b.children,
   "Recovery hierarchy differs: " .. a.path)
  if requireSameObjects then assert(a.object == b.object, "Live recovery input was replaced: " .. a.path) end
  equalFields(a.attributes, b.attributes, a.path .. "/Attributes")
  equalFields(a.properties, b.properties, a.path)
  for field, original in a.references do
   local restored = b.references[field]
   if original == false then
    assert(restored == false, "Recovery added reference: " .. a.path .. "/" .. field)
   else
    local target = before.paths[original]
    assert(target, "External recovery reference: " .. a.path .. "/" .. field)
    assert(restored ~= false and after.paths[restored] == target, "Recovery reference points elsewhere: " .. a.path .. "/" .. field)
    if field == "Value" then result.internalObjectValues += 1 else result.primaryParts += 1 end
   end
  end
 end
 for _, counts in before.roots do
  result.parts += counts.parts
  result.models += counts.models
  result.sources += counts.sources
  result.objectValues += counts.objectValues
 end
 return result
end

local function encode(bytes)
 local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
 local segments, a, b = {}, 1, 0
 local function consume(byte)
  a = (a + byte) % 65521
  b = (b + a) % 65521
 end
 for start = 1, #bytes, 9000 do
  local pieces = {}
  for index = start, math.min(start + 8999, #bytes), 3 do
   local x, y, z = string.byte(bytes, index, index + 2)
   consume(x)
   if y then consume(y) end
   if z then consume(z) end
   local word = x * 65536 + (y or 0) * 256 + (z or 0)
   local p = bit32.band(bit32.rshift(word, 18), 63) + 1
   local q = bit32.band(bit32.rshift(word, 12), 63) + 1
   local r = bit32.band(bit32.rshift(word, 6), 63) + 1
   local s = bit32.band(word, 63) + 1
   table.insert(pieces, alphabet:sub(p,p) .. alphabet:sub(q,q)
    .. (if y then alphabet:sub(r,r) else "=") .. (if z then alphabet:sub(s,s) else "="))
  end
  table.insert(segments, table.concat(pieces))
  task.wait()
 end
 return table.concat(segments), string.format("%08x", b * 65536 + a)
end

local runService = game:GetService("RunService")
assert(runService:IsStudio() and not runService:IsRunning() and game.PlaceId == 85558151074819 and game.CreatorId == 86069177,
 "Intended Egg Rush experience in Edit mode required")
local http = game:GetService("HttpService")
local httpBefore = http.HttpEnabled
local archive = resolve({"ServerStorage", "EggRushRevision_20261026"})
assert(not archive:FindFirstChild("RecoveryPayload"), "RecoveryPayload already exists; preserve and inspect it")
local course = resolve({"Workspace", "Course_EggRush"})
local prior = resolve({"ServerStorage", "EggRushRevision_20261026", "C05_OriginalBeforeR02"})
local candidate = course:GetAttribute("CandidateId")
assert(course:IsA("Model") and typeof(candidate) == "string" and candidate:sub(1, 10) == "ER_P2_R02_"
 and course:GetAttribute("Phase") == 2 and course:GetAttribute("RouteRevision") == "R02"
 and course:GetAttribute("CourseId") == "egg_rush_circuit" and course:GetAttribute("EROwned") == true,
 "Expected the current R02 authoring course")
assert(prior:IsA("Model") and prior:GetAttribute("CandidateId") == "ER_P2_R01_C05", "Expected preserved historical C05 course")

local sourceRoot = Instance.new("Folder")
sourceRoot.Name = "EggRush_R02_SourceRestore"
sourceRoot:SetAttribute("CandidateId", candidate)
sourceRoot:SetAttribute("CurrentSourcesExpected", 6)
sourceRoot:SetAttribute("HistoricalSourcesExpected", 2)
sourceRoot:SetAttribute("SourceNormalization", SOURCE_NORMALIZATION)
sourceRoot:SetAttribute("RestoreMode", "Merge only individual modules into RestorePath; historical modules restore to archive only")
local restart = Instance.new("Folder")
restart.Name, restart.Parent = "RestartP2", sourceRoot
local historical = Instance.new("Folder")
historical.Name, historical.Parent = "PriorSources", sourceRoot
historical:SetAttribute("HistoricalOnly", true)
local sourceInputs, sourceManifest = {}, {}
local function sourceCopy(source, parent, restorePath, historicalCanonical)
 assert(source:IsA("ModuleScript") and source.Archivable and #source:GetChildren() == 0,
  "Expected a childless allowlisted ModuleScript: " .. restorePath)
 local original = normalize(source.Source)
 local clone = assert(source:Clone(), "Source clone failed: " .. restorePath)
 clone:SetAttribute("RestorePath", restorePath)
 if historicalCanonical then
  clone:SetAttribute("HistoricalOnly", true)
  clone:SetAttribute("HistoricalCanonicalPath", historicalCanonical)
 end
 clone.Parent = parent
 assert(normalize(clone.Source) == original, "Source clone differs: " .. restorePath)
 table.insert(sourceInputs, source)
 table.insert(sourceManifest, {restorePath = restorePath, normalizedBytes = #original,
  historical = historicalCanonical ~= nil, historicalCanonicalPath = historicalCanonical})
end
for _, entry in CURRENT_SOURCES do
 local path = table.clone(SOURCE_BASE)
 for _, name in entry.suffix do table.insert(path, name) end
 sourceCopy(resolve(path), if #entry.suffix == 1 then sourceRoot else restart, table.concat(path, "."))
end
for _, entry in PRIOR_SOURCES do
 local path = {"ServerStorage", "EggRushRevision_20261026", entry.name}
 sourceCopy(resolve(path), historical, table.concat(path, "."), entry.canonical)
end
assert(#sourceInputs == 8, "Expected exactly six current and two historical source modules")
local sourcesBefore = snapshot(sourceInputs)

local roots = {course, prior, sourceRoot}
local before = snapshot(roots)
assert(before.roots[1].sources == 0 and before.roots[2].sources == 0 and before.roots[3].sources == 8,
 "Expected sources only in the allowlisted source restore root")
local serializer = game:GetService("SerializationService")
local serialized = serializer:SerializeInstancesAsync(roots)
assert(typeof(serialized) == "buffer", "Native serialization must return a buffer")
local bytes = buffer.tostring(serialized)
assert(#bytes >= 32 and bytes:sub(1,8) == "<roblox!", "Expected native binary Roblox model bytes")
local restored = serializer:DeserializeInstancesAsync(serialized)
assert(#restored == 3, "Expected exactly three detached restored roots")
for _, root in restored do assert(root.Parent == nil and not root:IsDescendantOf(game), "Readback root must stay detached") end
local parity = compare(before, snapshot(restored), false)
assert(parity.sources == 8, "Native readback source count differs")
compare(before, snapshot(roots), true)
compare(sourcesBefore, snapshot(sourceInputs), true)
assert(http.HttpEnabled == httpBefore, "HTTP setting changed during recovery")
parity.originalInputsUnchanged = true
parity.currentSources, parity.historicalSources = 6, 2
parity.sourceNormalization = SOURCE_NORMALIZATION

local base64, checksum = encode(bytes)
assert(#base64 == math.ceil(#bytes / 3) * 4, "Base64 length differs")
compare(before, snapshot(roots), true)
compare(sourcesBefore, snapshot(sourceInputs), true)
assert(http.HttpEnabled == httpBefore, "HTTP setting changed during encoding")
local manifest = {candidate = candidate, bytes = #bytes, base64Chars = #base64,
 chunks = math.ceil(#base64 / CHUNK_CHARS), rootcounts = before.roots, parity = parity,
 checksum = {algorithm = "Adler32", hex = checksum}, sourceManifest = sourceManifest,
 snapshotRootNames = {course.Name, prior.Name, sourceRoot.Name}, sourceNormalization = SOURCE_NORMALIZATION,
 restorePaths = {"Workspace.Course_EggRush", "ServerStorage.EggRushRevision_20261026.C05_OriginalBeforeR02", "Individual ModuleScript RestorePath attributes"},
 scope = "Scoped model/source recovery; not a whole-place save, publication or owner acceptance"}
local manifestJson = http:JSONEncode(manifest)

for _, root in restored do
 assert(root.Parent == nil and not root:IsDescendantOf(game), "Refuse cleanup of a parented readback root")
 root:Destroy()
end
assert(sourceRoot.Parent == nil and not sourceRoot:IsDescendantOf(game), "Refuse cleanup of a parented source restore root")
sourceRoot:Destroy()

local payload = Instance.new("Folder")
payload.Name = "RecoveryPayload"
payload:SetAttribute("CandidateId", candidate)
payload:SetAttribute("Bytes", #bytes)
payload:SetAttribute("Base64Chars", #base64)
payload:SetAttribute("Chunks", manifest.chunks)
payload:SetAttribute("ChecksumAlgorithm", "Adler32")
payload:SetAttribute("Checksum", checksum)
payload:SetAttribute("Scope", manifest.scope)
local metadata = Instance.new("StringValue")
metadata.Name, metadata.Value, metadata.Parent = "Manifest", manifestJson, payload
for index = 1, manifest.chunks do
 local chunk = Instance.new("StringValue")
 chunk.Name = string.format("Chunk_%04d", index)
 chunk.Value = base64:sub((index-1) * CHUNK_CHARS + 1, index * CHUNK_CHARS)
 assert(#chunk.Value <= CHUNK_CHARS, "Payload chunk exceeds transport limit")
 chunk.Parent = payload
end
assert(not archive:FindFirstChild("RecoveryPayload"), "RecoveryPayload appeared; preserve it")
payload.Parent = archive
return manifestJson
