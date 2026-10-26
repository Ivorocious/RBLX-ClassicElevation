local fs, roblox, serde = require("@lune/fs"), require("@lune/roblox"), require("@lune/serde")
local folder = "docs/artifacts/keyboard-circuit/phase3/m05-recovery/"
local expected = serde.decode("json", fs.readFile(folder .. "Before.json"))
local byName = {}
for _, row in expected.roots do byName[row.name] = row end
local result = {passed = true, files = {}, roots = {}}
for _, name in {"KeyboardCircuit-older-builds.rbxm", "M04-before-basic-handoff.rbxm"} do
	local bytes = fs.readFile(folder .. name)
	local roots = roblox.deserializeModel(bytes)
	table.insert(result.files, {file=name, bytes=#bytes, sha256=serde.hash("sha256", bytes), roots=#roots})
	for _, root in roots do
		local row = assert(byName[root.Name], "Unrecognized exported root")
		local items, classes, parts, sources = root:GetDescendants(), {}, 0, 0
		for _, item in items do
			classes[item.ClassName] = (classes[item.ClassName] or 0) + 1
			if item:IsA("BasePart") then parts += 1 end
			if item:IsA("LuaSourceContainer") then sources += 1 end
		end
		assert(#items == row.descendants and parts == row.parts and sources == row.sources, root.Name .. " export lost instances")
		for class, count in row.byClass do assert(classes[class] == count, root.Name .. " class mismatch: " .. class) end
		table.insert(result.roots, {name=root.Name, descendants=#items, parts=parts, sources=sources, classCountsMatch=true})
		root:Destroy()
	end
end
assert(#result.roots == #expected.roots, "Missing exported recovery root")
fs.writeFile(folder .. "Verified.json", serde.encode("json", result, true))
print(serde.encode("json", result))
