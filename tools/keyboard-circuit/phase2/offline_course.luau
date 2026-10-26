local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local prefix = "tools/keyboard-circuit/phase2/staged/"
local holder = roblox.Instance.new("Folder")
local source = roblox.Instance.new("Folder")
source.Name, source.Parent = "SourceSnapshot", holder
local compiled = 0
for _, name in fs.readDir(prefix) do
	if name:sub(-5) ~= ".luau" then continue end
	local content = fs.readFile(prefix .. name)
	luau.load(content, {debugName = name})
	compiled += 1
	local item = roblox.Instance.new("ModuleScript")
	item.Name = name:gsub("%.server%.luau$", ""):gsub("%.client%.luau$", ""):gsub("%.luau$", "")
	item.Source, item.Parent = content, source
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
	for key, value in roblox do env[key] = value end
	cache[item] = luau.load(item.Source, {environment = env, debugName = item.Name})()
	return cache[item]
end
local accepted = roblox.deserializeModel(fs.readFile("docs/artifacts/keyboard-circuit/phase1/native/KeyboardCircuit_P1_C08.rbxm"))[1]
local template
for _, item in accepted:GetDescendants() do if item:IsA("MeshPart") then template = item:Clone(); break end end
assert(template)
for _, child in template:GetChildren() do child:Destroy() end
local root = loadModule(source.Course).Build(holder, roblox.Vector3.new(3300, 330, -1600), template)
source.Parent = root
local sequences, mechanisms, experts, meshes, parts, legends, colliders, constraints, lights = {}, {}, {}, 0, 0, 0, 0, 0, 0
for _, item in root:GetDescendants() do
	local sequence, mechanism, expert = item:GetAttribute("SequenceId"), item:GetAttribute("MechanismId"), item:GetAttribute("ExpertId")
	if sequence then assert(not sequences[sequence], "Duplicate sequence"); sequences[sequence] = item end
	if mechanism then assert(not mechanisms[mechanism], "Duplicate mechanism"); mechanisms[mechanism] = item end
	if expert then assert(not experts[expert], "Duplicate expert"); experts[expert] = item end
	if item:IsA("BasePart") then parts += 1; if item.CanCollide then colliders += 1 end end
	if item:IsA("MeshPart") then
		meshes += 1
		local visible = 0
		for _, gui in item:GetChildren() do if gui:IsA("SurfaceGui") and gui.Enabled then visible += 1 end end
		assert(visible == 1, "Ordinary key must have one visible legend " .. item:GetFullName())
		assert(utf8.len(item:GetAttribute("KeyLegend")) == 1, "Ordinary key needs exactly one character")
		legends += 1
	end
	if item:IsA("Light") then lights += 1 end
	if item:IsA("Constraint") then constraints += 1 end
	if item:IsA("ObjectValue") and item.Value then assert(item.Value:IsDescendantOf(root), "External object reference") end
	if item:IsA("WeldConstraint") then assert(item.Part0:IsDescendantOf(root) and item.Part1:IsDescendantOf(root), "External weld") end
end
local function count(map) local n = 0; for _ in map do n += 1 end; return n end
assert(count(sequences) == 16 and count(mechanisms) == 8 and count(experts) == 2)
assert(#root.RouteEdges:GetChildren() == 25 and #root.RecoveryPads:GetChildren() == 4 and #root.Gates:GetChildren() == 5)
local Layout = loadModule(source.Layout)
local xml = fs.readFile("docs/artifacts/keyboard-circuit/keyboard-circuit.drawio")
for index, id in Layout.Main do
	local nextId = Layout.Main[index % #Layout.Main + 1]
	assert(xml:find('source="' .. id .. '" target="' .. nextId .. '"', 1, true))
	assert(root.RouteEdges:FindFirstChild(id .. "_to_" .. nextId))
end
local report = {
	revision = "KC_P2_C01", passed = true, compiledSources = compiled,
	sequences = count(sequences), mechanisms = count(mechanisms), expertChains = count(experts), routeEdges = 25,
	descendants = #root:GetDescendants(), parts = parts, meshes = meshes, oneCharacterMeshLegends = legends,
	colliders = colliders, constraints = constraints, lights = lights, orderedGateObjects = 5, stableRecoveryPads = 4,
	limits = "Offline Lune construction and syntax/XML/internal-reference checks. Model pivots are implemented by the fixture; this is not Roblox engine, contact, carrying, traversal, sound or performance proof.",
}
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/P2-C01-offline-construction.json", serde.encode("json", report, true))
print(serde.encode("json", report))
