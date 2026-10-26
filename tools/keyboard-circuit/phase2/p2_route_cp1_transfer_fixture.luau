local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local holder = roblox.Instance.new("Folder")
holder.Name = "OfflineLayoutFixture"
local source = roblox.Instance.new("Folder")
source.Name, source.Parent = "SourceSnapshot", holder
local compiled = 0
local sourceTexts = {}
for _, name in fs.readDir("tools/keyboard-circuit/phase2/staged/") do
	if name:sub(-5) ~= ".luau" then continue end
	local path = if name == "Layout.luau" then "tools/keyboard-circuit/phase2/p2_route_cp1_layout_proposed.luau" else "tools/keyboard-circuit/phase2/staged/" .. name
	local content = fs.readFile(path)
	sourceTexts[name] = content
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
	local content = item.Source
	if item.Name == "Course" then
		-- Lune does not synthesize BasePart.Position from CFrame as Roblox does.
		content = content:gsub("fromContact%.Position", "fromContact.CFrame.Position"):gsub("toContact%.Position", "toContact.CFrame.Position")
	end
	cache[item] = luau.load(content, {environment = env, debugName = item.Name})()
	return cache[item]
end
local accepted = roblox.deserializeModel(fs.readFile("docs/artifacts/keyboard-circuit/phase1/native/KeyboardCircuit_P1_C08.rbxm"))[1]
local template
for _, item in accepted:GetDescendants() do if item:IsA("MeshPart") then template = item:Clone(); break end end
assert(template)
for _, child in template:GetChildren() do child:Destroy() end
local root = loadModule(source.Course).Build(holder, roblox.Vector3.new(3300, 330, -1600), template)
local contacts, colliders, units, sourceHashes = {}, {}, {}, {}
local sequences, mechanisms, experts, meshes = 0, 0, 0, 0
for _, item in root:GetDescendants() do
	if item:GetAttribute("SequenceId") then sequences += 1 end
	if item:GetAttribute("MechanismId") then mechanisms += 1 end
	if item:GetAttribute("ExpertId") then experts += 1 end
	if item:IsA("MeshPart") then
		meshes += 1
		local visible = 0
		for _, gui in item:GetChildren() do if gui:IsA("SurfaceGui") and gui.Enabled then visible += 1 end end
		assert(visible == 1 and utf8.len(item:GetAttribute("KeyLegend")) == 1)
	end
	if item:IsA("BasePart") and item.CanCollide then
		local position = item.CFrame.Position
		local row = {path = item:GetFullName(), position = {position.X, position.Y, position.Z}, cf = {item.CFrame:GetComponents()}, size = {item.Size.X, item.Size.Y, item.Size.Z}, role = item:GetAttribute("Role")}
		table.insert(colliders, row)
		if item.Name == "BankContact" or item.Name == "KeyContact" or item.Parent.Name == "RecoveryPads" then table.insert(contacts, row) end
	end
	if item:IsA("Model") and item:GetAttribute("EntryPosition") and item:GetAttribute("ExitPosition") then
		local entry, exit = item:GetAttribute("EntryPosition"), item:GetAttribute("ExitPosition")
		units[item.Name] = {entry = {entry.X, entry.Y, entry.Z}, exit = {exit.X, exit.Y, exit.Z}}
	end
end
assert(sequences == 16 and mechanisms == 8 and experts == 2)
assert(#root.RouteEdges:GetChildren() == 25 and #root.Gates:GetChildren() == 5 and #root.RecoveryPads:GetChildren() == 4)
local Layout = loadModule(source.Layout)
local xml = fs.readFile("docs/artifacts/keyboard-circuit/keyboard-circuit.drawio")
for index, id in Layout.Main do
	assert(xml:find('source="' .. id .. '" target="' .. Layout.Main[index % #Layout.Main + 1] .. '"', 1, true))
end
local report = {fixture = "Actual staged Course with proposed Layout replaced in memory; contact Position reads mapped to CFrame.Position for Lune", layoutRevision = Layout.Revision, passed = true, compiledSources = compiled, sourceTexts = sourceTexts, sequenceCount = sequences, mechanismCount = mechanisms, expertCount = experts, meshes = meshes, contacts = contacts, colliders = colliders, units = units, limits = "Offline Lune construction. Model pivots use fixture methods; only Course fromContact.Position/toContact.Position read expressions are adapted to CFrame.Position because Lune does not synthesize the property. Recorded source texts remain unmodified. Accepted C08 key template is stripped of descendants. Not native Studio/physics/input, carrying, headroom, human difficulty, race duration or performance proof."}
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/research/p2_route_cp1_transfer_fixture.json", serde.encode("json", report, true))
print(serde.encode("json", {passed = true, layoutRevision = Layout.Revision, compiledSources = compiled, contacts = #contacts, colliders = #colliders, meshes = meshes, sequences = sequences, mechanisms = mechanisms, experts = experts}))
