local fs, luau, roblox, serde = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox"), require("@lune/serde")
local prefix = "tools/keyboard-circuit/phase2/work-i09/"
local holder, sources = roblox.Instance.new("Folder"), roblox.Instance.new("Folder")
sources.Name, sources.Parent = "Sources", holder
local compiled, hashes = 0, {}
for _, file in fs.readDir(prefix .. "sources/") do
 if file:sub(-5) ~= ".luau" then continue end
 local content = fs.readFile(prefix .. "sources/" .. file)
 luau.load(content, {debugName = file}); compiled += 1
 local name = file:gsub("%.server%.luau$", ""):gsub("%.client%.luau$", ""):gsub("%.luau$", "")
 local item = roblox.Instance.new("ModuleScript")
 item.Name, item.Source, item.Parent = name, content, sources
 hashes[name] = serde.hash("sha256", content)
end
roblox.implementMethod("Model", "GetPivot", function(model)
 return if model.PrimaryPart then model.PrimaryPart.CFrame * model.PrimaryPart.PivotOffset else model.WorldPivotData or roblox.CFrame.identity
end)
roblox.implementMethod("Model", "PivotTo", function(model, target)
 local delta = target * model:GetPivot():Inverse()
 for _, part in model:GetDescendants() do if part:IsA("BasePart") then part.CFrame = delta * part.CFrame end end
 model.WorldPivotData = target
end)
local cache = {}
local function loadModule(item)
 if cache[item] then return cache[item] end
 local env = {script = item, require = loadModule}
 for k,v in roblox do env[k] = v end
 cache[item] = luau.load(item.Source, {environment = env, debugName = item.Name})()
 return cache[item]
end
local accepted = roblox.deserializeModel(fs.readFile("docs/artifacts/keyboard-circuit/phase1/native/KeyboardCircuit_P1_C08.rbxm"))[1]
local template
for _, item in accepted:GetDescendants() do if item:IsA("MeshPart") then template = item:Clone(); break end end
assert(template)
for _, child in template:GetChildren() do child:Destroy() end
local root = loadModule(sources.Course).Build(holder, roblox.Vector3.new(22500, 330, -1600), template)
local report = {compiled = compiled, sourceHashes = hashes, parts = 0, caps = 0, colliders = 0, specialCaps = 0, main = 0, mechanisms = 0, branches = {}, recoveries = {}}
local function vec(v) return {v.X,v.Y,v.Z} end
local function endpoint(unit, departing)
 if unit:FindFirstChild("BankContact") then return unit.BankContact end
 return (unit:FindFirstChild(departing and "ExitBank" or "EntryBank") or unit:FindFirstChild(departing and "Exit" or "Entry")).BankContact
end
local units = {}
for _, item in root:GetDescendants() do
 if item:GetAttribute("SequenceId") then report.main += 1; units[item:GetAttribute("SequenceId")] = item end
 if item:GetAttribute("MechanismId") then report.mechanisms += 1 end
 if item:IsA("BasePart") then report.parts += 1; if item.CanCollide then report.colliders += 1 end end
 if item:IsA("MeshPart") and item:GetAttribute("Pressable") then
  report.caps += 1; assert(utf8.len(item:GetAttribute("KeyLegend")) == 1)
  if item.Name == "KeyTop" then report.specialCaps += 1; assert(item:GetAttribute("CapProfile") == "Beveled K02") end
 end
end
for _, item in root.CheckpointBays:GetChildren() do units[item.Name] = item end
for _, branch in root.ExpertRoutes:GetChildren() do
 local rows = {}
 for _, landing in branch.TraversalPoints:GetChildren() do
  local contact = branch["PrecisionLanding" .. landing.Name].KeyContact
  for _, other in root:GetDescendants() do
   if other:IsA("BasePart") and other.CanCollide and other ~= contact then
    local localPoint = other.CFrame:PointToObjectSpace(contact.CFrame.Position)
    assert(not (math.abs(localPoint.X) <= other.Size.X / 2 and math.abs(localPoint.Z) <= other.Size.Z / 2 and localPoint.Y <= other.Size.Y / 2 and localPoint.Y >= -8), "Precision contact masked by " .. other:GetFullName())
   end
  end
  table.insert(rows,{ordinal=landing:GetAttribute("Ordinal"),position=vec(landing.Value),size=vec(contact.Size),frame={contact.CFrame:GetComponents()}})
 end
 table.sort(rows,function(a,b) return a.ordinal<b.ordinal end)
 report.branches[branch:GetAttribute("ExpertId")] = {caps=branch:GetAttribute("PrecisionLandings"),path=rows,arc=branch:GetAttribute("ArcLength"),start=vec(branch:GetAttribute("PrecisionStartPosition")),merge=vec(branch:GetAttribute("PrecisionMergePosition")),from=branch:GetAttribute("BranchAfter"),before=branch:GetAttribute("MergeBefore")}
end
for _, pad in root.RecoveryPads:GetChildren() do
 local contact = pad.BankContact
 assert(not contact.CanCollide and contact.Transparency == 1)
 report.recoveries[pad.Name] = {spawn = vec(contact:GetAttribute("SpawnCFrame").Position),visibleParts=0}
 for _, part in pad:GetDescendants() do if part:IsA("BasePart") then assert(part.Transparency == 1) end end
end
report.normalEdges, report.branchCount = #root.RouteEdges:GetChildren(), #root.ExpertRoutes:GetChildren()
assert(report.main == 16 and report.mechanisms == 8 and report.branchCount == 2 and report.normalEdges == 25)
report.contacts = {}
for id,unit in units do
 report.contacts[id] = {entry=vec(endpoint(unit,false).CFrame.Position),exit=vec(endpoint(unit,true).CFrame.Position)}
end
for _, item in root:GetDescendants() do
 if item:IsA("TextLabel") then item.FontFace = roblox.Font.new("rbxasset://fonts/families/GothamSSm.json", roblox.Enum.FontWeight.Bold, roblox.Enum.FontStyle.Normal) end
end
fs.writeFile(prefix.."I09-preview.rbxm",roblox.serializeModel({root}))
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/P2-I09-offline-geometry-01.json",serde.encode("json",report,true))
print(serde.encode("json",{compiled=compiled,parts=report.parts,caps=report.caps,colliders=report.colliders,specialCaps=report.specialCaps,branches=report.branchCount,edges=report.normalEdges,status="passed"}))

