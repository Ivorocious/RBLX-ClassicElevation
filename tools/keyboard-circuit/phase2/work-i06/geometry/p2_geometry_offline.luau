local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local baselinePath = "tools/keyboard-circuit/phase2/staged/"
local candidatePath = "tools/keyboard-circuit/phase2/work-i06/geometry/"
local outputPath = candidatePath .. "O07-I06-offline.json"
local checks = 0
local function check(condition, message)
	assert(condition, message)
	checks += 1
end
roblox.implementMethod("Model", "GetPivot", function(model)
	return if model.PrimaryPart then model.PrimaryPart.CFrame * model.PrimaryPart.PivotOffset else model.WorldPivotData or roblox.CFrame.identity
end)
roblox.implementMethod("Model", "PivotTo", function(model, target)
	local delta = target * model:GetPivot():Inverse()
	for _, part in model:GetDescendants() do if part:IsA("BasePart") then part.CFrame = delta * part.CFrame end end
	model.WorldPivotData = target
end)
local accepted = roblox.deserializeModel(fs.readFile("docs/artifacts/keyboard-circuit/phase1/native/KeyboardCircuit_P1_C08.rbxm"))[1]
local template
for _, item in accepted:GetDescendants() do if item:IsA("MeshPart") then template = item:Clone(); break end end
assert(template)
for _, child in template:GetChildren() do child:Destroy() end
local function count(map) local n = 0; for _ in map do n += 1 end; return n end
local function construct(candidate)
	local holder = roblox.Instance.new("Folder")
	local source = roblox.Instance.new("Folder")
	source.Name, source.Parent = "SourceSnapshot", holder
	local compiled = 0
	for _, name in fs.readDir(baselinePath) do
		if name:sub(-5) ~= ".luau" then continue end
		local path = if candidate and (name == "Parts.luau" or name == "StaticPatterns.luau") then candidatePath else baselinePath
		local content = fs.readFile(path .. name)
		luau.load(content, {debugName = name})
		compiled += 1
		local item = roblox.Instance.new("ModuleScript")
		item.Name = name:gsub("%.server%.luau$", ""):gsub("%.client%.luau$", ""):gsub("%.luau$", "")
		item.Source, item.Parent = content, source
	end
	local cache = {}
	local function loadModule(item)
		if cache[item] then return cache[item] end
		local env = {script = item, require = loadModule}
		for key, value in roblox do env[key] = value end
		cache[item] = luau.load(item.Source, {environment = env, debugName = item.Name})()
		return cache[item]
	end
	local root = loadModule(source.Course).Build(holder, roblox.Vector3.new(3300, 330, -1600), template)
	source.Parent = root
	local sequences, mechanisms, experts = {}, {}, {}
	local inventory = {parts = 0, meshes = 0, colliders = 0, descendants = #root:GetDescendants(), compiled = compiled}
	for _, item in root:GetDescendants() do
		for attr, map in {SequenceId = sequences, MechanismId = mechanisms, ExpertId = experts} do
			local id = item:GetAttribute(attr)
			if id then check(not map[id], "Duplicate " .. attr); map[id] = item end
		end
		if item:IsA("BasePart") then
			inventory.parts += 1
			if item.CanCollide then inventory.colliders += 1 end
		end
		if item:IsA("MeshPart") then
			inventory.meshes += 1
			local visible = 0
			for _, gui in item:GetChildren() do if gui:IsA("SurfaceGui") and gui.Enabled then visible += 1 end end
			check(visible == 1 and utf8.len(item:GetAttribute("KeyLegend")) == 1, "One visible character per cap")
		end
		if item:IsA("ObjectValue") and item.Value then check(item.Value:IsDescendantOf(root), "External object reference") end
		if item:IsA("WeldConstraint") then check(item.Part0:IsDescendantOf(root) and item.Part1:IsDescendantOf(root), "External weld") end
	end
	check(count(sequences) == 16 and count(mechanisms) == 8 and count(experts) == 2, "Complete course inventory")
	check(#root.RouteEdges:GetChildren() == 25 and #root.RecoveryPads:GetChildren() == 4 and #root.Gates:GetChildren() == 5, "Route/recovery/gate inventory")
	local Layout = loadModule(source.Layout)
	local xml = fs.readFile("docs/artifacts/keyboard-circuit/keyboard-circuit.drawio")
	for index, id in Layout.Main do
		local nextId = Layout.Main[index % #Layout.Main + 1]
		check(xml:find('source="' .. id .. '" target="' .. nextId .. '"', 1, true) ~= nil and root.RouteEdges:FindFirstChild(id .. "_to_" .. nextId), "Native-plan route edge")
	end
	return {root = root, sequences = sequences, inventory = inventory, source = source, load = loadModule}
end
local baseline, candidate = construct(false), construct(true)
local function pathFrom(item, root)
	local names = {}
	while item ~= root do table.insert(names, 1, item.Name); item = item.Parent end
	return table.concat(names, "/")
end
local function geometry(model)
	local result = {}
	for _, item in model:GetDescendants() do
		if item:IsA("BasePart") then
			result[pathFrom(item, model)] = {item.Size, item.CFrame, item.CanCollide, item.CanQuery, item.CanTouch, item.Color, item:GetAttribute("Role")}
		end
	end
	return result
end
for _, id in {"O01", "O02", "O03", "O04", "O05", "O06", "O08"} do
	local before, after = geometry(baseline.sequences[id]), geometry(candidate.sequences[id])
	check(count(before) == count(after), "Unchanged part count " .. id)
	for name, row in before do
		check(after[name] ~= nil, "Preserved part " .. id .. "/" .. name)
		for index, value in row do check(value == after[name][index], "Preserved geometry " .. id .. "/" .. name) end
	end
end
local o05 = candidate.sequences.O05
local bracketMarks = {}
for name, mark in {Entry = "[", BracketLeft = "[", TopArm = "[", BracketRight = "]", BottomArm = "]", Exit = "]"} do
	local bank = o05:FindFirstChild(name, true)
	check(bank.Key_1_1:GetAttribute("KeyLegend") == mark and bank.Key_1_1.Legend.TextLabel.Text == mark, "Supplied bracket survives " .. name)
	bracketMarks[name] = mark
end
local Parts = candidate.load(candidate.source.Parts)
local scratch = roblox.Instance.new("Folder")
for input, expected in {Esc = "⎋", ENTER = "↵", SPACE = "␣", ["["] = "[", ["]"] = "]", A = "A", ["Ω"] = "Ω", Unknown = "1"} do
	local bank = Parts.Bank(scratch, input, template, roblox.CFrame.identity, 2, 2, "Clicky", input)
	check(bank.Key_1_1:GetAttribute("KeyLegend") == expected, "Alias/single-character/fallback " .. input)
end
local o07, oldO07 = candidate.sequences.O07, baseline.sequences.O07
for _, attr in {"EntryPosition", "ExitPosition", "EntryLocal", "ExitLocal"} do check(o07:GetAttribute(attr) == oldO07:GetAttribute(attr), "O07 endpoint " .. attr) end
for _, name in {"Entry", "Exit", "MarkedKillKeyLeft", "MarkedKillKeyRight"} do
	local before, after = geometry(oldO07[name]), geometry(o07[name])
	check(count(before) == count(after), "O07 endpoint/hazard part count")
	for key, row in before do for index, value in row do check(value == after[key][index], "O07 endpoint/hazard geometry") end end
end
local function contains(part, position)
	local localPoint = part.CFrame:PointToObjectSpace(position)
	return math.abs(localPoint.X) < part.Size.X / 2 and math.abs(localPoint.Z) < part.Size.Z / 2
end
local function keyAt(contact, position)
	local bank = contact.Parent
	local point = contact.CFrame:PointToObjectSpace(position)
	local x = math.clamp(math.floor(point.X / bank:GetAttribute("GridPitchX") + bank:GetAttribute("Columns") / 2) + 1, 1, bank:GetAttribute("Columns"))
	local z = math.clamp(math.floor(point.Z / bank:GetAttribute("GridPitchZ") + bank:GetAttribute("Rows") / 2) + 1, 1, bank:GetAttribute("Rows"))
	return bank:FindFirstChild("Key_" .. x .. "_" .. z)
end
local function separation(a, b)
	local largestGap = -math.huge
	for _, axis in {a.CFrame.RightVector, a.CFrame.LookVector, b.CFrame.RightVector, b.CFrame.LookVector} do
		local function radius(part)
			return math.abs(axis:Dot(part.CFrame.RightVector)) * part.Size.X / 2 + math.abs(axis:Dot(part.CFrame.LookVector)) * part.Size.Z / 2
		end
		largestGap = math.max(largestGap, math.abs((a.CFrame.Position - b.CFrame.Position):Dot(axis)) - radius(a) - radius(b))
	end
	return largestGap
end
local arrows, minimumHazardSeparation = {}, math.huge
for name, destination in {ArrowTurnRight = o07.ArrowTurnLeft, ArrowTurnLeft = o07.Exit} do
	local arrow = o07[name]
	local pose = arrow.BankContact.CFrame * roblox.CFrame.new(0, Parts.PressDepth + .125, 0)
	local contacts, occupied, keys = {}, {}, 0
	local target = destination:GetAttribute("TopPosition") - arrow:GetAttribute("TopPosition")
	target = roblox.Vector3.new(target.X, 0, target.Z).Unit
	check(pose.RightVector:Dot(target) > .99999 and arrow:GetAttribute("ArrowDirection"):Dot(target) > .99999, "Arrow points to actual next landing")
	check((arrow.BankContact.Size - oldO07[name].BankContact.Size).Magnitude < .001, "Preserved generous core landing")
	for _, item in arrow:GetDescendants() do
		if item.Name == "BankContact" then table.insert(contacts, item) end
		if item:IsA("MeshPart") then
			keys += 1
			local p = pose:PointToObjectSpace(item.CFrame.Position)
			local x, z = math.round(p.X / Parts.KeyPitch), math.round(p.Z / Parts.KeyPitch)
			if x == 0 then x = 0 end
			if z == 0 then z = 0 end
			check(math.abs(p.X - x * Parts.KeyPitch) < .001 and math.abs(p.Z - z * Parts.KeyPitch) < .001, "Arrow cell grid")
			occupied[x .. ":" .. z] = true
			check((item.Size - roblox.Vector3.new(2.42, .85, 2.42)).Magnitude < .001 and item:GetAttribute("KeyLegend") == "→", "Arrow cap scale/mark")
			check(not item.CanCollide and item:GetAttribute("Pressable") and item:GetAttribute("PressDepth") == .45, "Cosmetic held-key contract")
			check(keyAt(item.Parent.BankContact, item.CFrame.Position) == item, "Unchanged Feedback.keyAt grid resolution")
		end
	end
	check(keys == 31 and #contacts == 5, "Arrow cap/contact inventory")
	for x = -2, 4 do for z = -3, 3 do
		local expected = math.abs(x) <= 2 and math.abs(z) <= 2 or x == 0 and math.abs(z) == 3 or x == 3 and math.abs(z) <= 1 or x == 4 and z == 0
		local position = pose:PointToWorldSpace(roblox.Vector3.new(x * Parts.KeyPitch, -Parts.PressDepth, z * Parts.KeyPitch))
		local supported = false
		for _, contact in contacts do if contains(contact, position) then supported = true end end
		check((occupied[x .. ":" .. z] == true) == expected and supported == expected, string.format("Arrow %s cell %d:%d expected=%s occupied=%s supported=%s", name, x, z, tostring(expected), tostring(occupied[x .. ":" .. z]), tostring(supported)))
	end end
	for _, contact in contacts do
		check(contact.CanCollide and contact.Anchored and math.abs(contact.CFrame.Position.Y + contact.Size.Y / 2 - (arrow:GetAttribute("TopPosition").Y - .45)) < .001, "Fixed aligned collision plane")
		for _, hazard in {o07.MarkedKillKeyLeft.Contact, o07.MarkedKillKeyRight.Contact} do
			local gap = separation(contact, hazard)
			check(gap > .75, "Arrow contact stays clear of marked kill body")
			minimumHazardSeparation = math.min(minimumHazardSeparation, gap)
		end
	end
	local silhouette = {}
	for z = -3, 3 do local row = ""; for x = -2, 4 do row ..= if occupied[x .. ":" .. z] then "#" else "." end; table.insert(silhouette, row) end
	arrows[name] = {caps = keys, contactSections = #contacts, coreSize = {12.8, 12.8}, direction = {target.X, target.Y, target.Z}, silhouette = silhouette}
end
local points = o07.TraversalPoints:GetChildren()
table.sort(points, function(a, b) return a:GetAttribute("Ordinal") < b:GetAttribute("Ordinal") end)
local previous, transfers = nil, {}
local function edge(part, direction)
	local d = part.CFrame:VectorToObjectSpace(direction)
	local x = if math.abs(d.X) > .001 then (part.Size.X / 2 - .9) / math.abs(d.X) else math.huge
	local z = if math.abs(d.Z) > .001 then (part.Size.Z / 2 - .9) / math.abs(d.Z) else math.huge
	return part.CFrame.Position + direction * math.min(x, z)
end
for _, point in points do
	local model
	for _, item in o07:GetDescendants() do if item:IsA("Model") and item.Name == point.Name then model = item; break end end
	check(model and model:IsA("Model") and model:FindFirstChild("BankContact"), "Existing continuous-lap waypoint resolver")
	local target = model.BankContact
	check((point.Position - model:GetAttribute("TopPosition")).Magnitude < .001, "TraversalPoint at bank top")
	if previous and point:GetAttribute("JumpFromPrevious") then
		local delta = target.CFrame.Position - previous.CFrame.Position
		local direction = roblox.Vector3.new(delta.X, 0, delta.Z).Unit
		local gap = (edge(target, -direction) - edge(previous, direction)).Magnitude
		local velocity = math.sqrt(2 * 196.2 * 7.2)
		local flight = (velocity + math.sqrt(velocity ^ 2 - 2 * 196.2 * delta.Y)) / 196.2
		check(gap + .2 < flight * 16, "Bounded ideal movement range for " .. point.Name)
		table.insert(transfers, {to = point.Name, fixtureEdgeDistance = gap, idealHorizontalRange = flight * 16, drop = -delta.Y})
	end
	previous = target
end
check(#points == 6 and #transfers == 3, "Two broad takeoff markers and three descending jumps")
local report = {
	candidate = "I06 geometry proposal only", passed = true, checks = checks,
	construction = candidate.inventory, baselineConstruction = baseline.inventory,
	bracketMarks = bracketMarks, arrows = arrows, transfers = transfers,
	minimumHorizontalKillSeparationLowerBound = minimumHazardSeparation,
	limits = "Offline Lune construction, source syntax, XML/internal references, cell support/grid lookup and ideal movement bounds. Pivots are fixture-implemented. No Roblox engine traversal/contact/audio/playback, player-height readability, human difficulty, crowd, device or FPS proof.",
}
fs.writeFile(outputPath, serde.encode("json", report, true))
print(serde.encode("json", report))
