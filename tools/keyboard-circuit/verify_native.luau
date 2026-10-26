local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local directory = "docs/artifacts/keyboard-circuit/phase1/"
local function read(name)
	local roots = roblox.deserializeModel(fs.readFile(directory .. name .. "-native.rbxm"))
	assert(#roots == 1, name .. " must contain one root")
	return roots[1]
end
local function vector(v) return string.format("%.4f,%.4f,%.4f", v.X, v.Y, v.Z) end
local function relative(object, root) return object:GetFullName():sub(#root.Name + 2) end
local function signatures(root)
	local result = {}
	for _,object in root:GetDescendants() do
		if object:IsA("BasePart") then
			local cf = {object.CFrame:GetComponents()}
			for i,v in cf do cf[i] = string.format("%.4f", if math.abs(v) < .00005 then 0 else v) end
			local fields = {relative(object, root), object.ClassName, vector(object.Size), table.concat(cf, ","), tostring(object.Color), tostring(object.Material), tostring(object.CanCollide), tostring(object.CanQuery), tostring(object.CanTouch), tostring(object.Transparency)}
			if object:IsA("MeshPart") then table.insert(fields, tostring(object.MeshContent)) end
			table.insert(result, table.concat(fields, "|"))
		end
	end
	table.sort(result)
	return result
end
local function joined(list) return table.concat(list, "\n") end
local function summary(root)
	local counts = {descendants = #root:GetDescendants(), parts = 0, scripts = 0, constraints = 0, welds = 0}
	for _,object in root:GetDescendants() do
		if object:IsA("BasePart") then counts.parts += 1 end
		if object:IsA("LuaSourceContainer") then counts.scripts += 1 end
		if object:IsA("PrismaticConstraint") then
			assert(object.Attachment0 and object.Attachment1, "Constraint attachments were lost")
			assert(object.Attachment0:IsDescendantOf(root) and object.Attachment1:IsDescendantOf(root), "External attachment")
			counts.constraints += 1
		end
		if object:IsA("WeldConstraint") then
			assert(object.Part0 and object.Part1, "Weld references were lost")
			assert(object.Part0:IsDescendantOf(root) and object.Part1:IsDescendantOf(root), "External weld")
			counts.welds += 1
		end
	end
	return counts
end
local c05, kit = read("C05"), read("KitC05")
local report = {revision = "KC_P1_C05", candidate = summary(c05), kit = summary(kit), roundTrip = {}, geometryPrecisionStuds = .0001}
for name,root in {candidate = c05, kit = kit} do
	local encoded = roblox.serializeModel({root})
	local restored = roblox.deserializeModel(encoded)[1]
	local beforeParts,afterParts = signatures(root), signatures(restored)
	if joined(beforeParts) ~= joined(afterParts) then
		for i,line in beforeParts do if line ~= afterParts[i] then print("Round-trip difference:", line, afterParts[i]); break end end
		error(name .. " part properties changed on round trip")
	end
	local before,after = summary(root), summary(restored)
	assert(serde.encode("json", before) == serde.encode("json", after), name .. " counts changed on round trip")
	local sourceDifferences = {}
	for _,object in root:GetDescendants() do
		if object:IsA("LuaSourceContainer") then
			local cursor = restored
			for token in relative(object, root):gmatch("[^.]+") do cursor = cursor:FindFirstChild(token) end
			if not cursor or cursor.Source ~= object.Source then table.insert(sourceDifferences, {path = relative(object,root), beforeBytes = #object.Source, afterBytes = cursor and #cursor.Source}) end
		end
	end
	report.roundTrip[name] = {geometryAndReferencesPassed = true, bytes = #encoded, restored = after, localSourceDifferences = sourceDifferences}
end
local c05Geometry = joined(signatures(c05))
local c03 = read("C03")
assert(joined(signatures(c03)) == c05Geometry, "C03/C05 geometry differs; do not reuse its geometry evidence")
report.geometryMatchesC03 = true
report.sourceVerification = "Actual Roblox engine round-trip verification is recorded in C05-engine-native-verification.json. Local reserialized buffers are not deliverables."
fs.writeFile(directory .. "C05-native-verification.json", serde.encode("json", report, true))
print(serde.encode("json", report))
