--!nonstrict
-- Uses the native serialization/readback pattern in tools/stud-garden/Backup.luau.
local Backup = {}
local FILE = "er-p2-r01-c05-final.rbxm"
local URL = "http://127.0.0.1:8777/" .. FILE
local CANDIDATE = "ER_P2_R01_C05"
local GEOMETRY = {
 {path = {"Workspace", "Course_EggRush"}, kind = "course"},
 {path = {"ServerStorage", "CourseAssetKits", "EggRush_P2_R01_K01"}, kind = "phase2Kit", models = 27},
 {path = {"ServerStorage", "CourseAssetKits", "EggRush_P1_R01_K01"}, kind = "acceptedPhase1Kit", models = 26},
 {path = {"Workspace", "ER_P1_R01_AssetGallery"}, kind = "gallery", models = 26},
}
local SOURCES = {
 {"ServerStorage", "CourseBuilders", "EggRush", "Authoring"},
 {"ServerStorage", "CourseBuilders", "EggRush", "Builder"},
 {"ServerStorage", "CourseBuilders", "EggRush", "Finish"},
 {"ServerStorage", "CourseBuilders", "EggRush", "ImportKit"},
 {"ServerStorage", "CourseBuilders", "EggRush", "MechanismFinish"},
 {"ServerStorage", "CourseBuilders", "EggRush", "NativeChecks"},
 {"ServerStorage", "CourseBuilders", "EggRush", "NativeContacts"},
 {"ServerStorage", "CourseBuilders", "EggRush", "NativeFollowerChecks"},
 {"ServerStorage", "CourseBuilders", "EggRush", "NativeNoJumpChecks"},
 {"ServerStorage", "CourseBuilders", "EggRush", "NativeRaceChecks"},
 {"ServerStorage", "CourseBuilders", "EggRush", "NativeTraversal"},
 {"ServerStorage", "CourseBuilders", "EggRush", "Runtime"},
 {"ServerStorage", "CourseBuilders", "EggRush", "WorldFinish"},
 {"ServerStorage", "CourseBuilders", "EggRush", "RestartR01", "Builder"},
 {"ServerStorage", "CourseBuilders", "EggRush", "RestartR01", "Checks"},
 {"ServerStorage", "CourseBuilders", "EggRush", "RestartR01", "Sample"},
 {"ServerStorage", "CourseBuilders", "EggRush", "RestartR01", "Study"},
 {"ServerStorage", "CourseBuilders", "EggRush", "RestartP2", "Builder"},
 {"ServerStorage", "CourseBuilders", "EggRush", "RestartP2", "Presentation"},
 {"ServerScriptService", "Services", "EggRushService"},
}
local function resolve(path)
 local object = game
 for _, name in path do object = assert(object:FindFirstChild(name), "Missing exact backup input: " .. table.concat(path, ".")) end
 return object
end
local function normalize(source) return (source:gsub("\r\n", "\n"):gsub("\r", "\n")) end
local function models(root)
 local count = 0
 for _, child in root:GetChildren() do if child:IsA("Model") then count += 1 end end
 return count
end
local function visit(root, action)
 action(root)
 for _, object in root:GetDescendants() do action(object) end
end
local function difference(a, b)
 if typeof(a) ~= typeof(b) then return math.huge end
 local kind = typeof(a)
 if kind == "number" then return math.abs(a - b) end
 if kind == "Vector3" then return math.max(math.abs(a.X - b.X), math.abs(a.Y - b.Y), math.abs(a.Z - b.Z)) end
 if kind == "Vector2" then return math.max(math.abs(a.X - b.X), math.abs(a.Y - b.Y)) end
 if kind == "Color3" then return math.max(math.abs(a.R - b.R), math.abs(a.G - b.G), math.abs(a.B - b.B)) end
 if kind == "CFrame" then
  local x, y, maximum = {a:GetComponents()}, {b:GetComponents()}, 0
  for i = 1, 12 do maximum = math.max(maximum, math.abs(x[i] - y[i])) end
  return maximum
 end
 return if a == b then 0 else math.huge
