--!nonstrict
-- Scoped native recovery; this neither saves nor publishes the whole place.
local Backup = {}
local DEFAULT_CANDIDATE = "ER_P3_W06_C02"
local TOLERANCE = .0005
local CHUNK_CHARS = 45000
local SOURCE_NORMALIZATION = "CRLF and lone CR converted to LF"
local GEOMETRY = {
 {path={"Workspace","Course_EggRush"}, kind="currentCourse"},
 {path={"Workspace","ER_P1_R01_AssetGallery"}, kind="acceptedGallery", models=26},
 {path={"ServerStorage","CourseAssetKits","EggRush_P1_R01_K01"}, kind="acceptedPhase1Kit", models=26},
 {path={"ServerStorage","CourseAssetKits","EggRush_P2_R01_K01"}, kind="phase2Kit", models=27},
 {path={"ServerStorage","EggRushPhase3Meshes"}, kind="phase3MeshLibrary"},
}
local BUILDER_MODULES = {
 {"Phase3","World"}, {"Phase3","WorldPlan"}, {"Phase3","WorldKit"}, {"Phase3","PerchFoundations"},
 {"Phase3","RestStops"},
 {"RestartP2","Builder"}, {"RestartP2","Presentation"}, {"RestartP2","RevisionR02"},
 {"RestartP2","LayoutR02"}, {"RestartP2","HazardKit"}, {"RestartP2","RevisionR03"},
 {"RestartP2","ReadableKit"}, {"RestartP2","ChickenKit"}, {"RestartP2","ChickenR04"},
 {"RestartR01","Builder"}, {"RestartR01","Study"}, {"RestartR01","Sample"},
 {"Runtime"}, {"GuardianPeck"}, {"ChickenMotion"}, {"ChickenPeck"}, {"NativeTraversal"}, {"ImportKit"},
}
local OTHER_SOURCES = {
 {"ServerScriptService","Services","EggRushService"},
 {"ServerScriptService","Services","StagingService"},
 {"StarterPlayer","StarterPlayerScripts","EggRushAmbience"},
 {"ReplicatedStorage","Config","EggRushAmbienceConfig"},
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
   attributes = object:GetAttributes(), properties = {Archivable = object.Archivable}, references = {}, parent = object.Parent}
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
  if object:IsA("GuiObject")then
   copy({"Position","Size","AnchorPoint","Rotation","ZIndex","Visible","BackgroundColor3","BackgroundTransparency","BorderSizePixel"})
  end
  if object:IsA("SurfaceGui") then
   copy({"Face", "CanvasSize", "PixelsPerStud", "SizingMode","Enabled","ZOffset","LightInfluence"})
   record.references.Adornee=object.Adornee or false
  end
  if object:IsA("Sound") then copy({"SoundId", "Volume", "PlaybackSpeed", "Looped", "RollOffMinDistance", "RollOffMaxDistance"}) end
  if object:IsA("Light") then
   counts.lights += 1
   copy({"Enabled", "Brightness", "Color", "Shadows"})
  end
  if object:IsA("PointLight") then copy({"Range"}) end
  local children = sortedChildren(object)
  record.children = #children
  for index, entry in children do
   visit(entry.object, path .. "/" .. entry.object.Name .. "[" .. index .. "]", counts)
  end
 end
 for index, root in roots do
  local counts = {name = root.Name, instances = 0, parts = 0, models = 0, sources = 0, objectValues = 0, lights = 0}
  table.insert(state.roots, counts)
  visit(root, tostring(index) .. ":" .. root.Name, counts)
 end
 return state
end

