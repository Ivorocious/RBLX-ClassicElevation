local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local V, C = roblox.Vector3, roblox.CFrame
local root = roblox.Instance.new("Model")
root.Name = "P2_OfflineMechanismFixture"
root:SetAttribute("Phase2Only", true)
root:SetAttribute("OfflineFixtureOnly", true)
roblox.implementMethod("Model", "GetPivot", function(model)
	return if model.PrimaryPart then model.PrimaryPart.CFrame * model.PrimaryPart.PivotOffset else model.WorldPivotData or C.identity
end)
roblox.implementMethod("Model", "PivotTo", function(model, target)
	local delta = target * model:GetPivot():Inverse()
	for _,part in model:GetDescendants() do if part:IsA("BasePart") then part.CFrame = delta * part.CFrame end end
	model.WorldPivotData = target
end)
local source = roblox.Instance.new("Folder")
source.Name, source.Parent = "Source", root
for _,name in {"Mechanisms", "Motion", "Layout"} do
	local item = roblox.Instance.new("ModuleScript")
	item.Name, item.Source, item.Parent = name, fs.readFile("tools/keyboard-circuit/phase2/staged/" .. name .. ".luau"), source
end
for name, path in {Parts = "src/ServerStorage/CourseBuilders/KeyboardCircuit/Parts.luau", ConfigSnapshot = "src/ReplicatedStorage/Config/KeyboardCircuitConfig.luau"} do
	local item = roblox.Instance.new("ModuleScript")
	item.Name, item.Source, item.Parent = name, fs.readFile(path), source
end
local cache = {}
local function loadModule(item)
	if cache[item] then return cache[item] end
	local env = {script = item, require = loadModule}
	for key, value in roblox do env[key] = value end
	cache[item] = luau.load(item.Source, {environment = env, debugName = item.Name})()
	return cache[item]
end
local Mechanisms, Motion = loadModule(source.Mechanisms), loadModule(source.Motion)
local accepted = roblox.deserializeModel(fs.readFile("docs/artifacts/keyboard-circuit/phase1/native/KeyboardCircuit_P1_C08.rbxm"))[1]
local template
for _,item in accepted:GetDescendants() do if item:IsA("MeshPart") then template = item:Clone(); break end end
assert(template, "Accepted C08 cap template required")
for _,child in template:GetChildren() do child:Destroy() end
local rows, models, parts, meshes, actors, lethalShapes = {}, 0, 0, 0, 0, 0
for index, pair in {{"Seesaws", "Seesaws"}, {"Fallaway", "Fallaway"}, {"Foundry", "Foundry"}, {"Lift", "Lift"}, {"Shuttle", "Shuttle"}, {"Sweep", "Sweep"}, {"Domino", "Domino"}, {"Shift", "ShiftWindows"}} do
	local kind, constructor = pair[1], pair[2]
	local cf = C.new(index * 150, 20, 0) * C.Angles(0, .55, 0)
	local unit = Mechanisms[constructor](root, template, cf)
	local entry, exit = Mechanisms.GetEndpoints(unit)
	assert((entry - cf:PointToWorldSpace(Mechanisms.Endpoints[kind].entry)).Magnitude < .001)
	assert((exit - cf:PointToWorldSpace(Mechanisms.Endpoints[kind].exit)).Magnitude < .001)
	local beforeEntry = entry
	unit:PivotTo(unit:GetPivot() + V.new(0, 0, 7))
	entry, exit = Mechanisms.GetEndpoints(unit)
	assert((entry - beforeEntry - V.new(0, 0, 7)).Magnitude < .001, "Moved mechanism endpoint contract")
	unit:PivotTo(unit:GetPivot() - V.new(0, 0, 7))
	local actorCount, unitShapes = 0, 0
	for _,item in unit:GetDescendants() do
		if item:IsA("Model") then models += 1 end
		if item:IsA("BasePart") then parts += 1 end
		if item:IsA("MeshPart") then meshes += 1 end
		if item:GetAttribute("KCMover") then actors += 1; actorCount += 1 end
		if item:GetAttribute("Role") == "Lethal" then
			assert(item:IsA("BasePart") and item.CanQuery and not item.CanCollide and not item.CanTouch, "Lethal shape flags")
			lethalShapes += 1; unitShapes += 1
		end
	end
	assert(unit.EntryBank:GetAttribute("Role") == "SafeRefuge" and unit.ExitBank:GetAttribute("Role") == "SafeRefuge")
	if kind == "Seesaws" then assert(unit.Hinge1.Enabled == false and unit.Hinge2.Enabled == false) end
	if kind == "Lift" or kind == "Shuttle" then
		assert(unit.Slider.Enabled == false and unit.Slider.ActuatorType == roblox.Enum.ActuatorType.Servo)
		assert(unit.RideableBank.BankContact.CanCollide)
		assert(unit.RideableBank:FindFirstChild("Base"):FindFirstChildOfClass("WeldConstraint"))
	end
	table.insert(rows, {id = unit:GetAttribute("MechanismId"), kind = kind, actors = actorCount, lethalShapes = unitShapes, entry = {Mechanisms.Endpoints[kind].entry.X, Mechanisms.Endpoints[kind].entry.Y, Mechanisms.Endpoints[kind].entry.Z}, exit = {Mechanisms.Endpoints[kind].exit.X, Mechanisms.Endpoints[kind].exit.Y, Mechanisms.Endpoints[kind].exit.Z}})
end
local font
for _,item in accepted:GetDescendants() do if item:IsA("TextLabel") then font = item.FontFace; break end end
assert(font, "Accepted native font required for Lune serialization")
for _,item in root:GetDescendants() do if item:IsA("TextLabel") then item.FontFace = font end end
local bytes = roblox.serializeModel({root})
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/research/p2_route_mechanism_fixture.rbxm", bytes)
local restored = roblox.deserializeModel(bytes)[1]
assert(#restored:GetDescendants() == #root:GetDescendants(), "Offline native round-trip count")
local output = {status = "passed", fixtureOnly = true, template = "Owned clone of accepted C08 native cap; descendants stripped to match bare AssetImports template", constructors = rows, models = models, parts = parts, meshes = meshes, actors = actors, lethalShapes = lethalShapes, nativeBytes = #bytes, roundTripInstances = #restored:GetDescendants(), limits = "Lune native construction/serialization and structural checks. Uses simulated Model pivot methods; does not run Roblox physics, spatial contact queries, avatar carrying or Studio gameplay."}
fs.writeFile("docs/artifacts/keyboard-circuit/phase2/research/p2_route_native_receipt.json", serde.encode("json", output, true))
print(serde.encode("json", output, true))
