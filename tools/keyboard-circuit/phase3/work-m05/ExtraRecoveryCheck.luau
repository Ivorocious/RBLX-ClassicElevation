local fs, roblox, serde = require("@lune/fs"), require("@lune/roblox"), require("@lune/serde")
local folder = "docs/artifacts/keyboard-circuit/phase3/m05-recovery/"
local expected = serde.decode("json", fs.readFile(folder .. "ExtraBefore.json"))
local byName = {}; for _, row in expected.roots do byName[row.name] = row end
local bytes = fs.readFile(folder .. "KeyboardCircuit-phase1-history.rbxm")
local roots = roblox.deserializeModel(bytes)
assert(#roots == 2)
local result = {passed=true, file="KeyboardCircuit-phase1-history.rbxm", bytes=#bytes, sha256=serde.hash("sha256", bytes), roots={}}
for _, root in roots do
	local row = assert(byName[root.Name])
	local items, classes, parts, sources = root:GetDescendants(), {}, 0, 0
	for _, item in items do
		classes[item.ClassName] = (classes[item.ClassName] or 0) + 1
		if item:IsA("BasePart") then parts += 1 end
		if item:IsA("LuaSourceContainer") then sources += 1 end
	end
	assert(#items == row.descendants and parts == row.parts and sources == row.sources)
	for class, count in row.byClass do assert(classes[class] == count) end
	table.insert(result.roots, {name=root.Name, descendants=#items, parts=parts, sources=sources, classCountsMatch=true})
	root:Destroy()
end
fs.writeFile(folder .. "ExtraVerified.json", serde.encode("json", result, true))
print(serde.encode("json", result))