local function compare(before, after, requireSameObjects)
 assert(#before.roots == #after.roots and #before.records == #after.records, "Recovery instance/root counts differ")
 local result = {roots = #before.roots, instances = #before.records, parts = 0, models = 0, sources = 0,
  objectValues = 0, lights = 0, internalObjectValues = 0, internalAdornees = 0, primaryParts = 0, maximumNumericDifference = 0, tolerance = TOLERANCE}
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
  if requireSameObjects then
   assert(a.object == b.object, "Live recovery input was replaced: " .. a.path)
   assert(a.object.Parent == a.parent, "Live recovery input moved: " .. a.path)
  end
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
    if field == "Value" then result.internalObjectValues += 1
    elseif field=="Adornee"then result.internalAdornees+=1
    else result.primaryParts += 1 end
   end
  end
 end
 for _, counts in before.roots do
  result.parts += counts.parts
  result.models += counts.models
  result.sources += counts.sources
  result.objectValues += counts.objectValues
  result.lights += counts.lights
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

local function modelCount(root)
 local count = 0
 for _, child in root:GetChildren() do if child:IsA("Model") then count += 1 end end
 return count
end

function Backup.Run(expectedCandidate, outputName)
 expectedCandidate = expectedCandidate or DEFAULT_CANDIDATE
 local runService = game:GetService("RunService")
 assert(runService:IsStudio() and not runService:IsRunning() and game.PlaceId == 85558151074819 and game.CreatorId == 86069177,
  "Intended Egg Rush experience in Edit mode required")
 assert(typeof(expectedCandidate) == "string" and expectedCandidate:match("^ER_P3_W%d+_C%d+$"), "Explicit Phase3 world candidate required")
 if outputName == nil then outputName = "WorldRecoveryPayload_" .. expectedCandidate end
 assert(typeof(outputName) == "string" and outputName:match("^[%w_]+$"), "Recovery folder name must contain only letters, numbers and underscores")
 local http = game:GetService("HttpService")
 local httpBefore = http.HttpEnabled
 local archive = resolve({"ServerStorage","EggRushPhase3_20261026"})
 assert(archive:IsA("Folder"), "Expected owned Phase3 staging folder")
 assert(not archive:FindFirstChild(outputName), "Preserve the existing " .. outputName .. "; choose a fresh recovery folder name")
 local course = resolve(GEOMETRY[1].path)
 assert(course:IsA("Model") and course:GetAttribute("CandidateId") == expectedCandidate
  and course:GetAttribute("Phase") == 3 and course:GetAttribute("RouteRevision") == "R03"
  and course:GetAttribute("CourseId") == "egg_rush_circuit" and course:GetAttribute("EROwned") == true,
  "Expected current explicit Phase3 authoring course")
 assert(course:FindFirstChild("Decoration") and course.Decoration:FindFirstChild("HatcheryWorld"), "Installed hatchery world required")
 local roots, rootManifest = {}, {}
 for _, entry in GEOMETRY do
  local object = resolve(entry.path)
  assert(object:IsA("Model") or object:IsA("Folder"), "Expected geometry root: " .. table.concat(entry.path,"."))
  if entry.models then assert(modelCount(object) == entry.models, "Unexpected kit/gallery model count: " .. object.Name) end
  table.insert(roots, object)
  table.insert(rootManifest, {kind=entry.kind, restorePath=table.concat(entry.path,"."), name=object.Name})
 end
 local sourceInputs, sourceManifest, restored = {}, {}, nil
 local sourceRoot = Instance.new("Folder")
 sourceRoot.Name = "EggRush_Phase3_SourceRestore"
 sourceRoot:SetAttribute("CandidateId", expectedCandidate)
 sourceRoot:SetAttribute("SourceNormalization", SOURCE_NORMALIZATION)
 sourceRoot:SetAttribute("RestoreMode", "Merge individual LuaSourceContainers into their exact RestorePath; never replace service or source folders")
 local function cleanupDetached(root)
  assert(root.Parent == nil and not root:IsDescendantOf(game), "Refuse cleanup of a parented recovery root")
  root:Destroy()
 end
 local ok, output = xpcall(function()
  local function sourceCopy(path)
   local source = resolve(path)
   assert(source:IsA("LuaSourceContainer") and source.Archivable and #source:GetChildren() == 0,
    "Expected exact childless source: " .. table.concat(path,"."))
   local parent = sourceRoot
   for index = 1, #path - 1 do
    local folder = parent:FindFirstChild(path[index])
    if not folder then folder=Instance.new("Folder");folder.Name=path[index];folder.Parent=parent end
    parent=folder
   end
   assert(not parent:FindFirstChild(source.Name), "Duplicate allowlisted restore source")
   local original = normalize(source.Source)
   local clone = assert(source:Clone())
   clone:SetAttribute("RestorePath",table.concat(path,"."))
   clone.Parent=parent
   assert(normalize(clone.Source)==original,"Source clone differs: "..table.concat(path,"."))
   table.insert(sourceInputs,source)
   table.insert(sourceManifest,{restorePath=table.concat(path,"."),class=source.ClassName,normalizedBytes=#original})
  end
  for _, suffix in BUILDER_MODULES do
   local path={"ServerStorage","CourseBuilders","EggRush"}
   for _, name in suffix do table.insert(path,name) end
   sourceCopy(path)
  end
  for _, path in OTHER_SOURCES do sourceCopy(path) end
  assert(#sourceInputs == 27, "Expected exactly 27 allowlisted current sources")
  sourceRoot:SetAttribute("SourcesExpected",#sourceInputs)
  table.insert(roots,sourceRoot)
  table.insert(rootManifest,{kind="individualSourceRestore",name=sourceRoot.Name,restorePath="Individual RestorePath attributes only"})
  local sourceBefore,before=snapshot(sourceInputs),snapshot(roots)
  for index=1,#GEOMETRY do assert(before.roots[index].sources==0,"Geometry input unexpectedly contains source: "..roots[index].Name) end
  assert(before.roots[#roots].sources==#sourceInputs,"Source restore count differs")
  local serializer=game:GetService("SerializationService")
  local serialized=serializer:SerializeInstancesAsync(roots)
  assert(typeof(serialized)=="buffer","Native serialization must return a buffer")
  local bytes=buffer.tostring(serialized)
  assert(#bytes>=32 and bytes:sub(1,8)=="<roblox!","Expected native binary Roblox model bytes")
  restored=serializer:DeserializeInstancesAsync(serialized)
  assert(#restored==#roots,"Detached readback root count differs")
  for _, root in restored do assert(root.Parent==nil and not root:IsDescendantOf(game),"Readback must stay detached") end
  local parity=compare(before,snapshot(restored),false)
  assert(parity.sources==#sourceInputs,"Native source readback count differs")
  compare(before,snapshot(roots),true)
  compare(sourceBefore,snapshot(sourceInputs),true)
  assert(http.HttpEnabled==httpBefore,"HTTP setting changed")
  local base64,checksum=encode(bytes)
  assert(#base64==math.ceil(#bytes/3)*4,"Base64 length differs")
  compare(before,snapshot(roots),true)
  compare(sourceBefore,snapshot(sourceInputs),true)
  assert(http.HttpEnabled==httpBefore,"HTTP setting changed during encoding")
  parity.originalInputsUnchanged=true
  parity.sourceNormalization=SOURCE_NORMALIZATION
  local manifest={candidate=expectedCandidate,bytes=#bytes,base64Chars=#base64,chunks=math.ceil(#base64/CHUNK_CHARS),
   rootcounts=before.roots,rootManifest=rootManifest,parity=parity,sourceManifest=sourceManifest,
   checksum={algorithm="Adler32",hex=checksum},sourceNormalization=SOURCE_NORMALIZATION,
   readbackVerified=true,exportFolder="ServerStorage.EggRushPhase3_20261026." .. outputName,
   originalInputMutations=0,geometryClones=0,detachedReadbackRoots=#restored,
   scope="Scoped Egg Rush model/source recovery only; not a whole-place save, publication or owner acceptance",
   limits="Source line endings normalized for comparison; instance/property coverage follows SerializeChickenR05 with added PointLight checks; external project systems and original asset files are not included; root must decode, verify bytes/Adler32 and save a filesystem SHA256 receipt"}
  local payload=Instance.new("Folder")
  payload.Name=outputName
  payload:SetAttribute("CandidateId",expectedCandidate)
  payload:SetAttribute("Bytes",#bytes)
  payload:SetAttribute("Base64Chars",#base64)
  payload:SetAttribute("Chunks",manifest.chunks)
  payload:SetAttribute("ChecksumAlgorithm","Adler32")
  payload:SetAttribute("Checksum",checksum)
  payload:SetAttribute("ReadbackVerified",true)
  payload:SetAttribute("Scope",manifest.scope)
  local joined={}
  for index=1,manifest.chunks do
   local chunk=Instance.new("StringValue")
   chunk.Name=string.format("Chunk_%04d",index)
   chunk.Value=base64:sub((index-1)*CHUNK_CHARS+1,index*CHUNK_CHARS)
   assert(#chunk.Value<=CHUNK_CHARS,"Payload transport chunk too large")
   chunk.Parent=payload
   table.insert(joined,chunk.Value)
  end
  assert(table.concat(joined)==base64,"Stored payload differs from verified serialization")
  manifest.storedChunkTextVerified=true
  local metadata=Instance.new("StringValue")
  metadata.Name,metadata.Value,metadata.Parent="Manifest",http:JSONEncode(manifest),payload
  assert(not archive:FindFirstChild(payload.Name),"Preserve a payload that appeared during export")
  payload.Parent=archive
  return metadata.Value
 end,debug.traceback)
 if restored then for _, root in restored do cleanupDetached(root) end end
 cleanupDetached(sourceRoot)
 assert(ok,output)
 return output
end

return Backup