end
local function compare(original, restored)
 assert(#original == #restored, "Readback root count differs")
 local receipt = {instances = 0, parts = 0, models = 0, scripts = 0, normalizedSourceBytes = 0,
  references = 0, classes = {}, maximumNumericDifference = 0, tolerance = .00001, roots = {}}
 local mapped, deferred = {}, {}
 local function check(a, b, path)
  assert(a.Name == b.Name and a.ClassName == b.ClassName, "Readback hierarchy differs: " .. path)
  mapped[a] = b; receipt.instances += 1
  receipt.classes[a.ClassName] = (receipt.classes[a.ClassName] or 0) + 1
  local function equal(x, y, field)
   local d = difference(x, y); receipt.maximumNumericDifference = math.max(receipt.maximumNumericDifference, d)
   assert(d <= receipt.tolerance, "Readback property differs: " .. path .. "/" .. field)
  end
  local aa, ba = a:GetAttributes(), b:GetAttributes()
  for key, value in aa do equal(value, ba[key], "@" .. key) end
  for key in ba do assert(aa[key] ~= nil, "Readback added attribute: " .. path .. "/@" .. key) end
  equal(a.Archivable, b.Archivable, "Archivable")
  if a:IsA("BasePart") then
   receipt.parts += 1
   for _, key in {"CFrame", "Size", "Color", "Material", "MaterialVariant", "Transparency", "Anchored", "CanCollide", "CanTouch",
    "CanQuery", "CollisionGroup", "TopSurface", "BottomSurface", "Reflectance", "CastShadow"} do equal(a[key], b[key], key) end
  end
  if a:IsA("Part") then equal(a.Shape, b.Shape, "Shape") end
  if a:IsA("MeshPart") then
   for _, key in {"MeshId", "TextureID", "CollisionFidelity", "RenderFidelity", "DoubleSided"} do equal(a[key], b[key], key) end
  end
  if a:IsA("Model") then
   receipt.models += 1; equal(a:GetPivot(), b:GetPivot(), "Pivot")
   table.insert(deferred, {kind = "PrimaryPart", original = a.PrimaryPart, restored = b.PrimaryPart, path = path})
  end
  if a:IsA("ObjectValue") then
   receipt.references += 1
   table.insert(deferred, {kind = "ObjectValue", original = a.Value, restored = b.Value, path = path})
  end
  if a:IsA("LuaSourceContainer") then
   local sa, sb = normalize(a.Source), normalize(b.Source)
   assert(sa == sb, "Readback normalized source differs: " .. path)
   receipt.scripts += 1; receipt.normalizedSourceBytes += #sa
  end
  if a:IsA("Script") or a:IsA("LocalScript") then equal(a.Disabled, b.Disabled, "Disabled") end
  if a:IsA("TextLabel") or a:IsA("TextButton") then
   for _, key in {"Text", "TextColor3", "TextSize", "TextScaled", "TextWrapped", "FontFace", "BackgroundTransparency"} do equal(a[key], b[key], key) end
  end
  if a:IsA("SurfaceGui") then for _, key in {"Face", "CanvasSize", "PixelsPerStud", "SizingMode"} do equal(a[key], b[key], key) end end
  if a:IsA("Sound") then
   for _, key in {"SoundId", "Volume", "PlaybackSpeed", "Looped", "RollOffMinDistance", "RollOffMaxDistance"} do equal(a[key], b[key], key) end
  end
  local ac, bc = a:GetChildren(), b:GetChildren()
  assert(#ac == #bc, "Readback child count differs: " .. path)
  for index, child in ac do check(child, bc[index], path .. "/" .. child.Name .. "[" .. index .. "]") end
 end
 for index, root in original do
  assert(restored[index].Parent == nil, "Deserialized root must remain detached")
  check(root, restored[index], root.Name)
  table.insert(receipt.roots, {name = root.Name, descendants = #root:GetDescendants(), directModels = models(root),
   pivot = root:IsA("Model") and {root:GetPivot():GetComponents()} or nil})
 end
 for _, ref in deferred do
  if ref.original == nil then assert(ref.restored == nil, "Readback added reference: " .. ref.path)
  else
   assert(mapped[ref.original] ~= nil, "Backup contains an external reference: " .. ref.path)
   assert(ref.restored == mapped[ref.original], "Readback reference points elsewhere: " .. ref.path)
  end
 end
 return receipt
end

function Backup.Plan()
 local plan = {placeId = 85558151074819, candidateId = CANDIDATE, mode = "Edit only", url = URL, filename = FILE,
  roots = {}, sourcePaths = {}, sourceScriptsExpected = #SOURCES,
  sourceRoot = "Detached EggRush_P2_R01_C05_SourceRestore; restore its children by their RestorePath attributes",
  httpRequiredBeforeAndAfter = false,
  scope = "Five detached roots only; no live installation, place save, publication, receiver creation or existing artifact deletion"}
 for _, entry in GEOMETRY do table.insert(plan.roots, {path = table.concat(entry.path, "."), kind = entry.kind, directModelsExpected = entry.models}) end
 for _, path in SOURCES do table.insert(plan.sourcePaths, table.concat(path, ".")) end
 return plan
end

function Backup.Run()
 local runService, http = game:GetService("RunService"), game:GetService("HttpService")
 assert(runService:IsStudio() and not runService:IsRunning() and game.PlaceId == 85558151074819 and game.CreatorId == 86069177,
  "Intended experience in Edit mode required")
 local priorHttp = http.HttpEnabled
 assert(priorHttp == false, "Expected HTTP disabled before this bounded backup")
 local serializer = game:GetService("SerializationService")
 local created, restored, originalGeometry, clones, originals, sourceCopies = {}, nil, {}, {}, {}, {}
 local report = {ok = false, verified = false, filename = FILE, url = URL, placeId = game.PlaceId, candidateId = CANDIDATE,
  httpPrior = priorHttp, phase = 2, stage = "Preflight", roots = {}, sourceScriptsExpected = #SOURCES,
  originalRootsModified = false, scope = "Scoped model/source recovery; not a whole-place save, publication or owner acceptance"}
 local function track(root)
  assert(root.Parent == nil and not root:IsDescendantOf(game), "Only newly created detached roots may be tracked")
  table.insert(created, root); return root
 end
 local function assertArchivable(root)
  visit(root, function(object) assert(object.Archivable, "Nonarchivable backup input requires separate review: " .. object:GetFullName()) end)
 end
 local ok, failure = xpcall(function()
  for _, entry in GEOMETRY do
   local root = resolve(entry.path); assertArchivable(root)
   assert(root:IsA("Model") or root:IsA("Folder"), "Expected an owned Model/Folder backup root")
   visit(root, function(object) assert(not object:IsA("LuaSourceContainer"), "Unexpected source in geometry/kit/gallery root: " .. object:GetFullName()) end)
   if entry.models then assert(models(root) == entry.models, "Expected direct model count differs: " .. root:GetFullName()) end
   if entry.kind == "course" then
    assert(root:IsA("Model") and root:GetAttribute("CourseId") == "egg_rush_circuit" and root:GetAttribute("EROwned") == true
     and root:GetAttribute("CandidateId") == CANDIDATE and root:GetAttribute("Phase") == 2 and root:GetAttribute("Phase2Revision") == 5
     and root:GetAttribute("PresentationRevision") == "V03" and root:GetAttribute("FullBodyContacts") == true
     and root.CourseInfo:GetAttribute("Enabled") == true, "Expected the enabled C05/V03 full-body authoring candidate")
   end
   table.insert(originalGeometry, root)
   local clone = track(assert(root:Clone(), "Clone failed: " .. root:GetFullName()))
   table.insert(clones, clone)
   table.insert(report.roots, {name = clone.Name, kind = entry.kind, restorePath = table.concat(entry.path, "."),
    descendants = #root:GetDescendants(), directModels = models(root), pivot = root:IsA("Model") and {root:GetPivot():GetComponents()} or nil})
  end
  report.stage = "SourceClones"
  local sourceRoot = track(Instance.new("Folder")); sourceRoot.Name = "EggRush_P2_R01_C05_SourceRestore"
  sourceRoot:SetAttribute("CandidateId", CANDIDATE); sourceRoot:SetAttribute("SourceScriptsExpected", #SOURCES)
  sourceRoot:SetAttribute("RestoreMode", "Merge only the named children into their exact RestorePath; never replace a service")
  for _, entry in report.roots do sourceRoot:SetAttribute(entry.kind .. "RestorePath", entry.restorePath) end
  local containers = {[''] = sourceRoot}
  for _, path in SOURCES do
   local source = resolve(path)
   assert(source:IsA("ModuleScript") and #source:GetChildren() == 0, "Expected a childless canonical ModuleScript: " .. source:GetFullName())
   assertArchivable(source)
   local key, parent = "", sourceRoot
   for index = 1, #path - 1 do
    key = if key == "" then path[index] else key .. "." .. path[index]
    if not containers[key] then
     local folder = Instance.new("Folder"); folder.Name = path[index]
     local liveFolder = resolve({table.unpack(path, 1, index)})
     for name, value in liveFolder:GetAttributes() do folder:SetAttribute(name, value) end
     folder:SetAttribute("RestorePath", key); folder:SetAttribute("RestoreMode", "MergeChildrenOnly")
     folder.Parent = parent; containers[key] = folder
    end
    parent = containers[key]
   end
   local fullPath = table.concat(path, ".")
   local clone = assert(source:Clone(), "Source clone failed: " .. fullPath)
   clone:SetAttribute("RestorePath", fullPath); clone.Parent = parent
   local normalized = normalize(source.Source)
   assert(normalize(clone.Source) == normalized, "Original/clone normalized source differs: " .. fullPath)
   originals[fullPath], sourceCopies[fullPath] = {object = source, normalized = normalized}, clone
  end
  table.insert(clones, sourceRoot)
  assert(#clones == 5, "Expected four geometry roots plus one source root")
  report.originalCloneGeometry = compare(originalGeometry, {clones[1], clones[2], clones[3], clones[4]})
  report.sourceManifest, report.sourceScriptsExact = {}, 0
  for _, path in SOURCES do
   local fullPath = table.concat(path, ".")
   local entry = originals[fullPath]
   assert(normalize(entry.object.Source) == entry.normalized and normalize(sourceCopies[fullPath].Source) == entry.normalized,
    "Canonical source changed while preparing backup: " .. fullPath)
   report.sourceScriptsExact += 1
   table.insert(report.sourceManifest, {restorePath = fullPath, normalizedBytes = #entry.normalized, originalCloneExact = true})
  end
  assert(report.sourceScriptsExact == 20, "Expected exactly twenty allowlisted source scripts")
  report.stage = "Serialize"
  local body = buffer.tostring(serializer:SerializeInstancesAsync(clones))
  assert(#body >= 32 and body:sub(1, 8) == "<roblox!", "Native serialization did not return a binary Roblox model")
  report.serializedBytes = #body
  http.HttpEnabled = true
  report.stage = "FreshFilenameCheck"
  local existing = http:RequestAsync({Url = URL, Method = "GET"})
  assert(not existing.Success and existing.StatusCode == 404, "Fresh filename required; existing files are never overwritten")
  report.stage = "POST"
  local response = http:RequestAsync({Url = URL, Method = "POST", Headers = {["Content-Type"] = "application/octet-stream"}, Body = body})
  assert(response.Success, "Backup receiver rejected POST: " .. tostring(response.StatusCode))
  report.receipt = http:JSONDecode(response.Body)
  assert(report.receipt.file == FILE and report.receipt.bytes == #body and typeof(report.receipt.sha256) == "string"
   and #report.receipt.sha256 == 64 and report.receipt.sha256:match("^[%da-fA-F]+$"), "Receiver receipt does not match this file/byte count")
  report.stage = "GETReadback"
  local readback = http:GetAsync(URL, true)
  assert(readback == body, "Saved GET bytes differ from native serialization")
  report.byteReadbackEqual = true
  report.stage = "DetachedDeserialize"
  restored = serializer:DeserializeInstancesAsync(buffer.fromstring(readback))
  for _, root in restored do track(root) end
  assert(#restored == 5, "Detached readback root count differs")
  report.comparison = compare(clones, restored)
  assert(report.comparison.scripts == 20, "Detached readback did not contain exactly twenty source scripts")
  local restoredScripts = {}
  for _, root in restored do
   visit(root, function(object)
    if object:IsA("LuaSourceContainer") then
     local restorePath = object:GetAttribute("RestorePath")
     assert(typeof(restorePath) == "string" and originals[restorePath] and not restoredScripts[restorePath], "Unknown or duplicate restored source path")
     assert(normalize(object.Source) == originals[restorePath].normalized, "Restored/original normalized source differs: " .. restorePath)
     restoredScripts[restorePath] = true
    end
   end)
  end
  for path, entry in originals do
   assert(restoredScripts[path] and normalize(entry.object.Source) == entry.normalized, "Missing restored source or original changed during export: " .. path)
  end
  report.sourceScriptsOriginalCloneRestoredExact = 20
  report.coursePivot, report.galleryPivot = {restored[1]:GetPivot():GetComponents()}, {restored[4]:GetPivot():GetComponents()}
  report.detached = true
  report.stage = "Verified"
 end, debug.traceback)
 local restoredHttp, httpFailure = pcall(function() http.HttpEnabled = priorHttp; assert(http.HttpEnabled == false, "HTTP did not return to false") end)
 report.httpRestored = restoredHttp and http.HttpEnabled == priorHttp
 local cleanupErrors, destroyed = {}, 0
 for index = #created, 1, -1 do
  local root = created[index]
  local cleaned, why = pcall(function()
   assert(root.Parent == nil and not root:IsDescendantOf(game), "Refuse cleanup of a parented or original instance")
   root:Destroy(); destroyed += 1
  end)
  if not cleaned then table.insert(cleanupErrors, tostring(why)) end
 end
 report.detachedRootsCreated, report.detachedRootsDestroyed, report.cleanupErrors = #created, destroyed, cleanupErrors
 report.httpFailure, report.failure = if restoredHttp then nil else tostring(httpFailure), if ok then nil else failure
 report.ok = ok and report.httpRestored and #cleanupErrors == 0
 report.verified = report.ok and report.byteReadbackEqual == true and report.sourceScriptsOriginalCloneRestoredExact == 20
 return report
end

return Backup
